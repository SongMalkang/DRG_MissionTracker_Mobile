// 드워프 Ping 음성 데이터 정의
// 각 항목: id(snake_case), 표시명(i18n 키), 이미지 경로, 음성 파일 목록

class ShoutItem {
  final String id;
  final String nameKey;
  final String imagePath;
  final List<String> sounds;
  final List<String> subtitles; // sounds와 1:1 매칭, 영어 자막
  final List<String> mcSounds; // MC 응답 오디오 (와이어프레임: 빈 리스트)
  final List<String> mcSubtitles; // MC 응답 자막

  const ShoutItem({
    required this.id,
    required this.nameKey,
    required this.imagePath,
    required this.sounds,
    this.subtitles = const [],
    this.mcSounds = const [],
    this.mcSubtitles = const [],
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
    subtitles: [
      'Mushroom!',
      'Mushroom here!',
      'Look, a mushroom!',
      'Hey, check out this mushroom!',
    ],
    mcSounds: [],
    mcSubtitles: [
      'We heard you the first time.',
      'Yes, it\'s a mushroom. Move on.',
      'Stop poking the mushroom and get back to mining.',
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
    subtitles: [
      'Yeast Cone!',
      'There\'s a Yeast Cone over here!',
      'Found a Yeast Cone!',
      'Yeast Cone, anyone?',
    ],
    mcSounds: [],
    mcSubtitles: [
      'Enough with the Yeast Cone.',
      'We get it. Yeast Cone. Noted.',
      'If you ping that Yeast Cone one more time...',
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
    subtitles: [
      'We\'re rich!',
      'We are rich!',
      'Look at all this gold!',
      'Gold! We\'re rich!',
    ],
    mcSounds: [],
    mcSubtitles: [
      'Yes, you\'re rich. Now get back to work.',
      'That gold won\'t mine itself, miner.',
      'Management appreciates your enthusiasm. Now move along.',
    ],
  ),
];
