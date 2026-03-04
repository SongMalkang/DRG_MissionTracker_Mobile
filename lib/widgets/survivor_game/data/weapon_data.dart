enum WeaponId { gk2, m1000, drak25, boomstick, zhukov, boltshark }

enum WeaponSlot { primary, secondary }

class WeaponData {
  final WeaponId id;
  final String name;
  final WeaponSlot slot;
  final double damage;
  final double fireRate; // shots per second
  final double projectileSpeed;
  final double range;
  final int projectileCount;
  final double spread; // total cone angle (radians)
  final bool piercing;
  final int burstCount; // consecutive shots per trigger (e.g. double barrel)
  final double burstDelay; // seconds between burst shots

  const WeaponData({
    required this.id,
    required this.name,
    required this.slot,
    required this.damage,
    required this.fireRate,
    required this.projectileSpeed,
    required this.range,
    this.projectileCount = 1,
    this.spread = 0.0,
    this.piercing = false,
    this.burstCount = 1,
    this.burstDelay = 0.0,
  });
}

// Primary weapons (selected in loadout)
const Map<WeaponId, WeaponData> primaryWeapons = {
  WeaponId.gk2: WeaponData(
    id: WeaponId.gk2,
    name: 'Deepcore GK2',
    slot: WeaponSlot.primary,
    damage: 12,
    fireRate: 4.0,
    projectileSpeed: 400,
    range: 250,
  ),
  WeaponId.m1000: WeaponData(
    id: WeaponId.m1000,
    name: 'M1000 Classic',
    slot: WeaponSlot.primary,
    damage: 50,
    fireRate: 1.2,
    projectileSpeed: 600,
    range: 400,
    piercing: true,
  ),
  WeaponId.drak25: WeaponData(
    id: WeaponId.drak25,
    name: 'DRAK-25 Plasma',
    slot: WeaponSlot.primary,
    damage: 8,
    fireRate: 7.0,
    projectileSpeed: 350,
    range: 200,
    projectileCount: 2,
    spread: 0.25, // random deviation per bullet
  ),
};

// Secondary weapons (random drop on level up)
const Map<WeaponId, WeaponData> secondaryWeapons = {
  WeaponId.boomstick: WeaponData(
    id: WeaponId.boomstick,
    name: 'Boomstick',
    slot: WeaponSlot.secondary,
    damage: 25,
    fireRate: 0.4,
    projectileSpeed: 280,
    range: 165, // 1.5x buff (was 110)
    projectileCount: 7,
    spread: 0.35, // total cone ~20 degrees, tight cluster
    burstCount: 2, // double barrel — fires twice
    burstDelay: 0.12, // 120ms between barrels
  ),
  WeaponId.zhukov: WeaponData(
    id: WeaponId.zhukov,
    name: 'Zhukov NUK17',
    slot: WeaponSlot.secondary,
    damage: 3, // 50% nerf (was 6)
    fireRate: 12.0, // shorter cycle — rapid spray
    projectileSpeed: 400,
    range: 180,
    projectileCount: 2,
    spread: 0.5, // random deviation per bullet, sprays wide
  ),
  WeaponId.boltshark: WeaponData(
    id: WeaponId.boltshark,
    name: 'Boltshark X-80',
    slot: WeaponSlot.secondary,
    damage: 52.5, // 75% nerf (was 70)
    fireRate: 0.8,
    projectileSpeed: 500,
    range: 350,
    piercing: true,
  ),
};
