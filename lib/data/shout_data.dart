// 드워프 Ping 음성 데이터 정의
// 각 항목: id(snake_case), 표시명(i18n 키), 이미지 경로, 음성 파일 목록

class ShoutItem {
  final String id;
  final String nameKey;
  final String imagePath;
  final List<String> sounds;

  const ShoutItem({
    required this.id,
    required this.nameKey,
    required this.imagePath,
    required this.sounds,
  });
}

// Carousel에 표시할 항목 목록
const List<ShoutItem> shoutItems = [
  ShoutItem(
    id: 'mushroom',
    nameKey: 'shout_mushroom',
    imagePath: 'assets/images/mushroom.png',
    sounds: [
      'assets/audio/shouts/mushroom/Laserpoint_Misc_15_Mushroom.ogg',
      'assets/audio/shouts/mushroom/Laserpoint_Misc_15a_Mushroom_Scout.mp3',
      'assets/audio/shouts/mushroom/Laserpoint_Misc_15a_Mushroom_Driller.mp3',
      'assets/audio/shouts/mushroom/Laserpoint_Misc_15_Mushroom_Gunner.mp3',
    ],
  ),
  ShoutItem(
    id: 'yeastcone',
    nameKey: 'shout_yeastcone',
    imagePath: 'assets/images/yeastcorn.png',
    sounds: [
      'assets/audio/shouts/yeastcone/LaserPoinYeast_01.ogg',
      'assets/audio/shouts/yeastcone/LaserPoinYeast_02.ogg',
      'assets/audio/shouts/yeastcone/LaserPoinYeast_03.ogg',
      'assets/audio/shouts/yeastcone/LaserPoinYeast_04.ogg',
    ],
  ),
  ShoutItem(
    id: 'gold',
    nameKey: 'shout_gold',
    imagePath: 'assets/images/gold.png',
    sounds: [
      'assets/audio/shouts/gold/Laserpoint_Misc_17_WereRich.ogg',
      'assets/audio/shouts/gold/WereRichScout.mp3',
      'assets/audio/shouts/gold/WereRichDriller.mp3',
      'assets/audio/shouts/gold/WereRichGunner.mp3',
    ],
  ),
];
