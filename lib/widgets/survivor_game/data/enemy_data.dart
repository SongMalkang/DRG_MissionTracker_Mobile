class HazardConfig {
  final int level;
  final String name;
  final double hpMultiplier;
  final double speedMultiplier;
  final double spawnMultiplier;
  final double playerDamageMultiplier;
  final double scoreMultiplier;

  const HazardConfig({
    required this.level,
    required this.name,
    required this.hpMultiplier,
    required this.speedMultiplier,
    required this.spawnMultiplier,
    required this.playerDamageMultiplier,
    required this.scoreMultiplier,
  });
}

const List<HazardConfig> hazardLevels = [
  HazardConfig(level: 1, name: 'Low Risk', hpMultiplier: 0.6, speedMultiplier: 0.8, spawnMultiplier: 0.7, playerDamageMultiplier: 0.7, scoreMultiplier: 0.5),
  HazardConfig(level: 2, name: 'Moderate', hpMultiplier: 0.8, speedMultiplier: 0.9, spawnMultiplier: 0.85, playerDamageMultiplier: 0.85, scoreMultiplier: 0.75),
  HazardConfig(level: 3, name: 'Dangerous', hpMultiplier: 1.0, speedMultiplier: 1.0, spawnMultiplier: 1.0, playerDamageMultiplier: 1.0, scoreMultiplier: 1.0),
  HazardConfig(level: 4, name: 'Extreme', hpMultiplier: 1.3, speedMultiplier: 1.15, spawnMultiplier: 1.25, playerDamageMultiplier: 1.3, scoreMultiplier: 1.5),
  HazardConfig(level: 5, name: 'Lethal', hpMultiplier: 1.7, speedMultiplier: 1.3, spawnMultiplier: 1.5, playerDamageMultiplier: 1.6, scoreMultiplier: 2.0),
];

enum EnemyType { grunt, swarmer, guard, praetorian, oppressor, dreadnought, bulkDetonator }

class EnemyData {
  final EnemyType type;
  final String name;
  final double hp;
  final double speed;
  final double damage;
  final double radius;
  final bool frontArmor;
  final bool isBoss;
  final double xpDrop;
  final double goldDrop;

  const EnemyData({
    required this.type,
    required this.name,
    required this.hp,
    required this.speed,
    required this.damage,
    required this.radius,
    this.frontArmor = false,
    this.isBoss = false,
    this.xpDrop = 1,
    this.goldDrop = 0,
  });
}

const Map<EnemyType, EnemyData> enemyDataTable = {
  EnemyType.grunt: EnemyData(
    type: EnemyType.grunt,
    name: 'Glyphid Grunt',
    hp: 30,
    speed: 90,
    damage: 10,
    radius: 10,
    xpDrop: 1,
    goldDrop: 1,
  ),
  EnemyType.swarmer: EnemyData(
    type: EnemyType.swarmer,
    name: 'Swarmer',
    hp: 8,
    speed: 162,
    damage: 5,
    radius: 5,
    xpDrop: 0.3,
  ),
  EnemyType.guard: EnemyData(
    type: EnemyType.guard,
    name: 'Glyphid Guard',
    hp: 60,
    speed: 72,
    damage: 15,
    radius: 12,
    frontArmor: true,
    xpDrop: 3,
    goldDrop: 2,
  ),
  EnemyType.praetorian: EnemyData(
    type: EnemyType.praetorian,
    name: 'Praetorian',
    hp: 200,
    speed: 54,
    damage: 30,
    radius: 18,
    frontArmor: true,
    isBoss: true,
    xpDrop: 20,
    goldDrop: 15,
  ),
  EnemyType.oppressor: EnemyData(
    type: EnemyType.oppressor,
    name: 'Oppressor',
    hp: 350,
    speed: 45,
    damage: 40,
    radius: 22,
    frontArmor: true,
    isBoss: true,
    xpDrop: 35,
    goldDrop: 25,
  ),
  EnemyType.dreadnought: EnemyData(
    type: EnemyType.dreadnought,
    name: 'Dreadnought',
    hp: 800,
    speed: 36,
    damage: 50,
    radius: 28,
    isBoss: true,
    xpDrop: 80,
    goldDrop: 50,
  ),
  EnemyType.bulkDetonator: EnemyData(
    type: EnemyType.bulkDetonator,
    name: 'Bulk Detonator',
    hp: 500,
    speed: 27,
    damage: 80,
    radius: 25,
    isBoss: true,
    xpDrop: 50,
    goldDrop: 40,
  ),
};

/// Wave spawn configuration
class WaveConfig {
  final int wave;
  final int gruntCount;
  final double gruntHp;
  final double speedMultiplier;
  final List<SpawnEntry> specials;

  const WaveConfig({
    required this.wave,
    required this.gruntCount,
    required this.gruntHp,
    required this.speedMultiplier,
    this.specials = const [],
  });
}

class SpawnEntry {
  final EnemyType type;
  final int count;
  const SpawnEntry(this.type, this.count);
}

/// Wave table — starts at old Wave 5 intensity, escalates faster.
/// Bosses: Wave 3 (Praetorian), Wave 6 (Oppressor), Wave 10 (Dreadnought).
const List<WaveConfig> waveTable = [
  // Wave 1: immediate action — Grunt rush + Swarmers
  WaveConfig(wave: 1, gruntCount: 20, gruntHp: 40, speedMultiplier: 1.1,
      specials: [SpawnEntry(EnemyType.swarmer, 5)]),
  // Wave 2: Guards appear
  WaveConfig(wave: 2, gruntCount: 24, gruntHp: 45, speedMultiplier: 1.2,
      specials: [SpawnEntry(EnemyType.guard, 2), SpawnEntry(EnemyType.swarmer, 4)]),
  // Wave 3: First boss — Praetorian
  WaveConfig(wave: 3, gruntCount: 28, gruntHp: 50, speedMultiplier: 1.2,
      specials: [SpawnEntry(EnemyType.praetorian, 1), SpawnEntry(EnemyType.swarmer, 6)]),
  // Wave 4: Post-boss breather (still dangerous)
  WaveConfig(wave: 4, gruntCount: 24, gruntHp: 55, speedMultiplier: 1.3,
      specials: [SpawnEntry(EnemyType.guard, 3)]),
  // Wave 5: High density
  WaveConfig(wave: 5, gruntCount: 32, gruntHp: 60, speedMultiplier: 1.3,
      specials: [SpawnEntry(EnemyType.swarmer, 10), SpawnEntry(EnemyType.guard, 2)]),
  // Wave 6: Second boss — Oppressor
  WaveConfig(wave: 6, gruntCount: 36, gruntHp: 65, speedMultiplier: 1.4,
      specials: [SpawnEntry(EnemyType.oppressor, 1), SpawnEntry(EnemyType.guard, 2)]),
  // Wave 7: Swarm wave
  WaveConfig(wave: 7, gruntCount: 40, gruntHp: 70, speedMultiplier: 1.4,
      specials: [SpawnEntry(EnemyType.swarmer, 14), SpawnEntry(EnemyType.guard, 3)]),
  // Wave 8: Mixed elite
  WaveConfig(wave: 8, gruntCount: 44, gruntHp: 80, speedMultiplier: 1.5,
      specials: [SpawnEntry(EnemyType.guard, 4), SpawnEntry(EnemyType.praetorian, 1)]),
  // Wave 9: Pre-boss escalation
  WaveConfig(wave: 9, gruntCount: 50, gruntHp: 90, speedMultiplier: 1.5,
      specials: [SpawnEntry(EnemyType.guard, 5), SpawnEntry(EnemyType.swarmer, 12)]),
  // Wave 10: Final boss — Dreadnought
  WaveConfig(wave: 10, gruntCount: 55, gruntHp: 100, speedMultiplier: 1.6,
      specials: [SpawnEntry(EnemyType.dreadnought, 1), SpawnEntry(EnemyType.guard, 3)]),
];
