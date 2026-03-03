# Survivor 미니게임 기획서

> DRG Mission Tracker 앱의 미니게임 탭에 추가할 뱀파이어 서바이버 스타일 게임 기획.

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
- **"Swarm Survival"** (군체 생존) — DRG의 Swarm 이벤트에서 착안
- **"Hold the Line"** (방어선 사수)
- **"Bug Hunt"** (벌레 사냥)

### 핵심 루프
```
[웨이브 시작] → [자동 공격으로 Glyphid 처치] → [경험치 획득]
     ↑              ↓
[새 웨이브]    [레벨업 → 무기/능력 선택]
     ↑              ↓
[난이도 상승]  [보스 등장 (Dreadnought)]
     ↑              ↓
[반복]        [처치 → 미네랄 드롭 → 강화]
```

### DRG 테마 적용
| 뱀서류 일반 | DRG 버전 |
|-------------|----------|
| 캐릭터 | 4개 드워프 클래스 (Driller, Scout, Gunner, Engineer) |
| 적 몬스터 | Glyphid Grunt, Praetorian, Oppressor, Bulk Detonator |
| 보스 | Dreadnought, Hiveguard, Twins |
| 무기 | DRG Primary/Secondary 무기 |
| 경험치 젬 | Nitra, Gold, Morkite |
| 맵 배경 | DRG 바이옴 (Salt Pits, Magma Core, Crystalline Caverns) |
| 레벨업 선택지 | Overclock 선택 |

---

## 3. 독자적 시스템 (차별화 요소)

### 3-1. Supply Drop 시스템 (탄약 관리)
- VS류 게임과의 **핵심 차별점**
- 무기별 탄약이 존재, 자동 공격 시 소모
- 탄약 0 = 해당 무기 비활성 (곡괭이로만 공격)
- 일정 시간마다 **Supply Pod** 드롭 → 탄약 보급
- Supply Pod 위치까지 이동해야 보급 가능
- **전략적 판단**: 안전 지대를 벗어나 Supply Pod로 갈 것인가?

```
┌─────────────────────────────────┐
│                                 │
│    🪲🪲🪲        📦 Supply     │
│   🪲 DRILLER 🪲    Pod         │
│    🪲🪲🪲                      │
│                                 │
│  [Ammo: ████░░░░ 45%]          │
│  탄약 부족! Supply Pod로 이동?  │
└─────────────────────────────────┘
```

### 3-2. Terrain 시스템 (지형 상호작용)
- DRG의 핵심 — **파괴 가능한 지형**
- 맵에 파괴 가능한 바위/벽 존재
- Driller: 지형을 뚫어 새 경로 생성
- Engineer: 플랫폼 설치로 장벽 생성
- 지형 뒤에 숨겨진 미네랄/아이템

### 3-3. 클래스별 고유 능력
| 클래스 | 고유 능력 | 전략적 역할 |
|--------|-----------|-------------|
| **Driller** | 화염방사기 (부채꼴 공격), 지형 파괴 | 근거리 광역, 경로 개척 |
| **Scout** | 기동력 2배, 그래플링 훅 (순간이동), 조명탄 (시야 확보) | 회피 특화, 아이템 수집 |
| **Gunner** | 미니건 (직선 관통), 보호막 생성기 | 화력 특화, 방어 거점 |
| **Engineer** | 센트리 건 (자동 포탑 설치), 플랫폼 (벽 생성) | 거점 방어, 설치물 전략 |

### 3-4. Hazard Level 시스템
- DRG의 난이도 체계 그대로 활용
- Hazard 1~5 선택 가능
- 높은 Hazard = 더 많은 적 + 더 좋은 보상 + 더 높은 점수 배율
- **Hazard 5: "Lethal"** — 극한 도전

### 3-5. 미네랄 수집 & Forge 시스템
- 적 처치 시 Nitra, Gold, Morkite 드롭
- **Nitra**: Supply Pod 호출에 사용 (DRG 원작과 동일)
- **Gold**: 게임 내 영구 업그레이드 (런 간 진행)
- **Morkite**: 미션 목표 달성 (수집 미션)

### 3-6. Mission Objective (미션 목표)
- 단순 생존이 아닌, **미션 목표** 부여
- Mining: Morkite 일정량 수집
- Egg Hunt: 맵에 흩어진 에일리언 알 수집
- Elimination: 보스 Dreadnought 처치
- Point Extraction: Aquarq를 Mine Head로 운반
- 미션 완수 시 보너스 점수 + 탈출 페이즈

### 3-7. Molly & Escape 시스템
- 미션 목표 달성 후 **탈출** 페이즈 돌입
- **Molly**(광물 운반 로봇)가 탈출 지점으로 이동 시작
- 제한 시간 내에 Drop Pod(탈출선)에 도달해야 함
- 탈출 실패 = 점수 감소 (전멸은 아님)
- DRG의 가장 긴장감 있는 순간을 재현

---

## 4. 기술 구현 계획

### 4-1. 아키텍처
```
lib/
├── widgets/
│   └── survivor_game/
│       ├── survivor_game.dart          # 메인 게임 위젯 (StatefulWidget)
│       ├── game_engine.dart            # 게임 루프, 물리, 충돌
│       ├── entities/
│       │   ├── player.dart             # 플레이어 (드워프)
│       │   ├── enemy.dart              # 적 (Glyphid 등)
│       │   ├── projectile.dart         # 투사체
│       │   ├── pickup.dart             # 아이템 (Nitra, Gold, XP)
│       │   └── supply_pod.dart         # Supply Pod
│       ├── systems/
│       │   ├── weapon_system.dart      # 무기 로직
│       │   ├── wave_system.dart        # 웨이브/스폰 관리
│       │   ├── levelup_system.dart     # 레벨업 & 선택지
│       │   └── terrain_system.dart     # 지형 상호작용
│       ├── ui/
│       │   ├── game_hud.dart           # HUD (HP, 탄약, 타이머)
│       │   ├── levelup_modal.dart      # 레벨업 선택 UI
│       │   ├── game_over_screen.dart   # 게임 오버 / 결과
│       │   └── class_select_screen.dart # 클래스 선택
│       └── data/
│           ├── weapon_data.dart        # 무기 스탯
│           ├── enemy_data.dart         # 적 스탯
│           └── class_data.dart         # 클래스 스탯
│
├── data/
│   └── minigame_data.dart              # 기존 파일에 survivor 게임 추가
│
└── utils/
    └── strings.dart                    # i18n 문자열 추가
```

### 4-2. 렌더링 방식
- **Flutter Canvas (CustomPainter)** 사용
  - 외부 게임 엔진 의존성 없음 (Flame 등 미사용)
  - 기존 미니게임(Jet Boots, Whack-a-Mole)과 동일한 접근
  - 앱 번들 사이즈 증가 최소화
- **게임 루프**: `Ticker` + `AnimationController` (60fps 타겟)
- **충돌 감지**: AABB(Axis-Aligned Bounding Box) — 단순하지만 충분
- **렌더링 최적화**: 화면 밖 엔티티 컬링, 오브젝트 풀링

### 4-3. 비주얼 스타일
- 기존 미니게임과 일관된 **터미널/레트로 스타일**
- CRT 그린(#39FF14) 기반 or DRG 앰버 톤(#FFA500)
- 엔티티는 간단한 기하학적 도형 + 아이콘으로 표현
  - 플레이어: 드워프 실루엣 (클래스별 색상 구분)
  - 적: 원형/삼각형 (크기로 종류 구분)
  - 투사체: 작은 점/선
- ASCII 아트 느낌의 미니멀한 연출

```
시각적 예시 (터미널 그린 테마):

┌──────────────────────────────────────┐
│  SWARM SURVIVAL    HAZ:3   02:34     │
│  ══════════════════════════════════   │
│  HP ████████░░  AMMO ██████░░░░░░    │
│                                      │
│         ·  ·                         │
│      ·  ▲  · ·    ◆ ◆               │
│    · · ·█· · ·      ◆               │
│      ·  · ·                          │
│         ·        ■ Supply Pod        │
│                                      │
│  [LV.5] Kills: 127  Nitra: 34/80    │
│  ▲=You  ·=Glyphid  ◆=Gold  ■=Pod   │
└──────────────────────────────────────┘
```

### 4-4. 입력 방식
- **가상 조이스틱** (화면 왼쪽 하단 터치 & 드래그)
- 공격은 **완전 자동** (뱀서류 핵심 — 이동만 조작)
- 특수 능력: 화면 오른쪽 하단 버튼 (쿨다운 있음)
- 레벨업 시: 게임 일시정지 + 3개 선택지 터치

### 4-5. 점수 & 리더보드
- 기존 `SharedPreferences` 기반 로컬 리더보드 활용
- 점수 요소:
  - 처치 수 x Hazard 배율
  - 미션 목표 달성 보너스
  - 생존 시간 보너스
  - 탈출 성공 보너스

---

## 5. 기존 미니게임 시스템 연동

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
'minigame_survivor_title': 'SWARM SURVIVAL',
'minigame_survivor_desc': 'Glyphid 군체에서 살아남아라!',

// EN
'minigame_survivor_title': 'SWARM SURVIVAL',
'minigame_survivor_desc': 'Survive the Glyphid swarm!',

// ZH
'minigame_survivor_title': 'SWARM SURVIVAL',
'minigame_survivor_desc': '从Glyphid虫群中生存下来！',
```

### minigame_list.dart 연동
- `coming_soon` 슬롯을 `survivor`로 교체
- 또는 `coming_soon` 앞에 새 항목 추가

---

## 6. 개발 로드맵

### Phase 1: Core (MVP)
- [ ] 게임 루프 & 렌더링 엔진 (CustomPainter + Ticker)
- [ ] 플레이어 이동 (가상 조이스틱)
- [ ] 기본 적 스폰 & AI (플레이어를 향해 이동)
- [ ] 기본 자동 공격 (1개 무기)
- [ ] 충돌 감지 & 데미지
- [ ] HP 시스템 & 게임 오버
- [ ] 경험치 드롭 & 레벨업 (3개 선택지)
- [ ] HUD (HP, 타이머, 킬 카운트)

### Phase 2: DRG Identity
- [ ] 4개 클래스 선택 & 고유 능력
- [ ] DRG 무기 체계 (Primary/Secondary)
- [ ] 적 다양화 (Grunt, Praetorian, Bulk Detonator)
- [ ] Nitra 수집 → Supply Pod 호출
- [ ] Hazard Level 선택

### Phase 3: Unique Systems
- [ ] Mission Objective 시스템
- [ ] 탈출 페이즈 (Molly & Drop Pod)
- [ ] Terrain 시스템 (기본)
- [ ] 보스전 (Dreadnought)

### Phase 4: Polish
- [ ] 효과음 (DRG 테마)
- [ ] 점수 & 로컬 리더보드
- [ ] 밸런스 조정
- [ ] 성능 최적화 (오브젝트 풀링, 컬링)
- [ ] i18n (KR, EN, ZH)

---

## 7. 리스크 & 고려사항

| 리스크 | 영향도 | 대응 |
|--------|--------|------|
| 성능 (많은 엔티티) | 높음 | 오브젝트 풀링, 화면 밖 컬링, 최대 적 수 제한 |
| 앱 사이즈 증가 | 중간 | 에셋 최소화 (기하학적 도형 렌더링), 기존 오디오 재활용 |
| 터치 조작 불편 | 중간 | 가상 조이스틱 데드존 조정, 자동 공격으로 조작 최소화 |
| 개발 시간 | 높음 | Phase 1 MVP를 먼저 릴리즈, 점진적 확장 |
| DRG IP 사용 | 낮음 | 비영리 팬 앱, Ghost Ship Games의 관용적 정책 |
| 배터리 소모 | 중간 | 30fps 옵션, 백그라운드 시 자동 정지 |

---

## 8. 참고 자료

- [Vampire Survivors](https://store.steampowered.com/app/1794680/Vampire_Survivors/) — 장르 대표작
- [Magic Survival](https://play.google.com/store/apps/details?id=com.vkslr.survival) — 장르 원조
- [DRG Wiki - Enemies](https://deeprockgalactic.wiki.gg/wiki/Creatures) — 적 데이터
- [DRG Wiki - Weapons](https://deeprockgalactic.wiki.gg/wiki/Equipment) — 무기 데이터
- 기존 미니게임 구현: `lib/widgets/jet_boots_game.dart`, `lib/widgets/whack_a_mole_game.dart`
