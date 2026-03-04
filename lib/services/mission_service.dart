import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mission_model.dart';
import '../utils/constants.dart';

// 조건부 임포트: 웹에서는 dart:io / path_provider 사용 불가
import '../platform/file_cache_stub.dart'
    if (dart.library.io) '../platform/file_cache_native.dart';

// 조건부 임포트: 홈 위젯 (웹에서는 no-op)
import '../platform/home_widget_stub.dart'
    if (dart.library.io) '../services/home_widget_service.dart';

enum DataStatus { online, offline, outdated, refreshing }

/// 디바이스 시계가 서버 시간과 5분 이상 차이 날 때 경고
const int _clockDriftThresholdMinutes = 5;

class MissionService {
  static final MissionService _instance = MissionService._internal();
  factory MissionService() => _instance;
  MissionService._internal();

  // ── State ───────────────────────────────────────────────────────────────
  Map<String, List<Mission>> _allMissions = {};
  List<String> _availableSeasons = [];
  bool _isInitialized = false;
  DataStatus _status = DataStatus.offline;
  Timer? _refreshTimer;

  /// 서버-디바이스 시간 차이 (분). null이면 측정되지 않은 상태.
  int? _clockDriftMinutes;

  /// 원시 JSON 데이터 (지연 파싱용, 초기 로드 후 나머지 파싱 완료 시 null)
  Map<String, dynamic>? _rawJsonData;

  // ── Listeners ───────────────────────────────────────────────────────────
  final List<VoidCallback> _listeners = [];

  // ── Public Getters ──────────────────────────────────────────────────────
  Map<String, List<Mission>> get allMissions => _allMissions;
  List<String> get availableSeasons => _availableSeasons;
  bool get isInitialized => _isInitialized;
  DataStatus get status => _status;

  /// 서버-디바이스 시간 차이가 임계값 이상인 경우 true
  bool get hasClockDrift =>
      _clockDriftMinutes != null &&
      _clockDriftMinutes!.abs() >= _clockDriftThresholdMinutes;

  // ── Listener Management ─────────────────────────────────────────────────
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void _notifyListeners() {
    for (final cb in _listeners) {
      cb();
    }
  }

  // ── Initialization ──────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_isInitialized) {
      // 이미 초기화됨: 백그라운드 갱신만 시도
      unawaited(_backgroundRefresh());
      return;
    }

    try {
      // Tier 1: 로컬 캐시 (빠른 시작)
      final cacheJson = await loadCacheString(AppConstants.cachedMissionFile);
      if (cacheJson != null) {
        _parseJson(cacheJson);
        _status = DataStatus.offline;
        _isInitialized = true;
        _notifyListeners();
      }

      // Tier 2: 캐시 없으면 번들 에셋
      if (!_isInitialized) {
        try {
          final assetJson = await rootBundle.loadString(AppConstants.localMissionAsset);
          _parseJson(assetJson);
          _status = DataStatus.offline;
          _isInitialized = true;
          _notifyListeners();
        } catch (e) {
          debugPrint("Bundled asset load failed: $e");
        }
      }

      // Tier 3: GitHub Raw 비동기 fetch (논블로킹)
      unawaited(_backgroundRefresh());

      // 주기적 백그라운드 갱신 시작
      _startPeriodicRefresh();
    } catch (e) {
      debugPrint("Error initializing MissionService: $e");
    }
  }

  // ── Background Refresh ──────────────────────────────────────────────────
  Future<void> _backgroundRefresh() async {
    if (_status == DataStatus.refreshing) return;

    final previousStatus = _status;
    _status = DataStatus.refreshing;
    if (_isInitialized) _notifyListeners();

    try {
      final response = await _fetchWithRetry(AppConstants.missionDataUrl);
      _parseJson(response.body);
      _checkClockDrift(response);

      // 캐시 저장
      await saveCacheString(AppConstants.cachedMissionFile, response.body);
      await _saveCacheTimestamp();

      _status = DataStatus.online;
      _isInitialized = true;
      _notifyListeners();

      // 홈 위젯 데이터 갱신
      unawaited(HomeWidgetService.updateWidget());
    } catch (e) {
      debugPrint("Background refresh failed: $e");
      _status = previousStatus == DataStatus.refreshing
          ? DataStatus.offline
          : previousStatus;
      _checkDataValidity();
      _notifyListeners();
    }
  }

  // ── Public: Force Refresh ───────────────────────────────────────────────
  Future<void> forceRefresh() async {
    await _backgroundRefresh();
  }

  // ── Periodic Refresh ────────────────────────────────────────────────────
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: AppConstants.backgroundRefreshIntervalMinutes),
      (_) => _backgroundRefresh(),
    );
  }

  /// 백그라운드 전환 시 타이머 정지
  void pausePeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 포그라운드 복귀 시 타이머 재개 + 즉시 갱신 시도
  void resumePeriodicRefresh() {
    _startPeriodicRefresh();
    _backgroundRefresh();
  }

  // ── Cache Timestamp ─────────────────────────────────────────────────────
  Future<void> _saveCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      AppConstants.cacheTimestampKey,
      DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  }

  // ── Clock Drift Detection ──────────────────────────────────────────────────
  void _checkClockDrift(http.Response response) {
    final dateHeader = response.headers['date'];
    if (dateHeader == null) return;

    try {
      // HTTP date format: "Tue, 04 Mar 2026 12:00:00 GMT"
      final serverTime = _parseHttpDate(dateHeader);
      if (serverTime == null) return;
      final localTime = DateTime.now().toUtc();
      final diff = localTime.difference(serverTime).inMinutes;
      _clockDriftMinutes = diff;
      if (diff.abs() >= _clockDriftThresholdMinutes) {
        debugPrint(
          'Clock drift detected: device is ${diff}m '
          '${diff > 0 ? "ahead of" : "behind"} server time',
        );
      }
    } catch (e) {
      debugPrint('Failed to parse server date header: $e');
    }
  }

  static DateTime? _parseHttpDate(String dateStr) {
    // RFC 7231: "Tue, 04 Mar 2026 12:00:00 GMT"
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    try {
      final parts = dateStr.split(' ');
      if (parts.length < 6) return null;
      final day = int.parse(parts[1]);
      final month = months[parts[2]];
      if (month == null) return null;
      final year = int.parse(parts[3]);
      final timeParts = parts[4].split(':');
      return DateTime.utc(
        year, month, day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  // ── JSON Parsing (지연 파싱: 현재 시간대 우선) ──────────────────────────────
  void _parseJson(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);

    final now = DateTime.now().toUtc();
    final currentKey = getTimeKey(now);

    // 현재 ±1 슬롯 (현재 + 다음 30분) 우선 파싱
    final priorityKeys = <String>{
      currentKey,
      getTimeKey(now.subtract(const Duration(minutes: 30))),
      getTimeKey(now.add(const Duration(minutes: 30))),
    };

    final Map<String, List<Mission>> tempMap = {};
    final Set<String> seasons = {};

    // 1단계: 우선 슬롯만 즉시 파싱
    for (final key in priorityKeys) {
      final value = data[key];
      if (value is List) {
        final missions = value.map((m) => Mission.fromJson(m)).toList();
        tempMap[key] = missions;
        for (var m in missions) {
          seasons.addAll(m.seasons);
        }
      }
    }

    _allMissions = tempMap;
    _availableSeasons = seasons.toList()..sort();
    _checkDataValidity();

    // 2단계: 나머지 슬롯은 마이크로태스크로 지연 파싱
    _rawJsonData = data;
    Future.microtask(() => _parseDeferredSlots(priorityKeys));
  }

  /// 우선 파싱된 슬롯 외 나머지를 백그라운드에서 파싱
  void _parseDeferredSlots(Set<String> alreadyParsed) {
    final data = _rawJsonData;
    if (data == null) return;

    final Set<String> seasons = {};
    for (final s in _availableSeasons) {
      seasons.add(s);
    }

    data.forEach((key, value) {
      if (!alreadyParsed.contains(key) && value is List) {
        final missions = value.map((m) => Mission.fromJson(m)).toList();
        _allMissions[key] = missions;
        for (var m in missions) {
          seasons.addAll(m.seasons);
        }
      }
    });

    _availableSeasons = seasons.toList()..sort();
    _rawJsonData = null; // 원시 데이터 해제
    _checkDataValidity();
    _notifyListeners();
  }

  // ── Data Validity Check ─────────────────────────────────────────────────
  void _checkDataValidity() {
    final nowKey = getTimeKey(DateTime.now().toUtc());
    if (!_allMissions.containsKey(nowKey)) {
      if (_status != DataStatus.online && _status != DataStatus.refreshing) {
        _status = DataStatus.outdated;
      }
    }
  }

  // ── Network Fetch with Retry ────────────────────────────────────────────
  Future<http.Response> _fetchWithRetry(String url) async {
    for (int attempt = 0; attempt < AppConstants.maxRetryAttempts; attempt++) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: AppConstants.networkTimeoutSeconds),
        );
        if (response.statusCode == 200) return response;
      } catch (_) {
        // retry
      }
      if (attempt < AppConstants.maxRetryAttempts - 1) {
        await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }
    throw Exception('Failed after ${AppConstants.maxRetryAttempts} attempts');
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  static String getTimeKey(DateTime utcTime) {
    final y = utcTime.year.toString();
    final m = utcTime.month.toString().padLeft(2, '0');
    final d = utcTime.day.toString().padLeft(2, '0');
    final h = utcTime.hour.toString().padLeft(2, '0');
    final min = (utcTime.minute < 30 ? "00" : "30");
    return "$y-$m-${d}T$h:$min:00Z";
  }

  List<Mission> getMissionsForTime(DateTime utcTime) {
    final key = getTimeKey(utcTime);
    if (_allMissions.containsKey(key)) {
      return _allMissions[key]!;
    }
    // outdated 상태: 가장 가까운 과거 시간 키의 데이터 반환
    if (_allMissions.isNotEmpty) {
      final keys = _allMissions.keys.toList()..sort();
      // 요청 시간보다 이전이면서 가장 가까운 키
      String? closest;
      for (final k in keys.reversed) {
        if (k.compareTo(key) <= 0) {
          closest = k;
          break;
        }
      }
      // 과거에도 없으면 가장 마지막 키
      closest ??= keys.last;
      return _allMissions[closest] ?? [];
    }
    return [];
  }

  void debugSetStatus(DataStatus newStatus) {
    if (kDebugMode) {
      _status = newStatus;
      _notifyListeners();
    }
  }

  void dispose() {
    _refreshTimer?.cancel();
    _listeners.clear();
  }
}
