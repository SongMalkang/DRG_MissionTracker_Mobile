import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/game_colors.dart';
import '../../../utils/strings.dart';

const _termGreen = GameColors.termGreen;
const _termGreenDim = GameColors.termGreenDim;
const _termSurface = GameColors.termSurface;
const _termAmber = GameColors.termAmber;

// ── 헤더 (1-4: 점수 바운스 지원) ──
class GameHeader extends StatelessWidget {
  final String lang;
  final int score;
  final int highScore;
  final VoidCallback onBack;
  final double scoreBounceScale;

  const GameHeader({
    super.key,
    required this.lang,
    required this.score,
    required this.highScore,
    required this.onBack,
    this.scoreBounceScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final isBouncing = scoreBounceScale > 1.01;
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
            onPressed: onBack,
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
                // 1-4: 점수 바운스 애니메이션
                Transform.scale(
                  scale: scoreBounceScale,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${t('minigame_score', lang)}: $score',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 7,
                      color: isBouncing ? _termGreen : _termGreenDim,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (highScore > 0)
            Text(
              'HI:$highScore',
              style: GoogleFonts.pressStart2p(
                fontSize: 6,
                color: _termGreenDim,
              ),
            ),
        ],
      ),
    );
  }
}

// ── 생명 + 스테이지 바 (1-5: 라이프 손실 빨간 틴트) ──
class TimerBar extends StatelessWidget {
  final int stage;
  final int lives;
  final int maxLives;
  final int stageRescueCount;
  final bool lifeLostFlash;

  const TimerBar({
    super.key,
    required this.stage,
    required this.lives,
    required this.maxLives,
    required this.stageRescueCount,
    required this.lifeLostFlash,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      // 1-5: 라이프 손실 시 빨간 틴트
      color: lifeLostFlash
          ? Colors.redAccent.withValues(alpha: 0.15)
          : _termSurface,
      child: Row(
        children: [
          // 스테이지 표시
          Text(
            'STG $stage',
            style: GoogleFonts.pressStart2p(
              fontSize: 6,
              color: _termGreenDim,
            ),
          ),
          const SizedBox(width: 8),
          // 하트 (생명)
          for (int i = 0; i < maxLives; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                i < lives ? Icons.favorite : Icons.favorite_border,
                size: 14,
                color: lifeLostFlash && i == lives
                    ? Colors.redAccent
                    : (i < lives ? _termGreen : _termGreenDim),
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
                color: stageRescueCount > i ? _termGreen : Colors.transparent,
                border: Border.all(
                  color: stageRescueCount > i ? _termGreen : _termGreenDim,
                  width: 1,
                ),
                boxShadow: stageRescueCount > i
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
}

// ── 콤보 대형 오버레이 (4-4: 감쇠 깜빡임 지원) ──
class ComboOverlay extends StatelessWidget {
  final String lang;
  final int combo;
  final Animation<double> comboScaleAnim;
  final AnimationController comboAnimController;
  final bool comboDecayWarning;

  const ComboOverlay({
    super.key,
    required this.lang,
    required this.combo,
    required this.comboScaleAnim,
    required this.comboAnimController,
    this.comboDecayWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 6,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: comboAnimController,
          builder: (context, child) {
            final scale = comboScaleAnim.value;
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
                  '▸ ${t('minigame_wam_combo', lang)} ◂',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 8,
                    color: _termAmber.withValues(
                        alpha: comboDecayWarning ? 0.4 : 0.7),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'x$combo',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 22,
                    color: _termAmber.withValues(
                        alpha: comboDecayWarning ? 0.5 : 1.0),
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
}

// ── 하단 바 ──
class BottomStatusBar extends StatelessWidget {
  final String lang;
  final bool isPlaying;
  final bool isSurging;

  const BottomStatusBar({
    super.key,
    required this.lang,
    required this.isPlaying,
    required this.isSurging,
  });

  @override
  Widget build(BuildContext context) {
    final showSurge = isPlaying && isSurging;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: _termSurface,
      child: Center(
        child: Text(
          showSurge
              ? t('minigame_wam_swarm', lang)
              : (isPlaying ? 'TAP SCOUTS TO RESCUE' : ''),
          style: GoogleFonts.pressStart2p(
            fontSize: 7,
            color: showSurge ? _termAmber : _termGreenDim,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── 레디 오버레이 ──
class ReadyOverlay extends StatelessWidget {
  final String lang;
  final int blinkCounter;

  const ReadyOverlay({
    super.key,
    required this.lang,
    required this.blinkCounter,
  });

  @override
  Widget build(BuildContext context) {
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
          if (blinkCounter % 60 < 40)
            Text(
              t('minigame_tap_to_start', lang),
              style: GoogleFonts.pressStart2p(
                fontSize: 9,
                color: _termGreen,
              ),
            ),
        ],
      ),
    );
  }
}
