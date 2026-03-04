import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
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
// ═══════════════════════════════════════════════════════════════════════════

// 터미널 녹색 색상 팔레트 (GameColors에서 참조)
const _termBg = GameColors.termBg;

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

  // 오디오
  final AudioPlayer _audioPlayer = AudioPlayer();
  // 구출 사운드 풀 (동시재생 지원, 3개 라운드 로빈)
  final List<AudioPlayer> _rescuePool = List.generate(3, (_) => AudioPlayer());
  int _rescuePoolIdx = 0;
  static const _sfxSurprise = 'audio/shouts/pitjaw/NEW_Saluting_7.ogg';
  static const _sfxGrabbed = 'audio/shouts/pitjaw/Dwarf_Taken_by_Grabber_06.ogg';
  static const _sfxPop = 'audio/shouts/pitjaw/pop.mp3';
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
  bool _scoutStopped = false;   // Phase 2: 멈춤
  bool _scoutSurprised = false; // Phase 2: 놀란 표정
  bool _scoutCaught = false;    // Phase 3: 물림
  bool _sinking = false;        // Phase 4: 구덩이로 숨어듦
  double _sinkProgress = 0.0;   // Phase 4 진행률
  // 사운드 중복 재생 방지
  bool _playedSurpriseSound = false;
  bool _playedGrabbedSound = false;

  // ── 콤보 애니메이션 ──
  late AnimationController _comboAnimController;
  late Animation<double> _comboScaleAnim;

  // ── 난이도 (스테이지 기반 점근적 공식) ──
  double get _difficultyProgress => 1.0 - (1.0 / (1.0 + 0.25 * (_stage - 1)));

  /// 기본 노출 시간: 2.2s → 0.65s
  double get _baseVisibleTime => 2.2 - 1.55 * _difficultyProgress;

  /// 기본 스폰 간격: 1.3s → 0.30s (서지 시 절반)
  double get _baseSpawnInterval {
    final base = 1.3 - 1.0 * _difficultyProgress;
    return _isSurging ? base * 0.5 : base;
  }

  /// 최대 활성 두더지: 1→1→2→2→3→3→4+
  int get _maxActiveMoles {
    if (_stage <= 2) return 1;
    if (_stage <= 4) return 2;
    if (_stage <= 6) return 3;
    return 4;
  }

  /// 개별 두더지 랜덤 노출 시간 (스테이지↑ → 분산↑)
  double _randomizedVisibleTime() {
    final base = _baseVisibleTime;
    final variance = 0.15 + 0.20 * _difficultyProgress; // 0.15 → 0.35
    final multiplier = (1.0 - variance) + _random.nextDouble() * (2 * variance);
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
    // 놀람 사운드를 멈추기 전(0.20)에 미리 재생 → 끌려갈 때까지 들림
    if (v >= 0.20 && !_playedSurpriseSound) {
      _playedSurpriseSound = true;
      _playSound(_sfxSurprise);
    }
    if (v >= 0.40 && !_scoutSurprised) {
      setState(() => _scoutSurprised = true);
    }

    // Phase 3 (55~73%): 핏죠가 물림 + 스냅
    if (v >= 0.55 && !_scoutCaught) {
      setState(() => _scoutCaught = true);
      if (!_playedGrabbedSound) {
        _playedGrabbedSound = true;
        _playSound(_sfxGrabbed);
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

    if (_gamePhase != GamePhase.playing) return;

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
        // 서지 발생 확률: ~3%/s → ~8%/s
        final surgeChancePerSec = 0.03 + 0.05 * _difficultyProgress;
        if (_random.nextDouble() < surgeChancePerSec * dt) {
          _isSurging = true;
          _surgeCooldown = 2.0 + _random.nextDouble() * 1.5;
        }
      }

      // 활성 구멍 수 세기
      int activeCount = 0;

      // 각 구멍 업데이트
      for (final hole in _holes) {
        // 곡괭이 애니메이션 진행 (dt*2.5 → ~0.4초 소요)
        if (hole.pickaxeProgress > 0 && hole.pickaxeProgress < 1.0) {
          hole.pickaxeProgress =
              (hole.pickaxeProgress + dt * 2.5).clamp(0.0, 1.0);

          // 타격 임팩트 시점 (0.45): 히트 사운드 + 플래시
          if (hole.pickaxeProgress >= 0.45 && !hole.hitSoundPlayed) {
            hole.hitSoundPlayed = true;
            _playSound(_sfxPop);
          }

          // 히트 플래시 진행 (0.45~1.0)
          if (hole.pickaxeProgress >= 0.45) {
            hole.hitFlashProgress =
                ((hole.pickaxeProgress - 0.45) / 0.55).clamp(0.0, 1.0);
          }

          // 곡괭이 완료 (1.0) → 구출 시작
          if (hole.pickaxeProgress >= 1.0 && !hole.isRescued) {
            hole.isRescued = true;
            hole.rescueAnimProgress = 0.0;
            hole.textFloatProgress = 0.0;
            _playRescueEscapeSound();
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

        if (hole.isActive) {
          activeCount++;
          // 팝업 애니메이션
          if (hole.popProgress < 1.0) {
            hole.popProgress = (hole.popProgress + dt * 5.0).clamp(0.0, 1.0);
          }
          // 노출 타이머 감소
          hole.visibleTimer -= dt;
          if (hole.visibleTimer <= 0) {
            // 놓침 → 생명 감소
            hole.reset();
            _combo = 0;
            _lives--;
            _lifeLostFlash = true;
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) setState(() => _lifeLostFlash = false);
            });
            if (_lives <= 0) {
              _lives = 0;
              _triggerGameOver();
              return;
            }
          }
        }
      }

      // 새 스카웃 스폰
      _spawnTimer -= dt;
      if (_spawnTimer <= 0 && activeCount < _maxActiveMoles) {
        // 버스트 확률: 8% → 15% (스테이지에 따라)
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
      if (!_holes[i].isActive && !_holes[i].isRescued) {
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
    hole.totalVisibleTime = _randomizedVisibleTime();
    hole.visibleTimer = hole.totalVisibleTime;
  }

  void _onTapHole(int index) {
    if (_gamePhase != GamePhase.playing) return;

    final hole = _holes[index];
    if (!hole.isActive || hole.isRescued || hole.pickaxeProgress > 0) return;

    // 곡괭이 타격 시작
    hole.pickaxeProgress = 0.01; // 시작 트리거

    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    // 콤보 바운스 애니메이션 트리거
    if (_combo > 1) _comboAnimController.forward(from: 0);

    // 콤보 보너스 점수
    const basePoints = 10;
    final comboMultiplier = 1.0 + (_combo - 1) * 0.2;
    _score += (basePoints * comboMultiplier).round();

    // 스테이지 진행
    _rescueCount++;
    _stageRescueCount++;
    if (_stageRescueCount >= _rescuesPerStage) {
      _stage++;
      _stageRescueCount = 0;
      if (_lives < _maxLives) _lives++; // 스테이지 클리어 보상: +1 생명
      _playSound(_sfxGrappleHooks[_random.nextInt(_sfxGrappleHooks.length)]);
    }
    // 사운드는 곡괭이 임팩트 시점(gameLoop)에서 재생
  }

  void _handleTap() {
    // 인트로 중에는 Skip 버튼만으로 스킵 (전체 탭 스킵 제거)

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
  }

  // ── 오디오 ──

  Future<void> _playSound(String assetPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (_) {}
  }

  /// 탈출 시 사운드: 7콤보마다 그래플링 훅 랜덤, 그 외 pop
  /// 풀 방식으로 동시재생 지원 (최대 3개)
  Future<void> _playRescueEscapeSound() async {
    try {
      // 히트 사운드(ogg) 중단 → pop/훅이 묻히지 않도록
      await _audioPlayer.stop();

      final player = _rescuePool[_rescuePoolIdx % _rescuePool.length];
      _rescuePoolIdx++;

      await player.stop();
      if (_combo > 0 && _combo % 7 == 0) {
        final idx = _random.nextInt(_sfxGrappleHooks.length);
        await player.play(AssetSource(_sfxGrappleHooks[idx]));
      } else {
        await player.play(AssetSource(_sfxPop));
      }
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
    _audioPlayer.dispose();
    for (final p in _rescuePool) {
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
                    return Stack(
                      children: [
                        // CRT 배경
                        Positioned.fill(
                          child: CustomPaint(painter: CrtBackgroundPainter()),
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

                        // 콤보 대형 오버레이 (히트박스 위, 스캔라인 아래)
                        if (_gamePhase == GamePhase.playing && _combo > 1)
                          ComboOverlay(
                            lang: widget.lang,
                            combo: _combo,
                            comboScaleAnim: _comboScaleAnim,
                            comboAnimController: _comboAnimController,
                          ),

                        // CRT 스캔라인 오버레이
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(painter: ScanlinePainter()),
                          ),
                        ),
                      ],
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
