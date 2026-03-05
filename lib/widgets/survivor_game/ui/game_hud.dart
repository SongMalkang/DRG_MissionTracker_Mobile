import 'package:flutter/material.dart';
import '../../../utils/game_colors.dart';

/// HUD overlay painter — HP, XP, wave, timer, kill count
class GameHudPainter extends CustomPainter {
  final double hp;
  final double maxHp;
  final double xp;
  final double xpToNextLevel;
  final int level;
  final int wave;
  final double gameTime;
  final int killCount;
  final bool dashReady;
  final double nitra;
  final int hazardLevel;

  static const Color _termGreen = GameColors.survivorGreen;
  static const Color _termAmber = GameColors.survivorAmber;
  static const Color _termRed = GameColors.survivorRed;
  static const Color _termBg = GameColors.survivorBg;
  static const Color _nitraColor = Color(0xFF00CED1);

  GameHudPainter({
    required this.hp,
    required this.maxHp,
    required this.xp,
    required this.xpToNextLevel,
    required this.level,
    required this.wave,
    required this.gameTime,
    required this.killCount,
    required this.dashReady,
    this.nitra = 0,
    this.hazardLevel = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // — Top bar: HP + Wave + Timer —
    _drawHpBar(canvas, w);
    _drawWaveAndTimer(canvas, w);
    _drawXpBar(canvas, w);
    _drawKillCount(canvas, w);
    _drawLevelBadge(canvas, w);
    if (dashReady) _drawDashIndicator(canvas, size);
    _drawNitraCounter(canvas, w);
  }

  void _drawHpBar(Canvas canvas, double w) {
    const top = 12.0;
    const left = 12.0;
    final barWidth = w * 0.4;
    const barHeight = 14.0;
    final ratio = (hp / maxHp).clamp(0.0, 1.0);

    // Background
    canvas.drawRect(
      Rect.fromLTWH(left, top, barWidth, barHeight),
      Paint()..color = _termBg.withValues(alpha: 0.8),
    );

    // Fill
    final fillColor = ratio > 0.5
        ? _termGreen
        : ratio > 0.25
            ? _termAmber
            : _termRed;
    canvas.drawRect(
      Rect.fromLTWH(left, top, barWidth * ratio, barHeight),
      Paint()..color = fillColor.withValues(alpha: 0.8),
    );

    // Border
    canvas.drawRect(
      Rect.fromLTWH(left, top, barWidth, barHeight),
      Paint()
        ..color = _termGreen.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // HP text
    _drawText(canvas, 'HP ${hp.toInt()}/${maxHp.toInt()}',
        left + 4, top + 1, 9, _termGreen);
  }

  void _drawXpBar(Canvas canvas, double w) {
    const top = 30.0;
    const left = 12.0;
    final barWidth = w * 0.4;
    const barHeight = 6.0;
    final ratio = (xp / xpToNextLevel).clamp(0.0, 1.0);

    canvas.drawRect(
      Rect.fromLTWH(left, top, barWidth, barHeight),
      Paint()..color = _termBg.withValues(alpha: 0.6),
    );
    canvas.drawRect(
      Rect.fromLTWH(left, top, barWidth * ratio, barHeight),
      Paint()..color = _termAmber.withValues(alpha: 0.7),
    );
    canvas.drawRect(
      Rect.fromLTWH(left, top, barWidth, barHeight),
      Paint()
        ..color = _termAmber.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  void _drawWaveAndTimer(Canvas canvas, double w) {
    final minutes = (gameTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (gameTime.toInt() % 60).toString().padLeft(2, '0');
    final timeStr = '$minutes:$seconds';

    _drawText(canvas, timeStr, w / 2 - 25, 12, 14, _termGreen);
    _drawText(canvas, 'WAVE $wave', w / 2 - 25, 30, 8, _termGreen.withValues(alpha: 0.7));
  }

  void _drawKillCount(Canvas canvas, double w) {
    _drawText(canvas, 'KILLS: $killCount', w - 110, 12, 10, _termGreen);
  }

  void _drawLevelBadge(Canvas canvas, double w) {
    _drawText(canvas, 'LV.$level', w - 110, 28, 9, _termAmber);
  }

  void _drawNitraCounter(Canvas canvas, double w) {
    _drawText(canvas, 'NITRA: ${nitra.toInt()}', w - 110, 42, 9, _nitraColor);
    _drawText(canvas, 'HAZ $hazardLevel', w - 110, 56, 8, _termAmber.withValues(alpha: 0.6));
  }

  void _drawDashIndicator(Canvas canvas, Size size) {
    // Small indicator near bottom-left
    _drawText(canvas, 'DASH READY', 12, size.height - 90, 8,
        _termGreen.withValues(alpha: 0.5));
  }

  void _drawText(Canvas canvas, String text, double x, double y,
      double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant GameHudPainter old) => true;
}
