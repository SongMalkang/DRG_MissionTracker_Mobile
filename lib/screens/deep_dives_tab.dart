import 'package:flutter/material.dart';
import '../data/trivia_data.dart';
import '../utils/strings.dart';
import '../utils/asset_helper.dart';
import '../services/deep_dive_service.dart';
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        // 업데이트 안내 배너
        _UpdateBanner(
          nextUpdate: _formatNextUpdate(),
          lang: widget.lang,
          onRefresh: () => _ddService.loadDeepDives(forceRefresh: true),
        ),
        const SizedBox(height: 12),

        // Deep Dive 카드들
        ...(_ddService.dives ?? []).map((dive) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _DeepDiveCard(dive: dive, lang: widget.lang),
            )),
      ],
    );
  }
}

// ── 업데이트 배너 ──────────────────────────────────────────────────────────────

class _UpdateBanner extends StatelessWidget {
  final String nextUpdate;
  final String lang;
  final VoidCallback onRefresh;

  const _UpdateBanner({
    required this.nextUpdate,
    required this.lang,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.update, color: Colors.blueAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${i18n[lang]!['dd_next_update'] ?? 'Next Update:'}  $nextUpdate',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: onRefresh,
            child: const Icon(Icons.refresh,
                color: Colors.blueAccent, size: 18),
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
                  _StageRow(stage: stage, accent: accent, lang: lang),
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

  const _DDHeader({
    required this.biome,
    required this.codeName,
    required this.typeLabel,
    required this.accent,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 95,
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
          // 텍스트
          Positioned(
            left: 14,
            right: 14,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 타입 뱃지
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

// ── 스테이지 행 (콤팩트 2행 레이아웃) ─────────────────────────────────────────

class _StageRow extends StatelessWidget {
  final DeepDiveStage stage;
  final Color accent;
  final String lang;

  const _StageRow(
      {required this.stage, required this.accent, required this.lang});

  @override
  Widget build(BuildContext context) {
    final hastrivia = triviaData.containsKey(stage.primary);

    return Padding(
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

          // 미션 아이콘 (탭 → trivia)
          GestureDetector(
            onTap: hastrivia
                ? () => showTriviaModal(
                      context,
                      itemKey: stage.primary,
                      lang: lang,
                      iconPath: AssetHelper.getMissionIcon(stage.primary),
                      accentColor: accent,
                    )
                : null,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Image.asset(
                AssetHelper.getMissionIcon(stage.primary),
                errorBuilder: (ctx, e, st) => Icon(
                  Icons.assignment,
                  color: Colors.white24,
                  size: 24,
                ),
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
                // 행 1: 미션명 + trivia 버튼
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t(stage.primary, lang),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hastrivia)
                      GestureDetector(
                        onTap: () => showTriviaModal(
                          context,
                          itemKey: stage.primary,
                          lang: lang,
                          iconPath: AssetHelper.getMissionIcon(stage.primary),
                          accentColor: accent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.info_outline,
                            color: accent.withValues(alpha: 0.5),
                            size: 13,
                          ),
                        ),
                      ),
                  ],
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
                      if (stage.warning != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            '·',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                    // 경고
                    if (stage.warning != null) ...[
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: Image.asset(
                          AssetHelper.getWarningIcon(stage.warning!),
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
                          t(stage.warning, lang),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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

                    // 도트 (우측 정렬)
                    const Spacer(),
                    _MiniDots(
                      value: stage.length,
                      color: accent.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 5),
                    _MiniDots(
                      value: stage.complexity,
                      color: accent.withValues(alpha: 0.45),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 미니 점 (스테이지용 간단 버전) ────────────────────────────────────────────

class _MiniDots extends StatelessWidget {
  final int value;
  final Color color;
  const _MiniDots({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final on = i < value;
        return Container(
          margin: const EdgeInsets.only(right: 3),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? color : Colors.white.withValues(alpha: 0.12),
            border: on ? null : Border.all(color: Colors.white12),
          ),
        );
      }),
    );
  }
}
