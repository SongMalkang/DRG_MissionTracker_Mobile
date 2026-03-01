// 웹용 알림 stub: Android 전용 알림 기능을 no-op 처리

Future<bool> requestNotificationPermission() async => false;

Future<void> scheduleNotificationAlarms() async {}

Future<void> cancelAllNotificationAlarms() async {}
