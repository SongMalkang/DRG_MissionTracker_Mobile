/// 웹 빌드용 stub: Android 전용 초기화를 no-op 처리
Future<void> platformInit() async {
  // 웹에서는 AlarmManager / NotificationService 사용 불가 → 아무것도 안 함
}
