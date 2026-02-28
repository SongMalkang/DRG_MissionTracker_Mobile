import 'dart:convert';
import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mission_model.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';

/// 알림 서비스 (싱글톤)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifPlugin =
      FlutterLocalNotificationsPlugin();

  // ── 초기화 ──────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifPlugin.initialize(initSettings);
  }

  // ── 권한 요청 (Android 13+) ─────────────────────────────────────────────
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    return await Permission.notification.isGranted;
  }

  // ── 알람 스케줄 등록 ──────────────────────────────────────────────────────
  Future<void> scheduleAlarms() async {
    // 먼저 기존 알람 전부 취소
    await cancelAllAlarms();

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_enabled') ?? false;
    if (!enabled) return;

    final daysStr = prefs.getString('notif_days') ?? '1,2,3,4,5,6,7';
    final days = daysStr
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => int.parse(s))
        .toList();
    final hour = prefs.getInt('notif_time_hour') ?? 18;
    final minute = prefs.getInt('notif_time_minute') ?? 0;

    if (days.isEmpty) return;

    for (final day in days) {
      final nextDateTime = _nextOccurrence(day, hour, minute);
      await AndroidAlarmManager.oneShotAt(
        nextDateTime,
        day, // 알람 ID = 요일 번호
        alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
      debugPrint(
          'NotificationService: 알람 등록 day=$day → $nextDateTime');
    }
  }

  // ── 모든 알람 취소 ──────────────────────────────────────────────────────
  Future<void> cancelAllAlarms() async {
    for (int day = 1; day <= 7; day++) {
      await AndroidAlarmManager.cancel(day);
    }
    debugPrint('NotificationService: 모든 알람 취소됨');
  }

  // ── 다음 발화 시각 계산 ──────────────────────────────────────────────────
  DateTime _nextOccurrence(int targetDay, int hour, int minute) {
    final now = DateTime.now();
    // targetDay: 1=월 ~ 7=일, DateTime.weekday도 같은 체계
    int daysUntil = targetDay - now.weekday;
    if (daysUntil < 0) daysUntil += 7;
    if (daysUntil == 0) {
      final todayTarget =
          DateTime(now.year, now.month, now.day, hour, minute);
      if (todayTarget.isAfter(now)) {
        return todayTarget;
      }
      daysUntil = 7;
    }
    final target = DateTime(now.year, now.month, now.day, hour, minute)
        .add(Duration(days: daysUntil));
    return target;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  알람 콜백 (top-level 함수, 별도 Dart isolate에서 실행)
// ═══════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
Future<void> alarmCallback(int alarmId) async {
  try {
    // 1. SharedPreferences에서 설정 로드
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_enabled') ?? false;
    if (!enabled) return;

    final excludedStr = prefs.getString('notif_excluded_types') ?? '';
    final excludedTypes =
        excludedStr.split(',').where((s) => s.isNotEmpty).toSet();
    final lang = prefs.getString('selected_lang') ?? 'KR';

    // 2. 캐시된 미션 JSON 읽기
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${AppConstants.cachedMissionFile}');

    String jsonString;
    if (await file.exists()) {
      jsonString = await file.readAsString();
    } else {
      // 캐시 없으면 네트워크 fetch 시도
      try {
        final response = await http
            .get(Uri.parse(AppConstants.missionDataUrl))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          jsonString = response.body;
          await file.writeAsString(jsonString);
        } else {
          return;
        }
      } catch (_) {
        return;
      }
    }

    // 3. 현재 시간 슬롯 미션 파싱
    final now = DateTime.now().toUtc();
    final timeKey = _formatTimeKey(now);
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final missionList = data[timeKey] as List?;
    if (missionList == null || missionList.isEmpty) return;

    final missions = missionList
        .map((m) => Mission.fromJson(m as Map<String, dynamic>))
        .where((m) => m.buff != null && m.buff!.isNotEmpty)
        .where((m) => !excludedTypes.contains(m.missionType))
        .toList();

    if (missions.isEmpty) return;

    // 4. 알림 표시
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await plugin.initialize(initSettings);

    final body = missions.map((m) {
      final missionName = i18n[lang]?[m.missionType] ?? m.missionType;
      final biomeName = i18n[lang]?[m.biome] ?? m.biome;
      final buffName = i18n[lang]?[m.buff] ?? m.buff ?? '';
      return '$buffName: $missionName ($biomeName)';
    }).join('\n');

    final title = i18n[lang]?['notif_title'] ?? 'Bosco Terminal';

    await plugin.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mission_alerts',
          'Mission Alerts',
          channelDescription: 'Notifications for interesting missions',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );

    // 5. 다음 주 같은 요일로 재예약
    final nextWeek = DateTime.now().add(const Duration(days: 7));
    final hour = prefs.getInt('notif_time_hour') ?? 18;
    final minute = prefs.getInt('notif_time_minute') ?? 0;
    final nextOccurrence = DateTime(
        nextWeek.year, nextWeek.month, nextWeek.day, hour, minute);

    await AndroidAlarmManager.oneShotAt(
      nextOccurrence,
      alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  } catch (e) {
    debugPrint('alarmCallback error: $e');
  }
}

/// MissionService._getTimeKey와 동일 로직 (isolate에서 접근 불가하므로 별도 정의)
String _formatTimeKey(DateTime utcTime) {
  final y = utcTime.year.toString();
  final m = utcTime.month.toString().padLeft(2, '0');
  final d = utcTime.day.toString().padLeft(2, '0');
  final h = utcTime.hour.toString().padLeft(2, '0');
  final min = (utcTime.minute < 30) ? '00' : '30';
  return '$y-$m-${d}T$h:$min:00Z';
}
