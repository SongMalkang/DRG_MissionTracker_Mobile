// ═══════════════════════════════════════════════════════════════════════════
//  알림 공유 상수 및 유틸리티
//  Android(notification_service.dart)와 Web(web_notification_service.dart)
//  양쪽에서 사용하는 코드를 분리하여 dart:io 의존성 문제를 해결한다.
// ═══════════════════════════════════════════════════════════════════════════

// ── 보스코 테마 위트있는 알림 메시지 (언어별 · 5개 변형) ──────────────────────

const boscoMessages = {
  'KR': {
    'titles': [
      '📡 BOSCO 정찰 보고',
      '⛏️ 미션 컨트롤 수신',
      '🍺 Double XP 발견!',
      '🚀 광부님, 출동 요청!',
      '💎 BOSCO 긴급 전파',
    ],
    'prefixes': [
      'BOSCO가 열심히 정찰한 결과입니다.',
      '미션 컨트롤에서 보너스 미션을 탐지했습니다.',
      'BOSCO가 XP 두 배 구역을 발견했습니다!',
      '지금 출발하면 보너스를 챙길 수 있습니다!',
      '경고: 높은 가치의 미션이 진행 중입니다.',
    ],
  },
  'EN': {
    'titles': [
      '📡 BOSCO Scouting Report',
      '⛏️ Mission Control Incoming',
      '🍺 Double XP Detected!',
      '🚀 Miner, Gear Up!',
      '💎 BOSCO Priority Alert',
    ],
    'prefixes': [
      'BOSCO reporting in. Don\'t miss this!',
      'Mission Control has flagged bonus missions.',
      'BOSCO detected a Double XP zone!',
      'Suit up, miner — bonuses are live!',
      'Warning: High-value missions in progress.',
    ],
  },
  'CN': {
    'titles': [
      '📡 博斯科侦察报告',
      '⛏️ 任务控制收到信号',
      '🍺 发现双倍经验！',
      '🚀 矿工，出发吧！',
      '💎 博斯科紧急通报',
    ],
    'prefixes': [
      '博斯科侦察完毕，不要错过！',
      '任务控制检测到奖励任务。',
      '博斯科发现了双倍经验区域！',
      '穿上装备，矿工——奖励已上线！',
      '警告：高价值任务正在进行中。',
    ],
  },
};

/// 30분 슬롯 인덱스: 0(00:00) ~ 47(23:30)
int toSlot(int hour, int minute) => hour * 2 + (minute >= 30 ? 1 : 0);

/// UTC 시간을 미션 데이터 키 형식으로 변환
String formatTimeKey(DateTime utcTime) {
  final y   = utcTime.year.toString();
  final m   = utcTime.month.toString().padLeft(2, '0');
  final d   = utcTime.day.toString().padLeft(2, '0');
  final h   = utcTime.hour.toString().padLeft(2, '0');
  final min = (utcTime.minute < 30) ? '00' : '30';
  return '$y-$m-${d}T$h:$min:00Z';
}
