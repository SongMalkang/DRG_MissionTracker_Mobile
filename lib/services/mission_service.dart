import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/mission_model.dart';

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

  // GitHub CDN URL (향후 사용자님의 URL로 교체)
  final String _remoteUrl = "https://raw.githubusercontent.com/rolfosian/drgmissions/master/data/bulk/2026-02-27.json";

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
        jsonString = await rootBundle.loadString('data/daily_missions.json');
      }

      _parseJson(jsonString);
      
      // 3. 백그라운드에서 원격 데이터 갱신 시도 (Leeching 방지를 위해 하루 1회 권장하지만, 여기선 fetch 시도만 함)
      _refreshRemoteData();
      
      _isLoaded = true;
    } catch (e) {
      print("Error loading missions: $e");
    }
  }

  Future<void> _refreshRemoteData() async {
    try {
      // 원격 데이터 가져오기 (타임아웃 설정으로 무한 대기 방지)
      final response = await http.get(Uri.parse(_remoteUrl)).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final file = await _getLocalFile();
        await file.writeAsString(response.body); // 로컬에 저장
        _parseJson(response.body);
        _status = DataStatus.online;
      }
    } catch (e) {
      // 연결 실패 시 status는 이미 offline/outdated로 판단됨
      print("Remote refresh failed: $e");
      _checkDataValidity();
    }
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
    return File('${directory.path}/cached_missions.json');
  }

  List<Mission> getMissionsForTime(DateTime utcTime) {
    return _allMissions[_getTimeKey(utcTime)] ?? [];
  }

  // [DEBUG] 상태 강제 전환 트리거
  void debugSetStatus(DataStatus newStatus) {
    _status = status; // 기존 상태 저장 로직 대신
    _status = newStatus;
  }
}
