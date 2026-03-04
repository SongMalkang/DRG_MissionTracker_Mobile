class Projectile {
  double x;
  double y;
  double vx;
  double vy;
  double damage;
  double lifetime;
  bool piercing;
  bool isDead = false;
  double angle;
  String? weaponId; // tracks which weapon fired this projectile

  // Track enemies already hit (for piercing)
  final Set<int> hitEnemyIds = {};

  Projectile({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.damage,
    required this.lifetime,
    required this.angle,
    this.piercing = false,
    this.weaponId,
  });

  void update(double dt) {
    if (isDead) return;
    x += vx * dt;
    y += vy * dt;
    lifetime -= dt;
    if (lifetime <= 0) isDead = true;
  }
}
