import 'dart:async';
import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../models/watchlist_filter.dart';
import '../widgets/mission_card.dart';
import '../utils/strings.dart';
import '../utils/constants.dart';
import '../services/mission_service.dart';
import '../services/watchlist_service.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/watchlist_modal.dart';

class LiveMissionsTab extends StatefulWidget {
  final String lang;
  final String currentSeason;
  final Function(String) onSeasonChange;
  final bool showWarnings;
  final bool isVisible;

  const LiveMissionsTab({
    super.key,
    required this.lang,
    required this.currentSeason,
    required this.onSeasonChange,
    this.showWarnings = true,
    this.isVisible = true,
  });

  @override
  State<LiveMissionsTab> createState() => _LiveMissionsTabState();
}

class _LiveMissionsTabState extends State<LiveMissionsTab> {
  int _timeOffset = 0; // -1: Past, 0: Current, 1: Next
  late Timer _timer;

  final MissionService _missionService = MissionService();
  final WatchlistService _watchlistService = WatchlistService();
  WatchlistFilter _watchlistFilter = WatchlistFilter.empty;

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
    _missionService.addListener(_onDataChanged);
    _loadWatchlistFilter();
    // 30초마다 슬롯 전환 감지 (카운트다운은 _CountdownText 위젯이 독립 처리)
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && widget.isVisible) setState(() {});
    });
  }

  Future<void> _loadWatchlistFilter() async {
    final filter = await _watchlistService.getFilter();
    if (mounted) {
      setState(() {
        _watchlistFilter = filter;
        _dataVersion++; // 캐시 무효화
      });
    }
  }

  Future<void> _openWatchlistModal() async {
    final result = await showWatchlistModal(
      context,
      currentFilter: _watchlistFilter,
      lang: widget.lang,
    );
    if (result != null && mounted) {
      setState(() {
        _watchlistFilter = result;
        _dataVersion++; // 캐시 무효화
      });
    }
  }

  @override
  void didUpdateWidget(covariant LiveMissionsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 탭이 다시 보이게 되면 즉시 갱신
    if (widget.isVisible && !oldWidget.isVisible) {
      setState(() {});
    }
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {
        _dataVersion++;
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

    // 정렬 우선순위: 1) Double XP  2) Watchlist 매칭  3) 바이옴명
    filteredList.sort((a, b) {
      final aIsDouble = (a.buff == "Double XP");
      final bIsDouble = (b.buff == "Double XP");

      if (aIsDouble && !bIsDouble) return -1;
      if (!aIsDouble && bIsDouble) return 1;

      // Watchlist 매칭 미션 상단 고정
      if (_watchlistFilter.isActive) {
        final aMatch = _watchlistFilter.matches(a);
        final bMatch = _watchlistFilter.matches(b);
        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
      }

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
      // 에러 상태: 초기화 실패
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

    final seasonLabel = widget.currentSeason == "s0"
        ? i18n[widget.lang]!['standard']!
        : "SEASON ${widget.currentSeason.replaceAll('s', '')}";

    return Stack(
      children: [
        Column(
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
                  if (_timeOffset == 0 && widget.isVisible) ...[
                    _CountdownText(lang: widget.lang),
                  ],
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
                            final mission = filteredList[index];
                            return MissionCard(
                              mission: mission,
                              lang: widget.lang,
                              showWarnings: widget.showWarnings,
                              isWatchlistMatch: _watchlistFilter.isActive && _watchlistFilter.matches(mission),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
        // ── Watchlist FAB ──
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'watchlist_fab',
            backgroundColor: _watchlistFilter.isActive
                ? Colors.cyanAccent
                : Colors.grey[850],
            onPressed: _openWatchlistModal,
            child: Icon(
              Icons.visibility,
              color: _watchlistFilter.isActive
                  ? Colors.black
                  : Colors.white54,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 독립 카운트다운 위젯 (매초 Text 1개만 재빌드) ────────────────────────────

class _CountdownText extends StatefulWidget {
  final String lang;
  const _CountdownText({required this.lang});

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  late Timer _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _calculate();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculate());
  }

  void _calculate() {
    final now = DateTime.now();
    final next30 = (now.minute < 30) ? 30 : 60;
    final target = DateTime(now.year, now.month, now.day, now.hour, next30, 0);
    final diff = target.difference(now).inSeconds;
    if (mounted) {
      setState(() {
        _secondsLeft = diff.clamp(0, AppConstants.missionRotationMinutes * 60);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return Text(
      '${i18n[widget.lang]!['time_left']} $minutes:$seconds',
      style: const TextStyle(fontSize: 12, color: Colors.orangeAccent),
    );
  }
}
