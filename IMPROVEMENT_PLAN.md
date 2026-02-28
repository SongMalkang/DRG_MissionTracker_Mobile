# Bosco Terminal - 개선 계획 (v3)

> 아직 개발 단계. 과도한 설계/추상화 배제, 실용적 개선에 집중.

## 실행 전략

```
Phase 1~4 (안전 구간) → ✅ 테스트 통과 → Phase 5~6 (구조 변경)
```

---

## Phase 1: 매직 스트링 상수화

- `lib/utils/constants.dart` 생성 → API URL, 타이밍, UI 수치 등 한곳에 모으기
- 각 파일에서 하드코딩된 값을 상수 참조로 교체

## Phase 2: 에러 처리 강화

- `mission_service.dart`: 네트워크 타임아웃 증가 + 재시도 로직 (지수 백오프)
- `deep_dives_tab.dart`: 파싱 try-catch 보강 (크래시 방지)

## Phase 3: 코드 정리

- `mock_data.dart` 삭제 (전체 주석 상태)
- `print()` → `debugPrint()` 교체
- 디버그 기능 `kDebugMode` 체크로 격리

## Phase 4: 단위 테스트 + CI

테스트:
- `Mission` 모델 (fromJson, null 처리, Double XP 판별)
- `MissionService` (JSON 파싱, 시즌 필터링, 시간 슬롯)
- `AssetHelper` (경로 생성)
- `Strings` (언어별 키 누락 검사)

CI (`ci.yml` 신규):
- `dart analyze` → `flutter test` → `flutter build apk/web` (검증만, 릴리즈 없음)
- `data/**`, `**.md` 변경 시 스킵
- 기존 `update_data.yml` (일일 JSON 수집)은 그대로 유지

---

## ✅ 체크포인트: 테스트 전체 통과 확인 후 진행

---

## Phase 5: Riverpod 상태 관리 도입

- prop drilling 제거, 전역 상태로 전환
- 모든 화면 ConsumerWidget 전환

## Phase 6: UX 개선

- 오프라인 영구 캐싱
- 검색/필터 기능
