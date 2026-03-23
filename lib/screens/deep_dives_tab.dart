import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/strings.dart';
import '../utils/constants.dart';
import '../services/deep_dive_service.dart';
import '../widgets/deep_dive_card.dart';

// ── Deep Dive 탭 ───────────────────────────────────────────────────────────────

class DeepDivesTab extends StatefulWidget {
  final String lang;
  const DeepDivesTab({super.key, required this.lang});

  @override
  State<DeepDivesTab> createState() => _DeepDivesTabState();
}

class _DeepDivesTabState extends State<DeepDivesTab> {
  final DeepDiveService _ddService = DeepDiveService();

  // ── Feature 4: 새 데이터 도착 감지 ──
  bool _wasStale = false;
  bool _showSuccessBanner = false;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _ddService.addListener(_onDataChanged);
    _ddService.loadDeepDives();
    _wasStale = _ddService.isDataStale;
  }

  void _onDataChanged() {
    if (!mounted) return;
    final currentlyStale = _ddService.isDataStale;
    // stale → fresh 전환 감지 (데이터가 존재할 때만)
    if (_wasStale && !currentlyStale && _ddService.dives != null) {
      _showSuccessBanner = true;
      _successTimer?.cancel();
      _successTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSuccessBanner = false);
      });
    }
    _wasStale = currentlyStale;
    setState(() {});
  }

  @override
  void dispose() {
    _ddService.removeListener(_onDataChanged);
    _successTimer?.cancel();
    super.dispose();
  }

  /// 현재 표시 중인 데이터의 주차 정보
  String? _dataWeekLabel() {
    final key = _ddService.dataThursdayKey;
    if (key == null) return null;
    final parts = key.split('-');
    if (parts.length < 3) return null;
    return '${parts[1]}/${parts[2]}';
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
      // Feature 6: 폴링 중 수동 새로고침 시 안내
      onRefresh: () {
        if (_ddService.isThursdayPolling) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                i18n[widget.lang]!['dd_polling_active_snack'] ??
                    'Auto-checking is active. Will refresh automatically.',
              ),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 2),
            ),
          );
          return _ddService.loadDeepDives(forceRefresh: true);
        }
        return _ddService.loadDeepDives(forceRefresh: true);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          // 업데이트 안내 배너
          _UpdateBanner(
            nextThursday: _ddService.nextThursday(),
            lang: widget.lang,
            isStale: _ddService.isDataStale,
            isRefreshing: _ddService.isRefreshing,
            isPolling: _ddService.isThursdayPolling,
            pollAttempt: _ddService.pollAttempt,
            nextPollTime: _ddService.nextPollTime,
            onRefresh: () => _ddService.loadDeepDives(forceRefresh: true),
            dataWeekLabel: _dataWeekLabel(),
            showSuccess: _showSuccessBanner,
          ),
          const SizedBox(height: 12),

          // Deep Dive 카드들
          ...(_ddService.dives ?? []).map((dive) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DeepDiveCard(
                  dive: dive,
                  lang: widget.lang,
                  isStale: _ddService.isDataStale,
                ),
              )),
        ],
      ),
    );
  }
}

// ── 배너 상태 ───────────────────────────────────────────────────────────────────

enum _BannerState { success, polling, stale, preReset, normal }

// ── 업데이트 배너 (5단계 상태 머신 + 실시간 카운트다운) ────────────────────────────

class _UpdateBanner extends StatefulWidget {
  final DateTime nextThursday;
  final String lang;
  final bool isStale;
  final bool isRefreshing;
  final bool isPolling;
  final int pollAttempt;
  final DateTime? nextPollTime;
  final VoidCallback onRefresh;
  final String? dataWeekLabel;
  final bool showSuccess;

  const _UpdateBanner({
    required this.nextThursday,
    required this.lang,
    required this.isStale,
    required this.isRefreshing,
    required this.isPolling,
    required this.pollAttempt,
    this.nextPollTime,
    required this.onRefresh,
    this.dataWeekLabel,
    this.showSuccess = false,
  });

  @override
  State<_UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<_UpdateBanner> {
  Timer? _ticker;
  Duration _timeUntilReset = Duration.zero;
  int _secondsUntilPoll = 0;
  bool _lastWasPolling = false;

  @override
  void initState() {
    super.initState();
    _recalc();
    _startTicker();
  }

  @override
  void didUpdateWidget(covariant _UpdateBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPolling != _lastWasPolling) {
      _startTicker();
    }
    _recalc();
  }

  void _startTicker() {
    _ticker?.cancel();
    _lastWasPolling = widget.isPolling;
    final interval = widget.isPolling
        ? const Duration(seconds: 1)
        : const Duration(seconds: 60);
    _ticker = Timer.periodic(interval, (_) => _recalc());
  }

  void _recalc() {
    if (!mounted) return;
    setState(() {
      _timeUntilReset = widget.nextThursday.difference(DateTime.now());
      if (_timeUntilReset.isNegative) _timeUntilReset = Duration.zero;
      if (widget.nextPollTime != null) {
        _secondsUntilPoll = widget.nextPollTime!
            .difference(DateTime.now())
            .inSeconds
            .clamp(0, 9999);
      } else {
        _secondsUntilPoll = 0;
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  _BannerState _currentState() {
    if (widget.showSuccess) return _BannerState.success;
    if (widget.isPolling || (widget.isStale && widget.isRefreshing)) {
      return _BannerState.polling;
    }
    if (widget.isStale) return _BannerState.stale;
    // 리셋 30분 전
    if (_timeUntilReset.inMinutes <= 30 && _timeUntilReset > Duration.zero) {
      return _BannerState.preReset;
    }
    return _BannerState.normal;
  }

  String _formatCountdown(Duration d) {
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m';
    }
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final state = _currentState();
    final Color bannerColor;
    final IconData bannerIcon;
    final bool showSpinner;
    final String mainText;
    final List<String> subLines = [];

    switch (state) {
      case _BannerState.success:
        bannerColor = Colors.green;
        bannerIcon = Icons.check_circle;
        showSpinner = false;
        mainText =
            i18n[widget.lang]!['dd_fresh_data'] ?? 'New Deep Dive data received!';

      case _BannerState.polling:
        bannerColor = Colors.orange;
        bannerIcon = Icons.hourglass_top;
        showSpinner = widget.isRefreshing;
        mainText =
            i18n[widget.lang]!['dd_poll_title'] ?? 'Deep Dive reset! Waiting for new data...';
        // 다음 체크 카운트다운
        final pollMin = _secondsUntilPoll ~/ 60;
        final pollSec = (_secondsUntilPoll % 60).toString().padLeft(2, '0');
        final nextCheckLabel =
            i18n[widget.lang]!['dd_poll_next_check'] ?? 'Auto-checking... next check';
        subLines.add(
          '$nextCheckLabel $pollMin:$pollSec'
          '  (${widget.pollAttempt}/${AppConstants.ddPollMaxAttempts})',
        );
        if (widget.dataWeekLabel != null) {
          final showingOld =
              i18n[widget.lang]!['dd_poll_showing_old'] ?? "Showing last week's data";
          subLines.add('$showingOld (${widget.dataWeekLabel})');
        }

      case _BannerState.stale:
        bannerColor = Colors.orange;
        bannerIcon = Icons.hourglass_top;
        showSpinner = widget.isRefreshing;
        mainText =
            i18n[widget.lang]!['dd_refreshing'] ?? 'Checking for new Deep Dive data...';
        if (widget.dataWeekLabel != null) {
          subLines.add(
            '${i18n[widget.lang]!['dd_data_week'] ?? 'Data from week of'} ${widget.dataWeekLabel}',
          );
        }

      case _BannerState.preReset:
        bannerColor = Colors.amber;
        bannerIcon = Icons.timer;
        showSpinner = false;
        final imminent =
            i18n[widget.lang]!['dd_reset_imminent'] ?? 'Deep Dive reset imminent!';
        final minLeft =
            i18n[widget.lang]!['dd_minutes_left'] ?? 'min left';
        mainText = '$imminent ${_timeUntilReset.inMinutes}$minLeft';

      case _BannerState.normal:
        bannerColor = Colors.blueAccent;
        bannerIcon = Icons.update;
        showSpinner = false;
        final next = widget.nextThursday.toLocal();
        final dateStr =
            '${next.month}/${next.day}  ${next.hour.toString().padLeft(2, '0')}:00';
        mainText =
            '${i18n[widget.lang]!['dd_next_update'] ?? 'Next Update:'}  $dateStr';
        // 카운트다운 서브라인
        if (_timeUntilReset > Duration.zero) {
          final prefix =
              i18n[widget.lang]!['dd_countdown_prefix'] ?? 'Next reset in';
          subLines.add('$prefix ${_formatCountdown(_timeUntilReset)}');
        }
        if (widget.dataWeekLabel != null) {
          subLines.add(
            '${i18n[widget.lang]!['dd_data_week'] ?? 'Data from week of'} ${widget.dataWeekLabel}',
          );
        }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bannerColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (showSpinner)
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
                  mainText,
                  style: TextStyle(
                    color: bannerColor.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onRefresh,
                child: Icon(Icons.refresh, color: bannerColor, size: 18),
              ),
            ],
          ),
          // 서브라인들
          for (final line in subLines) ...[
            const SizedBox(height: 4),
            Text(
              line,
              style: TextStyle(
                color: bannerColor.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
