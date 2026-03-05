import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/watchlist_filter.dart';
import '../services/watchlist_service.dart';
import '../utils/strings.dart';

/// 모든 미션 타입 목록
const List<String> _allMissionTypes = [
  'Mining Expedition', 'Egg Hunt', 'On-Site Refining',
  'Point Extraction', 'Salvage Operation', 'Escort Duty',
  'Elimination', 'Industrial Sabotage', 'Deep Scan', 'Heavy Excavation',
];

/// 모든 바이옴 목록
const List<String> _allBiomes = [
  'Azure Weald', 'Crystalline Caverns', 'Dense Biozone',
  'Fungus Bogs', 'Glacial Strata', 'Hollow Bough',
  'Magma Core', 'Radioactive Exclusion Zone', 'Salt Pits',
  'Sandblasted Corridors', 'Ossuary Depths',
];

/// 모든 버프 목록
const List<String> _allBuffs = [
  'Double XP', 'Gold Rush', 'Mineral Mania',
  'Low Gravity', 'Rich Atmosphere', 'Critical Weakness',
  'Golden Bugs', 'Volatile Guts', 'Blood Sugar',
];

/// 모든 경고 목록
const List<String> _allWarnings = [
  'Cave Leech Cluster', 'Duck and Cover', 'Ebonite Outbreak',
  'Elite Threat', 'Exploder Infestation', 'Haunted Cave',
  'Lethal Enemies', 'Lithophage Outbreak', 'Low Oxygen',
  'Mactera Plague', 'Parasites', 'Pit Jaw Colony',
  'Regenerative Bugs', 'Rival Presence', 'Scrab Nesting Grounds',
  'Shield Disruption', 'Swarmageddon',
];

/// Watchlist 설정 모달을 표시합니다.
/// [onSave] 콜백으로 저장된 필터를 Live 페이지에 전달합니다.
Future<WatchlistFilter?> showWatchlistModal(
  BuildContext context, {
  required WatchlistFilter currentFilter,
  required String lang,
}) {
  return showGeneralDialog<WatchlistFilter>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Watchlist',
    barrierColor: Colors.black.withValues(alpha: 0.75),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim1, anim2) => _WatchlistModalContent(
      initialFilter: currentFilter,
      lang: lang,
    ),
    transitionBuilder: (ctx, anim1, anim2, child) {
      return Transform.scale(
        scale: Curves.easeOutBack.transform(anim1.value),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
  );
}

class _WatchlistModalContent extends StatefulWidget {
  final WatchlistFilter initialFilter;
  final String lang;

  const _WatchlistModalContent({
    required this.initialFilter,
    required this.lang,
  });

  @override
  State<_WatchlistModalContent> createState() => _WatchlistModalContentState();
}

class _WatchlistModalContentState extends State<_WatchlistModalContent> {
  late bool _enabled;
  late Set<String> _selectedTypes;
  late Set<String> _selectedBiomes;
  late Set<String> _selectedBuffs;
  late Set<String> _selectedWarnings;

  final WatchlistService _service = WatchlistService();

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialFilter.enabled;
    _selectedTypes = Set.from(widget.initialFilter.missionTypes);
    _selectedBiomes = Set.from(widget.initialFilter.biomes);
    _selectedBuffs = Set.from(widget.initialFilter.buffs);
    _selectedWarnings = Set.from(widget.initialFilter.warnings);
  }

  WatchlistFilter _buildFilter() {
    return WatchlistFilter(
      enabled: _enabled,
      missionTypes: _selectedTypes,
      biomes: _selectedBiomes,
      buffs: _selectedBuffs,
      warnings: _selectedWarnings,
    );
  }

  Future<void> _save() async {
    final filter = _buildFilter();
    await _service.saveFilter(filter);
    if (mounted) Navigator.of(context).pop(filter);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: screenHeight * 0.85,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _enabled ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.white12,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 헤더 ──
                _buildHeader(lang),

                // ── 플랫폼 알림 안내 (Web/PWA) ──
                if (kIsWeb)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t('watchlist_android_only', lang),
                            style: const TextStyle(color: Colors.amber, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── 바디 (스크롤) ──
                Flexible(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: _enabled
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                _buildSection(
                                  title: t('watchlist_type', lang),
                                  allItems: _allMissionTypes,
                                  selected: _selectedTypes,
                                  lang: lang,
                                ),
                                _buildSection(
                                  title: t('watchlist_biome', lang),
                                  allItems: _allBiomes,
                                  selected: _selectedBiomes,
                                  lang: lang,
                                ),
                                _buildSection(
                                  title: t('watchlist_buff', lang),
                                  allItems: _allBuffs,
                                  selected: _selectedBuffs,
                                  lang: lang,
                                ),
                                _buildSection(
                                  title: t('watchlist_warning', lang),
                                  allItems: _allWarnings,
                                  selected: _selectedWarnings,
                                  lang: lang,
                                ),
                                const SizedBox(height: 8),
                                _buildSummary(lang),
                                const SizedBox(height: 12),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),

                // ── 저장 버튼 ──
                _buildSaveButton(lang),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility,
            color: _enabled ? Colors.cyanAccent : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('watchlist', lang),
                  style: TextStyle(
                    color: _enabled ? Colors.cyanAccent : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  t('watchlist_desc', lang),
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Switch(
            value: _enabled,
            activeThumbColor: Colors.cyanAccent,
            onChanged: (v) => setState(() => _enabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> allItems,
    required Set<String> selected,
    required String lang,
  }) {
    final hasSelection = selected.isNotEmpty;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: hasSelection ? Colors.cyanAccent : Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (hasSelection) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${selected.length}',
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        iconColor: Colors.white38,
        collapsedIconColor: Colors.white38,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: allItems.map((item) {
              final isSelected = selected.contains(item);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selected.remove(item);
                    } else {
                      selected.add(item);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.cyanAccent.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? Colors.cyanAccent.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    t(item, lang),
                    style: TextStyle(
                      color: isSelected ? Colors.cyanAccent : Colors.white54,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSummary(String lang) {
    final parts = <String>[];

    if (_selectedTypes.isNotEmpty) {
      parts.add(_selectedTypes.map((e) => t(e, lang)).join(', '));
    }
    if (_selectedBiomes.isNotEmpty) {
      parts.add(_selectedBiomes.map((e) => t(e, lang)).join(', '));
    }
    if (_selectedBuffs.isNotEmpty) {
      parts.add(_selectedBuffs.map((e) => t(e, lang)).join(', '));
    }
    if (_selectedWarnings.isNotEmpty) {
      parts.add(_selectedWarnings.map((e) => t(e, lang)).join(', '));
    }

    final summary = parts.isEmpty ? t('watchlist_no_condition', lang) : parts.join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('watchlist_summary', lang),
            style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: TextStyle(
              color: parts.isEmpty ? Colors.white24 : Colors.cyanAccent.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            t('watchlist_save', lang),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
