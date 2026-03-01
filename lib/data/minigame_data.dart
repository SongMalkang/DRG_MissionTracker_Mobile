// 미니게임 메타데이터 정의

class MiniGameItem {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final bool isAvailable;

  const MiniGameItem({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    this.isAvailable = true,
  });
}

const List<MiniGameItem> miniGameItems = [
  MiniGameItem(
    id: 'jet_boots',
    titleKey: 'minigame_jet_boots_title',
    descriptionKey: 'minigame_jet_boots_desc',
    isAvailable: true,
  ),
  MiniGameItem(
    id: 'coming_soon',
    titleKey: 'minigame_coming_soon_title',
    descriptionKey: 'minigame_coming_soon_desc',
    isAvailable: false,
  ),
];
