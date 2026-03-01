/// 트리비아 데이터: 바이옴/미션타입/버프/경고별 설명과 팁
/// 키: 영문 원본 이름 (strings.dart의 i18n 키와 동일)
/// 값: 언어별 { 'desc': 설명, 'tips': 팁 리스트(줄바꿈 구분) }
const Map<String, Map<String, Map<String, String>>> triviaData = {
  // ═══════════════════════════════════════════════════════════════════════════
  //  바이옴 (11개)
  // ═══════════════════════════════════════════════════════════════════════════

  'Azure Weald': {
    'KR': {
      'desc': '발광 식물과 푸른 수정이 가득한 아름다운 지하 숲. 높은 천장과 넓은 공간이 특징.',
      'tips': '천장의 발광 식물이 자연 조명 역할을 해줌\n넓은 공간이 많아 이동이 비교적 수월\n케이브 엔젤을 타고 날 수 있음!',
    },
    'EN': {
      'desc': 'A beautiful underground forest filled with bioluminescent plants and blue crystals. Features high ceilings and open spaces.',
      'tips': 'Bioluminescent plants provide natural lighting\nOpen spaces make navigation relatively easy\nYou can ride Cave Angels to fly!',
    },
    'CN': {
      'desc': '充满发光植物和蓝色水晶的美丽地下森林。以高天花板和开阔空间为特征。',
      'tips': '天花板上的发光植物提供自然照明\n开阔空间多，移动相对容易\n可以骑乘洞穴天使飞行！',
    },
  },

  'Crystalline Caverns': {
    'KR': {
      'desc': '거대한 수정이 벽과 천장에 박혀있는 동굴. 전기 수정이 주기적으로 방전됨.',
      'tips': '전기 수정은 생각보다 강한 데미지를 줌\n수정이 많아 맵 밝기가 좋은 편\n수직 구조가 많아 집라인이 유용',
    },
    'EN': {
      'desc': 'Caves with massive crystals embedded in walls and ceilings. Electric crystals periodically discharge.',
      'tips': 'Electric crystals deal more damage than expected\nPlenty of crystals provide good map visibility\nVertical structures make ziplines useful',
    },
    'CN': {
      'desc': '巨大水晶嵌入墙壁和天花板的洞穴。电水晶会周期性放电。',
      'tips': '电水晶造成的伤害比预期的更高\n水晶多，地图亮度较好\n垂直结构多，滑索很有用',
    },
  },

  'Dense Biozone': {
    'KR': {
      'desc': '거대한 식물과 유기체로 뒤덮인 밀집된 생태지역. 좁은 통로와 독성 식물 주의.',
      'tips': '구 보머의 끈적이가 바닥에 있음\n좁은 통로가 많아 근접전 주의\n유기체 벽은 곡괭이로 파괴 가능',
    },
    'EN': {
      'desc': 'A dense ecosystem covered in giant plants and organisms. Watch for narrow passages and toxic plants.',
      'tips': 'Goo Bomber goo covers the floor\nNarrow passages require caution in close combat\nOrganic walls can be destroyed with pickaxe',
    },
    'CN': {
      'desc': '被巨大植物和有机体覆盖的密集生态区。注意狭窄通道和有毒植物。',
      'tips': '粘液轰炸者的粘液覆盖地面\n狭窄通道多，近战需小心\n有机体墙壁可用镐头破坏',
    },
  },

  'Fungus Bogs': {
    'KR': {
      'desc': '거대 버섯과 독성 가스 웅덩이가 가득한 늪지. 지형이 복잡하고 시야가 나쁨.',
      'tips': '폭발하는 버섯은 사격으로 미리 터뜨리기\n지형이 복잡해 길을 잃기 쉬움',
    },
    'EN': {
      'desc': 'Swamps full of giant mushrooms and toxic gas pools. Complex terrain with poor visibility.',
      'tips': 'Shoot explosive mushrooms from distance to detonate them\nComplex terrain makes it easy to get lost',
    },
    'CN': {
      'desc': '充满巨型蘑菇和有毒气体水池的沼泽。地形复杂，视野不佳。',
      'tips': '从远处射击爆炸蘑菇引爆\n地形复杂，容易迷路',
    },
  },

  'Glacial Strata': {
    'KR': {
      'desc': '얼어붙은 지하 동굴. 눈보라와 빙판이 이동을 방해하고, 냉기 속성 적이 출현.',
      'tips': '눈보라 중에는 시야가 크게 감소\n빙판에서 미끄러짐 주의',
    },
    'EN': {
      'desc': 'Frozen underground caves. Blizzards and ice surfaces hinder movement, and cryo enemies appear.',
      'tips': 'Visibility drops significantly during blizzards\nWatch for slipping on ice surfaces',
    },
    'CN': {
      'desc': '冰冻的地下洞穴。暴风雪和冰面阻碍移动，会出现冰冻敌人。',
      'tips': '暴风雪期间视野大幅降低\n注意冰面上的滑倒',
    },
  },

  'Hollow Bough': {
    'KR': {
      'desc': '거대한 나무 뿌리와 가시 덤불로 이루어진 동굴. 가시 접촉 시 데미지를 줌.',
      'tips': '가시 덤불은 파괴가 가능함(근접공격)\n찌름 덩굴은 노란 핵을 쏘아 파괴 가능',
    },
    'EN': {
      'desc': 'Caves made of giant tree roots and thorn bushes. Thorns deal damage on contact.',
      'tips': 'Thorn bushes can be destroyed (melee attack)\nStabber Vines can be destroyed by shooting their yellow core',
    },
    'CN': {
      'desc': '由巨大树根和荆棘丛组成的洞穴。荆棘接触时造成伤害。',
      'tips': '荆棘丛可以被破坏（近战攻击）\n刺藤可以通过射击黄色核心来摧毁',
    },
  },

  'Magma Core': {
    'KR': {
      'desc': '용암과 화염 간헐천이 가득한 고온 환경. 지진과 화산 분출 이벤트 발생.',
      'tips': '화염 간헐천은 주기적으로 분출하고, 파괴 시 폭발\n지진 발생 혹은 천장에서 운석 낙하 주의',
    },
    'EN': {
      'desc': 'High-temperature environment full of lava and fire geysers. Earthquakes and volcanic events occur.',
      'tips': 'Fire geysers erupt periodically and explode when destroyed\nWatch for earthquakes or meteor falls from the ceiling',
    },
    'CN': {
      'desc': '充满岩浆和火焰间歇泉的高温环境。会发生地震和火山事件。',
      'tips': '火焰间歇泉周期性喷发，被破坏时会爆炸\n注意地震或天花板掉落的陨石',
    },
  },

  'Radioactive Exclusion Zone': {
    'KR': {
      'desc': '방사능에 오염된 위험 구역. 발광하는 방사성 광물과 돌연변이 생물이 서식.',
      'tips': '방사능 수정 근처에 오래 머물면 피해 누적\n발광 글리피드는 죽을 때 방사능 폭발\n어둡고 복잡한 지형에 주의',
    },
    'EN': {
      'desc': 'Radioactive contaminated danger zone. Home to glowing radioactive minerals and mutant creatures.',
      'tips': 'Prolonged exposure near radioactive crystals causes damage\nGlowing enemies explode with radiation on death\nDark and complex terrain requires caution',
    },
    'CN': {
      'desc': '受放射性污染的危险区域。有发光的放射性矿物和变异生物。',
      'tips': '在放射性水晶附近停留过久会累积伤害\n发光敌人死亡时会产生放射性爆炸\n注意黑暗复杂的地形',
    },
  },

  'Salt Pits': {
    'KR': {
      'desc': '소금 결정으로 이루어진 거대한 동굴. 넓은 공간과 높은 천장이 특징.',
      'tips': '매우 넓은 공간이 많아 원거리 전투에 유리\n수직 절벽이 많아 낙사 주의',
    },
    'EN': {
      'desc': 'Massive caves made of salt crystals. Features wide open spaces and high ceilings.',
      'tips': 'Very wide spaces favor ranged combat\nMany vertical cliffs — watch for fall damage',
    },
    'CN': {
      'desc': '由盐晶体组成的巨大洞穴。以宽阔空间和高天花板为特征。',
      'tips': '非常宽阔的空间有利于远程战斗\n垂直悬崖多，注意坠落伤害',
    },
  },

  'Sandblasted Corridors': {
    'KR': {
      'desc': '모래 폭풍이 몰아치는 좁은 회랑. 강풍과 모래로 시야가 제한됨.',
      'tips': '모래 폭풍 중에는 시야가 극도로 제한\n좁은 통로에서 적과 조우하면 위험\n바람에 밀려 낙하 주의',
    },
    'EN': {
      'desc': 'Narrow corridors with raging sandstorms. Wind and sand limit visibility.',
      'tips': 'Visibility is extremely limited during sandstorms\nEncountering enemies in narrow corridors is dangerous\nWatch for being pushed by wind and falling',
    },
    'CN': {
      'desc': '沙尘暴肆虐的狭窄走廊。风沙限制视野。',
      'tips': '沙尘暴期间视野极度受限\n在狭窄走廊遭遇敌人很危险\n注意被风吹动而坠落',
    },
  },

  'Ossuary Depths': {
    'KR': {
      'desc': '뼈와 화석으로 가득한 깊은 동굴. Season 6에서 추가된 새로운 바이옴.',
      'tips': '뼈 구조물은 파괴 가능하며 통로를 만들 수 있음\n독특한 적 배치 패턴에 주의\n오스뮴을 모으면 미션 진행도 크게 상승',
    },
    'EN': {
      'desc': 'Deep caves filled with bones and fossils. New biome added in Season 6.',
      'tips': 'Bone structures are destructible and can create passages\nWatch for unique enemy placement patterns\nCollecting Osmium greatly increases mission progress',
    },
    'CN': {
      'desc': '充满骨骼和化石的深层洞穴。第6赛季新增的生物群落。',
      'tips': '骨骼结构可破坏，可以创造通道\n注意独特的敌人配置模式\n收集锇可以大幅提升任务进度',
    },
  },

  // ═══════════════════════════════════════════════════════════════════════════
  //  미션 타입 (10개)
  // ═══════════════════════════════════════════════════════════════════════════

  'Mining Expedition': {
    'KR': {
      'desc': '모르카이트를 채굴하여 목표량을 달성하는 기본 미션. 긴 통로 형태의 맵 구성.',
      'tips': '비교적 쉬운 난이도\n드랍포드가 내려오는 길 어딘가에 낙하',
    },
    'EN': {
      'desc': 'Mine Morkite to reach the quota. Features long corridor-style map layouts.',
      'tips': 'Relatively easy difficulty\nDrop pod lands somewhere along the descent path',
    },
    'CN': {
      'desc': '开采莫尔石达到目标量的基本任务。地图为长走廊式布局。',
      'tips': '难度相对较低\n掉落舱会降落在下行路径的某处',
    },
  },

  'Egg Hunt': {
    'KR': {
      'desc': '글리포드 알을 수집하는 미션. 알을 파내면 확률적으로 적 웨이브가 발생.',
      'tips': '알을 파기 전에 주변 방어 준비 필수\n한 번에 여러 개를 파면 웨이브가 중첩됨\n알의 위치는 지형 스캐너로 미리 파악',
    },
    'EN': {
      'desc': 'Collect Glyphid eggs. Extracting eggs may trigger enemy waves.',
      'tips': 'Prepare defenses before extracting eggs\nExtracting multiple eggs stacks waves\nLocate eggs early with terrain scanner',
    },
    'CN': {
      'desc': '收集格里芬虫卵的任务。挖掘卵时可能触发敌人波次。',
      'tips': '提取卵前准备好防御\n同时提取多个卵会叠加波次\n用地形扫描仪提前定位卵的位置',
    },
  },

  'On-Site Refining': {
    'KR': {
      'desc': '액체 모르카이트 파이프라인을 설치하고 정제하는 미션. 파이프 설치가 핵심.',
      'tips': '파이프 경로를 미리 계획하면 시간 절약\n파이프 위에서 미끄러져 이동 가능\n정제 완료 후 이벤트가 없다면 바로 버튼 누르기',
    },
    'EN': {
      'desc': 'Install liquid Morkite pipelines and refine. Pipeline routing is key.',
      'tips': 'Planning pipe routes in advance saves time\nYou can grind-ride on top of pipes\nPress the button right away after refining if no events are active',
    },
    'CN': {
      'desc': '安装液态矿石管道并进行精炼。管道布局是关键。',
      'tips': '提前规划管道路线节省时间\n可以在管道上滑行移动\n精炼完成后如果没有事件就立即按下按钮',
    },
  },

  'Point Extraction': {
    'KR': {
      'desc': '중앙 채굴 플랫폼에서 Aquarq를 수집하는 미션. 시간이 지날수록 적이 강해짐.',
      'tips': '몰리가 없음\n시간이 지날수록 적이 강해지니 속도가 중요\n벽에서 빛나는 지점을 찾아 채굴 시 아쿠아크',
    },
    'EN': {
      'desc': 'Collect Aquarqs from the central mining platform. Enemies scale with time.',
      'tips': 'No Molly in this mission\nEnemies get stronger over time — speed matters\nLook for glowing spots in walls to mine Aquarqs',
    },
    'CN': {
      'desc': '在中央开采平台收集水晶矿。敌人强度随时间增加。',
      'tips': '此任务没有莫莉\n敌人会随时间变强——速度很重要\n在墙上寻找发光点开采水晶矿',
    },
  },

  'Salvage Operation': {
    'KR': {
      'desc': '추락한 미니뮬을 수리하고 업링크 방어 미션. 고정 위치 방어가 핵심.',
      'tips': '업링크 구역은 미리 평탄화하면 방어 유리\n엔지니어의 터렛과 드릴러의 공사가 핵심',
    },
    'EN': {
      'desc': 'Repair crashed Mini-MULEs and defend uplink. Fixed position defense is key.',
      'tips': 'Flatten the uplink area beforehand for easier defense\nEngineer turrets and Driller construction are key',
    },
    'CN': {
      'desc': '修复坠毁的迷你骡并防守上行链路。固定位置防御是关键。',
      'tips': '提前整平上行链路区域便于防守\n工程师炮塔和钻工的施工是关键',
    },
  },

  'Escort Duty': {
    'KR': {
      'desc': '도저를 호위하며 하트스톤을 채굴하는 미션. 긴 시간과 높은 난이도가 특징.',
      'tips': '중간중간 연료가 바닥나서 오일셰일 채굴\n나이트라가 넉넉한 편\n도레타 파괴 시 미션 실패',
    },
    'EN': {
      'desc': 'Escort the Drilldozer to mine the Heartstone. Long duration and high difficulty.',
      'tips': 'Oil Shale mining needed when fuel runs out periodically\nNitra is relatively abundant\nMission fails if Doretta is destroyed',
    },
    'CN': {
      'desc': '护送钻地机开采心脏石。持续时间长，难度高。',
      'tips': '燃料定期耗尽时需要开采油页岩\n硝石相对充足\n多蕾塔被摧毁则任务失败',
    },
  },

  'Elimination': {
    'KR': {
      'desc': '드레드노트 보스를 처치하는 미션. 보스 패턴 숙지가 생존의 핵심.',
      'tips': '속성 무기가 매우 효과적인 편\n스카웃의 전도성 온도 카빈이 유용함',
    },
    'EN': {
      'desc': 'Eliminate Dreadnought bosses. Knowing boss patterns is key to survival.',
      'tips': 'Elemental weapons are very effective\nScout\'s Conductive Thermals Carbine is useful',
    },
    'CN': {
      'desc': '消灭无畏巨兽Boss。熟悉Boss模式是生存的关键。',
      'tips': '属性武器非常有效\n侦察兵的导热卡宾枪很有用',
    },
  },

  'Industrial Sabotage': {
    'KR': {
      'desc': '라이벌 사의 데이터 보관소를 파괴하는 미션.',
      'tips': '터렛과 봇이 다량 생성됨\n화염 무기가 효과적',
    },
    'EN': {
      'desc': 'Destroy the rival company\'s data vault.',
      'tips': 'Turrets and bots spawn in large numbers\nFire weapons are effective',
    },
    'CN': {
      'desc': '摧毁竞争公司数据保管库的任务。',
      'tips': '大量炮塔和机器人生成\n火焰武器很有效',
    },
  },

  'Deep Scan': {
    'KR': {
      'desc': '지하 깊은 곳의 지질 데이터를 스캔하는 미션. Season 5에서 추가.',
      'tips': '공명 크리스탈은 보랏빛으로 지면에 묻힘\n채굴 시 스캐너가 드랍됨\n드릴러베이터로 정공까지 내려감',
    },
    'EN': {
      'desc': 'Scan geological data deep underground. Added in Season 5.',
      'tips': 'Resonance Crystals glow purple and are buried in the ground\nScanners drop when mined\nRide the Drillevator down to the drilling point',
    },
    'CN': {
      'desc': '扫描地下深处的地质数据。第5赛季新增。',
      'tips': '共鸣水晶发紫光，埋在地面下\n开采时扫描仪会掉落\n乘坐钻地电梯下降到钻探点',
    },
  },

  'Heavy Excavation': {
    'KR': {
      'desc': '대형 장비로 대규모 발굴 작업을 수행하는 미션.',
      'tips': '발굴 지역 주변 안전 확보가 우선\n대규모 작전이므로 보급 관리 중요\n팀원 간 역할 분담으로 효율 극대화',
    },
    'EN': {
      'desc': 'Perform large-scale excavation with heavy equipment.',
      'tips': 'Securing the excavation area is the priority\nSupply management is critical for large operations\nMaximize efficiency with clear role assignments',
    },
    'CN': {
      'desc': '使用重型设备进行大规模挖掘作业。',
      'tips': '确保挖掘区域周围安全是首要任务\n大规模作战中补给管理很重要\n通过明确分工最大化效率',
    },
  },

  // ═══════════════════════════════════════════════════════════════════════════
  //  버프/뮤테이터 (7개)
  // ═══════════════════════════════════════════════════════════════════════════

  'Double XP': {
    'KR': {
      'desc': '미션 완료 시 경험치가 2배로 지급됩니다.',
      'tips': '레벨업이 목표라면 최우선 선택\n길고 복잡한 미션일수록 XP 이득이 큼\n프로모션을 위한 레벨업에 활용',
    },
    'EN': {
      'desc': 'Double experience points upon mission completion.',
      'tips': 'Top priority if leveling up is the goal\nLonger and complex missions yield more XP\nGreat for leveling towards promotions',
    },
    'CN': {
      'desc': '任务完成后获得双倍经验值。',
      'tips': '如果目标是升级，这是首选\n较长和复杂的任务获得更多经验\n适合为晋升而升级',
    },
  },

  'Gold Rush': {
    'KR': {
      'desc': '금 광맥이 대량 생성되어 크레딧 수입이 크게 증가.',
      'tips': '금을 최대한 많이 채굴하여 크레딧 확보\n스카웃이 높은 곳의 금맥 조명 필수\n맥주, 장비 업그레이드 자금 마련에 최적',
    },
    'EN': {
      'desc': 'Gold veins spawn in abundance, greatly increasing credit income.',
      'tips': 'Mine as much gold as possible for credits\nScout must illuminate high gold veins\nPerfect for funding beer and equipment upgrades',
    },
    'CN': {
      'desc': '大量金矿脉生成，大幅增加信用收入。',
      'tips': '尽可能多开采金矿以获得信用\n侦察兵必须照亮高处的金矿脉\n适合为啤酒和装备升级筹集资金',
    },
  },

  'Mineral Mania': {
    'KR': {
      'desc': '광물 생성량이 대폭 증가. 모든 자원을 풍부하게 획득 가능.',
      'tips': '모든 종류의 광물이 더 많이 생성\n자원 부족한 항목 집중 채굴 추천\n채굴 원정과 조합하면 효율 극대화',
    },
    'EN': {
      'desc': 'Mineral generation greatly increased. All resources available abundantly.',
      'tips': 'All mineral types spawn more frequently\nFocus on mining scarce resources\nCombine with Mining Expedition for max efficiency',
    },
    'CN': {
      'desc': '矿物生成量大幅增加。所有资源丰富可获取。',
      'tips': '所有矿物类型生成更频繁\n重点开采稀缺资源\n与采矿远征结合效率最大化',
    },
  },

  'Low Gravity': {
    'KR': {
      'desc': '중력이 약해져 점프가 높아지고 낙하 데미지가 감소.',
      'tips': '높이 점프 가능하지만 체공 시간도 길어짐\n낙하 데미지 크게 감소\n적도 공중에 더 오래 떠 있어 사격하기 쉬움',
    },
    'EN': {
      'desc': 'Reduced gravity increases jump height and decreases fall damage.',
      'tips': 'Jump higher but also float longer in air\nFall damage significantly reduced\nEnemies float longer too - easier to shoot',
    },
    'CN': {
      'desc': '重力降低，跳跃更高，坠落伤害减少。',
      'tips': '跳得更高但滞空时间也更长\n坠落伤害大幅降低\n敌人也会漂浮更久，更容易射击',
    },
  },

  'Rich Atmosphere': {
    'KR': {
      'desc': '산소가 풍부하여 이동 속도와 재생력이 증가.',
      'tips': '전반적으로 이동이 빨라져 미션이 수월\n체력 재생이 약간 빨라짐\n전투와 탐색 모두 유리한 환경',
    },
    'EN': {
      'desc': 'Rich oxygen increases movement speed and regeneration.',
      'tips': 'Overall faster movement makes missions easier\nHealth regeneration slightly improved\nFavorable conditions for both combat and exploration',
    },
    'CN': {
      'desc': '富氧环境增加移动速度和再生能力。',
      'tips': '整体移动速度加快，任务更轻松\n生命再生略有提高\n对战斗和探索都有利的环境',
    },
  },

  'Critical Weakness': {
    'KR': {
      'desc': '적의 약점 부위에 대한 데미지가 대폭 증가.',
      'tips': '약점 사격 정확도가 높으면 큰 이득\n드레드노트 등 보스전에서 특히 유용\n스카웃의 M1000 같은 정밀 무기와 상성 좋음',
    },
    'EN': {
      'desc': 'Greatly increased damage to enemy weak points.',
      'tips': 'High weak point accuracy players benefit most\nEspecially useful in Dreadnought boss fights\nSynergizes well with precision weapons like M1000',
    },
    'CN': {
      'desc': '对敌人弱点的伤害大幅增加。',
      'tips': '弱点射击准确度高的玩家获益最大\n在无畏巨兽Boss战中特别有用\n与M1000等精准武器配合良好',
    },
  },

  'Golden Bugs': {
    'KR': {
      'desc': '적을 처치하면 금을 드롭합니다.',
      'tips': '많이 처치할수록 크레딧 수입 증가\n스웜 웨이브에서 대량의 금 획득 가능\n처치 후 금을 줍는 것을 잊지 말 것',
    },
    'EN': {
      'desc': 'Enemies drop gold when killed.',
      'tips': 'More kills means more credit income\nSwarm waves yield large amounts of gold\nDon\'t forget to pick up gold after kills',
    },
    'CN': {
      'desc': '敌人被击杀时掉落金子。',
      'tips': '击杀越多，信用收入越多\n虫群波次可获得大量金子\n击杀后别忘了捡金子',
    },
  },

  // ═══════════════════════════════════════════════════════════════════════════
  //  경고/디버프 (22개)
  // ═══════════════════════════════════════════════════════════════════════════

  'Volatile Guts': {
    'KR': {
      'desc': '적이 죽을 때 폭발하여 주변에 피해를 줍니다.',
      'tips': '근접 전투 시 특히 주의\n연쇄 폭발로 아군 피해 가능\n원거리에서 처치하는 것이 안전',
    },
    'EN': {
      'desc': 'Enemies explode on death, dealing area damage.',
      'tips': 'Be extra careful in close combat\nChain explosions can damage allies\nSafer to kill from range',
    },
    'CN': {
      'desc': '敌人死亡时爆炸，对周围造成伤害。',
      'tips': '近战时要特别小心\n连锁爆炸可能伤害队友\n从远距离击杀更安全',
    },
  },

  'Shield Disruption': {
    'KR': {
      'desc': '보호막이 완전히 비활성화됩니다. 체력이 곧 생명.',
      'tips': '체력 관리가 최우선\n레드 슈가를 적극적으로 활용\n무리한 전투를 피하고 신중하게 행동',
    },
    'EN': {
      'desc': 'Shields are completely disabled. Health is everything.',
      'tips': 'Health management is top priority\nActively use Red Sugar\nAvoid reckless combat and play carefully',
    },
    'CN': {
      'desc': '护盾完全禁用。生命值就是一切。',
      'tips': '生命值管理是最高优先级\n积极使用红糖\n避免鲁莽战斗，谨慎行动',
    },
  },

  'Mactera Plague': {
    'KR': {
      'desc': '비행형 막테라 적이 대거 출현합니다.',
      'tips': '대공 무기나 냉기 무기가 효과적\n천장을 자주 확인\n밀집 대형으로 화력 집중이 유리',
    },
    'EN': {
      'desc': 'Flying Mactera enemies appear in large numbers.',
      'tips': 'Anti-air or cryo weapons are effective\nCheck ceilings frequently\nGrouped formation with focused fire works well',
    },
    'CN': {
      'desc': '大量飞行摩克特拉敌人出现。',
      'tips': '防空武器或冰冻武器有效\n经常检查天花板\n集中队形集中火力效果好',
    },
  },

  'Cave Leech Cluster': {
    'KR': {
      'desc': '천장에 숨은 케이브 리치가 다수 배치됩니다. 잡히면 공중으로 끌려감.',
      'tips': '항상 천장을 확인하며 이동\n스카웃의 조명탄으로 천장을 밝히기\n동료가 잡히면 즉시 사격으로 구출',
    },
    'EN': {
      'desc': 'Multiple Cave Leeches lurk on ceilings. Getting grabbed pulls you up.',
      'tips': 'Always check ceilings while moving\nUse Scout flares to illuminate ceilings\nImmediately shoot to rescue grabbed teammates',
    },
    'CN': {
      'desc': '多个洞穴水蛭潜伏在天花板上。被抓住会被拉到空中。',
      'tips': '移动时始终检查天花板\n用侦察兵照明弹照亮天花板\n队友被抓时立即射击营救',
    },
  },

  'Parasites': {
    'KR': {
      'desc': '기생충 적이 드워프에게 달려듭니다.',
      'tips': '바닥을 주의하세요',
    },
    'EN': {
      'desc': 'Parasite enemies rush at dwarves.',
      'tips': 'Watch the floor',
    },
    'CN': {
      'desc': '寄生虫敌人会冲向矮人。',
      'tips': '注意地面',
    },
  },

  'Exploder Infestation': {
    'KR': {
      'desc': '자폭형 적 익스플로더가 대량 출현합니다.',
      'tips': '거리를 유지하고 원거리 처치\n밀집된 곳에서는 연쇄 폭발 주의\n소리로 접근을 미리 감지 가능',
    },
    'EN': {
      'desc': 'Self-destructing Exploder enemies appear in large numbers.',
      'tips': 'Maintain distance and kill from range\nWatch for chain explosions in tight spaces\nListen for approaching sounds to detect early',
    },
    'CN': {
      'desc': '大量自爆型爆炸者敌人出现。',
      'tips': '保持距离从远处击杀\n密集区域注意连锁爆炸\n通过声音提前感知接近',
    },
  },

  'Lethal Enemies': {
    'KR': {
      'desc': '모든 적의 공격력이 대폭 증가합니다.',
      'tips': '회피와 거리 유지가 생존의 핵심\n모여다니는 것을 추천',
    },
    'EN': {
      'desc': 'All enemy damage is significantly increased.',
      'tips': 'Dodging and keeping distance is key to survival\nSticking together is recommended',
    },
    'CN': {
      'desc': '所有敌人的攻击力大幅增加。',
      'tips': '闪避和保持距离是生存关键\n建议集体行动',
    },
  },

  'Low Oxygen': {
    'KR': {
      'desc': '산소가 부족한 환경. 몰리 또는 보급 포드 등 시설물 근처에서만 산소를 보충할 수 있습니다.',
      'tips': '몰리 또는 보급 포드 반경을 벗어나지 말 것\n산소 소진 시 지속 피해 발생\n팀이 분산되면 산소 부족 위험 증가',
    },
    'EN': {
      'desc': 'Low oxygen environment. Oxygen is only replenished near Molly or supply pods.',
      'tips': 'Never stray far from Molly or supply pods\nRunning out of oxygen causes continuous damage\nSplitting up increases the risk of oxygen deprivation',
    },
    'CN': {
      'desc': '低氧环境。只能在莫莉或补给舱等设施附近补充氧气。',
      'tips': '不要离开莫莉或补给舱的范围\n氧气耗尽时会持续受到伤害\n团队分散会增加缺氧风险',
    },
  },

  'Haunted Cave': {
    'KR': {
      'desc': '유령 벌크(Ghostly Bulk Detonator)가 출몰합니다. 무적 상태이므로 처치할 수 없습니다.',
      'tips': '처치 불가 — 최대한 빠르게 미션 목표 달성\n목표 완료 후 즉시 추출 개시\n팀 전체가 신속하게 움직이는 것이 핵심',
    },
    'EN': {
      'desc': 'A Ghostly Bulk Detonator appears. It is invincible and cannot be killed.',
      'tips': 'Cannot be killed — complete objectives as fast as possible\nInitiate extraction immediately after objectives are done\nThe key is keeping the entire team moving quickly',
    },
    'CN': {
      'desc': '幽灵爆炸矮人出没。处于无敌状态，无法击杀。',
      'tips': '无法击杀——尽快完成任务目标\n目标完成后立即开始撤离\n全队快速行动是关键',
    },
  },

  'Elite Threat': {
    'KR': {
      'desc': '엘리트 등급의 강화 적이 등장합니다. 체력과 공격력이 크게 증가.',
      'tips': '엘리트 적은 빛나는 외형으로 구분 가능',
    },
    'EN': {
      'desc': 'Elite-grade enhanced enemies appear with greatly increased health and damage.',
      'tips': 'Elite enemies are identifiable by their glowing appearance',
    },
    'CN': {
      'desc': '出现精英级强化敌人，生命值和攻击力大幅增加。',
      'tips': '精英敌人可通过发光外观识别',
    },
  },

  'Swarmageddon': {
    'KR': {
      'desc': '소형 적 스웜이 끊임없이 밀려옵니다.',
      'tips': '범위 공격 무기가 매우 효과적\n탄약 관리가 어려운 편',
    },
    'EN': {
      'desc': 'Endless waves of small swarmer enemies.',
      'tips': 'Area damage weapons are very effective\nAmmo management can be difficult',
    },
    'CN': {
      'desc': '无尽的小型虫群敌人波次。',
      'tips': '范围伤害武器非常有效\n弹药管理比较困难',
    },
  },

  'Rival Presence': {
    'KR': {
      'desc': '라이벌 사의 로봇과 터렛이 맵 곳곳에 배치됩니다.',
      'tips': '발화(화염) 피해가 로봇에 효과적\n게이지 100% 도달 시 폭파\n기계는 노란색 약점 포인트',
    },
    'EN': {
      'desc': 'Rival company robots and turrets deployed throughout the map.',
      'tips': 'Fire/incendiary damage is effective against robots\nWatch out when the gauge reaches 100% — they explode\nMachines have yellow weak points',
    },
    'CN': {
      'desc': '竞争公司的机器人和炮塔部署在地图各处。',
      'tips': '火焰/燃烧伤害对机器人很有效\n注意仪表达到100%时会爆炸\n机器有黄色弱点',
    },
  },

  'Lithophage Outbreak': {
    'KR': {
      'desc': '리쏘파지 감염체가 맵에 퍼져있으며, 감염된 적이 출현합니다.',
      'tips': '정화 포드를 소환하여 제거 가능\n폼을 묻힌 뒤, 청소기로 흡입',
    },
    'EN': {
      'desc': 'Lithophage infection spreads across the map with infected enemies.',
      'tips': 'Summon cleansing pods to remove them\nApply foam first, then vacuum up',
    },
    'CN': {
      'desc': '岩噬感染体蔓延在地图上，出现被感染的敌人。',
      'tips': '召唤净化舱来清除\n先涂泡沫，然后用吸尘器吸取',
    },
  },

  'Regenerative Bugs': {
    'KR': {
      'desc': '적이 체력이 시간에 따라 재생합니다.',
      'tips': '화력 집중으로 빠르게 처치\n여러 적을 동시에 공격하면 비효율\n고화력 무기가 더 유리',
    },
    'EN': {
      'desc': 'Enemies regenerate health over time.',
      'tips': 'Focus fire for quick kills\nAttacking multiple enemies at once is inefficient\nHigh damage weapons are more effective',
    },
    'CN': {
      'desc': '敌人随时间恢复生命值。',
      'tips': '集中火力快速击杀\n同时攻击多个敌人效率低\n高伤害武器更有效',
    },
  },

  'Pit Jaw Colony': {
    'KR': {
      'desc': '땅 속에 숨어있는 핏 죠가 근접시 속박합니다.',
      'tips': '지면의 움직임을 주시\n이동 시 항상 발밑 확인\n의외로 소리가 큰 편이니 주의',
    },
    'EN': {
      'desc': 'Pit Jaws lurk underground. Stepping on them triggers attacks.',
      'tips': 'Watch for ground movement\nAlways check the ground while moving\nThey are surprisingly loud, so stay alert',
    },
    'CN': {
      'desc': '坑口鳄潜伏在地下。踩到会触发攻击。',
      'tips': '注意地面的动静\n移动时始终检查脚下\n它们出乎意料地响，要保持警惕',
    },
  },

  'Duck and Cover': {
    'KR': {
      'desc': '원거리 적 스폰 확률이 크게 증가합니다.',
      'tips': '거너의 실드가 매우 유용\n스카웃 등 정밀화기로 원거리 정리\n냉동 관련 오버클럭이 유용',
    },
    'EN': {
      'desc': 'Ranged enemy spawn probability is greatly increased.',
      'tips': 'Gunner\'s shield is very useful\nUse precision weapons like Scout to clear ranged enemies\nCryo-related overclocks are useful',
    },
    'CN': {
      'desc': '远程敌人生成概率大幅增加。',
      'tips': '枪手的护盾非常有用\n用侦察兵等精准武器清除远程敌人\n冰冻相关超频很有用',
    },
  },

  'Ebonite Outbreak': {
    'KR': {
      'desc': '에보나이트로 강화된 적이 출현합니다.',
      'tips': '강화된 적은 일반 공격에 데미지를 입지 않음\n곡괭이 강화 스프링클러를 활용\n강공격을 효율적으로 사용하기',
    },
    'EN': {
      'desc': 'Ebonite-enhanced enemies appear.',
      'tips': 'Enhanced enemies are immune to normal attacks\nUtilize pickaxe-boosting sprinklers\nUse power attacks efficiently',
    },
    'CN': {
      'desc': '出现乌木强化的敌人。',
      'tips': '强化敌人对普通攻击免疫\n利用强化镐头的喷洒器\n高效使用强力攻击',
    },
  },

  'Scrab Nesting Grounds': {
    'KR': {
      'desc': '스크랩 둥지가 맵 곳곳에 분포합니다.',
      'tips': '근접시 둥지에서 스크랩이 스폰\n무시할 수 있으면 피하는게 좋음',
    },
    'EN': {
      'desc': 'Scrab nests are scattered throughout the map.',
      'tips': 'Scrabs spawn from nests when approaching\nBest to avoid them if possible',
    },
    'CN': {
      'desc': '虫巢散布在地图各处。',
      'tips': '靠近时虫巢会生成虫子\n能忽略的话最好避开',
    },
  },
};
