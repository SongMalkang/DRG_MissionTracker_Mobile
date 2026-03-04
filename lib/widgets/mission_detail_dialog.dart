import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../utils/strings.dart';
import '../utils/asset_helper.dart';
import 'trivia_modal.dart';
import 'mission_detail_components.dart';

// ── 전역 함수: 어디서든 미션 상세 모달을 열 수 있음 ──────────────────────────
void showMissionModal(BuildContext context, Mission mission, String lang) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.75),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim1, anim2) =>
        MissionDetailDialog(mission: mission, lang: lang),
    transitionBuilder: (ctx, anim1, anim2, child) => Transform.scale(
      scale: Curves.easeOutBack.transform(anim1.value),
      child: FadeTransition(opacity: anim1, child: child),
    ),
  );
}

// ── 미션 상세 다이얼로그 위젯 ─────────────────────────────────────────────────
class MissionDetailDialog extends StatelessWidget {
  final Mission mission;
  final String lang;

  const MissionDetailDialog({super.key, required this.mission, required this.lang});

  @override
  Widget build(BuildContext context) {
    final warnings = mission.debuff
            ?.split(',')
            .map((w) => w.trim())
            .where((w) => w.isNotEmpty)
            .toList() ??
        [];
    final isDoubleXp = mission.buff == 'Double XP';

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
                color: isDoubleXp
                    ? Colors.amber.withValues(alpha: 0.8)
                    : Colors.orange.withValues(alpha: 0.6),
                width: isDoubleXp ? 2.0 : 1.5,
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
                  // 헤더
                  _ModalHeader(mission: mission, lang: lang),

                  // 스크롤 본문
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 코드명
                          if (mission.codeName != null &&
                              mission.codeName!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.tag,
                                      color: Colors.white38, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    '"${mission.codeName!}"',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // 보조 목표
                          if (mission.secondaryObjective != null &&
                              mission.secondaryObjective!.isNotEmpty) ...[
                            SectionLabel(
                                text: i18n[lang]!['secondary_obj'] ??
                                    'Secondary'),
                            const SizedBox(height: 6),
                            ObjectiveRow(
                              iconPath: AssetHelper.getSecondaryIcon(
                                  mission.secondaryObjective!),
                              label: t(mission.secondaryObjective, lang),
                              isPrimary: true,
                              fallbackIcon: Icons.local_florist_rounded,
                            ),
                          ],

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Colors.white12, height: 1),
                          ),

                          // 길이 / 복잡도
                          Row(
                            children: [
                              Expanded(
                                child: IconRating(
                                  label:
                                      i18n[lang]!['length'] ?? 'Length',
                                  value: mission.length,
                                  onIcon: 'assets/icons/ui/length_on.png',
                                  offIcon: 'assets/icons/ui/length_off.png',
                                  iconSize: 18,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: IconRating(
                                  label: i18n[lang]!['complexity'] ??
                                      'Complexity',
                                  value: mission.complexity,
                                  onIcon:
                                      'assets/icons/ui/complexity_on.png',
                                  offIcon:
                                      'assets/icons/ui/complexity_off.png',
                                  iconSize: 18,
                                ),
                              ),
                            ],
                          ),

                          // 버프 / 디버프
                          if (mission.buff != null ||
                              warnings.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child:
                                  Divider(color: Colors.white12, height: 1),
                            ),
                            if (mission.buff != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: BadgeRow(
                                  iconPath: AssetHelper.getMutatorIcon(
                                      mission.buff!),
                                  label: t(mission.buff, lang),
                                  color: Colors.amber,
                                  fallbackIcon: Icons.bolt,
                                  onTap: () => showTriviaModal(
                                    context,
                                    itemKey: mission.buff!,
                                    lang: lang,
                                    iconPath: AssetHelper.getMutatorIcon(
                                        mission.buff!),
                                    accentColor: Colors.amber,
                                  ),
                                ),
                              ),
                            ...warnings.map(
                              (w) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: BadgeRow(
                                  iconPath: AssetHelper.getWarningIcon(w),
                                  label: t(w, lang),
                                  color: Colors.redAccent,
                                  fallbackIcon: Icons.warning_amber_rounded,
                                  onTap: () => showTriviaModal(
                                    context,
                                    itemKey: w,
                                    lang: lang,
                                    iconPath: AssetHelper.getWarningIcon(w),
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

                  // 닫기 버튼
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1C1C1C),
                        border:
                            Border(top: BorderSide(color: Colors.white10)),
                      ),
                      child: Text(
                        i18n[lang]!['close'] ?? 'CLOSE',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.orange,
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

// ── 모달 헤더 ─────────────────────────────────────────────────────────────────
class _ModalHeader extends StatelessWidget {
  final Mission mission;
  final String lang;
  const _ModalHeader({required this.mission, required this.lang});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AssetHelper.getBiomeImage(mission.biome),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
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
          // 시즌 뱃지 + Double XP 뱃지 (우상단)
          Positioned(
            top: 10,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (mission.buff == 'Double XP')
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.8), width: 1.5),
                    ),
                    child: const Text(
                      '2x XP',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                SeasonBadge(
                  seasons: mission.seasons,
                  isExclusive: mission.seasons.length == 1,
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    AssetHelper.getMissionIcon(mission.missionType),
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.assignment,
                            color: Colors.white38, size: 32),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t(mission.missionType, lang),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 8)
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => showTriviaModal(
                          context,
                          itemKey: mission.biome,
                          lang: lang,
                          iconPath: null,
                          accentColor: Colors.orange,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t(mission.biome, lang),
                              style: TextStyle(
                                color: Colors.orange.shade300,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                shadows: const [
                                  Shadow(color: Colors.black, blurRadius: 6)
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.info_outline,
                                size: 13,
                                color: Colors.orange.withValues(alpha: 0.5)),
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
    );
  }
}
