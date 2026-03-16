import 'package:flutter/material.dart';
import '../services/deep_dive_service.dart';
import '../utils/strings.dart';
import '../utils/asset_helper.dart';
import 'mission_detail_components.dart';
import 'deep_dive_detail_dialog.dart';

// ── 스테이지 행 (콤팩트 2행 레이아웃) ─────────────────────────────────────────

class DeepDiveStageRow extends StatelessWidget {
  final DeepDiveStage stage;
  final Color accent;
  final String lang;
  final String biome;

  const DeepDiveStageRow({
    super.key,
    required this.stage,
    required this.accent,
    required this.lang,
    required this.biome,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showStageDetailModal(context, stage, biome, accent, lang),
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 스테이지 번호 원
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
            alignment: Alignment.center,
            child: Text(
              '${stage.num}',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 미션 아이콘
          SizedBox(
            width: 30,
            height: 30,
            child: Image.asset(
              AssetHelper.getMissionIcon(stage.primary),
              errorBuilder: (ctx, e, st) => const Icon(
                Icons.assignment,
                color: Colors.white24,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 정보 컬럼 (2행)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 행 1: 미션명
                Text(
                  t(stage.primary, lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),

                // 행 2: 보조목표 · 경고 · 도트 (한 줄로)
                Row(
                  children: [
                    // 보조 목표
                    if (stage.secondary != null) ...[
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: Image.asset(
                          AssetHelper.getSecondaryIcon(stage.secondary!),
                          errorBuilder: (ctx, e, st) => Icon(
                            Icons.flag,
                            color: accent.withValues(alpha: 0.6),
                            size: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          t(stage.secondary, lang),
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 구분자
                      if (stage.warnings.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            '·',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                    // 뮤테이터
                    if (stage.mutator != null) ...[
                      Tooltip(
                        message: t(stage.mutator, lang),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: Image.asset(
                            AssetHelper.getMutatorIcon(stage.mutator!),
                            errorBuilder: (ctx, e, st) => const Icon(
                              Icons.bolt,
                              color: Colors.amber,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          t(stage.mutator, lang),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (stage.warnings.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            '·',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                    // 경고 (다중 지원)
                    if (stage.warnings.isNotEmpty) ...[
                      if (stage.warnings.length == 1) ...[
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: Image.asset(
                            AssetHelper.getWarningIcon(stage.warnings.first),
                            errorBuilder: (ctx, e, st) => const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                              size: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            t(stage.warnings.first, lang),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        // 다중 경고: 아이콘 Row
                        for (int wi = 0; wi < stage.warnings.length; wi++) ...[
                          if (wi > 0) const SizedBox(width: 3),
                          Tooltip(
                            message: t(stage.warnings[wi], lang),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: Image.asset(
                                AssetHelper.getWarningIcon(stage.warnings[wi]),
                                errorBuilder: (ctx, e, st) => const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.redAccent,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ] else if (stage.secondary == null) ...[
                      // secondary도 없고 warning도 없는 경우
                      Text(
                        i18n[lang]!['no_warnings'] ?? 'No Warnings',
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                        ),
                      ),
                    ],

                    // 길이/복잡도 도트 (우측 정렬)
                    const Spacer(),
                    IconDots(
                      value: stage.length,
                      onIcon: 'assets/icons/ui/length_on.png',
                      offIcon: 'assets/icons/ui/length_off.png',
                      size: 11,
                    ),
                    const SizedBox(width: 6),
                    IconDots(
                      value: stage.complexity,
                      onIcon: 'assets/icons/ui/complexity_on.png',
                      offIcon: 'assets/icons/ui/complexity_off.png',
                      size: 11,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
