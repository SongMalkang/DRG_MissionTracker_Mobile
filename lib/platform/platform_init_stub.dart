import '../services/web_notification_service.dart';

/// 웹 빌드용 초기화: Web Notification 서비스 시작
Future<void> platformInit() async {
  await WebNotificationService().initialize();
}
