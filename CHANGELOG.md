# Changelog

## 1.6.0 — 2026-03-10

### PWA Pivot & Web Notifications

- **PWA 전환** — Android/iOS 앱 스토어 배포를 철회하고, 모든 플랫폼에서 PWA로 설치 가능하도록 전환
- **웹 알림 지원** — PC 브라우저에서 Web Notification API를 통한 Double XP 미션 알림 (Service Worker 기반)
- **도움말 버튼** — AppBar에 도움말 버튼 추가, 플랫폼별(Android/iOS/PC) PWA 설치 가이드 다이얼로그
- **알림 안내 개선** — 플랫폼별 알림 지원 현황 명확히 안내 (PC=지원, Android/iOS PWA=미지원, APK=지원)
- **APK 다운로드 안내** — GitHub Releases 링크를 통한 APK 다운로드 안내 (풀 알림 기능 지원)
- **README 개선** — Discord 연락처 카드, Ko-fi 후원 섹션, Twitter/Reddit 링크 추가
- **Service Worker** — 알림 전용 커스텀 `sw.js` (캐싱 없이 installability + notification만 처리)
- **코드 리팩토링** — `notification_shared.dart` 분리로 웹 빌드 시 `dart:io` 의존성 제거

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
