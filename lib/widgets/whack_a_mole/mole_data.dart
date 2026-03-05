// ── 게임 페이즈 ──
enum GamePhase { intro, ready, playing, gameOver }

// ── 몰 타입 (4-1: 디코이/나이트라, 4-2: 골든) ──
enum MoleType { normal, decoy, golden }

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

  // ── 몰 타입 ──
  MoleType moleType = MoleType.normal;

  // ── 멀티탭 강화 몰 ──
  int hitsRequired = 1;
  int hitsTaken = 0;

  // ── 등장 예고 (개미지옥) ──
  double warningTimer = 0.0; // >0이면 예고 중 (흔들림), 0이면 팝업 시작
  double warningDuration = 0.0; // 원래 예고 시간

  // ── 스냅 애니메이션 (타임아웃 시 턱이 닫힘) ──
  double snapProgress = 0.0; // 0=시작, 1=완료
  bool isSnapping = false;

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
    moleType = MoleType.normal;
    hitsRequired = 1;
    hitsTaken = 0;
    warningTimer = 0.0;
    warningDuration = 0.0;
    snapProgress = 0.0;
    isSnapping = false;
  }
}
