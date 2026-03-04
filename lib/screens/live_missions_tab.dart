import 'dart:async';
import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../widgets/mission_card.dart';
import '../utils/strings.dart';
import '../services/mission_service.dart';

class LiveMissionsTab extends StatefulWidget {
  final String lang;
  final String currentSeason;
  final Function(String) onSeasonChange;
  final bool showWarnings;

  const LiveMissionsTab({
    super.key,
    required this.lang,
    required this.currentSeason,
    required this.onSeasonChange,
    this.showWarnings = true,
  });

  @override
  State<LiveMissionsTab> createState() => _LiveMissionsTabState();
}

class _LiveMissionsTabState extends State<LiveMissionsTab> {
  int _timeOffset = 0; // -1: Past, 0: Current, 1: Next
  late Timer _timer;
  int _secondsUntilNext = 0;

  final MissionService _missionService = MissionService();

  // ── 캐시: filter+sort 결과를 매 build()마다 재계산하지 않음 ──
  List<Mission> _cachedFiltered = [];
  DateTime _cachedTargetUtc = DateTime.utc(2000);
  String _cachedSeason = '';
  // 캐시 무효화 트리거용 (데이터 변경 시 증가)
  int _dataVersion = 0;
  int _cachedDataVersion = -1;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _missionService.addListener(_onDataChanged);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {
        _dataVersion++;
      });
    }
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final next30 = (now.minute < 30) ? 30 : 60;
    final target = DateTime(now.year, now.month, now.day, now.hour, next30, 0);
    final diff = target.difference(now).inSeconds;
    if (mounted) {
      setState(() {
        _secondsUntilNext = diff.clamp(0, 1800);
      });
    }
  }

  @override
  void dispose() {
    _missionService.removeListener(_onDataChanged);
    _timer.cancel();
    super.dispose();
  }

  void _changeOffset(int change) {
    setState(() {
      _timeOffset = (_timeOffset + change).clamp(-1, 1);
    });
  }

  void _changeSeason(int change) {
    final available = _missionService.availableSeasons;
    if (available.isEmpty) return;

    int currentIdx = available.indexOf(widget.currentSeason);
    if (currentIdx == -1) currentIdx = available.indexOf("s0");
    if (currentIdx == -1) currentIdx = 0;

    int nextIdx = (currentIdx + change) % available.length;
    if (nextIdx < 0) nextIdx = available.length - 1;

    widget.onSeasonChange(available[nextIdx]);
  }

  DateTime _getTargetUtcTime() {
    final now = DateTime.now().toUtc();
    final int minutes = (now.minute < 30) ? 0 : 30;
    final base = DateTime.utc(now.year, now.month, now.day, now.hour, minutes);
    return base.add(Duration(minutes: _timeOffset * 30));
  }

  /// 캐시된 필터+정렬 결과 반환. targetUtc/season/dataVersion 변경 시만 재계산.
  List<Mission> _getFilteredMissions(DateTime targetUtc) {
    if (targetUtc == _cachedTargetUtc &&
        widget.currentSeason == _cachedSeason &&
        _dataVersion == _cachedDataVersion) {
      return _cachedFiltered;
    }

    final sourceList = _missionService.getMissionsForTime(targetUtc);

    // 시즌 필터링
    final filteredList = sourceList
        .where((m) => m.seasons.contains(widget.currentSeason))
        .toList();

    // Double XP 상단 고정 정렬 (가장 높은 우선순위)
    filteredList.sort((a, b) {
      final aIsDouble = (a.buff == "Double XP");
      final bIsDouble = (b.buff == "Double XP");

      if (aIsDouble && !bIsDouble) return -1;
      if (!aIsDouble && bIsDouble) return 1;

      // Double XP가 아닌 미션들 간에는 바이옴 이름순으로 정렬 (일관성 유지)
      return a.biome.compareTo(b.biome);
    });

    _cachedFiltered = filteredList;
    _cachedTargetUtc = targetUtc;
    _cachedSeason = widget.currentSeason;
    _cachedDataVersion = _dataVersion;

    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    if (!_missionService.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    final String statusText;
    if (_timeOffset == -1) {
      statusText = i18n[widget.lang]!['past']!;
    } else if (_timeOffset == 1) {
      statusText = i18n[widget.lang]!['upcoming']!;
    } else {
      statusText = i18n[widget.lang]!['current']!;
    }

    final targetUtc = _getTargetUtcTime();
    final localDisplayTime = targetUtc.toLocal();
    final filteredList = _getFilteredMissions(targetUtc);

    final minutes = (_secondsUntilNext ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsUntilNext % 60).toString().padLeft(2, '0');

    final seasonLabel = widget.currentSeason == "s0"
        ? i18n[widget.lang]!['standard']!
        : "SEASON ${widget.currentSeason.replaceAll('s', '')}";

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          color: Colors.black45,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: _timeOffset > -1 ? Colors.orange : Colors.grey, size: 18),
                    onPressed: () => _changeOffset(-1),
                  ),
                  Column(
                    children: [
                      Text(statusText, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(
                        '${localDisplayTime.hour.toString().padLeft(2, '0')}:${localDisplayTime.minute.toString().padLeft(2, '0')} Local',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, color: _timeOffset < 1 ? Colors.orange : Colors.grey, size: 18),
                    onPressed: () => _changeOffset(1),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left, color: Colors.orange),
                    onPressed: () => _changeSeason(-1),
                  ),
                  Text(
                    seasonLabel,
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_right, color: Colors.orange),
                    onPressed: () => _changeSeason(1),
                  ),
                ],
              ),
              if (_timeOffset == 0) ...[
                Text(
                  '${i18n[widget.lang]!['time_left']} $minutes:$seconds',
                  style: const TextStyle(fontSize: 12, color: Colors.orangeAccent),
                ),
              ],
              if (_missionService.hasClockDrift)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, color: Colors.amber, size: 14),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            t('clock_drift', widget.lang),
                            style: const TextStyle(color: Colors.amber, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: Colors.orange,
            backgroundColor: const Color(0xFF1E1E1E),
            onRefresh: () => _missionService.forceRefresh(),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: filteredList.isEmpty
                  ? ListView(
                      key: const ValueKey('empty'),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                t('no_missions', widget.lang).replaceAll('{season}', seasonLabel),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      key: ValueKey('missions_${targetUtc.toIso8601String()}_${widget.currentSeason}'),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        return MissionCard(mission: filteredList[index], lang: widget.lang, showWarnings: widget.showWarnings);
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
