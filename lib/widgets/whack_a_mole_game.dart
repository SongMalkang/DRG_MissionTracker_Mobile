import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/strings.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DRG 스타일 "PIT JAW RESCUE" 미니게임
//  ─ 터미널 녹색 CRT 모니터 미감 (JetBoots와 동일)
//  ─ 3x3 그리드에서 핏죠에 물린 스카웃이 구멍에서 튀어나옴
//  ─ 탭하면 곡괭이로 핏죠를 때리고, 그래플링 훅으로 스카웃 탈출
//  ─ 60초 타이머 + 콤보 + 로컬 리더보드
// ═══════════════════════════════════════════════════════════════════════════

// 터미널 녹색 색상 팔레트 (JetBoots와 동일)
const _termGreen = Color(0xFF39FF14);
const _termGreenDim = Color(0xFF1A8A0A);
const _termGreenFaint = Color(0xFF0D4D06);
const _termBg = Color(0xFF040A04);
const _termSurface = Color(0xFF081208);
const _termAmber = Color(0xFFFFBF00);

// ── 게임 페이즈 ──
enum _GamePhase { intro, ready, playing, gameOver }

// ── 구멍 데이터 ──
class _MoleHole {
  bool isActive = false;
  double popProgress = 0.0; // 0.0(숨김) ~ 1.0(완전 노출)
  bool isRescued = false;
  double visibleTimer = 0.0;
  double totalVisibleTime = 0.0;
  // 곡괭이 타격 애니메이션
  double pickaxeProgress = 0.0; // 0=없음, >0=진행중(0~1)
  bool hitSoundPlayed = false; // 타격 사운드 재생 여부
  // 타격 히트 플래시 이펙트
  double hitFlashProgress = 0.0; // 0=없음, 0~1=진행중
  // 구출 그래플링 훅 애니메이션
  double rescueAnimProgress = 0.0; // 0~1
  // "RESCUED!" 텍스트 떠오르기
  double textFloatProgress = 0.0;

  void reset() {
    isActive = false;
    popProgress = 0.0;
    isRescued = false;
    visibleTimer = 0.0;
    totalVisibleTime = 0.0;
    pickaxeProgress = 0.0;
    hitSoundPlayed = false;
    hitFlashProgress = 0.0;
    rescueAnimProgress = 0.0;
    textFloatProgress = 0.0;
  }
}

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
  _GamePhase _gamePhase = _GamePhase.intro;
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
  final List<_MoleHole> _holes = List.generate(9, (_) => _MoleHole());
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
        setState(() => _gamePhase = _GamePhase.ready);
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
      _gamePhase = _GamePhase.ready;
    });
  }

  void _gameLoop() {
    _blinkCounter++;

    if (_gamePhase != _GamePhase.playing) return;

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
    if (_gamePhase != _GamePhase.playing) return;

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

    if (_gamePhase == _GamePhase.ready) {
      // 게임 시작
      setState(() {
        _gamePhase = _GamePhase.playing;
        _lastFrameTime = DateTime.now();
        _spawnTimer = 0.5;
      });
      return;
    }

    if (_gamePhase == _GamePhase.gameOver) {
      if (!_canRestart) return;
      // 재시작
      setState(() {
        _gamePhase = _GamePhase.intro;
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
    _gamePhase = _GamePhase.gameOver;
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
    if (!mounted || _gamePhase != _GamePhase.gameOver) return;
    setState(() => _visibleScoreCount = index + 1);
    if (index + 1 < total) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _revealNextScore(index + 1, total);
      });
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || _gamePhase != _GamePhase.gameOver) return;
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
            _buildHeader(),
            _buildTimerBar(),
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
                          child: CustomPaint(painter: _CrtBackgroundPainter()),
                        ),

                        // 게임 그리드 또는 인트로
                        if (_gamePhase == _GamePhase.intro)
                          _buildIntroOverlay(constraints)
                        else if (_gamePhase == _GamePhase.ready)
                          _buildReadyOverlay()
                        else if (_gamePhase == _GamePhase.playing)
                          _buildGameGrid(constraints)
                        else if (_gamePhase == _GamePhase.gameOver)
                          _buildGameOverOverlay(),

                        // 콤보 대형 오버레이 (히트박스 위, 스캔라인 아래)
                        if (_gamePhase == _GamePhase.playing && _combo > 1)
                          _buildComboOverlay(),

                        // CRT 스캔라인 오버레이
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(painter: _ScanlinePainter()),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── 헤더 ──

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 6),
      decoration: BoxDecoration(
        color: _termSurface,
        border: Border(
          bottom: BorderSide(color: _termGreenDim.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: _termGreen, size: 18),
            onPressed: widget.onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const Icon(Icons.warning_amber, color: _termGreen, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PIT JAW RESCUE',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 8,
                    color: _termGreen,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${t('minigame_score', widget.lang)}: $_score',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 7,
                    color: _termGreenDim,
                  ),
                ),
              ],
            ),
          ),
          if (_highScore > 0)
            Text(
              'HI:$_highScore',
              style: GoogleFonts.pressStart2p(
                fontSize: 6,
                color: _termGreenDim,
              ),
            ),
        ],
      ),
    );
  }

  // ── 생명 + 스테이지 바 ──

  Widget _buildTimerBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: _termSurface,
      child: Row(
        children: [
          // 스테이지 표시
          Text(
            'STG $_stage',
            style: GoogleFonts.pressStart2p(
              fontSize: 6,
              color: _termGreenDim,
            ),
          ),
          const SizedBox(width: 8),
          // 하트 (생명)
          for (int i = 0; i < _maxLives; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                i < _lives ? Icons.favorite : Icons.favorite_border,
                size: 14,
                color: _lifeLostFlash && i == _lives
                    ? Colors.redAccent
                    : (i < _lives ? _termGreen : _termGreenDim),
              ),
            ),
          const Spacer(),
          // 스테이지 내 진행률 도트
          for (int i = 0; i < 10; i++)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _stageRescueCount > i ? _termGreen : Colors.transparent,
                border: Border.all(
                  color: _stageRescueCount > i ? _termGreen : _termGreenDim,
                  width: 1,
                ),
                boxShadow: _stageRescueCount > i
                    ? [
                        BoxShadow(
                          color: _termGreen.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  // ── 콤보 대형 오버레이 (상단 표시, 히트박스 미차단) ──

  Widget _buildComboOverlay() {
    return Positioned(
      top: 6,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _comboAnimController,
          builder: (context, child) {
            final scale = _comboScaleAnim.value;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '▸ ${t('minigame_wam_combo', widget.lang)} ◂',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 8,
                    color: _termAmber.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'x$_combo',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 22,
                    color: _termAmber,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: _termAmber.withValues(alpha: 0.5),
                        blurRadius: 16,
                      ),
                      Shadow(
                        color: _termAmber.withValues(alpha: 0.3),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 하단 바 ──

  Widget _buildBottomBar() {
    final showSurge = _gamePhase == _GamePhase.playing && _isSurging;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: _termSurface,
      child: Center(
        child: Text(
          showSurge
              ? t('minigame_wam_swarm', widget.lang)
              : (_gamePhase == _GamePhase.playing
                  ? 'TAP SCOUTS TO RESCUE'
                  : ''),
          style: GoogleFonts.pressStart2p(
            fontSize: 7,
            color: showSurge ? _termAmber : _termGreenDim,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  인트로 애니메이션 (5.5초, 4단계)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildIntroOverlay(BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    // 지면선 위치
    final groundY = h * 0.55;

    // 핏죠 크기 & 위치
    const pitjawW = 80.0;
    const pitjawH = 120.0;
    final pitjawX = w * 0.4;

    // 스카웃 위치
    final scoutX = w * _scoutWalkAnim.value;
    final scoutY = groundY - 50;

    // 걷는 흔들림 (멈추면 중단)
    final wobble = (_scoutStopped || _scoutCaught)
        ? 0.0
        : sin(_introController.value * 40) * 2.0;

    // sink 시 전체 Y 오프셋
    final sinkOffset = _sinking ? _sinkProgress * (h - groundY + 60) : 0.0;

    return Stack(
      children: [
        // 지면선
        Positioned(
          left: 0,
          right: 0,
          top: groundY,
          child: Container(height: 2, color: _termGreenDim),
        ),

        // 핏죠 (지면 위 턱 + 아래 몸체)
        Positioned(
          left: pitjawX - pitjawW / 2,
          top: groundY - 25 + sinkOffset,
          child: SizedBox(
            width: pitjawW,
            height: pitjawH,
            child: CustomPaint(painter: _PitJawPainter()),
          ),
        ),

        // 스카웃 (물리기 전)
        if (!_scoutCaught)
          Positioned(
            left: scoutX - 20,
            top: scoutY + wobble,
            child: SizedBox(
              width: 40,
              height: 50,
              child: CustomPaint(
                painter: _ScoutPainter(
                  surprised: _scoutSurprised,
                  caught: false,
                  blinkCounter: _blinkCounter,
                ),
              ),
            ),
          ),

        // 스카웃 (물린 후 — 핏죠 위에 스냅 + 같이 sink)
        if (_scoutCaught)
          Positioned(
            left: pitjawX - 20,
            top: groundY - 35 + sinkOffset,
            child: SizedBox(
              width: 40,
              height: 50,
              child: CustomPaint(
                painter: _ScoutPainter(
                  surprised: true,
                  caught: true,
                  blinkCounter: _blinkCounter,
                ),
              ),
            ),
          ),

        // 인트로 타이틀
        Positioned(
          left: 0,
          right: 0,
          top: h * 0.08,
          child: Center(
            child: Text(
              'PIT JAW RESCUE',
              style: GoogleFonts.pressStart2p(
                fontSize: 12,
                color: _termGreen,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),

        // Skip 버튼 (우측 상단)
        Positioned(
          right: 12,
          top: 8,
          child: GestureDetector(
            onTap: _skipIntro,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: _termGreenDim, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'SKIP >',
                style: GoogleFonts.pressStart2p(
                  fontSize: 7,
                  color: _termGreenDim,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  레디 오버레이
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildReadyOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PIT JAW RESCUE',
            style: GoogleFonts.pressStart2p(
              fontSize: 12,
              color: _termGreen,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'RESCUE SCOUTS\nDON\'T LET THEM ESCAPE',
            textAlign: TextAlign.center,
            style: GoogleFonts.pressStart2p(
              fontSize: 7,
              color: _termGreenDim,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '4 LIVES',
            style: GoogleFonts.pressStart2p(
              fontSize: 8,
              color: _termGreenDim,
            ),
          ),
          const SizedBox(height: 32),
          if (_blinkCounter % 60 < 40)
            Text(
              t('minigame_tap_to_start', widget.lang),
              style: GoogleFonts.pressStart2p(
                fontSize: 9,
                color: _termGreen,
              ),
            ),
        ],
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

            // 콤보 표시는 부모 Stack에서 오버레이로 표시
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
              painter: _HolePainter(
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

  // ═══════════════════════════════════════════════════════════════════════
  //  게임 오버
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildGameOverOverlay() {
    final isNewRecord =
        _score > 0 && _topScores.isNotEmpty && _score >= _topScores.first;

    final isAllLost = _lives <= 0;

    return Container(
      color: _termBg.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isAllLost
                  ? t('minigame_wam_all_lost', widget.lang)
                  : t('minigame_wam_extraction_complete', widget.lang),
              style: GoogleFonts.pressStart2p(
                fontSize: 10,
                color: isAllLost ? Colors.redAccent : _termGreen,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              '${t('minigame_score', widget.lang)}: $_score',
              style: GoogleFonts.pressStart2p(
                fontSize: 9,
                color: _termGreen,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              'STAGE: $_stage  ${t('minigame_wam_rescued', widget.lang)}: $_rescueCount',
              style: GoogleFonts.pressStart2p(
                fontSize: 6,
                color: _termGreenDim,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              '${t('minigame_wam_max_combo', widget.lang)}: $_maxCombo',
              style: GoogleFonts.pressStart2p(
                fontSize: 7,
                color: _termGreenDim,
              ),
            ),
            const SizedBox(height: 4),

            if (isNewRecord && _blinkCounter % 40 < 25)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'NEW RECORD!',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 8,
                    color: _termAmber,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            ..._buildLeaderboard(),

            const SizedBox(height: 24),

            if (_canRestart && _blinkCounter % 60 < 40)
              Text(
                t('minigame_tap_to_start', widget.lang),
                style: GoogleFonts.pressStart2p(
                  fontSize: 8,
                  color: _termGreen,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLeaderboard() {
    if (_topScores.isEmpty) return [];

    return [
      Text(
        'TOP SCORES',
        style: GoogleFonts.pressStart2p(
          fontSize: 7,
          color: _termGreenDim,
        ),
      ),
      const SizedBox(height: 8),
      for (int i = 0; i < _visibleScoreCount && i < _topScores.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '${i + 1}. ${_topScores[i]}',
            style: GoogleFonts.pressStart2p(
              fontSize: 7,
              color: (i == 0 && _topScores[i] == _score)
                  ? _termAmber
                  : _termGreenDim,
            ),
          ),
        ),
    ];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  CustomPainters
// ═══════════════════════════════════════════════════════════════════════════

// ── CRT 배경 그리드 ──
class _CrtBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _termGreenFaint.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    const spacing = 20.0;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── CRT 스캔라인 오버레이 ──
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.08);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── 핏죠 와이어프레임 페인터 (인트로용) ──
class _PitJawPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final groundY = h * 0.2;

    final jawPaint = Paint()
      ..color = _termGreenDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // V자 이빨
    final jawPath = Path();
    jawPath.moveTo(w * 0.1, groundY);
    jawPath.lineTo(w * 0.25, groundY - 15);
    jawPath.lineTo(w * 0.35, groundY);
    jawPath.lineTo(w * 0.45, groundY - 10);
    jawPath.lineTo(w * 0.5, groundY);
    jawPath.moveTo(w * 0.5, groundY);
    jawPath.lineTo(w * 0.55, groundY - 10);
    jawPath.lineTo(w * 0.65, groundY);
    jawPath.lineTo(w * 0.75, groundY - 15);
    jawPath.lineTo(w * 0.9, groundY);
    canvas.drawPath(jawPath, jawPaint);

    // 역삼각형 몸체
    final bodyPaint = Paint()
      ..color = _termGreenFaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final bodyPath = Path();
    bodyPath.moveTo(w * 0.1, groundY);
    bodyPath.lineTo(w * 0.3, h * 0.5);
    bodyPath.lineTo(w * 0.5, h * 0.9);
    bodyPath.lineTo(w * 0.7, h * 0.5);
    bodyPath.lineTo(w * 0.9, groundY);
    canvas.drawPath(bodyPath, bodyPaint);

    // 내부 디테일
    final detailPaint = Paint()
      ..color = _termGreenFaint.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(w * 0.3, h * 0.35), Offset(w * 0.5, h * 0.7), detailPaint);
    canvas.drawLine(
        Offset(w * 0.7, h * 0.35), Offset(w * 0.5, h * 0.7), detailPaint);

    // "PIT JAW" 라벨
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'PIT JAW',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 8,
          color: _termGreenFaint.withValues(alpha: 0.6),
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
        canvas, Offset((w - textPainter.width) / 2, h * 0.55));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── 스카웃 와이어프레임 페인터 (인트로용) ──
class _ScoutPainter extends CustomPainter {
  final bool surprised;
  final bool caught;
  final int blinkCounter;

  _ScoutPainter({
    this.surprised = false,
    this.caught = false,
    this.blinkCounter = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final color = surprised ? const Color(0xFFFF4444) : _termGreen;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 헬멧
    canvas.drawArc(
      Rect.fromLTWH(w * 0.2, 0, w * 0.6, h * 0.35),
      pi, pi, false, paint,
    );

    // 헤드램프
    final lampPaint = Paint()
      ..color = caught
          ? ((blinkCounter % 20 < 10) ? _termAmber : color)
          : _termGreen
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.08), 3, lampPaint);

    // 몸체
    canvas.drawRect(
      Rect.fromLTWH(w * 0.25, h * 0.35, w * 0.5, h * 0.4), paint);

    // 팔
    if (surprised || caught) {
      canvas.drawLine(
          Offset(w * 0.25, h * 0.4), Offset(w * 0.05, h * 0.15), paint);
      canvas.drawLine(
          Offset(w * 0.75, h * 0.4), Offset(w * 0.95, h * 0.15), paint);
    } else {
      canvas.drawLine(
          Offset(w * 0.25, h * 0.45), Offset(w * 0.1, h * 0.6), paint);
      canvas.drawLine(
          Offset(w * 0.75, h * 0.45), Offset(w * 0.9, h * 0.6), paint);
    }

    // 다리
    canvas.drawLine(
        Offset(w * 0.35, h * 0.75), Offset(w * 0.3, h), paint);
    canvas.drawLine(
        Offset(w * 0.65, h * 0.75), Offset(w * 0.7, h), paint);

    // 라벨
    final label = surprised ? 'SCOUT!' : 'SCOUT';
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 6,
          color: color.withValues(alpha: 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
        canvas, Offset((w - textPainter.width) / 2, h * 0.45));
  }

  @override
  bool shouldRepaint(covariant _ScoutPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
//  게임플레이 구멍 페인터 (핏죠 턱 + 스카웃 합체, 곡괭이, 그래플링훅)
// ═══════════════════════════════════════════════════════════════════════════
class _HolePainter extends CustomPainter {
  final _MoleHole hole;
  final int blinkCounter;

  _HolePainter({required this.hole, required this.blinkCounter});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 셀 전체 클리핑 (절대 밖으로 안 나감)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));

    // 구멍 위치 (하단 35%)
    final holeTop = h * 0.65;
    final holeRect = Rect.fromLTWH(w * 0.1, holeTop, w * 0.8, h * 0.28);

    // 구멍 배경
    final holeBgPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.black, _termBg],
      ).createShader(holeRect);
    canvas.drawOval(holeRect, holeBgPaint);

    // 구멍 테두리
    final holeBorderPaint = Paint()
      ..color = _termGreenDim.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(holeRect, holeBorderPaint);

    // 이빨 (구멍 상단)
    final toothPaint = Paint()
      ..color = _termGreenDim.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int i = 0; i < 4; i++) {
      final tx = w * (0.2 + i * 0.18);
      canvas.drawLine(
        Offset(tx, holeTop + 2),
        Offset(tx + w * 0.04, holeTop - 3),
        toothPaint,
      );
    }

    // 스카웃 + 핏죠 합체 팝업
    if (hole.isActive || hole.isRescued) {
      _drawComboAsset(canvas, w, h, holeTop);
    }

    // 곡괭이 타격 이펙트 (스윙 → 임팩트 → 파티클)
    if (hole.pickaxeProgress > 0 && hole.pickaxeProgress < 1.0) {
      _drawPickaxe(canvas, w, h, holeTop);
    }

    // 히트 이펙트 — 터미널 스타일 텍스트 + 파티클
    if (hole.hitFlashProgress > 0 && hole.hitFlashProgress < 1.0) {
      _drawHitEffect(canvas, w, h, holeTop);
    }

    canvas.restore();
  }

  /// 핏죠 턱 + 스카웃 상반신 합체 에셋
  void _drawComboAsset(Canvas canvas, double w, double h, double holeTop) {
    // 합체 에셋 크기 (셀 안에 맞춤)
    final assetW = w * 0.6;
    final assetH = h * 0.5; // 셀 높이의 50%
    final assetX = (w - assetW) / 2;

    // 팝업 위치 계산
    double assetY;
    double opacity = 1.0;

    if (hole.isRescued) {
      // 그래플링 훅 탈출: 위로 올라감
      final t = hole.rescueAnimProgress.clamp(0.0, 1.0);
      assetY = holeTop - assetH * (1.0 + t * 0.3);
      opacity = 1.0 - t;
    } else {
      // 일반 팝업: 구멍에서 위로
      final pop = hole.popProgress.clamp(0.0, 1.0);
      // pop 0 → 구멍 안 (holeTop), pop 1 → 구멍 위 (holeTop - assetH)
      assetY = holeTop - assetH * pop;
    }

    final color = (hole.isRescued ? _termAmber : _termGreen)
        .withValues(alpha: opacity);
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // ── 스카웃 상반신 (상단 60%) ──
    final scoutTopY = assetY;
    final scoutH = assetH * 0.6;

    // 헬멧 (반원)
    canvas.drawArc(
      Rect.fromLTWH(
          assetX + assetW * 0.2, scoutTopY, assetW * 0.6, scoutH * 0.45),
      pi, pi, false, strokePaint,
    );

    // 헤드램프
    final lampPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(assetX + assetW * 0.5, scoutTopY + scoutH * 0.06),
      2,
      lampPaint,
    );

    // 몸체 (상반신만)
    canvas.drawRect(
      Rect.fromLTWH(assetX + assetW * 0.25, scoutTopY + scoutH * 0.4,
          assetW * 0.5, scoutH * 0.55),
      strokePaint,
    );

    // 팔
    if (hole.isRescued) {
      // 구출: 한 팔 위로 (그래플링 훅) + 다른 팔 아래
      // 오른팔 위로 (그래플링)
      canvas.drawLine(
        Offset(assetX + assetW * 0.75, scoutTopY + scoutH * 0.45),
        Offset(assetX + assetW * 0.85, scoutTopY - scoutH * 0.1),
        strokePaint,
      );
      // 그래플링 훅 와이어 (팔 끝 → 셀 상단)
      final wirePaint = Paint()
        ..color = _termAmber.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(assetX + assetW * 0.85, scoutTopY - scoutH * 0.1),
        Offset(assetX + assetW * 0.85, 0),
        wirePaint,
      );
      // 갈고리 (작은 V)
      canvas.drawLine(
        Offset(assetX + assetW * 0.8, 4),
        Offset(assetX + assetW * 0.85, 0),
        wirePaint,
      );
      canvas.drawLine(
        Offset(assetX + assetW * 0.9, 4),
        Offset(assetX + assetW * 0.85, 0),
        wirePaint,
      );

      // 왼팔 아래
      canvas.drawLine(
        Offset(assetX + assetW * 0.25, scoutTopY + scoutH * 0.45),
        Offset(assetX + assetW * 0.1, scoutTopY + scoutH * 0.7),
        strokePaint,
      );
    } else {
      // SOS 양팔 위로
      canvas.drawLine(
        Offset(assetX + assetW * 0.25, scoutTopY + scoutH * 0.45),
        Offset(assetX, scoutTopY + scoutH * 0.15),
        strokePaint,
      );
      canvas.drawLine(
        Offset(assetX + assetW * 0.75, scoutTopY + scoutH * 0.45),
        Offset(assetX + assetW, scoutTopY + scoutH * 0.15),
        strokePaint,
      );
    }

    // ── 핏죠 턱 (하단 40%) ──
    if (!hole.isRescued) {
      final jawTopY = assetY + assetH * 0.6;
      final jawH = assetH * 0.4;
      final jawPaint = Paint()
        ..color = _termGreenDim.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // V자 이빨 (작은 버전)
      final jawPath = Path();
      jawPath.moveTo(assetX, jawTopY);
      jawPath.lineTo(assetX + assetW * 0.2, jawTopY - jawH * 0.3);
      jawPath.lineTo(assetX + assetW * 0.35, jawTopY);
      jawPath.lineTo(assetX + assetW * 0.5, jawTopY - jawH * 0.2);
      jawPath.lineTo(assetX + assetW * 0.65, jawTopY);
      jawPath.lineTo(assetX + assetW * 0.8, jawTopY - jawH * 0.3);
      jawPath.lineTo(assetX + assetW, jawTopY);
      canvas.drawPath(jawPath, jawPaint);

      // 턱 하단 (스카웃 물고 있는 형태)
      final jawBottomPaint = Paint()
        ..color = _termGreenFaint.withValues(alpha: opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(assetX, jawTopY),
        Offset(assetX + assetW * 0.5, jawTopY + jawH * 0.7),
        jawBottomPaint,
      );
      canvas.drawLine(
        Offset(assetX + assetW, jawTopY),
        Offset(assetX + assetW * 0.5, jawTopY + jawH * 0.7),
        jawBottomPaint,
      );
    }

    // "RESCUED!" 텍스트 떠오르기
    if (hole.isRescued && hole.textFloatProgress < 1.0) {
      final textY = assetY - 5 - hole.textFloatProgress * 15;
      final textOpacity = (1.0 - hole.textFloatProgress).clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: 'RESCUED!',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 6,
            fontWeight: FontWeight.bold,
            color: _termAmber.withValues(alpha: textOpacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((w - tp.width) / 2, textY));
    }

    // 남은 시간 인디케이터
    if (hole.isActive && !hole.isRescued && hole.totalVisibleTime > 0) {
      final barW = w * 0.5;
      final barX = (w - barW) / 2;
      final barY = h - 6;
      final ratio =
          (hole.visibleTimer / hole.totalVisibleTime).clamp(0.0, 1.0);

      canvas.drawRect(
        Rect.fromLTWH(barX, barY, barW, 3),
        Paint()..color = _termGreenFaint.withValues(alpha: 0.3),
      );
      canvas.drawRect(
        Rect.fromLTWH(barX, barY, barW * ratio, 3),
        Paint()
          ..color = ratio < 0.3 ? const Color(0xFFFF4444) : _termGreenDim,
      );
    }
  }

  /// 곡괭이 타격 이펙트 — 크고 명시적인 스윙
  void _drawPickaxe(Canvas canvas, double w, double h, double holeTop) {
    final t = hole.pickaxeProgress.clamp(0.0, 1.0);

    // 곡괭이 위치: 우상단에서 핏죠 턱 위치로 내려침
    final startX = w * 0.85;
    final startY = h * 0.05;
    final endX = w * 0.5;
    final endY = holeTop - h * 0.08;

    // 스윙 단계 (0~0.45: 내려침)
    final strikeT = (t / 0.45).clamp(0.0, 1.0);
    final eased = Curves.easeIn.transform(strikeT);
    final curX = startX + (endX - startX) * eased;
    final curY = startY + (endY - startY) * eased;

    // 곡괭이 회전 (0° → -60° 내려치기)
    final rotation = -1.05 * eased;

    // 스윙 중: 풀 불투명, 임팩트 후: 페이드아웃
    final alpha = t < 0.45 ? 1.0 : (1.0 - ((t - 0.45) / 0.55)).clamp(0.0, 1.0);

    final pickaxePaint = Paint()
      ..color = _termAmber.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final pickaxeFill = Paint()
      ..color = _termAmber.withValues(alpha: alpha * 0.4)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(curX, curY);
    canvas.rotate(rotation);

    // 곡괭이 자루 (두껍고 길게)
    canvas.drawLine(
      const Offset(0, -2),
      const Offset(0, 22),
      pickaxePaint,
    );

    // 곡괭이 머리 — 두꺼운 T자 + 곡선 날
    final headPaint = Paint()
      ..color = _termAmber.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    // 가로 날
    canvas.drawLine(const Offset(-12, 0), const Offset(12, 0), headPaint);
    // 좌측 날 끝 (곡선 효과)
    canvas.drawLine(const Offset(-12, 0), const Offset(-14, 5), headPaint);
    // 우측 날 끝
    canvas.drawLine(const Offset(12, 0), const Offset(14, 5), headPaint);
    // 날 꼭지 (삼각형)
    final tipPath = Path()
      ..moveTo(-14, 5)
      ..lineTo(-12, 8)
      ..lineTo(-10, 5);
    canvas.drawPath(tipPath, pickaxeFill);
    final tipPath2 = Path()
      ..moveTo(14, 5)
      ..lineTo(12, 8)
      ..lineTo(10, 5);
    canvas.drawPath(tipPath2, pickaxeFill);

    canvas.restore();

    // 스윙 궤적 (잔상) — 스윙 진행 중일 때
    if (t < 0.45 && t > 0.1) {
      final trailPaint = Paint()
        ..color = _termAmber.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      // 이전 위치에서 현재까지 궤적
      final prevT = (t - 0.08).clamp(0.0, 1.0);
      final prevEased = Curves.easeIn.transform((prevT / 0.45).clamp(0.0, 1.0));
      final prevX = startX + (endX - startX) * prevEased;
      final prevY = startY + (endY - startY) * prevEased;
      canvas.drawLine(Offset(prevX, prevY), Offset(curX, curY), trailPaint);
    }

    // ── 임팩트 이펙트 (0.45 이후) ──
    if (t >= 0.45) {
      final impactT = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
      final impactAlpha = (1.0 - impactT).clamp(0.0, 1.0);

      // 충격파 원 (확산)
      final ringPaint = Paint()
        ..color = _termAmber.withValues(alpha: impactAlpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      final ringR = 8.0 + impactT * w * 0.25;
      canvas.drawCircle(Offset(endX, endY), ringR, ringPaint);

      // 방사형 충격선 (8방향, 더 길게)
      final sparkPaint = Paint()
        ..color = _termAmber.withValues(alpha: impactAlpha * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final angle = (i * pi / 4) + pi / 8;
        final innerR = 4.0 + impactT * 8.0;
        final outerR = 10.0 + impactT * w * 0.2;
        canvas.drawLine(
          Offset(endX + cos(angle) * innerR, endY + sin(angle) * innerR),
          Offset(endX + cos(angle) * outerR, endY + sin(angle) * outerR),
          sparkPaint,
        );
      }

      // 별 모양 스파크 (십자)
      if (impactT < 0.6) {
        final starAlpha = (1.0 - impactT / 0.6) * 0.8;
        final starPaint = Paint()
          ..color = Colors.white.withValues(alpha: starAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        final starR = 5.0 + impactT * 15.0;
        canvas.drawLine(
          Offset(endX - starR, endY),
          Offset(endX + starR, endY),
          starPaint,
        );
        canvas.drawLine(
          Offset(endX, endY - starR),
          Offset(endX, endY + starR),
          starPaint,
        );
      }
    }
  }

  /// 터미널 스타일 히트 이펙트 — "██ HIT! ██" + 파티클
  void _drawHitEffect(Canvas canvas, double w, double h, double holeTop) {
    final t = hole.hitFlashProgress.clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0);

    // ── "██ HIT! ██" 텍스트 (셀 중앙, 위로 떠오름) ──
    final textY = holeTop * 0.35 - t * 12.0;
    final hitTp = TextPainter(
      text: TextSpan(
        text: '██ HIT! ██',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: _termAmber.withValues(alpha: alpha),
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hitTp.paint(canvas, Offset((w - hitTp.width) / 2, textY));

    // ── 터미널 파티클 (블록 문자들 흩뿌리기) ──
    final chars = ['█', '▓', '▒', '░', '✦', '⚡', '*'];
    final seed = (hole.pickaxeProgress * 1000).toInt();
    final rng = Random(seed);
    for (int i = 0; i < 6; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = 10.0 + t * (25.0 + rng.nextDouble() * 20.0);
      final px = w * 0.5 + cos(angle) * dist;
      final py = holeTop - h * 0.08 + sin(angle) * dist;
      final charAlpha = (alpha * (0.5 + rng.nextDouble() * 0.5)).clamp(0.0, 1.0);
      if (charAlpha < 0.05) continue;

      final tp = TextPainter(
        text: TextSpan(
          text: chars[i % chars.length],
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 6 + rng.nextDouble() * 4,
            color: (i % 2 == 0 ? _termAmber : _termGreen)
                .withValues(alpha: charAlpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px, py));
    }
  }

  @override
  bool shouldRepaint(covariant _HolePainter oldDelegate) => true;
}
