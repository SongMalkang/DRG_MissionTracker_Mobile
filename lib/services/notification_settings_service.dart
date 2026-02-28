import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 알림 설정 전용 SharedPreferences CRUD 서비스
class NotificationSettingsService {
  static const String _enabledKey = 'notif_enabled';
  static const String _daysKey = 'notif_days';
  static const String _timeHourKey = 'notif_time_hour';
  static const String _timeMinuteKey = 'notif_time_minute';
  static const String _excludedTypesKey = 'notif_excluded_types';

  // ── 마스터 스위치 ──

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  // ── 활성 요일 (1=월 ~ 7=일) ──

  Future<List<int>> getEnabledDays() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_daysKey) ?? '1,2,3,4,5,6,7';
    return str
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => int.parse(s))
        .toList();
  }

  Future<void> setEnabledDays(List<int> days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_daysKey, days.join(','));
  }

  // ── 알림 시간 ──

  Future<TimeOfDay> getScheduledTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_timeHourKey) ?? 18;
    final minute = prefs.getInt(_timeMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setScheduledTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timeHourKey, hour);
    await prefs.setInt(_timeMinuteKey, minute);
  }

  // ── 제외할 미션 타입 ──

  Future<Set<String>> getExcludedMissionTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_excludedTypesKey) ?? '';
    if (str.isEmpty) return {};
    return str.split(',').where((s) => s.isNotEmpty).toSet();
  }

  Future<void> setExcludedMissionTypes(Set<String> types) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_excludedTypesKey, types.join(','));
  }
}
