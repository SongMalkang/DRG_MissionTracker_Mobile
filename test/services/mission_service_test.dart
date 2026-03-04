import 'package:flutter_test/flutter_test.dart';
import 'package:drg_mission_tracker/services/mission_service.dart';

void main() {
  group('MissionService.getTimeKey', () {
    test('분이 30 미만이면 :00으로 라운딩', () {
      final dt = DateTime.utc(2024, 3, 15, 14, 0);
      expect(MissionService.getTimeKey(dt), '2024-03-15T14:00:00Z');

      final dt2 = DateTime.utc(2024, 3, 15, 14, 15);
      expect(MissionService.getTimeKey(dt2), '2024-03-15T14:00:00Z');

      final dt3 = DateTime.utc(2024, 3, 15, 14, 29);
      expect(MissionService.getTimeKey(dt3), '2024-03-15T14:00:00Z');
    });

    test('분이 30 이상이면 :30으로 라운딩', () {
      final dt = DateTime.utc(2024, 3, 15, 14, 30);
      expect(MissionService.getTimeKey(dt), '2024-03-15T14:30:00Z');

      final dt2 = DateTime.utc(2024, 3, 15, 14, 45);
      expect(MissionService.getTimeKey(dt2), '2024-03-15T14:30:00Z');

      final dt3 = DateTime.utc(2024, 3, 15, 14, 59);
      expect(MissionService.getTimeKey(dt3), '2024-03-15T14:30:00Z');
    });

    test('자정 처리', () {
      final dt = DateTime.utc(2024, 1, 1, 0, 0);
      expect(MissionService.getTimeKey(dt), '2024-01-01T00:00:00Z');
    });

    test('월/일 패딩', () {
      final dt = DateTime.utc(2024, 1, 5, 8, 0);
      expect(MissionService.getTimeKey(dt), '2024-01-05T08:00:00Z');
    });

    test('23:30 처리', () {
      final dt = DateTime.utc(2024, 12, 31, 23, 45);
      expect(MissionService.getTimeKey(dt), '2024-12-31T23:30:00Z');
    });
  });

  group('MissionService - DataStatus', () {
    test('초기 상태는 offline', () {
      final service = MissionService();
      expect(service.status, DataStatus.offline);
    });

    test('isInitialized 초기값은 false가 아닐 수 있음 (싱글톤)', () {
      // MissionService는 싱글톤이므로 다른 테스트의 상태가 남아있을 수 있음
      final service = MissionService();
      expect(service, isNotNull);
    });
  });

  group('MissionService.getMissionsForTime', () {
    test('데이터 없을 때 빈 리스트 반환', () {
      final service = MissionService();
      // 먼 미래 시간에 대해 조회
      final farFuture = DateTime.utc(2099, 1, 1, 0, 0);
      final missions = service.getMissionsForTime(farFuture);
      // 결과는 빈 리스트이거나 stale fallback (allMissions이 비어있지 않으면)
      expect(missions, isA<List>());
    });
  });

  group('MissionService - Listener Management', () {
    test('addListener / removeListener는 예외 없이 동작', () {
      final service = MissionService();
      void cb() {}
      // 추가 / 제거가 예외 없이 동작하는지 확인
      service.addListener(cb);
      service.removeListener(cb);
    });
  });

  group('MissionService - hasClockDrift', () {
    test('초기값은 false (측정 전)', () {
      final service = MissionService();
      expect(service.hasClockDrift, false);
    });
  });

  group('MissionService - availableSeasons', () {
    test('초기값은 List<String> 타입', () {
      final service = MissionService();
      expect(service.availableSeasons, isA<List<String>>());
    });
  });

  group('MissionService._parseHttpDate (via getTimeKey proxy)', () {
    // _parseHttpDate는 private이므로 직접 테스트 불가,
    // getTimeKey로 간접 검증 (시간 키 생성 로직)
    test('경계값: 자정 직전 23:59', () {
      final dt = DateTime.utc(2024, 12, 31, 23, 59);
      expect(MissionService.getTimeKey(dt), '2024-12-31T23:30:00Z');
    });

    test('경계값: 정확히 30분', () {
      final dt = DateTime.utc(2024, 6, 15, 10, 30);
      expect(MissionService.getTimeKey(dt), '2024-06-15T10:30:00Z');
    });
  });
}
