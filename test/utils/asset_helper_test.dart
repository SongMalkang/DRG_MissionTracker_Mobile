import 'package:flutter_test/flutter_test.dart';
import 'package:drg_mission_tracker/utils/asset_helper.dart';

void main() {
  group('AssetHelper.getBiomeImage', () {
    test('converts biome name to snake_case path', () {
      expect(
        AssetHelper.getBiomeImage('Azure Weald'),
        'assets/images/biomes/azure_weald.png',
      );
    });

    test('handles hyphens', () {
      expect(
        AssetHelper.getBiomeImage('Radioactive Exclusion Zone'),
        'assets/images/biomes/radioactive_exclusion_zone.png',
      );
    });

    test('handles apostrophes', () {
      // Hypothetical biome name with apostrophe
      expect(
        AssetHelper.getBiomeImage("Miner's Haven"),
        "assets/images/biomes/miners_haven.png",
      );
    });
  });

  group('AssetHelper.getMissionIcon', () {
    test('converts mission type to path', () {
      expect(
        AssetHelper.getMissionIcon('Mining Expedition'),
        'assets/images/missions/mining_expedition.png',
      );
    });

    test('handles multi-word types', () {
      expect(
        AssetHelper.getMissionIcon('On-Site Refining'),
        'assets/images/missions/on_site_refining.png',
      );
    });
  });

  group('AssetHelper.getMutatorIcon', () {
    test('converts mutator name to path', () {
      expect(
        AssetHelper.getMutatorIcon('Double XP'),
        'assets/icons/mutators/double_xp.png',
      );
    });
  });

  group('AssetHelper.getWarningIcon', () {
    test('converts single warning to path', () {
      expect(
        AssetHelper.getWarningIcon('Swarmageddon'),
        'assets/icons/warnings/swarmageddon.png',
      );
    });

    test('uses first warning when comma-separated', () {
      expect(
        AssetHelper.getWarningIcon('Cave Leech Cluster, Parasites'),
        'assets/icons/warnings/cave_leech_cluster.png',
      );
    });
  });

  group('AssetHelper.getSecondaryIcon', () {
    test('converts secondary objective to path', () {
      expect(
        AssetHelper.getSecondaryIcon('Fossils'),
        'assets/icons/secondary/fossils.png',
      );
    });
  });
}
