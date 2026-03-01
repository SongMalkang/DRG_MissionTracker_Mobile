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
  final String? warning;
  final int complexity;
  final int length;

  const DeepDiveStage({
    required this.num,
    required this.primary,
    this.secondary,
    this.warning,
    required this.complexity,
    required this.length,
  });

  factory DeepDiveStage.fromJson(int num, Map<String, dynamic> j) {
    final warnings = j['MissionWarnings'] as List?;
    return DeepDiveStage(
      num: num,
      primary: j['PrimaryObjective'] as String? ?? '',
      secondary: j['SecondaryObjective'] as String?,
      warning: (warnings != null && warnings.isNotEmpty)
          ? warnings.first as String
          : null,
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

  // ── Public Getters ────────────────────────────────────────────────────
  List<DeepDive>? get dives => _dives;
  DateTime? get thursdayUtc => _thursdayUtc;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  // ── Load Deep Dives ───────────────────────────────────────────────────
  Future<void> loadDeepDives({bool forceRefresh = false}) async {
    if (_isLoading) return;

    final thu = _latestThursday();
    _thursdayUtc = thu;

    // 메모리에 이미 같은 주 데이터가 있으면 즉시 반환
    if (!forceRefresh && _dives != null) {
      return;
    }

    _isLoading = true;
    _error = null;
    _notifyListeners();

    // Tier 1: 로컬 캐시
    if (!forceRefresh) {
      final cached = await _loadFromCache(thu);
      if (cached != null) {
        _dives = cached;
        _isLoading = false;
        _notifyListeners();
        // 백그라운드에서 GitHub도 확인 (silent refresh)
        _silentRefresh(thu);
        return;
      }
    }

    // Tier 2: GitHub Raw
    try {
      final body = await _fetchFromGitHub();
      final dives = _parseDiveData(body);
      _dives = dives;
      _isLoading = false;
      _notifyListeners();
      await _saveToCache(body, thu);
    } catch (e) {
      debugPrint("Deep Dive GitHub fetch failed: $e");

      // Tier 3: 번들 에셋
      try {
        final assetBody = await rootBundle.loadString('data/deep_dive.json');
        final dives = _parseDiveData(assetBody);
        _dives = dives;
        _error = null;
      } catch (assetError) {
        debugPrint("Deep Dive asset fallback failed: $assetError");
        // Tier 4: stale 캐시라도 표시
        final stale = await _loadFromCache(thu, ignoreExpiry: true);
        if (stale != null) {
          _dives = stale;
          _error = null;
        } else {
          _error = e.toString();
        }
      }

      _isLoading = false;
      _notifyListeners();
    }
  }

  // ── Silent Background Refresh ─────────────────────────────────────────
  Future<void> _silentRefresh(DateTime thu) async {
    try {
      final body = await _fetchFromGitHub();
      final dives = _parseDiveData(body);
      _dives = dives;
      await _saveToCache(body, thu);
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
  Future<List<DeepDive>?> _loadFromCache(DateTime thu, {bool ignoreExpiry = false}) async {
    try {
      if (!ignoreExpiry) {
        final prefs = await SharedPreferences.getInstance();
        final cachedThursday = prefs.getString(AppConstants.deepDiveCacheThursdayKey);
        if (cachedThursday != _thursdayKey(thu)) return null;
      }

      final body = await loadCacheString(AppConstants.cachedDeepDiveFile);
      if (body == null) return null;

      return _parseDiveData(body);
    } catch (e) {
      debugPrint("Deep Dive cache load failed: $e");
      return null;
    }
  }

  Future<void> _saveToCache(String body, DateTime thu) async {
    try {
      await saveCacheString(AppConstants.cachedDeepDiveFile, body);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        AppConstants.deepDiveCacheTimestampKey,
        DateTime.now().toUtc().millisecondsSinceEpoch,
      );
      await prefs.setString(
        AppConstants.deepDiveCacheThursdayKey,
        _thursdayKey(thu),
      );
    } catch (e) {
      debugPrint("Deep Dive cache save failed: $e");
    }
  }

  // ── Parsing ───────────────────────────────────────────────────────────
  List<DeepDive> _parseDiveData(String body) {
    final jsonData = jsonDecode(body) as Map<String, dynamic>;
    final ddMap = jsonData['Deep Dives'] as Map<String, dynamic>?;
    if (ddMap == null) throw const FormatException('Missing "Deep Dives" key');

    final dives = <DeepDive>[];
    for (final key in ['Deep Dive Normal', 'Deep Dive Elite']) {
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
    }
    return dives;
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
