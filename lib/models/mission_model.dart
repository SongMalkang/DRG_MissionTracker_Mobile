class Mission {
  final String biome;
  final String missionType;
  final String timeWindow;
  final int length;
  final int complexity;
  final String? buff;
  final String? debuff;
  final bool isPast; // 타임라인에서 과거 미션인지 판별용

  Mission({
    required this.biome,
    required this.missionType,
    required this.timeWindow,
    required this.length,
    required this.complexity,
    this.buff,
    this.debuff,
    this.isPast = false,
  });
}