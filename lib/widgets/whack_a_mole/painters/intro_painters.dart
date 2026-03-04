import 'dart:math';
import 'package:flutter/material.dart';
import '../../../utils/game_colors.dart';

// 터미널 녹색 색상 팔레트
const _termGreen = GameColors.termGreen;
const _termGreenDim = GameColors.termGreenDim;
const _termGreenFaint = GameColors.termGreenFaint;
const _termAmber = GameColors.termAmber;

// ── 핏죠 와이어프레임 페인터 (인트로용) ──
class PitJawPainter extends CustomPainter {
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
class ScoutPainter extends CustomPainter {
  final bool surprised;
  final bool caught;
  final int blinkCounter;

  ScoutPainter({
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
  bool shouldRepaint(covariant ScoutPainter oldDelegate) => true;
}
