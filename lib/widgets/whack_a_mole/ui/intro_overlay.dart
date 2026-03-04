import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/game_colors.dart';
import '../painters/intro_painters.dart';

const _termGreen = GameColors.termGreen;
const _termGreenDim = GameColors.termGreenDim;

class IntroOverlay extends StatelessWidget {
  final BoxConstraints constraints;
  final Animation<double> scoutWalkAnim;
  final double introValue;
  final int blinkCounter;
  final bool scoutStopped;
  final bool scoutSurprised;
  final bool scoutCaught;
  final bool sinking;
  final double sinkProgress;
  final VoidCallback onSkip;

  const IntroOverlay({
    super.key,
    required this.constraints,
    required this.scoutWalkAnim,
    required this.introValue,
    required this.blinkCounter,
    required this.scoutStopped,
    required this.scoutSurprised,
    required this.scoutCaught,
    required this.sinking,
    required this.sinkProgress,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    // 지면선 위치
    final groundY = h * 0.55;

    // 핏죠 크기 & 위치
    const pitjawW = 80.0;
    const pitjawH = 120.0;
    final pitjawX = w * 0.4;

    // 스카웃 위치
    final scoutX = w * scoutWalkAnim.value;
    final scoutY = groundY - 50;

    // 걷는 흔들림 (멈추면 중단)
    final wobble = (scoutStopped || scoutCaught)
        ? 0.0
        : sin(introValue * 40) * 2.0;

    // sink 시 전체 Y 오프셋
    final sinkOffset = sinking ? sinkProgress * (h - groundY + 60) : 0.0;

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
            child: CustomPaint(painter: PitJawPainter()),
          ),
        ),

        // 스카웃 (물리기 전)
        if (!scoutCaught)
          Positioned(
            left: scoutX - 20,
            top: scoutY + wobble,
            child: SizedBox(
              width: 40,
              height: 50,
              child: CustomPaint(
                painter: ScoutPainter(
                  surprised: scoutSurprised,
                  caught: false,
                  blinkCounter: blinkCounter,
                ),
              ),
            ),
          ),

        // 스카웃 (물린 후 — 핏죠 위에 스냅 + 같이 sink)
        if (scoutCaught)
          Positioned(
            left: pitjawX - 20,
            top: groundY - 35 + sinkOffset,
            child: SizedBox(
              width: 40,
              height: 50,
              child: CustomPaint(
                painter: ScoutPainter(
                  surprised: true,
                  caught: true,
                  blinkCounter: blinkCounter,
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
            onTap: onSkip,
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
}
