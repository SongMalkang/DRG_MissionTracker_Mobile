import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/mission_model.dart';
import '../utils/constants.dart';

enum DataStatus { online, offline, outdated }

class MissionService {
  static final MissionService _instance = MissionService._internal();
  factory MissionService() => _instance;
  MissionService._internal();

  Map<String, List<Mission>> _allMissions = {};
  List<String> _availableSeasons = [];
  bool _isLoaded = false;
  DataStatus _status = DataStatus.online;

  Map<String, List<Mission>> get allMissions => _allMissions;
  List<String> get availableSeasons => _availableSeasons;
  bool get isLoaded => _isLoaded;
  DataStatus get status => _status;

  final String _remoteUrl = AppConstants.missionDataRemoteUrl;

  Future<void> loadMissions() async {
    if (_isLoaded) return;

    try {
      // 1. 로컬 캐시 확인
      final file = await _getLocalFile();
      String jsonString;

      if (await file.exists()) {
        jsonString = await file.readAsString();
        _status = DataStatus.offline; // 일단 오프라인 모드로 로드
      } else {
        // 2. 캐시 없으면 에셋에서 로드 (최초 실행)
        jsonString = await rootBundle.loadString(AppConstants.localMissionAsset);
      }

      _parseJson(jsonString);
      
      // 3. 백그라운드에서 원격 데이터 갱신 시도 (Leeching 방지를 위해 하루 1회 권장하지만, 여기선 fetch 시도만 함)
      _refreshRemoteData();
      
      _isLoaded = true;
    } catch (e) {
      debugPrint("Error loading missions: $e");
    }
  }

  Future<void> _refreshRemoteData() async {
    try {
      final response = await _fetchWithRetry(_remoteUrl);
      final file = await _getLocalFile();
      await file.writeAsString(response.body);
      _parseJson(response.body);
      _status = DataStatus.online;
    } catch (e) {
      debugPrint("Remote refresh failed: $e");
      _checkDataValidity();
    }
  }

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

  void _checkDataValidity() {
    final nowKey = _getTimeKey(DateTime.now().toUtc());
    if (!_allMissions.containsKey(nowKey)) {
      _status = DataStatus.outdated;
    }
  }

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
    }
  }
}
