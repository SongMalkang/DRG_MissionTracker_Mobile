// 미니게임 메타데이터 정의

import 'package:flutter/material.dart';

class MiniGameItem {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final bool isAvailable;
  final IconData icon;

  const MiniGameItem({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    this.isAvailable = true,
    this.icon = Icons.videogame_asset,
  });
}

const List<MiniGameItem> miniGameItems = [
  MiniGameItem(
    id: 'jet_boots',
    titleKey: 'minigame_jet_boots_title',
    descriptionKey: 'minigame_jet_boots_desc',
    isAvailable: true,
    icon: Icons.rocket_launch,
  ),
  MiniGameItem(
    id: 'whack_a_mole',
    titleKey: 'minigame_wam_title',
    descriptionKey: 'minigame_wam_desc',
    isAvailable: true,
    icon: Icons.pest_control,
  ),
  MiniGameItem(
    id: 'survivor',
    titleKey: 'minigame_survivor_title',
    descriptionKey: 'minigame_survivor_desc',
    isAvailable: true,
    icon: Icons.shield,
  ),
  MiniGameItem(
    id: 'coming_soon',
    titleKey: 'minigame_coming_soon_title',
    descriptionKey: 'minigame_coming_soon_desc',
    isAvailable: false,
  ),
];
