import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../utils/strings.dart';
import '../utils/asset_helper.dart';

// ── 전역 함수: 어디서든 미션 상세 모달을 열 수 있음 ──────────────────────────
void showMissionModal(BuildContext context, Mission mission, String lang) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.75),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim1, anim2) =>
        _MissionDetailDialog(mission: mission, lang: lang),
    transitionBuilder: (ctx, anim1, anim2, child) => Transform.scale(
      scale: Curves.easeOutBack.transform(anim1.value),
      child: FadeTransition(opacity: anim1, child: child),
    ),
  );
}

// ── 미션 카드 (목록 표시용) ────────────────────────────────────────────────────
class MissionCard extends StatelessWidget {
  final Mission mission;
  final String lang;

  const MissionCard({super.key, required this.mission, required this.lang});

  @override
  Widget build(BuildContext context) {
    final bool isDoubleXp = mission.buff == 'Double XP';

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
                                  _IconDots(
                                    value: mission.length,
                                    onIcon: 'assets/icons/ui/length_on.png',
                                    offIcon: 'assets/icons/ui/length_off.png',
                                    size: 13,
                                  ),
                                  const SizedBox(width: 8),
                                  _IconDots(
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

                        // 버프 / 디버프 아이콘 (우측)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (mission.buff != null)
                              Tooltip(
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
                            if (mission.buff != null && mission.debuff != null)
                              const SizedBox(height: 4),
                            if (mission.debuff != null)
                              Tooltip(
                                message: t(
                                    mission.debuff!.split(',').first.trim(),
                                    lang),
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Image.asset(
                                    AssetHelper.getWarningIcon(mission.debuff!
                                        .split(',')
                                        .first
                                        .trim()),
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.redAccent,
                                                size: 22),
                                  ),
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

// ── 미션 상세 다이얼로그 위젯 ─────────────────────────────────────────────────
class _MissionDetailDialog extends StatelessWidget {
  final Mission mission;
  final String lang;

  const _MissionDetailDialog({required this.mission, required this.lang});

  @override
  Widget build(BuildContext context) {
    final warnings = mission.debuff
            ?.split(',')
            .map((w) => w.trim())
            .where((w) => w.isNotEmpty)
            .toList() ??
        [];

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
                color: Colors.orange.withValues(alpha: 0.6),
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

                          // 주 목표
                          _SectionLabel(
                              text: i18n[lang]!['primary_obj'] ?? 'Primary'),
                          const SizedBox(height: 6),
                          _ObjectiveRow(
                            iconPath: AssetHelper.getMissionIcon(
                                mission.missionType),
                            label: t(mission.missionType, lang),
                            isPrimary: true,
                            fallbackIcon: Icons.assignment,
                          ),

                          // 보조 목표
                          if (mission.secondaryObjective != null &&
                              mission.secondaryObjective!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _SectionLabel(
                                text: i18n[lang]!['secondary_obj'] ??
                                    'Secondary'),
                            const SizedBox(height: 6),
                            _ObjectiveRow(
                              iconPath: AssetHelper.getSecondaryIcon(
                                  mission.secondaryObjective!),
                              label: t(mission.secondaryObjective, lang),
                              isPrimary: false,
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
                                child: _IconRating(
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
                                child: _IconRating(
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
                                child: _BadgeRow(
                                  iconPath: AssetHelper.getMutatorIcon(
                                      mission.buff!),
                                  label: t(mission.buff, lang),
                                  color: Colors.amber,
                                  fallbackIcon: Icons.bolt,
                                ),
                              ),
                            ...warnings.map(
                              (w) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _BadgeRow(
                                  iconPath: AssetHelper.getWarningIcon(w),
                                  label: t(w, lang),
                                  color: Colors.redAccent,
                                  fallbackIcon: Icons.warning_amber_rounded,
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

// ── 섹션 레이블 ────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── 목표 행 (Primary / Secondary) ─────────────────────────────────────────────
class _ObjectiveRow extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isPrimary;
  final IconData fallbackIcon;

  const _ObjectiveRow({
    required this.iconPath,
    required this.label,
    required this.isPrimary,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPrimary ? Colors.white : Colors.greenAccent.shade100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.greenAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimary
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.greenAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Image.asset(
              iconPath,
              errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon,
                  color: color.withValues(alpha: 0.5),
                  size: 26),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 길이/복잡도 아이콘 도트 (카드용) ──────────────────────────────────────────
class _IconDots extends StatelessWidget {
  final int value;
  final String onIcon;
  final String offIcon;
  final double size;

  const _IconDots({
    required this.value,
    required this.onIcon,
    required this.offIcon,
    this.size = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isOn = i < value;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Image.asset(
            isOn ? onIcon : offIcon,
            width: size,
            height: size,
            errorBuilder: (context, error, stackTrace) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOn
                    ? Colors.orange
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── 길이/복잡도 아이콘 레이팅 (모달용) ────────────────────────────────────────
class _IconRating extends StatelessWidget {
  final String label;
  final int value;
  final String onIcon;
  final String offIcon;
  final double iconSize;

  const _IconRating({
    required this.label,
    required this.value,
    required this.onIcon,
    required this.offIcon,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final isOn = i < value;
            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Image.asset(
                isOn ? onIcon : offIcon,
                width: iconSize,
                height: iconSize,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOn
                        ? Colors.orange
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── 버프/디버프 배지 행 ────────────────────────────────────────────────────────
class _BadgeRow extends StatelessWidget {
  final String iconPath;
  final String label;
  final Color color;
  final IconData fallbackIcon;

  const _BadgeRow({
    required this.iconPath,
    required this.label,
    required this.color,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: Image.asset(
            iconPath,
            errorBuilder: (context, error, stackTrace) =>
                Icon(fallbackIcon, color: color, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
