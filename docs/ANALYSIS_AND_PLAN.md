# Bosco Terminal - 문제점 분석 & 개선 계획

> 2026-03-05 작성. 코드베이스 전체 분석 기반.
> **Phase A~C 실행 완료 (2026-03-05)** — 검증: `dart analyze` 0 issues, `flutter test` 109/109 통과.

---

## 1. 현재 문제점 (Critical Issues)

### 1.1 에러 처리 불일치 ✅ 해결

| 탭 | 에러 상태 UI | 로딩 UI | Pull-to-Refresh |
|----|-------------|---------|-----------------|
| LiveMissions | ✅ 에러+재시도 | ✅ Skeleton | ✅ |
| Highlights | ✅ 에러+재시도 | ✅ Skeleton | ✅ |
| DeepDives | ✅ 에러+재시도 | ✅ | ✅ |
| DwarfVoice | N/A | N/A | N/A |

**해결:** `MissionService.lastError` getter 추가. LiveMissions/Highlights에 에러 UI + 재시도 버튼 추가. Skeleton Loading 위젯(`skeleton_loading.dart`) 신규 생성.

### 1.2 Silent Failures (조용한 실패) — 부분 해결

- `mission_service.dart`: `lastError` getter 추가, 에러 상태 UI에서 사용자에게 표시 ✅
- `notification_service.dart`: `AndroidAlarmManager.oneShotAt()` 실패 시 무시 — 미해결
- `settings_screen.dart`: 알림 활성화/비활성화 시 SnackBar 피드백 추가 ✅
- `dwarf_voice_tab.dart`: `_playRandomSound`에 try-catch + 실패 시 SnackBar 추가 ✅

### 1.3 탭 전환 시 상태 손실 ✅ 해결

```dart
// main_screen.dart — IndexedStack 적용 완료
body: IndexedStack(
  index: _currentIndex,
  children: tabs,
),
```

스크롤 위치, 시간 오프셋, 선택 상태가 탭 전환 시에도 유지됨.

### 1.4 Splash Screen 레이스 컨디션 ✅ 해결

- `_preloadData()`에 try-catch 추가: 데이터 로딩 실패해도 앱 진입 허용 (캐시/오프라인 모드)
- 매직넘버 `2500` → `AppConstants.splashMinDurationMs`로 상수화
- 기존 `_tryNavigate()` 로직(`_animationDone && _dataDone`)은 정상 — 실패 시 무한 대기만 수정

### 1.5 알림 시간 범위 검증 없음 ✅ 해결

- `_pickNotifEndTime()`에 종료 시간 < 시작 시간 검증 추가
- 해당 시 경고 SnackBar 표시 (3개 언어: `notif_time_warning`)

### 1.6 시간 동기화 경고 부족

- 시계 오차(`clockDrift`) 감지 시 `debugPrint`만 출력
- 미션 시간대가 실제와 다를 수 있음을 사용자에게 명시적으로 알리지 않음
- 특정 탭에서만 배너 표시, 다른 탭에서는 보이지 않음

---

## 2. 코드 품질 개선

### 2.1 매직 넘버 상수화 — 부분 완료

| 현재 | 위치 | 상태 |
|------|------|------|
| `1800` | live_missions_tab.dart | ✅ `AppConstants.missionRotationMinutes * 60` |
| `2500` (ms) | splash_screen.dart | ✅ `AppConstants.splashMinDurationMs` |
| `0.75`, `0.62`, `0.08` | 여러 위젯 | 미해결 (Phase D) |
| `30` (분) | 여러 서비스 | ✅ 이미 `AppConstants.missionRotationMinutes` 사용 중 |

### 2.2 Build 메서드 내 문자열 파싱

```dart
// mission_card.dart:207-211
final ws = mission.debuff!.split(',').map((e) => e.trim())...
```

매 렌더링마다 debuff 문자열 파싱 → `Mission` 모델에 `List<String> get debuffList` 캐시 필요

### 2.3 타입 안전성

```dart
// notification_service.dart:301-303
final titles = langMessages['titles'] as List;  // unsafe cast
```

딕셔너리 → `List` 캐스팅이 안전하지 않음. 타입드 모델 사용 권장.

---

## 3. UX 개선 계획

### 3.1 로딩 경험 ✅ 완료

- `lib/widgets/skeleton_loading.dart` 신규 생성 (`MissionCardSkeleton`, `SkeletonLoadingList`)
- 미션 카드 형태의 pulse 애니메이션 스켈레톤 (94px 높이, 바이옴/텍스트/아이콘 영역)
- LiveMissionsTab, HighlightsTab에서 `CircularProgressIndicator` → `SkeletonLoadingList` 교체

### 3.2 에러 상태 통일 ✅ 완료

- `MissionService`에 `lastError` getter 추가
- LiveMissionsTab, HighlightsTab에 DeepDivesTab과 동일한 패턴 적용
  - `Icons.wifi_off` + `load_error` 메시지 + `retry` 버튼
- i18n 문자열 추가: `load_error`, `retry` (3개 언어)

### 3.3 오프라인 모드 개선 ✅ 완료

- 하단 떠다니는 오버레이 → AppBar `bottom` 슬림 배너(28px)로 변경
- offline: 주황 배너 + `cloud_off` 아이콘, outdated: 빨간 배너 + `warning` 아이콘
- 탭으로 즉시 새로고침 가능 (`_missionService.forceRefresh()`)
- `MissionService.getCacheTime()` getter 추가 (향후 "X시간 전" 표시 가능)

### 3.4 탭 상태 보존 ✅ 완료

`main_screen.dart`에서 `IndexedStack` 적용 완료.

### 3.5 Pull-to-Refresh 전체 적용 ✅ 기존 완료 확인

확인 결과 LiveMissions, Highlights, DeepDives 3탭 모두 이미 `RefreshIndicator` 적용되어 있음.

### 3.6 설정 변경 피드백 ✅ 완료

- `_toggleNotification`에 활성화/비활성화 SnackBar 추가 (녹색/회색)
- i18n 문자열 추가: `notif_enabled`, `notif_disabled` (3개 언어)

### 3.7 DwarfVoice 탭 뒤로가기 ✅ 완료

- `PopScope` 래핑: 미니게임→목록→메인 순차 뒤로가기
- `canPop: _dwarfPage == _DwarfPage.shouts` — shouts 페이지에서만 시스템 뒤로가기 허용

### 3.8 오디오 재생 피드백 ✅ 완료

- `_playRandomSound`에 try-catch 추가
- 에러 시 빨간 SnackBar ("Audio playback failed")

---

## 4. 접근성 개선

### 4.1 시맨틱 레이블 (Priority: Medium)

```dart
// 현재: 아이콘만
Icon(Icons.warning, size: 18)

// 개선: 시맨틱 레이블 추가
Semantics(
  label: 'Warning: Haunted Cave',
  child: Icon(Icons.warning, size: 18),
)
```

적용 대상:
- 미션 카드 내 buff/debuff 아이콘
- 탭 바 아이콘
- 설정 화면 토글

### 4.2 색상만으로 구분하는 요소 개선

- Double XP: 금색 테두리 + 텍스트 라벨 추가 (색맹 사용자)
- 과거/현재/미래 미션: 투명도 + 텍스트 라벨 ("Past", "Now", "Next")

### 4.3 터치 타겟 크기

- 최소 48x48dp 보장 (Material Design 가이드라인)
- 특히 미션 카드 내 작은 아이콘 (현재 30x30)

---

## 5. 성능 개선

### 5.1 불필요한 리빌드 최소화 (Priority: Medium)

```dart
// 현재: 전체 탭 리빌드
void _onDataChanged() => setState(() {});

// 개선: 변경된 데이터만 비교 후 리빌드
void _onDataChanged() {
  if (_missionService.dataVersion != _cachedDataVersion) {
    setState(() { _cachedDataVersion = _missionService.dataVersion; });
  }
}
```

참고: LiveMissionsTab은 이미 `_dataVersion` 캐시 사용 중 — 다른 탭에도 동일 패턴 적용

### 5.2 이미지 캐싱 설정 (Priority: Low)

```dart
// main.dart에서 앱 초기화 시
PaintingBinding.instance.imageCache.maximumSize = 100;
PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50MB
```

### 5.3 Mission 모델 파생 데이터 캐시 (Priority: Low)

```dart
class Mission {
  // 기존 필드...

  // 캐시된 파생 데이터
  late final List<String> debuffList =
    debuff?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];
  late final List<String> buffList =
    buff?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];
}
```

---

## 6. 실행 우선순위

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Phase   작업                          난이도  영향도  상태
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 A       탭 상태 보존 (IndexedStack)     Low    High   ✅
 A       에러 상태 통일 (3탭)            Med    High   ✅
 A       Pull-to-Refresh 전체 적용       Low    Med    ✅ (기존 완료)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 B       Skeleton Loading               Med    High   ✅
 B       오프라인 모드 개선              Low    Med    ✅
 B       알림 시간 검증                  Low    Med    ✅
 B       DwarfVoice 뒤로가기 수정       Low    Med    ✅
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 C       Splash 레이스컨디션 수정        Med    Med    ✅
 C       설정 피드백 SnackBar            Low    Low    ✅
 C       오디오 에러 처리                Low    Low    ✅
 C       매직넘버 상수화                 Low    Low    ✅ (부분)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 D       접근성 (시맨틱 레이블)          Med    Med    미착수
 D       빌드 메서드 최적화              Low    Low    미착수
 D       Mission 모델 캐시              Low    Low    미착수
 D       이미지 캐시 설정               Low    Low    미착수
 D       opacity 매직넘버 상수화         Low    Low    미착수
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Phase A~C** → 2026-03-05 완료
**Phase D** → 여유 시 진행, 장기 개선

---

## 7. 기존 문서와의 관계

| 문서 | 범위 | 이 문서와의 관계 |
|------|------|-----------------|
| `docs/IMPROVEMENT_PLAN.md` | 코드 품질/구조 리팩토링 | Phase 0~4 완료. Phase 5(Riverpod) 미착수 |
| `docs/FEATURE_ROADMAP.md` | 신규 기능 기획 | F1~F6 기능 추가 로드맵 (독립) |
| `docs/SURVIVOR_MINIGAME_PLAN.md` | 미니게임 개발 | Phase 2+ 개발 계획 (독립) |
| **이 문서** | 기존 기능의 버그/UX/성능 | 위 문서들과 독립적으로 실행 가능 |

---

*Phase A~C 완료 (2026-03-05). Phase D 여유 시 진행.*
*검증: `dart analyze` 0 issues, `flutter test` 109/109 통과.*
