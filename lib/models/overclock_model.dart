/// 오버클럭 등급
enum OverclockTier { clean, balanced, unstable }

/// 드워프 클래스
enum DwarfClass { driller, engineer, gunner, scout }

/// 개별 오버클럭
class Overclock {
  final String id;       // "driller_crspr_lighter_tanks"
  final String name;     // "Lighter Tanks" (영문 공식 명칭)
  final OverclockTier tier;
  final String effect;   // 효과 설명 (영문)
  final String icon;     // OC 아이콘 파일명 (예: "icon_upgrade_ammo")

  const Overclock({
    required this.id,
    required this.name,
    required this.tier,
    required this.effect,
    required this.icon,
  });
}

/// 무기
class Weapon {
  final String id;       // "crspr_flamethrower"
  final String name;     // "CRSPR Flamethrower"
  final bool isPrimary;
  final List<Overclock> overclocks;

  const Weapon({
    required this.id,
    required this.name,
    required this.isPrimary,
    required this.overclocks,
  });
}

/// 드워프 캐릭터 (오버클럭용)
class DwarfCharacter {
  final DwarfClass dwarfClass;
  final String name;       // "Driller"
  final String imagePath;  // "assets/images/character/300px-Driller.webp"
  final List<Weapon> weapons; // 6개 (primary 3 + secondary 3)

  const DwarfCharacter({
    required this.dwarfClass,
    required this.name,
    required this.imagePath,
    required this.weapons,
  });

  List<Weapon> get primaryWeapons =>
      weapons.where((w) => w.isPrimary).toList();

  List<Weapon> get secondaryWeapons =>
      weapons.where((w) => !w.isPrimary).toList();

  int get totalOverclocks =>
      weapons.fold(0, (sum, w) => sum + w.overclocks.length);
}
