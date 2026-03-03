import 'package:flutter_test/flutter_test.dart';
import 'package:drg_mission_tracker/services/deep_dive_service.dart';

void main() {
  group('DeepDiveStage.fromJson', () {
    test('올바른 JSON 파싱', () {
      final json = {
        'PrimaryObjective': 'Mining Expedition',
        'SecondaryObjective': 'Fossils',
        'MissionWarnings': ['Cave Leech Cluster'],
        'Complexity': '2',
        'Length': '3',
      };

      final stage = DeepDiveStage.fromJson(1, json);

      expect(stage.num, 1);
      expect(stage.primary, 'Mining Expedition');
      expect(stage.secondary, 'Fossils');
      expect(stage.warning, 'Cave Leech Cluster');
      expect(stage.complexity, 2);
      expect(stage.length, 3);
    });

    test('경고 없는 스테이지', () {
      final json = {
        'PrimaryObjective': 'Egg Hunt',
        'SecondaryObjective': null,
        'MissionWarnings': [],
        'Complexity': '1',
        'Length': '1',
      };

      final stage = DeepDiveStage.fromJson(2, json);

      expect(stage.warning, isNull);
      expect(stage.secondary, isNull);
    });

    test('MissionWarnings 없을 때', () {
      final json = {
        'PrimaryObjective': 'Escort Duty',
        'Complexity': '3',
        'Length': '2',
      };

      final stage = DeepDiveStage.fromJson(3, json);
      expect(stage.warning, isNull);
    });

    test('기본값 처리 (비어있는 JSON)', () {
      final json = <String, dynamic>{};
      final stage = DeepDiveStage.fromJson(1, json);

      expect(stage.primary, '');
      expect(stage.complexity, 1);
      expect(stage.length, 1);
    });
  });

  group('DeepDiveService', () {
    test('nextThursday는 미래 시간을 반환', () {
      final service = DeepDiveService();
      final nextThu = service.nextThursday();

      expect(nextThu.isAfter(DateTime.now().toUtc()), isTrue);
      expect(nextThu.weekday, DateTime.thursday);
    });

    test('parseDiveData - 올바른 JSON 파싱', () {
      const jsonBody = '''
{
  "Deep Dives": {
    "Deep Dive Normal": {
      "Biome": "Azure Weald",
      "CodeName": "Test Dive",
      "Stages": [
        {
          "PrimaryObjective": "Mining Expedition",
          "SecondaryObjective": "Fossils",
          "MissionWarnings": ["Cave Leech Cluster"],
          "Complexity": "2",
          "Length": "2"
        },
        {
          "PrimaryObjective": "Egg Hunt",
          "SecondaryObjective": null,
          "MissionWarnings": [],
          "Complexity": "2",
          "Length": "3"
        }
      ]
    },
    "Deep Dive Elite": {
      "Biome": "Magma Core",
      "CodeName": "Elite Test",
      "Stages": [
        {
          "PrimaryObjective": "Escort Duty",
          "SecondaryObjective": "Morkite",
          "MissionWarnings": ["Swarmageddon"],
          "Complexity": "3",
          "Length": "3"
        }
      ]
    }
  }
}''';

      final dives = DeepDiveService.parseDiveDataPublic(jsonBody);

      expect(dives.length, 2);

      // Normal dive
      expect(dives[0].isElite, false);
      expect(dives[0].biome, 'Azure Weald');
      expect(dives[0].codeName, 'Test Dive');
      expect(dives[0].stages.length, 2);
      expect(dives[0].stages[0].primary, 'Mining Expedition');
      expect(dives[0].stages[1].warning, isNull);

      // Elite dive
      expect(dives[1].isElite, true);
      expect(dives[1].biome, 'Magma Core');
      expect(dives[1].stages[0].warning, 'Swarmageddon');
    });

    test('parseDiveData - Deep Dives 키 없으면 예외', () {
      const jsonBody = '{"other_key": {}}';

      expect(
        () => DeepDiveService.parseDiveDataPublic(jsonBody),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
