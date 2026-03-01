import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/strings.dart';

/// Shout 페이지 상단에 표시되는 픽셀/아타리 미감의 MiniGame 배너
class MiniGameBanner extends StatelessWidget {
  final String lang;
  final VoidCallback onTap;

  const MiniGameBanner({super.key, required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1200),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            // 픽셀 게임 아이콘
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.videogame_asset,
                color: Colors.orange,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // 타이틀 + 부제
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('minigame_banner_title', lang),
                    style: GoogleFonts.pressStart2p(
                      fontSize: 10,
                      color: Colors.orange,
                      letterSpacing: 1.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    t('minigame_banner_subtitle', lang),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white24,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            // 우측 chevron
            const Icon(
              Icons.chevron_right,
              color: Colors.orange,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
