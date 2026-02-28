import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/mission_card.dart';
import '../models/mission_model.dart';
import '../utils/strings.dart';
import '../services/mission_service.dart';

class LiveMissionsTab extends StatefulWidget {
  final String lang;
  final String currentSeason;
  final Function(String) onSeasonChange;

  const LiveMissionsTab({
    super.key,
    required this.lang,
    required this.currentSeason,
    required this.onSeasonChange,
  });

  @override
  State<LiveMissionsTab> createState() => _LiveMissionsTabState();
}

class _LiveMissionsTabState extends State<LiveMissionsTab> {
  int _timeOffset = 0; // -1: Past, 0: Current, 1: Next
  late Timer _timer;
  int _secondsUntilNext = 0;

  final MissionService _missionService = MissionService();

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
    if (mounted) setState(() {});
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final next30 = (now.minute < 30) ? 30 : 60;
    final target = DateTime(now.year, now.month, now.day, now.hour, next30, 0);
    if (mounted) {
      setState(() {
        _secondsUntilNext = target.difference(now).inSeconds;
        if (_secondsUntilNext <= 0) {
          _calculateTimeLeft();
        }
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
    DateTime base = DateTime.utc(now.year, now.month, now.day, now.hour, minutes);
    return base.add(Duration(minutes: _timeOffset * 30));
  }

  @override
  Widget build(BuildContext context) {
    if (!_missionService.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    String statusText;
    if (_timeOffset == -1) {
      statusText = i18n[widget.lang]!['past']!;
    } else if (_timeOffset == 1) {
      statusText = i18n[widget.lang]!['upcoming']!;
    } else {
      statusText = i18n[widget.lang]!['current']!;
    }

    DateTime targetUtc = _getTargetUtcTime();
    DateTime localDisplayTime = targetUtc.toLocal();
    List<Mission> sourceList = _missionService.getMissionsForTime(targetUtc);

    // 시즌 필터링
    List<Mission> filteredList = sourceList
        .where((m) => m.seasons.contains(widget.currentSeason))
        .toList();

    // Double XP 상단 고정 정렬 (가장 높은 우선순위)
    filteredList.sort((a, b) {
      bool aIsDouble = (a.buff == "Double XP");
      bool bIsDouble = (b.buff == "Double XP");

      if (aIsDouble && !bIsDouble) return -1;
      if (!aIsDouble && bIsDouble) return 1;

      // Double XP가 아닌 미션들 간에는 바이옴 이름순으로 정렬 (일관성 유지)
      return a.biome.compareTo(b.biome);
    });

    final minutes = (_secondsUntilNext ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsUntilNext % 60).toString().padLeft(2, '0');

    String seasonLabel = widget.currentSeason == "s0"
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
              ]
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: filteredList.isEmpty
                ? Center(
                    key: const ValueKey('empty'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          "No missions found for $seasonLabel\nat this time.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    key: ValueKey('missions_${targetUtc.toIso8601String()}_${widget.currentSeason}'),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return MissionCard(mission: filteredList[index], lang: widget.lang);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
