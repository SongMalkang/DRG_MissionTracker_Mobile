import 'package:flutter/material.dart';
import '../data/overclock_data.dart';
import '../models/overclock_model.dart';
import '../services/overclock_collection_service.dart';
import '../utils/asset_helper.dart';
import '../utils/strings.dart';
import 'overclock_character_screen.dart';

// ─── 서브 페이지 enum ───────────────────────────────────

enum _OverclockPage { characterGrid, characterDetail }

// ─── 메인 탭 ────────────────────────────────────────────

class OverclockTab extends StatefulWidget {
  final String lang;
  const OverclockTab({super.key, required this.lang});

  @override
  State<OverclockTab> createState() => _OverclockTabState();
}

class _OverclockTabState extends State<OverclockTab> {
  _OverclockPage _page = _OverclockPage.characterGrid;
  DwarfCharacter? _selectedCharacter;
  Set<String> _collected = {};
  bool _isForward = true;

  @override
  void initState() {
    super.initState();
    _loadCollected();
  }

  Future<void> _loadCollected() async {
    final data = await OverclockCollectionService.getCollected();
    if (mounted) setState(() => _collected = data);
  }

  void _selectCharacter(DwarfCharacter character) {
    setState(() {
      _selectedCharacter = character;
      _isForward = true;
      _page = _OverclockPage.characterDetail;
    });
  }

  void _goBack() {
    setState(() {
      _isForward = false;
      _page = _OverclockPage.characterGrid;
    });
  }

  Future<void> _toggleOC(String id) async {
    final updated = await OverclockCollectionService.toggle(id);
    if (mounted) setState(() => _collected = updated);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _page == _OverclockPage.characterGrid,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          final offset = _isForward
              ? const Offset(0.12, 0)
              : const Offset(-0.12, 0);
          return SlideTransition(
            position:
                Tween<Offset>(begin: offset, end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _buildCurrentPage(),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_page) {
      case _OverclockPage.characterGrid:
        return _buildGrid();
      case _OverclockPage.characterDetail:
        return OverclockCharacterScreen(
          key: ValueKey('oc_detail_${_selectedCharacter!.name}'),
          character: _selectedCharacter!,
          lang: widget.lang,
          collected: _collected,
          onToggle: _toggleOC,
          onBack: _goBack,
        );
    }
  }

  void _showSyncModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) =>
          _LoadoutSyncModal(lang: widget.lang),
      transitionBuilder: (ctx, anim1, anim2, child) => Transform.scale(
        scale: Curves.easeOutBack.transform(anim1.value),
        child: FadeTransition(opacity: anim1, child: child),
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      key: const ValueKey('oc_grid'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 전체 진행률
          _buildOverallProgress(),
          const SizedBox(height: 16),
          // 2×2 캐릭터 그리드
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: allDwarves
                  .map((dwarf) => _CharacterCard(
                        character: dwarf,
                        lang: widget.lang,
                        collected: _collected,
                        onTap: () => _selectCharacter(dwarf),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Coming Soon 배너
          _ComingSoonBanner(
            lang: widget.lang,
            onTap: _showSyncModal,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgress() {
    final total =
        allDwarves.fold(0, (sum, d) => sum + d.totalOverclocks);
    final count = _collected.length;
    final progress = total > 0 ? count / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('oc_progress', widget.lang),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$count / $total',
                style: TextStyle(
                  color: count == total && total > 0
                      ? Colors.green
                      : Colors.orange,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                count == total && total > 0 ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 캐릭터 카드 ─────────────────────────────────────────

class _CharacterCard extends StatelessWidget {
  final DwarfCharacter character;
  final String lang;
  final Set<String> collected;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.character,
    required this.lang,
    required this.collected,
    required this.onTap,
  });

  int get _count {
    return character.weapons.fold(0, (sum, w) {
      return sum +
          w.overclocks.where((oc) => collected.contains(oc.id)).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = character.totalOverclocks;
    final count = _count;
    final isComplete = count == total;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isComplete
                ? Colors.green.withValues(alpha: 0.4)
                : Colors.white10,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 캐릭터 이미지 배경 (0.8배 축소하여 잘림 방지)
            Transform.scale(
              scale: 0.8,
              child: Image.asset(
                character.imagePath,
                fit: BoxFit.cover,
                errorBuilder: AssetHelper.assetErrorBuilder,
              ),
            ),
            // 그라디언트 오버레이
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
            // 이름 + 진행률
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 프로그레스 바
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: total > 0 ? count / total : 0,
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count / $total',
                    style: TextStyle(
                      color: isComplete ? Colors.green : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // 완료 체크
            if (isComplete)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Coming Soon 배너 ────────────────────────────────────

class _ComingSoonBanner extends StatelessWidget {
  final String lang;
  final VoidCallback onTap;

  const _ComingSoonBanner({required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.cyan.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.cyan.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.sync,
                color: Colors.cyan.withValues(alpha: 0.6), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        t('oc_sync_title', lang),
                        style: TextStyle(
                          color: Colors.cyan.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t('oc_sync_coming_soon', lang),
                          style: TextStyle(
                            color: Colors.cyan.withValues(alpha: 0.9),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t('oc_sync_subtitle', lang),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.2), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── 로드아웃 동기화 모달 ────────────────────────────────

class _LoadoutSyncModal extends StatelessWidget {
  final String lang;
  const _LoadoutSyncModal({required this.lang});

  static const _accent = Colors.cyan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 380,
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _accent.withValues(alpha: 0.4),
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
                  // 헤더
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.08),
                      border: Border(
                        bottom: BorderSide(
                            color: _accent.withValues(alpha: 0.15)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sync, color: _accent, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t('oc_sync_modal_title', lang),
                            style: const TextStyle(
                              color: _accent,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 본문
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('oc_sync_modal_body', lang),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 상태 표시
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _accent.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        _accent.withValues(alpha: 0.6)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    t('oc_sync_modal_status', lang),
                                    style: TextStyle(
                                      color: _accent.withValues(alpha: 0.8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            t('oc_sync_modal_note', lang),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 닫기
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1C1C1C),
                        border:
                            Border(top: BorderSide(color: Colors.white10)),
                      ),
                      child: Text(
                        t('close', lang),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _accent,
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
