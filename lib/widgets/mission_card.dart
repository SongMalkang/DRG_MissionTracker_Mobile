import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../utils/strings.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;
  final String lang;

  const MissionCard({super.key, required this.mission, required this.lang});

  void _showMissionDetails(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: Stack(
                        children: [
                          Container(
                            height: 100,
                            color: Colors.grey[800],
                            child: Center(child: Text('[ ${t(mission.biome, lang)} 이미지(PNG) ]', style: const TextStyle(color: Colors.white24))),
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
                            child: Text('${t(mission.missionType, lang)} - ${t(mission.biome, lang)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
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
                          if (mission.buff != null) Text('+ ${t(mission.buff, lang)}', style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 14)),
                          if (mission.debuff != null) Text('- ${t(mission.debuff, lang)}', style: const TextStyle(color: Colors.red, fontSize: 14)),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.05),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(6)
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('⚠️ 바이옴: [ 예: 모래 폭풍으로 시야 제한 ]', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                                SizedBox(height: 6),
                                Text('⚠️ 미션: [ 예: 알을 파낼 때 스웜 발생 위험 ]', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
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
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDoubleXp = mission.buff == "Double XP";
    
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          height: 100, // 카드 높이 유지
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDoubleXp ? Colors.amber : Colors.white10, 
              width: isDoubleXp ? 2.0 : 1.0,
            ),
            boxShadow: isDoubleXp ? [
              BoxShadow(
                color: Colors.amber.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ] : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showMissionDetails(context),
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  // 배경 텍스트 플레이스홀더
                  Center(child: Text('[ ${t(mission.biome, lang)} ]', style: const TextStyle(color: Colors.white10, fontSize: 18))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        // 1. 미션 유형 아이콘 (크기 확대, 테두리 제거)
                        Icon(Icons.assignment, color: Colors.white.withOpacity(0.4), size: 42),
                        const SizedBox(width: 12),
                        // 2. 미션 정보
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(t(mission.missionType, lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(t(mission.biome, lang), style: const TextStyle(fontSize: 11, color: Colors.orange)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('${i18n[lang]!['length']}: ${mission.length}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(width: 8),
                                  Text('${i18n[lang]!['complexity']}: ${mission.complexity}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 3. 변이 및 주의사항 (아이콘 크기 확대)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (mission.buff != null)
                              Tooltip(
                                message: t(mission.buff, lang),
                                child: Container(
                                  width: 28, height: 28,
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[700],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.black, width: 1.5),
                                  ),
                                  child: const Icon(Icons.bolt, color: Colors.black, size: 20),
                                ),
                              ),
                            if (mission.debuff != null)
                              Tooltip(
                                message: t(mission.debuff, lang),
                                child: Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.red[800],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.black, width: 1.5),
                                  ),
                                  child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                          ],
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
