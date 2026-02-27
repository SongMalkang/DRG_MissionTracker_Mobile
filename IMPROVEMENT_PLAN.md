# Bosco Terminal - 전반적 개선 계획

## 현재 상태 요약

| 항목 | 현황 |
|------|------|
| Framework | Flutter (Dart 3.11+) |
| Dart 파일 수 | 14개, ~2,500줄 |
| 테스트 | 0개 (커버리지 0%) |
| 상태 관리 | StatefulWidget + setState() (프레임워크 없음) |
| CI/CD | 데이터 업데이트만 (빌드/테스트 없음) |
| 지원 언어 | 3개 (KR, EN, ZH) |
| 지원 플랫폼 | 6개 (iOS, Android, Web, Windows, macOS, Linux) |

---

## Phase 1: 코드 품질 및 안정성 (기반 강화)

### 1-1. 상태 관리 도입 (Provider 또는 Riverpod)

**현재 문제**: setState() 기반으로 lang/season 등을 prop drilling으로 전달 중
- `main_screen.dart` → `live_missions_tab.dart` → `mission_card.dart`로 콜백과 값을 수동 전달

**개선 방향**:
- `Riverpod` 도입 (Flutter 생태계에서 가장 추천되는 상태 관리)
- `langProvider`, `seasonProvider`, `missionDataProvider` 등으로 전역 상태 분리
- 각 탭이 독립적으로 필요한 상태를 구독하도록 변경

**변경 대상 파일**:
- `lib/main.dart` - ProviderScope 래핑
- `lib/screens/main_screen.dart` - prop drilling 제거
- `lib/screens/live_missions_tab.dart` - ConsumerWidget으로 전환
- `lib/screens/highlights_tab.dart` - ConsumerWidget으로 전환
- `lib/screens/deep_dives_tab.dart` - ConsumerWidget으로 전환
- `lib/screens/settings_screen.dart` - Provider를 통해 설정 변경
- 새 파일: `lib/providers/` 디렉토리

### 1-2. 에러 처리 강화

**현재 문제**:
- `deep_dives_tab.dart`에서 파싱 에러 시 탭 크래시 가능
- 5초 네트워크 타임아웃으로 느린 네트워크에서 실패
- 재시도 로직 없음

**개선 방향**:
- `mission_service.dart`: 타임아웃을 10초로 증가, 지수 백오프 재시도 (최대 3회) 추가
- `deep_dives_tab.dart`: try-catch로 파싱 에러 안전 처리, 사용자에게 에러 UI 표시
- 전역 에러 바운더리 위젯 추가 (앱 크래시 방지)

### 1-3. 매직 스트링/값 상수화

**현재 문제**: URL, 지속 시간, 색상 등이 코드 곳곳에 하드코딩

**개선 방향**:
- `lib/utils/constants.dart` 생성
  - API URL들 (`doublexp.net` 엔드포인트)
  - 타이밍 값들 (30분 로테이션, 타임아웃 등)
  - UI 상수 (패딩, 투명도 값 등)
- `lib/utils/theme.dart` 생성
  - 현재 `main.dart`에 있는 ThemeData를 별도 파일로 분리

---

## Phase 2: 테스트 인프라 구축

### 2-1. 단위 테스트 추가

**우선순위 높음** (비즈니스 로직):
- `MissionService` - JSON 파싱, 캐싱, 필터링 로직
- `SettingsService` - SharedPreferences 읽기/쓰기
- `Mission` 모델 - fromJson 변환, 필드 유효성
- 시간 계산 로직 - UTC→로컬, 30분 슬롯, 목요일 감지

**우선순위 중간** (유틸리티):
- `AssetHelper` - 경로 생성 정확성
- `Strings` - 다국어 키 누락 검사

**목표**: 핵심 서비스 80%+ 커버리지

### 2-2. 위젯 테스트 추가

- `MissionCard` - 다양한 미션 데이터로 렌더링 검증
- `MainScreen` - 탭 전환 동작 검증
- `SettingsScreen` - 설정 변경 시 콜백 호출 검증

### 2-3. 통합 테스트

- 앱 시작 → 스플래시 → 메인 화면 흐름 검증
- 오프라인 모드 동작 검증

---

## Phase 3: 아키텍처 개선

### 3-1. 서비스 레이어 리팩토링

**현재 문제**: `MissionService`가 데이터 로딩, 파싱, 캐싱, 필터링을 모두 담당

**개선 방향**:
- `MissionRepository` - 데이터 소스 추상화 (네트워크/로컬 캐시)
- `MissionService` - 비즈니스 로직만 담당 (필터링, 정렬)
- `DeepDiveRepository` - 딥다이브 데이터 분리 (현재 탭 안에 직접 구현)

### 3-2. 화면 코드 분리

**현재 문제**: `live_missions_tab.dart`, `highlights_tab.dart`에 UI + 비즈니스 로직 혼재

**개선 방향**:
- 각 탭의 데이터 로딩/필터링 로직을 Provider(또는 ViewModel)로 분리
- 화면 파일은 순수 UI 렌더링만 담당

### 3-3. 다국어(i18n) 시스템 개선

**현재 문제**: `strings.dart`에 모든 번역이 Map으로 하드코딩

**개선 방향**:
- Flutter의 `intl` 패키지 또는 `easy_localization` 도입
- ARB 파일 기반 번역 관리
- 새 언어 추가 시 코드 수정 없이 파일만 추가

---

## Phase 4: CI/CD 강화

### 4-1. 빌드 및 테스트 파이프라인

```yaml
# 추가할 워크플로우
on: [push, pull_request]
jobs:
  analyze:    # dart analyze (린트)
  test:       # flutter test (단위/위젯 테스트)
  build-apk:  # flutter build apk (Android 빌드 검증)
  build-ios:  # flutter build ios --no-codesign (iOS 빌드 검증)
```

### 4-2. 자동 배포 (선택사항)

- GitHub Releases로 APK 자동 업로드
- Fastlane 연동으로 스토어 배포 자동화

---

## Phase 5: 사용자 경험 개선

### 5-1. 푸시 알림

- Double XP 미션 알림 (사용자가 원하는 미션 타입 설정)
- 딥다이브 갱신 알림 (매주 목요일)

### 5-2. 오프라인 지원 강화

- 마지막으로 성공한 데이터를 로컬에 영구 캐싱
- 오프라인에서도 캐시된 데이터로 전체 기능 사용 가능

### 5-3. 검색 및 필터 기능

- 특정 바이옴, 미션 타입, 목표 등으로 필터링
- 즐겨찾기 미션 타입 설정

### 5-4. 위젯 지원

- Android/iOS 홈 화면 위젯
- 현재 미션 또는 다음 Double XP 시간 표시

---

## Phase 6: 코드 정리

### 6-1. 불필요한 코드 제거
- `lib/utils/mock_data.dart` - 주석 처리된 목 데이터 삭제
- `print()` 문 → 프로덕션에서는 로깅 라이브러리(`logger` 패키지) 사용
- 디버그 기능(`debugSetStatus`, `_cycleDebugStatus`) → 디버그 빌드에서만 활성화

### 6-2. 코드 문서화
- 공개 API에 dartdoc 주석 추가
- 주요 비즈니스 로직에 영문 주석 (국제 기여자 고려)

---

## 실행 우선순위

| 순서 | 항목 | 영향도 | 난이도 | 예상 파일 변경 |
|------|------|--------|--------|---------------|
| 1 | 매직 스트링 상수화 + 테마 분리 | 중 | 낮음 | 5-8개 |
| 2 | 에러 처리 강화 | 높음 | 낮음 | 3-4개 |
| 3 | 불필요한 코드 정리 | 낮음 | 낮음 | 3-4개 |
| 4 | 단위 테스트 추가 | 높음 | 중간 | 5-8개 (신규) |
| 5 | Riverpod 상태 관리 도입 | 높음 | 높음 | 10-15개 |
| 6 | 서비스 레이어 리팩토링 | 중 | 중간 | 5-8개 |
| 7 | CI/CD 파이프라인 | 중 | 중간 | 1-2개 (신규) |
| 8 | i18n 시스템 개선 | 중 | 중간 | 5-10개 |
| 9 | 사용자 경험 개선 (알림, 위젯 등) | 높음 | 높음 | 다수 |

---

## 참고: 현재 유지해야 할 강점

- 깔끔한 UI/UX 디자인 (다크 테마, 애니메이션)
- 효율적인 데이터 파이프라인 (GitHub Actions + Python 스크래퍼)
- 멀티 플랫폼 지원
- 3개 언어 지원
- 오프라인 감지 및 사용자 알림
