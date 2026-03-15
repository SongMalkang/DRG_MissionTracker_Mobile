// 앱 내장 Changelog 데이터
// 버전별 변경사항을 다국어로 정의한다.
// key: pubspec.yaml의 version (예: '1.1.0')

const Map<String, Map<String, String>> changelogData = {
  '2.0.0': {
    'KR': '• 오버클럭 수집 트래커 추가: 4클래스 × 24무기 × 159개 오버클럭 체크리스트.\n'
        '• 캐릭터별 수집 진행률 및 전체 진행률 표시.\n'
        '• 무기별 아코디언 UI로 오버클럭 관리 (Clean/Balanced/Unstable 등급 표시).\n'
        '• 오버클럭 상세 모달: 효과 설명 및 수집 토글.\n'
        '• 수집 상태 로컬 저장 (앱 재시작 후에도 유지).\n'
        '• 로드아웃 동기화 기능 예고 (인게임 모드 연동 준비중).\n'
        '• 위키 기반 무기/오버클럭 아이콘 에셋 추가 (WebP).',
    'EN': '• Overclock Collection Tracker: 4 classes × 24 weapons × 159 overclocks checklist.\n'
        '• Per-character and overall collection progress display.\n'
        '• Weapon accordion UI for overclock management (Clean/Balanced/Unstable tiers).\n'
        '• Overclock detail modal: effect description & collection toggle.\n'
        '• Collection state persisted locally (survives app restart).\n'
        '• Loadout Sync feature teased (in-game mod integration coming soon).\n'
        '• Wiki-based weapon/overclock icon assets added (WebP).',
    'CN': '• 新增超频收集追踪器：4职业 × 24武器 × 159个超频清单。\n'
        '• 按角色和总体显示收集进度。\n'
        '• 武器手风琴UI管理超频（Clean/Balanced/Unstable等级显示）。\n'
        '• 超频详情弹窗：效果描述及收集切换。\n'
        '• 收集状态本地持久化（重启应用后保持）。\n'
        '• 配装同步功能预告（游戏内模组集成准备中）。\n'
        '• 新增基于Wiki的武器/超频图标资源（WebP）。',
  },
  '1.6.2': {
    'KR': '• Deep Dive 스테이지 상세 모달 추가 (바이옴 배경, 보조 목표, 길이/복잡도, 경고).\n'
        '• 하이라이트 탭에 "모레 일정" 구분선 추가.\n'
        '• 알림 안내 문구 개선: Android APK 알림 지원 안내 명확화.\n'
        '• Deep Dive 신규 목표 번역 추가 (Mine Morkite, Get Alien Eggs).\n'
        '• JetBoots 미니게임 조작성 개선 (중력·상승력 완화).',
    'EN': '• Deep Dive stage detail modal (biome background, secondary objectives, length/complexity, warnings).\n'
        '• "Day After Tomorrow" divider in Highlights tab.\n'
        '• Clarified notification messages: Android APK alert support.\n'
        '• New Deep Dive objective translations (Mine Morkite, Get Alien Eggs).\n'
        '• JetBoots mini-game smoother controls (reduced gravity & thrust).',
    'CN': '• 新增Deep Dive阶段详情弹窗（生态背景、次要目标、长度/复杂度、警告）。\n'
        '• 亮点标签新增"后天"分隔线。\n'
        '• 改进通知提示文案：明确Android APK通知支持。\n'
        '• 新增Deep Dive目标翻译（Mine Morkite、Get Alien Eggs）。\n'
        '• JetBoots迷你游戏操控优化（降低重力和推力）。',
  },
  '1.6.1': {
    'KR': '• Deep Dive 데이터 갱신 안정성 개선.\n'
        '• 주간 리셋 시 구 데이터가 계속 표시되던 문제 수정.\n'
        '• 데이터 수집 타이밍 최적화 (목요일 11:01 UTC).\n'
        '• Deep Dive 갱신 상태를 배너로 정확히 표시.',
    'EN': '• Improved Deep Dive data refresh stability.\n'
        '• Fixed stale data persisting after weekly reset.\n'
        '• Optimized data collection timing (Thu 11:01 UTC).\n'
        '• Accurate Deep Dive refresh status banner.',
    'CN': '• 改进Deep Dive数据刷新稳定性。\n'
        '• 修复每周重置后旧数据持续显示的问题。\n'
        '• 优化数据收集时间（周四 11:01 UTC）。\n'
        '• 准确显示Deep Dive刷新状态横幅。',
  },
  '1.6.0': {
    'KR': '• PWA 전면 전환: 모든 플랫폼에서 브라우저로 설치 가능.\n'
        '• PC 브라우저 웹 알림 지원 (Web Notification API).\n'
        '• 도움말 버튼 추가: 플랫폼별 PWA 설치 가이드.\n'
        '• APK 다운로드 안내 (GitHub Releases 링크).\n'
        '• 알림 설정 UI 개선: 플랫폼별 지원 현황 안내.\n'
        '• README 대규모 개편: PWA 링크, Discord 연락처, Ko-fi.',
    'EN': '• Full PWA pivot: installable via browser on all platforms.\n'
        '• PC browser web notifications (Web Notification API).\n'
        '• Help button: platform-specific PWA install guide.\n'
        '• APK download card (GitHub Releases link).\n'
        '• Notification settings UI: per-platform support info.\n'
        '• README overhaul: PWA link, Discord contact, Ko-fi.',
    'CN': '• PWA全面转型：所有平台均可通过浏览器安装。\n'
        '• PC浏览器Web通知支持（Web Notification API）。\n'
        '• 新增帮助按钮：各平台PWA安装指南。\n'
        '• APK下载卡片（GitHub Releases链接）。\n'
        '• 通知设置UI改进：各平台支持状态提示。\n'
        '• README大规模改版：PWA链接、Discord联系方式、Ko-fi。',
  },
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
