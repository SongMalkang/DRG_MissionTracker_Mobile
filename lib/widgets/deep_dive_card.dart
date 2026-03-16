import 'package:flutter/material.dart';
import '../services/deep_dive_service.dart';
import '../utils/strings.dart';
import '../utils/asset_helper.dart';
import 'deep_dive_stage_row.dart';

// ── Deep Dive 카드 ─────────────────────────────────────────────────────────────

class DeepDiveCard extends StatelessWidget {
  final DeepDive dive;
  final String lang;

  const DeepDiveCard({super.key, required this.dive, required this.lang});

  @override
  Widget build(BuildContext context) {
    final Color accent = dive.isElite
        ? const Color(0xFFEF5350)
        : const Color(0xFF42A5F5);
    final String typeLabel = dive.isElite
        ? (i18n[lang]!['elite_dd'] ?? 'ELITE DEEP DIVE')
        : (i18n[lang]!['standard_dd'] ?? 'STANDARD DEEP DIVE');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          children: [
            // ── 헤더: 바이옴 배경 ──────────────────────────────────────────
            DDHeader(
              biome: dive.biome,
              codeName: dive.codeName,
              typeLabel: typeLabel,
              accent: accent,
              lang: lang,
              stages: dive.stages,
            ),

            // ── 스테이지 목록 ──────────────────────────────────────────────
            ...dive.stages.asMap().entries.map((entry) {
              final i = entry.key;
              final stage = entry.value;
              return Column(
                children: [
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                      indent: 12,
                      endIndent: 12,
                    ),
                  DeepDiveStageRow(stage: stage, accent: accent, lang: lang, biome: dive.biome),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── DD 헤더 ───────────────────────────────────────────────────────────────────

class DDHeader extends StatelessWidget {
  final String biome;
  final String codeName;
  final String typeLabel;
  final Color accent;
  final String lang;
  final List<DeepDiveStage> stages;

  const DDHeader({
    super.key,
    required this.biome,
    required this.codeName,
    required this.typeLabel,
    required this.accent,
    required this.lang,
    required this.stages,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 105,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 바이옴 배경
          Image.asset(
            AssetHelper.getBiomeImage(biome),
            fit: BoxFit.cover,
            errorBuilder: (ctx, e, st) =>
                Container(color: Colors.grey[850]),
          ),
          // 그라디언트 오버레이
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
          // 텍스트 + 스테이지 요약
          Positioned(
            left: 14,
            right: 14,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 타입 뱃지 + 스테이지 아이콘 요약 (같은 행)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: accent.withValues(alpha: 0.6), width: 1),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 스테이지 미션 아이콘 요약: [1] → [2] → [3]
                    StageSummaryIcons(stages: stages, accent: accent),
                  ],
                ),
                const SizedBox(height: 5),
                // 코드명
                Text(
                  codeName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                ),
                // 바이옴명
                Text(
                  t(biome, lang),
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 스테이지 미션 아이콘 요약 (헤더 우측) ─────────────────────────────────────

class StageSummaryIcons extends StatelessWidget {
  final List<DeepDiveStage> stages;
  final Color accent;

  const StageSummaryIcons({super.key, required this.stages, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.3),
                size: 12,
              ),
            ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: Image.asset(
              AssetHelper.getMissionIcon(stages[i].primary),
              errorBuilder: (ctx, e, st) => Icon(
                Icons.assignment,
                color: accent.withValues(alpha: 0.5),
                size: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
