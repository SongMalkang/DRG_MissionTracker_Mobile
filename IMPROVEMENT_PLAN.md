# Bosco Terminal - 개선 계획 (v2)

## 현재 상태 요약

| 항목 | 현황 |
|------|------|
| Framework | Flutter (Dart 3.11+) |
| Dart 파일 수 | 14개, ~2,500줄 |
| 테스트 | 0개 (커버리지 0%) |
| 상태 관리 | StatefulWidget + setState() (프레임워크 없음) |
| CI/CD | GitHub Actions - 데이터 업데이트만 (빌드/테스트 없음) |
| 지원 언어 | 3개 (KR, EN, ZH) |
| 지원 플랫폼 | 6개 (iOS, Android, Web, Windows, macOS, Linux) |

---

## 실행 전략

```
┌─────────────────────────────────────────────────────────┐
│           안전 구간 (기존 동작 유지하며 개선)              │
│                                                         │
│  Phase 1  →  Phase 2  →  Phase 3  →  Phase 4           │
│  상수화/     에러 처리    코드 정리    테스트 작성         │
│  테마 분리   강화                                        │
│                                                         │
├─────────────── ✅ 체크포인트: 전체 테스트 통과 ───────────┤
│                                                         │
│           구조 변경 구간 (아키텍처 리팩토링)               │
│                                                         │
│  Phase 5  →  Phase 6                                    │
│  상태 관리    아키텍처/                                   │
│  + i18n      UX 개선                                    │
└─────────────────────────────────────────────────────────┘
```

---

## Phase 1: 매직 스트링 상수화 + 테마 분리

**위험도**: 낮음 | **영향 범위**: 전체 파일에서 참조만 변경

### 1-1. 상수 파일 생성

`lib/utils/constants.dart` 신규 생성:

```dart
class AppConstants {
  // API
  static const String missionDataBaseUrl = 'https://raw.githubusercontent.com/...';
  static const String deepDiveBaseUrl = 'https://doublexp.net/static/json/deepdives/';
  static const String bulkMissionBaseUrl = 'https://doublexp.net/static/json/bulkmissions/';

  // Timing
  static const int missionRotationMinutes = 30;
  static const int networkTimeoutSeconds = 10;
  static const int maxRetryAttempts = 3;
  static const int dataFreshnessMinutes = 30;

  // UI
  static const double elapsedMissionOpacity = 0.38;
  static const double cardBorderRadius = 12.0;
}
```

### 1-2. 테마 분리

`lib/utils/theme.dart` 신규 생성:
- `main.dart`의 `ThemeData` 정의를 별도 파일로 이동
- 색상 상수 (`AppColors`) 정의

**변경 대상**: `main.dart`, `live_missions_tab.dart`, `highlights_tab.dart`, `deep_dives_tab.dart`, `mission_card.dart`, `mission_service.dart`

---

## Phase 2: 에러 처리 강화

**위험도**: 낮음 | **영향 범위**: 서비스 및 데이터 로딩 부분만

### 2-1. 네트워크 요청 안정화

`mission_service.dart` 수정:
- 타임아웃 5초 → `AppConstants.networkTimeoutSeconds` (10초)
- 지수 백오프 재시도 로직 추가 (최대 3회: 1초, 2초, 4초)

```dart
Future<http.Response> _fetchWithRetry(String url) async {
  for (int attempt = 0; attempt < AppConstants.maxRetryAttempts; attempt++) {
    try {
      final response = await http.get(Uri.parse(url))
          .timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));
      if (response.statusCode == 200) return response;
    } catch (_) {}
    if (attempt < AppConstants.maxRetryAttempts - 1) {
      await Future.delayed(Duration(seconds: 1 << attempt)); // 1s, 2s, 4s
    }
  }
  throw Exception('Failed after ${AppConstants.maxRetryAttempts} attempts');
}
```

### 2-2. Deep Dive 파싱 안전 처리

`deep_dives_tab.dart` 수정:
- HTML 파싱 전체를 try-catch로 감싸기
- 파싱 실패 시 에러 UI 표시 (크래시 방지)

### 2-3. 전역 에러 바운더리

`main.dart`에 `FlutterError.onError` 및 `runZonedGuarded` 추가:
- 예기치 않은 에러 시 앱 크래시 대신 에러 화면 표시

---

## Phase 3: 코드 정리

**위험도**: 낮음 | **영향 범위**: 불필요한 코드 제거만

### 3-1. 불필요한 파일/코드 제거

- `lib/utils/mock_data.dart` 삭제 (전체 주석 처리된 상태)
- `print()` 문을 `debugPrint()`로 교체 (릴리즈 빌드에서 자동 무시)

### 3-2. 디버그 기능 격리

- `debugSetStatus()`, `_cycleDebugStatus()` → `kDebugMode` 체크로 감싸기
- 릴리즈 빌드에서는 디버그 기능이 완전히 비활성화

```dart
if (kDebugMode) {
  // 디버그 전용 기능
}
```

---

## Phase 4: 테스트 인프라 구축

**위험도**: 낮음 (기존 코드 수정 없음) | **영향 범위**: 신규 테스트 파일만 추가

### 4-1. 단위 테스트 (우선순위 높음)

| 테스트 대상 | 파일 | 검증 항목 |
|------------|------|-----------|
| Mission 모델 | `test/models/mission_model_test.dart` | fromJson 변환, null 필드 처리, Double XP 판별 |
| MissionService | `test/services/mission_service_test.dart` | JSON 파싱, 시즌 필터링, 시간 슬롯 계산 |
| SettingsService | `test/services/settings_service_test.dart` | 기본값, 저장/로드 |
| AssetHelper | `test/utils/asset_helper_test.dart` | 바이옴/미션 아이콘 경로 생성 |
| Strings | `test/utils/strings_test.dart` | 모든 언어에 키 누락 없는지 검증 |

### 4-2. 위젯 테스트 (우선순위 중간)

| 테스트 대상 | 파일 | 검증 항목 |
|------------|------|-----------|
| MissionCard | `test/widgets/mission_card_test.dart` | 렌더링, Double XP 뱃지, 탭 동작 |
| MainScreen | `test/screens/main_screen_test.dart` | 탭 전환, 네비게이션 |

### 4-3. 목표

- 핵심 서비스 커버리지 80%+
- 모든 테스트 통과 확인 후 Phase 5로 진행

---

## ✅ 체크포인트: Phase 1~4 검증

Phase 5 진행 전 반드시 확인:
1. `flutter analyze` - 린트 경고 0개
2. `flutter test` - 전체 테스트 통과
3. 기존 기능 정상 동작 (수동 확인)
   - Live Missions 탭: 시즌 필터, 시간 오프셋
   - Highlights 탭: Double XP 타임라인
   - Deep Dives 탭: 데이터 로딩
   - Settings: 언어/시즌 변경

---

## Phase 5: 상태 관리 도입 + i18n 개선

**위험도**: 중간~높음 | **영향 범위**: 거의 모든 화면 파일 변경

### 5-1. Riverpod 상태 관리 도입

**현재 문제**: prop drilling으로 lang/season을 모든 탭에 수동 전달

**개선**:
```
lib/providers/
├── lang_provider.dart       # 언어 상태
├── season_provider.dart     # 시즌 상태
├── mission_provider.dart    # 미션 데이터 + 로딩 상태
└── deep_dive_provider.dart  # 딥다이브 데이터
```

**변경 대상**:
- `main.dart` → `ProviderScope`로 래핑
- 모든 화면 → `ConsumerWidget`으로 전환
- `main_screen.dart` → 콜백 prop drilling 제거

### 5-2. 서비스 레이어 리팩토링

```
lib/repositories/
├── mission_repository.dart    # 데이터 소스 추상화 (네트워크 + 로컬 캐시)
└── deep_dive_repository.dart  # 딥다이브 데이터 분리

lib/services/
├── mission_service.dart       # 비즈니스 로직만 (필터링, 정렬)
└── settings_service.dart      # 유지
```

### 5-3. i18n 시스템 개선

- `easy_localization` 또는 `intl` 패키지 도입
- `strings.dart`의 Map 기반 번역 → ARB 파일 기반으로 전환
- 새 언어 추가 시 코드 수정 없이 ARB 파일만 추가

### 5-4. Phase 5 검증

- 기존 Phase 4 테스트 전체 통과 확인
- Provider 관련 테스트 추가
- 전체 기능 수동 검증

---

## Phase 6: 사용자 경험 개선

**위험도**: 중간 | **영향 범위**: 신규 기능 추가

### 6-1. 오프라인 지원 강화

- 마지막 성공 데이터를 로컬 파일로 영구 캐싱
- 오프라인에서도 캐시된 데이터로 전체 기능 사용 가능
- 데이터 신선도 표시 ("2시간 전 업데이트")

### 6-2. 검색 및 필터 기능

- 바이옴, 미션 타입, 목표 등 다중 필터
- 즐겨찾기 미션 타입 설정 및 하이라이트

### 6-3. 푸시 알림 (선택)

- Double XP 미션 알림
- 딥다이브 갱신 알림 (매주 목요일)

### 6-4. 홈 화면 위젯 (선택)

- Android/iOS 홈 화면 위젯
- 현재 미션 또는 다음 Double XP 시간 표시

---

## CI/CD 계획

### 워크플로우 1: 데이터 업데이트 (기존 유지)

> 파일: `.github/workflows/update_data.yml` (변경 없음)

```
매일 00:05 UTC
  → Python 스크립트 실행 (fetch_daily_missions.py)
  → doublexp.net에서 어제/오늘/내일 미션 데이터 수집
  → data/daily_missions.json 갱신
  → 자동 커밋 & 푸시 [skip ci]
```

- 이 워크플로우는 현재 잘 동작하므로 그대로 유지
- `[skip ci]` 태그로 코드 품질 워크플로우가 불필요하게 트리거되지 않음

### 워크플로우 2: 코드 품질 (신규 추가)

> 파일: `.github/workflows/ci.yml` (신규)

```yaml
name: CI

on:
  push:
    branches: [main]
    paths-ignore:
      - 'data/**'          # JSON 데이터 변경 시 스킵
      - '**.md'             # 문서 변경 시 스킵
  pull_request:
    branches: [main]

jobs:
  analyze:
    name: Lint & Analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: dart analyze --fatal-infos

  test:
    name: Unit & Widget Tests
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter test --coverage
      # 선택: 커버리지 리포트 업로드
      # - uses: codecov/codecov-action@v4
      #   with:
      #     file: coverage/lcov.info

  build:
    name: Build Verification
    runs-on: ubuntu-latest
    needs: test
    strategy:
      matrix:
        target: [apk, web]
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter build ${{ matrix.target }} --release
```

**핵심 설계 결정**:

| 항목 | 결정 | 이유 |
|------|------|------|
| 트리거 | push + PR (main) | 코드 변경 시만 실행 |
| `data/**` 제외 | `paths-ignore` | JSON 업데이트는 코드 품질과 무관 |
| 빌드 대상 | APK + Web | iOS는 macOS 러너 비용이 높으므로 제외 |
| 실행 순서 | analyze → test → build | 빠른 실패: 린트 → 테스트 → 빌드 순 |
| 커버리지 | 선택 사항 | Phase 4 완료 후 Codecov 연동 가능 |

### 워크플로우 관계도

```
┌─────────────────────────────────────────────────────┐
│                   GitHub Actions                     │
│                                                     │
│  ┌─────────────────────┐  ┌──────────────────────┐  │
│  │  update_data.yml    │  │  ci.yml              │  │
│  │  (기존 유지)         │  │  (신규 추가)          │  │
│  │                     │  │                      │  │
│  │  트리거: 매일 00:05  │  │  트리거: push/PR     │  │
│  │  + 수동 dispatch    │  │  (data/** 제외)      │  │
│  │                     │  │                      │  │
│  │  Python 스크립트    │  │  ① dart analyze      │  │
│  │  → JSON 갱신       │  │  ② flutter test      │  │
│  │  → 자동 커밋       │  │  ③ flutter build     │  │
│  │    [skip ci]       │  │     (APK + Web)      │  │
│  └─────────────────────┘  └──────────────────────┘  │
│         ↕ 독립 운영           ↕ 코드 변경 시만       │
└─────────────────────────────────────────────────────┘
```

---

## 전체 실행 순서 요약

| 순서 | Phase | 내용 | 위험도 | 기존 코드 수정 |
|------|-------|------|--------|---------------|
| 1 | Phase 1 | 매직 스트링 상수화 + 테마 분리 | 낮음 | 참조 변경만 |
| 2 | Phase 2 | 에러 처리 강화 | 낮음 | 서비스 일부 |
| 3 | Phase 3 | 코드 정리 (불필요 코드 삭제) | 낮음 | 삭제만 |
| 4 | Phase 4 | 테스트 작성 + CI 워크플로우 추가 | 낮음 | 신규 파일만 |
| - | **체크포인트** | **전체 테스트 통과 + 기능 검증** | - | - |
| 5 | Phase 5 | Riverpod + 서비스 분리 + i18n | 중~높음 | 거의 전체 |
| 6 | Phase 6 | UX 개선 (오프라인, 필터, 알림) | 중간 | 신규 기능 |

---

## 참고: 현재 유지해야 할 강점

- 깔끔한 UI/UX 디자인 (다크 테마, 애니메이션)
- 효율적인 데이터 파이프라인 (GitHub Actions + Python 스크래퍼)
- 멀티 플랫폼 지원
- 3개 언어 지원
- 오프라인 감지 및 사용자 알림
