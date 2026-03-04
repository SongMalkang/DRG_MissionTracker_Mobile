import 'dart:math';
import 'entities/player.dart';
import 'entities/enemy.dart';
import 'entities/projectile.dart';
import 'entities/pickup.dart';
import 'data/weapon_data.dart';
import 'data/enemy_data.dart';

enum GamePhase { playing, levelUp, gameOver }

enum LevelUpChoiceType {
  damageUp,
  fireRateUp,
  speedUp,
  maxHpUp,
  hpRecovery,
  extraProjectile,
  collectionRadiusUp,
  secondaryWeapon,
}

class LevelUpChoice {
  final LevelUpChoiceType type;
  final String title;
  final String description;
  final WeaponId? weaponId;

  const LevelUpChoice({
    required this.type,
    required this.title,
    required this.description,
    this.weaponId,
  });
}

class DamageNumber {
  double x, y;
  double damage;
  double timer;
  bool isCrit;
  DamageNumber(this.x, this.y, this.damage, {this.isCrit = false}) : timer = 0.6;
}

class GameEngine {
  final Player player;
  final List<Enemy> enemies = [];
  final List<Projectile> projectiles = [];
  final List<Pickup> pickups = [];
  final List<DamageNumber> damageNumbers = [];
  final Random _rng = Random();

  GamePhase phase = GamePhase.playing;
  int wave = 0;
  double waveTimer = 0;
  double gameTimer = 0;
  int killCount = 0;
  double score = 0;

  // Wave management
  double _spawnTimer = 0;
  final double _waveInterval = 25; // seconds per wave
  int _enemiesSpawnedThisWave = 0;
  int _enemiesToSpawnThisWave = 0;
  List<SpawnEntry> _specialsToSpawn = [];

  // Screen size for spawn positioning
  double screenWidth = 0;
  double screenHeight = 0;

  // Pending level ups (if multiple levels gained)
  int _pendingLevelUps = 0;

  // Burst fire queue (for weapons like double-barrel Boomstick)
  final List<_BurstEntry> _burstQueue = [];

  GameEngine({WeaponId primaryWeapon = WeaponId.gk2})
      : player = Player(primaryWeapon: primaryWeapon) {
    _startNextWave();
  }

  void setScreenSize(double w, double h) {
    screenWidth = w;
    screenHeight = h;
  }

  void update(double dt, double joystickX, double joystickY) {
    if (phase != GamePhase.playing) return;

    gameTimer += dt;
    waveTimer += dt;

    // Check wave progression
    if (waveTimer >= _waveInterval) {
      _startNextWave();
    }

    // Update player
    player.update(dt);
    player.move(joystickX, joystickY, dt);

    // Auto-fire weapons
    _fireWeapons();
    _processBurstQueue(dt);

    // Spawn enemies for current wave
    _spawnEnemies(dt);

    // Update entities
    _updateEnemies(dt);
    _updateProjectiles(dt);
    _updatePickups(dt);
    _updateDamageNumbers(dt);

    // Check collisions
    _checkProjectileEnemyCollisions();
    _checkEnemyPlayerCollisions();

    // Clean up dead entities
    _cleanup();

    // Check game over
    if (player.isDead) {
      phase = GamePhase.gameOver;
    }
  }

  void _startNextWave() {
    wave++;
    waveTimer = 0;

    final config = _getWaveConfig(wave);
    _enemiesToSpawnThisWave = config.gruntCount;
    _enemiesSpawnedThisWave = 0;
    _specialsToSpawn = List.from(config.specials);
    _spawnTimer = 0;
  }

  WaveConfig _getWaveConfig(int w) {
    if (w <= waveTable.length) {
      return waveTable[w - 1];
    }
    // Scale infinitely after wave 10
    final baseConfig = waveTable.last;
    final extraScale = 1.0 + (w - 10) * 0.12;
    return WaveConfig(
      wave: w,
      gruntCount: (baseConfig.gruntCount * extraScale).round(),
      gruntHp: baseConfig.gruntHp * extraScale,
      speedMultiplier: baseConfig.speedMultiplier + (w - 15) * 0.05,
      specials: baseConfig.specials,
    );
  }

  void _spawnEnemies(double dt) {
    _spawnTimer -= dt;
    if (_spawnTimer > 0) return;

    final config = _getWaveConfig(wave);

    // Spawn grunt
    if (_enemiesSpawnedThisWave < _enemiesToSpawnThisWave) {
      final spawnInterval = _waveInterval / _enemiesToSpawnThisWave;
      _spawnTimer = spawnInterval;
      _enemiesSpawnedThisWave++;

      final pos = _randomSpawnPosition();
      final gruntData = enemyDataTable[EnemyType.grunt]!;
      final enemy = Enemy.fromData(gruntData, pos.x, pos.y,
          hpMultiplier: config.gruntHp / 30.0,
          speedMultiplier: config.speedMultiplier);
      enemies.add(enemy);
    }

    // Spawn specials at wave start
    if (_specialsToSpawn.isNotEmpty) {
      for (final entry in _specialsToSpawn) {
        final data = enemyDataTable[entry.type]!;
        for (int i = 0; i < entry.count; i++) {
          final pos = _randomSpawnPosition();
          enemies.add(Enemy.fromData(data, pos.x, pos.y,
              speedMultiplier: config.speedMultiplier));
        }
      }
      _specialsToSpawn.clear();
    }

    // Random Bulk Detonator chance (wave 8+)
    if (wave >= 8 && _rng.nextDouble() < 0.001 * dt) {
      final data = enemyDataTable[EnemyType.bulkDetonator]!;
      final pos = _randomSpawnPosition();
      enemies.add(Enemy.fromData(data, pos.x, pos.y));
    }
  }

  Point<double> _randomSpawnPosition() {
    // Spawn enemies outside the visible screen
    final margin = 50.0;
    final halfW = screenWidth / 2 + margin;
    final halfH = screenHeight / 2 + margin;

    // Pick a random edge
    final edge = _rng.nextInt(4);
    double sx, sy;
    switch (edge) {
      case 0: // top
        sx = player.x + (_rng.nextDouble() * 2 - 1) * halfW;
        sy = player.y - halfH;
      case 1: // bottom
        sx = player.x + (_rng.nextDouble() * 2 - 1) * halfW;
        sy = player.y + halfH;
      case 2: // left
        sx = player.x - halfW;
        sy = player.y + (_rng.nextDouble() * 2 - 1) * halfH;
      default: // right
        sx = player.x + halfW;
        sy = player.y + (_rng.nextDouble() * 2 - 1) * halfH;
    }
    return Point(sx, sy);
  }

  void _fireWeapons() {
    // Primary weapon auto-fire
    if (player.primaryFireTimer <= 0) {
      final weapon = primaryWeapons[player.primaryWeapon]!;
      final effectiveFireRate = weapon.fireRate * player.fireRateMultiplier;
      player.primaryFireTimer = 1.0 / effectiveFireRate;
      _fireAt(weapon, _findNearestEnemy());
    }

    // Secondary weapon auto-fire
    if (player.secondaryWeapon != null && player.secondaryFireTimer <= 0) {
      final weapon = secondaryWeapons[player.secondaryWeapon]!;
      final effectiveFireRate = weapon.fireRate * player.fireRateMultiplier;
      player.secondaryFireTimer = 1.0 / effectiveFireRate;

      // Boltshark targets highest-HP enemy; others target nearest
      final target = weapon.id == WeaponId.boltshark
          ? _findHighestHpEnemy(weapon.range)
          : _findNearestEnemy();

      // First shot
      _fireAt(weapon, target);

      // Queue remaining burst shots (e.g. double barrel)
      for (int b = 1; b < weapon.burstCount; b++) {
        _burstQueue.add(_BurstEntry(
          weapon: weapon,
          delay: weapon.burstDelay * b,
        ));
      }
    }
  }

  void _processBurstQueue(double dt) {
    for (final entry in _burstQueue) {
      entry.delay -= dt;
    }
    final ready = _burstQueue.where((e) => e.delay <= 0).toList();
    for (final entry in ready) {
      final target = entry.weapon.id == WeaponId.boltshark
          ? _findHighestHpEnemy(entry.weapon.range)
          : _findNearestEnemy();
      _fireAt(entry.weapon, target);
    }
    _burstQueue.removeWhere((e) => e.delay <= 0);
  }

  Enemy? _findHighestHpEnemy(double range) {
    Enemy? best;
    double bestHp = 0;
    final rangeSq = range * range * 2.25; // 1.5x range tolerance squared
    for (final e in enemies) {
      if (e.isDead) continue;
      final dx = e.x - player.x;
      final dy = e.y - player.y;
      if (dx * dx + dy * dy > rangeSq) continue;
      if (e.hp > bestHp) {
        bestHp = e.hp;
        best = e;
      }
    }
    return best;
  }

  Enemy? _findNearestEnemy() {
    Enemy? nearest;
    double nearestDist = double.infinity;
    for (final e in enemies) {
      if (e.isDead) continue;
      final dx = e.x - player.x;
      final dy = e.y - player.y;
      final dist = dx * dx + dy * dy;
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = e;
      }
    }
    return nearest;
  }

  void _fireAt(WeaponData weapon, Enemy? target) {
    if (target == null) return;

    final dx = target.x - player.x;
    final dy = target.y - player.y;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist > weapon.range * 1.5) return;

    final baseAngle = atan2(dy, dx);
    final count = weapon.projectileCount + player.extraProjectiles;
    final halfSpread = weapon.spread / 2;

    for (int i = 0; i < count; i++) {
      double angle = baseAngle;

      if (weapon.projectileCount >= 5) {
        if (count > 1) {
          final t = (i / (count - 1)) * 2 - 1;
          angle += t * halfSpread;
        }
        angle += (_rng.nextDouble() - 0.5) * 0.06;
      } else if (weapon.spread > 0) {
        angle += (_rng.nextDouble() - 0.5) * weapon.spread;
      }

      projectiles.add(Projectile(
        x: player.x,
        y: player.y,
        vx: cos(angle) * weapon.projectileSpeed,
        vy: sin(angle) * weapon.projectileSpeed,
        damage: weapon.damage * player.damageMultiplier,
        lifetime: weapon.range / weapon.projectileSpeed,
        angle: angle,
        piercing: weapon.piercing,
      ));
    }
  }

  void _updateEnemies(double dt) {
    for (final e in enemies) {
      e.update(dt, player.x, player.y);
    }
  }

  void _updateProjectiles(double dt) {
    for (final p in projectiles) {
      p.update(dt);
    }
  }

  void _updatePickups(double dt) {
    for (final p in pickups) {
      p.update(dt, player.x, player.y, player.collectionRadius);
      if (p.collected) {
        switch (p.type) {
          case PickupType.xp:
            if (player.addXp(p.value)) {
              _pendingLevelUps++;
              if (phase == GamePhase.playing) {
                phase = GamePhase.levelUp;
              }
            }
          case PickupType.gold:
            score += p.value;
        }
      }
    }
  }

  void _updateDamageNumbers(double dt) {
    for (final d in damageNumbers) {
      d.timer -= dt;
      d.y -= 30 * dt;
    }
    damageNumbers.removeWhere((d) => d.timer <= 0);
  }

  void _checkProjectileEnemyCollisions() {
    for (final p in projectiles) {
      if (p.isDead) continue;
      for (final e in enemies) {
        if (e.isDead) continue;

        final dx = p.x - e.x;
        final dy = p.y - e.y;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < e.radius + 3) {
          // Hit
          final enemyId = e.hashCode;
          if (p.piercing && p.hitEnemyIds.contains(enemyId)) continue;

          final actualDmg = e.takeDamage(p.damage, fromAngle: p.angle + pi);
          damageNumbers.add(DamageNumber(e.x, e.y - e.radius, actualDmg));

          if (p.piercing) {
            p.hitEnemyIds.add(enemyId);
          } else {
            p.isDead = true;
          }

          if (e.isDead) {
            _onEnemyKilled(e);
          }
          if (!p.piercing) break;
        }
      }
    }
  }

  void _checkEnemyPlayerCollisions() {
    if (player.isInvincible || player.isDead) return;

    for (final e in enemies) {
      if (e.isDead || !e.canAttack()) continue;

      final dx = e.x - player.x;
      final dy = e.y - player.y;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist < e.radius + 12) {
        player.takeDamage(e.damage);
        e.onAttack();
        break;
      }
    }
  }

  void _onEnemyKilled(Enemy e) {
    killCount++;
    score += e.xpDrop * 10;

    // Spawn XP pickup
    pickups.add(Pickup(
      x: e.x,
      y: e.y,
      type: PickupType.xp,
      value: e.xpDrop,
    ));

    // Spawn gold pickup (if applicable)
    if (e.goldDrop > 0) {
      pickups.add(Pickup(
        x: e.x,
        y: e.y,
        type: PickupType.gold,
        value: e.goldDrop,
      ));
    }
  }

  void _cleanup() {
    enemies.removeWhere((e) => e.isDead);
    projectiles.removeWhere((p) => p.isDead);
    pickups.removeWhere((p) => p.collected);
  }

  /// Generate 3 random level-up choices
  List<LevelUpChoice> generateChoices() {
    final List<LevelUpChoice> pool = [
      const LevelUpChoice(
        type: LevelUpChoiceType.damageUp,
        title: 'DAMAGE UP',
        description: '+20% damage',
      ),
      const LevelUpChoice(
        type: LevelUpChoiceType.fireRateUp,
        title: 'FIRE RATE UP',
        description: '+15% fire rate',
      ),
      const LevelUpChoice(
        type: LevelUpChoiceType.speedUp,
        title: 'SPEED UP',
        description: '+10% move speed',
      ),
      const LevelUpChoice(
        type: LevelUpChoiceType.maxHpUp,
        title: 'MAX HP UP',
        description: '+25 max HP',
      ),
      const LevelUpChoice(
        type: LevelUpChoiceType.hpRecovery,
        title: 'HP RECOVERY',
        description: 'Restore 30 HP',
      ),
      const LevelUpChoice(
        type: LevelUpChoiceType.extraProjectile,
        title: 'EXTRA SHOT',
        description: '+1 projectile',
      ),
      const LevelUpChoice(
        type: LevelUpChoiceType.collectionRadiusUp,
        title: 'MAGNET',
        description: '+30% pickup range',
      ),
    ];

    // Add secondary weapon options if not equipped
    if (player.secondaryWeapon == null) {
      for (final entry in secondaryWeapons.entries) {
        pool.add(LevelUpChoice(
          type: LevelUpChoiceType.secondaryWeapon,
          title: entry.value.name.toUpperCase(),
          description: 'Equip ${entry.value.name}',
          weaponId: entry.key,
        ));
      }
    }

    pool.shuffle(_rng);
    final result = pool.take(3).toList();

    // First level-up without secondary: guarantee at least one weapon choice
    if (player.secondaryWeapon == null) {
      final hasWeapon = result.any((c) => c.type == LevelUpChoiceType.secondaryWeapon);
      if (!hasWeapon) {
        final weaponChoices = pool
            .where((c) => c.type == LevelUpChoiceType.secondaryWeapon)
            .toList();
        if (weaponChoices.isNotEmpty) {
          weaponChoices.shuffle(_rng);
          result[_rng.nextInt(result.length)] = weaponChoices.first;
        }
      }
    }

    return result;
  }

  /// Apply a level-up choice
  void applyChoice(LevelUpChoice choice) {
    switch (choice.type) {
      case LevelUpChoiceType.damageUp:
        player.damageMultiplier *= 1.2;
      case LevelUpChoiceType.fireRateUp:
        player.fireRateMultiplier *= 1.15;
      case LevelUpChoiceType.speedUp:
        player.speed *= 1.1;
      case LevelUpChoiceType.maxHpUp:
        player.maxHp += 25;
        player.hp += 25;
      case LevelUpChoiceType.hpRecovery:
        player.heal(30);
      case LevelUpChoiceType.extraProjectile:
        player.extraProjectiles++;
      case LevelUpChoiceType.collectionRadiusUp:
        player.collectionRadius *= 1.3;
      case LevelUpChoiceType.secondaryWeapon:
        if (choice.weaponId != null) {
          player.secondaryWeapon = choice.weaponId;
        }
    }

    _pendingLevelUps--;
    if (_pendingLevelUps > 0) {
      // More level-ups pending
      phase = GamePhase.levelUp;
    } else {
      phase = GamePhase.playing;
    }
  }

  /// Calculate final score
  double get finalScore {
    return score + killCount * 5 + gameTimer * 2;
  }
}

class _BurstEntry {
  final WeaponData weapon;
  double delay;
  _BurstEntry({required this.weapon, required this.delay});
}
