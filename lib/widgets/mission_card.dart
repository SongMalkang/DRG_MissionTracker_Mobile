import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../utils/strings.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;
  final String lang;

  const MissionCard({super.key, required this.mission, required this.lang});

  // [Req 1] 부드러운 애니메이션 커스텀 팝업
  void _showMissionDetails(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true, // 바깥 영역 터치 시 닫힘
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.7), // 뒷배경 어둡게
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400), // [Req 4] 폴드/태블릿 대응 (최대 너비 제한)
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212), // 앱 배경색 (시인성 확보)
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Header (Bg + Shading + White Text)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: Stack(
                        children: [
                          Container(
                            height: 100,
                            color: Colors.grey[800], // 임시 바이옴 이미지 자리
                            child: Center(child: Text('[ ${mission.biome} 이미지(PNG) ]', style: const TextStyle(color: Colors.white24))),
                          ),
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, const Color(0xFF121212).withOpacity(0.95)],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12, left: 16,
                            child: Text('${mission.missionType} - ${mission.biome}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                    // 2. Body (미션 상세 정보)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${i18n[lang]!['length']}: ${mission.length}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              Text('${i18n[lang]!['complexity']}: ${mission.complexity}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (mission.buff != null) Text('+ ${mission.buff}', style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 14)),
                          if (mission.debuff != null) Text('- ${mission.debuff}', style: const TextStyle(color: Colors.red, fontSize: 14)),
                          const SizedBox(height: 16),
                          
                          // 3. Warning Area (주의사항 구역)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.05),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(6)
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('⚠️ 바이옴: [ 예: 모래 폭풍으로 시야 제한 ]', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                                SizedBox(height: 6),
                                Text('⚠️ 미션: [ 예: 알을 파낼 때 스웜 발생 위험 ]', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    // 4. Footer (최하단 닫기 버튼)
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10))
                        ),
                        child: Text(i18n[lang]!['close']!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
      // 튀어나오는 애니메이션 정의
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value), // 살짝 커졌다가 줄어드는 탄성 효과
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDoubleXp = mission.buff == "Double XP";
    
    // [Req 4] 리스트 카드도 폴드 대응을 위해 가로 길이 제한
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDoubleXp ? Colors.amber : Colors.white24, width: isDoubleXp ? 2 : 1),
            boxShadow: isDoubleXp ? [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)] : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showMissionDetails(context),
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Center(child: Text('[ ${mission.biome} 이미지 ]', style: const TextStyle(color: Colors.white10, fontSize: 18))),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      // ... (이하 Row 내부 코드는 이전과 완전히 동일합니다)
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(mission.missionType, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(mission.biome, style: const TextStyle(fontSize: 12, color: Colors.orange)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${i18n[lang]!['length']}: ${mission.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('${i18n[lang]!['complexity']}: ${mission.complexity}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (mission.buff != null)
                                Container(color: Colors.yellow[700], padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), child: Text('+ ${mission.buff}', style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold))),
                              const SizedBox(height: 4),
                              if (mission.debuff != null)
                                Container(color: Colors.red[800], padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), child: Text('- ${mission.debuff}', style: const TextStyle(color: Colors.white, fontSize: 9))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}