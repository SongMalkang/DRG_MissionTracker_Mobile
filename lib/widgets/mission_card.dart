import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../utils/strings.dart';
import '../utils/asset_helper.dart';
import 'trivia_modal.dart';
import 'mission_detail_components.dart';
import 'mission_detail_dialog.dart';

// 기존 import 호환성 유지
export 'mission_detail_dialog.dart' show showMissionModal;

// ── 미션 카드 (목록 표시용) ────────────────────────────────────────────────────
class MissionCard extends StatelessWidget {
  final Mission mission;
  final String lang;

  const MissionCard({super.key, required this.mission, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isDoubleXp = mission.buff == 'Double XP';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          height: 88,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDoubleXp
                  ? Colors.amber
                  : Colors.white.withValues(alpha: 0.08),
              width: isDoubleXp ? 2.0 : 1.0,
            ),
            boxShadow: isDoubleXp
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.18),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showMissionModal(context, mission, lang),
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  // 바이옴 배경 이미지
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        AssetHelper.getBiomeImage(mission.biome),
                        fit: BoxFit.cover,
                        color: Colors.black.withValues(alpha: 0.62),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // 카드 콘텐츠
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // 미션 타입 아이콘
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: Image.asset(
                            AssetHelper.getMissionIcon(mission.missionType),
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.assignment,
                                    color: Colors.white24, size: 38),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 미션명 + 바이옴명 + 아이콘 행
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                t(mission.missionType, lang),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 6)
                                  ],
                                ),
                              ),
                              Text(
                                t(mission.biome, lang),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade300,
                                  fontWeight: FontWeight.w600,
                                  shadows: const [
                                    Shadow(color: Colors.black, blurRadius: 4)
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  IconDots(
                                    value: mission.length,
                                    onIcon: 'assets/icons/ui/length_on.png',
                                    offIcon: 'assets/icons/ui/length_off.png',
                                    size: 13,
                                  ),
                                  const SizedBox(width: 8),
                                  IconDots(
                                    value: mission.complexity,
                                    onIcon:
                                        'assets/icons/ui/complexity_on.png',
                                    offIcon:
                                        'assets/icons/ui/complexity_off.png',
                                    size: 13,
                                  ),
                                  if (mission.secondaryObjective != null &&
                                      mission.secondaryObjective!
                                          .isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Tooltip(
                                      message:
                                          t(mission.secondaryObjective, lang),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Image.asset(
                                          AssetHelper.getSecondaryIcon(
                                              mission.secondaryObjective!),
                                          errorBuilder: (context, error,
                                                  stackTrace) =>
                                              const Icon(
                                                  Icons.local_florist_rounded,
                                                  color: Colors.white38,
                                                  size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 버프 / 디버프 아이콘 (우측, 탭 → Trivia)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (mission.buff != null)
                              GestureDetector(
                                onTap: () => showTriviaModal(
                                  context,
                                  itemKey: mission.buff!,
                                  lang: lang,
                                  iconPath: AssetHelper.getMutatorIcon(mission.buff!),
                                  accentColor: Colors.amber,
                                ),
                                child: Tooltip(
                                  message: t(mission.buff, lang),
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: Image.asset(
                                      AssetHelper.getMutatorIcon(mission.buff!),
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.bolt,
                                                  color: Colors.amber, size: 22),
                                    ),
                                  ),
                                ),
                              ),
                            if (mission.buff != null && mission.debuff != null)
                              const SizedBox(height: 4),
                            if (mission.debuff != null)
                              Builder(
                                builder: (_) {
                                  final ws = mission.debuff!
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (int i = 0; i < ws.length; i++) ...[
                                        if (i > 0)
                                          const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => showTriviaModal(
                                            context,
                                            itemKey: ws[i],
                                            lang: lang,
                                            iconPath: AssetHelper.getWarningIcon(ws[i]),
                                            accentColor: Colors.redAccent,
                                          ),
                                          child: Tooltip(
                                            message: t(ws[i], lang),
                                            child: SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: Image.asset(
                                                AssetHelper.getWarningIcon(
                                                    ws[i]),
                                                errorBuilder: (_, _, _) =>
                                                    const Icon(
                                                      Icons.warning_amber_rounded,
                                                      color: Colors.redAccent,
                                                      size: 22,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
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
