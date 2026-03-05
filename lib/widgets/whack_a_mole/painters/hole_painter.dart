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
// 함정(decoy): 새빨간색
const _nitraRed = Color(0xFFFF1111);
const _nitraRedDim = Color(0xFFCC0000);
const _goldenColor = Color(0xFFFFD700);

// ═══════════════════════════════════════════════════════════════════════════
//  게임플레이 구멍 페인터
//  - 등장 예고 (개미지옥 흔들림)
//  - 핏죠 턱 + 스카웃 합체, 곡괭이, 그래플링훅
//  - 함정(빨간 decoy), 골든, 멀티탭 크랙
//  - 스냅 애니메이션 (타임아웃 시 턱 닫힘)
// ═══════════════════════════════════════════════════════════════════════════
class HolePainter extends CustomPainter {
  final MoleHole hole;
  final int blinkCounter;

  HolePainter({required this.hole, required this.blinkCounter});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));

    // 구멍 위치 (하단 35%)
    final holeTop = h * 0.65;
    final holeRect = Rect.fromLTWH(w * 0.1, holeTop, w * 0.8, h * 0.28);

    // ── 함정(decoy): 빨간 글로우 (구멍 주변) ──
    if (hole.moleType == MoleType.decoy && hole.isActive && !hole.isSnapping) {
      final glowAlpha = 0.15 + 0.1 * sin(blinkCounter * 0.2);
      final glowPaint = Paint()
        ..color = _nitraRed.withValues(alpha: glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawOval(holeRect.inflate(4), glowPaint);

      // 광맥 결정 라인 (구멍 주변에 뻗어나온 빨간 결)
      final veinPaint = Paint()
        ..color = _nitraRedDim.withValues(alpha: 0.5 + 0.2 * sin(blinkCounter * 0.15))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final cx = w * 0.5;
      final cy = holeTop + h * 0.14;
      // 좌측 결정
      canvas.drawLine(Offset(w * 0.08, cy - 4), Offset(w * 0.18, cy + 2), veinPaint);
      canvas.drawLine(Offset(w * 0.18, cy + 2), Offset(w * 0.12, cy + 8), veinPaint);
      // 우측 결정
      canvas.drawLine(Offset(w * 0.92, cy - 2), Offset(w * 0.82, cy + 4), veinPaint);
      canvas.drawLine(Offset(w * 0.82, cy + 4), Offset(w * 0.88, cy + 10), veinPaint);
      // 상단 결정
      canvas.drawLine(Offset(cx - 8, holeTop - 6), Offset(cx - 2, holeTop - 1), veinPaint);
      canvas.drawLine(Offset(cx + 8, holeTop - 5), Offset(cx + 3, holeTop - 1), veinPaint);
    }

    // 구멍 배경
    final holeBgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.black, _termBg],
      ).createShader(holeRect);
    canvas.drawOval(holeRect, holeBgPaint);

    // 구멍 테두리 — 함정은 새빨간 테두리
    Color borderColor;
    double borderWidth = 1.5;
    if (hole.moleType == MoleType.decoy && hole.isActive) {
      borderColor = _nitraRed.withValues(alpha: 0.7 + 0.3 * sin(blinkCounter * 0.2));
      borderWidth = 2.0;
    } else {
      borderColor = _termGreenDim.withValues(alpha: 0.6);
    }
    final holeBorderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawOval(holeRect, holeBorderPaint);

    // 이빨 (구멍 상단)
    final toothColor = hole.moleType == MoleType.decoy && hole.isActive
        ? _nitraRedDim.withValues(alpha: 0.6)
        : _termGreenDim.withValues(alpha: 0.4);
    final toothPaint = Paint()
      ..color = toothColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // ── 등장 예고: 이빨 흔들림 ──
    if (hole.warningTimer > 0 && hole.isActive) {
      _drawWarningTeeth(canvas, w, h, holeTop, toothPaint);
    } else {
      // 일반 이빨
      for (int i = 0; i < 4; i++) {
        final tx = w * (0.2 + i * 0.18);
        canvas.drawLine(
          Offset(tx, holeTop + 2),
          Offset(tx + w * 0.04, holeTop - 3),
          toothPaint,
        );
      }
    }

    // ── 스냅 애니메이션 (턱이 닫힘) ──
    if (hole.isSnapping) {
      _drawSnapAnimation(canvas, w, h, holeTop);
    }
    // 스카웃 + 핏죠 합체 팝업 (예고 중에는 표시 안함, 스냅 중에도 안함)
    else if ((hole.isActive && hole.warningTimer <= 0) || hole.isRescued) {
      _drawComboAsset(canvas, w, h, holeTop);
    }

    // 곡괭이 타격 이펙트
    if (hole.pickaxeProgress > 0 && hole.pickaxeProgress < 1.0) {
      _drawPickaxe(canvas, w, h, holeTop);
    }

    // 히트 이펙트
    if (hole.hitFlashProgress > 0 && hole.hitFlashProgress < 1.0) {
      _drawHitEffect(canvas, w, h, holeTop);
    }

    canvas.restore();
  }

  /// 등장 예고: 이빨이 위아래로 흔들리며 긁적거림
  void _drawWarningTeeth(
      Canvas canvas, double w, double h, double holeTop, Paint basePaint) {
    final warnProgress = hole.warningDuration > 0
        ? 1.0 - (hole.warningTimer / hole.warningDuration)
        : 0.0;
    // 흔들림 강도: 시간이 지날수록 증가
    final shakeAmp = 1.0 + warnProgress * 3.0;
    final shakeFreq = 8.0 + warnProgress * 12.0;

    // 이빨이 점점 높이 올라오며 흔들림
    final peekAmount = warnProgress * 4.0; // 최대 4px 올라옴

    // 함정이면 빨간 이빨
    final paint = hole.moleType == MoleType.decoy
        ? (Paint()
          ..color = _nitraRed.withValues(alpha: 0.4 + warnProgress * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 + warnProgress * 0.5)
        : basePaint;

    for (int i = 0; i < 4; i++) {
      final tx = w * (0.2 + i * 0.18);
      final shake = sin(blinkCounter * shakeFreq * 0.1 + i * 1.5) * shakeAmp;
      canvas.drawLine(
        Offset(tx + shake, holeTop + 2 - peekAmount),
        Offset(tx + w * 0.04 + shake * 0.5, holeTop - 3 - peekAmount),
        paint,
      );
    }

    // 구멍에서 먼지 파티클 (흔들림 시)
    if (warnProgress > 0.3) {
      final dustAlpha = (warnProgress - 0.3) * 0.5;
      final dustPaint = Paint()
        ..color = (hole.moleType == MoleType.decoy ? _nitraRedDim : _termGreenDim)
            .withValues(alpha: dustAlpha);
      final rng = Random(blinkCounter ~/ 3);
      for (int i = 0; i < 3; i++) {
        final dx = w * 0.2 + rng.nextDouble() * w * 0.6;
        final dy = holeTop - 2 - rng.nextDouble() * peekAmount * 2;
        canvas.drawCircle(Offset(dx, dy), 1.0 + rng.nextDouble(), dustPaint);
      }
    }
  }

  /// 스냅 애니메이션: 턱이 위에서 덮쳐 닫힘 + "SNAP!" 텍스트
  void _drawSnapAnimation(Canvas canvas, double w, double h, double holeTop) {
    final t = hole.snapProgress.clamp(0.0, 1.0);
    // 턱 닫힘: 위에서 아래로 빠르게
    final jawCloseT = Curves.easeIn.transform(min(t * 2.0, 1.0));
    // 흔들림: 닫힌 후
    final shakeT = max(t - 0.5, 0.0) * 2.0;

    final assetW = w * 0.6;
    final assetX = (w - assetW) / 2;
    final jawY = holeTop - h * 0.15 * (1.0 - jawCloseT);

    // 상단 턱 (위에서 내려옴)
    final jawColor = hole.moleType == MoleType.decoy
        ? _nitraRed
        : _termGreenDim;
    final jawPaint = Paint()
      ..color = jawColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // 흔들림 오프셋
    final shakeX = shakeT > 0 ? sin(shakeT * 20) * 2.0 * (1.0 - shakeT) : 0.0;

    // 상단 V자 이빨
    final topJaw = Path();
    topJaw.moveTo(assetX + shakeX, jawY);
    topJaw.lineTo(assetX + assetW * 0.2 + shakeX, jawY + 8);
    topJaw.lineTo(assetX + assetW * 0.35 + shakeX, jawY);
    topJaw.lineTo(assetX + assetW * 0.5 + shakeX, jawY + 6);
    topJaw.lineTo(assetX + assetW * 0.65 + shakeX, jawY);
    topJaw.lineTo(assetX + assetW * 0.8 + shakeX, jawY + 8);
    topJaw.lineTo(assetX + assetW + shakeX, jawY);
    canvas.drawPath(topJaw, jawPaint);

    // 하단 V자 이빨 (구멍 위치에서)
    final bottomJaw = Path();
    final bJawY = holeTop + 4;
    bottomJaw.moveTo(assetX + shakeX, bJawY);
    bottomJaw.lineTo(assetX + assetW * 0.15 + shakeX, bJawY - 6);
    bottomJaw.lineTo(assetX + assetW * 0.3 + shakeX, bJawY);
    bottomJaw.lineTo(assetX + assetW * 0.5 + shakeX, bJawY - 5);
    bottomJaw.lineTo(assetX + assetW * 0.7 + shakeX, bJawY);
    bottomJaw.lineTo(assetX + assetW * 0.85 + shakeX, bJawY - 6);
    bottomJaw.lineTo(assetX + assetW + shakeX, bJawY);
    canvas.drawPath(bottomJaw, jawPaint);

    // "SNAP!" 텍스트 (닫힌 후 표시)
    if (t > 0.4) {
      final textAlpha = ((t - 0.4) / 0.3).clamp(0.0, 1.0) * (1.0 - max(t - 0.7, 0.0) / 0.3);
      final snapColor = hole.moleType == MoleType.decoy ? _nitraRed : _termAmber;
      final tp = TextPainter(
        text: TextSpan(
          text: 'SNAP!',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: snapColor.withValues(alpha: textAlpha.clamp(0.0, 1.0)),
            letterSpacing: 2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((w - tp.width) / 2, holeTop - h * 0.25));
    }
  }

  /// 몰 타입별 주 색상
  Color _moleColor(double opacity) {
    switch (hole.moleType) {
      case MoleType.decoy:
        return _nitraRed.withValues(alpha: opacity);
      case MoleType.golden:
        return _goldenColor.withValues(alpha: opacity);
      case MoleType.normal:
        return _termGreen.withValues(alpha: opacity);
    }
  }

  /// 핏죠 턱 + 스카웃 상반신 합체 에셋
  void _drawComboAsset(Canvas canvas, double w, double h, double holeTop) {
    final assetW = w * 0.6;
    final assetH = h * 0.5;
    final assetX = (w - assetW) / 2;

    double assetY;
    double opacity = 1.0;

    if (hole.isRescued) {
      final t = hole.rescueAnimProgress.clamp(0.0, 1.0);
      assetY = holeTop - assetH * (1.0 + t * 0.3);
      opacity = 1.0 - t;
    } else {
      // elasticOut 이징
      final rawPop = hole.popProgress.clamp(0.0, 1.0);
      final pop = Curves.elasticOut.transform(rawPop);
      assetY = holeTop - assetH * pop;
    }

    final color = (hole.isRescued ? _termAmber : _moleColor(1.0))
        .withValues(alpha: opacity);
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = hole.moleType == MoleType.decoy ? 2.0 : 1.5;

    // ── 스카웃 상반신 (상단 60%) ──
    final scoutTopY = assetY;
    final scoutH = assetH * 0.6;

    // 헬멧 (반원)
    canvas.drawArc(
      Rect.fromLTWH(
          assetX + assetW * 0.2, scoutTopY, assetW * 0.6, scoutH * 0.45),
      pi, pi, false, strokePaint,
    );

    // 헤드램프 — 골든은 별 글로우
    if (hole.moleType == MoleType.golden) {
      final glowPaint = Paint()
        ..color = _goldenColor.withValues(alpha: opacity * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(
        Offset(assetX + assetW * 0.5, scoutTopY + scoutH * 0.06),
        5, glowPaint,
      );
      final starPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final cx = assetX + assetW * 0.5;
      final cy = scoutTopY + scoutH * 0.06;
      canvas.drawLine(Offset(cx - 4, cy), Offset(cx + 4, cy), starPaint);
      canvas.drawLine(Offset(cx, cy - 4), Offset(cx, cy + 4), starPaint);
    } else {
      final lampPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(assetX + assetW * 0.5, scoutTopY + scoutH * 0.06),
        2, lampPaint,
      );
    }

    // 함정(decoy): 빨간 경고 깜빡임 + "TRAP" 라벨
    if (hole.moleType == MoleType.decoy && !hole.isRescued) {
      // 빨간 글로우 오라
      final auraPaint = Paint()
        ..color = _nitraRed.withValues(
            alpha: opacity * (0.15 + 0.1 * sin(blinkCounter * 0.25)))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRect(
        Rect.fromLTWH(assetX - 4, scoutTopY - 2, assetW + 8, assetH * 0.7),
        auraPaint,
      );

      // "TRAP" 라벨 (깜빡임)
      final labelAlpha =
          opacity * (blinkCounter % 16 < 8 ? 1.0 : 0.4);
      final labelTp = TextPainter(
        text: TextSpan(
          text: 'TRAP',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 7,
            fontWeight: FontWeight.w900,
            color: _nitraRed.withValues(alpha: labelAlpha),
            letterSpacing: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelTp.paint(
          canvas, Offset((w - labelTp.width) / 2, scoutTopY - 10));
    }

    // 몸체 (상반신만)
    canvas.drawRect(
      Rect.fromLTWH(assetX + assetW * 0.25, scoutTopY + scoutH * 0.4,
          assetW * 0.5, scoutH * 0.55),
      strokePaint,
    );

    // 팔
    if (hole.isRescued) {
      canvas.drawLine(
        Offset(assetX + assetW * 0.75, scoutTopY + scoutH * 0.45),
        Offset(assetX + assetW * 0.85, scoutTopY - scoutH * 0.1),
        strokePaint,
      );
      final wirePaint = Paint()
        ..color = _termAmber.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(assetX + assetW * 0.85, scoutTopY - scoutH * 0.1),
        Offset(assetX + assetW * 0.85, 0),
        wirePaint,
      );
      canvas.drawLine(Offset(assetX + assetW * 0.8, 4),
          Offset(assetX + assetW * 0.85, 0), wirePaint);
      canvas.drawLine(Offset(assetX + assetW * 0.9, 4),
          Offset(assetX + assetW * 0.85, 0), wirePaint);
      canvas.drawLine(
        Offset(assetX + assetW * 0.25, scoutTopY + scoutH * 0.45),
        Offset(assetX + assetW * 0.1, scoutTopY + scoutH * 0.7),
        strokePaint,
      );
    } else {
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
      final jawColor = hole.moleType == MoleType.decoy
          ? _nitraRed.withValues(alpha: opacity)
          : hole.moleType == MoleType.golden
              ? _goldenColor.withValues(alpha: opacity * 0.7)
              : _termGreenDim.withValues(alpha: opacity);
      final jawStroke = hole.moleType == MoleType.decoy ? 2.5 : 1.5;
      final jawPaint = Paint()
        ..color = jawColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = jawStroke;

      final jawPath = Path();
      jawPath.moveTo(assetX, jawTopY);
      jawPath.lineTo(assetX + assetW * 0.2, jawTopY - jawH * 0.3);
      jawPath.lineTo(assetX + assetW * 0.35, jawTopY);
      jawPath.lineTo(assetX + assetW * 0.5, jawTopY - jawH * 0.2);
      jawPath.lineTo(assetX + assetW * 0.65, jawTopY);
      jawPath.lineTo(assetX + assetW * 0.8, jawTopY - jawH * 0.3);
      jawPath.lineTo(assetX + assetW, jawTopY);
      canvas.drawPath(jawPath, jawPaint);

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

      // 멀티탭 크랙 이펙트
      if (hole.hitsTaken > 0 && hole.hitsTaken < hole.hitsRequired) {
        final crackPaint = Paint()
          ..color = _termAmber.withValues(alpha: opacity * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        final cx = assetX + assetW * 0.5;
        final cy = jawTopY;
        canvas.drawLine(Offset(cx - 6, cy - 4), Offset(cx, cy + 2), crackPaint);
        canvas.drawLine(Offset(cx, cy + 2), Offset(cx + 4, cy - 3), crackPaint);
        canvas.drawLine(Offset(cx + 4, cy - 3), Offset(cx + 8, cy + 1), crackPaint);
        final hitTp = TextPainter(
          text: TextSpan(
            text: '${hole.hitsTaken}/${hole.hitsRequired}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 6,
              fontWeight: FontWeight.bold,
              color: _termAmber.withValues(alpha: opacity * 0.9),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        hitTp.paint(canvas,
            Offset(assetX + assetW * 0.5 - hitTp.width / 2, jawTopY + 6));
      }
    }

    // "RESCUED!" 텍스트
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
    if (hole.isActive && !hole.isRescued && !hole.isSnapping &&
        hole.warningTimer <= 0 && hole.totalVisibleTime > 0) {
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

  /// 곡괭이 타격 이펙트
  void _drawPickaxe(Canvas canvas, double w, double h, double holeTop) {
    final t = hole.pickaxeProgress.clamp(0.0, 1.0);

    final startX = w * 0.85;
    final startY = h * 0.05;
    final endX = w * 0.5;
    final endY = holeTop - h * 0.08;

    final strikeT = (t / 0.45).clamp(0.0, 1.0);
    final eased = Curves.easeIn.transform(strikeT);
    final curX = startX + (endX - startX) * eased;
    final curY = startY + (endY - startY) * eased;
    final rotation = -1.05 * eased;
    final alpha =
        t < 0.45 ? 1.0 : (1.0 - ((t - 0.45) / 0.55)).clamp(0.0, 1.0);

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

    canvas.drawLine(const Offset(0, -2), const Offset(0, 22), pickaxePaint);

    final headPaint = Paint()
      ..color = _termAmber.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-12, 0), const Offset(12, 0), headPaint);
    canvas.drawLine(const Offset(-12, 0), const Offset(-14, 5), headPaint);
    canvas.drawLine(const Offset(12, 0), const Offset(14, 5), headPaint);
    final tipPath = Path()..moveTo(-14, 5)..lineTo(-12, 8)..lineTo(-10, 5);
    canvas.drawPath(tipPath, pickaxeFill);
    final tipPath2 = Path()..moveTo(14, 5)..lineTo(12, 8)..lineTo(10, 5);
    canvas.drawPath(tipPath2, pickaxeFill);

    canvas.restore();

    if (t < 0.45 && t > 0.1) {
      final trailPaint = Paint()
        ..color = _termAmber.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final prevT = (t - 0.08).clamp(0.0, 1.0);
      final prevEased = Curves.easeIn.transform((prevT / 0.45).clamp(0.0, 1.0));
      final prevX = startX + (endX - startX) * prevEased;
      final prevY = startY + (endY - startY) * prevEased;
      canvas.drawLine(Offset(prevX, prevY), Offset(curX, curY), trailPaint);
    }

    if (t >= 0.45) {
      final impactT = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
      final impactAlpha = (1.0 - impactT).clamp(0.0, 1.0);

      final ringPaint = Paint()
        ..color = _termAmber.withValues(alpha: impactAlpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(endX, endY), 8.0 + impactT * w * 0.25, ringPaint);

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

      if (impactT < 0.6) {
        final starAlpha = (1.0 - impactT / 0.6) * 0.8;
        final starPaint = Paint()
          ..color = Colors.white.withValues(alpha: starAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        final starR = 5.0 + impactT * 15.0;
        canvas.drawLine(Offset(endX - starR, endY), Offset(endX + starR, endY), starPaint);
        canvas.drawLine(Offset(endX, endY - starR), Offset(endX, endY + starR), starPaint);
      }
    }
  }

  /// 히트 이펙트 텍스트 + 파티클
  void _drawHitEffect(Canvas canvas, double w, double h, double holeTop) {
    final t = hole.hitFlashProgress.clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0);

    final hitText = hole.moleType == MoleType.decoy
        ? 'TRAP!'
        : hole.moleType == MoleType.golden
            ? 'GOLD!'
            : (hole.hitsTaken < hole.hitsRequired ? 'CRACK!' : 'HIT!');
    final hitColor = hole.moleType == MoleType.decoy
        ? _nitraRed
        : hole.moleType == MoleType.golden
            ? _goldenColor
            : _termAmber;

    final textY = holeTop * 0.35 - t * 12.0;
    final hitTp = TextPainter(
      text: TextSpan(
        text: hitText,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: hitColor.withValues(alpha: alpha),
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hitTp.paint(canvas, Offset((w - hitTp.width) / 2, textY));

    final chars = ['█', '▓', '▒', '░', '✦', '⚡', '*'];
    final seed = (hole.pickaxeProgress * 1000).toInt();
    final rng = Random(seed);
    for (int i = 0; i < 6; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = 10.0 + t * (25.0 + rng.nextDouble() * 20.0);
      final px = w * 0.5 + cos(angle) * dist;
      final py = holeTop - h * 0.08 + sin(angle) * dist;
      final charAlpha =
          (alpha * (0.5 + rng.nextDouble() * 0.5)).clamp(0.0, 1.0);
      if (charAlpha < 0.05) continue;

      final tp = TextPainter(
        text: TextSpan(
          text: chars[i % chars.length],
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 6 + rng.nextDouble() * 4,
            color: (i % 2 == 0 ? hitColor : _termGreen)
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
