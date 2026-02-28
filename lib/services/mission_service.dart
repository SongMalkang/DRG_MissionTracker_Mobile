import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mission_model.dart';
import '../utils/constants.dart';

enum DataStatus { online, offline, outdated, refreshing }

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

  // ── Listeners ───────────────────────────────────────────────────────────
  final List<VoidCallback> _listeners = [];

  // ── Public Getters ──────────────────────────────────────────────────────
  Map<String, List<Mission>> get allMissions => _allMissions;
  List<String> get availableSeasons => _availableSeasons;
  bool get isInitialized => _isInitialized;
  DataStatus get status => _status;

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
      _backgroundRefresh();
      return;
    }

    try {
      // Tier 1: 로컬 캐시 (빠른 시작)
      final file = await _getLocalFile();
      if (await file.exists()) {
        final cacheJson = await file.readAsString();
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
      _backgroundRefresh();

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

      // 캐시 저장
      final file = await _getLocalFile();
      await file.writeAsString(response.body);
      await _saveCacheTimestamp();

      _status = DataStatus.online;
      _isInitialized = true;
      _notifyListeners();
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

  // ── Cache Timestamp ─────────────────────────────────────────────────────
  Future<void> _saveCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      AppConstants.cacheTimestampKey,
      DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  }

  // ── JSON Parsing (압축 포맷) ────────────────────────────────────────────
  void _parseJson(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);
    Map<String, List<Mission>> tempMap = {};
    Set<String> seasons = {};

    data.forEach((key, value) {
      if (value is List) {
        final missions = value.map((m) => Mission.fromJson(m)).toList();
        tempMap[key] = missions;
        for (var m in missions) {
          seasons.addAll(m.seasons);
        }
      }
    });

    _allMissions = tempMap;
    _availableSeasons = seasons.toList()..sort();
    _checkDataValidity();
  }

  // ── Data Validity Check ─────────────────────────────────────────────────
  void _checkDataValidity() {
    final nowKey = _getTimeKey(DateTime.now().toUtc());
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
  String _getTimeKey(DateTime utcTime) {
    String y = utcTime.year.toString();
    String m = utcTime.month.toString().padLeft(2, '0');
    String d = utcTime.day.toString().padLeft(2, '0');
    String h = utcTime.hour.toString().padLeft(2, '0');
    String min = (utcTime.minute < 30 ? "00" : "30");
    return "${y}-${m}-${d}T$h:$min:00Z";
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/${AppConstants.cachedMissionFile}');
  }

  List<Mission> getMissionsForTime(DateTime utcTime) {
    return _allMissions[_getTimeKey(utcTime)] ?? [];
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
