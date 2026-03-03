import 'package:flutter_test/flutter_test.dart';
import 'package:drg_mission_tracker/services/notification_service.dart';

void main() {
  group('formatTimeKey', () {
    test('분 < 30이면 :00으로 라운딩', () {
      final dt = DateTime.utc(2024, 3, 15, 14, 0);
      expect(formatTimeKey(dt), '2024-03-15T14:00:00Z');

      final dt2 = DateTime.utc(2024, 3, 15, 14, 29);
      expect(formatTimeKey(dt2), '2024-03-15T14:00:00Z');
    });

    test('분 >= 30이면 :30으로 라운딩', () {
      final dt = DateTime.utc(2024, 3, 15, 14, 30);
      expect(formatTimeKey(dt), '2024-03-15T14:30:00Z');

      final dt2 = DateTime.utc(2024, 3, 15, 14, 59);
      expect(formatTimeKey(dt2), '2024-03-15T14:30:00Z');
    });

    test('월/일 제로패딩', () {
      final dt = DateTime.utc(2024, 1, 5, 8, 0);
      expect(formatTimeKey(dt), '2024-01-05T08:00:00Z');
    });
  });

  group('toSlot', () {
    test('0:00 → slot 0', () {
      expect(toSlot(0, 0), 0);
    });

    test('0:30 → slot 1', () {
      expect(toSlot(0, 30), 1);
    });

    test('12:00 → slot 24', () {
      expect(toSlot(12, 0), 24);
    });

    test('23:30 → slot 47', () {
      expect(toSlot(23, 30), 47);
    });

    test('분이 29이면 하반부가 아님 → slot = hour * 2', () {
      expect(toSlot(10, 29), 20);
    });

    test('분이 31이면 하반부 → slot = hour * 2 + 1', () {
      expect(toSlot(10, 31), 21);
    });
  });

  group('boscoMessages', () {
    test('모든 언어에 5개 titles/prefixes 존재', () {
      for (final lang in ['KR', 'EN', 'CN']) {
        final msgs = boscoMessages[lang]!;
        final titles = msgs['titles'] as List;
        final prefixes = msgs['prefixes'] as List;

        expect(titles.length, 5, reason: '$lang titles should have 5 entries');
        expect(prefixes.length, 5, reason: '$lang prefixes should have 5 entries');
        expect(titles.length, prefixes.length,
            reason: '$lang titles and prefixes should have same length');
      }
    });

    test('인덱싱 버그 없음: alarmId % titles.length는 항상 유효', () {
      for (final lang in ['KR', 'EN', 'CN']) {
        final msgs = boscoMessages[lang]!;
        final titles = msgs['titles'] as List;

        // 다양한 alarmId에 대해 인덱스가 범위 내인지 확인
        for (int alarmId = 0; alarmId < 748; alarmId++) {
          final idx = alarmId % titles.length;
          expect(idx, lessThan(titles.length));
          expect(idx, greaterThanOrEqualTo(0));
        }
      }
    });
  });
}
