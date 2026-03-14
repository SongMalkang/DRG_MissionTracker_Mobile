# Changelog

## 1.6.2 — 2026-03-14

### Deep Dive 상세 모달 & UI 개선

- **스테이지 상세 모달** — Deep Dive 스테이지 행 탭 시 상세 다이얼로그 표시 (바이옴 배경 이미지, 미션 아이콘, 보조 목표, 길이/복잡도, 경고 목록)
- **"모레 일정" 구분선** — 하이라이트 탭에서 모레(Day After Tomorrow) 시간대를 별도 구분선으로 표시
- **알림 문구 명확화** — "PC에서만 알림 가능" → "웹 알림은 PC, 모바일은 Android APK" 로 오해 소지 제거
- **신규 Deep Dive 목표 번역** — `Mine Morkite`(모르카이트 채굴), `Get Alien Eggs`(외계 알 수집) 3개 언어 추가
- **JetBoots 조작성 개선** — 중력(3.24→2.916) 및 상승력(0.96→0.864) 10% 완화로 부드러운 조작감

### 코드 변경

- **`deep_dives_tab.dart`** — `_StageRow`에 biome 전달, `_showStageDetailModal()` 및 `_StageDetailDialog` 위젯 신규 추가
- **`highlights_tab.dart`** — `isDayAfterTomorrow` 플래그 추가, `_TomorrowDivider`에 모레 라벨 분기
- **`strings.dart`** — `day_after_tomorrow`, `Mine Morkite`, `Get Alien Eggs` 키 추가 (KR/EN/CN), `notif_web_note` 문구 수정
- **`pwa_install_guide.dart`** — Android/iOS PWA 알림 안내 및 footer 문구에 APK 대안 명시
- **`jet_boots_game.dart`** — 중력 상수 3.24→2.916, 점프 속도 -0.96→-0.864

---

## 1.6.1 — 2026-03-13

### Deep Dive 데이터 갱신 안정성 개선

- **데이터 출처 기록** — Deep Dive JSON에 `thursday` 필드 추가, 데이터가 어느 주의 것인지 자체 증명 (cache poisoning 근본 해결)
- **주간 리셋 감지 수정** — 메모리/로컬 캐시가 주(week) 변경을 정확히 감지하도록 수정 (기존: 구 데이터를 이번 주 것으로 오인)
- **갱신 배너 정확도 향상** — `isDataStale` 판정을 데이터 내용 기반으로 변경, 조기 게시된 미래 데이터는 stale 미표시
- **수집 타이밍 최적화** — 목요일 cron 11:00→11:01 UTC (doublexp.net 게시 시점 11:00:30 대응)
- **중복 감지 호환** — 기존 파일에 `thursday` 필드 없을 시 1회 재저장으로 자동 마이그레이션

### 코드 변경

- **`fetch_daily_missions.py`** — `data["thursday"]` 필드 추가, `existing_has_thursday` 마이그레이션 로직
- **`deep_dive_service.dart`** — `_cachedThursdayKey` → `_dataThursdayKey` (데이터 기반), `_extractThursdayKey()` 추가, `_loadFromCache` → `_loadCacheBody` (raw body 반환), `_saveToCache`에서 `thu` 파라미터 제거, 비교 연산자 `!=` → `<` (사전순 날짜 비교)
- **`deep_dives_tab.dart`** — 불필요한 자동 갱신 루프 제거
- **`update_data.yml`** — 첫 번째 목요일 cron `11:00` → `11:01` UTC

---

## 1.6.0 — 2026-03-10

### PWA Pivot & Web Notifications

- **PWA 전면 전환** — Android/iOS 앱 스토어 배포를 철회하고, 모든 플랫폼(Android/iOS/PC)에서 PWA로 설치 가능하도록 전환
- **웹 알림 지원** — PC 브라우저에서 Web Notification API를 통한 Double XP 미션 알림 (Service Worker 기반)
- **커스텀 Service Worker** — 알림 전용 `sw.js` 신규 작성 (push, notificationclick, postMessage 핸들링)
- **도움말 버튼** — AppBar에 (?) 도움말 버튼 추가, 플랫폼별(Android/iOS/PC) PWA 설치 가이드 다이얼로그 제공
- **APK 다운로드 안내** — 도움말 내 GitHub Releases 링크를 통한 APK 다운로드 카드 추가 (풀 알림 + 위젯 기능)
- **알림 안내 개선** — 플랫폼별 알림 지원 현황을 명확히 구분 (Android APK=백그라운드 푸시, PC=브라우저 알림, 모바일 PWA=미지원)
- **알림 설정 UI 변경** — 웹에서도 알림 설정 섹션 접근 가능하도록 변경 (기존: 웹 비활성화 → 현재: 플랫폼 안내 배너로 교체)

### README 대규모 개편

- **PWA 링크 추가** — 상단에 브라우저에서 바로 사용 가능한 링크 배치
- **플랫폼 지원 테이블 개편** — 4열 구조(플랫폼/지원/알림/비고)로 확장, 알림 지원 여부 명확히 표기
- **알림 섹션 개편** — 플랫폼별 동작 방식 테이블 추가 (AlarmManager / Web Notification API / 미지원)
- **Discord 연락처 카드** — 프로필 사진 + DM 버튼이 포함된 별도 섹션
- **Ko-fi 후원 섹션** — 독립 섹션으로 분리 (뱃지만 제공, 모순되는 문구 제거)
- **개발자 카드 SNS 추가** — Steam · Twitter · Reddit 링크
- **면책 조항 수정** — 비상업성 문구와 후원 섹션 간 모순 해소
- **3개 언어 동시 반영** — README.md / README.ko.md / README.zh.md 동일 구조 유지

### 코드 변경

- **`web_notification_service.dart`** (신규) — Web Notification API 서비스, 30분 주기 폴링, Service Worker postMessage 연동
- **`notification_shared.dart`** (신규) — 알림 공통 코드 분리 (boscoMessages, toSlot, formatTimeKey), 웹 빌드 시 `dart:io` 의존성 제거
- **`pwa_install_guide.dart`** (신규) — PWA 설치 가이드 다이얼로그 위젯 (플랫폼별 아코디언 카드, 알림 지원 배너, APK 다운로드 카드)
- **`sw.js`** (신규) — 커스텀 Service Worker (스마트 캐싱 + 알림 + installability). CanvasKit/에셋은 cache-first, 앱 코드는 network-first, API는 network-only. 배포 시 CI가 버전을 자동 주입하여 캐시 갱신
- **`notification_service.dart`** — 공통 코드를 `notification_shared.dart`로 분리
- **`notification_settings_section.dart`** — 웹 플랫폼 비활성화 제거, 안내 배너로 교체
- **`platform_init_stub.dart` / `notification_helpers_stub.dart`** — no-op에서 WebNotificationService 연동으로 변경
- **`main_screen.dart`** — 도움말 버튼 추가
- **`strings.dart`** — `notif_web_note`, `pwa_guide_*`, `watchlist_android_only` 등 신규 문자열 추가
- **`constants.dart`** — `githubReleasesUrl` 추가
- **`web/index.html`** — Service Worker 등록 스크립트 교체 (업데이트 감지 포함)
- **`web/manifest.json`** — Play Store `related_applications` 제거
- **`deploy_web.yml` / `ci.yml`** — PWA 전환 관련 주석 업데이트
- **`pubspec.yaml`** — 버전 `1.5.0+5` → `1.6.0+6`
- **`version.json`** — 최신 버전 + changelog 업데이트, `store_url` → GitHub Releases

---

## 1.5.0

- 미니게임 3종 개선 (보스 특수능력, Nitra/수류탄, Hazard Level, Pit Jaw, 무기 해금)
- 위젯 정상화 (테스트중)
- 미션 워치리스트 추가
- Deep Dive 버그 수정

---

## 1.4.0

- Deep Dive & Elite Deep Dive 정보 추가
- Trivia 시스템
- 오프라인 캐시

---

## 1.3.0

- BOSCO 푸시 알림 (Android)
- 알림 커스터마이징 (요일, 시간, 미션 타입)

---

## 1.2.0

- 3개 언어 지원 (한국어, English, 中文)
- UI/UX 개선

---

## 1.1.0

- 실시간 미션 트래커
- Double XP / Gold Rush 하이라이트

---

## 1.0.0

- 초기 릴리스
