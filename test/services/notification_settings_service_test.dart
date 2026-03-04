import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drg_mission_tracker/services/notification_settings_service.dart';

void main() {
  group('NotificationSettingsService', () {
    late NotificationSettingsService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = NotificationSettingsService();
    });

    test('isEnabled 기본값은 false', () async {
      final enabled = await service.isEnabled();
      expect(enabled, false);
    });

    test('setEnabled + isEnabled 라운드트립', () async {
      await service.setEnabled(true);
      final enabled = await service.isEnabled();
      expect(enabled, true);
    });

    test('getEnabledDays 기본값은 모든 요일 (1~7)', () async {
      final days = await service.getEnabledDays();
      expect(days, [1, 2, 3, 4, 5, 6, 7]);
    });

    test('setEnabledDays + getEnabledDays 라운드트립', () async {
      await service.setEnabledDays([1, 3, 5]);
      final days = await service.getEnabledDays();
      expect(days, [1, 3, 5]);
    });

    test('getScheduledTime 기본값은 19:00', () async {
      final time = await service.getScheduledTime();
      expect(time.hour, 19);
      expect(time.minute, 0);
    });

    test('setScheduledTime + getScheduledTime 라운드트립', () async {
      await service.setScheduledTime(8, 30);
      final time = await service.getScheduledTime();
      expect(time.hour, 8);
      expect(time.minute, 30);
    });

    test('getEndTime 기본값은 22:00', () async {
      final time = await service.getEndTime();
      expect(time.hour, 22);
      expect(time.minute, 0);
    });

    test('setEndTime + getEndTime 라운드트립', () async {
      await service.setEndTime(23, 45);
      final time = await service.getEndTime();
      expect(time.hour, 23);
      expect(time.minute, 45);
    });

    test('getExcludedMissionTypes 기본값은 빈 Set', () async {
      final types = await service.getExcludedMissionTypes();
      expect(types, isEmpty);
    });

    test('setExcludedMissionTypes + getExcludedMissionTypes 라운드트립', () async {
      await service.setExcludedMissionTypes({'Mining Expedition', 'Egg Hunt'});
      final types = await service.getExcludedMissionTypes();
      expect(types, containsAll(['Mining Expedition', 'Egg Hunt']));
      expect(types.length, 2);
    });
  });
}
