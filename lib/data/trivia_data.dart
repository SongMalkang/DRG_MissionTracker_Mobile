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
      'tips': 'Bioluminescent plants provide natural lighting\nOpen spaces make navigation relatively easy\nResources often hide behind crystal pillars',
    },
    'CN': {
      'desc': '充满发光植物和蓝色水晶的美丽地下森林。以高天花板和开阔空间为特征。',
      'tips': '天花板上的发光植物提供自然照明\n开阔空间多，移动相对容易\n资源常隐藏在水晶柱后面',
    },
  },

  'Crystalline Caverns': {
    'KR': {
      'desc': '거대한 수정이 벽과 천장에 박혀있는 동굴. 전기 수정이 주기적으로 방전됨.',
      'tips': '전기 수정은 생각보다 강한 데미지를 줌\n수정이 많아 맵 밝기가 좋은 편\n수직 구조가 많아 집라인이 유용',
    },
    'EN': {
      'desc': 'Caves with massive crystals embedded in walls and ceilings. Electric crystals periodically discharge.',
      'tips': 'Stay away from electric crystals during discharge cycles\nCrystals provide good visibility\nVertical layouts make ziplines useful',
    },
    'CN': {
      'desc': '巨大水晶嵌入墙壁和天花板的洞穴。电水晶会周期性放电。',
      'tips': '远离电水晶的放电周期\n水晶多，视野较好\n垂直结构多，滑索很有用',
    },
  },

  'Dense Biozone': {
    'KR': {
      'desc': '거대한 식물과 유기체로 뒤덮인 밀집된 생태지역. 좁은 통로와 독성 식물 주의.',
      'tips': '독성 포자 식물을 미리 제거하면 안전\n좁은 통로가 많아 근접전 주의\n유기체 벽은 곡괭이로 파괴 가능',
    },
    'EN': {
      'desc': 'A dense ecosystem covered in giant plants and organisms. Watch for narrow passages and toxic plants.',
      'tips': 'Clear toxic spore plants early for safety\nNarrow passages require caution in close combat\nOrganic walls can be destroyed with pickaxe',
    },
    'CN': {
      'desc': '被巨大植物和有机体覆盖的密集生态区。注意狭窄通道和有毒植物。',
      'tips': '提前清除有毒孢子植物以确保安全\n狭窄通道多，近战需小心\n有机体墙壁可用镐头破坏',
    },
  },

  'Fungus Bogs': {
    'KR': {
      'desc': '거대 버섯과 독성 가스 웅덩이가 가득한 늪지. 지형이 복잡하고 시야가 나쁨.',
      'tips': '독성 가스 웅덩이에 빠지면 지속 피해\n폭발하는 버섯은 사격으로 미리 터뜨리기\n지형이 복잡해 길을 잃기 쉬움',
    },
    'EN': {
      'desc': 'Swamps full of giant mushrooms and toxic gas pools. Complex terrain with poor visibility.',
      'tips': 'Toxic gas pools deal continuous damage\nShoot explosive mushrooms from distance\nComplex terrain makes it easy to get lost',
    },
    'CN': {
      'desc': '充满巨型蘑菇和有毒气体水池的沼泽。地形复杂，视野不佳。',
      'tips': '有毒气体水池会造成持续伤害\n远距离射击爆炸蘑菇\n地形复杂，容易迷路',
    },
  },

  'Glacial Strata': {
    'KR': {
      'desc': '얼어붙은 지하 동굴. 눈보라와 빙판이 이동을 방해하고, 냉동 적이 출현.',
      'tips': '눈보라 중에는 시야가 크게 감소\n빙판에서 미끄러짐 주의\n냉동 공격은 드릴러의 화염방사기로 대응',
    },
    'EN': {
      'desc': 'Frozen underground caves. Blizzards and ice surfaces hinder movement, and cryo enemies appear.',
      'tips': 'Visibility drops significantly during blizzards\nWatch for slipping on ice surfaces\nCounter cryo attacks with Driller\'s flamethrower',
    },
    'CN': {
      'desc': '冰冻的地下洞穴。暴风雪和冰面阻碍移动，会出现冰冻敌人。',
      'tips': '暴风雪期间视野大幅降低\n注意冰面上的滑倒\n钻工的火焰喷射器可对抗冰冻攻击',
    },
  },

  'Hollow Bough': {
    'KR': {
      'desc': '거대한 나무 뿌리와 가시 덤불로 이루어진 동굴. 가시가 접촉 시 데미지를 줌.',
      'tips': '가시 덤불은 접촉만으로 피해를 줌\n드릴러로 가시를 뚫는 것이 효율적\n수직 이동이 많아 스카우트가 핵심',
    },
    'EN': {
      'desc': 'Caves made of giant tree roots and thorn bushes. Thorns deal damage on contact.',
      'tips': 'Thorn bushes deal damage on contact alone\nDriller is efficient at clearing thorns\nLots of vertical movement makes Scout essential',
    },
    'CN': {
      'desc': '由巨大树根和荆棘丛组成的洞穴。荆棘接触时造成伤害。',
      'tips': '荆棘丛仅接触就会造成伤害\n钻工清除荆棘效率高\n大量垂直移动使侦察兵至关重要',
    },
  },

  'Magma Core': {
    'KR': {
      'desc': '용암과 화염 간헐천이 가득한 고온 환경. 지진과 화산 분출 이벤트 발생.',
      'tips': '화염 간헐천은 주기적으로 분출하니 패턴 파악\n지진 발생 시 천장에서 불덩이 낙하\n용암 웅덩이 근처에서는 항상 주의',
    },
    'EN': {
      'desc': 'High-temperature environment full of lava and fire geysers. Earthquakes and volcanic events occur.',
      'tips': 'Fire geysers erupt periodically - learn the pattern\nEarthquakes cause fireballs to fall from ceiling\nAlways be cautious near lava pools',
    },
    'CN': {
      'desc': '充满岩浆和火焰间歇泉的高温环境。会发生地震和火山事件。',
      'tips': '火焰间歇泉周期性喷发，掌握规律\n地震时天花板会掉落火球\n在岩浆池附近始终保持警惕',
    },
  },

  'Radioactive Exclusion Zone': {
    'KR': {
      'desc': '방사능에 오염된 위험 구역. 발광하는 방사성 광물과 돌연변이 생물이 서식.',
      'tips': '방사능 수정 근처에 오래 머물면 피해 누적\n발광 적은 죽을 때 방사능 폭발\n어둡고 복잡한 지형에 주의',
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
      'tips': '매우 넓은 공간이 많아 원거리 전투에 유리\n수직 절벽이 많아 낙사 주의\n소금 기둥 뒤에 자원이 잘 숨겨져 있음',
    },
    'EN': {
      'desc': 'Massive caves made of salt crystals. Features wide open spaces and high ceilings.',
      'tips': 'Very wide spaces favor ranged combat\nMany vertical cliffs - watch for fall damage\nResources often hide behind salt pillars',
    },
    'CN': {
      'desc': '由盐晶体组成的巨大洞穴。以宽阔空间和高天花板为特征。',
      'tips': '非常宽阔的空间有利于远程战斗\n垂直悬崖多，注意坠落伤害\n资源常隐藏在盐柱后面',
    },
  },

  'Sandblasted Corridors': {
    'KR': {
      'desc': '모래 폭풍이 몰아치는 좁은 회랑. 강풍과 모래로 시야가 제한됨.',
      'tips': '모래 폭풍 중에는 시야가 극도로 제한\n좁은 통로에서 적과 조우하면 위험\n바람 방향을 확인하고 이동 계획 수립',
    },
    'EN': {
      'desc': 'Narrow corridors with raging sandstorms. Wind and sand limit visibility.',
      'tips': 'Visibility is extremely limited during sandstorms\nEncountering enemies in narrow corridors is dangerous\nCheck wind direction for movement planning',
    },
    'CN': {
      'desc': '沙尘暴肆虐的狭窄走廊。风沙限制视野。',
      'tips': '沙尘暴期间视野极度受限\n在狭窄走廊遭遇敌人很危险\n确认风向规划移动路线',
    },
  },

  'Ossuary Depths': {
    'KR': {
      'desc': '뼈와 화석으로 가득한 깊은 동굴. Season 6에서 추가된 새로운 바이옴.',
      'tips': '뼈 구조물은 파괴 가능하며 통로를 만들 수 있음\n독특한 적 배치 패턴에 주의\n수직 구조가 많아 기동성이 중요',
    },
    'EN': {
      'desc': 'Deep caves filled with bones and fossils. New biome added in Season 6.',
      'tips': 'Bone structures are destructible and can create passages\nWatch for unique enemy placement patterns\nVertical layouts make mobility important',
    },
    'CN': {
      'desc': '充满骨骼和化石的深层洞穴。第6赛季新增的生物群落。',
      'tips': '骨骼结构可破坏，可以创造通道\n注意独特的敌人配置模式\n垂直结构多，机动性很重要',
    },
  },

  // ═══════════════════════════════════════════════════════════════════════════
  //  미션 타입 (10개)
  // ═══════════════════════════════════════════════════════════════════════════

  'Mining Expedition': {
    'KR': {
      'desc': '미스릴을 채굴하여 목표량을 달성하는 기본 미션. 가장 직관적인 미션 유형.',
      'tips': '스카우트의 조명탄이 광맥 발견에 핵심\n벽면에 반짝이는 광맥을 놓치지 말 것\n엔지니어의 플랫폼으로 높은 곳의 광맥 접근',
    },
    'EN': {
      'desc': 'Mine Morkite to reach the quota. The most straightforward mission type.',
      'tips': 'Scout\'s flare gun is key for finding veins\nDon\'t miss the glowing veins on walls\nEngineer\'s platforms help reach high veins',
    },
    'CN': {
      'desc': '开采矿石达到目标量的基本任务。最直观的任务类型。',
      'tips': '侦察兵的照明弹是发现矿脉的关键\n不要错过墙上发光的矿脉\n工程师的平台帮助到达高处矿脉',
    },
  },

  'Egg Hunt': {
    'KR': {
      'desc': '글리포드 알을 수집하는 미션. 알을 파낼 때마다 적 웨이브가 발생.',
      'tips': '알을 파기 전에 주변 방어 준비 필수\n한 번에 여러 개를 파면 웨이브가 중첩됨\n알의 위치는 지형 스캐너로 미리 파악',
    },
    'EN': {
      'desc': 'Collect Glyphid eggs. Each egg extraction triggers an enemy wave.',
      'tips': 'Prepare defenses before extracting eggs\nExtracting multiple eggs stacks waves\nLocate eggs early with terrain scanner',
    },
    'CN': {
      'desc': '收集格里芬虫卵。每次提取卵都会触发敌人波次。',
      'tips': '提取卵前准备好防御\n同时提取多个卵会叠加波次\n用地形扫描仪提前定位卵的位置',
    },
  },

  'On-Site Refining': {
    'KR': {
      'desc': '액체 미스릴 파이프라인을 설치하고 정제하는 미션. 파이프 설치가 핵심.',
      'tips': '파이프 경로를 미리 계획하면 시간 절약\n파이프 위에서 미끄러져 이동 가능\n정제 중 방어가 어려우니 팀워크 필수',
    },
    'EN': {
      'desc': 'Install liquid Morkite pipelines and refine. Pipeline routing is key.',
      'tips': 'Planning pipe routes in advance saves time\nYou can grind-ride on top of pipes\nDefense during refining is tough - teamwork essential',
    },
    'CN': {
      'desc': '安装液态矿石管道并进行精炼。管道布局是关键。',
      'tips': '提前规划管道路线节省时间\n可以在管道上滑行移动\n精炼期间防御困难，团队合作必不可少',
    },
  },

  'Point Extraction': {
    'KR': {
      'desc': '중앙 채굴 플랫폼에서 Aquarq를 수집하는 미션. 시간이 지날수록 적이 강해짐.',
      'tips': '시간이 지날수록 적이 강해지니 속도가 중요\nAquarq는 벽에서 빛나는 푸른 돌\n중앙 플랫폼 주변 방어 진지 구축 권장',
    },
    'EN': {
      'desc': 'Collect Aquarqs from the central mining platform. Enemies scale with time.',
      'tips': 'Enemies get stronger over time - speed matters\nAquarqs are blue glowing stones in walls\nBuild defenses around the central platform',
    },
    'CN': {
      'desc': '在中央开采平台收集水晶矿。敌人强度随时间增加。',
      'tips': '敌人会随时间变强，速度很重要\n水晶矿是墙上发光的蓝色石头\n建议在中央平台周围建立防御阵地',
    },
  },

  'Salvage Operation': {
    'KR': {
      'desc': '추락한 미니뮬을 수리하고 업링크 방어 미션. 고정 위치 방어가 핵심.',
      'tips': '업링크 구역은 미리 평탄화하면 방어 유리\n엔지니어의 터렛과 건너의 방어벽이 핵심\n미니뮬 수리 전에 탈출 경로 확보',
    },
    'EN': {
      'desc': 'Repair crashed Mini-MULEs and defend uplink. Fixed position defense is key.',
      'tips': 'Flatten the uplink area beforehand for easier defense\nEngineer turrets and Gunner shields are essential\nSecure escape routes before repairing Mini-MULEs',
    },
    'CN': {
      'desc': '修复坠毁的迷你骡并防守上行链路。固定位置防御是关键。',
      'tips': '提前整平上行链路区域便于防守\n工程师炮塔和枪手护盾至关重要\n修复迷你骡前确保撤退路线',
    },
  },

  'Escort Duty': {
    'KR': {
      'desc': '도저를 호위하며 하트스톤을 채굴하는 미션. 긴 시간과 높은 난이도가 특징.',
      'tips': '도저 주변의 바위를 미리 제거하면 이동 원활\n연료 보급 정거장에서 보급과 방어 준비\n최종 보스전은 팀원 역할 분담이 중요',
    },
    'EN': {
      'desc': 'Escort the Drilldozer to mine the Heartstone. Long duration and high difficulty.',
      'tips': 'Clear rocks around the Dozer for smooth movement\nUse fuel stops to resupply and prepare defenses\nFinal boss fight requires clear role assignment',
    },
    'CN': {
      'desc': '护送钻地机开采心脏石。持续时间长，难度高。',
      'tips': '提前清除钻地机周围的岩石以便顺利移动\n在燃料补给站补给并准备防御\n最终Boss战需要明确的角色分工',
    },
  },

  'Elimination': {
    'KR': {
      'desc': '드레드노트 보스를 처치하는 미션. 보스 패턴 숙지가 생존의 핵심.',
      'tips': '드레드노트의 약점 부위(빛나는 부분)를 집중 공격\n보스 소환 전 평탄한 전투 공간 확보\n보스 체력이 낮아질수록 공격 패턴이 변화',
    },
    'EN': {
      'desc': 'Eliminate Dreadnought bosses. Knowing boss patterns is key to survival.',
      'tips': 'Focus fire on weak points (glowing spots)\nSecure flat combat space before summoning boss\nBoss attack patterns change at lower health',
    },
    'CN': {
      'desc': '消灭无畏巨兽Boss。熟悉Boss模式是生存的关键。',
      'tips': '集中攻击弱点（发光部位）\n召唤Boss前确保平坦的战斗空间\nBoss血量降低时攻击模式会变化',
    },
  },

  'Industrial Sabotage': {
    'KR': {
      'desc': '라이벌 사의 데이터 보관소를 파괴하는 미션. 해킹과 보스전이 포함.',
      'tips': '패트롯 봇 해킹 시 주변 터렛을 먼저 처리\n전원 노드는 팀원이 분산해서 동시 파괴\n최종 보스 캐벗의 코어가 열릴 때만 공격 가능',
    },
    'EN': {
      'desc': 'Destroy the rival company\'s data vault. Includes hacking and boss fight.',
      'tips': 'Clear turrets before hacking Patrol Bots\nSplit team to destroy power nodes simultaneously\nFinal boss Caretaker is only vulnerable when core opens',
    },
    'CN': {
      'desc': '摧毁竞争公司的数据保管库。包含黑客入侵和Boss战。',
      'tips': '黑客入侵巡逻机器人前先清除炮塔\n分散队友同时摧毁电源节点\n最终Boss管理者只有核心打开时才能攻击',
    },
  },

  'Deep Scan': {
    'KR': {
      'desc': '지하 깊은 곳의 지질 데이터를 스캔하는 미션. Season 5에서 추가.',
      'tips': '스캐너 위치를 먼저 파악하고 이동 경로 계획\n스캔 중 방어가 필요하니 엔지니어 터렛 배치\n깊은 곳으로 내려갈수록 적이 강해짐',
    },
    'EN': {
      'desc': 'Scan geological data deep underground. Added in Season 5.',
      'tips': 'Locate scanners first and plan movement routes\nDeploy Engineer turrets for defense during scans\nEnemies get stronger the deeper you go',
    },
    'CN': {
      'desc': '扫描地下深处的地质数据。第5赛季新增。',
      'tips': '先定位扫描仪并规划移动路线\n扫描期间部署工程师炮塔防御\n越深处敌人越强',
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
      'tips': '금을 최대한 많이 채굴하여 크레딧 확보\n스카우트가 높은 곳의 금맥 조명 필수\n맥주, 장비 업그레이드 자금 마련에 최적',
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
      'tips': '약점 사격 정확도가 높으면 큰 이득\n드레드노트 등 보스전에서 특히 유용\n스카우트의 M1000 같은 정밀 무기와 상성 좋음',
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
      'tips': '대공 무기나 산탄총이 효과적\n천장을 자주 확인\n밀집 대형으로 화력 집중이 유리',
    },
    'EN': {
      'desc': 'Flying Mactera enemies appear in large numbers.',
      'tips': 'Anti-air weapons and shotguns are effective\nCheck ceilings frequently\nGrouped formation with focused fire works well',
    },
    'CN': {
      'desc': '大量飞行摩克特拉敌人出现。',
      'tips': '防空武器和霰弹枪有效\n经常检查天花板\n集中队形集中火力效果好',
    },
  },

  'Cave Leech Cluster': {
    'KR': {
      'desc': '천장에 숨은 케이브 리치가 다수 배치됩니다. 잡히면 공중으로 끌려감.',
      'tips': '항상 천장을 확인하며 이동\n스카우트의 조명탄으로 천장을 밝히기\n동료가 잡히면 즉시 사격으로 구출',
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
      'desc': '적을 처치하면 기생충 소형 적이 추가 생성됩니다.',
      'tips': '처치 후에도 방심하지 말 것\n소형 적은 근접 공격이 효율적\n군중 제어 무기가 유용',
    },
    'EN': {
      'desc': 'Killing enemies spawns small parasite enemies.',
      'tips': 'Stay alert even after kills\nMelee attacks are efficient against small enemies\nCrowd control weapons are useful',
    },
    'CN': {
      'desc': '击杀敌人后会生成小型寄生虫敌人。',
      'tips': '击杀后也不要放松警惕\n近战攻击对小型敌人效率高\n群体控制武器很有用',
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
      'tips': '회피와 거리 유지가 생존의 핵심\n힐링 자원을 아껴서 사용\n팀원 간 커버와 지원이 중요',
    },
    'EN': {
      'desc': 'All enemy damage is significantly increased.',
      'tips': 'Dodging and keeping distance is key to survival\nConserve healing resources\nTeam cover and support is essential',
    },
    'CN': {
      'desc': '所有敌人的攻击力大幅增加。',
      'tips': '闪避和保持距离是生存关键\n节约治疗资源\n团队掩护和支援至关重要',
    },
  },

  'Low Oxygen': {
    'KR': {
      'desc': '산소가 부족하여 몰리에서 멀어지면 질식 데미지를 받습니다.',
      'tips': '몰리(보급 팟) 근처에서 행동\n산소 보충 식물을 적극 활용\n팀이 분산되면 위험이 증가',
    },
    'EN': {
      'desc': 'Low oxygen causes suffocation damage when far from Molly.',
      'tips': 'Stay near Molly (supply pod)\nActively use oxygen replenishment plants\nSplitting the team increases danger',
    },
    'CN': {
      'desc': '氧气不足，远离莫莉时会受到窒息伤害。',
      'tips': '在莫莉（补给舱）附近行动\n积极利用氧气补充植物\n团队分散会增加危险',
    },
  },

  'Haunted Cave': {
    'KR': {
      'desc': '무적의 유령 적이 한 명의 드워프를 계속 추적합니다.',
      'tips': '유령은 처치 불가, 무조건 도망\n타겟이 되면 팀에게 알리기\n좁은 공간에 몰리면 매우 위험',
    },
    'EN': {
      'desc': 'An invincible ghost enemy continuously chases one dwarf.',
      'tips': 'Ghost cannot be killed - always run\nAlert team when you\'re the target\nGetting cornered in tight spaces is very dangerous',
    },
    'CN': {
      'desc': '一个无敌的幽灵敌人持续追踪一名矮人。',
      'tips': '幽灵无法击杀，只能逃跑\n成为目标时通知队友\n在狭窄空间被逼到角落非常危险',
    },
  },

  'Elite Threat': {
    'KR': {
      'desc': '엘리트 등급의 강화 적이 등장합니다. 체력과 공격력이 크게 증가.',
      'tips': '엘리트 적은 빛나는 외형으로 구분 가능\n일반 적보다 우선 처치 권장\n처치 시 더 많은 XP 획득',
    },
    'EN': {
      'desc': 'Elite-grade enhanced enemies appear with greatly increased health and damage.',
      'tips': 'Elite enemies are identifiable by their glowing appearance\nPrioritize killing over regular enemies\nGrants more XP when killed',
    },
    'CN': {
      'desc': '出现精英级强化敌人，生命值和攻击力大幅增加。',
      'tips': '精英敌人可通过发光外观识别\n建议优先于普通敌人击杀\n击杀时获得更多经验值',
    },
  },

  'Swarmageddon': {
    'KR': {
      'desc': '소형 적 스웜이 끊임없이 밀려옵니다.',
      'tips': '범위 공격 무기가 매우 효과적\n탄약 관리에 특히 신경 쓸 것\n밀려오는 적에 둘러싸이지 않도록 주의',
    },
    'EN': {
      'desc': 'Endless waves of small swarmer enemies.',
      'tips': 'Area damage weapons are very effective\nPay special attention to ammo management\nDon\'t let yourself get surrounded',
    },
    'CN': {
      'desc': '无尽的小型虫群敌人波次。',
      'tips': '范围伤害武器非常有效\n特别注意弹药管理\n不要让自己被包围',
    },
  },

  'Rival Presence': {
    'KR': {
      'desc': '라이벌 사의 로봇과 터렛이 맵 곳곳에 배치됩니다.',
      'tips': '터렛은 접근 전에 원거리 파괴\n전자 장비 파괴 시 주변 폭발 주의\n통신 라우터를 찾아 파괴하면 효과적',
    },
    'EN': {
      'desc': 'Rival company robots and turrets deployed throughout the map.',
      'tips': 'Destroy turrets from range before approaching\nWatch for explosions when destroying electronics\nFind and destroy comm routers for effectiveness',
    },
    'CN': {
      'desc': '竞争公司的机器人和炮塔部署在地图各处。',
      'tips': '接近前远距离摧毁炮塔\n摧毁电子设备时注意周围爆炸\n找到并摧毁通信路由器效果好',
    },
  },

  'Lithophage Outbreak': {
    'KR': {
      'desc': '리쏘페이지 감염체가 맵에 퍼져있으며, 감염된 적이 출현합니다.',
      'tips': '감염체 덩어리를 파괴하면 확산 억제\n감염된 적은 처치 시 추가 폭발\n깨끗한 구역을 확보하며 전진',
    },
    'EN': {
      'desc': 'Lithophage infection spreads across the map with infected enemies.',
      'tips': 'Destroy infection clusters to contain spread\nInfected enemies explode additionally on death\nSecure clean areas while advancing',
    },
    'CN': {
      'desc': '岩噬感染体蔓延在地图上，出现被感染的敌人。',
      'tips': '摧毁感染体集群以遏制蔓延\n被感染的敌人死亡时会额外爆炸\n确保清洁区域后再前进',
    },
  },

  'Regenerative Bugs': {
    'KR': {
      'desc': '적이 체력을 시간에 따라 재생합니다.',
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
      'desc': '땅 속에 숨어있는 갱구 악어가 서식합니다. 밟으면 공격받음.',
      'tips': '지면의 움직임을 주시\n이동 시 항상 발밑 확인\n조명으로 미리 위치 파악 가능',
    },
    'EN': {
      'desc': 'Pit Jaws lurk underground. Stepping on them triggers attacks.',
      'tips': 'Watch for ground movement\nAlways check the ground while moving\nLighting can help spot them in advance',
    },
    'CN': {
      'desc': '坑口鳄潜伏在地下。踩到会触发攻击。',
      'tips': '注意地面的动静\n移动时始终检查脚下\n照明可以帮助提前发现',
    },
  },

  'Duck and Cover': {
    'KR': {
      'desc': '주기적으로 폭격이 쏟아집니다. 엄폐가 필수!',
      'tips': '폭격 경고음이 들리면 즉시 엄폐\n지붕이 있는 곳이 안전\n개방된 공간에서 전투를 피할 것',
    },
    'EN': {
      'desc': 'Periodic bombardment rains down. Cover is essential!',
      'tips': 'Take cover immediately when warning sounds\nAreas with ceiling coverage are safe\nAvoid combat in open areas',
    },
    'CN': {
      'desc': '周期性轰炸倾泻而下。掩护是必须的！',
      'tips': '听到警报声立即寻找掩护\n有顶部遮盖的区域是安全的\n避免在开阔区域战斗',
    },
  },

  'Ebonite Outbreak': {
    'KR': {
      'desc': '에보나이트로 강화된 적이 출현합니다.',
      'tips': '강화된 적은 일반 공격에 저항이 높음\n약점 공격이 더욱 중요\n팀 화력 집중이 필수',
    },
    'EN': {
      'desc': 'Ebonite-enhanced enemies appear.',
      'tips': 'Enhanced enemies resist normal attacks\nWeak point attacks become even more important\nTeam focus fire is essential',
    },
    'CN': {
      'desc': '出现乌木强化的敌人。',
      'tips': '强化敌人对普通攻击有抗性\n弱点攻击变得更加重要\n团队集中火力是必须的',
    },
  },

  'Scrab Nesting Grounds': {
    'KR': {
      'desc': '스크랩 둥지가 맵 곳곳에 분포합니다.',
      'tips': '둥지를 파괴하면 적 생성을 억제\n둥지 근처에서는 적이 더 빈번하게 출현\n팀원과 함께 둥지 소탕 권장',
    },
    'EN': {
      'desc': 'Scrab nests are scattered throughout the map.',
      'tips': 'Destroying nests suppresses enemy spawning\nEnemies spawn more frequently near nests\nClear nests as a team for best results',
    },
    'CN': {
      'desc': '虫巢散布在地图各处。',
      'tips': '摧毁虫巢可以抑制敌人生成\n虫巢附近敌人出现更频繁\n建议团队一起清除虫巢',
    },
  },
};
