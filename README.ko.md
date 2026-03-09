# ⛏️ Bosco Terminal

[ [English](./README.md) | **한국어** | [中文](./README.zh.md) ]

[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![CI](https://github.com/SongMalkang/DRG_MissionTracker_Mobile/actions/workflows/ci.yml/badge.svg)](https://github.com/SongMalkang/DRG_MissionTracker_Mobile/actions/workflows/ci.yml)

**Bosco Terminal**은 *Deep Rock Galactic(DRG)* 플레이어를 위한 비공식 미션 추적 앱입니다. Double XP 미션을 놓치지 마세요 — 실시간 미션 트래킹, 딥 다이브 정보, BOSCO 테마 알림을 한곳에서 확인하세요.

---

## ✨ 주요 기능

- **실시간 미션 트래커** — 30분마다 갱신되는 미션 로테이션. Double XP 및 Gold Rush 미션은 황금색 테두리로 강조되어 상단에 고정됩니다.
- **딥 다이브 & 엘리트 딥 다이브** — 단계별 주 목표, 보조 목표, 바이옴, 이상 현상 정보를 모두 제공합니다.
- **Trivia 시스템** — 바이옴, 미션 타입, 버프, 경고 뱃지를 탭하면 해당 항목의 상세 정보와 공략 팁을 확인할 수 있습니다.
- **BOSCO 푸시 알림** — Double XP 미션이 등장하면 알림을 받으세요. 알림받을 요일, 시간, 미션 타입을 직접 설정할 수 있습니다. *(Android 전용)*
- **오프라인 캐시** — 네트워크 연결 없이도 마지막으로 가져온 데이터를 표시합니다.
- **3개 언어 지원** — 한국어 · English · 中文

---

## 📱 플랫폼 지원

| 플랫폼 | 지원 | 비고 |
|---|---|---|
| Android | ✅ | Push 알림 포함 전체 기능 지원 |
| Web PWA | ✅ | Push 알림 불가 (브라우저 한계) |
| iOS | ❌ | App Store 등록비($99/년) 문제로 미지원 |

---

## 🔔 푸시 알림 *(Android 전용)*

BOSCO가 Double XP 미션이 등장하면 직접 알려줍니다.

- 알림받을 **요일**과 **시간**을 자유롭게 설정
- 원하지 않는 미션 타입은 알림에서 제외 (예: Escort Duty)
- 앱이 꺼진 상태에서도 동작
- 설정한 언어로 BOSCO 스타일의 위트있는 문구로 전달

*Web PWA 버전은 브라우저 한계로 인해 Push 알림이 지원되지 않습니다.*

---

## 🙏 Special Thanks

이 프로젝트는 **[rolfosian](https://github.com/rolfosian)** 님 덕분에 존재할 수 있었습니다.

- 본 앱의 모든 실시간 미션 데이터는 **[doublexp.net](https://doublexp.net)** 에서 제공됩니다.
- **데이터 정책**: 원본 서버 부하(Leeching) 방지를 위해, GitHub Actions 워크플로우가 매일 00:05 UTC에 단 한 번 데이터를 가져와 본 저장소에 JSON으로 캐싱합니다. 앱은 캐싱된 JSON만 읽으며, doublexp.net에 직접 접근하지 않습니다.
- 복잡한 게임 내 데이터를 스크래핑하여 커뮤니티와 공유해주신 `rolfosian` 님과 고품질 게임 에셋을 제공하는 **[Deep Rock Galactic Wiki](https://deeprockgalactic.wiki.gg/)** 커뮤니티에 깊은 감사를 표합니다. **Rock and Stone!** ⛏️

---

## 👨‍💻 개발자

<table>
  <tr>
    <td align="center" width="100">
      <a href="https://steamcommunity.com/id/VonVon93/">
        <img src="https://shared.fastly.steamstatic.com/community_assets/images/items/3331000/4ef70f99c425ae03163495f923c5d452f83ba978.gif"
             width="80" alt="Pinyo Steam Profile"/>
      </a>
    </td>
    <td valign="middle">
      <b>Pinyo</b><br/>
      <a href="https://steamcommunity.com/id/VonVon93/">🎮 Steam</a> · <a href="https://x.com/SongMalkang">𝕏 Twitter</a> · <a href="https://www.reddit.com/user/SongSongYi/">📮 Reddit</a><br/>
      <sub>버그 제보 및 피드백은 GitHub Issues로 부탁드립니다.</sub>
    </td>
  </tr>
</table>

---

## 💬 연락처

> **가장 빠른 연락 방법은 Discord DM입니다.**

<table>
  <tr>
    <td align="center" width="100">
      <a href="https://discord.com/users/286124554915676161">
        <img src="https://avatars.githubusercontent.com/u/108260540?v=4"
             width="80" style="border-radius:50%" alt="vonvon93"/>
      </a>
    </td>
    <td valign="middle">
      <b>vonvon93</b><br/>
      <sub>버그 제보, 피드백, 기능 요청 등 무엇이든 편하게 보내주세요.</sub><br/><br/>
      <a href="https://discord.com/users/286124554915676161">
        <img src="https://img.shields.io/badge/Discord_DM_보내기-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Send DM"/>
      </a>
    </td>
  </tr>
</table>

---

## ☕ 후원

<a href="https://ko-fi.com/songmalkang">
  <img src="https://storage.ko-fi.com/cdn/kofi2.png?v=6" alt="Ko-fi에서 후원하기" height="36"/>
</a>

---

## 🔨 직접 빌드하기

APK를 직접 빌드하여 설치하고 싶다면 아래 절차를 따라주세요.

### 사전 요구사항

| 도구 | 필요 버전 | 설치 가이드 |
|------|---------|-----------|
| Flutter SDK | **3.41.x** (Dart ≥ 3.11.0) | [flutter.dev/get-started](https://docs.flutter.dev/get-started/install) |
| Android Studio | 최신 안정 버전 | [developer.android.com](https://developer.android.com/studio) |
| Android SDK | API 36 (SDK Manager에서 설치) | Android Studio에 포함 |
| Java (JDK) | **17** | Android Studio에 번들 포함 |
| Git | 최신 버전 | [git-scm.com](https://git-scm.com/) |

> **참고**: Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20은 프로젝트에 설정되어 있으며, 첫 빌드 시 자동으로 다운로드됩니다.

### 1. 환경 확인

```bash
flutter doctor
```

아래 항목에 **❌ 에러가 없는지** 확인하세요:
- `Flutter` — stable 채널, 3.41.x
- `Android toolchain` — Android SDK API 36
- `Android Studio` — Dart, Flutter 플러그인 설치됨

### 2. 클론 및 의존성 설치

```bash
git clone https://github.com/SongMalkang/DRG_MissionTracker_Mobile.git
cd DRG_MissionTracker_Mobile
flutter pub get
```

### 3. APK 빌드

**디버그 빌드** (테스트용):
```bash
flutter build apk --debug
```

**릴리스 빌드** (최적화, 용량 축소):
```bash
flutter build apk --release
```

> ⚠️ 릴리스 빌드는 `minifyEnabled`와 `shrinkResources`가 활성화되어 있습니다. 리소스 누락 에러 발생 시 `android/app/proguard-rules.pro`를 확인하세요.

### 4. APK 산출물 위치

| 빌드 타입 | 출력 경로 |
|----------|---------|
| Debug | `build/app/outputs/flutter-apk/app-debug.apk` |
| Release | `build/app/outputs/flutter-apk/app-release.apk` |

### 5. 디바이스에 설치

```bash
# ADB를 통한 설치 (USB 디버깅 활성화 필요)
flutter install

# 또는 APK 파일을 디바이스에 직접 전송하여 설치
```

### Web (PWA) 빌드

```bash
flutter build web
# 산출물: build/web/
```

### 문제 해결

| 문제 | 해결 방법 |
|-----|---------|
| `Gradle build failed` | `cd android && ./gradlew clean` 실행 후 재시도 |
| `SDK version mismatch` | Android Studio → SDK Manager → API 36 설치 |
| `flutter doctor`에서 Java 에러 | `JAVA_HOME`이 JDK 17을 가리키는지 확인 |
| `Kotlin version conflict` | `.gradle` 캐시 삭제: `rm -rf ~/.gradle/caches` |

---

## ⚖️ 면책 조항

1. **Non-Commercial**: 본 프로젝트는 **순수 비영리 팬 프로젝트**입니다. 앱 내에 광고, 인앱 결제, 유료 콘텐츠가 일절 포함되어 있지 않습니다.
2. **Intellectual Property**: *Deep Rock Galactic*의 모든 게임 에셋(이미지, 아이콘, 사운드 등)의 저작권은 **Ghost Ship Games ApS** 및 **Coffee Stain Publishing**에 있습니다. 해당 에셋은 권리자의 별도 허가 하에 사용되며, MIT 라이선스에 **포함되지 않습니다**. Ghost Ship Games의 명시적 허가 없이 에셋을 재배포하는 것은 금지됩니다.
3. **No Affiliation**: 본 앱은 Ghost Ship Games와 공식적으로 연관되어 있지 않으며, 커뮤니티를 위한 보조 도구로만 작동합니다.

---

## 📄 라이선스

본 프로젝트의 **소스 코드**는 [MIT 라이선스](LICENSE) 하에 배포됩니다.

게임 에셋(이미지, 아이콘, 사운드 등)은 MIT 라이선스에서 **제외**되며, Ghost Ship Games ApS / Coffee Stain Publishing의 소유입니다. 자세한 내용은 [LICENSE](LICENSE) 파일과 [ASSETS.md](ASSETS.md) 에셋 목록을 참조하세요.
