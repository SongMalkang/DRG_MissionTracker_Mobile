import 'package:flutter/material.dart';

// ─── 부츠 캐릭터 페인터 (픽셀 부츠 + 제트 분사) ─────────────────────────────

class BootPainter extends CustomPainter {
  final bool isThrusting;
  final int thrustPhase;
  final double velocity; // 4-4: 속도 기반 화염 강도

  BootPainter({
    required this.isThrusting,
    required this.thrustPhase,
    this.velocity = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 부츠 본체 영역 (하단 제트 분사 공간 확보)
    final bootH = h * 0.7;
    final bootTop = 0.0;

    // Boot colors: white body (DRG Jet Boots style)
    const bootWhite = Color(0xFFEEEEEE);
    const bootGray = Color(0xFFAAAAAA);
    final fillPaint = Paint()..color = bootWhite;
    final dimPaint = Paint()..color = bootGray;
    final borderPaint = Paint()
      ..color = bootWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final glowPaint = Paint()
      ..color = bootWhite.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);

    // ── 발목 (상단 좁은 부분) ──
    final ankleW = w * 0.5;
    final ankleH = bootH * 0.45;
    final ankleL = (w - ankleW) / 2;
    final ankleRect = Rect.fromLTWH(ankleL, bootTop, ankleW, ankleH);
    canvas.drawRect(ankleRect, fillPaint);
    canvas.drawRect(ankleRect, borderPaint);

    // 발목 내부 가로줄 패턴
    final linePaint = Paint()..color = bootGray.withValues(alpha: 0.5);
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

      // 4-4: 속도 비례 화염 길이
      final speedFactor = (-velocity / 1.2).clamp(0.0, 1.0);
      final flameLen =
          h * (0.20 + 0.15 * speedFactor) + (thrustPhase % 3) * 2.0;
      final flamePath = Path()
        ..moveTo(centerX - 5, thrustTop)
        ..lineTo(centerX + 5, thrustTop)
        ..lineTo(centerX, thrustTop + flameLen)
        ..close();

      // Flame colors: red/orange (DRG Jet Boots style)
      const flameRed = Color(0xFFFF3300);
      const flameOrange = Color(0xFFFF6600);
      final flamePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            flameOrange,
            flameRed.withValues(alpha: 0.6),
            flameRed.withValues(alpha: 0.0),
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
          ..color = flameRed.withValues(alpha: 0.4);
        canvas.drawPath(sidePath, sidePaint);
      }

      // 불꽃 글로우
      canvas.drawCircle(
        Offset(centerX, thrustTop + 4),
        8,
        Paint()
          ..color = flameRed.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(BootPainter oldDelegate) =>
      oldDelegate.isThrusting != isThrusting ||
      oldDelegate.thrustPhase != thrustPhase ||
      oldDelegate.velocity != velocity;
}
