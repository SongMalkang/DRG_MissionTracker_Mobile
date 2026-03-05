import 'dart:async';
import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';
import '../services/mission_service.dart';
import '../utils/asset_helper.dart';
import '../widgets/mission_card.dart' show showMissionModal;
import '../widgets/mission_detail_components.dart' show SeasonBadge;
import '../widgets/skeleton_loading.dart';

class HighlightsTab extends StatefulWidget {
  final String lang;
  final bool showWarnings;
  const HighlightsTab({super.key, required this.lang, this.showWarnings = true});

  @override
  State<HighlightsTab> createState() => _HighlightsTabState();
}

class _HighlightsTabState extends State<HighlightsTab> {
  late Timer _timer;
  late DateTime _now;
  final MissionService _missionService = MissionService();

  // 각 원소: { 'time': DateTime, 'missions': List(Mission), 'isPast': bool,
  //             'isCurrent': bool, 'isTomorrow': bool }
  List<Map<String, dynamic>> _slots = [];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _missionService.addListener(_onDataChanged);
    if (_missionService.isInitialized) {
      _processHighlights();
    }
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          _processHighlights();
        });
      }
    });
  }

  void _onDataChanged() {
    if (mounted) {
      _now = DateTime.now();
      _processHighlights();
    }
  }

  void _processHighlights() {
    final allMissions = _missionService.allMissions;
    final startTime = _now.subtract(const Duration(hours: AppConstants.highlightLookbackHours));

    // 시간 슬롯별로 Double XP 미션 그룹화
    final Map<DateTime, List<Mission>> slotMap = {};
    for (final key in (allMissions.keys.toList()..sort())) {
      final utcTime = DateTime.tryParse(key);
      if (utcTime == null) continue;
      final localTime = utcTime.toLocal();
      if (localTime.isBefore(startTime)) continue;

      final dxpMissions =
          allMissions[key]!.where((m) => m.buff == 'Double XP').toList();
      if (dxpMissions.isEmpty) continue;
      slotMap[localTime] = dxpMissions;
    }

    final slots = <Map<String, dynamic>>[];
    for (final time in (slotMap.keys.toList()..sort())) {
      final endTime = time.add(const Duration(minutes: AppConstants.missionRotationMinutes));
      slots.add({
        'time': time,
        'missions': slotMap[time]!,
        'isPast': endTime.isBefore(_now),
        'isCurrent': time.isBefore(_now) && endTime.isAfter(_now),
        'isTomorrow': time.day != _now.day,
      });
    }

    setState(() {
      _slots = slots;
    });
  }

  @override
  void dispose() {
    _missionService.removeListener(_onDataChanged);
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_missionService.isInitialized) {
      if (_missionService.lastError != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(
                  i18n[widget.lang]!['load_error'] ?? 'Failed to load data.',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _missionService.forceRefresh(),
                  icon: const Icon(Icons.refresh),
                  label: Text(i18n[widget.lang]!['retry'] ?? 'Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return const SkeletonLoadingList();
    }

    final timeStr =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';

    return Column(
      children: [
        // 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.black45,
          child: Text(
            i18n[widget.lang]!['timeline_title']!,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            color: Colors.orange,
            backgroundColor: const Color(0xFF1E1E1E),
            onRefresh: () => MissionService().forceRefresh(),
            child: _slots.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 56,
                              color: Colors.orange.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text(i18n[widget.lang]!['no_highlights']!,
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: _slots.length,
                  itemBuilder: (context, index) {
                    final slot = _slots[index];
                    final List<Mission> missions = slot['missions'];
                    final DateTime time = slot['time'];
                    final bool isPast = slot['isPast'];
                    final bool isCurrent = slot['isCurrent'];
                    final bool isTomorrow = slot['isTomorrow'];

                    final slotTimeStr =
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── 내일 구분선 ──────────────────────────────────
                        if (isTomorrow &&
                            (index == 0 ||
                                !_slots[index - 1]['isTomorrow']))
                          _TomorrowDivider(lang: widget.lang),

                        // ── 현재 시각 마커 ────────────────────────────────
                        if (isCurrent)
                          _CurrentTimeMarker(timeStr: timeStr),

                        // ── 타임 슬롯 블록 ────────────────────────────────
                        Opacity(
                          opacity: isPast ? AppConstants.elapsedMissionOpacity : 1.0,
                          child: _TimeSlotBlock(
                            timeStr: slotTimeStr,
                            missions: missions,
                            isCurrent: isCurrent,
                            isTomorrow: isTomorrow,
                            lang: widget.lang,
                            showWarnings: widget.showWarnings,
                          ),
                        ),
                      ],
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }
}

// ── 내일 구분선 ───────────────────────────────────────────────────────────────

class _TomorrowDivider extends StatelessWidget {
  final String lang;
  const _TomorrowDivider({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.blueAccent, thickness: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
            ),
            child: Text(
              i18n[lang]!['tomorrow']!,
              style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8),
            ),
          ),
          const Expanded(child: Divider(color: Colors.blueAccent, thickness: 1)),
        ],
      ),
    );
  }
}

// ── 현재 시각 마커 ────────────────────────────────────────────────────────────

class _CurrentTimeMarker extends StatelessWidget {
  final String timeStr;
  const _CurrentTimeMarker({required this.timeStr});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Expanded(
              child: Divider(color: Colors.greenAccent, thickness: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: Colors.greenAccent, size: 7),
                const SizedBox(width: 5),
                Text(
                  'NOW  $timeStr',
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0),
                ),
              ],
            ),
          ),
          const Expanded(
              child: Divider(color: Colors.greenAccent, thickness: 1)),
        ],
      ),
    );
  }
}

// ── 타임 슬롯 블록 (하나의 시간에 여러 미션 묶음) ─────────────────────────────

class _TimeSlotBlock extends StatelessWidget {
  final String timeStr;
  final List<Mission> missions;
  final bool isCurrent;
  final bool isTomorrow;
  final String lang;
  final bool showWarnings;

  const _TimeSlotBlock({
    required this.timeStr,
    required this.missions,
    required this.isCurrent,
    required this.isTomorrow,
    required this.lang,
    this.showWarnings = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent
            ? Colors.amber.withValues(alpha: 0.04)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isCurrent
            ? Border.all(color: Colors.amber.withValues(alpha: 0.25))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시간 레이블
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 14,
                      color: isCurrent ? Colors.amber : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isTomorrow)
                    Text(
                      i18n[lang]!['tomorrow']!.substring(
                          0,
                          i18n[lang]!['tomorrow']!
                              .split(' ')
                              .first
                              .length), // 첫 단어만
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 7,
                          fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ),
          // 미션 카드들
          Expanded(
            child: Column(
              children: missions
                  .map((m) => _HighlightMissionRow(mission: m, lang: lang, showWarnings: showWarnings))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 하이라이트 미션 행 ────────────────────────────────────────────────────────

class _HighlightMissionRow extends StatelessWidget {
  final Mission mission;
  final String lang;
  final bool showWarnings;
  const _HighlightMissionRow({required this.mission, required this.lang, this.showWarnings = true});

  @override
  Widget build(BuildContext context) {
    // 단일 시즌 전용 여부
    final bool isExclusive = mission.seasons.length == 1;

    return GestureDetector(
      onTap: () => _openCard(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5, right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[900],
          border: const Border(
            left: BorderSide(color: Colors.amber, width: 3),
          ),
        ),
        child: Row(
          children: [
            // 미션 아이콘
            SizedBox(
              width: 34,
              height: 34,
              child: Image.asset(
                AssetHelper.getMissionIcon(mission.missionType),
                errorBuilder: (ctx, e, st) => const Icon(Icons.assignment,
                    color: Colors.white24, size: 26),
              ),
            ),
            const SizedBox(width: 10),

            // 미션명 + 바이옴명
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(mission.missionType, lang),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    t(mission.biome, lang),
                    style: TextStyle(
                        color: Colors.orange.shade300, fontSize: 11),
                  ),
                ],
              ),
            ),

            // 시즌 뱃지
            SeasonBadge(seasons: mission.seasons, isExclusive: isExclusive),

            const SizedBox(width: 6),

            // Double XP 아이콘 + Warning
            Column(
              children: [
                SizedBox(
                  width: 26,
                  height: 26,
                  child: Image.asset(
                    AssetHelper.getMutatorIcon('Double XP'),
                    errorBuilder: (ctx, e, st) => const Icon(Icons.bolt,
                        color: Colors.amber, size: 20),
                  ),
                ),
                if (mission.debuff != null && showWarnings) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: mission.debuff!
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .map((w) => Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: Image.asset(
                                  AssetHelper.getWarningIcon(w),
                                  errorBuilder: (ctx, e, st) => const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.redAccent,
                                      size: 16),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openCard(BuildContext context) {
    showMissionModal(context, mission, lang);
  }
}

