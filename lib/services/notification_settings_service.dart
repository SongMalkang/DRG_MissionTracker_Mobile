import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 알림 설정 전용 SharedPreferences CRUD 서비스
class NotificationSettingsService {
  static const String _enabledKey = 'notif_enabled';
  static const String _daysKey = 'notif_days';
  static const String _timeHourKey = 'notif_time_hour';
  static const String _timeMinuteKey = 'notif_time_minute';
  static const String _endHourKey = 'notif_end_hour';
  static const String _endMinuteKey = 'notif_end_minute';
  static const String _excludedTypesKey = 'notif_excluded_types';

  // ── 마스터 스위치 ──

  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? false;
    } catch (e) {
      debugPrint('NotificationSettingsService.isEnabled failed: $e');
      return false;
    }
  }

  Future<void> setEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (e) {
      debugPrint('NotificationSettingsService.setEnabled failed: $e');
    }
  }

  // ── 활성 요일 (1=월 ~ 7=일) ──

  Future<List<int>> getEnabledDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_daysKey) ?? '1,2,3,4,5,6,7';
      return str
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s))
          .toList();
    } catch (e) {
      debugPrint('NotificationSettingsService.getEnabledDays failed: $e');
      return [1, 2, 3, 4, 5, 6, 7];
    }
  }

  Future<void> setEnabledDays(List<int> days) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_daysKey, days.join(','));
    } catch (e) {
      debugPrint('NotificationSettingsService.setEnabledDays failed: $e');
    }
  }

  // ── 알림 시작 시간 ──

  Future<TimeOfDay> getScheduledTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt(_timeHourKey) ?? 19;
      final minute = prefs.getInt(_timeMinuteKey) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint('NotificationSettingsService.getScheduledTime failed: $e');
      return const TimeOfDay(hour: 19, minute: 0);
    }
  }

  Future<void> setScheduledTime(int hour, int minute) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_timeHourKey, hour);
      await prefs.setInt(_timeMinuteKey, minute);
    } catch (e) {
      debugPrint('NotificationSettingsService.setScheduledTime failed: $e');
    }
  }

  // ── 알림 종료 시간 (default 23:00) ──

  Future<TimeOfDay> getEndTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt(_endHourKey) ?? 22;
      final minute = prefs.getInt(_endMinuteKey) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint('NotificationSettingsService.getEndTime failed: $e');
      return const TimeOfDay(hour: 22, minute: 0);
    }
  }

  Future<void> setEndTime(int hour, int minute) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_endHourKey, hour);
      await prefs.setInt(_endMinuteKey, minute);
    } catch (e) {
      debugPrint('NotificationSettingsService.setEndTime failed: $e');
    }
  }

  // ── 제외할 미션 타입 ──

  Future<Set<String>> getExcludedMissionTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_excludedTypesKey) ?? '';
      if (str.isEmpty) return {};
      return str.split(',').where((s) => s.isNotEmpty).toSet();
    } catch (e) {
      debugPrint('NotificationSettingsService.getExcludedMissionTypes failed: $e');
      return {};
    }
  }

  Future<void> setExcludedMissionTypes(Set<String> types) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_excludedTypesKey, types.join(','));
    } catch (e) {
      debugPrint('NotificationSettingsService.setExcludedMissionTypes failed: $e');
    }
  }
}
