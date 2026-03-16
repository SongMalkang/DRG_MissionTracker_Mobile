import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/shout_data.dart';
import '../utils/strings.dart';
import '../widgets/minigame_banner.dart';
import '../widgets/minigame_list.dart';
import '../widgets/jet_boots/jet_boots_game.dart';
import '../widgets/whack_a_mole/whack_a_mole_game.dart';
import '../widgets/survivor_game/survivor_game.dart';

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
  final AudioPlayer? _audioPlayer = kIsWeb ? null : AudioPlayer();
  final AudioPlayer? _mcAudioPlayer = kIsWeb ? null : AudioPlayer();
  final Random _random = Random();
  int _currentPage = 0;

  // 서브 네비게이션 상태
  _DwarfPage _dwarfPage = _DwarfPage.shouts;
  bool _isForward = true; // 전환 방향: true=오른쪽→, false=←왼쪽
  String? _selectedGameId;

  // 말풍선 상태
  String? _currentSubtitle;
  Timer? _bubbleDismissTimer;

  // MC 오버레이 상태
  String? _mcSubtitle;
  Timer? _mcDismissTimer;
  Timer? _mcTriggerTimer;

  // 항목별 탭 카운터
  final Map<String, int> _tapCounts = {};

  @override
  void dispose() {
    _pageController.dispose();
    _audioPlayer?.dispose();
    _mcAudioPlayer?.dispose();
    _bubbleDismissTimer?.cancel();
    _mcDismissTimer?.cancel();
    _mcTriggerTimer?.cancel();
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

    // 1. 기존 사운드 재생
    try {
      await _audioPlayer?.stop();
      await _audioPlayer?.play(
        AssetSource(item.sounds[index].replaceFirst('assets/', '')),
      );
    } catch (e) {
      debugPrint('Audio playback failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio playback failed'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    // 2. 말풍선 표시
    if (item.subtitles.isNotEmpty) {
      final subtitleIndex = index < item.subtitles.length
          ? index
          : _random.nextInt(item.subtitles.length);
      _bubbleDismissTimer?.cancel();
      setState(() {
        _currentSubtitle = item.subtitles[subtitleIndex];
      });
      _bubbleDismissTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _currentSubtitle = null);
      });
    }

    // 3. MC 트리거 확률 계산
    final count = (_tapCounts[item.id] ?? 0) + 1;
    _tapCounts[item.id] = count;

    final probability = ((count - 1) * 0.17).clamp(0.0, 1.0);
    if (_random.nextDouble() < probability && item.mcSubtitles.isNotEmpty) {
      // MC 트리거!
      _tapCounts[item.id] = 0;
      final mcIndex = _random.nextInt(item.mcSubtitles.length);

      // 800ms 딜레이 후 MC 오버레이 표시
      _mcTriggerTimer?.cancel();
      _mcTriggerTimer = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;

        // MC 사운드 재생 (mcSounds가 비어있지 않을 때만)
        if (item.mcSounds.isNotEmpty) {
          final mcSoundIndex = mcIndex < item.mcSounds.length
              ? mcIndex
              : _random.nextInt(item.mcSounds.length);
          _mcAudioPlayer?.stop();
          _mcAudioPlayer?.play(
            AssetSource(item.mcSounds[mcSoundIndex].replaceFirst('assets/', '')),
          );
        }

        _mcDismissTimer?.cancel();
        setState(() {
          _mcSubtitle = item.mcSubtitles[mcIndex];
        });
        _mcDismissTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _mcSubtitle = null);
        });
      });
    }
  }

  void _navigateTo(_DwarfPage page) {
    setState(() {
      _isForward = page.index > _dwarfPage.index;
      _dwarfPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _dwarfPage == _DwarfPage.shouts,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_dwarfPage == _DwarfPage.miniGame) {
            _navigateTo(_DwarfPage.miniGameList);
          } else if (_dwarfPage == _DwarfPage.miniGameList) {
            _navigateTo(_DwarfPage.shouts);
          }
        }
      },
      child: AnimatedSwitcher(
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
    ),
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
          onSelectGame: (gameId) {
            setState(() => _selectedGameId = gameId);
            _navigateTo(_DwarfPage.miniGame);
          },
          onBack: () => _navigateTo(_DwarfPage.shouts),
        );
      case _DwarfPage.miniGame:
        return _buildGameWidget();
    }
  }

  void _goBackToList() => _navigateTo(_DwarfPage.miniGameList);

  Widget _buildGameWidget() {
    switch (_selectedGameId) {
      case 'whack_a_mole':
        return WhackAMoleGame(
          key: const ValueKey('whackAMoleGame'),
          lang: widget.lang,
          onBack: _goBackToList,
        );
      case 'survivor':
        return SurvivorGame(
          key: const ValueKey('survivorGame'),
          lang: widget.lang,
          onBack: _goBackToList,
        );
      case 'jet_boots':
      default:
        return JetBootsGame(
          key: const ValueKey('jetBootsGame'),
          lang: widget.lang,
          onBack: _goBackToList,
        );
    }
  }

  // ─── Shout 페이지 (기존 레이아웃 + 말풍선 + MC 오버레이) ───────────

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

        // 말풍선 — pointing 이미지 위 중앙
        Positioned(
          left: 40,
          right: 40,
          bottom: 105,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            reverseDuration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: _currentSubtitle != null
                ? _SpeechBubble(
                    key: ValueKey(_currentSubtitle),
                    text: _currentSubtitle!,
                  )
                : const SizedBox.shrink(key: ValueKey('empty_bubble')),
          ),
        ),

        // MC 오버레이 — 화면 중앙, 최상위
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _mcSubtitle == null,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              reverseDuration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: _mcSubtitle != null
                  ? Center(
                      key: ValueKey(_mcSubtitle),
                      child: _McOverlay(text: _mcSubtitle!),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty_mc')),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 말풍선 위젯 ─────────────────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 말풍선 본체
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'RussoOne',
              fontSize: 12,
              color: Colors.orange,
              height: 1.3,
            ),
          ),
        ),
        // 꼬리 (하단 삼각형)
        CustomPaint(
          size: const Size(24, 12),
          painter: _BubbleTailPainter(
            fillColor: const Color(0xFF1A1A1A),
            borderColor: Colors.orange.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ─── 말풍선 꼬리 CustomPainter ───────────────────────────────────────────────

class _BubbleTailPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  _BubbleTailPainter({required this.fillColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Border (left and right edges only, top is covered by bubble)
    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);

    canvas.drawPath(
      borderPath,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      fillColor != oldDelegate.fillColor ||
      borderColor != oldDelegate.borderColor;
}

// ─── MC 오버레이 위젯 ────────────────────────────────────────────────────────

class _McOverlay extends StatelessWidget {
  final String text;
  const _McOverlay({required this.text});

  static const _mcBlue = Color(0xFF4FC3F7);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _mcBlue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _mcBlue.withValues(alpha: 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단: 안테나 아이콘 + MISSION CONTROL 라벨
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cell_tower, color: _mcBlue, size: 18),
              SizedBox(width: 6),
              Text(
                'MISSION CONTROL',
                style: TextStyle(
                  color: _mcBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // MC 자막
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
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
