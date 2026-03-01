import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/minigame_data.dart';
import '../utils/strings.dart';

/// 미니게임 선택 리스트 (테이블 형태)
class MiniGameList extends StatelessWidget {
  final String lang;
  final Function(String gameId) onSelectGame;
  final VoidCallback onBack;

  const MiniGameList({
    super.key,
    required this.lang,
    required this.onSelectGame,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 헤더 ────────────────────────────────────────────
        _buildHeader(),

        // ── 게임 리스트 ─────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: miniGameItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildGameTile(miniGameItems[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.18),
            Colors.orange.withValues(alpha: 0.04),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: Colors.white10),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.orange, size: 20),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 4),
          Text(
            'MINI GAMES',
            style: GoogleFonts.pressStart2p(
              fontSize: 12,
              color: Colors.orange,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTile(MiniGameItem game) {
    final isAvailable = game.isAvailable;

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.38,
      child: GestureDetector(
        onTap: isAvailable ? () => onSelectGame(game.id) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isAvailable
                  ? Colors.orange.withValues(alpha: 0.35)
                  : Colors.white10,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 좌측 아이콘
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? Colors.orange.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isAvailable ? Icons.rocket_launch : Icons.lock_outline,
                  color: isAvailable ? Colors.orange : Colors.white24,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),

              // 타이틀 + 설명
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(game.titleKey, lang),
                      style: GoogleFonts.pressStart2p(
                        fontSize: 9,
                        color: isAvailable ? Colors.orange : Colors.white38,
                        letterSpacing: 1.0,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t(game.descriptionKey, lang),
                      style: TextStyle(
                        fontSize: 11,
                        color: isAvailable ? Colors.white54 : Colors.white24,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // 우측 화살표 / 잠금
              Icon(
                isAvailable ? Icons.chevron_right : Icons.lock,
                color: isAvailable ? Colors.orange : Colors.white24,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
