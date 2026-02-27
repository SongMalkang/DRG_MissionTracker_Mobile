class Mission {
  final String biome;
  final String missionType;
  final String? secondaryObjective;
  final String? codeName;
  final int length;
  final int complexity;
  final String? buff;
  final String? debuff;
  final List<String> seasons;
  final String timeWindow;
  final bool isPast;

  Mission({
    required this.biome,
    required this.missionType,
    this.secondaryObjective,
    this.codeName,
    required this.length,
    required this.complexity,
    this.buff,
    this.debuff,
    this.seasons = const [],
    this.timeWindow = "",
    this.isPast = false,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      biome: json['b'] ?? "",
      missionType: json['t'] ?? "",
      secondaryObjective: json['so'],
      codeName: json['cn'],
      length: json['l'] ?? 1,
      complexity: json['c'] ?? 1,
      buff: json['bf'],
      debuff: json['df'],
      seasons: List<String>.from(json['s'] ?? []),
    );
  }
}
