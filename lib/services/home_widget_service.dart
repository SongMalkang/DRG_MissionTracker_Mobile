import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import 'mission_service.dart';

class HomeWidgetService {
  static const _androidSmall = 'SmallWidgetProvider';
  static const _androidMedium = 'MediumWidgetProvider';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId('com.songmalkang.drg_mission_tracker');
  }

  /// MissionService 갱신 후 호출 — 위젯 데이터 갱신
  static Future<void> updateWidget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('selected_lang') ?? 'KR';
      final ms = MissionService();

      if (!ms.isInitialized) return;

      final now = DateTime.now().toUtc();
      final missions = ms.getMissionsForTime(now);
      final doubleXpMissions =
          missions.where((m) => m.buff == 'Double XP').toList();

      // 다음 로테이션까지 남은 시간
      final next30 = (now.minute < 30) ? 30 : 60;
      final target =
          DateTime.utc(now.year, now.month, now.day, now.hour, next30);
      final secondsLeft = target.difference(now).inSeconds;
      final mm = (secondsLeft ~/ 60).toString().padLeft(2, '0');
      final ss = (secondsLeft % 60).toString().padLeft(2, '0');

      // 미션 요약 (최대 3개)
      final summary = StringBuffer();
      final count =
          doubleXpMissions.length > 3 ? 3 : doubleXpMissions.length;
      for (int i = 0; i < count; i++) {
        final m = doubleXpMissions[i];
        final mType = t(m.missionType, lang);
        final biome = t(m.biome, lang);
        if (i > 0) summary.write('\n');
        summary.write('$mType \u00b7 $biome');
      }
      if (doubleXpMissions.length > 3) {
        summary.write('\n+${doubleXpMissions.length - 3}');
      }

      // SharedPreferences에 저장
      await HomeWidget.saveWidgetData(
          AppConstants.widgetTitle, t('widget_title', lang));
      await HomeWidget.saveWidgetData(
          AppConstants.widgetDoubleXpCount, doubleXpMissions.length);
      await HomeWidget.saveWidgetData(
          AppConstants.widgetMissionSummary, summary.toString());
      await HomeWidget.saveWidgetData(
          AppConstants.widgetNextRotation, '$mm:$ss');
      await HomeWidget.saveWidgetData(
          AppConstants.widgetLastUpdate, DateTime.now().toIso8601String());
      await HomeWidget.saveWidgetData(
          AppConstants.widgetNoDoubleXp, t('widget_no_xp', lang));

      // 위젯 갱신 트리거
      await HomeWidget.updateWidget(androidName: _androidSmall);
      await HomeWidget.updateWidget(androidName: _androidMedium);
    } catch (e) {
      // 위젯 업데이트 실패는 앱 기능에 영향 없음 — 무시
    }
  }
}
