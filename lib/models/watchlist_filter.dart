import 'mission_model.dart';

/// Watchlist 필터 조건 모델
///
/// 각 카테고리 내 조건은 OR (하나라도 일치하면 통과),
/// 카테고리 간 조건은 AND (설정된 카테고리 전부 통과해야 매칭).
/// 빈 Set = 해당 카테고리 필터 없음 (전체 허용).
class WatchlistFilter {
  final bool enabled;
  final Set<String> missionTypes;
  final Set<String> biomes;
  final Set<String> buffs;
  final Set<String> warnings;

  const WatchlistFilter({
    this.enabled = false,
    this.missionTypes = const {},
    this.biomes = const {},
    this.buffs = const {},
    this.warnings = const {},
  });

  static const WatchlistFilter empty = WatchlistFilter();

  /// 조건이 하나라도 설정되어 있고 활성 상태인지
  bool get isActive =>
      enabled &&
      (missionTypes.isNotEmpty ||
          biomes.isNotEmpty ||
          buffs.isNotEmpty ||
          warnings.isNotEmpty);

  /// 미션이 Watchlist 조건에 매칭되는지 판정
  bool matches(Mission mission) {
    if (!isActive) return false;

    // 미션 타입 필터 (비어있으면 전체 통과)
    if (missionTypes.isNotEmpty && !missionTypes.contains(mission.missionType)) {
      return false;
    }

    // 바이옴 필터
    if (biomes.isNotEmpty && !biomes.contains(mission.biome)) {
      return false;
    }

    // 버프 필터
    if (buffs.isNotEmpty) {
      if (mission.buff == null || !buffs.contains(mission.buff)) {
        return false;
      }
    }

    // 경고 필터 (미션의 debuff가 쉼표 구분 문자열이므로 하나라도 포함되면 통과)
    if (warnings.isNotEmpty) {
      if (mission.debuff == null) return false;
      final missionWarnings = mission.debuff!
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      if (missionWarnings.intersection(warnings).isEmpty) {
        return false;
      }
    }

    return true;
  }

  WatchlistFilter copyWith({
    bool? enabled,
    Set<String>? missionTypes,
    Set<String>? biomes,
    Set<String>? buffs,
    Set<String>? warnings,
  }) {
    return WatchlistFilter(
      enabled: enabled ?? this.enabled,
      missionTypes: missionTypes ?? this.missionTypes,
      biomes: biomes ?? this.biomes,
      buffs: buffs ?? this.buffs,
      warnings: warnings ?? this.warnings,
    );
  }
}
