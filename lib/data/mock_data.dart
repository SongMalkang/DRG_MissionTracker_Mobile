import '../models/mission_model.dart';

// final List<Mission> mockPrevMissions = [
//   Mission(biome: "Fungus Bogs", missionType: "Elimination", timeWindow: "Past", length: 2, complexity: 2),
//   Mission(biome: "Crystalline Caverns", missionType: "Point Extraction", timeWindow: "Past", length: 3, complexity: 3),
// ];

// final List<Mission> mockCurrentMissions = [
//   Mission(biome: "Salt Pits", missionType: "Egg Hunt", timeWindow: "Current", length: 2, complexity: 2, buff: "Double XP"),
//   Mission(biome: "Magma Core", missionType: "Mining", timeWindow: "Current", length: 3, complexity: 3, debuff: "Lethal Enemies"),
//   Mission(biome: "Azure Weald", missionType: "Escort", timeWindow: "Current", length: 3, complexity: 2, buff: "Mineral Mania", debuff: "Cave Leech Cluster"),
// ];

// final List<Mission> mockNextMissions = [
//   Mission(biome: "Radioactive Exclusion Zone", missionType: "Salvage", timeWindow: "Next", length: 2, complexity: 1, buff: "Double XP"),
//   Mission(biome: "Sandblasted Corridors", missionType: "Refining", timeWindow: "Next", length: 3, complexity: 2),
// ];

final List<Mission> mockPrevMissions = [
  Mission(biome: "Fungus Bogs", missionType: "Elimination", timeWindow: "Past", length: 2, complexity: 2),
  Mission(biome: "Crystalline Caverns", missionType: "Point Extraction", timeWindow: "Past", length: 3, complexity: 3),
];

final List<Mission> mockCurrentMissions = [
  Mission(biome: "Salt Pits", missionType: "Egg Hunt", timeWindow: "Current", length: 2, complexity: 2),
  Mission(biome: "Magma Core", missionType: "Mining", timeWindow: "Current", length: 3, complexity: 3, debuff: "Lethal Enemies"),
  Mission(biome: "Azure Weald", missionType: "Escort", timeWindow: "Current", length: 3, complexity: 2, buff: "Double XP", debuff: "Cave Leech Cluster"), // 정렬 테스트용
];

final List<Mission> mockNextMissions = [
  Mission(biome: "Radioactive Exclusion Zone", missionType: "Salvage", timeWindow: "Next", length: 2, complexity: 1, buff: "Double XP"),
  Mission(biome: "Sandblasted Corridors", missionType: "Refining", timeWindow: "Next", length: 3, complexity: 2),
];

// 하이라이트 탭 전용 데이터 (과거~미래 시간순 배열)
final List<Mission> mockHighlights = [
  Mission(biome: "Fungus Bogs", missionType: "Mining", timeWindow: "08:30", length: 2, complexity: 2, buff: "Double XP", isPast: true),
  Mission(biome: "Salt Pits", missionType: "Egg Hunt", timeWindow: "11:00", length: 1, complexity: 1, buff: "Mineral Mania", isPast: true),
  Mission(biome: "Azure Weald", missionType: "Escort", timeWindow: "14:30", length: 3, complexity: 2, buff: "Double XP", isPast: false), // 현재
  Mission(biome: "Magma Core", missionType: "Refining", timeWindow: "18:00", length: 3, complexity: 3, buff: "Double XP", isPast: false),
  Mission(biome: "Glacial Strata", missionType: "Salvage", timeWindow: "21:30", length: 2, complexity: 2, buff: "Double XP", isPast: false),
];