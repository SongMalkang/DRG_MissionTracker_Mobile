import 'package:flutter/material.dart';

/// 게임 공통 터미널 CRT 색상 팔레트
/// JetBoots, Whack-a-Mole, Survivor 미니게임에서 공유
class GameColors {
  GameColors._();

  // ── 터미널 녹색 팔레트 (JetBoots / Whack-a-Mole) ─────────────────────
  static const Color termGreen = Color(0xFF39FF14);
  static const Color termGreenDim = Color(0xFF1A8A0A);
  static const Color termGreenFaint = Color(0xFF0D4D06);
  static const Color termBg = Color(0xFF040A04);
  static const Color termSurface = Color(0xFF081208);
  static const Color termAmber = Color(0xFFFFBF00);

  // ── Survivor 팔레트 (약간 다른 녹색 톤) ────────────────────────────────
  static const Color survivorGreen = Color(0xFF00FF41);
  static const Color survivorBg = Color(0xFF0A0E0A);
  static const Color survivorAmber = Color(0xFFFFB000);
  static const Color survivorRed = Color(0xFFFF3333);
}
