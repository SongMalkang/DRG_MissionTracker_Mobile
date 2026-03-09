# Hoxxes Survival 미니게임 기획서

> DRG Mission Tracker 앱의 미니게임 탭에 추가할 뱀파이어 서바이버 스타일 게임 기획.

### 개발 진행 상태
| Phase | 상태 | 내용 |
|-------|------|------|
| **Phase 1: Core Engine (MVP)** | **완료** | 게임 루프, 조이스틱, 적 스폰/AI, 자동공격, 충돌, HP, 레벨업, HUD, 리더보드 |
| Phase 2: DRG 시스템 | 미착수 | 인트로, 장비 커스텀, Nitra 채굴, 필살기, 해금 |
| Phase 3: 위험 & 보스 | 미착수 | Pit Jaw, 보스 컷씬, Bulk Detonator, Hazard Level |
| Phase 4: Polish | 미착수 | SFX, 밸런스, 최적화, i18n, 조명탄 |

---

## 1. 저작권 분석

### 결론: **저작권 위배 아님** (조건부)

### 상세 분석

**게임 메카닉은 저작권 보호 대상이 아니다**
- 미국/한국 저작권법상 **게임 규칙, 메카닉, 시스템**은 "아이디어"에 해당하며 저작권 보호 대상이 아님
- 보호되는 것: 구체적인 **표현** (아트, 음악, 캐릭터 이름, 스토리, 특정 UI 디자인)
- 판례: Tetris vs. Xio Interactive (2012) — 규칙이 아닌 "시각적 표현의 총체"만 보호

**뱀파이어 서바이버 자체가 장르의 시작이 아님**
- Vampire Survivors(2022)는 **Magic Survival**(2021, 한국 모바일 게임)에서 영감을 받음
- 이후 "Bullet Heaven" 장르로 정착: Brotato, Halls of Torment, Soulstone Survivors, HoloCure, 20 Minutes Till Dawn 등 수십 개의 게임이 같은 장르로 출시됨
- 장르 자체가 이미 완전히 일반화됨

**위반이 되는 경우 (피해야 할 것)**
| 항목 | 위반 여부 | 설명 |
|------|-----------|------|
| 동일한 게임 메카닉 (자동 공격, 레벨업, 무기 선택) | ❌ 위반 아님 | 게임 규칙은 저작권 비보호 |
| "Vampire Survivors" 이름 사용 | ⚠️ 상표권 위반 | 이름, 로고 사용 금지 |
| VS의 캐릭터/무기 이름 그대로 사용 | ⚠️ 위반 가능 | Antonio, Whip, King Bible 등 고유 명칭 |
| VS의 아트 스타일 모방 | ⚠️ 위반 가능 | 픽셀아트 자체는 OK, 동일한 스프라이트 디자인은 NG |
| DRG 세계관 + 독자적 시스템 | ✅ 완전 안전 | 고유 IP + 독창적 요소 |

**안전하게 만드는 방법**
1. DRG 세계관과 캐릭터를 사용 (Driller, Scout, Gunner, Engineer)
2. DRG 고유의 적 (Glyphid, Praetorian, Dreadnought 등)
3. DRG 무기 체계 기반 (Flamethrower, Breach Cutter, Cryo Cannon 등)
4. 독자적 시스템 추가 (아래 섹션 참조)
5. "서바이버" "뱀파이어" 등의 이름 사용하지 않음

> **참고**: DRG IP 사용에 대해서는 Ghost Ship Games(DRG 개발사)의 팬 콘텐츠 정책을 확인할 것.
> DRG 커뮤니티는 팬 프로젝트에 대해 매우 우호적이며, 비영리/팬 앱에 대한 제재 사례 없음.
> 단, 상업적 이익을 목적으로 하지 않는 것이 안전.

---

## 2. 게임 컨셉

### 제목안
- ~~"Swarm Survival"~~ → **"Hoxxes Survival"** (확정) — DRG의 행성 Hoxxes에서 착안
- ~~"Hold the Line"~~
- ~~"Bug Hunt"~~

### 주인공: Scout (스카웃)
- **Scout 단일 주인공** — 4클래스 선택 방식이 아님
- DRG에서 가장 기동력이 높은 클래스로, 서바이버류의 회피 플레이와 잘 맞음
- 그래플링 훅, 조명탄 등 Scout 고유 장비 활용
- **인게임 디자인**: Pit Jaw Rescue 인트로의 `ScoutPainter` 디자인을 그대로 계승
  - 반원 헬멧 + 상단 헤드램프(발광 원) + 네모 몸통(`drawRect`) + 짧은 팔/다리 라인
  - 터미널 스타일 와이어프레임 유지, 피격 시 빨간색 전환 (`surprised` 상태와 동일)
  - 참고: `lib/widgets/whack_a_mole/painters/intro_painters.dart` — `ScoutPainter`

### 핵심 루프
```
[인트로 씬] → [장비 커스텀] → [출격]
                                 ↓
[웨이브 시작] → [자동 공격으로 Glyphid 처치] → [재화 획득]
     ↑              ↓
[새 웨이브]    [레벨업 → 무기/능력 선택]
     ↑              ↓
[난이도 상승]  [중간보스 등장 (이미지 컷씬)]
     ↑              ↓
[반복]        [처치 → 미네랄 드롭 → 강화]
                     ↓
              [Nitra 채굴 → 필살기 충전]
```

### 게임 흐름
```
1. 인트로 (이미지 에셋 기반 컷씬)
        ↓
2. 장비 커스텀 (무기 선택, 해금 상태에 따라 개방)
        ↓
3. 게임 플레이 (터미널 스타일 + 부분 이미지 에셋)
        ↓
4. 게임 오버 / 결과 화면
```

### DRG 테마 적용
| 뱀서류 일반 | DRG 버전 |
|-------------|----------|
| 캐릭터 | **Scout** (단일 주인공) |
| 적 몬스터 | Glyphid Grunt, Praetorian, Oppressor |
| 중간보스 | Dreadnought, Hiveguard, Twins, Bulk Detonator (이미지 컷씬 등장) |
| 무기 | Scout의 Primary 무기 (해금제) + Secondary 무기 (인게임 랜덤 획득) |
| 재화 | 적 처치 시 드롭되는 Gold, XP |
| 전략 자원 | Nitra (채굴 포인트에서 수집 → 필살기) |
| 환경 위험 | Pit Jaw (숨어있다 체력 감소) |
| 맵 배경 | DRG 바이옴 (Salt Pits, Magma Core, Crystalline Caverns) |
| 레벨업 선택지 | Overclock 선택 + Secondary 무기 랜덤 획득 |

---

## 3. 비주얼 디자인 방향

### 하이브리드 스타일: 터미널 + 이미지 에셋
기존 미니게임의 터미널 디자인을 기본 골격으로 유지하되, **볼륨이 큰 이벤트에는 이미지 에셋을 활용**하여 몰입감 강화.

| 요소 | 렌더링 방식 | 설명 |
|------|-------------|------|
| **게임 플레이 전반** | 터미널 스타일 (CustomPainter) | 기하학적 도형, CRT 톤, 기존 미니게임과 통일감 |
| **인트로 씬** | 이미지 에셋 | DRG 세계관 소개, 미션 브리핑 느낌 |
| **보스 등장 씬** | 레이어 적용(강조띠 내부) + 이미지 컷인(단일이미지 이동 + 추가이미지) | 중간보스 등장 시 짧은 경고 연출 & 소리 재생 |
| **적 처치 재화 드롭** | 이미지 에셋 (작은 아이콘) | Gold, XP 등 시각적 구분을 위한 소형 스프라이트 |
| **장비 커스텀 화면** | 이미지 에셋 + UI | 무기 일러스트, 장비 선택 인터페이스 |
| **HUD / 일반 적** | 터미널 스타일 | 게이지바, 텍스트, 기하학적 도형 |

```
시각적 흐름:

[인트로 - 이미지 에셋]
  "Mission Control: Scout, 긴급 상황이다..."
  ┌───────────────────────────┐
  │   ╔══════════════════╗    │
  │   ║  (Scout 이미지)  ║    │
  │   ║   미션 브리핑    ║    │
  │   ╚══════════════════╝    │
  │      [ TAP TO START ]     │
  └───────────────────────────┘
           ↓
[장비 커스텀 - 이미지 + UI]
  ┌───────────────────────────┐
  │  LOADOUT SELECT           │
  │  ┌─────┐  ┌─────┐        │
  │  │(M1K)│  │(GK2)│ 🔒     │
  │  └─────┘  └─────┘        │
  │  PRIMARY ──────────────   │
  │                           │
  │  SECONDARY: 인게임 랜덤   │
  │                           │
  │      [ DEPLOY ]           │
  └───────────────────────────┘
           ↓
[게임 플레이 - 터미널 스타일 + 부분 이미지]
  ┌──────────────────────────────┐
  │ HP ████████░░  LV.5  02:34  │
  │                              │
  │     ·  ·    ◇ (gold img)    │
  │   · ▲ · ·                   │
  │  · · · · ·    ♦ Nitra       │
  │     ·  ·                    │
  │            ⚠ Pit Jaw        │
  │                              │
  │ Nitra: ██░░░░  [필살기]     │
  └──────────────────────────────┘
           ↓
[보스 등장 - 이미지 컷씬]
  ┌──────────────────────────────┐
  │  !! WARNING !!               │
  │  ┌────────────────────┐     │
  │  │ (Dreadnought 이미지)│     │
  │  │   DREADNOUGHT       │     │
  │  │   DETECTED          │     │
  │  └────────────────────┘     │
  │  [ 2초 후 자동 복귀 ]        │
  └──────────────────────────────┘
```

---

## 4. 독자적 시스템 (차별화 요소)

### 4-1. 장비 커스텀 시스템 (인트로 후, 게임 시작 전)
- DRG의 장비 시스템을 **간략화**하여 적용
- 인트로 씬 이후, 게임 시작 전에 **Primary 무기만** 선택
- **해금 시스템**: 플레이 횟수/성과에 따라 무기가 차차 개방
- **Secondary 무기**: 인게임 레벨업 시 **랜덤 획득** (매 판 다른 빌드 유도)

#### Primary 무기 목록 (장비 커스텀에서 선택, 해금제)
| 순서 | Primary | 해금 조건 |
|------|---------|-----------|
| 기본 | Deepcore GK2 (돌격소총) | 초기 해금 |
| 2차 | M1000 Classic (반자동 저격) | 첫 클리어 or 누적 500킬 |
| 3차 | DRAK-25 Plasma Carbine (플라즈마) | 보스 처치 or 누적 2000킬 |

#### Secondary 무기 목록 (인게임 레벨업 시 랜덤 등장)
| Secondary | 특성 | 스탯 |
|-----------|------|------|
| Jury-Rigged Boomstick (산탄총) | 근거리 광역 산탄, 강력하지만 느림 | DMG 25, FR 0.4, 7발 산탄, spread 0.7 |
| Zhukov NUK17 (듀얼 SMG) | 고속 연사, 낮은 정확도 | DMG 6, FR 8.0, 2발 동시, spread 0.35 |
| Nishanka Boltshark X-80 (석궁) | 관통, 고데미지 단발 | DMG 70, FR 0.8, 관통 |

> Secondary는 레벨업 선택지에서 무작위로 제시됨 (Overclock과 동일 풀).
> Primary 선택 + Secondary 랜덤 조합 = 매 판 다른 빌드 경험.

#### 장비 슬롯 구성
```
┌── Primary Weapon ──── (자동 공격 — 주력 화기, 가장 높은 빈도) [장비 커스텀에서 선택]
├── Secondary Weapon ── (자동 공격 — 쿨다운 기반) [인게임 레벨업 시 랜덤 획득]
├── Traversal Tool ──── 그래플링 훅 (고정, Scout 정체성) — 조이스틱 플릭으로 발동
└── Support Tool ────── 조명탄 (고정) → 자동 발사, 주변 시야 확보 (45초 마다. 발사시 효과음)
```

#### 조작 철학: "이동만 한다"
뱀서류의 핵심은 **조작의 단순함**. 액티브 버튼을 **최대 1개**로 제한한다.
- **Primary + Secondary 무기**: 모두 **완전 자동 공격** (수동 발사 없음)
  - Primary: 가장 가까운 적에게 지속 사격 (높은 빈도)
  - Secondary: 쿨다운 주기마다 자동 발동 (강력하지만 간헐적) — 인게임 획득 전에는 미장착
- **조명탄**: 자동으로 주기적 발사, 주변 일정 범위 시야 확보
- **그래플링 훅 (대시)**: 조이스틱 **플릭**(빠르게 밀어서 놓기)으로 발동 → 이동 방향으로 대시, 별도 버튼 없음
- **수류탄 (필살기)**: **수동 버튼 1개** (Nitra 소모) — 유일한 액티브 버튼

```
최종 조작 구성:

┌─────────────────────────────────┐
│                                 │
│          [게임 화면]             │
│                                 │
│                                 │
│                          💣     │ ← 필살기 버튼 (Nitra 충분 시 활성화, 유일한 버튼)
│   ◎                             │ ← 가상 조이스틱 (이동 + 플릭 = 대시)
│                                 │
└─────────────────────────────────┘
  조작: 조이스틱(이동/대시) + 버튼 1개(필살기) = 끝
  나머지(Primary, Secondary, 조명탄) = 전부 자동
```

### 4-2. Nitra 채굴 & 필살기 시스템
- VS류 게임과의 **핵심 차별점**
- 맵 곳곳에 **Nitra 채굴 포인트** 존재 (고정 위치, 빛나는 표시)
- 채굴 포인트에 접근 → **채굴 범위 내에서** 채굴 진행
  - 채굴 중 **곡괭이 소리 SFX** 재생
  - 진행률 게이지 표시
  - Nitra 자원이 **팝업 애니메이션**과 함께 획득
- 채굴 중에는 **채굴 범위 내 저속 이동** 가능 (완전 정지 아님)
  - 채굴 범위를 벗어나면 진행률 유지, 돌아오면 이어서 채굴
  - 채굴 시작 시 **주변 적 넉백** 효과 발동 (짧은 안전 시간 확보)
- 수집한 Nitra로 **필살기(Ultimate) 발동**

```
Nitra 채굴 시퀀스:

  1. 채굴 포인트 접근
  ┌──────────────────────┐
  │     ♦ (Nitra 광맥)   │
  │     ▲ Scout          │
  │  "채굴 가능"          │
  └──────────────────────┘

  2. 범위 내에서 저속 이동하며 채굴
  ┌──────────────────────┐
  │  ╭ · · · · · ╮       │
  │  · ⛏ (채굴 중) ·     │
  │  ·  ▲ Scout    ·     │  ← 채굴 범위 내 저속 이동 가능
  │  ╰ · · · · · ╯       │
  │  ████████░░░░ 62%    │
  │  ♪ 곡괭이 SFX ♪      │
  └──────────────────────┘

  3. 채굴 완료 → Nitra 팝업
  ┌──────────────────────┐
  │    +15 Nitra!        │
  │     ▲ Scout          │
  │  Nitra: ██████████   │
  │  [필살기 준비 완료!]  │
  └──────────────────────┘
```

#### 필살기: 수류탄 (유일한 수동 조작)
- Nitra를 모아서 발동하는 **유일한 액티브 버튼**
- 화면 오른쪽 하단에 수류탄 버튼 (Nitra 충족 시 활성화)
- 터치하면 Scout 주변 적이 많이 모인곳에 자동 투척(자율판단)
- 필살기 강화 시에도 컷인 발생(드릴러의 C4지원, 엔지니어의 펫보이 지원)

| 단계 | Nitra 비용 | 효과 |
|------|-----------|------|
| **수류탄** | 40 Nitra | 주변 광역 데미지 + 넉백 |
| **클러스터 수류탄** | 80 Nitra | 대형 폭발 + 파편 산개 + 화면 전체 데미지 |

> Nitra 40/80은 DRG 원작의 Supply Pod 호출 비용과 동일한 숫자를 유지.
> "보급"이 아닌 "수류탄" 및 "회복(50HP)"

### 4-3. Pit Jaw 환경 위험 시스템
- DRG의 환경 위험 요소를 게임에 도입
- **Pit Jaw**가 맵 곳곳에 **낮은 확률**로 숨어 있음
- 플레이어가 **가까이 접근하면 공격** → 체력 감소
- Pit Jaw와의 조우는 **순간적** (물려서 HP 감소 후 바로 해제)
- **인게임 디자인**: Pit Jaw Rescue 인트로의 `PitJawPainter` 디자인을 축소 적용
  - 기본 상태(은신): **V자 이빨(윗주둥이)만 지면 위로 노출** — 작은 사이즈로 렌더링
  - 공격 상태: 역삼각형 몸체가 지면 위로 올라오며 물기 연출
  - 참고: `lib/widgets/whack_a_mole/painters/intro_painters.dart` — `PitJawPainter`

#### 가시성: 2단계 시스템 (불쾌하지 않은 설계)
불쾌한 경험(보이지 않는 것에 당하는 느낌)을 방지하기 위해, **조명탄 없이도 어느 정도 관측 가능**.

| 상태 | 가시성 | 설명 |
|------|--------|------|
| **기본 (조명탄 없이)** | 미세한 힌트 | 바닥에 미약한 균열/움직임 표시, 주의 깊게 보면 피할 수 있음 |
| **조명탄 범위 안** | 원형 위험 인디케이터 | 빨간 원형 경고 표시로 위치를 명확히 알려줌 |

```
Pit Jaw 가시성 비교:

  조명탄 없이 (기본 힌트 — 윗주둥이 V자만 미세하게 노출):
  ┌──────────────────────────────┐
  │  · · ·   ▲   · · ·          │
  │     ·  ·   ·  ·             │
  │  · ·    ∧∧∧   · ·           │  ← V자 이빨 힌트 (작게) — 관찰하면 피할 수 있음
  │     · ·    ·  ·             │
  └──────────────────────────────┘

  조명탄 범위 안 (명확한 경고 — V자 + 빨간 인디케이터):
  ┌──────────────────────────────┐
  │  · · ·   ▲   · · ·          │
  │     ·  · ╭─╮ ·  ·           │
  │  · ·    │∧∧│   · ·          │  ← 빨간 원형 인디케이터 + V자 이빨 (명확)
  │     · ·  ╰─╯  ·  ·          │
  └──────────────────────────────┘

  접근 시 (공격 — 역삼각형 몸체 출현):
  ┌──────────────────────────────┐
  │        ▲ Scout               │
  │     ∧∧∧∧∧                   │
  │      ╲   ╱  -25 HP!         │  ← 역삼각형 몸체 돌출 + 데미지
  │       ╲ ╱                    │
  │        V                     │
  └──────────────────────────────┘
```

- **설계 의도**: "몰라서 당하는 것"이 아니라 "알고도 피하지 못한 것"
- 조명탄은 자동 발사이므로, 자연스럽게 시야 안의 Pit Jaw는 경고됨
- 조명탄 범위 밖에서도 힌트가 있으므로 관찰력으로 회피 가능

### 4-4. Hazard Level 시스템
- DRG의 난이도 체계 그대로 활용
- Hazard 1~5 선택 가능
- 높은 Hazard = 더 많은 적 + 더 좋은 보상 + 더 높은 점수 배율
- **Hazard 5: "Lethal"** — 극한 도전

### 4-5. 중간보스 시스템
- 일정 웨이브마다 **중간보스** 등장
- 등장 시 **이미지 에셋 기반 경고 컷씬** (2초간)
- 보스 처치 시 대량 재화 + 레어 업그레이드 드롭
- 보스 종류:
  - **Glyphid Praetorian** (5웨이브) — 전면 장갑, 후방 약점
  - **Glyphid Oppressor** (10웨이브) — 밀어내기 공격
  - **Glyphid Dreadnought** (15웨이브) — 최종 보스급, 이미지 컷씬 연출
  - **Bulk Detonator** (랜덤) — 자폭형, 사망 시 **적색 원형 Shading**으로 폭발 범위를 명시적으로 표시 → 짧은 딜레이(~1.5초) 후 폭발 (회피 판단 시간 부여)

### 4-6. 웨이브 난이도 곡선 (Hazard 3 기준)

밸런싱의 기준점이 되는 난이도 곡선 테이블. Hazard 레벨에 따라 배율 적용.

#### 웨이브별 적 스폰 테이블 (v2 — 압축 난이도, 25초/웨이브)
| 웨이브 | 시간 (초) | Grunt 수 | Grunt HP | Grunt 속도 | 특수 적 | 비고 |
|--------|-----------|----------|----------|------------|---------|------|
| 1 | 0~25 | 20 | 40 | 1.1x | Swarmer x5 | 즉시 전투 시작 |
| 2 | 25~50 | 24 | 45 | 1.2x | Guard x2, Swarmer x4 | Guard 등장 |
| **3** | **50~75** | **28** | **50** | **1.2x** | **Praetorian x1**, Swarmer x6 | **첫 보스** |
| 4 | 75~100 | 24 | 55 | 1.3x | Guard x3 | 보스 후 소강 |
| 5 | 100~125 | 32 | 60 | 1.3x | Swarmer x10, Guard x2 | 고밀도 |
| **6** | **125~150** | **36** | **65** | **1.4x** | **Oppressor x1**, Guard x2 | **두 번째 보스** |
| 7 | 150~175 | 40 | 70 | 1.4x | Swarmer x14, Guard x3 | Swarm 러시 |
| 8 | 175~200 | 44 | 80 | 1.5x | Guard x4, Praetorian x1 | 복합 엘리트 |
| 9 | 200~225 | 50 | 90 | 1.5x | Guard x5, Swarmer x12 | 최종 에스컬레이션 |
| **10** | **225~250** | **55** | **100** | **1.6x** | **Dreadnought x1**, Guard x3 | **최종 보스** |

> 웨이브 10 이후 무한 스케일링 (x0.12/웨이브).
> **Bulk Detonator**: 웨이브 8 이후 각 웨이브에서 5% 확률로 랜덤 스폰.

#### Hazard 배율
| Hazard | 적 수 배율 | 적 HP 배율 | 적 속도 배율 | 점수 배율 |
|--------|-----------|-----------|-------------|----------|
| 1 (Easy) | 0.6x | 0.7x | 0.8x | 0.5x |
| 2 (Normal) | 0.8x | 0.85x | 0.9x | 0.75x |
| 3 (Challenging) | 1.0x | 1.0x | 1.0x | 1.0x |
| 4 (Hazardous) | 1.3x | 1.2x | 1.1x | 1.5x |
| 5 (Lethal) | 1.6x | 1.5x | 1.2x | 2.5x |

#### 적 타입별 기본 스탯
| 적 타입 | HP | 속도 | 데미지 | 특수 능력 |
|---------|-----|------|--------|----------|
| Glyphid Grunt | 30 | 1.0 | 10 | 없음 |
| Swarmer | 8 | 1.8 | 5 | 소형, 군체 이동 |
| Glyphid Guard | 60 | 0.8 | 15 | 전면 장갑 (데미지 50% 감소) |
| Praetorian | 200 | 0.6 | 30 | 전면 장갑, 독 방사 |
| Oppressor | 350 | 0.5 | 40 | 넉백 공격, 전면 무적 |
| Dreadnought | 800 | 0.4 | 50 | 체력 단계별 패턴 변화 |
| Bulk Detonator | 500 | 0.3 | 80 (자폭) | 사망 시 적색 원형 Shading(폭발 범위 표시) → ~1.5초 후 광역 폭발 |

---

## 5. 기술 구현 계획

### 5-1. 아키텍처
```
lib/
├── widgets/
│   └── survivor_game/
│       ├── survivor_game.dart          # 메인 게임 위젯 (StatefulWidget)
│       ├── game_engine.dart            # 게임 루프, 물리, 충돌
│       ├── entities/
│       │   ├── player.dart             # Scout 플레이어
│       │   ├── enemy.dart              # 적 (Glyphid 등)
│       │   ├── projectile.dart         # 투사체
│       │   ├── pickup.dart             # 아이템 (Gold, XP)
│       │   ├── nitra_node.dart         # Nitra 채굴 포인트
│       │   └── pit_jaw.dart            # Pit Jaw 환경 위험
│       ├── systems/
│       │   ├── weapon_system.dart      # 무기 로직 (자동 공격)
│       │   ├── wave_system.dart        # 웨이브/스폰 관리
│       │   ├── levelup_system.dart     # 레벨업 & Overclock 선택지
│       │   ├── nitra_system.dart       # Nitra 채굴 & 필살기
│       │   └── unlock_system.dart      # 무기 해금 관리
│       ├── ui/
│       │   ├── game_hud.dart           # HUD (HP, Nitra, 타이머)
│       │   ├── intro_screen.dart       # 인트로 씬 (이미지 에셋)
│       │   ├── loadout_screen.dart     # 장비 커스텀 (이미지 에셋)
│       │   ├── boss_cutscene.dart      # 보스 등장 컷씬 (이미지 에셋)
│       │   ├── levelup_modal.dart      # 레벨업 선택 UI
│       │   └── game_over_screen.dart   # 게임 오버 / 결과
│       └── data/
│           ├── weapon_data.dart        # 무기 스탯 & 해금 조건
│           ├── enemy_data.dart         # 적 스탯
│           └── boss_data.dart          # 보스 스탯 & 등장 웨이브
│
├── data/
│   └── minigame_data.dart              # 기존 파일에 survivor 게임 추가
│
├── assets/images/survivor/             # 이미지 에셋 디렉토리
│   ├── intro/                          # 인트로 씬 이미지
│   ├── weapons/                        # 무기 일러스트 (해금 화면용)
│   ├── bosses/                         # 보스 컷씬 이미지
│   ├── pickups/                        # 재화 아이콘 (Gold, Nitra 등)
│   └── ui/                             # UI 에셋 (버튼, 프레임 등)
│
└── utils/
    └── strings.dart                    # i18n 문자열 추가
```

### 5-2. 렌더링 방식 (하이브리드)
- **게임 플레이**: Flutter Canvas (`CustomPainter`) — 터미널 스타일
  - 기존 미니게임(Jet Boots, Whack-a-Mole)과 동일한 접근
  - 외부 게임 엔진 의존성 없음 (Flame 등 미사용)
- **이미지 에셋 레이어**: `Image` 위젯 / `Canvas.drawImage`
  - 인트로, 보스 컷씬: 별도 `Widget` 으로 오버레이
  - 인게임 재화/아이콘: `Canvas.drawImage` 로 작은 스프라이트 렌더링
  - 장비 커스텀 화면: 일반 Flutter `Widget` 기반 UI
- **게임 루프**: `Ticker` + `AnimationController` (60fps 타겟)
- **충돌 감지**: AABB(Axis-Aligned Bounding Box) — 단순하지만 충분
- **렌더링 최적화**: 화면 밖 엔티티 컬링, 오브젝트 풀링

### 5-3. 에셋 관리 전략
- 이미지 에셋은 **최소한으로** 유지 (앱 사이즈 관리)
- 에셋 우선순위:
  1. **필수**: 보스 이미지 (3-4장), 무기 아이콘 (6장), 재화 아이콘 (3장)
  2. **권장**: 인트로 배경 (1-2장), UI 프레임
  3. **선택**: 추가 연출 에셋
- 예상 에셋 총 사이즈: ~2-3MB
- 포맷: WebP (압축률 우수) 또는 PNG

### 5-4. 입력 방식 (극도로 단순화)
- **가상 조이스틱** (화면 왼쪽 하단 터치 & 드래그) — 이동 + 플릭(빠르게 밀어서 놓기) = 대시
- **수류탄 버튼 1개** (화면 오른쪽 하단) — Nitra 충분 시 활성화, 유일한 액티브 버튼
- 그 외 **모든 것은 자동**:
  - Primary 무기: 자동 사격 (가장 가까운 적)
  - Secondary 무기: 쿨다운마다 자동 발동 (인게임 획득 후)
  - 조명탄: 자동 주기적 발사
  - Nitra 채굴: 채굴 범위 안에 있으면 자동
- 레벨업 시: 게임 일시정지 + 3개 선택지 터치 (Overclock 또는 Secondary 무기)

> **원칙**: 플레이어가 동시에 조작하는 것은 **조이스틱 + 버튼 1개** 이하.
> 뱀서류의 "한 손으로 플레이 가능한" 접근성을 유지.

### 5-5. 데이터 영속성
- **SharedPreferences** 기반 (기존 미니게임과 동일)
  - 하이스코어 / 리더보드
  - 무기 해금 상태
  - 누적 킬 수 (해금 조건용)
  - 최고 도달 웨이브

### 5-6. 점수 & 리더보드
- 기존 `SharedPreferences` 기반 로컬 리더보드 활용
- 점수 요소:
  - 처치 수 x Hazard 배율
  - 생존 시간 보너스
  - 보스 처치 보너스
  - Nitra 채굴량 보너스

---

## 6. 기존 미니게임 시스템 연동

### minigame_data.dart에 추가
```dart
MiniGameItem(
  id: 'survivor',
  titleKey: 'minigame_survivor_title',
  descriptionKey: 'minigame_survivor_desc',
  isAvailable: true,
  icon: Icons.shield,  // 또는 커스텀 아이콘
),
```

### strings.dart i18n 추가
```dart
// KR
'minigame_survivor_title': 'HOXXES SURVIVAL',
'minigame_survivor_desc': 'Glyphid 군체에서 살아남아라!',

// EN
'minigame_survivor_title': 'HOXXES SURVIVAL',
'minigame_survivor_desc': 'Survive the Glyphid swarm!',

// ZH
'minigame_survivor_title': 'HOXXES SURVIVAL',
'minigame_survivor_desc': '从Glyphid虫群中生存下来！',
```

### minigame_list.dart 연동
- `coming_soon` 슬롯을 `survivor`로 교체
- 또는 `coming_soon` 앞에 새 항목 추가

---

## 7. 개발 로드맵

### Phase 1: Core Engine (MVP) — **완료**
- [x] 게임 루프 & 렌더링 엔진 (CustomPainter + AnimationController)
- [x] Scout 플레이어 이동 (가상 조이스틱 + 플릭 대시)
- [x] 기본 적 (Glyphid Grunt, Swarmer, Guard) 스폰 & AI
- [x] 기본 자동 공격 (Deepcore GK2 + Secondary 무기 인게임 획득)
- [x] 충돌 감지 & 데미지 (AABB, 전면 장갑, 관통)
- [x] HP 시스템 & 게임 오버 화면 (순차 리빌 + 리더보드)
- [x] 경험치 드롭 & 레벨업 (7종 스탯업 + Secondary 무기 3종)
- [x] HUD (HP바, XP바, 타이머, 웨이브, 킬 카운트, 레벨)
- [x] 보스 등장 (Praetorian W3, Oppressor W6, Dreadnought W10)
- [x] CRT 터미널 스타일 렌더링 (그리드, 스캔라인)
- [x] 카메라 시스템 (플레이어 중심 추적)
- [x] 디버그 오버레이 (타이틀 더블탭 토글)

### Phase 2-4: 상세 구현 계획 (5 Batch)

Phase 1(MVP)이 완료된 상태에서 4가지 개선을 동시 진행: 비주얼/사운드 폴리시, 보스 패턴, 나이트라/환경, 무기/레벨업 확장. 5개 배치로 나누어 **각 배치 후 완전히 플레이 가능한 상태를 유지**한다.

**배치 의존성**: `BATCH 1 (VFX) → BATCH 2 (보스) → BATCH 3 (나이트라) → BATCH 4 (무기) → BATCH 5 (사운드)`

---

#### BATCH 1: 비주얼 이펙트 & 화면 흔들림

**목표**: 게임 로직 변경 없이 렌더링만으로 체감 대폭 향상

##### 1a. 파티클 시스템
- [ ] **Create** `effects/particles.dart` — `Particle` + `ParticleSystem` 클래스
  - 적 사망: 6-10개 적 색상 파티클 폭발 (0.3s)
  - 피격 스파크: 3-4개 흰색/앰버 파티클 (충돌 지점)
  - 머즐 플래시: 2-3개 앰버 파티클 (플레이어 위치, 빠른 페이드)
  - 픽업 수집: 3-4개 픽업 색상 파티클
  - 폭발 이펙트: 15-25개 파티클 (Bulk Detonator, 수류탄 등)

##### 1b. 화면 흔들림
- [ ] **Modify** `survivor_game.dart` — `_shakeIntensity`, `_shakeDecay` 추가
  - 플레이어 피격: intensity 4, 보스 처치: 6, Bulk 폭발: 10
  - 카메라 오프셋에 랜덤 진동 적용 (`_GamePainter`에서 camX/camY에 shake 합산)

##### 1c. 적 사망 애니메이션
- [ ] **Modify** `entities/enemy.dart` — `deathTimer`, `deathScale`, `deathAlpha` 추가
  - 사망 시 즉시 제거 대신 축소+페이드 아웃 (0.3s) 후 제거
- [ ] **Modify** `game_engine.dart` — `_cleanup()`에서 `deathTimer <= 0`인 것만 제거

##### 1d. 통합
- [ ] **Modify** `game_engine.dart` — `ParticleSystem` 인스턴스 소유, `_onEnemyKilled`/충돌/발사 시 emit
- [ ] **Modify** `survivor_game.dart` — `_GamePainter`에서 파티클 렌더링

| 파일 | 액션 |
|------|------|
| `effects/particles.dart` | Create |
| `entities/enemy.dart` | Modify — deathTimer, deathScale, deathAlpha |
| `game_engine.dart` | Modify — ParticleSystem, emit 호출, cleanup 변경 |
| `survivor_game.dart` | Modify — 파티클 렌더, 화면 흔들림 |

**검증**: 적 처치 시 파티클 폭발, 피격 시 화면 흔들림, 적 사망 시 축소+페이드 아웃

---

#### BATCH 2: 보스 패턴 & 적 강화

**목표**: 보스별 고유 능력, Bulk Detonator 자폭, 보스 경고, Hazard Level

##### 2a. 보스 능력
- [ ] **Create** `systems/boss_abilities.dart` — 능력 정의 + AbilityState

| 보스 | 능력 | 구현 |
|------|------|------|
| Praetorian | 독 오라 | 반경 60 내 3 DPS, 녹색 원 렌더링 |
| Oppressor | 넉백 슬램 | 4초마다, 반경 80 내 플레이어 밀어냄 |
| Dreadnought | 2페이즈 | HP 50% 이하 시 속도 1.5x + 적 탄환 5발 확산 |
| Bulk Detonator | 자폭 | 사망→빨간 원(1.5초 팽창)→80데미지 광역 |

##### 2b. 적 탄환
- [ ] **Modify** `entities/projectile.dart` — `isEnemyProjectile` 플래그
- [ ] **Modify** `game_engine.dart` — `_checkEnemyProjectilePlayerCollisions()` 추가

##### 2c. 보스 경고 오버레이
- [ ] `game_engine.dart`에 `bossWarningTimer`, `bossWarningName` 추가
- [ ] 보스 스폰 시 1.5초간 "WARNING: [BOSS] INCOMING" 텍스트 오버레이 (게임 계속 진행)
- [ ] `survivor_game.dart`에서 경고 텍스트 렌더링

##### 2d. Hazard Level
- [ ] 시작 화면에 1~5 선택기 추가 (`survivor_game.dart`)
- [ ] `GameEngine` 생성자에 `hazardLevel` 파라미터
- [ ] 배율 적용: 적 HP (0.7x~1.5x), 속도 (0.8x~1.2x), 점수 (0.5x~2.5x)

##### 2e. Player 넉백
- [ ] **Modify** `entities/player.dart` — `knockbackVx/Vy`, `knockbackTimer`
- [ ] `player.update()`에서 넉백 벡터 적용 (감쇠)

| 파일 | 액션 |
|------|------|
| `systems/boss_abilities.dart` | Create |
| `entities/enemy.dart` | Modify — AbilityState, explodingTimer |
| `entities/projectile.dart` | Modify — isEnemyProjectile |
| `entities/player.dart` | Modify — knockback 필드 |
| `game_engine.dart` | Modify — 보스 능력 업데이트, 경고, Hazard, 적 탄환 충돌 |
| `survivor_game.dart` | Modify — 보스 이펙트 렌더, 경고 오버레이, Hazard 선택기 |

**검증**: 각 보스 능력 동작, Bulk 자폭 폭발, Hazard 선택 가능, 보스 경고 표시

---

#### BATCH 3: 나이트라 채굴 & 환경 시스템

**목표**: 나이트라 자원 루프 (채굴→수류탄) + Pit Jaw 위험 + 조명탄

##### 3a. 나이트라 노드
- [ ] **Create** `entities/nitra_node.dart` — 접근 시 자동 채굴 (1.5초), 진행률 바
  - 웨이브당 2-3개 스폰, 노드당 10-20 나이트라
  - **빨간색 결정** 스프라이트 (터미널 레드 색상으로 렌더링)

##### 3b. 수류탄 시스템
- [ ] **Create** `entities/aoe_effect.dart` — AoE 데미지 영역
  - 40 나이트라: 일반 수류탄 (반경 80, 100 데미지)
  - 80 나이트라: 클러스터 수류탄 (3개 소형 AoE)
  - 적 밀집 지역 자동 타겟팅

##### 3c. Pit Jaw
- [ ] **Create** `entities/pit_jaw.dart` — 은신 상태, 접근 시 20 데미지
  - Wave 3부터 1-2개 스폰
  - 2단계 가시성: 기본(미세한 힌트), 조명탄 범위 내(명확한 경고)

##### 3d. 조명탄
- [ ] **Create** `entities/flare.dart` — 자동 발사 (45초마다), 30초 지속, 반경 120
  - Pit Jaw 탐지 + 밝은 노란/흰색 광원 렌더링

##### 3e. UI & 스프라이트
- [ ] HUD에 나이트라 바 + 수류탄 버튼 (우하단) — `game_hud.dart`
- [ ] `sprite_data.dart`에 나이트라 결정, Pit Jaw 스프라이트 추가

| 파일 | 액션 |
|------|------|
| `entities/nitra_node.dart` | Create |
| `entities/aoe_effect.dart` | Create |
| `entities/pit_jaw.dart` | Create |
| `entities/flare.dart` | Create |
| `entities/player.dart` | Modify — nitra, flareTimer |
| `game_engine.dart` | Modify — 스폰/업데이트/수류탄 로직 |
| `survivor_game.dart` | Modify — 렌더링, 수류탄 버튼 |
| `data/sprite_data.dart` | Modify — 나이트라/PitJaw 스프라이트 |
| `ui/game_hud.dart` | Modify — 나이트라 바, 수류탄 인디케이터 |

**검증**: 나이트라 노드 채굴, 수류탄 발사, Pit Jaw 피격, 조명탄 자동 발사 확인

---

#### BATCH 4: 무기 & 레벨업 확장

**목표**: 장비 선택 화면, 무기 해금 시스템, 레벨업 선택지 확장

##### 4a. 해금 매니저
- [ ] **Create** `systems/unlock_manager.dart` — SharedPreferences 기반
  - GK2: 기본, M1000: 500킬, DRAK-25: 보스킬 or 2000킬
  - 누적 킬/보스킬 추적

##### 4b. 장비 선택 화면
- [ ] **Create** `ui/loadout_screen.dart` — 터미널 스타일 무기 선택 UI
  - 3개 Primary 무기 표시 (잠긴 것은 회색 + 해금 조건 텍스트)
  - 선택한 무기 스탯 미리보기
  - "DEPLOY" 버튼

##### 4c. DRAK-25 밸런스 조정
- [ ] `data/weapon_data.dart` 수정
  - 현재: damage 8, fireRate 7.0, range 200, 2발 → DPS 112 (과도)
  - 변경: damage 6, fireRate 5.5, range 250, 2발 → DPS 66 (GK2 48보다 조금 높은 수준)

##### 4d. 레벨업 선택지 추가
- [ ] `game_engine.dart` — LevelUpChoiceType에 추가:
  - `pierceUp` — 관통 +1
  - `dashCooldownDown` — 대시 쿨다운 -0.3초
  - `nitraEfficiency` — 나이트라 채굴량 +25%
  - `grenadeRadius` — 수류탄 반경 +20%

##### 4e. 게임 흐름 변경
- [ ] 시작→로드아웃→플레이 3단계 흐름 (`survivor_game.dart`)
- [ ] 게임 오버 시 해금 상태 업데이트 + 새 해금 알림 (`game_over_screen.dart`)

| 파일 | 액션 |
|------|------|
| `systems/unlock_manager.dart` | Create |
| `ui/loadout_screen.dart` | Create |
| `data/weapon_data.dart` | Modify — DRAK-25 밸런스 |
| `game_engine.dart` | Modify — 새 LevelUpChoiceType, applyChoice |
| `survivor_game.dart` | Modify — 로드아웃 흐름, 해금 알림 |
| `ui/game_over_screen.dart` | Modify — 해금 알림 표시 |

**검증**: 로드아웃 화면에서 무기 선택, 해금 진행, 새 레벨업 선택지 동작 확인

---

#### BATCH 5: 사운드 이펙트

**목표**: 전체 게임에 오디오 피드백 추가

##### 5a. 사운드 매니저
- [ ] **Create** `systems/sound_manager.dart` — AudioPlayer 풀 (4개) + 라운드 로빈
  - 무기 발사, 피격, 적 사망, 보스 경고, 레벨업, 곡괭이, 수류탄, 게임오버

##### 5b. 콜백 패턴 (엔진 독립성 유지)
- [ ] `game_engine.dart`에 이벤트 콜백 추가:
  ```dart
  void Function()? onWeaponFire, onEnemyHit, onEnemyKilled, onPlayerHit,
                    onLevelUp, onNitraMined, onGrenadeUsed;
  void Function(String)? onBossWarning;
  ```
- [ ] `survivor_game.dart`에서 콜백을 SoundManager에 연결

##### 5c. 음소거 토글
- [ ] 상단 바에 `[SND]`/`[---]` 토글 추가 (`survivor_game.dart`)

| 파일 | 액션 |
|------|------|
| `systems/sound_manager.dart` | Create |
| `game_engine.dart` | Modify — 이벤트 콜백 |
| `survivor_game.dart` | Modify — SoundManager 연결, 음소거 토글 |

**검증**: 각 이벤트에서 사운드 재생, 음소거 토글 확인

---

#### 전체 파일 변경 요약

| 파일 | Batch 1 | Batch 2 | Batch 3 | Batch 4 | Batch 5 |
|------|---------|---------|---------|---------|---------|
| `effects/particles.dart` | **Create** | | | | |
| `systems/boss_abilities.dart` | | **Create** | | | |
| `systems/unlock_manager.dart` | | | | **Create** | |
| `systems/sound_manager.dart` | | | | | **Create** |
| `entities/nitra_node.dart` | | | **Create** | | |
| `entities/aoe_effect.dart` | | | **Create** | | |
| `entities/pit_jaw.dart` | | | **Create** | | |
| `entities/flare.dart` | | | **Create** | | |
| `ui/loadout_screen.dart` | | | | **Create** | |
| `entities/enemy.dart` | Modify | Modify | | | |
| `entities/player.dart` | | Modify | Modify | | |
| `entities/projectile.dart` | | Modify | | | |
| `game_engine.dart` | Modify | Modify | Modify | Modify | Modify |
| `survivor_game.dart` | Modify | Modify | Modify | Modify | Modify |
| `data/sprite_data.dart` | | | Modify | | |
| `data/weapon_data.dart` | | | | Modify | |
| `ui/game_hud.dart` | | | Modify | | |
| `ui/game_over_screen.dart` | | | | Modify | |

**총 새 파일**: 9개 / **수정 파일**: 10개

---

## 8. 리스크 & 고려사항

| 리스크 | 영향도 | 대응 |
|--------|--------|------|
| 성능 (많은 엔티티) | 높음 | 오브젝트 풀링, 화면 밖 컬링, 최대 적 수 제한 |
| **앱 사이즈 증가 (이미지 에셋)** | **높음** | WebP 압축, 필수 에셋만 우선 포함 (~2-3MB), 해상도 최적화 |
| 터치 조작 불편 | 중간 | 가상 조이스틱 데드존 조정, 자동 공격으로 조작 최소화 |
| 개발 시간 (볼륨 증가) | 높음 | Phase 1 MVP를 먼저 릴리즈, 점진적 확장 |
| DRG IP 사용 | 낮음 | 비영리 팬 앱, Ghost Ship Games의 관용적 정책 |
| 배터리 소모 | 중간 | 30fps 옵션, 백그라운드 시 자동 정지 |
| **이미지 에셋 제작** | **높음** | 자체 제작 or 라이센스 프리 에셋 활용, AI 생성 아트 검토 |

---

## 8. 참고 자료

- [Vampire Survivors](https://store.steampowered.com/app/1794680/Vampire_Survivors/) — 장르 대표작
- [Magic Survival](https://play.google.com/store/apps/details?id=com.vkslr.survival) — 장르 원조
- [DRG Wiki - Enemies](https://deeprockgalactic.wiki.gg/wiki/Creatures) — 적 데이터
- [DRG Wiki - Weapons](https://deeprockgalactic.wiki.gg/wiki/Equipment) — 무기 데이터
- 기존 미니게임 구현: `lib/widgets/jet_boots/`, `lib/widgets/whack_a_mole/`, `lib/widgets/survivor_game/`
