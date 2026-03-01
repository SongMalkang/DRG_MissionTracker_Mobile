import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/shout_data.dart';
import '../utils/strings.dart';
import '../widgets/minigame_banner.dart';
import '../widgets/minigame_list.dart';
import '../widgets/jet_boots_game.dart';

// ─── 서브 페이지 enum ───────────────────────────────────────────────────────

enum _DwarfPage { shouts, miniGameList, miniGame }

// ─── 메인 탭 위젯 (서브 네비게이션 허브) ─────────────────────────────────────

class DwarfVoiceTab extends StatefulWidget {
  final String lang;
  const DwarfVoiceTab({super.key, required this.lang});

  @override
  State<DwarfVoiceTab> createState() => _DwarfVoiceTabState();
}

class _DwarfVoiceTabState extends State<DwarfVoiceTab> {
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();
  int _currentPage = 0;

  // 서브 네비게이션 상태
  _DwarfPage _dwarfPage = _DwarfPage.shouts;
  bool _isForward = true; // 전환 방향: true=오른쪽→, false=←왼쪽

  @override
  void dispose() {
    _pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    final target = page.clamp(0, shoutItems.length - 1);
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _playRandomSound(ShoutItem item) async {
    if (item.sounds.isEmpty) return;
    final index = _random.nextInt(item.sounds.length);
    await _audioPlayer.stop();
    await _audioPlayer.play(
      AssetSource(item.sounds[index].replaceFirst('assets/', '')),
    );
  }

  void _navigateTo(_DwarfPage page) {
    setState(() {
      _isForward = page.index > _dwarfPage.index;
      _dwarfPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        final offset = _isForward
            ? const Offset(0.12, 0)
            : const Offset(-0.12, 0);
        return SlideTransition(
          position: Tween<Offset>(begin: offset, end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _buildCurrentPage(),
    );
  }

  Widget _buildCurrentPage() {
    switch (_dwarfPage) {
      case _DwarfPage.shouts:
        return _buildShoutsPage();
      case _DwarfPage.miniGameList:
        return MiniGameList(
          key: const ValueKey('miniGameList'),
          lang: widget.lang,
          onSelectGame: (gameId) => _navigateTo(_DwarfPage.miniGame),
          onBack: () => _navigateTo(_DwarfPage.shouts),
        );
      case _DwarfPage.miniGame:
        return JetBootsGame(
          key: const ValueKey('jetBootsGame'),
          lang: widget.lang,
          onBack: () => _navigateTo(_DwarfPage.miniGameList),
        );
    }
  }

  // ─── Shout 페이지 (기존 레이아웃 + 상단 배너 + pointing 전폭) ───────────

  Widget _buildShoutsPage() {
    return Stack(
      key: const ValueKey('shouts'),
      children: [
        // 메인 콘텐츠
        Column(
          children: [
            // MiniGame 배너 (상단)
            MiniGameBanner(
              lang: widget.lang,
              onTap: () => _navigateTo(_DwarfPage.miniGameList),
            ),

            // Carousel 영역
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // PageView
                  PageView.builder(
                    controller: _pageController,
                    itemCount: shoutItems.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      final item = shoutItems[index];
                      return _ShoutItemView(
                        item: item,
                        lang: widget.lang,
                        onTap: () => _playRandomSound(item),
                      );
                    },
                  ),

                  // 좌측 꺽쇠
                  Positioned(
                    left: 8,
                    child: _currentPage > 0
                        ? IconButton(
                            icon: const Icon(Icons.chevron_left,
                                color: Colors.orange, size: 36),
                            onPressed: () => _goToPage(_currentPage - 1),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // 우측 꺽쇠
                  Positioned(
                    right: 8,
                    child: _currentPage < shoutItems.length - 1
                        ? IconButton(
                            icon: const Icon(Icons.chevron_right,
                                color: Colors.orange, size: 36),
                            onPressed: () => _goToPage(_currentPage + 1),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // 페이지 인디케이터 (dots)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(shoutItems.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          i == _currentPage ? Colors.orange : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // pointing 이미지 높이만큼 하단 여백
            const SizedBox(height: 120),
          ],
        ),

        // 드워프 Pointing Meme — 하단 고정, 전폭
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/pointing.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 개별 항목 뷰 (이미지 + 탭 애니메이션) ─────────────────────────────────────

class _ShoutItemView extends StatefulWidget {
  final ShoutItem item;
  final String lang;
  final VoidCallback onTap;

  const _ShoutItemView({
    required this.item,
    required this.lang,
    required this.onTap,
  });

  @override
  State<_ShoutItemView> createState() => _ShoutItemViewState();
}

class _ShoutItemViewState extends State<_ShoutItemView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    // scale bounce: 1.0 → 0.9 → 1.08 → 1.0
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.9),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0),
        weight: 30,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 항목 이름
          Text(
            t(widget.item.nameKey, widget.lang),
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),

          // 탭 가능한 이미지
          GestureDetector(
            onTap: _handleTap,
            child: AnimatedBuilder(
              animation: _scaleAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnim.value,
                  child: child,
                );
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    widget.item.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, st) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.volume_up,
                          color: Colors.orange, size: 64),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 탭 안내 텍스트
          const Text(
            'TAP TO PLAY',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
