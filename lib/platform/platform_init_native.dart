import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../services/notification_service.dart';
import '../services/home_widget_service.dart';

/// 네이티브(Android) 빌드: AlarmManager + NotificationService + HomeWidget 초기화
Future<void> platformInit() async {
  await AndroidAlarmManager.initialize();
  await NotificationService().initialize();
  await HomeWidgetService.initialize();
}
