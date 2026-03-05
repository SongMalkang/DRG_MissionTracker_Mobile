import 'dart:math';
import 'package:flutter/material.dart';
import '../../../utils/game_colors.dart';

// 터미널 녹색 색상 팔레트 (GameColors에서 참조)
const _termGreenFaint = GameColors.termGreenFaint;

// ─── CRT 배경 페인터 (그리드 + 미세한 녹색 노이즈) ───────────────────────────

class CrtBackgroundPainter extends CustomPainter {
  /// 4-5: 스테이지 기반 앰버 틴트 (0.0 = 순수 그린, 1.0 = 앰버)
  final double amberTint;

  CrtBackgroundPainter({this.amberTint = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    // 4-5: 고스테이지 앰버 배경 틴트
    if (amberTint > 0.0) {
      final amberPaint = Paint()
        ..color = GameColors.termAmber.withValues(alpha: 0.03 * amberTint);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), amberPaint);
    }

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
  bool shouldRepaint(CrtBackgroundPainter oldDelegate) =>
      oldDelegate.amberTint != amberTint;
}

// ─── CRT 스캔라인 오버레이 ──────────────────────────────────────────────────

class ScanlinePainter extends CustomPainter {
  /// 4-2: 스테이지 전환 글리치 효과
  final bool stageFlash;

  ScanlinePainter({this.stageFlash = false});

  @override
  void paint(Canvas canvas, Size size) {
    // 기본 스캔라인
    final alpha = stageFlash ? 0.2 : 0.08;
    final thickness = stageFlash ? 2.0 : 1.0;
    final spacing = stageFlash ? 3.0 : 3.0;
    final paint = Paint()..color = Colors.black.withValues(alpha: alpha);
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, thickness), paint);
    }

    // 4-2: 글리치 밴드 (스테이지 전환 시 2~3개 수평 오프셋)
    if (stageFlash) {
      final rng = Random(42); // 고정 시드: 매 프레임 동일 위치
      final glitchPaint = Paint()
        ..color = GameColors.termGreen.withValues(alpha: 0.12);
      for (int i = 0; i < 3; i++) {
        final bandY = rng.nextDouble() * size.height;
        final bandH = 4.0 + rng.nextDouble() * 8.0;
        final offsetX = (rng.nextDouble() - 0.5) * 12.0;
        canvas.drawRect(
          Rect.fromLTWH(offsetX, bandY, size.width, bandH),
          glitchPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ScanlinePainter oldDelegate) =>
      oldDelegate.stageFlash != stageFlash;
}

// ─── 니어미스 테두리 플래시 오버레이 ─────────────────────────────────────────

class NearMissBorderPainter extends CustomPainter {
  final double intensity; // 0.0~1.0

  NearMissBorderPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.0) return;

    final borderWidth = 3.0;
    final paint = Paint()
      ..color = GameColors.termGreen.withValues(alpha: 0.6 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // 상단
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, borderWidth), paint);
    // 하단
    canvas.drawRect(
        Rect.fromLTWH(0, size.height - borderWidth, size.width, borderWidth),
        paint);
    // 좌
    canvas.drawRect(Rect.fromLTWH(0, 0, borderWidth, size.height), paint);
    // 우
    canvas.drawRect(
        Rect.fromLTWH(size.width - borderWidth, 0, borderWidth, size.height),
        paint);
  }

  @override
  bool shouldRepaint(NearMissBorderPainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}

// ─── 추진 파티클 페인터 ──────────────────────────────────────────────────────

class Particle {
  double x, y, vx, vy, life;
  Particle(this.x, this.y, this.vx, this.vy, this.life);
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final alpha = (p.life).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = const Color(0xFFFF6600).withValues(alpha: alpha * 0.8);
      canvas.drawCircle(Offset(p.x, p.y), 1.5 + alpha, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
