import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/strings.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DRG 스타일 "JET BOOT SAFTY PROTOCOL" 미니게임
//  ─ 터미널 녹색 CRT 모니터 미감
//  ─ 좌우 벽에서 뻗어나온 기둥 + 슬릿(틈) 통과
//  ─ 슬릿 통과마다 미터(M) 증가
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
  int _meter = 0; // 통과한 슬릿 수 (미터)
  int _highScore = 0;

  // 장애물: 좌우 벽에서 뻗어나온 기둥 + 슬릿
  final List<_Slit> _slits = [];
  final Random _random = Random();

  // 캐릭터 위치 (화면 비율)
  static const _characterX = 0.2; // 좌측에서 20% 위치
  static const _gapSize = 0.25; // 슬릿 틈 크기 (난이도)

  // 깜박임
  int _blinkCounter = 0;

  @override
  void initState() {
    super.initState();
    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);

    _initSlits();
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
    if (!_isStarted || _isGameOver) return;

    _blinkCounter++;
    setState(() {
      _velocity += 0.0009;
      _characterY = (_characterY + _velocity).clamp(0.0, 1.0);

      // 바닥/천장 충돌
      if (_characterY >= 0.98 || _characterY <= 0.02) {
        _triggerGameOver();
        return;
      }

      // 슬릿 이동 (좌측으로 스크롤)
      for (final slit in _slits) {
        slit.x -= 0.005;

        // 슬릿 통과 판정
        if (!slit.passed && slit.x < _characterX - 0.03) {
          slit.passed = true;
          _meter++;
        }

        // 화면 밖으로 나가면 재배치
        if (slit.x < -0.1) {
          slit.x = 1.1;
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

  bool _checkCollision(_Slit slit) {
    // 캐릭터가 슬릿의 x 범위 안에 있는지
    const charWidth = 0.06;
    final slitLeft = slit.x - 0.03;
    final slitRight = slit.x + 0.03;
    final charLeft = _characterX - charWidth / 2;
    final charRight = _characterX + charWidth / 2;

    if (charRight < slitLeft || charLeft > slitRight) return false;

    // 슬릿의 기둥 영역과 겹치는지
    final gapTop = slit.gapCenter - _gapSize / 2;
    final gapBottom = slit.gapCenter + _gapSize / 2;

    return _characterY < gapTop || _characterY > gapBottom;
  }

  void _triggerGameOver() {
    _isGameOver = true;
    if (_meter > _highScore) _highScore = _meter;
    _gameLoopController.stop();
  }

  void _jump() {
    if (_isGameOver) {
      // 재시작
      setState(() {
        _isGameOver = false;
        _isStarted = false;
        _characterY = 0.5;
        _velocity = 0.0;
        _meter = 0;
        _initSlits();
      });
      return;
    }

    if (!_isStarted) {
      setState(() => _isStarted = true);
      _gameLoopController.repeat();
      return;
    }

    // 점프 (완화된 상승력)
    setState(() => _velocity = -0.016);
  }

  @override
  void dispose() {
    _gameLoopController.dispose();
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
                  '${_meter}M',
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
    // 프로그레스 도트 (DRG 레퍼런스의 상단 프로그레스)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: _termSurface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(10, (i) {
          final filled = _meter > i;
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
    final gapTop = (slit.gapCenter - _gapSize / 2) * screenH;
    final gapBottom = (slit.gapCenter + _gapSize / 2) * screenH;

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
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: _termBg.withValues(alpha: 0.92),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PROTOCOL FAILED',
              style: GoogleFonts.pressStart2p(
                fontSize: 10,
                color: Colors.redAccent,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${_meter}M',
              style: GoogleFonts.pressStart2p(
                fontSize: 18,
                color: _termGreen,
              ),
            ),
            const SizedBox(height: 4),
            if (_meter >= _highScore && _meter > 0)
              Text(
                'NEW RECORD!',
                style: GoogleFonts.pressStart2p(
                  fontSize: 7,
                  color: _termGreen,
                ),
              ),
            const SizedBox(height: 20),
            Text(
              t('minigame_tap_to_start', widget.lang),
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
