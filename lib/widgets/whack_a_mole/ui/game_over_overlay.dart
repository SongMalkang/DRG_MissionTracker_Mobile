import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/game_colors.dart';
import '../../../utils/strings.dart';

const _termGreen = GameColors.termGreen;
const _termGreenDim = GameColors.termGreenDim;
const _termBg = GameColors.termBg;
const _termAmber = GameColors.termAmber;

class GameOverOverlay extends StatelessWidget {
  final String lang;
  final int score;
  final int stage;
  final int rescueCount;
  final int maxCombo;
  final int lives;
  final int blinkCounter;
  final bool canRestart;
  final List<int> topScores;
  final int visibleScoreCount;

  const GameOverOverlay({
    super.key,
    required this.lang,
    required this.score,
    required this.stage,
    required this.rescueCount,
    required this.maxCombo,
    required this.lives,
    required this.blinkCounter,
    required this.canRestart,
    required this.topScores,
    required this.visibleScoreCount,
  });

  @override
  Widget build(BuildContext context) {
    final isNewRecord =
        score > 0 && topScores.isNotEmpty && score >= topScores.first;

    final isAllLost = lives <= 0;

    return Container(
      color: _termBg.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isAllLost
                  ? t('minigame_wam_all_lost', lang)
                  : t('minigame_wam_extraction_complete', lang),
              style: GoogleFonts.pressStart2p(
                fontSize: 10,
                color: isAllLost ? Colors.redAccent : _termGreen,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              '${t('minigame_score', lang)}: $score',
              style: GoogleFonts.pressStart2p(
                fontSize: 9,
                color: _termGreen,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              'STAGE: $stage  ${t('minigame_wam_rescued', lang)}: $rescueCount',
              style: GoogleFonts.pressStart2p(
                fontSize: 6,
                color: _termGreenDim,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              '${t('minigame_wam_max_combo', lang)}: $maxCombo',
              style: GoogleFonts.pressStart2p(
                fontSize: 7,
                color: _termGreenDim,
              ),
            ),
            const SizedBox(height: 4),

            if (isNewRecord && blinkCounter % 40 < 25)
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

            if (canRestart && blinkCounter % 60 < 40)
              Text(
                t('minigame_tap_to_start', lang),
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
    if (topScores.isEmpty) return [];

    return [
      Text(
        'TOP SCORES',
        style: GoogleFonts.pressStart2p(
          fontSize: 7,
          color: _termGreenDim,
        ),
      ),
      const SizedBox(height: 8),
      for (int i = 0; i < visibleScoreCount && i < topScores.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '${i + 1}. ${topScores[i]}',
            style: GoogleFonts.pressStart2p(
              fontSize: 7,
              color: (i == 0 && topScores[i] == score)
                  ? _termAmber
                  : _termGreenDim,
            ),
          ),
        ),
    ];
  }
}
