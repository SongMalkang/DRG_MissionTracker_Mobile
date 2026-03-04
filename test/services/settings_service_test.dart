import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drg_mission_tracker/services/settings_service.dart';

void main() {
  group('SettingsService', () {
    late SettingsService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = SettingsService();
    });

    test('getLanguage 기본값은 기기 로케일 기반 (저장 없을 때)', () async {
      final lang = await service.getLanguage();
      // 테스트 환경에서는 기기 로케일에 따라 다를 수 있지만, 유효한 값이어야 함
      expect(['KR', 'EN', 'CN'], contains(lang));
    });

    test('saveLanguage + getLanguage 라운드트립', () async {
      await service.saveLanguage('CN');
      final lang = await service.getLanguage();
      expect(lang, 'CN');
    });

    test('getSeason 기본값은 s6', () async {
      final season = await service.getSeason();
      expect(season, 's6');
    });

    test('saveSeason + getSeason 라운드트립', () async {
      await service.saveSeason('s0');
      final season = await service.getSeason();
      expect(season, 's0');
    });

    test('getShowWarnings 기본값은 true', () async {
      final show = await service.getShowWarnings();
      expect(show, true);
    });

    test('saveShowWarnings + getShowWarnings 라운드트립', () async {
      await service.saveShowWarnings(false);
      final show = await service.getShowWarnings();
      expect(show, false);
    });
  });
}
