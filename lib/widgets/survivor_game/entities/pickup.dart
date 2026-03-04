import 'dart:math';

enum PickupType { xp, gold }

class Pickup {
  double x;
  double y;
  PickupType type;
  double value;
  bool collected = false;

  // Magnet effect: attraction toward player
  double magnetSpeed = 0;
  static const double magnetAcceleration = 400;
  static const double maxMagnetSpeed = 350;

  // Spawn animation
  double spawnTimer = 0.3;
  double spawnOffsetX;
  double spawnOffsetY;

  Pickup({
    required this.x,
    required this.y,
    required this.type,
    required this.value,
  })  : spawnOffsetX = (Random().nextDouble() - 0.5) * 30,
        spawnOffsetY = (Random().nextDouble() - 0.5) * 30;

  double get displayX => x + (spawnTimer > 0 ? spawnOffsetX * (spawnTimer / 0.3) : 0);
  double get displayY => y + (spawnTimer > 0 ? spawnOffsetY * (spawnTimer / 0.3) : 0);

  void update(double dt, double playerX, double playerY, double collectionRadius) {
    if (collected) return;

    if (spawnTimer > 0) {
      spawnTimer -= dt;
      return;
    }

    final dx = playerX - x;
    final dy = playerY - y;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist < collectionRadius) {
      // Attracted to player
      magnetSpeed = (magnetSpeed + magnetAcceleration * dt).clamp(0, maxMagnetSpeed);
      if (dist > 1) {
        x += (dx / dist) * magnetSpeed * dt;
        y += (dy / dist) * magnetSpeed * dt;
      }
      // Collected when very close
      if (dist < 8) {
        collected = true;
      }
    } else {
      magnetSpeed = 0;
    }
  }
}
