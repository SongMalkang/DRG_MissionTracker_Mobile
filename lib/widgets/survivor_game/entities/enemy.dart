import 'dart:math';
import '../data/enemy_data.dart';

class Enemy {
  double x;
  double y;
  EnemyType type;
  double hp;
  double maxHp;
  double speed;
  double damage;
  double radius;
  double facingAngle = 0;
  double hitFlashTimer = 0;
  bool isDead = false;

  // Front armor: projectiles from the front deal 50% less damage
  final bool frontArmor;
  final bool isBoss;
  final double xpDrop;
  final double goldDrop;

  // Damage cooldown (prevent rapid multi-hit on player)
  double attackCooldown = 0;
  static const double attackInterval = 0.5;

  Enemy({
    required this.x,
    required this.y,
    required this.type,
    required this.maxHp,
    required this.speed,
    required this.damage,
    required this.radius,
    this.frontArmor = false,
    this.isBoss = false,
    this.xpDrop = 1,
    this.goldDrop = 0,
  }) : hp = maxHp;

  factory Enemy.fromData(EnemyData data, double x, double y,
      {double hpMultiplier = 1.0, double speedMultiplier = 1.0}) {
    return Enemy(
      x: x,
      y: y,
      type: data.type,
      maxHp: data.hp * hpMultiplier,
      speed: data.speed * speedMultiplier,
      damage: data.damage,
      radius: data.radius,
      frontArmor: data.frontArmor,
      isBoss: data.isBoss,
      xpDrop: data.xpDrop,
      goldDrop: data.goldDrop,
    );
  }

  void update(double dt, double playerX, double playerY) {
    if (isDead) return;
    if (hitFlashTimer > 0) hitFlashTimer -= dt;
    if (attackCooldown > 0) attackCooldown -= dt;

    // Move toward player
    final dx = playerX - x;
    final dy = playerY - y;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist > 1) {
      final nx = dx / dist;
      final ny = dy / dist;
      x += nx * speed * dt;
      y += ny * speed * dt;
      facingAngle = atan2(ny, nx);
    }
  }

  /// Returns actual damage dealt (after armor)
  double takeDamage(double amount, {double? fromAngle}) {
    if (isDead) return 0;

    double finalDamage = amount;
    // Front armor check
    if (frontArmor && fromAngle != null) {
      final angleDiff = _angleDiff(fromAngle, facingAngle);
      if (angleDiff.abs() < pi / 3) {
        // Hit from front — 50% damage reduction
        finalDamage *= 0.5;
      }
    }

    hp -= finalDamage;
    hitFlashTimer = 0.1;
    if (hp <= 0) {
      hp = 0;
      isDead = true;
    }
    return finalDamage;
  }

  bool canAttack() {
    return attackCooldown <= 0 && !isDead;
  }

  void onAttack() {
    attackCooldown = attackInterval;
  }

  static double _angleDiff(double a, double b) {
    double diff = a - b;
    while (diff > pi) { diff -= 2 * pi; }
    while (diff < -pi) { diff += 2 * pi; }
    return diff;
  }
}
