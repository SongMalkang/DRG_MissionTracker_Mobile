import 'package:flutter/material.dart';
import '../models/overclock_model.dart';
import '../utils/asset_helper.dart';
import '../utils/strings.dart';

/// 오버클럭 상세 모달 표시
void showOverclockDetailModal(
  BuildContext context, {
  required Overclock overclock,
  required String lang,
  required bool isCollected,
  required VoidCallback onToggle,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.75),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim1, anim2) => _OverclockDetailDialog(
      overclock: overclock,
      lang: lang,
      isCollected: isCollected,
      onToggle: onToggle,
    ),
    transitionBuilder: (ctx, anim1, anim2, child) => Transform.scale(
      scale: Curves.easeOutBack.transform(anim1.value),
      child: FadeTransition(opacity: anim1, child: child),
    ),
  );
}

class _OverclockDetailDialog extends StatelessWidget {
  final Overclock overclock;
  final String lang;
  final bool isCollected;
  final VoidCallback onToggle;

  const _OverclockDetailDialog({
    required this.overclock,
    required this.lang,
    required this.isCollected,
    required this.onToggle,
  });

  Color _tierColor() {
    switch (overclock.tier) {
      case OverclockTier.clean:
        return Colors.green;
      case OverclockTier.balanced:
        return Colors.orange;
      case OverclockTier.unstable:
        return Colors.redAccent;
    }
  }

  String _tierLabel() {
    switch (overclock.tier) {
      case OverclockTier.clean:
        return t('oc_tier_clean', lang);
      case OverclockTier.balanced:
        return t('oc_tier_balanced', lang);
      case OverclockTier.unstable:
        return t('oc_tier_unstable', lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _tierColor();

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
                color: color.withValues(alpha: 0.5),
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
                      color: color.withValues(alpha: 0.1),
                      border: Border(
                        bottom:
                            BorderSide(color: color.withValues(alpha: 0.2)),
                      ),
                    ),
                    child: Row(
                      children: [
                        // OC 아이콘
                        Image.asset(
                          AssetHelper.getOverclockImage(overclock.icon),
                          width: 32,
                          height: 32,
                          errorBuilder: (ctx, e, st) =>
                              Icon(Icons.extension, color: color, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                overclock.name,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // 티어 뱃지
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _tierLabel(),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 효과 설명
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('oc_effect', lang),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            overclock.effect,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 수집 토글
                          InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              onToggle();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isCollected
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCollected
                                      ? Colors.green.withValues(alpha: 0.3)
                                      : Colors.white12,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isCollected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isCollected
                                        ? Colors.green
                                        : Colors.white38,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isCollected
                                        ? t('oc_collected', lang)
                                        : t('oc_not_collected', lang),
                                    style: TextStyle(
                                      color: isCollected
                                          ? Colors.green
                                          : Colors.white38,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 닫기 버튼
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
                        style: TextStyle(
                          color: color,
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
