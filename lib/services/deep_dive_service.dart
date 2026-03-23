import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'base_data_service.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class DeepDiveStage {
  final int num;
  final String primary;
  final String? secondary;
  final List<String> warnings;
  final String? mutator;
  final int complexity;
  final int length;

  const DeepDiveStage({
    required this.num,
    required this.primary,
    this.secondary,
    this.warnings = const [],
    this.mutator,
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
      mutator: j['MissionMutator'] as String?,
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

class DeepDiveService with ListenerMixin, NetworkFetchMixin, CacheManagementMixin {
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

  // ── Thursday Polling State ────────────────────────────────────────────
  Timer? _thursdayPollTimer;
  int _pollAttempt = 0;
  bool _isThursdayPolling = false;
  DateTime? _nextPollTime;

  // ── Public Getters ────────────────────────────────────────────────────
  List<DeepDive>? get dives => _dives;
  DateTime? get thursdayUtc => _thursdayUtc;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get dataThursdayKey => _dataThursdayKey;

  /// 목요일 자동 폴링이 진행 중인 경우 true
  bool get isThursdayPolling => _isThursdayPolling;

  /// 현재 폴링 시도 횟수
  int get pollAttempt => _pollAttempt;

  DateTime? get nextPollTime => _nextPollTime;

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

  // ── Listeners (via ListenerMixin) ─────────────────────────────────────

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
      notifyListeners();
      try {
        final body = await _fetchFromGitHub(bustCache: true);
        _dives = _parseDiveData(body);
        _dataThursdayKey = _extractThursdayKey(body);
        await _saveToCache(body);
      } catch (_) {
        // GitHub 실패 → 기존 데이터 유지, isDataStale 유지 (수동 새로고침 가능)
      }
      _isLoading = false;
      notifyListeners();
      _onLoadComplete();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    // Tier 1: 로컬 캐시
    if (!forceRefresh) {
      final body = await _loadCacheBody(thu);
      if (body != null) {
        try {
          _dives = _parseDiveData(body);
          _dataThursdayKey = _extractThursdayKey(body);
          _isLoading = false;
          notifyListeners();
          // 백그라운드에서 GitHub도 확인 (silent refresh)
          unawaited(_silentRefresh());
          _onLoadComplete();
          return;
        } catch (_) {
          // 캐시 파싱 실패 → 다음 단계로
        }
      }
    }

    // Tier 2: GitHub Raw (forceRefresh 시 캐시 버스팅)
    try {
      final body = await _fetchFromGitHub(bustCache: forceRefresh);
      _dives = _parseDiveData(body);
      _dataThursdayKey = _extractThursdayKey(body);
      _isLoading = false;
      notifyListeners();
      await _saveToCache(body);
      _onLoadComplete();
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
      notifyListeners();
      _onLoadComplete();
    }
  }

  /// 로드 완료 후 공통 처리: 새 데이터면 폴링 중단, stale이면 폴링 시작
  void _onLoadComplete() {
    if (!isDataStale && _isThursdayPolling) {
      _stopThursdayPolling();
    } else {
      _maybeStartThursdayPolling();
    }
  }

  // ── Silent Background Refresh ─────────────────────────────────────────
  Future<void> _silentRefresh() async {
    try {
      final body = await _fetchFromGitHub(bustCache: isDataStale);
      final dives = _parseDiveData(body);
      _dives = dives;
      _dataThursdayKey = _extractThursdayKey(body);
      await _saveToCache(body);
      notifyListeners();
      // 새 데이터가 도착했으면 폴링 중단
      if (!isDataStale && _isThursdayPolling) {
        _stopThursdayPolling();
      }
    } catch (_) {
      // silent fail - 캐시 데이터 유지
    }
    // 여전히 stale이면 폴링 시작 시도
    _maybeStartThursdayPolling();
  }

  // ── GitHub Fetch (via NetworkFetchMixin) ─────────────────────────────
  Future<String> _fetchFromGitHub({bool bustCache = false}) {
    String url = AppConstants.deepDiveDataUrl;
    if (bustCache) {
      // 브라우저 HTTP 캐시 및 CDN 캐시를 우회하여 최신 데이터 확보
      url += '?_cb=${DateTime.now().millisecondsSinceEpoch}';
    }
    return fetchBodyWithRetry(url);
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

      return await loadCache(AppConstants.cachedDeepDiveFile);
    } catch (e) {
      debugPrint("Deep Dive cache load failed: $e");
      return null;
    }
  }

  Future<void> _saveToCache(String body) async {
    try {
      await saveCache(AppConstants.cachedDeepDiveFile, body);

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

  // ── Thursday Adaptive Polling ──────────────────────────────────────────

  /// 목요일 리셋 윈도우 내에서 stale 데이터가 감지되면 자동 폴링 시작
  void _maybeStartThursdayPolling() {
    if (_isThursdayPolling) return;
    if (!isDataStale) return;
    if (!_isInThursdayPollWindow()) return;
    _startThursdayPolling();
  }

  /// 현재 시각이 목요일 리셋 윈도우(11:00 ~ 11:00+90분) 안인지 확인
  bool _isInThursdayPollWindow() {
    final now = DateTime.now().toUtc();
    if (now.weekday != DateTime.thursday) return false;
    final resetTime = DateTime.utc(
      now.year, now.month, now.day,
      AppConstants.deepDiveResetHourUtc,
    );
    final windowEnd = resetTime.add(
      const Duration(minutes: AppConstants.ddPollWindowMinutes),
    );
    return !now.isBefore(resetTime) && now.isBefore(windowEnd);
  }

  void _startThursdayPolling() {
    if (_isThursdayPolling) return;
    _isThursdayPolling = true;
    _pollAttempt = 0;
    debugPrint('Deep Dive: Thursday adaptive polling started');
    notifyListeners();
    _thursdayPollTick();
  }

  Future<void> _thursdayPollTick() async {
    if (!_isThursdayPolling) return;

    // 수동 새로고침이 진행 중이면 이번 틱은 건너뛰고 다음 틱 예약
    if (_isLoading) {
      _scheduleNextPollTick();
      return;
    }

    if (_pollAttempt >= AppConstants.ddPollMaxAttempts) {
      debugPrint('Deep Dive: max poll attempts (${AppConstants.ddPollMaxAttempts}) reached');
      _stopThursdayPolling();
      return;
    }

    if (!_isInThursdayPollWindow()) {
      debugPrint('Deep Dive: outside Thursday poll window, stopping');
      _stopThursdayPolling();
      return;
    }

    _pollAttempt++;
    debugPrint('Deep Dive: poll #$_pollAttempt');

    try {
      final body = await _fetchFromGitHub(bustCache: true);
      final fetchedKey = _extractThursdayKey(body);
      final currentKey = _thursdayKey(_latestThursday());

      if (fetchedKey != null && fetchedKey.compareTo(currentKey) >= 0) {
        // 새로운 데이터 도착
        _dives = _parseDiveData(body);
        _dataThursdayKey = fetchedKey;
        await _saveToCache(body);
        debugPrint('Deep Dive: fresh data arrived (week: $fetchedKey)');
        _stopThursdayPolling();
        return;
      }
      debugPrint('Deep Dive: data still stale (got: $fetchedKey, need: $currentKey)');
    } catch (e) {
      debugPrint('Deep Dive: poll #$_pollAttempt failed: $e');
    }

    _scheduleNextPollTick();
  }

  void _scheduleNextPollTick() {
    if (!_isThursdayPolling) return;
    final interval = _calcPollInterval(_pollAttempt);
    debugPrint('Deep Dive: next poll in ${interval.inSeconds}s');
    _nextPollTime = DateTime.now().add(interval);
    _thursdayPollTimer = Timer(interval, _thursdayPollTick);
    notifyListeners();
  }

  /// 지수 백오프 간격 계산
  /// attempt 1-3: 30s, 4-6: 60s, 7-9: 120s, 10+: 300s (최대)
  Duration _calcPollInterval(int attempt) {
    final bucket = (attempt - 1) ~/ 3; // 0, 1, 2, 3+
    final multiplier = 1 << bucket.clamp(0, 4); // 1, 2, 4, 8, 16
    final seconds = (AppConstants.ddPollInitialDelaySeconds * multiplier)
        .clamp(AppConstants.ddPollInitialDelaySeconds, AppConstants.ddPollMaxIntervalSeconds);
    return Duration(seconds: seconds);
  }

  void _stopThursdayPolling() {
    _thursdayPollTimer?.cancel();
    _thursdayPollTimer = null;
    _isThursdayPolling = false;
    _pollAttempt = 0;
    _nextPollTime = null;
    notifyListeners();
  }

  /// 앱 백그라운드 전환 시 폴링 타이머 정지 (배터리 절약)
  void pausePolling() {
    _thursdayPollTimer?.cancel();
    _thursdayPollTimer = null;
  }

  /// 앱 포그라운드 복귀 시 폴링 재개 (데이터가 여전히 stale이면)
  void resumePolling() {
    if (_isThursdayPolling && _thursdayPollTimer == null) {
      // pause로 타이머만 중단된 상태 → 즉시 재개
      _thursdayPollTick();
    } else {
      // 새로 폴링이 필요한지 확인
      _maybeStartThursdayPolling();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  DateTime nextThursday() {
    final thu = _thursdayUtc ?? _latestThursday();
    return thu.add(const Duration(days: 7));
  }

  void dispose() {
    _stopThursdayPolling();
    clearListeners();
  }
}
