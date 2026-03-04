// ── 게임 페이즈 ──
enum GamePhase { intro, ready, playing, gameOver }

// ── 구멍 데이터 ──
class MoleHole {
  bool isActive = false;
  double popProgress = 0.0; // 0.0(숨김) ~ 1.0(완전 노출)
  bool isRescued = false;
  double visibleTimer = 0.0;
  double totalVisibleTime = 0.0;
  // 곡괭이 타격 애니메이션
  double pickaxeProgress = 0.0; // 0=없음, >0=진행중(0~1)
  bool hitSoundPlayed = false; // 타격 사운드 재생 여부
  // 타격 히트 플래시 이펙트
  double hitFlashProgress = 0.0; // 0=없음, 0~1=진행중
  // 구출 그래플링 훅 애니메이션
  double rescueAnimProgress = 0.0; // 0~1
  // "RESCUED!" 텍스트 떠오르기
  double textFloatProgress = 0.0;

  void reset() {
    isActive = false;
    popProgress = 0.0;
    isRescued = false;
    visibleTimer = 0.0;
    totalVisibleTime = 0.0;
    pickaxeProgress = 0.0;
    hitSoundPlayed = false;
    hitFlashProgress = 0.0;
    rescueAnimProgress = 0.0;
    textFloatProgress = 0.0;
  }
}
