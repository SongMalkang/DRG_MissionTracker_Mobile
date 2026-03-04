import 'dart:math';
import 'package:flutter/material.dart';
import '../../../utils/game_colors.dart';
import '../mole_data.dart';

// 터미널 녹색 색상 팔레트
const _termGreen = GameColors.termGreen;
const _termGreenDim = GameColors.termGreenDim;
const _termGreenFaint = GameColors.termGreenFaint;
const _termBg = GameColors.termBg;
const _termAmber = GameColors.termAmber;

// ═══════════════════════════════════════════════════════════════════════════
//  게임플레이 구멍 페인터 (핏죠 턱 + 스카웃 합체, 곡괭이, 그래플링훅)
// ═══════════════════════════════════════════════════════════════════════════
class HolePainter extends CustomPainter {
  final MoleHole hole;
  final int blinkCounter;

  HolePainter({required this.hole, required this.blinkCounter});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 셀 전체 클리핑 (절대 밖으로 안 나감)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));

    // 구멍 위치 (하단 35%)
    final holeTop = h * 0.65;
    final holeRect = Rect.fromLTWH(w * 0.1, holeTop, w * 0.8, h * 0.28);

    // 구멍 배경
    final holeBgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.black, _termBg],
      ).createShader(holeRect);
    canvas.drawOval(holeRect, holeBgPaint);

    // 구멍 테두리
    final holeBorderPaint = Paint()
      ..color = _termGreenDim.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(holeRect, holeBorderPaint);

    // 이빨 (구멍 상단)
    final toothPaint = Paint()
      ..color = _termGreenDim.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int i = 0; i < 4; i++) {
      final tx = w * (0.2 + i * 0.18);
      canvas.drawLine(
        Offset(tx, holeTop + 2),
        Offset(tx + w * 0.04, holeTop - 3),
        toothPaint,
      );
    }

    // 스카웃 + 핏죠 합체 팝업
    if (hole.isActive || hole.isRescued) {
      _drawComboAsset(canvas, w, h, holeTop);
    }

    // 곡괭이 타격 이펙트 (스윙 → 임팩트 → 파티클)
    if (hole.pickaxeProgress > 0 && hole.pickaxeProgress < 1.0) {
      _drawPickaxe(canvas, w, h, holeTop);
    }

    // 히트 이펙트 — 터미널 스타일 텍스트 + 파티클
    if (hole.hitFlashProgress > 0 && hole.hitFlashProgress < 1.0) {
      _drawHitEffect(canvas, w, h, holeTop);
    }

    canvas.restore();
  }

  /// 핏죠 턱 + 스카웃 상반신 합체 에셋
  void _drawComboAsset(Canvas canvas, double w, double h, double holeTop) {
    // 합체 에셋 크기 (셀 안에 맞춤)
    final assetW = w * 0.6;
    final assetH = h * 0.5; // 셀 높이의 50%
    final assetX = (w - assetW) / 2;

    // 팝업 위치 계산
    double assetY;
    double opacity = 1.0;

    if (hole.isRescued) {
      // 그래플링 훅 탈출: 위로 올라감
      final t = hole.rescueAnimProgress.clamp(0.0, 1.0);
      assetY = holeTop - assetH * (1.0 + t * 0.3);
      opacity = 1.0 - t;
    } else {
      // 일반 팝업: 구멍에서 위로
      final pop = hole.popProgress.clamp(0.0, 1.0);
      // pop 0 → 구멍 안 (holeTop), pop 1 → 구멍 위 (holeTop - assetH)
      assetY = holeTop - assetH * pop;
    }

    final color = (hole.isRescued ? _termAmber : _termGreen)
        .withValues(alpha: opacity);
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // ── 스카웃 상반신 (상단 60%) ──
    final scoutTopY = assetY;
    final scoutH = assetH * 0.6;

    // 헬멧 (반원)
    canvas.drawArc(
      Rect.fromLTWH(
          assetX + assetW * 0.2, scoutTopY, assetW * 0.6, scoutH * 0.45),
      pi, pi, false, strokePaint,
    );

    // 헤드램프
    final lampPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(assetX + assetW * 0.5, scoutTopY + scoutH * 0.06),
      2,
      lampPaint,
    );

    // 몸체 (상반신만)
    canvas.drawRect(
      Rect.fromLTWH(assetX + assetW * 0.25, scoutTopY + scoutH * 0.4,
          assetW * 0.5, scoutH * 0.55),
      strokePaint,
    );

    // 팔
    if (hole.isRescued) {
      // 구출: 한 팔 위로 (그래플링 훅) + 다른 팔 아래
      // 오른팔 위로 (그래플링)
      canvas.drawLine(
        Offset(assetX + assetW * 0.75, scoutTopY + scoutH * 0.45),
        Offset(assetX + assetW * 0.85, scoutTopY - scoutH * 0.1),
        strokePaint,
      );
      // 그래플링 훅 와이어 (팔 끝 → 셀 상단)
      final wirePaint = Paint()
        ..color = _termAmber.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(assetX + assetW * 0.85, scoutTopY - scoutH * 0.1),
        Offset(assetX + assetW * 0.85, 0),
        wirePaint,
      );
      // 갈고리 (작은 V)
      canvas.drawLine(
        Offset(assetX + assetW * 0.8, 4),
        Offset(assetX + assetW * 0.85, 0),
        wirePaint,
      );
      canvas.drawLine(
        Offset(assetX + assetW * 0.9, 4),
        Offset(assetX + assetW * 0.85, 0),
        wirePaint,
      );

      // 왼팔 아래
      canvas.drawLine(
        Offset(assetX + assetW * 0.25, scoutTopY + scoutH * 0.45),
        Offset(assetX + assetW * 0.1, scoutTopY + scoutH * 0.7),
        strokePaint,
      );
    } else {
      // SOS 양팔 위로
      canvas.drawLine(
        Offset(assetX + assetW * 0.25, scoutTopY + scoutH * 0.45),
        Offset(assetX, scoutTopY + scoutH * 0.15),
        strokePaint,
      );
      canvas.drawLine(
        Offset(assetX + assetW * 0.75, scoutTopY + scoutH * 0.45),
        Offset(assetX + assetW, scoutTopY + scoutH * 0.15),
        strokePaint,
      );
    }

    // ── 핏죠 턱 (하단 40%) ──
    if (!hole.isRescued) {
      final jawTopY = assetY + assetH * 0.6;
      final jawH = assetH * 0.4;
      final jawPaint = Paint()
        ..color = _termGreenDim.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // V자 이빨 (작은 버전)
      final jawPath = Path();
      jawPath.moveTo(assetX, jawTopY);
      jawPath.lineTo(assetX + assetW * 0.2, jawTopY - jawH * 0.3);
      jawPath.lineTo(assetX + assetW * 0.35, jawTopY);
      jawPath.lineTo(assetX + assetW * 0.5, jawTopY - jawH * 0.2);
      jawPath.lineTo(assetX + assetW * 0.65, jawTopY);
      jawPath.lineTo(assetX + assetW * 0.8, jawTopY - jawH * 0.3);
      jawPath.lineTo(assetX + assetW, jawTopY);
      canvas.drawPath(jawPath, jawPaint);

      // 턱 하단 (스카웃 물고 있는 형태)
      final jawBottomPaint = Paint()
        ..color = _termGreenFaint.withValues(alpha: opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(assetX, jawTopY),
        Offset(assetX + assetW * 0.5, jawTopY + jawH * 0.7),
        jawBottomPaint,
      );
      canvas.drawLine(
        Offset(assetX + assetW, jawTopY),
        Offset(assetX + assetW * 0.5, jawTopY + jawH * 0.7),
        jawBottomPaint,
      );
    }

    // "RESCUED!" 텍스트 떠오르기
    if (hole.isRescued && hole.textFloatProgress < 1.0) {
      final textY = assetY - 5 - hole.textFloatProgress * 15;
      final textOpacity = (1.0 - hole.textFloatProgress).clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: 'RESCUED!',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 6,
            fontWeight: FontWeight.bold,
            color: _termAmber.withValues(alpha: textOpacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((w - tp.width) / 2, textY));
    }

    // 남은 시간 인디케이터
    if (hole.isActive && !hole.isRescued && hole.totalVisibleTime > 0) {
      final barW = w * 0.5;
      final barX = (w - barW) / 2;
      final barY = h - 6;
      final ratio =
          (hole.visibleTimer / hole.totalVisibleTime).clamp(0.0, 1.0);

      canvas.drawRect(
        Rect.fromLTWH(barX, barY, barW, 3),
        Paint()..color = _termGreenFaint.withValues(alpha: 0.3),
      );
      canvas.drawRect(
        Rect.fromLTWH(barX, barY, barW * ratio, 3),
        Paint()
          ..color = ratio < 0.3 ? const Color(0xFFFF4444) : _termGreenDim,
      );
    }
  }

  /// 곡괭이 타격 이펙트 — 크고 명시적인 스윙
  void _drawPickaxe(Canvas canvas, double w, double h, double holeTop) {
    final t = hole.pickaxeProgress.clamp(0.0, 1.0);

    // 곡괭이 위치: 우상단에서 핏죠 턱 위치로 내려침
    final startX = w * 0.85;
    final startY = h * 0.05;
    final endX = w * 0.5;
    final endY = holeTop - h * 0.08;

    // 스윙 단계 (0~0.45: 내려침)
    final strikeT = (t / 0.45).clamp(0.0, 1.0);
    final eased = Curves.easeIn.transform(strikeT);
    final curX = startX + (endX - startX) * eased;
    final curY = startY + (endY - startY) * eased;

    // 곡괭이 회전 (0° → -60° 내려치기)
    final rotation = -1.05 * eased;

    // 스윙 중: 풀 불투명, 임팩트 후: 페이드아웃
    final alpha = t < 0.45 ? 1.0 : (1.0 - ((t - 0.45) / 0.55)).clamp(0.0, 1.0);

    final pickaxePaint = Paint()
      ..color = _termAmber.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final pickaxeFill = Paint()
      ..color = _termAmber.withValues(alpha: alpha * 0.4)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(curX, curY);
    canvas.rotate(rotation);

    // 곡괭이 자루 (두껍고 길게)
    canvas.drawLine(
      const Offset(0, -2),
      const Offset(0, 22),
      pickaxePaint,
    );

    // 곡괭이 머리 — 두꺼운 T자 + 곡선 날
    final headPaint = Paint()
      ..color = _termAmber.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    // 가로 날
    canvas.drawLine(const Offset(-12, 0), const Offset(12, 0), headPaint);
    // 좌측 날 끝 (곡선 효과)
    canvas.drawLine(const Offset(-12, 0), const Offset(-14, 5), headPaint);
    // 우측 날 끝
    canvas.drawLine(const Offset(12, 0), const Offset(14, 5), headPaint);
    // 날 꼭지 (삼각형)
    final tipPath = Path()
      ..moveTo(-14, 5)
      ..lineTo(-12, 8)
      ..lineTo(-10, 5);
    canvas.drawPath(tipPath, pickaxeFill);
    final tipPath2 = Path()
      ..moveTo(14, 5)
      ..lineTo(12, 8)
      ..lineTo(10, 5);
    canvas.drawPath(tipPath2, pickaxeFill);

    canvas.restore();

    // 스윙 궤적 (잔상) — 스윙 진행 중일 때
    if (t < 0.45 && t > 0.1) {
      final trailPaint = Paint()
        ..color = _termAmber.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      // 이전 위치에서 현재까지 궤적
      final prevT = (t - 0.08).clamp(0.0, 1.0);
      final prevEased = Curves.easeIn.transform((prevT / 0.45).clamp(0.0, 1.0));
      final prevX = startX + (endX - startX) * prevEased;
      final prevY = startY + (endY - startY) * prevEased;
      canvas.drawLine(Offset(prevX, prevY), Offset(curX, curY), trailPaint);
    }

    // ── 임팩트 이펙트 (0.45 이후) ──
    if (t >= 0.45) {
      final impactT = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
      final impactAlpha = (1.0 - impactT).clamp(0.0, 1.0);

      // 충격파 원 (확산)
      final ringPaint = Paint()
        ..color = _termAmber.withValues(alpha: impactAlpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      final ringR = 8.0 + impactT * w * 0.25;
      canvas.drawCircle(Offset(endX, endY), ringR, ringPaint);

      // 방사형 충격선 (8방향, 더 길게)
      final sparkPaint = Paint()
        ..color = _termAmber.withValues(alpha: impactAlpha * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final angle = (i * pi / 4) + pi / 8;
        final innerR = 4.0 + impactT * 8.0;
        final outerR = 10.0 + impactT * w * 0.2;
        canvas.drawLine(
          Offset(endX + cos(angle) * innerR, endY + sin(angle) * innerR),
          Offset(endX + cos(angle) * outerR, endY + sin(angle) * outerR),
          sparkPaint,
        );
      }

      // 별 모양 스파크 (십자)
      if (impactT < 0.6) {
        final starAlpha = (1.0 - impactT / 0.6) * 0.8;
        final starPaint = Paint()
          ..color = Colors.white.withValues(alpha: starAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        final starR = 5.0 + impactT * 15.0;
        canvas.drawLine(
          Offset(endX - starR, endY),
          Offset(endX + starR, endY),
          starPaint,
        );
        canvas.drawLine(
          Offset(endX, endY - starR),
          Offset(endX, endY + starR),
          starPaint,
        );
      }
    }
  }

  /// 터미널 스타일 히트 이펙트 — "██ HIT! ██" + 파티클
  void _drawHitEffect(Canvas canvas, double w, double h, double holeTop) {
    final t = hole.hitFlashProgress.clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0);

    // ── "██ HIT! ██" 텍스트 (셀 중앙, 위로 떠오름) ──
    final textY = holeTop * 0.35 - t * 12.0;
    final hitTp = TextPainter(
      text: TextSpan(
        text: '██ HIT! ██',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: _termAmber.withValues(alpha: alpha),
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hitTp.paint(canvas, Offset((w - hitTp.width) / 2, textY));

    // ── 터미널 파티클 (블록 문자들 흩뿌리기) ──
    final chars = ['█', '▓', '▒', '░', '✦', '⚡', '*'];
    final seed = (hole.pickaxeProgress * 1000).toInt();
    final rng = Random(seed);
    for (int i = 0; i < 6; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = 10.0 + t * (25.0 + rng.nextDouble() * 20.0);
      final px = w * 0.5 + cos(angle) * dist;
      final py = holeTop - h * 0.08 + sin(angle) * dist;
      final charAlpha = (alpha * (0.5 + rng.nextDouble() * 0.5)).clamp(0.0, 1.0);
      if (charAlpha < 0.05) continue;

      final tp = TextPainter(
        text: TextSpan(
          text: chars[i % chars.length],
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 6 + rng.nextDouble() * 4,
            color: (i % 2 == 0 ? _termAmber : _termGreen)
                .withValues(alpha: charAlpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px, py));
    }
  }

  @override
  bool shouldRepaint(covariant HolePainter oldDelegate) => true;
}
