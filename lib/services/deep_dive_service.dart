import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

// 조건부 임포트: 웹에서는 SharedPreferences, 네이티브에서는 파일 I/O
import '../platform/file_cache_stub.dart'
    if (dart.library.io) '../platform/file_cache_native.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class DeepDiveStage {
  final int num;
  final String primary;
  final String? secondary;
  final List<String> warnings;
  final int complexity;
  final int length;

  const DeepDiveStage({
    required this.num,
    required this.primary,
    this.secondary,
    this.warnings = const [],
    required this.complexity,
    required this.length,
  });

  /// 하위 호환: 첫 번째 경고 또는 null
  String? get warning => warnings.isNotEmpty ? warnings.first : null;

  factory DeepDiveStage.fromJson(int num, Map<String, dynamic> j) {
    return DeepDiveStage(
      num: num,
      primary: j['PrimaryObjective'] as String? ?? '',
      secondary: j['SecondaryObjective'] as String?,
      warnings: (j['MissionWarnings'] as List?)
              ?.whereType<String>()
              .toList() ??
          [],
      complexity: int.tryParse(j['Complexity']?.toString() ?? '1') ?? 1,
      length: int.tryParse(j['Length']?.toString() ?? '1') ?? 1,
    );
  }
}

class DeepDive {
  final bool isElite;
  final String biome;
  final String codeName;
  final List<DeepDiveStage> stages;

  const DeepDive({
    required this.isElite,
    required this.biome,
    required this.codeName,
    required this.stages,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class DeepDiveService {
  static final DeepDiveService _instance = DeepDiveService._internal();
  factory DeepDiveService() => _instance;
  DeepDiveService._internal();

  // ── State ─────────────────────────────────────────────────────────────
  List<DeepDive>? _dives;
  DateTime? _thursdayUtc;
  bool _isLoading = false;
  String? _error;

  /// 현재 로드된 데이터가 어느 주의 것인지 (JSON의 "thursday" 필드에서 추출)
  String? _dataThursdayKey;

  // ── Public Getters ────────────────────────────────────────────────────
  List<DeepDive>? get dives => _dives;
  DateTime? get thursdayUtc => _thursdayUtc;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 현재 표시 중인 데이터가 이번 주보다 오래된 경우 true
  /// (다음 주 DD가 조기 게시된 경우에는 stale이 아님)
  bool get isDataStale {
    if (_dives == null) return false;
    // _dataThursdayKey가 null이면 구 포맷 데이터 → stale 취급
    if (_dataThursdayKey == null) return true;
    final latestKey = _thursdayKey(_latestThursday());
    return _dataThursdayKey!.compareTo(latestKey) < 0;
  }

  /// 기존 데이터를 보여주면서 백그라운드 로딩 중인 경우 true
  bool get isRefreshing => _isLoading && _dives != null;

  // ── Listeners ─────────────────────────────────────────────────────────
  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void _notifyListeners() {
    for (final cb in _listeners) {
      cb();
    }
  }

  // ── 이번 주 목요일 UTC 11:00 계산 ──────────────────────────────────────
  DateTime _latestThursday() {
    final now = DateTime.now().toUtc();
    int daysBack = (now.weekday - DateTime.thursday) % 7;
    if (daysBack < 0) daysBack += 7;
    DateTime thu = DateTime.utc(
      now.year, now.month, now.day - daysBack,
      AppConstants.deepDiveResetHourUtc,
    );
    if (now.isBefore(thu)) thu = thu.subtract(const Duration(days: 7));
    return thu;
  }

  String _thursdayKey(DateTime thu) {
    return '${thu.year}-${thu.month.toString().padLeft(2, '0')}-${thu.day.toString().padLeft(2, '0')}';
  }

  /// JSON 본문에서 "thursday" 필드를 추출 (데이터의 실제 출처 주)
  static String? _extractThursdayKey(String body) {
    try {
      final jsonData = jsonDecode(body) as Map<String, dynamic>;
      return jsonData['thursday'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Load Deep Dives ───────────────────────────────────────────────────
  Future<void> loadDeepDives({bool forceRefresh = false}) async {
    if (_isLoading) return;

    final thu = _latestThursday();
    _thursdayUtc = thu;

    final currentKey = _thursdayKey(thu);

    // 메모리에 현재 주 이상의 데이터가 있으면 즉시 반환
    final hasCurrentData = _dataThursdayKey != null &&
        _dataThursdayKey!.compareTo(currentKey) >= 0;
    if (!forceRefresh && _dives != null && hasCurrentData) {
      return;
    }

    // 주가 바뀌었지만 기존 데이터가 있으면 → 기존 데이터 유지하면서 갱신 시도
    if (!forceRefresh && _dives != null && !hasCurrentData) {
      _isLoading = true;
      _notifyListeners();
      try {
        final body = await _fetchFromGitHub();
        _dives = _parseDiveData(body);
        _dataThursdayKey = _extractThursdayKey(body);
        await _saveToCache(body);
      } catch (_) {
        // GitHub 실패 → 기존 데이터 유지, isDataStale 유지 (수동 새로고침 가능)
      }
      _isLoading = false;
      _notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _notifyListeners();

    // Tier 1: 로컬 캐시
    if (!forceRefresh) {
      final body = await _loadCacheBody(thu);
      if (body != null) {
        try {
          _dives = _parseDiveData(body);
          _dataThursdayKey = _extractThursdayKey(body);
          _isLoading = false;
          _notifyListeners();
          // 백그라운드에서 GitHub도 확인 (silent refresh)
          unawaited(_silentRefresh());
          return;
        } catch (_) {
          // 캐시 파싱 실패 → 다음 단계로
        }
      }
    }

    // Tier 2: GitHub Raw
    try {
      final body = await _fetchFromGitHub();
      _dives = _parseDiveData(body);
      _dataThursdayKey = _extractThursdayKey(body);
      _isLoading = false;
      _notifyListeners();
      await _saveToCache(body);
    } catch (e) {
      debugPrint("Deep Dive GitHub fetch failed: $e");

      // Tier 3: 번들 에셋
      try {
        final assetBody = await rootBundle.loadString('data/deep_dive.json');
        _dives = _parseDiveData(assetBody);
        _dataThursdayKey = _extractThursdayKey(assetBody);
        _error = null;
      } catch (assetError) {
        debugPrint("Deep Dive asset fallback failed: $assetError");
        // Tier 4: stale 캐시라도 표시
        final staleBody = await _loadCacheBody(thu, ignoreExpiry: true);
        if (staleBody != null) {
          try {
            _dives = _parseDiveData(staleBody);
            _dataThursdayKey = _extractThursdayKey(staleBody);
            _error = null;
          } catch (_) {
            _error = e.toString();
          }
        } else {
          _error = e.toString();
        }
      }

      _isLoading = false;
      _notifyListeners();
    }
  }

  // ── Silent Background Refresh ─────────────────────────────────────────
  Future<void> _silentRefresh() async {
    try {
      final body = await _fetchFromGitHub();
      final dives = _parseDiveData(body);
      _dives = dives;
      _dataThursdayKey = _extractThursdayKey(body);
      await _saveToCache(body);
      _notifyListeners();
    } catch (_) {
      // silent fail - 캐시 데이터 유지
    }
  }

  // ── GitHub Fetch ──────────────────────────────────────────────────────
  Future<String> _fetchFromGitHub() async {
    for (int attempt = 0; attempt < AppConstants.maxRetryAttempts; attempt++) {
      try {
        final response = await http
            .get(Uri.parse(AppConstants.deepDiveDataUrl))
            .timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));
        if (response.statusCode == 200) return response.body;
      } catch (_) {
        // retry
      }
      if (attempt < AppConstants.maxRetryAttempts - 1) {
        await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }
    throw Exception('Deep Dive fetch failed after ${AppConstants.maxRetryAttempts} attempts');
  }

  // ── Cache Management ──────────────────────────────────────────────────
  Future<String?> _loadCacheBody(DateTime thu, {bool ignoreExpiry = false}) async {
    try {
      if (!ignoreExpiry) {
        final prefs = await SharedPreferences.getInstance();
        final cachedThursday = prefs.getString(AppConstants.deepDiveCacheThursdayKey);
        // 캐시 데이터가 현재 주보다 과거이면 만료 (조기 게시된 미래 데이터는 유효)
        if (cachedThursday == null || cachedThursday.compareTo(_thursdayKey(thu)) < 0) {
          return null;
        }
      }

      return await loadCacheString(AppConstants.cachedDeepDiveFile);
    } catch (e) {
      debugPrint("Deep Dive cache load failed: $e");
      return null;
    }
  }

  Future<void> _saveToCache(String body) async {
    try {
      await saveCacheString(AppConstants.cachedDeepDiveFile, body);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        AppConstants.deepDiveCacheTimestampKey,
        DateTime.now().toUtc().millisecondsSinceEpoch,
      );
      await prefs.setString(
        AppConstants.deepDiveCacheThursdayKey,
        _extractThursdayKey(body) ?? '',
      );
    } catch (e) {
      debugPrint("Deep Dive cache save failed: $e");
    }
  }

  // ── Parsing ───────────────────────────────────────────────────────────
  static List<DeepDive> parseDiveDataPublic(String body) => DeepDiveService._parseDiveDataImpl(body);

  List<DeepDive> _parseDiveData(String body) => _parseDiveDataImpl(body);

  static List<DeepDive> _parseDiveDataImpl(String body) {
    try {
      final jsonData = jsonDecode(body) as Map<String, dynamic>;
      final ddMap = jsonData['Deep Dives'] as Map<String, dynamic>?;
      if (ddMap == null) throw const FormatException('Missing "Deep Dives" key');

      final dives = <DeepDive>[];
      for (final key in ['Deep Dive Normal', 'Deep Dive Elite']) {
        try {
          final dd = ddMap[key] as Map<String, dynamic>?;
          if (dd == null) continue;
          final stagesRaw = dd['Stages'] as List?;
          if (stagesRaw == null) continue;
          final stages = stagesRaw
              .asMap()
              .entries
              .map((e) => DeepDiveStage.fromJson(
                  e.key + 1, e.value as Map<String, dynamic>))
              .toList();
          dives.add(DeepDive(
            isElite: key.contains('Elite'),
            biome: dd['Biome'] as String? ?? '',
            codeName: dd['CodeName'] as String? ?? '',
            stages: stages,
          ));
        } catch (e) {
          debugPrint('Failed to parse deep dive "$key": $e');
          continue;
        }
      }
      return dives;
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Deep Dive JSON parsing failed: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  DateTime nextThursday() {
    final thu = _thursdayUtc ?? _latestThursday();
    return thu.add(const Duration(days: 7));
  }

  void dispose() {
    _listeners.clear();
  }
}
