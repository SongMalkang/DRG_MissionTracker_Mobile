import '../services/notification_service.dart';

/// 네이티브(Android)용 알림 헬퍼: NotificationService에 위임

Future<bool> requestNotificationPermission() async {
  return NotificationService().requestPermission();
}

Future<void> scheduleNotificationAlarms() async {
  await NotificationService().scheduleAlarms();
}

Future<void> cancelAllNotificationAlarms() async {
  await NotificationService().cancelAllAlarms();
}
