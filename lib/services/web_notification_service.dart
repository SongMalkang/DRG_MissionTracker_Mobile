import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mission_model.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import 'notification_shared.dart';

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('Notification')
extension type _JsNotification._(JSObject _) implements JSObject {
  external factory _JsNotification(JSString title, [JSObject? options]);

  @JS('permission')
  external static JSString get _permission;

  external static JSPromise<JSString> requestPermission();
}

@JS('navigator.serviceWorker')
external JSObject? get _serviceWorkerContainer;

@JS('navigator.serviceWorker.ready')
external JSPromise<JSObject> get _swReady;

/// 서비스 워커가 등록되어 있는지 확인
bool get _hasSW => _serviceWorkerContainer != null;

/// 웹 알림 서비스 (싱글톤)
///
/// Web Notification API + Service Worker를 사용하여
/// 브라우저/PWA에서 Double XP 미션 알림을 표시한다.
///
/// 동작 방식:
///   - 앱이 열려있는 동안 30분마다 미션 데이터를 확인
///   - Double XP 미션 발견 시 Web Notification API로 알림 표시
///   - Service Worker를 통해 백그라운드 탭에서도 알림 표시 가능
class WebNotificationService {
  static final WebNotificationService _instance =
      WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  Timer? _checkTimer;
  bool _initialized = false;

  /// 서비스 초기화: 타이머 설정
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_enabled') ?? false;
    if (enabled) {
      _startPeriodicCheck();
    }
  }

  /// 알림 권한 요청
  Future<bool> requestPermission() async {
    try {
      final result =
          (await _JsNotification.requestPermission().toDart).toDart;
      return result == 'granted';
    } catch (e) {
      debugPrint('WebNotificationService: permission request failed: $e');
      return false;
    }
  }

  /// 현재 권한 상태 확인
  bool get hasPermission {
    try {
      return _JsNotification._permission.toDart == 'granted';
    } catch (_) {
      return false;
    }
  }

  /// 알림 스케줄 시작 (30분 간격 체크)
  Future<void> scheduleAlarms() async {
    _startPeriodicCheck();
  }

  /// 모든 알림 스케줄 취소
  Future<void> cancelAllAlarms() async {
    _stopPeriodicCheck();
  }

  /// 테스트 알림 표시
  Future<void> showTestNotification(String lang) async {
    final langMessages = boscoMessages[lang] ?? boscoMessages['EN']!;
    final title = (langMessages['titles'] as List)[0] as String;
    final prefix = (langMessages['prefixes'] as List)[0] as String;

    final testBody = lang == 'KR'
        ? '$prefix\n• 🧪 이것은 테스트 알림입니다!'
        : lang == 'CN'
            ? '$prefix\n• 🧪 这是测试通知！'
            : '$prefix\n• 🧪 This is a test notification!';

    await _showNotification(title, testBody, tag: 'bosco-test');
  }

  // ── 내부 구현 ─────────────────────────────────────────────────────────────

  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    // 다음 정각(00분) 또는 반(30분)에 맞춰 타이머 시작
    final now = DateTime.now();
    final nextMin = now.minute < 30 ? 30 : 60;
    final delayMinutes = nextMin - now.minute;
    final initialDelay = Duration(
      minutes: delayMinutes,
      seconds: -now.second, // 정확히 00초에 맞춤
    );

    if (initialDelay.isNegative || initialDelay == Duration.zero) {
      // 이미 정각/반이면 즉시 체크 후 30분 주기
      _checkMissions();
      _checkTimer = Timer.periodic(
        const Duration(minutes: 30),
        (_) => _checkMissions(),
      );
    } else {
      // 다음 정각/반까지 대기 후 체크, 이후 30분 주기
      _checkTimer = Timer(initialDelay, () {
        _checkMissions();
        _checkTimer = Timer.periodic(
          const Duration(minutes: 30),
          (_) => _checkMissions(),
        );
      });
    }
    debugPrint('WebNotificationService: periodic check started '
        '(next check in ${initialDelay.inSeconds}s)');
  }

  void _stopPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
    debugPrint('WebNotificationService: periodic check stopped');
  }

  Future<void> _checkMissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notif_enabled') ?? false;
      if (!enabled) return;

      // 현재 시간이 설정된 알림 시간 범위 내인지 확인
      final now = DateTime.now();
      final currentDay = now.weekday; // 1(월) ~ 7(일)

      final daysStr = prefs.getString('notif_days') ?? '1,2,3,4,5,6,7';
      final days = daysStr
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s))
          .toList();
      if (!days.contains(currentDay)) return;

      final startHour = prefs.getInt('notif_time_hour') ?? 19;
      final startMinute = prefs.getInt('notif_time_minute') ?? 0;
      final endHour = prefs.getInt('notif_end_hour') ?? 22;
      final endMinute = prefs.getInt('notif_end_minute') ?? 0;

      final currentSlot = toSlot(now.hour, now.minute);
      final startSlot = toSlot(startHour, startMinute);
      final endSlot = toSlot(endHour, endMinute);

      if (startSlot <= endSlot) {
        if (currentSlot < startSlot || currentSlot > endSlot) return;
      } else {
        // 잘못된 범위 → startSlot만 체크
        if (currentSlot != startSlot) return;
      }

      // 미션 데이터 fetch
      final excludedStr = prefs.getString('notif_excluded_types') ?? '';
      final excludedTypes =
          excludedStr.split(',').where((s) => s.isNotEmpty).toSet();
      final lang = prefs.getString('selected_lang') ?? 'KR';

      String jsonString;
      try {
        final response = await http
            .get(Uri.parse(AppConstants.missionDataUrl))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          jsonString = response.body;
        } else {
          return;
        }
      } catch (_) {
        return;
      }

      // 현재 시간 키의 미션 파싱
      final utcNow = DateTime.now().toUtc();
      final timeKey = formatTimeKey(utcNow);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final missionList = data[timeKey] as List?;
      if (missionList == null || missionList.isEmpty) return;

      // Double XP + 제외 타입 필터
      final missions = missionList
          .map((m) => Mission.fromJson(m as Map<String, dynamic>))
          .where((m) => m.buff == 'Double XP')
          .where((m) => !excludedTypes.contains(m.missionType))
          .toList();

      if (missions.isEmpty) return;

      // 중복 알림 방지: 같은 timeKey로 이미 알림을 보냈으면 스킵
      final lastNotifKey = prefs.getString('web_last_notif_key') ?? '';
      if (lastNotifKey == timeKey) return;
      await prefs.setString('web_last_notif_key', timeKey);

      // 보스코 메시지 선택
      final langMessages = boscoMessages[lang] ?? boscoMessages['EN']!;
      final titles = langMessages['titles'] as List;
      final prefixes = langMessages['prefixes'] as List;
      final msgIdx = currentSlot % titles.length;
      final title = titles[msgIdx] as String;
      final prefix = prefixes[msgIdx] as String;

      // 미션 목록 (최대 5개)
      final missionLines = StringBuffer();
      final displayCount = missions.length > 5 ? 5 : missions.length;
      for (int i = 0; i < displayCount; i++) {
        final m = missions[i];
        final missionName = i18n[lang]?[m.missionType] ?? m.missionType;
        final biomeName = i18n[lang]?[m.biome] ?? m.biome;
        missionLines.writeln('• $missionName  [$biomeName]');
      }
      if (missions.length > 5) {
        final extra = missions.length - 5;
        final extraText = lang == 'KR'
            ? '외 $extra개 더'
            : lang == 'CN'
                ? '以及另外$extra个'
                : '+ $extra more';
        missionLines.write(extraText);
      }

      final bodyFull = '$prefix\n${missionLines.toString().trimRight()}';
      await _showNotification(title, bodyFull,
          tag: 'bosco-dxp-$timeKey');
    } catch (e) {
      debugPrint('WebNotificationService: check failed: $e');
    }
  }

  /// Web Notification 표시 (Service Worker 경유 우선)
  Future<void> _showNotification(String title, String body,
      {String? tag}) async {
    if (!hasPermission) return;

    // Service Worker를 통해 알림 표시 (백그라운드 탭 지원)
    if (_hasSW) {
      try {
        final sw = await _swReady.toDart;
        final message = <String, dynamic>{
          'type': 'SHOW_NOTIFICATION',
          'title': title,
          'body': body,
          'tag': tag ?? 'bosco-mission-alert',
        }.jsify();
        final active = sw.getProperty<JSObject?>('active'.toJS);
        if (active != null) {
          active.callMethod('postMessage'.toJS, message);
          return;
        }
      } catch (e) {
        debugPrint('WebNotificationService: SW notification failed: $e');
      }
    }

    // Fallback: 직접 Notification API 사용 (포그라운드 전용)
    try {
      final options = <String, dynamic>{
        'body': body,
        'icon': 'icons/Icon-192.png',
        'tag': tag ?? 'bosco-mission-alert',
      }.jsify() as JSObject;
      _JsNotification(title.toJS, options);
    } catch (e) {
      debugPrint('WebNotificationService: direct notification failed: $e');
    }
  }
}
