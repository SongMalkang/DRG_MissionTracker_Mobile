import '../services/web_notification_service.dart';

/// 웹용 알림 헬퍼: Web Notification API에 위임

Future<bool> requestNotificationPermission() async {
  return WebNotificationService().requestPermission();
}

Future<void> scheduleNotificationAlarms() async {
  await WebNotificationService().scheduleAlarms();
}

Future<void> cancelAllNotificationAlarms() async {
  await WebNotificationService().cancelAllAlarms();
}
