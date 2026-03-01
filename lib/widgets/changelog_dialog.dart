import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/changelog_data.dart';
import '../utils/strings.dart';

const String _seenVersionKey = 'changelog_seen_version';

/// 앱 시작 시 호출: 현재 버전의 changelog를 아직 안 봤으면 팝업 표시
Future<void> checkAndShowChangelog(BuildContext context, String lang) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final seenVersion = prefs.getString(_seenVersionKey) ?? '';
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // 이미 이 버전의 changelog를 봤으면 skip
    if (seenVersion == currentVersion) return;

    // 이 버전의 changelog가 정의되어 있는지 확인
    if (!changelogData.containsKey(currentVersion)) return;

    if (!context.mounted) return;
    showChangelogDialog(context, lang, currentVersion);
  } catch (_) {
    // 실패 시 무시 (앱 사용에 지장 없음)
  }
}

/// Changelog 다이얼로그를 직접 표시 (디버그 테스트용으로도 사용)
void showChangelogDialog(BuildContext context, String lang, String version) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Changelog',
    barrierColor: Colors.black.withValues(alpha: 0.82),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) =>
        _ChangelogDialog(lang: lang, version: version),
    transitionBuilder: (ctx, anim1, anim2, child) => Transform.scale(
      scale: Curves.easeOutBack.transform(anim1.value),
      child: FadeTransition(opacity: anim1, child: child),
    ),
  );
}

class _ChangelogDialog extends StatelessWidget {
  final String lang;
  final String version;

  const _ChangelogDialog({required this.lang, required this.version});

  Future<void> _dismiss(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seenVersionKey, version);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Colors.orange;
    final versionChangelog = changelogData[version] ?? {};
    final content = versionChangelog[lang] ?? versionChangelog['EN'] ?? '';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.18),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── 헤더 ──────────────────────────────────
                  _buildHeader(),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 버전 Pill ─────────────────────────
                        _buildVersionPill(),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: Colors.white10, height: 1),
                        ),
                        // ── Changelog 내용 ────────────────────
                        _buildContent(content),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // ── 확인 버튼 ───────────────────────────────
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white10)),
                    ),
                    child: InkWell(
                      onTap: () => _dismiss(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          t('changelog_ok', lang),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 14,
                          ),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.18),
            Colors.orange.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Colors.orange,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            t('changelog_title', lang),
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionPill() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
        ),
        child: Text(
          'v$version',
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('update_changelog', lang).toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.7,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
