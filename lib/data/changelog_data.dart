// 앱 내장 Changelog 데이터
// 버전별 변경사항을 다국어로 정의한다.
// key: pubspec.yaml의 version (예: '1.1.0')

const Map<String, Map<String, String>> changelogData = {
  '1.1.0': {
    'KR': '• 드워프 보이스 탭 추가 (버섯, 이스트콘, 금덩어리)\n'
        '• Push 알림 기능 추가\n'
        '• 중국어(简体) 지원 추가\n'
        '• UI/UX 개선 및 버그 수정',
    'EN': '• Added Dwarf Voice tab (Mushroom, Yeast Cone, Gold)\n'
        '• Added Push Notification feature\n'
        '• Added Chinese (Simplified) language support\n'
        '• UI/UX improvements and bug fixes',
    'CN': '• 添加矮人语音标签（蘑菇、酵母锥、金块）\n'
        '• 添加推送通知功能\n'
        '• 添加简体中文支持\n'
        '• UI/UX改进和错误修复',
  },
};
