// ─── 슬릿 데이터 ────────────────────────────────────────────────────────────

class Slit {
  double x; // 화면 비율 X 위치
  double gapCenter; // 슬릿 중심 (0.0~1.0)
  bool fromLeft; // 기둥이 왼쪽에서 뻗는지 (현재 미사용, 확장용)
  bool passed = false; // 통과 여부

  Slit({
    required this.x,
    required this.gapCenter,
    required this.fromLeft,
  });
}
