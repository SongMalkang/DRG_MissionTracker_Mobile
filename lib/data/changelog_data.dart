// 앱 내장 Changelog 데이터
// 버전별 변경사항을 다국어로 정의한다.
// key: pubspec.yaml의 version (예: '1.1.0')

const Map<String, Map<String, String>> changelogData = {
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
