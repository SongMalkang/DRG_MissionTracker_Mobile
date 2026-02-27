import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/mission_model.dart';

class MissionService {
  Map<String, List<Mission>> _allMissions = {};
  bool _isLoaded = false;

  Future<void> loadMissions() async {
    if (_isLoaded) return;
    try {
      final String response = await rootBundle.loadString('data/daily_missions.json');
      final Map<String, dynamic> data = json.decode(response);
      
      Map<String, List<Mission>> tempMap = {};
      Set<String> seasons = {};
      
      data.forEach((key, value) {
        final List<Mission> missions = (value as List).map((m) => Mission.fromJson(m)).toList();
        tempMap[key] = missions;
        for (var m in missions) {
          seasons.addAll(m.seasons);
        }
      });
      _allMissions = tempMap;
      _availableSeasons = seasons.toList()..sort();
      _isLoaded = true;
    } catch (e) {
      // ignore: avoid_print
      print("Error loading missions: $e");
    }
  }

  List<String> _availableSeasons = [];
  List<String> get availableSeasons => _availableSeasons;

  List<Mission> getMissionsForTime(DateTime utcTime) {
    // Format: 2026-02-27T00:00:00Z
    String y = utcTime.year.toString();
    String m = utcTime.month.toString().padLeft(2, '0');
    String d = utcTime.day.toString().padLeft(2, '0');
    String h = utcTime.hour.toString().padLeft(2, '0');
    String min = (utcTime.minute < 30 ? "00" : "30");
    
    String key = "$y-$m-${d}T$h:$min:00Z";
    return _allMissions[key] ?? [];
  }

  Map<String, List<Mission>> get allMissions => _allMissions;
}
