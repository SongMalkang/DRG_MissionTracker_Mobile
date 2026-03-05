// ─── 슬릿 데이터 ────────────────────────────────────────────────────────────

class Slit {
  double x; // 화면 비율 X 위치
  double gapCenter; // 슬릿 중심 (0.0~1.0)
  bool fromLeft; // 기둥이 왼쪽에서 뻗는지 (half-pillar)
  bool passed = false; // 통과 여부

  // ── 진동 슬릿 (스테이지 3+) ──
  double oscillateAmplitude; // 0.0 = 정적
  double oscillateSpeed;
  double oscillatePhase;

  // ── 갭 크기 배율 (교대 패턴) ──
  double gapSizeMultiplier;

  // ── 니어미스 ──
  bool nearMissTriggered = false;

  Slit({
    required this.x,
    required this.gapCenter,
    required this.fromLeft,
    this.oscillateAmplitude = 0.0,
    this.oscillateSpeed = 0.0,
    this.oscillatePhase = 0.0,
    this.gapSizeMultiplier = 1.0,
  });

  /// 시간 기반 실효 갭 중심 계산
  double effectiveGapCenter(double time) {
    if (oscillateAmplitude <= 0.0) return gapCenter;
    final offset =
        oscillateAmplitude * _sin(time * oscillateSpeed + oscillatePhase);
    return (gapCenter + offset).clamp(0.15, 0.85);
  }
}

/// dart:math 없이 간단한 sin 근사 (테일러 급수)
/// slit_data 단독 파일이므로 dart:math import 최소화
double _sin(double x) {
  // Normalize to [-pi, pi]
  const pi = 3.14159265358979;
  x = x % (2 * pi);
  if (x > pi) x -= 2 * pi;
  if (x < -pi) x += 2 * pi;
  // Taylor series (enough precision for game visuals)
  final x3 = x * x * x;
  final x5 = x3 * x * x;
  final x7 = x5 * x * x;
  return x - x3 / 6.0 + x5 / 120.0 - x7 / 5040.0;
}
