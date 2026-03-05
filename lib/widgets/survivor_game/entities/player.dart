import 'dart:math';
import '../data/weapon_data.dart';

class Player {
  double x;
  double y;
  double hp;
  double maxHp;
  int level;
  double xp;
  double xpToNextLevel;

  // Weapons
  WeaponId primaryWeapon;
  WeaponId? secondaryWeapon;

  // Combat timers
  double primaryFireTimer = 0;
  double secondaryFireTimer = 0;

  // Movement
  double speed;
  double baseSpeed;

  // Dash (grappling hook flick)
  bool isDashing = false;
  double dashTimer = 0;
  double dashCooldown = 0;
  double dashDirX = 0;
  double dashDirY = 0;
  static const double dashDuration = 0.2;
  static const double dashSpeed = 750;
  static const double dashCooldownTime = 1.5;

  // Invincibility after hit
  double invincibilityTimer = 0;
  static const double invincibilityDuration = 0.8;

  // Stats (upgradeable)
  double damageMultiplier = 1.0;
  double fireRateMultiplier = 1.0;
  double collectionRadius = 52; // base 40 + 1 magnet upgrade (40 * 1.3)
  int extraProjectiles = 0;

  // Facing direction (for rendering)
  double facingAngle = 0;

  Player({
    this.x = 0,
    this.y = 0,
    this.maxHp = 100,
    this.primaryWeapon = WeaponId.gk2,
    this.baseSpeed = 180,
  })  : hp = maxHp,
        level = 1,
        xp = 0,
        xpToNextLevel = 10,
        speed = baseSpeed;

  bool get isInvincible => invincibilityTimer > 0;
  bool get isDead => hp <= 0;

  void update(double dt) {
    if (invincibilityTimer > 0) invincibilityTimer -= dt;
    if (dashCooldown > 0) dashCooldown -= dt;
    if (primaryFireTimer > 0) primaryFireTimer -= dt;
    if (secondaryFireTimer > 0) secondaryFireTimer -= dt;

    if (isDashing) {
      dashTimer -= dt;
      if (dashTimer <= 0) {
        isDashing = false;
        invincibilityTimer = 0.1;
      }
    }
  }

  void move(double dx, double dy, double dt) {
    if (isDashing) {
      x += dashDirX * dashSpeed * dt;
      y += dashDirY * dashSpeed * dt;
      return;
    }
    if (dx != 0 || dy != 0) {
      final len = sqrt(dx * dx + dy * dy);
      final nx = dx / len;
      final ny = dy / len;
      x += nx * speed * dt;
      y += ny * speed * dt;
      facingAngle = atan2(ny, nx);
    }
  }

  bool tryDash(double dirX, double dirY) {
    if (isDashing || dashCooldown > 0) return false;
    final len = sqrt(dirX * dirX + dirY * dirY);
    if (len < 0.01) return false;
    dashDirX = dirX / len;
    dashDirY = dirY / len;
    isDashing = true;
    dashTimer = dashDuration;
    dashCooldown = dashCooldownTime;
    invincibilityTimer = dashDuration;
    return true;
  }

  void takeDamage(double amount) {
    if (isInvincible || isDead) return;
    hp = (hp - amount).clamp(0.0, maxHp);
    invincibilityTimer = invincibilityDuration;
  }

  void applyKnockback(double dx, double dy, double force) {
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 0.01) return;
    final nx = dx / dist;
    final ny = dy / dist;
    x += nx * force * 0.1; // instant displacement
    y += ny * force * 0.1;
  }

  void heal(double amount) {
    hp = (hp + amount).clamp(0.0, maxHp);
  }

  /// Returns true if leveled up
  bool addXp(double amount) {
    xp += amount;
    if (xp >= xpToNextLevel) {
      xp -= xpToNextLevel;
      level++;
      xpToNextLevel = _calcXpForLevel(level);
      return true;
    }
    return false;
  }

  double _calcXpForLevel(int lv) {
    return 10 + (lv - 1) * 5.0;
  }
}
