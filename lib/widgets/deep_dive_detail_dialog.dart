import 'package:flutter/material.dart';
import '../data/trivia_data.dart';
import '../services/deep_dive_service.dart';
import '../utils/strings.dart';
import '../utils/asset_helper.dart';
import 'mission_detail_components.dart';
import 'trivia_modal.dart';

// ── 스테이지 상세 모달 ────────────────────────────────────────────────────────

void showStageDetailModal(
  BuildContext context,
  DeepDiveStage stage,
  String biome,
  Color accent,
  String lang,
) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.75),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim1, anim2) => DeepDiveStageDetailDialog(
      stage: stage,
      biome: biome,
      accent: accent,
      lang: lang,
    ),
    transitionBuilder: (ctx, anim1, anim2, child) => Transform.scale(
      scale: Curves.easeOutBack.transform(anim1.value),
      child: FadeTransition(opacity: anim1, child: child),
    ),
  );
}

class DeepDiveStageDetailDialog extends StatelessWidget {
  final DeepDiveStage stage;
  final String biome;
  final Color accent;
  final String lang;

  const DeepDiveStageDetailDialog({
    super.key,
    required this.stage,
    required this.biome,
    required this.accent,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final hastrivia = triviaData.containsKey(stage.primary);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── 헤더: 바이옴 배경 + 미션 아이콘 ──────────────────────
                  SizedBox(
                    height: 130,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            AssetHelper.getBiomeImage(biome),
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, e, st) =>
                                Container(color: Colors.grey[850]),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.2),
                                  const Color(0xFF141414),
                                ],
                                stops: const [0.3, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // 스테이지 번호 뱃지 (우상단)
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: accent.withValues(alpha: 0.8),
                                  width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${stage.num}',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        // 미션 아이콘 + 미션명 + 바이옴
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: hastrivia
                                    ? () => showTriviaModal(
                                          context,
                                          itemKey: stage.primary,
                                          lang: lang,
                                          iconPath:
                                              AssetHelper.getMissionIcon(
                                                  stage.primary),
                                          accentColor: accent,
                                        )
                                    : null,
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.15)),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Image.asset(
                                    AssetHelper.getMissionIcon(
                                        stage.primary),
                                    errorBuilder: (ctx, e, st) =>
                                        const Icon(Icons.assignment,
                                            color: Colors.white38,
                                            size: 32),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      t(stage.primary, lang),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                              color: Colors.black,
                                              blurRadius: 8)
                                        ],
                                      ),
                                    ),
                                    Text(
                                      t(biome, lang),
                                      style: TextStyle(
                                        color:
                                            accent.withValues(alpha: 0.9),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        shadows: const [
                                          Shadow(
                                              color: Colors.black,
                                              blurRadius: 6)
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 스크롤 본문 ─────────────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 보조 목표 (추가 메인 미션) — 텍스트로 표현
                          if (stage.secondary != null &&
                              stage.secondary!.isNotEmpty) ...[
                            SectionLabel(
                                text: i18n[lang]!['secondary_obj'] ??
                                    'Secondary'),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        accent.withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.flag_rounded,
                                      color:
                                          accent.withValues(alpha: 0.7),
                                      size: 24),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      t(stage.secondary, lang),
                                      style: TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child:
                                Divider(color: Colors.white12, height: 1),
                          ),

                          // 길이 / 복잡도
                          Row(
                            children: [
                              Expanded(
                                child: IconRating(
                                  label: i18n[lang]!['length'] ??
                                      'Length',
                                  value: stage.length,
                                  onIcon:
                                      'assets/icons/ui/length_on.png',
                                  offIcon:
                                      'assets/icons/ui/length_off.png',
                                  iconSize: 18,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: IconRating(
                                  label:
                                      i18n[lang]!['complexity'] ??
                                          'Complexity',
                                  value: stage.complexity,
                                  onIcon:
                                      'assets/icons/ui/complexity_on.png',
                                  offIcon:
                                      'assets/icons/ui/complexity_off.png',
                                  iconSize: 18,
                                ),
                              ),
                            ],
                          ),

                          // 뮤테이터 (Mutator)
                          if (stage.mutator != null) ...[
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                  color: Colors.white12, height: 1),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: BadgeRow(
                                iconPath:
                                    AssetHelper.getMutatorIcon(stage.mutator!),
                                label: t(stage.mutator, lang),
                                color: Colors.amber,
                                fallbackIcon: Icons.bolt,
                                onTap: () => showTriviaModal(
                                  context,
                                  itemKey: stage.mutator!,
                                  lang: lang,
                                  iconPath:
                                      AssetHelper.getMutatorIcon(stage.mutator!),
                                  accentColor: Colors.amber,
                                ),
                              ),
                            ),
                          ],

                          // 경고 (Warnings)
                          if (stage.warnings.isNotEmpty) ...[
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                  color: Colors.white12, height: 1),
                            ),
                            ...stage.warnings.map(
                              (w) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: BadgeRow(
                                  iconPath:
                                      AssetHelper.getWarningIcon(w),
                                  label: t(w, lang),
                                  color: Colors.redAccent,
                                  fallbackIcon:
                                      Icons.warning_amber_rounded,
                                  onTap: () => showTriviaModal(
                                    context,
                                    itemKey: w,
                                    lang: lang,
                                    iconPath:
                                        AssetHelper.getWarningIcon(w),
                                    accentColor: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),

                  // ── 닫기 버튼 ───────────────────────────────────────────
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1C1C1C),
                        border: Border(
                            top: BorderSide(color: Colors.white10)),
                      ),
                      child: Text(
                        i18n[lang]!['close'] ?? 'CLOSE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.4,
                          fontSize: 13,
                        ),
                      ),
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
