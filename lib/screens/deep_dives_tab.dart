import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import '../utils/asset_helper.dart';

// ── 데이터 모델 ────────────────────────────────────────────────────────────────

class _Stage {
  final int num;
  final String primary;
  final String secondary;
  final String? warning;
  final int complexity;
  final int length;

  const _Stage({
    required this.num,
    required this.primary,
    required this.secondary,
    this.warning,
    required this.complexity,
    required this.length,
  });

  factory _Stage.fromJson(int num, Map<String, dynamic> j) {
    final warnings = j['MissionWarnings'] as List?;
    return _Stage(
      num: num,
      primary: j['PrimaryObjective'] as String? ?? '',
      secondary: j['SecondaryObjective'] as String? ?? '',
      warning: (warnings != null && warnings.isNotEmpty)
          ? warnings.first as String
          : null,
      complexity:
          int.tryParse(j['Complexity']?.toString() ?? '1') ?? 1,
      length: int.tryParse(j['Length']?.toString() ?? '1') ?? 1,
    );
  }
}

class _DeepDive {
  final bool isElite;
  final String biome;
  final String codeName;
  final List<_Stage> stages;

  const _DeepDive({
    required this.isElite,
    required this.biome,
    required this.codeName,
    required this.stages,
  });
}

// ── Deep Dive 탭 ───────────────────────────────────────────────────────────────

class DeepDivesTab extends StatefulWidget {
  final String lang;
  const DeepDivesTab({super.key, required this.lang});

  @override
  State<DeepDivesTab> createState() => _DeepDivesTabState();
}

class _DeepDivesTabState extends State<DeepDivesTab> {
  List<_DeepDive>? _dives;
  DateTime? _thursdayUtc;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DeepDivesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 언어 변경 시 리빌드만 하면 됨 (데이터 재로딩 불필요)
  }

  // ── 이번 주 목요일 UTC 11:00 계산 ─────────────────────────────────────────
  DateTime _latestThursday() {
    final now = DateTime.now().toUtc();
    // weekday: Mon=1 … Thu=4 … Sun=7
    int daysBack = (now.weekday - DateTime.thursday) % 7;
    if (daysBack < 0) daysBack += 7;
    DateTime thu = DateTime.utc(now.year, now.month, now.day - daysBack, AppConstants.deepDiveResetHourUtc);
    // 오늘이 목요일인데 아직 11:00 UTC 전이면 이전 주
    if (now.isBefore(thu)) thu = thu.subtract(const Duration(days: 7));
    return thu;
  }

  String _buildUrl(DateTime thu) {
    final y = thu.year;
    final m = thu.month.toString().padLeft(2, '0');
    final d = thu.day.toString().padLeft(2, '0');
    return '${AppConstants.deepDiveBaseUrl}$y-$m-${d}T11-00-00Z.json';
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final thu = _latestThursday();
      _thursdayUtc = thu;
      final url = _buildUrl(thu);

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: AppConstants.networkTimeoutSeconds);
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close().timeout(
        const Duration(seconds: AppConstants.networkTimeoutSeconds),
      );
      final body = await res.transform(utf8.decoder).join();
      client.close();

      final dives = _parseDiveData(body);

      if (mounted) {
        setState(() {
          _dives = dives;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Deep Dive load failed: $e");
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<_DeepDive> _parseDiveData(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final ddMap = json['Deep Dives'] as Map<String, dynamic>?;
    if (ddMap == null) throw FormatException('Missing "Deep Dives" key');

    final dives = <_DeepDive>[];
    for (final key in ['Deep Dive Normal', 'Deep Dive Elite']) {
      final dd = ddMap[key] as Map<String, dynamic>?;
      if (dd == null) continue;
      final stagesRaw = dd['Stages'] as List?;
      if (stagesRaw == null) continue;
      final stages = stagesRaw
          .asMap()
          .entries
          .map((e) =>
              _Stage.fromJson(e.key + 1, e.value as Map<String, dynamic>))
          .toList();
      dives.add(_DeepDive(
        isElite: key.contains('Elite'),
        biome: dd['Biome'] as String? ?? '',
        codeName: dd['CodeName'] as String? ?? '',
        stages: stages,
      ));
    }
    return dives;
  }

  // 다음 목요일 UTC 11:00 계산
  DateTime _nextThursday() {
    final thu = _thursdayUtc ?? _latestThursday();
    return thu.add(const Duration(days: 7));
  }

  String _formatNextUpdate() {
    final next = _nextThursday().toLocal();
    return '${next.month}/${next.day}  ${next.hour.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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

    if (_error != null) {
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
                onPressed: _load,
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
          onRefresh: _load,
        ),
        const SizedBox(height: 12),

        // Deep Dive 카드들
        ...(_dives ?? []).map((dive) => Padding(
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
  final _DeepDive dive;
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
      height: 120,
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
            left: 16,
            right: 16,
            bottom: 14,
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

// ── 스테이지 행 ───────────────────────────────────────────────────────────────

class _StageRow extends StatelessWidget {
  final _Stage stage;
  final Color accent;
  final String lang;

  const _StageRow(
      {required this.stage, required this.accent, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 스테이지 번호 원
          Container(
            width: 30,
            height: 30,
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
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 미션 아이콘
          SizedBox(
            width: 38,
            height: 38,
            child: Image.asset(
              AssetHelper.getMissionIcon(stage.primary),
              errorBuilder: (ctx, e, st) => const Icon(Icons.assignment,
                  color: Colors.white24, size: 30),
            ),
          ),
          const SizedBox(width: 10),

          // 정보 컬럼
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 미션명
                Text(
                  t(stage.primary, lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),

                // 보조 목표
                Row(
                  children: [
                    const Icon(Icons.task_alt,
                        color: Colors.white30, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      t(stage.secondary, lang),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),

                // 경고
                if (stage.warning != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: Image.asset(
                          AssetHelper.getWarningIcon(stage.warning!),
                          errorBuilder: (ctx, e, st) => const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                              size: 13),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t(stage.warning, lang),
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    i18n[lang]!['no_warnings'] ?? 'No Warnings',
                    style: const TextStyle(
                        color: Colors.white24, fontSize: 11),
                  ),
                ],

                const SizedBox(height: 6),

                // 길이 / 복잡도 도트
                Row(
                  children: [
                    _MiniDots(
                        value: stage.length,
                        color: accent.withValues(alpha: 0.7)),
                    const SizedBox(width: 10),
                    _MiniDots(
                        value: stage.complexity,
                        color: accent.withValues(alpha: 0.45)),
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
