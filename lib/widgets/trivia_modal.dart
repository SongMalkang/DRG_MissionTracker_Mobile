import 'package:flutter/material.dart';
import '../data/trivia_data.dart';
import '../utils/strings.dart';

/// 트리비아 모달을 표시하는 전역 함수
void showTriviaModal(
  BuildContext context, {
  required String itemKey,
  required String lang,
  required String? iconPath,
  required Color accentColor,
}) {
  final entry = triviaData[itemKey]?[lang];
  if (entry == null) return;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.75),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim1, anim2) => _TriviaDialog(
      itemKey: itemKey,
      lang: lang,
      iconPath: iconPath,
      accentColor: accentColor,
      entry: entry,
    ),
    transitionBuilder: (ctx, anim1, anim2, child) => Transform.scale(
      scale: Curves.easeOutBack.transform(anim1.value),
      child: FadeTransition(opacity: anim1, child: child),
    ),
  );
}

class _TriviaDialog extends StatelessWidget {
  final String itemKey;
  final String lang;
  final String? iconPath;
  final Color accentColor;
  final Map<String, String> entry;

  const _TriviaDialog({
    required this.itemKey,
    required this.lang,
    required this.iconPath,
    required this.accentColor,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final desc = entry['desc'] ?? '';
    final tipsRaw = entry['tips'] ?? '';
    final tips = tipsRaw.split('\n').where((s) => s.isNotEmpty).toList();
    final translatedName = t(itemKey, lang);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 380,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.5),
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
                      color: accentColor.withValues(alpha: 0.1),
                      border: Border(
                        bottom: BorderSide(
                            color: accentColor.withValues(alpha: 0.2)),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (iconPath != null) ...[
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: Image.asset(
                              iconPath!,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.info_outline,
                                color: accentColor,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            translatedName,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 스크롤 본문
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 설명
                          Text(
                            desc,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),

                          // 팁
                          if (tips.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              i18n[lang]?['trivia_tips'] ?? 'Tips',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...tips.map(
                              (tip) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.arrow_right,
                                        color: accentColor.withValues(
                                            alpha: 0.6),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 4),
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
                        border: Border(
                            top: BorderSide(color: Colors.white10)),
                      ),
                      child: Text(
                        i18n[lang]?['trivia_close'] ??
                            i18n[lang]?['close'] ??
                            'CLOSE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accentColor,
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
