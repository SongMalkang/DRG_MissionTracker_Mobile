import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/game_colors.dart';
import 'mole_data.dart';
import 'painters/background_painters.dart';
import 'painters/hole_painter.dart';
import 'ui/intro_overlay.dart';
import 'ui/game_over_overlay.dart';
import 'ui/game_hud.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DRG 스타일 "PIT JAW RESCUE" 미니게임
//  ─ 터미널 녹색 CRT 모니터 미감 (JetBoots와 동일)
//  ─ 3x3 그리드에서 핏죠에 물린 스카웃이 구멍에서 튀어나옴
//  ─ 탭하면 곡괭이로 핏죠를 때리고, 그래플링 훅으로 스카웃 탈출
//  ─ 생명 4개 + 콤보 + 로컬 리더보드
//  ─ 디코이/골든/멀티탭 몰 + 콤보 감쇠 + 체인 보너스
// ═══════════════════════════════════════════════════════════════════════════

// 터미널 녹색 색상 팔레트 (GameColors에서 참조)
const _termBg = GameColors.termBg;
const _termGreen = GameColors.termGreen;
const _termAmber = GameColors.termAmber;

class WhackAMoleGame extends StatefulWidget {
  final String lang;
  final VoidCallback onBack;

  const WhackAMoleGame({super.key, required this.lang, required this.onBack});

  @override
  State<WhackAMoleGame> createState() => _WhackAMoleGameState();
}

class _WhackAMoleGameState extends State<WhackAMoleGame>
    with TickerProviderStateMixin {
  late AnimationController _gameLoopController;

  // 게임 상태
  GamePhase _gamePhase = GamePhase.intro;
  int _score = 0;
  int _highScore = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _blinkCounter = 0;

  // 생명 & 스테이지
  int _lives = 4;
  static const _maxLives = 4;
  int _stage = 1;
  int _rescueCount = 0;
  int _stageRescueCount = 0;
  static const _rescuesPerStage = 10;
  double _surgeCooldown = 0.0;
  bool _isSurging = false;
  bool _lifeLostFlash = false;
  DateTime _lastFrameTime = DateTime.now();

  // 구멍 그리드
  final List<MoleHole> _holes = List.generate(9, (_) => MoleHole());
  double _spawnTimer = 1.5;
  final Random _random = Random();

  // ── 1-2: 화면 흔들림 ──
  double _shakeOffsetX = 0.0;
  double _shakeOffsetY = 0.0;
  int _shakeFrames = 0;

  // ── 1-3: 사망 프리즈 프레임 ──
  bool _deathFreeze = false;

  // ── 1-4: 점수 바운스 ──
  double _scoreBounceScale = 1.0;
  int _scoreBounceTimer = 0;

  // ── 3-1: 스테이지 텍스트 ──
  String? _stageText;
  int _stageTextTimer = 0;
  bool _stageFlash = false;

  // ── 3-2: 서지 비주얼 ──
  double _surgeVisualIntensity = 0.0;

  // ── 3-3: 히트 파티클 ──
  final List<HitParticle> _particles = [];
  static const _maxParticles = 30;

  // ── 3-4: 앰버 틴트 ──
  double get _amberTint {
    if (_stage < 5) return 0.0;
    return ((_stage - 4) / 6.0).clamp(0.0, 1.0);
  }

  // ── 3-5: 니어미스 ──
  bool _showNearMissText = false;
  int _nearMissTimer = 0;
  double _nearMissIntensity = 0.0;

  // ── 4-4: 콤보 감쇠 타이머 ──
  double _comboDecayAccum = 0.0;
  static const _comboDecayThreshold = 2.5; // 2.5초 무구출 시 감쇠 시작
  static const _comboDecayInterval = 0.8; // 0.8초마다 콤보 -1
  bool _comboDecayWarning = false;

  // ── 4-5: 구출 체인 보너스 ──
  final List<double> _recentRescueTimes = [];
  bool _chainActive = false;
  int _chainTextTimer = 0;
  double _chainFreezeRemaining = 0.0;

  // ── 스냅 스턴 시스템 ──
  double _snapStunRemaining = 0.0; // >0이면 모든 탭 차단
  int _snapCount = 0; // 스냅 누적 (2번째마다 라이프 감소)

  // ── 오디오 ──
  // 인트로/특수 이벤트 전용 (서지, 스테이지 등 — 게임 루프와 겹치지 않음)
  final AudioPlayer _eventPlayer = AudioPlayer();
  // SFX 풀: 히트 pop + 구출 사운드 공용 (3개 라운드로빈)
  final List<AudioPlayer> _sfxPool = List.generate(3, (_) => AudioPlayer());
  int _sfxPoolIdx = 0;

  static const _sfxSurprise = 'audio/shouts/pitjaw/NEW_Saluting_7.ogg';
  static const _sfxGrabbed =
      'audio/shouts/pitjaw/Dwarf_Taken_by_Grabber_06.ogg';
  static const _sfxPop = 'audio/shouts/pitjaw/pop.mp3';
  // 라이프 손실 사운드 (미사용 에셋 활용)
  static const _sfxLifeLost =
      'audio/shouts/pitjaw/Dwarf_Taken_by_Grabber_09.ogg';
  static const _sfxGrappleHooks = [
    'audio/shouts/pitjaw/WeaponsGrapplingHookUse_1.ogg',
    'audio/shouts/pitjaw/WeaponsGrapplingHookUse_2.ogg',
    'audio/shouts/pitjaw/WeaponsGrapplingHookUse_4.ogg',
    'audio/shouts/pitjaw/WeaponsGrapplingHookUse_5.ogg',
    'audio/shouts/pitjaw/WeaponsGrapplingHookUse_7.ogg',
  ];

  // 리더보드
  static const _topScoresKey = 'whack_a_mole_top_scores';
  List<int> _topScores = [];
  bool _canRestart = false;
  int _visibleScoreCount = 0;

  // ── 인트로 애니메이션 (5.5초, 4단계) ──
  late AnimationController _introController;
  late Animation<double> _scoutWalkAnim;
  // 인트로 상태
  bool _scoutStopped = false; // Phase 2: 멈춤
  bool _scoutSurprised = false; // Phase 2: 놀란 표정
  bool _scoutCaught = false; // Phase 3: 물림
  bool _sinking = false; // Phase 4: 구덩이로 숨어듦
  double _sinkProgress = 0.0; // Phase 4 진행률
  // 사운드 중복 재생 방지
  bool _playedSurpriseSound = false;
  bool _playedGrabbedSound = false;

  // ── 콤보 애니메이션 ──
  late AnimationController _comboAnimController;
  late Animation<double> _comboScaleAnim;

  // ── 난이도 (스테이지 기반 점근적 공식) ──
  double get _difficultyProgress =>
      1.0 - (1.0 / (1.0 + 0.25 * (_stage - 1)));

  /// 기본 노출 시간: 2.2s -> 0.65s
  double get _baseVisibleTime => 2.2 - 1.55 * _difficultyProgress;

  /// 기본 스폰 간격: 1.3s -> 0.30s (서지 시 절반)
  double get _baseSpawnInterval {
    final base = 1.3 - 1.0 * _difficultyProgress;
    return _isSurging ? base * 0.5 : base;
  }

  /// 최대 활성 두더지: 1->1->2->2->3->3->4+
  int get _maxActiveMoles {
    if (_stage <= 2) return 1;
    if (_stage <= 4) return 2;
    if (_stage <= 6) return 3;
    return 4;
  }

  /// 개별 두더지 랜덤 노출 시간 (스테이지up -> 분산up)
  double _randomizedVisibleTime() {
    final base = _baseVisibleTime;
    final variance = 0.15 + 0.20 * _difficultyProgress; // 0.15 -> 0.35
    final multiplier =
        (1.0 - variance) + _random.nextDouble() * (2 * variance);
    return (base * multiplier).clamp(0.45, 3.0);
  }

  @override
  void initState() {
    super.initState();
    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);

    // 인트로 애니메이션 컨트롤러 (총 5.5초)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    // 스카웃 걸어오기: 0~36% 구간 (0~2초)
    _scoutWalkAnim = Tween<double>(begin: 1.2, end: 0.52).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.36, curve: Curves.easeInOut),
      ),
    );

    _introController.addListener(_introTick);

    // 콤보 바운스 애니메이션 (400ms elasticOut)
    _comboAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _comboScaleAnim = Tween<double>(begin: 1.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _comboAnimController,
        curve: Curves.elasticOut,
      ),
    );

    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _gamePhase = GamePhase.ready);
      }
    });

    _loadTopScores();
    _introController.forward();
    _gameLoopController.repeat();
  }

  void _introTick() {
    final v = _introController.value;

    // Phase 2 (36~55%): 멈춤 + 놀란 표정 + 사운드
    if (v >= 0.36 && !_scoutStopped) {
      setState(() => _scoutStopped = true);
    }
    if (v >= 0.20 && !_playedSurpriseSound) {
      _playedSurpriseSound = true;
      _playEventSound(_sfxSurprise);
    }
    if (v >= 0.40 && !_scoutSurprised) {
      setState(() => _scoutSurprised = true);
    }

    // Phase 3 (55~73%): 핏죠가 물림 + 스냅
    if (v >= 0.55 && !_scoutCaught) {
      setState(() => _scoutCaught = true);
      if (!_playedGrabbedSound) {
        _playedGrabbedSound = true;
        _playEventSound(_sfxGrabbed);
      }
    }

    // Phase 4 (73~100%): sink
    if (v >= 0.73 && !_sinking) {
      setState(() => _sinking = true);
    }
    if (_sinking) {
      setState(() {
        _sinkProgress = ((v - 0.73) / 0.27).clamp(0.0, 1.0);
      });
    }

    setState(() {}); // 애니메이션 값 반영
  }

  void _skipIntro() {
    _introController.stop();
    setState(() {
      _scoutStopped = true;
      _scoutSurprised = true;
      _scoutCaught = true;
      _sinking = true;
      _sinkProgress = 1.0;
      _gamePhase = GamePhase.ready;
    });
  }

  void _gameLoop() {
    _blinkCounter++;

    // 1-2: 화면 흔들림 갱신 (게임오버 중에도)
    if (_shakeFrames > 0) {
      _shakeFrames--;
      _shakeOffsetX = (_random.nextDouble() - 0.5) * 8;
      _shakeOffsetY = (_random.nextDouble() - 0.5) * 8;
    } else {
      _shakeOffsetX = 0;
      _shakeOffsetY = 0;
    }

    // 3-5: 니어미스 타이머
    if (_nearMissTimer > 0) {
      _nearMissTimer--;
      _nearMissIntensity = _nearMissTimer / 12.0;
      if (_nearMissTimer == 0) _showNearMissText = false;
    }

    // 1-4: 점수 바운스 감소
    if (_scoreBounceTimer > 0) {
      _scoreBounceTimer--;
      _scoreBounceScale = 1.0 + 0.3 * (_scoreBounceTimer / 12.0);
    }

    // 3-1: 스테이지 텍스트 타이머
    if (_stageTextTimer > 0) {
      _stageTextTimer--;
      if (_stageTextTimer == 0) {
        _stageText = null;
        _stageFlash = false;
      }
    }

    // 4-5: 체인 텍스트 타이머
    if (_chainTextTimer > 0) {
      _chainTextTimer--;
      if (_chainTextTimer == 0) _chainActive = false;
    }

    if (_gamePhase != GamePhase.playing) {
      if (_shakeFrames > 0 || _nearMissTimer > 0) setState(() {});
      return;
    }

    // 1-3: 사망 프리즈 (움직임 중단, 렌더링은 유지)
    if (_deathFreeze) return;

    final now = DateTime.now();
    final dt = (now.difference(_lastFrameTime).inMicroseconds / 1000000.0)
        .clamp(0.0, 0.1);
    _lastFrameTime = now;

    setState(() {
      // 서지 쿨다운 처리
      if (_isSurging) {
        _surgeCooldown -= dt;
        if (_surgeCooldown <= 0) {
          _isSurging = false;
          _surgeCooldown = 0;
        }
      } else {
        // 서지 발생 확률: ~3%/s -> ~8%/s
        final surgeChancePerSec = 0.03 + 0.05 * _difficultyProgress;
        if (_random.nextDouble() < surgeChancePerSec * dt) {
          _isSurging = true;
          _surgeCooldown = 2.0 + _random.nextDouble() * 1.5;
          // 2-4: 서지 시작 햅틱만 (사운드는 서지 비주얼로 충분)
          HapticFeedback.mediumImpact();
        }
      }

      // 3-2: 서지 비주얼 펄스
      if (_isSurging) {
        _surgeVisualIntensity =
            0.5 + 0.5 * sin(_blinkCounter * 0.15);
      } else {
        _surgeVisualIntensity = 0.0;
      }

      // 4-4: 콤보 감쇠 타이머
      if (_combo > 0) {
        _comboDecayAccum += dt;
        _comboDecayWarning = _comboDecayAccum >= 2.0;
        if (_comboDecayAccum >= _comboDecayThreshold) {
          _comboDecayAccum -= _comboDecayInterval;
          _combo = max(0, _combo - 1);
          if (_combo == 0) {
            _comboDecayAccum = 0;
            _comboDecayWarning = false;
          }
        }
      }

      // 4-5: 체인 프리즈 (활성 몰 타이머 정지)
      if (_chainFreezeRemaining > 0) {
        _chainFreezeRemaining -= dt;
      }

      // 활성 구멍 수 세기
      int activeCount = 0;

      // 3-3: 파티클 업데이트
      _updateParticles(dt);

      // ── 스냅 스턴 타이머 ──
      if (_snapStunRemaining > 0) {
        _snapStunRemaining -= dt;
        if (_snapStunRemaining < 0) _snapStunRemaining = 0;
      }

      // 각 구멍 업데이트
      for (final hole in _holes) {
        // 곡괭이 애니메이션 진행 (dt*2.5 -> ~0.4초 소요)
        if (hole.pickaxeProgress > 0 && hole.pickaxeProgress < 1.0) {
          hole.pickaxeProgress =
              (hole.pickaxeProgress + dt * 2.5).clamp(0.0, 1.0);

          // 타격 임팩트 시점 (0.45): 플래시 마커만 (사운드는 탭 즉시 재생됨)
          if (hole.pickaxeProgress >= 0.45 && !hole.hitSoundPlayed) {
            hole.hitSoundPlayed = true;
          }

          // 히트 플래시 진행 (0.45~1.0)
          if (hole.pickaxeProgress >= 0.45) {
            hole.hitFlashProgress =
                ((hole.pickaxeProgress - 0.45) / 0.55).clamp(0.0, 1.0);
          }

          // 곡괭이 완료 (1.0) -> 구출 시작 (멀티탭: 마지막 히트만)
          if (hole.pickaxeProgress >= 1.0 && !hole.isRescued) {
            if (hole.hitsTaken >= hole.hitsRequired) {
              hole.isRescued = true;
              hole.rescueAnimProgress = 0.0;
              hole.textFloatProgress = 0.0;
              // 사운드는 _onTapHole에서 이미 처리됨 (pop 즉시 + 콤보 그래플)
            } else {
              // 멀티탭: 다음 탭 대기 — 곡괭이 리셋
              hole.pickaxeProgress = 0.0;
              hole.hitSoundPlayed = false;
              hole.hitFlashProgress = 0.0;
            }
          }
        }

        if (hole.isRescued) {
          // 그래플링 훅 탈출 애니메이션 진행
          hole.rescueAnimProgress += dt * 3.0;
          hole.textFloatProgress += dt * 2.0;
          if (hole.rescueAnimProgress >= 1.0) {
            hole.reset();
          }
          continue;
        }

        // ── 스냅 애니메이션 진행 ──
        if (hole.isSnapping) {
          hole.snapProgress =
              (hole.snapProgress + dt * 3.5).clamp(0.0, 1.0); // ~0.3초
          if (hole.snapProgress >= 1.0) {
            // 스냅 완료 → 스턴 + 데미지 판정
            _snapStunRemaining = 1.0; // 1초 탭 차단
            _snapCount++;
            _combo = 0;
            _comboDecayAccum = 0;
            _comboDecayWarning = false;
            // 데미지 너프: 2번째 스냅마다 라이프 감소
            if (_snapCount % 2 == 0) {
              _lives--;
              _lifeLostFlash = true;
              HapticFeedback.mediumImpact();
              _shakeFrames = 6;
              _playEventSound(_sfxLifeLost);
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) setState(() => _lifeLostFlash = false);
              });
              if (_lives <= 0) {
                _lives = 0;
                _triggerGameOver();
                return;
              }
            } else {
              // 라이프 감소 없는 스냅도 햅틱/셰이크는 줌
              HapticFeedback.lightImpact();
              _shakeFrames = 4;
            }
            hole.reset();
          }
          continue;
        }

        // ── 등장 예고 (warning) 페이즈 ──
        if (hole.isActive && hole.warningTimer > 0) {
          hole.warningTimer -= dt;
          if (hole.warningTimer <= 0) {
            hole.warningTimer = 0; // 예고 종료 → 팝업 시작
          }
          activeCount++;
          continue;
        }

        if (hole.isActive) {
          activeCount++;
          // 팝업 애니메이션
          if (hole.popProgress < 1.0) {
            hole.popProgress =
                (hole.popProgress + dt * 5.0).clamp(0.0, 1.0);
          }
          // 노출 타이머 감소 (체인 프리즈 또는 스냅 스턴 시 정지)
          if (_chainFreezeRemaining <= 0 && _snapStunRemaining <= 0) {
            hole.visibleTimer -= dt;
          }
          if (hole.visibleTimer <= 0) {
            // 타임아웃 — 몰 타입별 처리
            if (hole.moleType == MoleType.decoy ||
                hole.moleType == MoleType.golden) {
              // 디코이/골든: 놓쳐도 페널티 없음 (그냥 사라짐)
              hole.reset();
            } else {
              // 일반: 놓침 → 스냅 애니메이션 시작 (즉시 라이프 감소 X)
              hole.isSnapping = true;
              hole.snapProgress = 0.0;
              hole.visibleTimer = 0;
              // 스냅 시작 사운드
              _playSfx(_sfxPop);
            }
          }
        }
      }

      // 새 스카웃 스폰
      _spawnTimer -= dt;
      if (_spawnTimer <= 0 && activeCount < _maxActiveMoles) {
        // 버스트 확률: 8% -> 15% (스테이지에 따라)
        final burstChance = 0.08 + 0.07 * _difficultyProgress;
        final burstCount = (_random.nextDouble() < burstChance)
            ? min(2 + (_stage >= 7 ? 1 : 0), _maxActiveMoles - activeCount)
            : 1;
        for (int i = 0; i < burstCount; i++) {
          _spawnMole();
        }
        _spawnTimer = _baseSpawnInterval;
      }
    });
  }

  void _spawnMole() {
    final inactiveIndices = <int>[];
    for (int i = 0; i < 9; i++) {
      if (!_holes[i].isActive && !_holes[i].isRescued && !_holes[i].isSnapping) {
        inactiveIndices.add(i);
      }
    }
    if (inactiveIndices.isEmpty) return;

    final idx = inactiveIndices[_random.nextInt(inactiveIndices.length)];
    final hole = _holes[idx];
    hole.isActive = true;
    hole.popProgress = 0.0;
    hole.isRescued = false;
    hole.pickaxeProgress = 0.0;
    hole.hitsTaken = 0;
    hole.isSnapping = false;
    hole.snapProgress = 0.0;

    // ── 등장 예고 (개미지옥 떨림) ──
    // 스테이지가 높을수록 예고 시간 단축
    final warningBase = 0.6 + _random.nextDouble() * 0.3; // 0.6~0.9초
    final warningScale = 1.0 - 0.3 * _difficultyProgress; // 고스테이지 30% 단축
    hole.warningTimer = warningBase * warningScale;
    hole.warningDuration = hole.warningTimer;

    // ── 몰 타입 결정 ──
    final roll = _random.nextDouble();
    if (_stage >= 3 && roll < 0.04) {
      // 4-2: 골든 스카우트 (3~5% 확률)
      hole.moleType = MoleType.golden;
      hole.totalVisibleTime = _randomizedVisibleTime() * 0.5; // 50% 시간
      hole.hitsRequired = 1;
    } else if (_stage >= 3 && roll < 0.04 + 0.12) {
      // 4-1: 디코이/나이트라 몰 (10~15% 확률, 스테이지 3+)
      hole.moleType = MoleType.decoy;
      hole.totalVisibleTime = _randomizedVisibleTime();
      hole.hitsRequired = 1;
      // 나이트라는 예고 없이 즉시 등장
      hole.warningTimer = 0;
      hole.warningDuration = 0;
    } else {
      // 일반 몰
      hole.moleType = MoleType.normal;
      hole.totalVisibleTime = _randomizedVisibleTime();
      // 4-3: 멀티탭 (스테이지 5+, 20~30% 확률)
      if (_stage >= 5 && _random.nextDouble() < 0.25) {
        hole.hitsRequired = 2;
      } else {
        hole.hitsRequired = 1;
      }
    }

    hole.visibleTimer = hole.totalVisibleTime;
  }

  void _onTapHole(int index) {
    if (_gamePhase != GamePhase.playing) return;

    // 스냅 스턴 중 모든 탭 차단
    if (_snapStunRemaining > 0) return;

    final hole = _holes[index];
    if (!hole.isActive || hole.isRescued) return;

    // 예고 중(떨림)에는 탭 불가
    if (hole.warningTimer > 0) return;

    // 스냅 애니메이션 중에는 탭 불가
    if (hole.isSnapping) return;

    // 4-1: 디코이 몰 — 탭하면 라이프 -1, 콤보 리셋
    if (hole.moleType == MoleType.decoy) {
      hole.pickaxeProgress = 0.01;
      hole.hitSoundPlayed = false;
      hole.hitsTaken = 1;
      // 디코이 페널티
      _combo = 0;
      _comboDecayAccum = 0;
      _comboDecayWarning = false;
      _lives--;
      _lifeLostFlash = true;
      // 1-1: 햅틱
      HapticFeedback.mediumImpact();
      // 1-2: 셰이크
      _shakeFrames = 6;
      // 사운드
      _playEventSound(_sfxLifeLost);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _lifeLostFlash = false);
      });
      // 곡괭이 완료 후 사라지도록
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() => hole.reset());
        }
      });
      if (_lives <= 0) {
        _lives = 0;
        _triggerGameOver();
      }
      return;
    }

    // 멀티탭: 이미 곡괭이 진행 중이면 무시 (다음 탭 대기)
    if (hole.pickaxeProgress > 0 && hole.pickaxeProgress < 1.0) return;

    // 곡괭이 타격 시작
    hole.pickaxeProgress = 0.01;
    hole.hitSoundPlayed = false;
    hole.hitsTaken++;

    // 즉시 pop 사운드 (탭과 동시)
    _playSfx(_sfxPop);

    // 1-1: 히트 햅틱
    HapticFeedback.lightImpact();

    // 3-3: 히트 파티클 생성
    _spawnHitParticles(index);

    // 3-5: 니어미스 감지 — 마지막 순간 구출
    final nearMissBonus =
        hole.totalVisibleTime > 0 &&
        (hole.visibleTimer / hole.totalVisibleTime) < 0.2;
    if (nearMissBonus) {
      _nearMissTimer = 12;
      _nearMissIntensity = 1.0;
      _showNearMissText = true;
      HapticFeedback.selectionClick();
    }

    // 멀티탭: 첫 탭은 부분 점수만
    if (hole.hitsTaken < hole.hitsRequired) {
      _score += 5; // 부분 점수
      _scoreBounceTimer = 8;
      _scoreBounceScale = 1.15;
      return;
    }

    // ── 구출 성공 ──
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    // 콤보 바운스 애니메이션 트리거
    if (_combo > 1) _comboAnimController.forward(from: 0);
    // 4-4: 콤보 감쇠 리셋
    _comboDecayAccum = 0;
    _comboDecayWarning = false;

    // 콤보 10 배수 도달 시 그래플링 훅 + 햅틱
    if (_combo > 0 && _combo % 10 == 0) {
      HapticFeedback.selectionClick();
      final idx = min(_combo ~/ 10 - 1, _sfxGrappleHooks.length - 1);
      _playEventSound(_sfxGrappleHooks[idx]);
    }

    // 콤보 보너스 점수
    const basePoints = 10;
    final comboMultiplier = 1.0 + (_combo - 1) * 0.2;
    int points = (basePoints * comboMultiplier).round();

    // 4-2: 골든 스카우트 — 3배 점수 + 라이프 +1
    if (hole.moleType == MoleType.golden) {
      points *= 3;
      if (_lives < _maxLives) _lives++;
    }

    // 3-5: 니어미스 보너스
    if (nearMissBonus) {
      points += 5;
    }

    _score += points;

    // 1-4: 점수 바운스
    _scoreBounceTimer = 12;
    _scoreBounceScale = 1.3;

    // 4-5: 구출 체인 보너스 추적
    final nowMs =
        DateTime.now().millisecondsSinceEpoch / 1000.0;
    _recentRescueTimes.add(nowMs);
    _recentRescueTimes
        .removeWhere((t) => nowMs - t > 1.5);
    if (_recentRescueTimes.length >= 3 && !_chainActive) {
      _chainActive = true;
      _chainTextTimer = 36; // ~600ms
      _chainFreezeRemaining = 1.0; // 1초 타이머 정지
      HapticFeedback.selectionClick();
      _recentRescueTimes.clear();
    }

    // 스테이지 진행
    _rescueCount++;
    _stageRescueCount++;
    if (_stageRescueCount >= _rescuesPerStage) {
      _stage++;
      _stageRescueCount = 0;
      if (_lives < _maxLives) _lives++; // 스테이지 클리어 보상: +1 생명
      // 1-1: 스테이지 전환 햅틱
      HapticFeedback.mediumImpact();

      // 스테이지 전환 사운드
      _playEventSound(
          _sfxGrappleHooks[_random.nextInt(_sfxGrappleHooks.length)]);

      // 3-1: 스테이지 텍스트 + 글리치
      if (_stage >= 10) {
        _stageText = 'SWARM OVERLOAD';
      } else if (_stage >= 5) {
        _stageText = 'SWARM WARNING';
      } else {
        _stageText = 'STAGE $_stage';
      }
      _stageTextTimer = 36; // ~600ms at 60fps
      _stageFlash = true;
    }
    // 사운드는 곡괭이 임팩트 시점(gameLoop)에서 재생
  }

  void _handleTap() {
    if (_gamePhase == GamePhase.ready) {
      // 게임 시작
      setState(() {
        _gamePhase = GamePhase.playing;
        _lastFrameTime = DateTime.now();
        _spawnTimer = 0.5;
      });
      return;
    }

    if (_gamePhase == GamePhase.gameOver) {
      if (!_canRestart) return;
      // 재시작
      setState(() {
        _gamePhase = GamePhase.intro;
        _score = 0;
        _combo = 0;
        _maxCombo = 0;
        _lives = _maxLives;
        _stage = 1;
        _rescueCount = 0;
        _stageRescueCount = 0;
        _surgeCooldown = 0;
        _isSurging = false;
        _lifeLostFlash = false;
        _canRestart = false;
        _visibleScoreCount = 0;
        _spawnTimer = 1.5;
        _shakeOffsetX = 0;
        _shakeOffsetY = 0;
        _shakeFrames = 0;
        _deathFreeze = false;
        _scoreBounceScale = 1.0;
        _scoreBounceTimer = 0;
        _stageText = null;
        _stageTextTimer = 0;
        _stageFlash = false;
        _surgeVisualIntensity = 0.0;
        _particles.clear();
        _nearMissTimer = 0;
        _nearMissIntensity = 0.0;
        _showNearMissText = false;
        _comboDecayAccum = 0;
        _comboDecayWarning = false;
        _recentRescueTimes.clear();
        _chainActive = false;
        _chainTextTimer = 0;
        _chainFreezeRemaining = 0;
        _snapStunRemaining = 0;
        _snapCount = 0;
        _scoutStopped = false;
        _scoutSurprised = false;
        _scoutCaught = false;
        _sinking = false;
        _sinkProgress = 0.0;
        _playedSurpriseSound = false;
        _playedGrabbedSound = false;
        for (final h in _holes) {
          h.reset();
        }
      });
      _introController.reset();
      _introController.forward();
    }
  }

  void _triggerGameOver() {
    // 1-1: 게임오버 햅틱
    HapticFeedback.heavyImpact();
    // 1-2: 화면 흔들림
    _shakeFrames = 10;

    // 1-3: 사망 프리즈 프레임 (120ms 후 실제 게임오버)
    _deathFreeze = true;
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() {
        _deathFreeze = false;
        _gamePhase = GamePhase.gameOver;
        _canRestart = false;
        _visibleScoreCount = 0;

        final isTopScore = _score > 0 &&
            (_topScores.length < 5 ||
                _topScores.isEmpty ||
                _score > _topScores.last);
        if (isTopScore) {
          _saveScore(_score);
        }

        if (_score > _highScore) _highScore = _score;

        _startLeaderboardReveal();
      });
    });
  }

  // ── 3-3: 파티클 시스템 ──

  void _spawnHitParticles(int holeIndex) {
    if (_particles.length >= _maxParticles) return;
    // 대략적 셀 중심 좌표 계산
    final row = holeIndex ~/ 3;
    final col = holeIndex % 3;
    // 상대적 위치 (나중에 build에서 실제 크기로 변환)
    // 일단 정규화된 0~1 좌표 저장
    final cx = (col + 0.5) / 3.0;
    final cy = (row + 0.5) / 3.0;
    for (int i = 0; i < 8 && _particles.length < _maxParticles; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 30.0 + _random.nextDouble() * 60.0;
      _particles.add(HitParticle(
        cx, cy,
        cos(angle) * speed,
        sin(angle) * speed - 20, // 약간 위로
        1.0,
      ));
    }
  }

  void _updateParticles(double dt) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx * dt / 300; // 정규화 좌표 기준
      p.y += p.vy * dt / 300;
      p.vy += 120 * dt / 300; // 중력
      p.life -= dt * 2.5;
      if (p.life <= 0) _particles.removeAt(i);
    }
  }

  // ── 오디오 ──

  /// 이벤트 사운드 (인트로, 라이프 손실, 스테이지 전환, 콤보 마일스톤)
  /// 단일 플레이어 — 동시 1개만, 새 이벤트가 이전 것을 덮어씀
  Future<void> _playEventSound(String assetPath) async {
    try {
      await _eventPlayer.stop();
      await _eventPlayer.play(AssetSource(assetPath));
    } catch (_) {}
  }

  /// SFX 풀 라운드로빈 (pop 등 빈번한 짧은 소리)
  /// 최대 3개 동시재생, 클리핑 방지
  Future<void> _playSfx(String assetPath) async {
    try {
      final player = _sfxPool[_sfxPoolIdx % _sfxPool.length];
      _sfxPoolIdx++;
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (_) {}
  }

  // ── 리더보드 ──

  Future<void> _loadTopScores() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_topScoresKey) ?? '';
    if (str.isNotEmpty) {
      _topScores = str
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s))
          .toList();
    }
    if (_topScores.isNotEmpty && mounted) {
      setState(() => _highScore = _topScores.first);
    }
  }

  Future<void> _saveScore(int score) async {
    _topScores.add(score);
    _topScores.sort((a, b) => b.compareTo(a));
    if (_topScores.length > 5) {
      _topScores = _topScores.sublist(0, 5);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_topScoresKey, _topScores.join(','));
  }

  void _startLeaderboardReveal() {
    final count = _topScores.isEmpty ? 1 : _topScores.length;
    Future.delayed(const Duration(milliseconds: 500), () {
      _revealNextScore(0, count);
    });
  }

  void _revealNextScore(int index, int total) {
    if (!mounted || _gamePhase != GamePhase.gameOver) return;
    setState(() => _visibleScoreCount = index + 1);
    if (index + 1 < total) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _revealNextScore(index + 1, total);
      });
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || _gamePhase != GamePhase.gameOver) return;
        setState(() => _canRestart = true);
      });
    }
  }

  @override
  void dispose() {
    _gameLoopController.dispose();
    _introController.dispose();
    _comboAnimController.dispose();
    _eventPlayer.dispose();
    for (final p in _sfxPool) {
      p.dispose();
    }
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: Container(
        color: _termBg,
        child: Column(
          children: [
            GameHeader(
              lang: widget.lang,
              score: _score,
              highScore: _highScore,
              onBack: widget.onBack,
              scoreBounceScale: _scoreBounceScale,
            ),
            TimerBar(
              stage: _stage,
              lives: _lives,
              maxLives: _maxLives,
              stageRescueCount: _stageRescueCount,
              lifeLostFlash: _lifeLostFlash,
            ),
            Expanded(
              child: GestureDetector(
                onTap: _handleTap,
                behavior: HitTestBehavior.opaque,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 1-2: 화면 흔들림 Transform
                    return Transform.translate(
                      offset: Offset(_shakeOffsetX, _shakeOffsetY),
                      child: Stack(
                        children: [
                          // CRT 배경 (3-4: 앰버 틴트, 3-2: 서지 워시)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CrtBackgroundPainter(
                                amberTint: _amberTint,
                                surgeIntensity: _surgeVisualIntensity,
                              ),
                            ),
                          ),

                          // 게임 그리드 또는 인트로
                          if (_gamePhase == GamePhase.intro)
                            IntroOverlay(
                              constraints: constraints,
                              scoutWalkAnim: _scoutWalkAnim,
                              introValue: _introController.value,
                              blinkCounter: _blinkCounter,
                              scoutStopped: _scoutStopped,
                              scoutSurprised: _scoutSurprised,
                              scoutCaught: _scoutCaught,
                              sinking: _sinking,
                              sinkProgress: _sinkProgress,
                              onSkip: _skipIntro,
                            )
                          else if (_gamePhase == GamePhase.ready)
                            ReadyOverlay(
                              lang: widget.lang,
                              blinkCounter: _blinkCounter,
                            )
                          else if (_gamePhase == GamePhase.playing)
                            _buildGameGrid(constraints)
                          else if (_gamePhase == GamePhase.gameOver)
                            GameOverOverlay(
                              lang: widget.lang,
                              score: _score,
                              stage: _stage,
                              rescueCount: _rescueCount,
                              maxCombo: _maxCombo,
                              lives: _lives,
                              blinkCounter: _blinkCounter,
                              canRestart: _canRestart,
                              topScores: _topScores,
                              visibleScoreCount: _visibleScoreCount,
                            ),

                          // 3-3: 히트 파티클 레이어
                          if (_particles.isNotEmpty &&
                              _gamePhase == GamePhase.playing)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _GameParticlePainter(
                                    particles: _particles,
                                    gridSize: min(
                                        constraints.maxWidth - 32,
                                        constraints.maxHeight - 32),
                                    areaSize: Size(constraints.maxWidth,
                                        constraints.maxHeight),
                                  ),
                                ),
                              ),
                            ),

                          // 콤보 대형 오버레이
                          if (_gamePhase == GamePhase.playing && _combo > 1)
                            ComboOverlay(
                              lang: widget.lang,
                              combo: _combo,
                              comboScaleAnim: _comboScaleAnim,
                              comboAnimController: _comboAnimController,
                              comboDecayWarning: _comboDecayWarning,
                            ),

                          // 3-5: 니어미스 "CLOSE!" 텍스트
                          if (_showNearMissText)
                            Center(
                              child: Text(
                                'CLOSE!',
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 10,
                                  color: _termAmber.withValues(
                                      alpha: _nearMissIntensity),
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color: _termAmber.withValues(alpha: 0.5),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // 4-5: 체인 보너스 텍스트
                          if (_chainActive)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Text(
                                  'RESCUE CHAIN!',
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 9,
                                    color: _termGreen.withValues(
                                        alpha: (_chainTextTimer / 36.0)
                                            .clamp(0.0, 1.0)),
                                    letterSpacing: 1,
                                    shadows: [
                                      Shadow(
                                        color:
                                            _termGreen.withValues(alpha: 0.5),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // 3-1: 스테이지 텍스트 플래시
                          if (_stageText != null)
                            Center(
                              child: Text(
                                _stageText!,
                                style: GoogleFonts.pressStart2p(
                                  fontSize:
                                      _stageText!.length > 10 ? 8 : 14,
                                  color: _termGreen.withValues(
                                      alpha: (_stageTextTimer / 36.0)
                                          .clamp(0.0, 1.0)),
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color:
                                          _termGreen.withValues(alpha: 0.5),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // CRT 스캔라인 오버레이 (3-1: 글리치)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                  painter: ScanlinePainter(
                                stageFlash: _stageFlash,
                              )),
                            ),
                          ),

                          // 3-2: 서지 앰버 테두리 펄스
                          if (_surgeVisualIntensity > 0)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: SurgeBorderPainter(
                                    intensity: _surgeVisualIntensity,
                                    color: _termAmber,
                                  ),
                                ),
                              ),
                            ),

                          // 3-5: 니어미스 테두리 플래시
                          if (_nearMissIntensity > 0)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: SurgeBorderPainter(
                                    intensity: _nearMissIntensity,
                                    color: _termGreen,
                                  ),
                                ),
                              ),
                            ),

                          // 스냅 스턴 오버레이 (빨간 틴트 + "STUNNED!" 텍스트)
                          if (_snapStunRemaining > 0 &&
                              _gamePhase == GamePhase.playing)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  color: Colors.redAccent.withValues(
                                      alpha: 0.08 *
                                          (_snapStunRemaining.clamp(0.0, 1.0))),
                                  child: Center(
                                    child: Text(
                                      'SNAP!',
                                      style: GoogleFonts.pressStart2p(
                                        fontSize: 14,
                                        color: Colors.redAccent.withValues(
                                            alpha: _snapStunRemaining
                                                .clamp(0.0, 1.0)),
                                        letterSpacing: 2,
                                        shadows: [
                                          Shadow(
                                            color: Colors.redAccent
                                                .withValues(alpha: 0.5),
                                            blurRadius: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            BottomStatusBar(
              lang: widget.lang,
              isPlaying: _gamePhase == GamePhase.playing,
              isSurging: _isSurging,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  게임 그리드
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildGameGrid(BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    final gridSize = min(w - 32, h - 32);
    final cellSize = gridSize / 3;

    return Center(
      child: SizedBox(
        width: gridSize,
        height: gridSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 3x3 그리드
            for (int row = 0; row < 3; row++)
              for (int col = 0; col < 3; col++)
                _buildHoleCell(row, col, cellSize),
          ],
        ),
      ),
    );
  }

  Widget _buildHoleCell(int row, int col, double cellSize) {
    final index = row * 3 + col;
    final hole = _holes[index];

    return Positioned(
      left: col * cellSize,
      top: row * cellSize,
      width: cellSize,
      height: cellSize,
      child: GestureDetector(
        onTap: () => _onTapHole(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ClipRect(
            child: CustomPaint(
              painter: HolePainter(
                hole: hole,
                blinkCounter: _blinkCounter,
              ),
              size: Size(cellSize - 8, cellSize - 8),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 게임 레벨 파티클 페인터 (정규화 좌표 -> 실제 픽셀) ──
class _GameParticlePainter extends CustomPainter {
  final List<HitParticle> particles;
  final double gridSize;
  final Size areaSize;

  _GameParticlePainter({
    required this.particles,
    required this.gridSize,
    required this.areaSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final offsetX = (areaSize.width - gridSize) / 2;
    final offsetY = (areaSize.height - gridSize) / 2;

    for (final p in particles) {
      final alpha = p.life.clamp(0.0, 1.0);
      final paint = Paint()
        ..color = GameColors.termAmber.withValues(alpha: alpha * 0.8);
      final px = offsetX + p.x * gridSize;
      final py = offsetY + p.y * gridSize;
      canvas.drawCircle(Offset(px, py), 1.5 + alpha, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
