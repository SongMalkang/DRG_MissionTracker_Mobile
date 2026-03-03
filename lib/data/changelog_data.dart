// 앱 내장 Changelog 데이터
// 버전별 변경사항을 다국어로 정의한다.
// key: pubspec.yaml의 version (예: '1.1.0')

const Map<String, Map<String, String>> changelogData = {
  '1.3.0': {
    'KR':'• 밈, 미니게임 기능을 웹에서도 이용할 수 있습니다.\n'
        '• Play Store 출시 준비를 위한 안정성 개선.\n'
        '• URL을 갤 외부에 노출하지마세요.',
    'EN': '• Shout and Mini Games are now available on the web.\n'
        '• Stability improvements for Play Store release.\n'
        '• Do not expose the URL outside the gallery.',
    'CN': '• Shout 和迷你游戏现已在网页版上可用。\n'
        '• 为 Play Store 上架进行了稳定性改进。\n'
        '• 请不要将 URL 泄露到画廊之外。',
  },
  '1.2.0': {
    'KR': '• Pit Jaw 게임이 추가되었습니다!\n'
        '• JetBoot 게임의 난이도가 완화되었습니다.\n'
        '• 아이콘 이미지가 개선되었습니다.\n'
        '• 번역 오류를 수정했습니다.',
    'EN': '• Pit Jaw game added!\n'
        '• JetBoot game difficulty reduced.\n'
        '• Icon images improved.\n'
        '• Translation errors fixed.',
    'CN': '• 新增 Pit Jaw 游戏！\n'
        '• 降低了 JetBoot 游戏的难度。\n'
        '• 优化了图标图像。\n'
        '• 修复了翻译错误。',
  },
};
