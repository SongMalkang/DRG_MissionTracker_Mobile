import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/strings.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DRG 스타일 "JET BOOT SAFTY PROTOCOL" 미니게임
//  ─ 터미널 녹색 CRT 모니터 미감
//  ─ 좌우 벽에서 뻗어나온 기둥 + 슬릿(틈) 통과
//  ─ 슬릿 통과마다 미터(M) 증가
//  ─ 점진적 난이도 + 사운드 + 로컬 리더보드
// ═══════════════════════════════════════════════════════════════════════════

// 터미널 녹색 색상 팔레트
const _termGreen = Color(0xFF39FF14);
const _termGreenDim = Color(0xFF1A8A0A);
const _termGreenFaint = Color(0xFF0D4D06);
const _termBg = Color(0xFF040A04);
const _termSurface = Color(0xFF081208);

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

  // 스테이지
  int _stage = 1;
  int _stageStartMeter = 0;
  static const _slitsPerStage = 10;
  bool _stageFlash = false;

  // 장애물: 좌우 벽에서 뻗어나온 기둥 + 슬릿
  final List<_Slit> _slits = [];
  final Random _random = Random();

  // 캐릭터 위치 (화면 비율)
  static const _characterX = 0.2; // 좌측에서 20% 위치

  // 깜박임
  int _blinkCounter = 0;

  // ── 오디오 ──
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const _sfxStart = 'audio/shouts/jetboots/JetBootsUse_02.ogg';
  static const _sfxMilestone = 'audio/shouts/jetboots/JetBootsUse_16.ogg';
  static const _sfxFail = 'audio/shouts/jetboots/JetBoots_Overheat_2.ogg';

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
    for (int i = 0; i < 3; i++) {
      _slits.add(_Slit(
        x: 0.7 + i * 0.5,
        gapCenter: 0.25 + _random.nextDouble() * 0.5,
        fromLeft: _random.nextBool(),
      ));
    }
  }

  void _gameLoop() {
    // 깜박임은 게임오버 중에도 갱신 (오버레이 애니메이션용)
    _blinkCounter++;

    if (!_isStarted || _isGameOver) return;

    final now = DateTime.now();
    final dt = (now.difference(_lastFrameTime).inMicroseconds / 1000000.0)
        .clamp(0.0, 0.1);
    _lastFrameTime = now;

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
          _checkMilestone(_meter);
        }

        // 화면 밖으로 나가면 재배치
        if (slit.x < -0.1) {
          slit.x = _getNextSlitX();
          slit.gapCenter = 0.2 + _random.nextDouble() * 0.6;
          slit.fromLeft = _random.nextBool();
          slit.passed = false;
        }
      }

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

  bool _checkCollision(_Slit slit) {
    // 캐릭터가 슬릿의 x 범위 안에 있는지
    const charWidth = 0.06;
    final slitLeft = slit.x - 0.03;
    final slitRight = slit.x + 0.03;
    final charLeft = _characterX - charWidth / 2;
    final charRight = _characterX + charWidth / 2;

    if (charRight < slitLeft || charLeft > slitRight) return false;

    // 슬릿의 기둥 영역과 겹치는지
    final gapSize = _currentGapSize;
    final gapTop = slit.gapCenter - gapSize / 2;
    final gapBottom = slit.gapCenter + gapSize / 2;

    return _characterY < gapTop || _characterY > gapBottom;
  }

  void _triggerGameOver() {
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
        _initSlits();
      });
      return;
    }

    if (!_isStarted) {
      setState(() => _isStarted = true);
      _lastFrameTime = DateTime.now();
      _gameLoopController.repeat();
      _playSound(_sfxStart);
      return;
    }

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

  void _checkMilestone(int meter) {
    final slitsInStage = meter - _stageStartMeter;
    if (slitsInStage >= _slitsPerStage) {
      _stage++;
      _stageStartMeter = meter;
      _playSound(_sfxMilestone);
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
                    return Stack(
                      children: [
                        // 배경: CRT 스캔라인 + 그리드
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CrtBackgroundPainter(),
                          ),
                        ),

                        // 좌우 벽 테두리
                        Positioned(
                          left: 0, top: 0, bottom: 0,
                          child: Container(width: 2, color: _termGreenDim),
                        ),
                        Positioned(
                          right: 0, top: 0, bottom: 0,
                          child: Container(width: 2, color: _termGreenDim),
                        ),

                        // 바닥 라인
                        Positioned(
                          left: 0, right: 0, bottom: 0,
                          child: Container(height: 2, color: _termGreenDim),
                        ),

                        // 슬릿 장애물
                        for (final slit in _slits)
                          _buildSlit(slit, w, h),

                        // 캐릭터 (부츠)
                        Positioned(
                          left: w * _characterX - 14,
                          top: _characterY * (h - 36),
                          child: _buildCharacter(),
                        ),

                        // CRT 스캔라인 오버레이
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _ScanlinePainter(),
                            ),
                          ),
                        ),

                        // 시작 오버레이
                        if (!_isStarted && !_isGameOver)
                          _buildStartOverlay(),

                        // 게임 오버 오버레이
                        if (_isGameOver)
                          _buildGameOverOverlay(),
                      ],
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
                Text(
                  'STG $_stage  ${_meter}M',
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
          painter: _BootPainter(
            isThrusting: isThrusting,
            thrustPhase: _blinkCounter % 4,
          ),
        ),
      ),
    );
  }

  Widget _buildSlit(_Slit slit, double screenW, double screenH) {
    final x = slit.x * screenW;
    const pillarWidth = 28.0;
    final gapSize = _currentGapSize;
    final gapTop = (slit.gapCenter - gapSize / 2) * screenH;
    final gapBottom = (slit.gapCenter + gapSize / 2) * screenH;

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
                painter: _TerminalPillarPainter(),
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
                painter: _TerminalPillarPainter(),
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
            for (int i = 0; i < _topScores.length && i < _visibleScoreCount; i++)
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

// ─── 슬릿 데이터 ────────────────────────────────────────────────────────────

class _Slit {
  double x; // 화면 비율 X 위치
  double gapCenter; // 슬릿 중심 (0.0~1.0)
  bool fromLeft; // 기둥이 왼쪽에서 뻗는지 (현재 미사용, 확장용)
  bool passed = false; // 통과 여부

  _Slit({
    required this.x,
    required this.gapCenter,
    required this.fromLeft,
  });
}

// ─── CRT 배경 페인터 (그리드 + 미세한 녹색 노이즈) ───────────────────────────

class _CrtBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 미세한 그리드 라인 (가로)
    final gridPaint = Paint()
      ..color = _termGreenFaint.withValues(alpha: 0.15);
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 0.5), gridPaint);
    }
    // 세로
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 0.5, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── CRT 스캔라인 오버레이 ──────────────────────────────────────────────────

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

// ─── 부츠 캐릭터 페인터 (픽셀 부츠 + 제트 분사) ─────────────────────────────

class _BootPainter extends CustomPainter {
  final bool isThrusting;
  final int thrustPhase;

  _BootPainter({required this.isThrusting, required this.thrustPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 부츠 본체 영역 (하단 제트 분사 공간 확보)
    final bootH = h * 0.7;
    final bootTop = 0.0;

    final fillPaint = Paint()..color = _termGreen;
    final dimPaint = Paint()..color = _termGreenDim;
    final borderPaint = Paint()
      ..color = _termGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final glowPaint = Paint()
      ..color = _termGreen.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);

    // ── 발목 (상단 좁은 부분) ──
    final ankleW = w * 0.5;
    final ankleH = bootH * 0.45;
    final ankleL = (w - ankleW) / 2;
    final ankleRect = Rect.fromLTWH(ankleL, bootTop, ankleW, ankleH);
    canvas.drawRect(ankleRect, fillPaint);
    canvas.drawRect(ankleRect, borderPaint);

    // 발목 내부 가로줄 패턴
    final linePaint = Paint()..color = _termGreenDim.withValues(alpha: 0.5);
    for (double y = bootTop + 4; y < bootTop + ankleH - 2; y += 4) {
      canvas.drawLine(
        Offset(ankleL + 2, y),
        Offset(ankleL + ankleW - 2, y),
        linePaint,
      );
    }

    // ── 발 (하단 넓은 부분, 앞쪽 돌출) ──
    final footTop = bootTop + ankleH;
    final footH = bootH * 0.4;
    final footL = w * 0.1;
    final footW = w * 0.85; // 앞쪽(우측)으로 돌출
    final footRect = Rect.fromLTWH(footL, footTop, footW, footH);
    canvas.drawRect(footRect, fillPaint);
    canvas.drawRect(footRect, borderPaint);

    // ── 밑창 (밝은 라인) ──
    final soleTop = footTop + footH;
    final soleH = bootH * 0.15;
    final soleRect = Rect.fromLTWH(footL - 1, soleTop, footW + 2, soleH);
    canvas.drawRect(soleRect, dimPaint);
    canvas.drawRect(soleRect, borderPaint);

    // 글로우 효과
    final bootBounds = Rect.fromLTWH(footL - 1, bootTop, footW + 2, bootH);
    canvas.drawRect(bootBounds, glowPaint);

    // ── 제트 분사 (점프 시에만) ──
    if (isThrusting) {
      final thrustTop = soleTop + soleH;
      final centerX = ankleL + ankleW / 2;

      // 메인 불꽃 (삼각형)
      final flameLen = h * 0.28 + (thrustPhase % 3) * 2.0;
      final flamePath = Path()
        ..moveTo(centerX - 5, thrustTop)
        ..lineTo(centerX + 5, thrustTop)
        ..lineTo(centerX, thrustTop + flameLen)
        ..close();

      final flamePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _termGreen,
            _termGreen.withValues(alpha: 0.6),
            _termGreenDim.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(
            centerX - 5, thrustTop, 10, flameLen));
      canvas.drawPath(flamePath, flamePaint);

      // 사이드 불꽃 (작은 삼각형)
      final sideLen = flameLen * 0.6;
      for (final dx in [-6.0, 6.0]) {
        final sidePath = Path()
          ..moveTo(centerX + dx - 2, thrustTop + 2)
          ..lineTo(centerX + dx + 2, thrustTop + 2)
          ..lineTo(centerX + dx, thrustTop + sideLen)
          ..close();
        final sidePaint = Paint()
          ..color = _termGreen.withValues(alpha: 0.4);
        canvas.drawPath(sidePath, sidePaint);
      }

      // 불꽃 글로우
      canvas.drawCircle(
        Offset(centerX, thrustTop + 4),
        8,
        Paint()
          ..color = _termGreen.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(_BootPainter oldDelegate) =>
      oldDelegate.isThrusting != isThrusting ||
      oldDelegate.thrustPhase != thrustPhase;
}

// ─── 터미널 기둥 페인터 (녹색 + 내부 패턴) ──────────────────────────────────

class _TerminalPillarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 기둥 본체 (반투명 녹색)
    final bodyPaint = Paint()..color = _termGreenFaint.withValues(alpha: 0.6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bodyPaint);

    // 테두리 (밝은 녹색)
    final borderPaint = Paint()
      ..color = _termGreenDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    // 내부 수평 라인 패턴
    final linePaint = Paint()..color = _termGreenDim.withValues(alpha: 0.3);
    for (double y = 6; y < size.height; y += 8) {
      canvas.drawRect(
        Rect.fromLTWH(3, y, size.width - 6, 1),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
