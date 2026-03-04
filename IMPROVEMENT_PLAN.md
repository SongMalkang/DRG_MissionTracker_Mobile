# Bosco Terminal - 개선 계획 (v4)

> 아직 개발 단계. 과도한 설계/추상화 배제, 실용적 개선에 집중.

## 실행 전략

```
Phase 0 (Lint) → Phase 1 (구조) → Phase 3 (테스트) → Phase 5 (Riverpod)
                 Phase 2 (에러) → Phase 3 (테스트)
                 Phase 4 (성능) [Phase 1 이후]
```

---

## Phase 0: Lint 규칙 활성화 ✅

- `analysis_options.yaml`에서 `avoid_print: true`, `prefer_const_constructors: true` 활성화
- 18개 lint 위반 수정 (Icon, Padding, Text, Border, Duration 등에 `const` 추가)
- 검증: `dart analyze --fatal-infos` 통과

## Phase 1: 코드 구조 개선 ✅

### 1.1 게임 공통 색상 추출 ✅
- `lib/utils/game_colors.dart` 신규 생성
- JetBoots/WhackAMole 터미널 색상 + SurvivorGame 색상 통합
- 6개 파일에서 중복 색상 상수 제거

### 1.2 대형 파일 분해 ✅
| 원본 파일 | 원본 라인 | 분해 결과 |
|-----------|----------|-----------|
| `whack_a_mole_game.dart` | 1,817 | `lib/widgets/whack_a_mole/` (6개 파일) |
| `jet_boots_game.dart` | 1,041 | `lib/widgets/jet_boots/` (6개 파일) |
| `settings_screen.dart` | 653 | ~230줄 + `lib/widgets/settings/` (2개 위젯) |

- survivor_game 디렉토리 구조를 참고 패턴으로 활용

### 1.3 trivia_data.dart 외부화 ✅
- 710줄 하드코딩 Map → `data/trivia.json` + 비동기 로더
- `pubspec.yaml` 에셋 등록, `main.dart`에서 앱 시작 전 로드

## Phase 2: 에러 처리 강화 ✅

### 2.1 네트워크 재시도 + Exponential Backoff ✅
- `mission_service.dart`, `deep_dive_service.dart` 모두 1s→2s→4s 재시도 확인

### 2.2 서비스 Timer 정리 ✅
- `main_screen.dart`에 `WidgetsBindingObserver` 추가
- 백그라운드 전환 시 `pausePeriodicRefresh()`, 포그라운드 복귀 시 `resumePeriodicRefresh()`

### 2.3 누락 에셋 로깅 ✅
- `asset_helper.dart`에 `assetErrorBuilder` 메서드 추가 (debugPrint + fallback Icon)

### 2.4 Deep Dive 파싱 견고성 ✅
- `_parseDiveDataImpl`에 개별 dive 타입별 try-catch 강화 (Normal 실패해도 Elite 파싱 계속)

## Phase 3: 테스트 보강 ✅

### 현재: 9개 테스트 파일, 84개 테스트 통과

### 3.1 게임 엔진 테스트 ✅
- `test/widgets/survivor_game/game_engine_test.dart` 신규 (19개 테스트)
- 초기화, 웨이브, 적 스폰, HP/XP, 레벨업, 점수, 대시 검증

### 3.2 CI 커버리지 추가 ✅
- `ci.yml` 테스트 단계에 `--coverage` 플래그 + 아티팩트 업로드

## Phase 4: 성능 ✅

### 4.1 daily_missions.json 지연 파싱 ✅
- 현재 ±1 타임슬롯(현재+이전+다음 30분)만 즉시 파싱
- 나머지 슬롯은 `Future.microtask`로 지연 파싱 → UI 블로킹 최소화

### 4.2 시간 동기화 경고 ✅
- HTTP 응답의 `date` 헤더 파싱 → 디바이스 시간과 비교
- 5분+ 차이 시 `hasClockDrift` 플래그 활성화 + debugPrint 경고

---

## Phase 5: Riverpod 마이그레이션 (미착수 — Low)

- `flutter_riverpod` 추가, `ProviderScope` 래핑
- 서비스별 Provider → 화면별 점진적 ConsumerWidget 전환
- `highlights_tab.dart`부터 (가장 단순한 의존성)

---

## 검증 결과 (2026-03-04)

| 항목 | 결과 |
|------|------|
| `dart analyze --fatal-infos` | 0 issues |
| `flutter test` | 84/84 통과 |
| `flutter build web --release` | 성공 |
| `print()` 호출 | 0건 |
