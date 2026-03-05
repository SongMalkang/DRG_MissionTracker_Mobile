// 앱 내장 Changelog 데이터
// 버전별 변경사항을 다국어로 정의한다.
// key: pubspec.yaml의 version (예: '1.1.0')

const Map<String, Map<String, String>> changelogData = {
  '1.5.0': {
    'KR': '• 미니게임 3종 개선 (보스 특수능력, Nitra/수류탄, Hazard Level, Pit Jaw, 무기 해금).\n'
        '• 위젯 정상화 (테스트중).\n'
        '• 미션 워치리스트 추가.\n'
        '• Deep Dive 버그 수정.',
    'EN': '• 3 mini-games improved (boss abilities, Nitra/grenades, Hazard Level, Pit Jaw, weapon unlocks).\n'
        '• Widget stabilization (testing).\n'
        '• Mission watchlist added.\n'
        '• Deep Dive bug fix.',
    'CN': '• 3款迷你游戏改进（Boss特殊能力、Nitra/手雷、危险等级、Pit Jaw、武器解锁）。\n'
        '• 小组件稳定化（测试中）。\n'
        '• 新增任务关注列表。\n'
        '• Deep Dive Bug修复。',
  },
  '1.4.0': {
    'KR': '• 코드 품질 개선: Lint 규칙 확장 및 버그 수정.\n'
        '• 미션 리스트 성능 최적화 (캐싱 적용).\n'
        '• 대형 파일 분해로 유지보수성 향상.\n'
        '• 서비스 에러 핸들링 강화.\n'
        '• 테스트 커버리지 대폭 확대 (84→109개).',
    'EN': '• Code quality: expanded lint rules and bug fixes.\n'
        '• Mission list performance optimization (caching).\n'
        '• Large files decomposed for better maintainability.\n'
        '• Improved service error handling.\n'
        '• Test coverage expanded significantly (84→109).',
    'CN': '• 代码质量改进：扩展 Lint 规则并修复 Bug。\n'
        '• 任务列表性能优化（缓存）。\n'
        '• 大文件拆分，提升可维护性。\n'
        '• 增强服务错误处理。\n'
        '• 测试覆盖率大幅提升（84→109）。',
  },
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
