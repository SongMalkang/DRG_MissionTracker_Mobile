import 'package:flutter/material.dart';
import '../data/trivia_data.dart';
import '../utils/strings.dart';
import '../utils/asset_helper.dart';
import '../services/deep_dive_service.dart';
import '../widgets/mission_detail_components.dart';
import '../widgets/trivia_modal.dart';

// ── Deep Dive 탭 ───────────────────────────────────────────────────────────────

class DeepDivesTab extends StatefulWidget {
  final String lang;
  const DeepDivesTab({super.key, required this.lang});

  @override
  State<DeepDivesTab> createState() => _DeepDivesTabState();
}

class _DeepDivesTabState extends State<DeepDivesTab> {
  final DeepDiveService _ddService = DeepDiveService();

  @override
  void initState() {
    super.initState();
    _ddService.addListener(_onDataChanged);
    _ddService.loadDeepDives();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ddService.removeListener(_onDataChanged);
    super.dispose();
  }

  String _formatNextUpdate() {
    final next = _ddService.nextThursday().toLocal();
    return '${next.month}/${next.day}  ${next.hour.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    if (_ddService.isLoading && _ddService.dives == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 14),
            Text(
              i18n[widget.lang]!['dd_loading'] ?? 'Loading...',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_ddService.error != null && _ddService.dives == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                i18n[widget.lang]!['dd_error'] ?? 'Failed to load data.',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _ddService.loadDeepDives(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.blueAccent,
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: () => _ddService.loadDeepDives(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          // 업데이트 안내 배너
          _UpdateBanner(
            nextUpdate: _formatNextUpdate(),
            lang: widget.lang,
            isStale: _ddService.isDataStale,
            isRefreshing: _ddService.isRefreshing,
            onRefresh: () => _ddService.loadDeepDives(forceRefresh: true),
          ),
          const SizedBox(height: 12),

          // Deep Dive 카드들
          ...(_ddService.dives ?? []).map((dive) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _DeepDiveCard(dive: dive, lang: widget.lang),
              )),
        ],
      ),
    );
  }
}

// ── 업데이트 배너 (3단계 상태) ──────────────────────────────────────────────────

class _UpdateBanner extends StatelessWidget {
  final String nextUpdate;
  final String lang;
  final bool isStale;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const _UpdateBanner({
    required this.nextUpdate,
    required this.lang,
    required this.isStale,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final Color bannerColor;
    final IconData bannerIcon;
    final String bannerText;

    if (isStale || isRefreshing) {
      // 갱신 대기 중: 리셋 시간 경과 + 새 데이터 미도착 or 로딩 중
      bannerColor = Colors.orange;
      bannerIcon = Icons.hourglass_top;
      bannerText = i18n[lang]!['dd_refreshing'] ?? 'Checking for new Deep Dive data...';
    } else {
      // 정상
      bannerColor = Colors.blueAccent;
      bannerIcon = Icons.update;
      bannerText = '${i18n[lang]!['dd_next_update'] ?? 'Next Update:'}  $nextUpdate';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bannerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          if (isRefreshing)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: bannerColor,
              ),
            )
          else
            Icon(bannerIcon, color: bannerColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              bannerText,
              style: TextStyle(
                color: bannerColor.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRefresh,
            child: Icon(Icons.refresh, color: bannerColor, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Deep Dive 카드 ─────────────────────────────────────────────────────────────

class _DeepDiveCard extends StatelessWidget {
  final DeepDive dive;
  final String lang;

  const _DeepDiveCard({required this.dive, required this.lang});

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
            _DDHeader(
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
                  _StageRow(stage: stage, accent: accent, lang: lang, biome: dive.biome),
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

class _DDHeader extends StatelessWidget {
  final String biome;
  final String codeName;
  final String typeLabel;
  final Color accent;
  final String lang;
  final List<DeepDiveStage> stages;

  const _DDHeader({
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
                    _StageSummaryIcons(stages: stages, accent: accent),
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

class _StageSummaryIcons extends StatelessWidget {
  final List<DeepDiveStage> stages;
  final Color accent;

  const _StageSummaryIcons({required this.stages, required this.accent});

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

// ── 스테이지 행 (콤팩트 2행 레이아웃) ─────────────────────────────────────────

class _StageRow extends StatelessWidget {
  final DeepDiveStage stage;
  final Color accent;
  final String lang;
  final String biome;

  const _StageRow(
      {required this.stage, required this.accent, required this.lang, required this.biome});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showStageDetailModal(context, stage, biome, accent, lang),
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

// ── 스테이지 상세 모달 ────────────────────────────────────────────────────────

void _showStageDetailModal(
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
    pageBuilder: (ctx, anim1, anim2) => _StageDetailDialog(
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

class _StageDetailDialog extends StatelessWidget {
  final DeepDiveStage stage;
  final String biome;
  final Color accent;
  final String lang;

  const _StageDetailDialog({
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
