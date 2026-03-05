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

class PitJaw {
  double x, y;
  double detectRadius;
  double damageRadius;
  double damage;
  bool revealed = false;
  double revealTimer = 0;
  double attackCooldown = 0;

  // ── 예고(warning) 페이즈 ──
  double warningTimer = 0; // >0이면 예고 중 (흔들림)
  double warningDuration = 0;
  bool warningTriggered = false; // 한 번만 예고

  // ── 스냅 애니메이션 ──
  bool isSnapping = false;
  double snapProgress = 0; // 0~1
  double snapStunTimer = 0; // >0이면 플레이어 스턴 중

  // ── 데미지 너프: 스냅 카운트 ──
  int snapCount = 0; // 2번째마다 실제 데미지

  PitJaw({
    required this.x,
    required this.y,
    this.detectRadius = 80,
    this.damageRadius = 25,
    this.damage = 20,
  });
}

class NitraNode {
  double x, y;
  double nitraRemaining;
  double maxNitra;
  double mineRadius;
  bool depleted = false;
  NitraNode({
    required this.x,
    required this.y,
    this.nitraRemaining = 15,
    this.mineRadius = 30,
  }) : maxNitra = nitraRemaining;
}

class RedSugarNode {
  double x, y;
  double healAmount;
  bool consumed = false;
  double collectRadius;
  RedSugarNode({
    required this.x,
    required this.y,
    this.healAmount = 30,
    this.collectRadius = 20,
  });
}

class PendingExplosion {
  double x, y;
  double radius;
  double damage;
  double delay;
  double maxDelay;
  bool damagesPlayer;
  bool triggered = false;
  PendingExplosion({
    required this.x,
    required this.y,
    required this.radius,
    required this.damage,
    required this.delay,
    this.damagesPlayer = true,
  }) : maxDelay = delay;
}

class GameEngine {
  final Player player;
  final List<Enemy> enemies = [];
  final List<Projectile> projectiles = [];
  final List<Pickup> pickups = [];
  final List<DamageNumber> damageNumbers = [];
  final List<PendingExplosion> pendingExplosions = [];
  final List<NitraNode> nitraNodes = [];
  final List<PitJaw> pitJaws = [];
  final List<RedSugarNode> redSugarNodes = [];
  double nitra = 0;
  double _scannerTimer = 10;
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

  // Hazard difficulty
  final HazardConfig hazard;

  GameEngine({WeaponId primaryWeapon = WeaponId.gk2, HazardConfig? hazard})
      : player = Player(primaryWeapon: primaryWeapon),
        hazard = hazard ?? hazardLevels[2] {
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
    // 스냅 스턴 중이면 이동 차단
    if (!isPlayerSnapped) {
      player.move(joystickX, joystickY, dt);
    }

    // Auto-fire weapons
    _fireWeapons();
    _processBurstQueue(dt);

    // Spawn enemies for current wave
    _spawnEnemies(dt);

    // Update entities
    _updateEnemies(dt);
    _updateBossAbilities(dt);
    _updateProjectiles(dt);
    _updatePickups(dt);
    _updateDamageNumbers(dt);
    _updateNitraNodes(dt);
    _updatePitJaws(dt);
    _updateRedSugar(dt);
    _updateScanner(dt);
    _updateExplosions(dt);

    // Check collisions
    _checkProjectileEnemyCollisions();
    _checkEnemyProjectilePlayerCollisions();
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
    _enemiesToSpawnThisWave = (config.gruntCount * hazard.spawnMultiplier).round();
    _enemiesSpawnedThisWave = 0;
    _specialsToSpawn = List.from(config.specials);
    _spawnTimer = 0;

    // Spawn Pit Jaws (wave 3+)
    if (wave >= 3) {
      final jawCount = 1 + _rng.nextInt(3);
      for (int i = 0; i < jawCount; i++) {
        final angle = _rng.nextDouble() * 2 * pi;
        final dist = 100 + _rng.nextDouble() * 200;
        pitJaws.add(PitJaw(
          x: player.x + cos(angle) * dist,
          y: player.y + sin(angle) * dist,
        ));
      }
    }

    // Spawn Red Sugar (낮은 확률: ~20% per wave)
    if (_rng.nextDouble() < 0.2) {
      final angle = _rng.nextDouble() * 2 * pi;
      final dist = 80 + _rng.nextDouble() * 180;
      redSugarNodes.add(RedSugarNode(
        x: player.x + cos(angle) * dist,
        y: player.y + sin(angle) * dist,
      ));
    }

    // Spawn 2~4 Nitra nodes per wave
    final nitraCount = 2 + _rng.nextInt(3);
    for (int i = 0; i < nitraCount; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final dist = 100 + _rng.nextDouble() * 200;
      nitraNodes.add(NitraNode(
        x: player.x + cos(angle) * dist,
        y: player.y + sin(angle) * dist,
      ));
    }
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
          hpMultiplier: config.gruntHp / 30.0 * hazard.hpMultiplier,
          speedMultiplier: config.speedMultiplier * hazard.speedMultiplier);
      enemies.add(enemy);
    }

    // Spawn specials at wave start
    if (_specialsToSpawn.isNotEmpty) {
      for (final entry in _specialsToSpawn) {
        final data = enemyDataTable[entry.type]!;
        for (int i = 0; i < entry.count; i++) {
          final pos = _randomSpawnPosition();
          enemies.add(Enemy.fromData(data, pos.x, pos.y,
              hpMultiplier: hazard.hpMultiplier,
              speedMultiplier: config.speedMultiplier * hazard.speedMultiplier));
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
        weaponId: weapon.id.name,
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
          case PickupType.nitra:
            nitra += p.value;
          case PickupType.redSugar:
            player.heal(p.value);
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
        player.takeDamage(e.damage * hazard.playerDamageMultiplier);
        e.onAttack();
        break;
      }
    }
  }

  void _updatePitJaws(double dt) {
    for (final jaw in pitJaws) {
      final dx = player.x - jaw.x;
      final dy = player.y - jaw.y;
      final distSq = dx * dx + dy * dy;

      // ── 스냅 스턴 처리 (플레이어 이동불가) ──
      if (jaw.snapStunTimer > 0) {
        jaw.snapStunTimer -= dt;
        if (jaw.snapStunTimer <= 0) {
          jaw.snapStunTimer = 0;
        }
      }

      // ── 스냅 애니메이션 진행 ──
      if (jaw.isSnapping) {
        jaw.snapProgress = (jaw.snapProgress + dt * 3.5).clamp(0.0, 1.0);
        if (jaw.snapProgress >= 1.0) {
          // 스냅 완료 → 플레이어를 핏죠 중심으로 끌어당김 + 스턴
          jaw.isSnapping = false;
          jaw.snapCount++;
          jaw.snapStunTimer = 1.0; // 1초 이동불가
          jaw.attackCooldown = 3.0; // 재공격 쿨다운

          // 플레이어를 핏죠 한가운데로 강제 이동 (물림 연출)
          player.x = jaw.x;
          player.y = jaw.y;

          // 데미지 너프: 2번째 스냅마다만 실제 데미지
          if (jaw.snapCount % 2 == 0 && !player.isInvincible) {
            player.takeDamage(jaw.damage);
          }
        }
        continue;
      }

      // ── 예고(warning) 페이즈 ──
      if (jaw.warningTimer > 0) {
        jaw.warningTimer -= dt;
        if (jaw.warningTimer <= 0) {
          // 예고 종료 → 스냅 시작!
          jaw.warningTimer = 0;
          jaw.isSnapping = true;
          jaw.snapProgress = 0;
          jaw.revealed = true;
          jaw.revealTimer = 15.0;
        }
        continue;
      }

      // Proximity detection: reveal if player within detect radius
      if (distSq < jaw.detectRadius * jaw.detectRadius && !jaw.revealed) {
        jaw.revealed = true;
        jaw.revealTimer = 15.0;
      }

      // Reveal countdown
      if (jaw.revealed) {
        jaw.revealTimer -= dt;
        if (jaw.revealTimer <= 0) {
          jaw.revealed = false;
        }
      }

      // Attack cooldown
      if (jaw.attackCooldown > 0) jaw.attackCooldown -= dt;

      // ── 감지 반경 내 진입 → 예고 시작 (즉시 데미지 X) ──
      if (distSq < jaw.damageRadius * jaw.damageRadius &&
          jaw.attackCooldown <= 0 &&
          !jaw.warningTriggered &&
          !player.isInvincible) {
        jaw.warningTriggered = true;
        jaw.warningTimer = 0.6; // 0.6초 예고
        jaw.warningDuration = 0.6;
        jaw.revealed = true;
        jaw.revealTimer = 15.0;
      }

      // 플레이어가 멀어지면 예고 리셋 (다음에 다시 트리거 가능)
      if (distSq > jaw.detectRadius * jaw.detectRadius) {
        jaw.warningTriggered = false;
      }
    }
  }

  /// 현재 스냅 스턴 상태인 핏죠가 있는지 (플레이어 이동 차단용)
  bool get isPlayerSnapped {
    for (final jaw in pitJaws) {
      if (jaw.snapStunTimer > 0) return true;
    }
    return false;
  }

  /// 현재 예고 중인 핏죠가 있는지 (경고 표시용)
  bool get isPitJawWarning {
    for (final jaw in pitJaws) {
      if (jaw.warningTimer > 0) return true;
    }
    return false;
  }

  void _updateScanner(double dt) {
    _scannerTimer -= dt;
    if (_scannerTimer <= 0) {
      _scannerTimer = 10.0;
      // Reveal pit jaws within 200 range of player
      for (final jaw in pitJaws) {
        final dx = player.x - jaw.x;
        final dy = player.y - jaw.y;
        if (dx * dx + dy * dy < 200 * 200) {
          jaw.revealed = true;
          jaw.revealTimer = 8.0;
        }
      }
    }
  }

  void _updateNitraNodes(double dt) {
    for (final node in nitraNodes) {
      if (node.depleted) continue;
      final dx = player.x - node.x;
      final dy = player.y - node.y;
      if (dx * dx + dy * dy < node.mineRadius * node.mineRadius) {
        final mined = 8.0 * dt;
        if (node.nitraRemaining <= mined) {
          nitra += node.nitraRemaining;
          node.nitraRemaining = 0;
          node.depleted = true;
        } else {
          node.nitraRemaining -= mined;
          nitra += mined;
        }
      }
    }
    nitraNodes.removeWhere((n) => n.depleted);
  }

  void _updateRedSugar(double dt) {
    for (final node in redSugarNodes) {
      if (node.consumed) continue;
      final dx = player.x - node.x;
      final dy = player.y - node.y;
      if (dx * dx + dy * dy < node.collectRadius * node.collectRadius) {
        node.consumed = true;
        player.heal(node.healAmount);
      }
    }
    redSugarNodes.removeWhere((n) => n.consumed);
  }

  void throwGrenade() {
    if (nitra < 40) return;
    nitra -= 40;
    final target = _findNearestEnemy();
    if (target == null) return;
    pendingExplosions.add(PendingExplosion(
      x: target.x,
      y: target.y,
      radius: 70,
      damage: 60,
      delay: 0.5,
      damagesPlayer: false,
    ));
  }

  void throwSuperGrenade() {
    if (nitra < 80) return;
    nitra -= 80;
    final target = _findNearestEnemy();
    if (target == null) return;
    pendingExplosions.add(PendingExplosion(
      x: target.x,
      y: target.y,
      radius: 120,
      damage: 120,
      delay: 0.8,
      damagesPlayer: false,
    ));
  }

  void _updateBossAbilities(double dt) {
    for (final e in enemies) {
      if (e.isDead) continue;

      final dx = player.x - e.x;
      final dy = player.y - e.y;
      final dist = sqrt(dx * dx + dy * dy);

      // Praetorian: Poison Aura — 3 DPS within radius 60
      if (e.type == EnemyType.praetorian && e.poisonAuraRadius > 0) {
        if (dist < e.poisonAuraRadius && !player.isInvincible) {
          player.takeDamage(e.poisonDps * dt);
        }
      }

      // Oppressor: Knockback Slam — 4s cooldown, range 40
      if (e.type == EnemyType.oppressor && e.slamCooldown <= 0) {
        if (dist < e.slamRange) {
          player.applyKnockback(dx, dy, e.slamForce);
          e.slamCooldown = e.slamCooldownMax;
        }
      }

      // Dreadnought: Phase 2 projectile — fires toward player
      if (e.type == EnemyType.dreadnought && e.wantsToShoot) {
        e.wantsToShoot = false;
        if (dist > 1) {
          final nx = dx / dist;
          final ny = dy / dist;
          projectiles.add(Projectile(
            x: e.x,
            y: e.y,
            vx: nx * 200,
            vy: ny * 200,
            damage: 25,
            lifetime: 3.0,
            angle: atan2(ny, nx),
            isEnemyProjectile: true,
          ));
        }
      }
    }
  }

  void _updateExplosions(double dt) {
    for (final exp in pendingExplosions) {
      if (exp.triggered) continue;
      exp.delay -= dt;
      if (exp.delay <= 0) {
        exp.triggered = true;
        // Damage enemies in range
        for (final e in enemies) {
          if (e.isDead) continue;
          final dx = e.x - exp.x;
          final dy = e.y - exp.y;
          if (dx * dx + dy * dy < exp.radius * exp.radius) {
            e.takeDamage(exp.damage);
            if (e.isDead) _onEnemyKilled(e);
          }
        }
        // Damage player if applicable
        if (exp.damagesPlayer && !player.isInvincible) {
          final dx = player.x - exp.x;
          final dy = player.y - exp.y;
          if (dx * dx + dy * dy < exp.radius * exp.radius) {
            player.takeDamage(exp.damage);
          }
        }
      }
    }
    pendingExplosions.removeWhere((e) => e.triggered);
  }

  void _checkEnemyProjectilePlayerCollisions() {
    if (player.isInvincible || player.isDead) return;
    for (final p in projectiles) {
      if (p.isDead || !p.isEnemyProjectile) continue;
      final dx = p.x - player.x;
      final dy = p.y - player.y;
      if (dx * dx + dy * dy < 15 * 15) {
        player.takeDamage(p.damage);
        p.isDead = true;
      }
    }
  }

  void _onEnemyKilled(Enemy e) {
    killCount++;
    score += e.xpDrop * 10;

    // Bulk Detonator: death explosion
    if (e.explodeOnDeath) {
      pendingExplosions.add(PendingExplosion(
        x: e.x,
        y: e.y,
        radius: 80,
        damage: 80,
        delay: 1.5,
        damagesPlayer: true,
      ));
    }

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
    return (score + killCount * 5 + gameTimer * 2) * hazard.scoreMultiplier;
  }
}

class _BurstEntry {
  final WeaponData weapon;
  double delay;
  _BurstEntry({required this.weapon, required this.delay});
}
