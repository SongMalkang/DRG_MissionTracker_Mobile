# Bosco Terminal - Feature Roadmap

> 기능 기획 문서. 기술적 리팩토링은 `IMPROVEMENT_PLAN.md` 참조.

## Platform Strategy

| Platform | Method | Cost | Note |
|----------|--------|------|------|
| Android | Play Store | $25 (one-time) | Primary target |
| iOS / Web | Flutter Web (PWA) | $0 (hosting only) | Apple Store $99/yr 배제 |

Flutter Web은 번들 사이즈(2MB+)가 크지만, 타겟 유저(PC 게이머)의 네트워크 환경에서 허용 범위.
코드베이스 단일 유지가 우선. 웹 UX 불만족 시 경량 PWA 별도 개발 검토.

---

## Feature Priority

```
[P0] Push Notification     ← app 존재 이유. 웹 불가 기능.
[P0] Android Home Widget   ← app 존재 이유. 웹 불가 기능.
[P1] Mutator/Warning 설명  ← 기존 UI에 녹이는 방식. 작업량 적음.
[P2] Double XP 통계        ← 기존 데이터 활용. 차별화 요소.
[P2] Custom Watchlist       ← Push 알림 확장. 개인화.
[P3] Daily Deal 표시        ← 데이터 이미 존재. 여유 시 추가.
```

---

## F1: Push Notification (P0)

### 개요
Double XP 미션 등장 시 사용자에게 즉시 알림.
게임을 켜지 않아도, 웹사이트에 접속하지 않아도, 폰 알림으로 "지금 Double XP" 확인.

### 핵심 요구사항

**스팸 방지 (Critical)**
- 활성 시간대 설정: 사용자가 알림 수신 시간 지정 (예: 18:00~24:00)
- 요일별 on/off (평일 저녁만, 주말 종일 등)
- 쿨다운: 동일 조건 알림 최소 간격 설정 (예: 1시간)
- DND(Do Not Disturb) 연동: 시스템 DND 모드 자동 존중

**알림 유형**
- Double XP 등장 (기본, 기본 활성화)
- Custom Watchlist 조건 매칭 (F5 구현 후 연동)
- Deep Dive 주간 리셋 (목요일 11:00 UTC, 선택적)
- Daily Deal 갱신 (자정 GMT, 선택적)

**기술 구현**
- Package: `flutter_local_notifications` + `workmanager` (Android background task)
- 동작: 30분 주기로 doublexp.net JSON 폴링 → 조건 매칭 → 로컬 알림
- 백엔드 불필요: 클라이언트 사이드 폴링 + 로컬 알림
- 배터리: Android WorkManager가 OS 최적화 존중 (Doze mode 등)
- 데이터: 30분마다 수 KB JSON fetch → 데이터 사용량 무시 가능

**설정 UI**
```
[알림 설정]
├─ Double XP 알림: [ON/OFF]
├─ 활성 시간: [18:00] ~ [24:00]
├─ 활성 요일: [월 화 수 목 금 토 일]
├─ 최소 간격: [1시간 ▼]
├─ Deep Dive 리셋 알림: [ON/OFF]
└─ Daily Deal 알림: [ON/OFF]
```

**PWA 제한사항**
- iOS PWA에서는 Push API 지원이 제한적 (iOS 16.4+에서 부분 지원)
- Web Push는 서버(FCM 등) 필요 → 초기에는 Android only로 제한
- iOS 사용자에게는 "앱을 열어서 확인" 안내

### 배제 사항
- Steam 친구 게임 시작 감지: 기술적으로 가능하나 (Steam Web API GetPlayerSummaries),
  사용자 Steam API Key 발급 필요 + 프로필 공개 필수 + 모바일 폴링 배터리 부담 +
  진입장벽 대비 사용률 낮을 것으로 판단. **배제.**

---

## F2: Android Home Widget (P0)

### 개요
앱을 열지 않고 홈 화면에서 현재 Double XP 상태를 즉시 확인.
Push 알림과 함께 "앱이어야만 가능한 기능" #2.

### 위젯 타입

**Small Widget (2x1)**
```
┌──────────────────┐
│ ⚡ Double XP NOW │
│  Mining Exp · 12m │
└──────────────────┘

또는 Double XP 없을 때:

┌──────────────────┐
│  No Double XP    │
│  Next rot: 18m   │
└──────────────────┘
```

**Medium Widget (4x2)**
```
┌────────────────────────────────┐
│ BOSCO TERMINAL                 │
│ ⚡ Double XP: Mining Exp       │
│    Azure Weald · Haz4          │
│ ─────────────────────────────  │
│ Next rotation: 12m 34s         │
│ Deep Dive resets in: 2d 5h     │
└────────────────────────────────┘
```

### 기술 구현
- Package: `home_widget` (Flutter)
- 업데이트 주기: 30분 (미션 로테이션과 동기화)
- 데이터: Background fetch로 최신 미션 데이터 캐싱 → 위젯에 표시
- Push 알림의 background worker와 데이터 공유 가능

### 제한사항
- Android 전용 (iOS 위젯은 Flutter 지원이 불안정, PWA 위젯 불가)
- 네트워크 없을 시 마지막 캐시 데이터 표시 + "offline" 표시

---

## F3: Mutator/Warning Quick Reference (P1)

### 개요
전체 코덱스가 아닌, 미션 카드 UI에 녹이는 방식의 빠른 참조.
뮤테이터/워닝 아이콘 탭 → 설명 팝업.

### 구현 방식
- 기존 미션 카드의 buff/debuff 아이콘에 onTap 추가
- 탭 시 BottomSheet 또는 Dialog로 설명 표시:
  ```
  ┌─────────────────────────┐
  │ ⚠️ Haunted Cave          │
  │                         │
  │ A Ghost will pursue the │
  │ team. Cannot be killed. │
  │ Keep moving!            │
  │                         │
  │ Tips:                   │
  │ · Scout flare helps     │
  │ · Don't stay stationary │
  └─────────────────────────┘
  ```

### 데이터 구조
```dart
// lib/data/mutator_info.dart
const Map<String, Map<String, Map<String, String>>> mutatorInfo = {
  'haunted_cave': {
    'en': {
      'name': 'Haunted Cave',
      'desc': 'A Ghost will pursue the team...',
      'tips': 'Keep moving. Scout flares help tracking.',
    },
    'ko': {
      'name': '유령 동굴',
      'desc': '유령이 팀을 추적합니다...',
      'tips': '계속 이동하세요. 스카우트 조명탄이 추적에 도움됩니다.',
    },
    'zh': { ... },
  },
};
```

### 작업량 예상
- Buffs (Anomalies): ~9개
- Debuffs (Warnings): ~11개
- 총 20개 항목 x 3개 언어 = 60개 번역 항목
- 정적 데이터, 앱 번들에 포함
- 게임 시즌 업데이트 시만 갱신 필요

### 확장 가능성
- 바이옴 설명 추가 (미션 카드 배경 이미지 탭)
- 미션 타입 설명 추가 (미션 아이콘 탭)
- 각각 11개, 10개 항목 → 점진적 추가 가능

---

## F4: Double XP Statistics (P2)

### 개요
축적된 미션 데이터를 활용한 Double XP 패턴 분석.
"데이터가 이미 있다"는 강점을 활용.

### 표시 정보
- 오늘/이번 주 Double XP 등장 횟수
- Double XP 평균 등장 간격
- 바이옴별 Double XP 빈도 (어느 바이옴에서 자주 뜨는지)
- 미션 타입별 Double XP 빈도
- 최근 7일 Double XP 히트맵 (시간대별)

### 데이터 소스
- doublexp.net의 daily JSON 파일 (날짜별 축적)
- URL 패턴: `https://doublexp.net/static/json/bulkmissions/YYYY-MM-DD.json`
- 과거 7일 데이터를 한번 fetch → 로컬 캐시 → 분석

### 기술 구현
- 백엔드 불필요: 클라이언트에서 JSON 파싱 + 집계
- UI: 새 탭 또는 Highlights 탭 내 섹션
- 차트: `fl_chart` 패키지 (경량)

---

## F5: Custom Watchlist (P2)

### 개요
사용자가 관심 조건을 설정하면, 해당 조건의 미션 등장 시 알림.
Push Notification(F1)의 확장 기능.

### 설정 예시
```
[나의 워치리스트]
├─ ⚡ Escort Duty + Double XP
├─ 🪨 Magma Core + Gold Rush
└─ + 새 조건 추가
```

### 조건 조합
- 미션 타입 (선택)
- 바이옴 (선택)
- 버프 (선택)
- 시즌 (선택)
- 조건은 AND 결합

### 기술 구현
- 로컬 스토리지 (SharedPreferences / Hive)
- F1 Push 알림의 background worker에서 조건 매칭
- 의존성: F1 (Push Notification) 구현 필요

---

## F6: Daily Deal Display (P3)

### 개요
일일 광물 거래 정보 표시. 하루 1회 갱신 (자정 GMT).

### 현재 상태
- doublexp.net JSON에 데이터 포함되어 있음 (확인 필요)
- 기존 도구 중 모바일에서 보여주는 곳 없음
- Bosco Discord bot 커뮤니티에서 요청된 기능

### 우선순위가 낮은 이유
- doublexp.net 웹에서 이미 제공 중
- 일일 광물 거래만으로 접속 동기 부여가 약함
- 구현 비용은 낮으니 여유 시 추가

### 구현 시
- Deep Dives 탭 하단 또는 별도 섹션
- "오늘의 거래: Croppa 150cr / Bismor 120cr"
- Daily Deal 알림 (F1과 연동, 선택적)

---

## Excluded Features (배제 사유)

| Feature | 사유 |
|---------|------|
| 멀티 Room 조회 | P2P 아키텍처로 구현 불가능 |
| 빌드 시뮬레이터 | DB/백엔드 필요, 독립 프로젝트 규모 (Karl.gg 존재) |
| 어사인먼트 헬퍼 | 해당 미션 타입이 매 로테이션마다 항상 존재하므로 불필요 |
| Steam 친구 감지 | API Key 발급 필요 + 프로필 공개 필수 + 배터리 부담 + ROI 낮음 |
| Apple Store 배포 | 연간 $99 비용 대비 타겟 유저 규모가 작음 |

---

## Implementation Dependencies

```
F1 (Push Notification) ──→ F5 (Custom Watchlist)
                       └──→ F6 (Daily Deal 알림)

F2 (Home Widget) ──→ F1과 background worker 공유 가능

F3 (Mutator Reference) ──→ 독립 구현 가능
F4 (Statistics) ──→ 독립 구현 가능
```

### 추천 구현 순서
```
1. F3 (Mutator Reference)  ← 가장 빠르게 완성 가능, 즉시 가치 제공
2. F1 (Push Notification)  ← 킬러 기능, 기술적 난이도 있음
3. F2 (Home Widget)        ← F1의 background worker 재활용
4. F4 (Statistics)         ← 데이터 활용, 독립 구현
5. F5 (Custom Watchlist)   ← F1 확장
6. F6 (Daily Deal)         ← 여유 시
```

---

## Value Proposition Summary

**"doublexp.net을 앱으로 옮긴 것" → "DRG 플레이어의 일상에 끼어드는 도구"**

| 가치 | 웹 가능? | 이 앱만? |
|------|----------|----------|
| 미션 보드 조회 | O | X |
| Double XP 하이라이트 | O | X |
| Push 알림 "지금 Double XP" | X | **O** |
| 홈 위젯 | X | **O** |
| 뮤테이터 즉시 참조 | 위키 가능 | **더 빠름** |
| 개인화된 워치리스트 알림 | X | **O** |
