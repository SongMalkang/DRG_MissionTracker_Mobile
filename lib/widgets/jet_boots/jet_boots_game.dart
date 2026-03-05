import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/game_colors.dart';
import '../../utils/strings.dart';
import 'slit_data.dart';
import 'painters/background_painters.dart';
import 'painters/boot_painter.dart';
import 'painters/pillar_painter.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DRG 스타일 "JET BOOT SAFTY PROTOCOL" 미니게임
//  ─ 터미널 녹색 CRT 모니터 미감
//  ─ 좌우 벽에서 뻗어나온 기둥 + 슬릿(틈) 통과
//  ─ 슬릿 통과마다 미터(M) 증가
//  ─ 점진적 난이도 + 사운드 + 로컬 리더보드
// ═══════════════════════════════════════════════════════════════════════════

// 터미널 녹색 색상 팔레트 (GameColors에서 참조)
const _termGreen = GameColors.termGreen;
const _termGreenDim = GameColors.termGreenDim;
const _termBg = GameColors.termBg;
const _termSurface = GameColors.termSurface;

class JetBootsGame extends StatefulWidget {
  final String lang;
  final VoidCallback onBack;

  const JetBootsGame({super.key, required this.lang, required this.onBack});

  @override
  State<JetBootsGame> createState() => _JetBootsGameState();
}

class _JetBootsGameState extends State<JetBootsGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _gameLoopController;

  // 게임 상태
  bool _isStarted = false;
  bool _isGameOver = false;
  double _characterY = 0.5; // 정규화: 0.0 = 상단, 1.0 = 하단
  double _velocity = 0.0;
  DateTime _lastFrameTime = DateTime.now();
  int _meter = 0; // 통과한 슬릿 수 (미터)
  int _highScore = 0;
  double _gameTime = 0.0; // 게임 경과 시간 (진동 슬릿용)

  // 스테이지
  int _stage = 1;
  int _stageStartMeter = 0;
  static const _slitsPerStage = 10;
  bool _stageFlash = false;

  // 장애물: 좌우 벽에서 뻗어나온 기둥 + 슬릿
  final List<Slit> _slits = [];
  final Random _random = Random();
  int _slitCounter = 0; // 교대 갭 패턴용

  // 캐릭터 위치 (화면 비율)
  static const _characterX = 0.2; // 좌측에서 20% 위치

  // 깜박임
  int _blinkCounter = 0;

  // ── 1-2: 화면 흔들림 ──
  double _shakeOffsetX = 0.0;
  double _shakeOffsetY = 0.0;
  int _shakeFrames = 0;

  // ── 1-3: 사망 프리즈 프레임 ──
  bool _deathFreeze = false;

  // ── 1-4: 점수 바운스 ──
  double _scoreBounceScale = 1.0;
  int _scoreBounceTimer = 0;

  // ── 3-4: 스테이지 텍스트 플래시 ──
  String? _stageText;
  int _stageTextTimer = 0;

  // ── 4-1: 추진 파티클 ──
  final List<Particle> _particles = [];
  static const _maxParticles = 20;

  // ── 4-3: 니어미스 ──
  double _nearMissIntensity = 0.0;
  int _nearMissTimer = 0;
  bool _showNearMissText = false;

  // ── 오디오 ──
  final AudioPlayer _audioPlayer = AudioPlayer();
  // 2-1: SFX 풀 (3개 라운드로빈)
  final List<AudioPlayer> _sfxPool = List.generate(3, (_) => AudioPlayer());
  int _sfxPoolIdx = 0;

  static const _sfxStart = 'audio/shouts/jetboots/JetBootsUse_02.ogg';
  static const _sfxMilestone = 'audio/shouts/jetboots/JetBootsUse_16.ogg';
  static const _sfxFail = 'audio/shouts/jetboots/JetBoots_Overheat_2.ogg';
  // 2-2/2-3/2-4: pass/thrust SFX 제거 (pop.mp3는 제트부츠와 안 어울림)
  static const _sfxNearMiss =
      'audio/shouts/pitjaw/WeaponsGrapplingHookUse_1.ogg';

  // ── 리더보드 ──
  static const _topScoresKey = 'jetboots_top_scores';
  List<int> _topScores = [];
  bool _canRestart = false;
  int _visibleScoreCount = 0; // 리더보드 순차 등장 애니메이션

  // ── 난이도 (스테이지 기반 점근적 공식) ──
  double get _difficultyProgress => 1.0 - (1.0 / (1.0 + 0.25 * (_stage - 1)));

  /// 갭 크기: 0.30 → 0.16
  double get _currentGapSize {
    return 0.30 - 0.14 * _difficultyProgress;
  }

  /// 슬릿 간 X축 간격: 0.50 → 0.28
  double get _currentSpacing {
    return 0.50 - 0.22 * _difficultyProgress;
  }

  /// 이동 속도: 0.30/s → 0.48/s
  double get _currentSpeed {
    return 0.30 + 0.18 * _difficultyProgress;
  }

  /// 4-5: 앰버 틴트 (스테이지 5부터 서서히 증가)
  double get _amberTint {
    if (_stage < 5) return 0.0;
    return ((_stage - 4) / 6.0).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);

    _initSlits();
    _loadTopScores();
  }

  void _initSlits() {
    _slits.clear();
    _slitCounter = 0;
    for (int i = 0; i < 3; i++) {
      _slitCounter++;
      _slits.add(_createSlit(0.7 + i * 0.5));
    }
  }

  Slit _createSlit(double x) {
    final slit = Slit(
      x: x,
      gapCenter: 0.2 + _random.nextDouble() * 0.6,
      fromLeft: _random.nextBool(),
    );

    // 3-3: 교대 갭 패턴
    if (_slitCounter % 5 == 0) {
      slit.gapSizeMultiplier = 0.85; // 긴장
    } else if (_slitCounter % 3 == 0) {
      slit.gapSizeMultiplier = 1.3; // 휴식
    }

    // 3-2: 진동 슬릿 (스테이지 3+)
    if (_stage >= 3) {
      final amp = _stage >= 5 ? 0.08 : 0.05;
      slit.oscillateAmplitude = amp;
      slit.oscillateSpeed = 2.0 + _random.nextDouble() * 2.0;
      slit.oscillatePhase = _random.nextDouble() * 6.28;
    }

    return slit;
  }

  void _gameLoop() {
    // 깜박임은 게임오버 중에도 갱신 (오버레이 애니메이션용)
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

    // 4-3: 니어미스 타이머 감소
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

    // 3-4: 스테이지 텍스트 타이머
    if (_stageTextTimer > 0) {
      _stageTextTimer--;
      if (_stageTextTimer == 0) _stageText = null;
    }

    if (!_isStarted || _isGameOver) {
      if (_shakeFrames > 0 || _nearMissTimer > 0) setState(() {});
      return;
    }

    // 1-3: 사망 프리즈 (움직임 중단, 렌더링은 유지)
    if (_deathFreeze) return;

    final now = DateTime.now();
    final dt = (now.difference(_lastFrameTime).inMicroseconds / 1000000.0)
        .clamp(0.0, 0.1);
    _lastFrameTime = now;
    _gameTime += dt;

    setState(() {
      _velocity += 3.24 * dt;
      _characterY = (_characterY + _velocity * dt).clamp(0.0, 1.0);

      // 바닥/천장 충돌
      if (_characterY >= 0.98 || _characterY <= 0.02) {
        _triggerGameOver();
        return;
      }

      final speed = _currentSpeed;

      // 슬릿 이동 (좌측으로 스크롤)
      for (final slit in _slits) {
        slit.x -= speed * dt;

        // 슬릿 통과 판정
        if (!slit.passed && slit.x < _characterX - 0.03) {
          slit.passed = true;
          _meter++;

          // 1-4: 점수 바운스
          _scoreBounceTimer = 12;
          _scoreBounceScale = 1.3;

          // 4-3: 니어미스 판정
          _checkNearMiss(slit);

          _checkMilestone(_meter);
        }

        // 화면 밖으로 나가면 재배치
        if (slit.x < -0.1) {
          _slitCounter++;
          final newSlit = _createSlit(_getNextSlitX());
          slit.x = newSlit.x;
          slit.gapCenter = newSlit.gapCenter;
          slit.fromLeft = newSlit.fromLeft;
          slit.passed = false;
          slit.nearMissTriggered = false;
          slit.oscillateAmplitude = newSlit.oscillateAmplitude;
          slit.oscillateSpeed = newSlit.oscillateSpeed;
          slit.oscillatePhase = newSlit.oscillatePhase;
          slit.gapSizeMultiplier = newSlit.gapSizeMultiplier;
        }
      }

      // 4-1: 추진 파티클 업데이트
      _updateParticles(dt);

      // 충돌 판정
      for (final slit in _slits) {
        if (_checkCollision(slit)) {
          _triggerGameOver();
          return;
        }
      }
    });
  }

  /// 가장 우측 슬릿 기준으로 최소 간격을 보장한 X좌표 반환
  double _getNextSlitX() {
    double maxX = 0.0;
    for (final s in _slits) {
      if (s.x > maxX) maxX = s.x;
    }
    return max(1.1, maxX + _currentSpacing);
  }

  bool _checkCollision(Slit slit) {
    // 캐릭터가 슬릿의 x 범위 안에 있는지
    const charWidth = 0.06;
    final slitLeft = slit.x - 0.03;
    final slitRight = slit.x + 0.03;
    final charLeft = _characterX - charWidth / 2;
    final charRight = _characterX + charWidth / 2;

    if (charRight < slitLeft || charLeft > slitRight) return false;

    // 3-2: 진동 슬릿 — effectiveGapCenter 사용
    final gapSize = _currentGapSize * slit.gapSizeMultiplier;
    final effectiveCenter = slit.effectiveGapCenter(_gameTime);
    final gapTop = effectiveCenter - gapSize / 2;
    final gapBottom = effectiveCenter + gapSize / 2;

    return _characterY < gapTop || _characterY > gapBottom;
  }

  // ── 4-3: 니어미스 판정 ──
  void _checkNearMiss(Slit slit) {
    if (slit.nearMissTriggered) return;

    final gapSize = _currentGapSize * slit.gapSizeMultiplier;
    final effectiveCenter = slit.effectiveGapCenter(_gameTime);
    final gapTop = effectiveCenter - gapSize / 2;
    final gapBottom = effectiveCenter + gapSize / 2;

    final marginThreshold = gapSize * 0.15;
    final distToTop = _characterY - gapTop;
    final distToBottom = gapBottom - _characterY;

    if (distToTop < marginThreshold || distToBottom < marginThreshold) {
      slit.nearMissTriggered = true;
      _nearMissTimer = 12; // ~200ms at 60fps
      _nearMissIntensity = 1.0;
      _showNearMissText = true;
      // 2-4: 니어미스 사운드
      _playSfx(_sfxNearMiss);
      // 1-1: 니어미스 햅틱
      HapticFeedback.selectionClick();
    }
  }

  // ── 4-1: 파티클 시스템 ──
  void _spawnParticles(double screenW, double screenH) {
    if (_particles.length >= _maxParticles) return;
    final px = screenW * _characterX;
    final py = _characterY * (screenH - 36) + 36; // 부츠 하단 근처
    for (int i = 0; i < 2; i++) {
      _particles.add(Particle(
        px + (_random.nextDouble() - 0.5) * 6,
        py,
        (_random.nextDouble() - 0.5) * 20,
        30 + _random.nextDouble() * 40,
        1.0,
      ));
    }
  }

  void _updateParticles(double dt) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt * 2.5;
      if (p.life <= 0) _particles.removeAt(i);
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
        _isGameOver = true;
        _canRestart = false;
        _visibleScoreCount = 0;
        _gameLoopController.stop();
        _playSound(_sfxFail);

        // Top 5 진입 여부 확인 후 저장
        final isTopScore =
            _meter > 0 &&
            (_topScores.length < 5 ||
                _topScores.isEmpty ||
                _meter > _topScores.last);
        if (isTopScore) {
          _saveScore(_meter);
        }

        if (_meter > _highScore) _highScore = _meter;

        _startLeaderboardReveal();
      });
    });
  }

  void _jump() {
    if (_isGameOver) {
      if (!_canRestart) return; // 리더보드 애니메이션 중 탭 무시
      // 재시작
      setState(() {
        _isGameOver = false;
        _isStarted = false;
        _canRestart = false;
        _characterY = 0.5;
        _velocity = 0.0;
        _meter = 0;
        _stage = 1;
        _stageStartMeter = 0;
        _stageFlash = false;
        _gameTime = 0.0;
        _particles.clear();
        _nearMissIntensity = 0.0;
        _nearMissTimer = 0;
        _showNearMissText = false;
        _scoreBounceScale = 1.0;
        _scoreBounceTimer = 0;
        _stageText = null;
        _stageTextTimer = 0;
        _initSlits();
      });
      return;
    }

    if (!_isStarted) {
      setState(() => _isStarted = true);
      _lastFrameTime = DateTime.now();
      _gameLoopController.repeat();
      _playSound(_sfxStart);
      // 1-1: 시작 햅틱
      HapticFeedback.lightImpact();
      return;
    }

    // 1-1: 점프 햅틱
    HapticFeedback.lightImpact();

    // 점프 (완화된 상승력)
    setState(() => _velocity = -0.96);
  }

  // ── 오디오 헬퍼 ──

  Future<void> _playSound(String assetPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (_) {
      // 사운드 재생 실패해도 게임에는 영향 없음
    }
  }

  // 2-1: SFX 풀 라운드로빈
  Future<void> _playSfx(String assetPath) async {
    try {
      final player = _sfxPool[_sfxPoolIdx % _sfxPool.length];
      _sfxPoolIdx++;
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (_) {}
  }

  void _checkMilestone(int meter) {
    final slitsInStage = meter - _stageStartMeter;
    if (slitsInStage >= _slitsPerStage) {
      _stage++;
      _stageStartMeter = meter;
      _playSound(_sfxMilestone);

      // 1-1: 스테이지 전환 햅틱
      HapticFeedback.mediumImpact();

      // 3-4: 스테이지 텍스트 플래시
      if (_stage >= 10) {
        _stageText = 'PROTOCOL OVERLOAD';
      } else if (_stage >= 5) {
        _stageText = 'WARNING: SPEED CRITICAL';
      } else {
        _stageText = 'STAGE $_stage';
      }
      _stageTextTimer = 36; // ~600ms at 60fps

      _stageFlash = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _stageFlash = false);
      });
    }
  }

  // ── 리더보드 저장/로드 ──

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
    _topScores.sort((a, b) => b.compareTo(a)); // 내림차순
    if (_topScores.length > 5) {
      _topScores = _topScores.sublist(0, 5);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_topScoresKey, _topScores.join(','));
  }

  // ── 리더보드 순차 등장 애니메이션 ──

  void _startLeaderboardReveal() {
    final count = _topScores.isEmpty ? 1 : _topScores.length;
    // 0.5초 후 시작, 행당 0.3초
    Future.delayed(const Duration(milliseconds: 500), () {
      _revealNextScore(0, count);
    });
  }

  void _revealNextScore(int index, int total) {
    if (!mounted || !_isGameOver) return;
    setState(() => _visibleScoreCount = index + 1);
    if (index + 1 < total) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _revealNextScore(index + 1, total);
      });
    } else {
      // 마지막 행 표시 후 0.3초 뒤 재시작 가능
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || !_isGameOver) return;
        setState(() => _canRestart = true);
      });
    }
  }

  @override
  void dispose() {
    _gameLoopController.dispose();
    _audioPlayer.dispose();
    for (final p in _sfxPool) {
      p.dispose();
    }
    super.dispose();
  }

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
            // ── 헤더: JET BOOT SAFTY PROTOCOL ────────────────
            _buildHeader(),

            // ── 미터 프로그레스 바 ─────────────────────────────
            _buildMeterBar(),

            // ── 게임 영역 ──────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: _jump,
                behavior: HitTestBehavior.opaque,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;

                    // 4-1: 추진 시 파티클 생성
                    if (_isStarted &&
                        !_isGameOver &&
                        !_deathFreeze &&
                        _velocity < 0) {
                      _spawnParticles(w, h);
                    }

                    // 1-2: 화면 흔들림 Transform
                    return Transform.translate(
                      offset: Offset(_shakeOffsetX, _shakeOffsetY),
                      child: Stack(
                        children: [
                          // 배경: CRT 스캔라인 + 그리드 (4-5: 앰버 틴트)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CrtBackgroundPainter(
                                amberTint: _amberTint,
                              ),
                            ),
                          ),

                          // 좌우 벽 테두리
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child:
                                Container(width: 2, color: _termGreenDim),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child:
                                Container(width: 2, color: _termGreenDim),
                          ),

                          // 바닥 라인
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child:
                                Container(height: 2, color: _termGreenDim),
                          ),

                          // 슬릿 장애물
                          for (final slit in _slits)
                            _buildSlit(slit, w, h),

                          // 4-1: 추진 파티클
                          if (_particles.isNotEmpty)
                            Positioned.fill(
                              child: CustomPaint(
                                painter:
                                    ParticlePainter(particles: _particles),
                              ),
                            ),

                          // 캐릭터 (부츠)
                          Positioned(
                            left: w * _characterX - 14,
                            top: _characterY * (h - 36),
                            child: _buildCharacter(),
                          ),

                          // 4-3: 니어미스 "!!" 텍스트
                          if (_showNearMissText)
                            Positioned(
                              left: w * _characterX + 16,
                              top: _characterY * (h - 36) - 8,
                              child: Text(
                                '!!',
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 10,
                                  color: _termGreen.withValues(
                                      alpha: _nearMissIntensity),
                                ),
                              ),
                            ),

                          // CRT 스캔라인 오버레이 (4-2: 글리치)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: ScanlinePainter(
                                  stageFlash: _stageFlash,
                                ),
                              ),
                            ),
                          ),

                          // 4-3: 니어미스 테두리 플래시
                          if (_nearMissIntensity > 0)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: NearMissBorderPainter(
                                    intensity: _nearMissIntensity,
                                  ),
                                ),
                              ),
                            ),

                          // 3-4: 스테이지 텍스트 플래시
                          if (_stageText != null)
                            Center(
                              child: Text(
                                _stageText!,
                                style: GoogleFonts.pressStart2p(
                                  fontSize: _stageText!.length > 10 ? 8 : 14,
                                  color: _termGreen.withValues(
                                      alpha: (_stageTextTimer / 36.0)
                                          .clamp(0.0, 1.0)),
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color: _termGreen.withValues(alpha: 0.5),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // 시작 오버레이
                          if (!_isStarted && !_isGameOver)
                            _buildStartOverlay(),

                          // 게임 오버 오버레이
                          if (_isGameOver) _buildGameOverOverlay(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── 하단: HACK 버튼 영역 ──────────────────────────
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

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
                  'JET BOOT SAFTY PROTOCOL',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 8,
                    color: _termGreen,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                // 1-4: 점수 바운스 애니메이션
                Transform.scale(
                  scale: _scoreBounceScale,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'STG $_stage  ${_meter}M',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 7,
                      color: _scoreBounceTimer > 0 ? _termGreen : _termGreenDim,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_highScore > 0)
            Text(
              'HI:${_highScore}M',
              style: GoogleFonts.pressStart2p(
                fontSize: 6,
                color: _termGreenDim,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeterBar() {
    final stageProgress = _meter - _stageStartMeter;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: _stageFlash
          ? _termGreen.withValues(alpha: 0.3)
          : _termSurface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(10, (i) {
          final filled = stageProgress > i;
          return Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? _termGreen : Colors.transparent,
              border: Border.all(
                color: filled ? _termGreen : _termGreenDim,
                width: 1.5,
              ),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: _termGreen.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCharacter() {
    final tilt = (_velocity * 8).clamp(-0.4, 0.4);
    final isThrusting = _isStarted && _velocity < 0;

    return Transform.rotate(
      angle: tilt,
      child: SizedBox(
        width: 28,
        height: 36,
        child: CustomPaint(
          painter: BootPainter(
            isThrusting: isThrusting,
            thrustPhase: _blinkCounter % 4,
            velocity: _velocity, // 4-4: 속도 기반 화염
          ),
        ),
      ),
    );
  }

  Widget _buildSlit(Slit slit, double screenW, double screenH) {
    final x = slit.x * screenW;
    const pillarWidth = 28.0;
    // 3-2: 진동 슬릿 — effectiveGapCenter 사용
    // 3-3: 교대 갭 패턴 — gapSizeMultiplier 적용
    final gapSize = _currentGapSize * slit.gapSizeMultiplier;
    final effectiveCenter = slit.effectiveGapCenter(_gameTime);
    final gapTop = (effectiveCenter - gapSize / 2) * screenH;
    final gapBottom = (effectiveCenter + gapSize / 2) * screenH;

    // 3-1: fromLeft half-pillar 판정
    final bool pillarFromLeft = slit.fromLeft;

    return Positioned(
      left: x - pillarWidth / 2,
      top: 0,
      bottom: 0,
      child: SizedBox(
        width: pillarWidth,
        child: Stack(
          children: [
            // 상단 기둥
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: gapTop,
              child: CustomPaint(
                painter: TerminalPillarPainter(fromLeft: pillarFromLeft),
              ),
            ),
            // 슬릿 가장자리 밝은 라인 (상단)
            Positioned(
              left: 0,
              right: 0,
              top: gapTop - 3,
              height: 3,
              child: Container(color: _termGreen),
            ),
            // 하단 기둥
            Positioned(
              top: gapBottom,
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomPaint(
                painter: TerminalPillarPainter(fromLeft: pillarFromLeft),
              ),
            ),
            // 슬릿 가장자리 밝은 라인 (하단)
            Positioned(
              left: 0,
              right: 0,
              top: gapBottom,
              height: 3,
              child: Container(color: _termGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartOverlay() {
    final blink = _blinkCounter % 60 < 30;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: _termBg.withValues(alpha: 0.9),
          border: Border.all(color: _termGreenDim),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'JET BOOT',
              style: GoogleFonts.pressStart2p(
                fontSize: 16,
                color: _termGreen,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: _termGreen.withValues(alpha: 0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'SAFTY PROTOCOL',
              style: GoogleFonts.pressStart2p(
                fontSize: 8,
                color: _termGreenDim,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 28),
            AnimatedOpacity(
              opacity: blink ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 200),
              child: Text(
                t('minigame_tap_to_start', widget.lang),
                style: GoogleFonts.pressStart2p(
                  fontSize: 7,
                  color: _termGreen,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    final blink = _blinkCounter % 60 < 30;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: _termBg.withValues(alpha: 0.94),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. PROTOCOL FAILED
            Text(
              'PROTOCOL FAILED',
              style: GoogleFonts.pressStart2p(
                fontSize: 10,
                color: Colors.redAccent,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            // 2. 현재 점수
            Text(
              '${_meter}M',
              style: GoogleFonts.pressStart2p(
                fontSize: 18,
                color: _termGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'STAGE $_stage',
              style: GoogleFonts.pressStart2p(
                fontSize: 7,
                color: _termGreenDim,
              ),
            ),
            const SizedBox(height: 4),

            // 3. NEW RECORD
            if (_meter >= _highScore && _meter > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'NEW RECORD!',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 7,
                    color: _termGreen,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // 4. 리더보드 (순차 등장)
            _buildLeaderboard(),

            const SizedBox(height: 14),

            // 5. 재시작 안내 (리더보드 완료 후만)
            if (_canRestart)
              AnimatedOpacity(
                opacity: blink ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  t('minigame_tap_to_start', widget.lang),
                  style: GoogleFonts.pressStart2p(
                    fontSize: 6,
                    color: _termGreen,
                    letterSpacing: 1,
                  ),
                ),
              )
            else
              Text(
                'ANALYZING...',
                style: GoogleFonts.pressStart2p(
                  fontSize: 6,
                  color: _termGreenDim,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: _termGreenDim.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '── LEADERBOARD ──',
            style: GoogleFonts.pressStart2p(
              fontSize: 5,
              color: _termGreenDim,
            ),
          ),
          const SizedBox(height: 6),
          if (_topScores.isEmpty && _visibleScoreCount > 0)
            Text(
              'NO DATA',
              style: GoogleFonts.pressStart2p(
                fontSize: 6,
                color: _termGreenDim,
              ),
            )
          else
            for (int i = 0;
                i < _topScores.length && i < _visibleScoreCount;
                i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${i + 1}.',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 6,
                          color: _topScores[i] == _meter && _meter > 0
                              ? _termGreen
                              : _termGreenDim,
                        ),
                      ),
                    ),
                    Text(
                      '${_topScores[i]}M',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 6,
                        color: _topScores[i] == _meter && _meter > 0
                            ? _termGreen
                            : _termGreenDim,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _termSurface,
        border: Border(
          top: BorderSide(color: _termGreenDim.withValues(alpha: 0.5)),
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: _termGreenDim),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app, color: _termGreenDim, size: 14),
              const SizedBox(width: 6),
              Text(
                'TAP',
                style: GoogleFonts.pressStart2p(
                  fontSize: 8,
                  color: _termGreenDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
