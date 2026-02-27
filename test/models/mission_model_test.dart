import 'package:flutter_test/flutter_test.dart';
import 'package:drg_mission_tracker/models/mission_model.dart';

void main() {
  group('Mission.fromJson', () {
    test('parses complete JSON correctly', () {
      final json = {
        'b': 'Azure Weald',
        't': 'Mining Expedition',
        'so': 'Fossils',
        'cn': 'Jolly Descent',
        'l': 2,
        'c': 3,
        'bf': 'Double XP',
        'df': 'Cave Leech Cluster',
        's': ['s0', 's3'],
      };

      final mission = Mission.fromJson(json);

      expect(mission.biome, 'Azure Weald');
      expect(mission.missionType, 'Mining Expedition');
      expect(mission.secondaryObjective, 'Fossils');
      expect(mission.codeName, 'Jolly Descent');
      expect(mission.length, 2);
      expect(mission.complexity, 3);
      expect(mission.buff, 'Double XP');
      expect(mission.debuff, 'Cave Leech Cluster');
      expect(mission.seasons, ['s0', 's3']);
    });

    test('handles null optional fields', () {
      final json = {
        'b': 'Magma Core',
        't': 'Egg Hunt',
        'l': 1,
        'c': 1,
        's': ['s0'],
      };

      final mission = Mission.fromJson(json);

      expect(mission.biome, 'Magma Core');
      expect(mission.missionType, 'Egg Hunt');
      expect(mission.secondaryObjective, isNull);
      expect(mission.codeName, isNull);
      expect(mission.buff, isNull);
      expect(mission.debuff, isNull);
    });

    test('handles missing required fields with defaults', () {
      final json = <String, dynamic>{};

      final mission = Mission.fromJson(json);

      expect(mission.biome, '');
      expect(mission.missionType, '');
      expect(mission.length, 1);
      expect(mission.complexity, 1);
      expect(mission.seasons, isEmpty);
    });

    test('handles empty seasons list', () {
      final json = {
        'b': 'Salt Pits',
        't': 'Elimination',
        'l': 2,
        'c': 2,
        's': <String>[],
      };

      final mission = Mission.fromJson(json);
      expect(mission.seasons, isEmpty);
    });
  });

  group('Mission properties', () {
    test('default timeWindow and isPast', () {
      final mission = Mission(
        biome: 'test',
        missionType: 'test',
        length: 1,
        complexity: 1,
      );

      expect(mission.timeWindow, '');
      expect(mission.isPast, false);
    });

    test('Double XP detection via buff field', () {
      final dxp = Mission(
        biome: 'test',
        missionType: 'test',
        length: 1,
        complexity: 1,
        buff: 'Double XP',
      );
      final normal = Mission(
        biome: 'test',
        missionType: 'test',
        length: 1,
        complexity: 1,
        buff: 'Gold Rush',
      );
      final noBuff = Mission(
        biome: 'test',
        missionType: 'test',
        length: 1,
        complexity: 1,
      );

      expect(dxp.buff, 'Double XP');
      expect(normal.buff, isNot('Double XP'));
      expect(noBuff.buff, isNull);
    });
  });
}
