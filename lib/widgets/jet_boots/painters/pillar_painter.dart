import 'package:flutter/material.dart';
import '../../../utils/game_colors.dart';

// 터미널 녹색 색상 팔레트 (GameColors에서 참조)
const _termGreenDim = GameColors.termGreenDim;
const _termGreenFaint = GameColors.termGreenFaint;

// ─── 터미널 기둥 페인터 (녹색 + 내부 패턴) ──────────────────────────────────

class TerminalPillarPainter extends CustomPainter {
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
