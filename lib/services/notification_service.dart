import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

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

// ═══════════════════════════════════════════════════════════════════════════
//  보스코 테마 위트있는 알림 메시지 (언어별 · 5개 변형)
// ═══════════════════════════════════════════════════════════════════════════

const boscoMessages = {
  'KR': {
    'titles': [
      '📡 BOSCO 정찰 보고',
      '⛏️ 미션 컨트롤 수신',
      '🍺 Double XP 발견!',
      '🚀 광부님, 출동 요청!',
      '💎 BOSCO 긴급 전파',
    ],
    'prefixes': [
      'BOSCO가 열심히 정찰한 결과입니다.',
      '미션 컨트롤에서 보너스 미션을 탐지했습니다.',
      'BOSCO가 XP 두 배 구역을 발견했습니다!',
      '지금 출발하면 보너스를 챙길 수 있습니다!',
      '경고: 높은 가치의 미션이 진행 중입니다.',
    ],
  },
  'EN': {
    'titles': [
      '📡 BOSCO Scouting Report',
      '⛏️ Mission Control Incoming',
      '🍺 Double XP Detected!',
      '🚀 Miner, Gear Up!',
      '💎 BOSCO Priority Alert',
    ],
    'prefixes': [
      'BOSCO reporting in. Don\'t miss this!',
      'Mission Control has flagged bonus missions.',
      'BOSCO detected a Double XP zone!',
      'Suit up, miner — bonuses are live!',
      'Warning: High-value missions in progress.',
    ],
  },
  'CN': {
    'titles': [
      '📡 博斯科侦察报告',
      '⛏️ 任务控制收到信号',
      '🍺 发现双倍经验！',
      '🚀 矿工，出发吧！',
      '💎 博斯科紧急通报',
    ],
    'prefixes': [
      '博斯科侦察完毕，不要错过！',
      '任务控制检测到奖励任务。',
      '博斯科发现了双倍经验区域！',
      '穿上装备，矿工——奖励已上线！',
      '警告：高价值任务正在进行中。',
    ],
  },
};

/// 알림 서비스 (싱글톤)
///
/// 알람 ID 체계: day * 100 + slotIdx
///   - day: 1(월) ~ 7(일)
///   - slotIdx: 0(00:00) ~ 47(23:30), 30분 단위
///   - 예) 월요일 18:00 → 1 * 100 + 36 = 136
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
  /// startTime ~ endTime 사이의 30분 슬롯마다 알람 등록
  Future<void> scheduleAlarms() async {
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
    if (days.isEmpty) return;

    final startHour   = prefs.getInt('notif_time_hour') ?? 18;
    final startMinute = prefs.getInt('notif_time_minute') ?? 0;
    final endHour     = prefs.getInt('notif_end_hour') ?? 23;
    final endMinute   = prefs.getInt('notif_end_minute') ?? 0;

    // startTime이 endTime보다 늦으면 단일 알람(startTime)만 등록
    final startSlot = toSlot(startHour, startMinute);
    final endSlot   = toSlot(endHour, endMinute);
    final slots     = startSlot <= endSlot
        ? List.generate(endSlot - startSlot + 1, (i) => startSlot + i)
        : [startSlot]; // 잘못된 범위 → 시작 시간만

    for (final day in days) {
      for (final slot in slots) {
        final h   = slot ~/ 2;
        final min = (slot % 2) * 30;
        final dt  = _nextOccurrence(day, h, min);
        final id  = day * 100 + slot;
        await AndroidAlarmManager.oneShotAt(
          dt,
          id,
          alarmCallback,
          exact: false,
          wakeup: true,
          rescheduleOnReboot: true,
        );
        debugPrint('NotificationService: 알람 등록 day=$day slot=$slot → $dt (id=$id)');
      }
    }
  }

  // ── 테스트 알림 (디버그용) ───────────────────────────────────────────────
  /// 보스코 롱프레스 시 즉시 테스트 알림을 표시한다.
  Future<void> showTestNotification(String lang) async {
    final langMessages = boscoMessages[lang] ?? boscoMessages['EN']!;
    final title  = (langMessages['titles']  as List)[0] as String;
    final prefix = (langMessages['prefixes'] as List)[0] as String;

    final testBody = lang == 'KR'
        ? '$prefix\n• 🧪 이것은 테스트 알림입니다!'
        : lang == 'CN'
            ? '$prefix\n• 🧪 这是测试通知！'
            : '$prefix\n• 🧪 This is a test notification!';

    await _notifPlugin.show(
      99999, // 테스트 전용 ID
      title,
      testBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'mission_alerts',
          'Mission Alerts',
          channelDescription: 'Double XP mission notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('bosco_notification'),
          color: const Color(0xFFFF9800),
          styleInformation: BigTextStyleInformation(
            testBody,
            contentTitle: title,
            summaryText: 'DEBUG TEST',
            htmlFormatBigText: false,
            htmlFormatContentTitle: false,
          ),
        ),
      ),
    );
  }

  // ── 모든 알람 취소 ──────────────────────────────────────────────────────
  Future<void> cancelAllAlarms() async {
    // day 1~7, slot 0~47 → 최대 336개
    for (int day = 1; day <= 7; day++) {
      for (int slot = 0; slot < 48; slot++) {
        await AndroidAlarmManager.cancel(day * 100 + slot);
      }
    }
    debugPrint('NotificationService: 모든 알람 취소됨');
  }

  // ── 다음 발화 시각 계산 ──────────────────────────────────────────────────
  DateTime _nextOccurrence(int targetDay, int hour, int minute) {
    final now = DateTime.now();
    int daysUntil = targetDay - now.weekday;
    if (daysUntil < 0) daysUntil += 7;
    if (daysUntil == 0) {
      final todayTarget =
          DateTime(now.year, now.month, now.day, hour, minute);
      if (todayTarget.isAfter(now)) return todayTarget;
      daysUntil = 7;
    }
    return DateTime(now.year, now.month, now.day, hour, minute)
        .add(Duration(days: daysUntil));
  }
}

/// 30분 슬롯 인덱스: 0(00:00) ~ 47(23:30)
int toSlot(int hour, int minute) => hour * 2 + (minute >= 30 ? 1 : 0);

// ═══════════════════════════════════════════════════════════════════════════
//  알람 콜백 (top-level 함수, 별도 Dart isolate에서 실행)
// ═══════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
Future<void> alarmCallback(int alarmId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_enabled') ?? false;
    if (!enabled) return;

    // alarmId에서 요일·슬롯 디코딩
    final alarmDay  = alarmId ~/ 100;  // 1~7
    final alarmSlot = alarmId % 100;   // 0~47
    final slotHour  = alarmSlot ~/ 2;
    final slotMin   = (alarmSlot % 2) * 30;

    // 현재 설정된 종료 슬롯보다 크면 스킵 (설정이 축소된 경우)
    final endHour   = prefs.getInt('notif_end_hour') ?? 23;
    final endMinute = prefs.getInt('notif_end_minute') ?? 0;
    if (alarmSlot > toSlot(endHour, endMinute)) return;

    // 요일 활성 여부 확인
    final daysStr = prefs.getString('notif_days') ?? '1,2,3,4,5,6,7';
    final days = daysStr
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => int.parse(s))
        .toList();
    if (!days.contains(alarmDay)) return;

    final excludedStr  = prefs.getString('notif_excluded_types') ?? '';
    final excludedTypes = excludedStr.split(',').where((s) => s.isNotEmpty).toSet();
    final lang = prefs.getString('selected_lang') ?? 'KR';

    // 캐시된 미션 JSON 읽기 (없으면 네트워크 fetch)
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${AppConstants.cachedMissionFile}');
    String jsonString;
    if (await file.exists()) {
      jsonString = await file.readAsString();
    } else {
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

    // 현재 30분 슬롯의 미션 파싱
    final now     = DateTime.now().toUtc();
    final timeKey = formatTimeKey(now);
    final data    = json.decode(jsonString) as Map<String, dynamic>;
    final missionList = data[timeKey] as List?;
    if (missionList == null || missionList.isEmpty) return;

    // Double XP(buff != null) + 제외 타입 필터
    final missions = missionList
        .map((m) => Mission.fromJson(m as Map<String, dynamic>))
        .where((m) => m.buff != null && m.buff!.isNotEmpty)
        .where((m) => !excludedTypes.contains(m.missionType))
        .toList();

    if (missions.isEmpty) return;

    // 알림 표시
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings    = InitializationSettings(android: androidSettings);
    await plugin.initialize(initSettings);

    // ── 위트있는 보스코 메시지 선택 (alarmId 기반 결정론적 선택) ──────────
    final langMessages = boscoMessages[lang] ?? boscoMessages['EN']!;
    final titles  = langMessages['titles']  as List;
    final prefixes = langMessages['prefixes'] as List;
    final msgIdx  = alarmId % titles.length;
    final title   = titles[msgIdx] as String;
    final prefix  = prefixes[msgIdx] as String;

    // ── 미션 목록 (최대 5개 표시, 초과 시 "외 N개" 안내) ─────────────────
    final missionLines = StringBuffer();
    final displayCount = missions.length > 5 ? 5 : missions.length;
    for (int i = 0; i < displayCount; i++) {
      final m           = missions[i];
      final missionName = i18n[lang]?[m.missionType] ?? m.missionType;
      final biomeName   = i18n[lang]?[m.biome] ?? m.biome;
      missionLines.writeln('• $missionName  [$biomeName]');
    }
    if (missions.length > 5) {
      final extra = missions.length - 5;
      final extraText = lang == 'KR' ? '외 $extra개 더'
                      : lang == 'CN' ? '以及另外$extra个'
                      : '+ $extra more';
      missionLines.write(extraText);
    }

    final bodyFull    = '$prefix\n${missionLines.toString().trimRight()}';
    final summaryText = i18n[lang]?['notif_summary']
        ?.replaceAll('{n}', '${missions.length}')
        ?? '${missions.length} Double XP';

    // ── 알림 표시 (largeIcon: 보스코, BigText 스타일) ─────────────────────
    await plugin.show(
      alarmId, // 슬롯별 고유 ID → 시간대별로 별도 알림
      title,
      bodyFull,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'mission_alerts',
          'Mission Alerts',
          channelDescription: 'Double XP mission notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('bosco_notification'),
          color: const Color(0xFFFF9800), // 주황 액센트
          styleInformation: BigTextStyleInformation(
            bodyFull,
            contentTitle: title,
            summaryText: summaryText,
            htmlFormatBigText: false,
            htmlFormatContentTitle: false,
          ),
        ),
      ),
    );

    // 다음 주 같은 요일·시간으로 재예약
    final nextWeek = DateTime.now().add(const Duration(days: 7));
    final nextOccurrence = DateTime(
        nextWeek.year, nextWeek.month, nextWeek.day, slotHour, slotMin);
    await AndroidAlarmManager.oneShotAt(
      nextOccurrence,
      alarmId,
      alarmCallback,
      exact: false,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  } catch (e) {
    debugPrint('alarmCallback error: $e');
  }
}


String formatTimeKey(DateTime utcTime) {
  final y   = utcTime.year.toString();
  final m   = utcTime.month.toString().padLeft(2, '0');
  final d   = utcTime.day.toString().padLeft(2, '0');
  final h   = utcTime.hour.toString().padLeft(2, '0');
  final min = (utcTime.minute < 30) ? '00' : '30';
  return '$y-$m-${d}T$h:$min:00Z';
}
