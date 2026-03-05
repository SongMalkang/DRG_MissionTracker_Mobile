import 'package:flutter/material.dart';
import '../../../utils/game_colors.dart';

// 터미널 녹색 색상 팔레트 (GameColors에서 참조)
const _termGreen = GameColors.termGreen;
const _termGreenDim = GameColors.termGreenDim;
const _termGreenFaint = GameColors.termGreenFaint;

// ─── 터미널 기둥 페인터 (녹색 + 내부 패턴) ──────────────────────────────────

class TerminalPillarPainter extends CustomPainter {
  /// true = 왼쪽 벽에서 뻗는 half-pillar, false = 오른쪽 벽에서
  /// null = 양쪽 모두 (기존 full-pillar)
  final bool? fromLeft;

  /// 갭 가장자리 글로우 강도 (0.0 = 없음)
  final double edgeGlow;

  TerminalPillarPainter({this.fromLeft, this.edgeGlow = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (fromLeft != null) {
      _paintHalfPillar(canvas, size, fromLeft!);
    } else {
      _paintFullPillar(canvas, size);
    }

    // 엣지 글로우 (갭 가장자리 방향 — 하단에 그려짐)
    if (edgeGlow > 0.0) {
      final glowPaint = Paint()
        ..color = _termGreen.withValues(alpha: 0.15 * edgeGlow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRect(
        Rect.fromLTWH(0, size.height - 4, size.width, 4),
        glowPaint,
      );
    }
  }

  void _paintFullPillar(Canvas canvas, Size size) {
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

  void _paintHalfPillar(Canvas canvas, Size size, bool fromLeft) {
    final w = size.width;
    final h = size.height;

    // Half-pillar: 한쪽 벽에서만 뻗어나옴 (직사각형)
    final bodyPaint = Paint()..color = _termGreenFaint.withValues(alpha: 0.6);
    final borderPaint = Paint()
      ..color = _termGreenDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(rect, bodyPaint);
    canvas.drawRect(rect, borderPaint);

    // 뻗어나오는 쪽 끝에 밝은 엣지라인 (방향 표시)
    final edgePaint = Paint()
      ..color = _termGreen.withValues(alpha: 0.5)
      ..strokeWidth = 2;
    if (fromLeft) {
      // 오른쪽 끝 강조
      canvas.drawLine(Offset(w, 0), Offset(w, h), edgePaint);
    } else {
      // 왼쪽 끝 강조
      canvas.drawLine(const Offset(0, 0), Offset(0, h), edgePaint);
    }

    // 내부 수평 라인 패턴
    final linePaint = Paint()..color = _termGreenDim.withValues(alpha: 0.3);
    for (double y = 6; y < h; y += 8) {
      canvas.drawRect(Rect.fromLTWH(3, y, w - 6, 1), linePaint);
    }
  }

  @override
  bool shouldRepaint(TerminalPillarPainter oldDelegate) =>
      oldDelegate.fromLeft != fromLeft || oldDelegate.edgeGlow != edgeGlow;
}
