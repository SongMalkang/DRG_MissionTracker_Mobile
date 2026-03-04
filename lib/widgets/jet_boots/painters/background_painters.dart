import 'package:flutter/material.dart';
import '../../../utils/game_colors.dart';

// 터미널 녹색 색상 팔레트 (GameColors에서 참조)
const _termGreenFaint = GameColors.termGreenFaint;

// ─── CRT 배경 페인터 (그리드 + 미세한 녹색 노이즈) ───────────────────────────

class CrtBackgroundPainter extends CustomPainter {
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

class ScanlinePainter extends CustomPainter {
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
