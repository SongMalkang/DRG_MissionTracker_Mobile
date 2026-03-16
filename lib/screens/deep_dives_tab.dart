import 'package:flutter/material.dart';
import '../utils/strings.dart';
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

  /// 현재 표시 중인 데이터의 주차 정보
  String? _dataWeekLabel() {
    final key = _ddService.dataThursdayKey;
    if (key == null) return null;
    // key format: "YYYY-MM-DD"
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
            dataWeekLabel: _dataWeekLabel(),
          ),
          const SizedBox(height: 12),

          // Deep Dive 카드들
          ...(_ddService.dives ?? []).map((dive) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DeepDiveCard(dive: dive, lang: widget.lang),
              )),
        ],
      ),
    );
  }
}

// ── 업데이트 배너 (3단계 상태 + 주차 정보) ───────────────────────────────────────

class _UpdateBanner extends StatelessWidget {
  final String nextUpdate;
  final String lang;
  final bool isStale;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final String? dataWeekLabel;

  const _UpdateBanner({
    required this.nextUpdate,
    required this.lang,
    required this.isStale,
    required this.isRefreshing,
    required this.onRefresh,
    this.dataWeekLabel,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
          // 주차 정보 표시 (데이터가 어느 주의 것인지)
          if (dataWeekLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              '${i18n[lang]!['dd_data_week'] ?? 'Data from week of'} $dataWeekLabel',
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
