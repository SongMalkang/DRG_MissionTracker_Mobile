import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
import '../utils/strings.dart';

/// 업데이트 다이얼로그를 표시하는 전역 함수
///
/// [info.isForced]가 true면 닫기 불가 (강제 업데이트)
void showUpdateDialog(BuildContext context, UpdateInfo info, String lang) {
  showGeneralDialog(
    context: context,
    barrierDismissible: !info.isForced,
    barrierLabel: 'Update',
    barrierColor: Colors.black.withValues(alpha: 0.82),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) => _UpdateDialog(info: info, lang: lang),
    transitionBuilder: (ctx, anim1, anim2, child) => Transform.scale(
      scale: Curves.easeOutBack.transform(anim1.value),
      child: FadeTransition(opacity: anim1, child: child),
    ),
  );
}

class _UpdateDialog extends StatelessWidget {
  final UpdateInfo info;
  final String lang;

  const _UpdateDialog({required this.info, required this.lang});

  Future<void> _launchStore() async {
    final uri = Uri.tryParse(info.storeUrl);
    if (uri != null && uri.hasScheme) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForced = info.isForced;
    final accentColor = isForced ? Colors.redAccent : Colors.orange;
    final changelog =
        info.changelog[lang] ?? info.changelog['EN'] ?? '';

    return PopScope(
      // 강제 업데이트면 뒤로가기 차단
      canPop: !isForced,
      child: Center(
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
                    // ── 헤더 ────────────────────────────────────
                    _buildHeader(accentColor, isForced),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 버전 비교 행 ─────────────────────
                          _buildVersionRow(accentColor),

                          if (changelog.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child:
                                  Divider(color: Colors.white10, height: 1),
                            ),
                            // ── Changelog ───────────────────────
                            _buildChangelog(changelog),
                          ],

                          // 강제 업데이트 안내 문구
                          if (isForced) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.redAccent
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      color: Colors.redAccent, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      t('update_force_desc', lang),
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // ── 버튼 영역 ────────────────────────────────
                    _buildButtons(context, accentColor, isForced),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentColor, bool isForced) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.18),
            accentColor.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(
            isForced ? Icons.system_update : Icons.new_releases_outlined,
            color: accentColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            t(isForced ? 'update_required' : 'update_available', lang),
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow(Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _versionPill(
          t('update_ver_current', lang),
          info.currentVersion,
          Colors.white38,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.arrow_forward_rounded,
              color: accentColor.withValues(alpha: 0.6), size: 18),
        ),
        _versionPill(
          t('update_ver_new', lang),
          info.latestVersion,
          accentColor,
        ),
      ],
    );
  }

  Widget _versionPill(String label, String version, Color color) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Text(
            'v$version',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangelog(String changelog) {
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
          constraints: const BoxConstraints(maxHeight: 150),
          child: SingleChildScrollView(
            child: Text(
              changelog,
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

  Widget _buildButtons(
      BuildContext context, Color accentColor, bool isForced) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: isForced
          ? _forcedButton(accentColor)
          : _optionalButtons(context, accentColor),
    );
  }

  /// 강제 업데이트: 단일 버튼, 닫기 없음
  Widget _forcedButton(Color accentColor) {
    return InkWell(
      onTap: _launchStore,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Text(
          t('update_now', lang),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// 선택적 업데이트: 나중에 | 지금 업데이트
  Widget _optionalButtons(BuildContext context, Color accentColor) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Text(
                t('update_later', lang),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        Container(width: 1, height: 52, color: Colors.white10),
        Expanded(
          child: InkWell(
            onTap: _launchStore,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Text(
                t('update_now', lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
