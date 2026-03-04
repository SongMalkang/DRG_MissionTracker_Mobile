import 'package:flutter/material.dart';
import '../../../utils/game_colors.dart';

class GameOverScreen extends StatefulWidget {
  final int killCount;
  final int wave;
  final double gameTime;
  final double score;
  final int level;
  final List<int> topScores;
  final VoidCallback onRestart;
  final VoidCallback onBack;

  const GameOverScreen({
    super.key,
    required this.killCount,
    required this.wave,
    required this.gameTime,
    required this.score,
    required this.level,
    required this.topScores,
    required this.onRestart,
    required this.onBack,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  static const Color _termGreen = GameColors.survivorGreen;
  static const Color _termAmber = GameColors.survivorAmber;
  static const Color _termRed = GameColors.survivorRed;
  static const Color _termBg = GameColors.survivorBg;

  int _visibleLines = 0;
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();
    _revealLines();
  }

  void _revealLines() async {
    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() => _visibleLines = i + 1);
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _showButtons = true);
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (widget.gameTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (widget.gameTime.toInt() % 60).toString().padLeft(2, '0');

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _termBg,
            border: Border.all(color: _termRed, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'MISSION FAILED',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  color: _termRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dwarf Down!',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: _termRed.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              if (_visibleLines >= 1) _statLine('SCORE', widget.score.toInt().toString(), _termAmber),
              if (_visibleLines >= 2) _statLine('KILLS', widget.killCount.toString(), _termGreen),
              if (_visibleLines >= 3) _statLine('WAVE', widget.wave.toString(), _termGreen),
              if (_visibleLines >= 4) _statLine('TIME', '$minutes:$seconds', _termGreen),
              if (_visibleLines >= 5) _statLine('LEVEL', widget.level.toString(), _termGreen),
              if (_visibleLines >= 6) const SizedBox(height: 12),
              if (_visibleLines >= 6)
                Text(
                  '── TOP SCORES ──',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: _termGreen.withValues(alpha: 0.5),
                  ),
                ),
              if (_visibleLines >= 7) ..._buildLeaderboard(),
              if (_visibleLines >= 8) const SizedBox(height: 16),
              if (_showButtons) ...[
                _buildButton('RETRY', _termGreen, widget.onRestart),
                const SizedBox(height: 8),
                _buildButton('BACK', _termGreen.withValues(alpha: 0.5), widget.onBack),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statLine(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: _termGreen.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLeaderboard() {
    return widget.topScores.take(5).toList().asMap().entries.map((entry) {
      final rank = entry.key + 1;
      final score = entry.value;
      final isNew = score == widget.score.toInt() && rank == 1;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '#$rank',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: isNew ? _termAmber : _termGreen.withValues(alpha: 0.4),
              ),
            ),
            Text(
              score.toString(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: isNew ? _termAmber : _termGreen.withValues(alpha: 0.6),
                fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildButton(String text, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1),
            color: _termBg,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
