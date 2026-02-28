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
- **데이터 정책**: 원본 서버 부하(Leeching) 방지를 위해, 앱은 매일 00:05 UTC에 단 한 번 데이터를 갱신하여 본 저장소에 캐싱합니다. 앱은 doublexp.net에 직접 접근하지 않습니다.
- 복잡한 게임 내 데이터를 스크래핑하여 커뮤니티와 공유해주신 `rolfosian` 님께 깊은 감사를 표합니다. **Rock and Stone!** ⛏️

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
      <a href="https://steamcommunity.com/id/VonVon93/">🎮 Steam 프로필</a><br/>
      <sub>버그 제보 및 피드백은 Steam으로 부탁드립니다.</sub>
    </td>
  </tr>
</table>

---

## ⚖️ 면책 조항

1. **Non-Commercial**: 본 프로젝트는 수익을 목적으로 하지 않는 비상업적 팬 프로젝트입니다.
2. **Intellectual Property**: *Deep Rock Galactic*의 모든 자산, 이미지, 캐릭터 및 관련 데이터의 저작권은 **Ghost Ship Games** 및 **Coffee Stain Publishing**에 있습니다.
3. **No Affiliation**: 본 앱은 Ghost Ship Games와 공식적으로 연관되어 있지 않으며, 공식 서비스의 보조 도구로만 작동합니다.

---

## 📄 라이선스

이 프로젝트는 [MIT 라이선스](LICENSE) 하에 배포됩니다.
