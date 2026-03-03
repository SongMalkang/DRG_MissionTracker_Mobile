import 'package:flutter_test/flutter_test.dart';
import 'package:drg_mission_tracker/services/update_service.dart';

void main() {
  group('UpdateService._compareVersions', () {
    // _compareVersions는 static이므로 직접 접근 가능하게 래핑
    int compare(String v1, String v2) => UpdateService.compareVersions(v1, v2);

    test('동일 버전 → 0', () {
      expect(compare('1.0.0', '1.0.0'), 0);
      expect(compare('2.5.3', '2.5.3'), 0);
    });

    test('v1 > v2 → 양수', () {
      expect(compare('1.1.0', '1.0.0'), greaterThan(0));
      expect(compare('2.0.0', '1.9.9'), greaterThan(0));
      expect(compare('1.0.1', '1.0.0'), greaterThan(0));
    });

    test('v1 < v2 → 음수', () {
      expect(compare('1.0.0', '1.1.0'), lessThan(0));
      expect(compare('1.0.0', '2.0.0'), lessThan(0));
      expect(compare('1.2.0', '1.2.1'), lessThan(0));
    });

    test('짧은 버전 문자열 처리', () {
      expect(compare('1', '1.0.0'), 0);
      expect(compare('1.2', '1.2.0'), 0);
      expect(compare('2', '1.9.9'), greaterThan(0));
    });

    test('주요 버전 변경', () {
      expect(compare('1.2.0', '1.1.0'), greaterThan(0));
      expect(compare('1.0.0', '1.0.1'), lessThan(0));
    });
  });
}
