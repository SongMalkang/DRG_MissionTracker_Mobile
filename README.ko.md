# ⛏️ Bosco Terminal (Unofficial DRG Mission Tracker)

[ [English](./README.md) | **한국어** | [中文](./README.zh.md) ]

**Bosco Terminal**은 *Deep Rock Galactic(DRG)* 플레이어들을 위한 비공식 미션 추적 앱입니다. 30분마다 갱신되는 실시간 미션 정보, Double XP 하이라이트, 그리고 주간 딥 다이브 정보를 한눈에 확인할 수 있도록 설계되었습니다.

## 🙏 Special Thanks: The Heart of Data

이 프로젝트는 DRG 커뮤니티의 헌신적인 개발자 **[rolfosian](https://www.google.com/search?q=https://github.com/rolfosian)**님 덕분에 존재할 수 있었습니다.

* 본 앱에서 사용하는 모든 실시간 미션 데이터는 **[doublexp.net](https://doublexp.net)** 및 **[rolfosian/drgmissions](https://github.com/rolfosian/drgmissions)** 저장소에서 제공됩니다.
* 복잡한 게임 내 데이터를 스크래핑하여 모든 드워프 형제들을 위해 공유해주신 `rolfosian`님께 깊은 존경과 감사를 표합니다. **Rock and Stone!** ⛏️

---

## ✨ Key Features (Currently Developed)

* **Live Mission Tracker**: 실시간 미션 로테이션 및 다음 갱신까지의 카운트다운 표시.
* **Double XP Highlights**: 보너스 경험치 미션을 상단에 고정하고 황금색 테두리로 강조.
* **Deep Dive Timeline**: 일반 및 엘리트 딥 다이브의 3단계 미션 정보 제공.
* **Multilingual Support**: 한국어(KR), 영어(EN), 중국어(CN) 완벽 지원.
* **Interactive UI**: 터치 시 반응하는 애니메이션 보스코(Bosco) 아이콘 및 바이옴별 상세 정보 팝업.
* **Responsive Design**: 갤럭시 폴드, 플립 및 태블릿 환경을 고려한 가변 레이아웃 적용.

## ⚖️ Disclaimer (면책 조항)

1. **Non-Commercial Fan Project**: 본 프로젝트는 수익을 목적으로 하지 않는 비상업적 팬 프로젝트입니다.
2. **Intellectual Property**: *Deep Rock Galactic*의 모든 자산, 이미지, 캐릭터 및 관련 데이터의 저작권은 **Ghost Ship Games** 및 **Coffee Stain Publishing**에 있습니다.
3. **No Affiliation**: 본 앱은 Ghost Ship Games와 공식적으로 연관되어 있지 않으며, 공식 서비스의 보조 도구로만 작동합니다.
4. **Donation Usage**: 제공되는 후원 링크는 오직 Apple App Store 등록비($99/year) 및 서버/데이터 유지보수 비용을 충당하기 위해서만 사용됩니다.

## 🛠️ Tech Stack

* **Frontend**: Flutter (Dart)
* **Data Pipeline**: Python (Data Scraping) + GitHub Actions (Automation)
* **Storage**: Shared Preferences (Local Settings)
* **Architecture**: Modular UI Components
