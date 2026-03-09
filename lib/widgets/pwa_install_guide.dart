import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';

/// PWA 설치 가이드 다이얼로그를 표시한다.
void showPwaInstallGuide(BuildContext context, String lang) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'PWA Install Guide',
    barrierColor: Colors.black.withValues(alpha: 0.82),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) => _PwaInstallGuideDialog(lang: lang),
    transitionBuilder: (ctx, anim1, anim2, child) => Transform.scale(
      scale: Curves.easeOutBack.transform(anim1.value),
      child: Opacity(opacity: anim1.value, child: child),
    ),
  );
}

class _PwaInstallGuideDialog extends StatelessWidget {
  final String lang;
  const _PwaInstallGuideDialog({required this.lang});

  @override
  Widget build(BuildContext context) {
    final langMap = i18n[lang]!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.install_mobile,
                          color: Colors.orange, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          langMap['pwa_guide_title'] ?? 'Install as App',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close,
                            color: Colors.white38, size: 20),
                      ),
                    ],
                  ),
                ),

                // 설명
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    langMap['pwa_guide_desc'] ??
                        'Install Bosco Terminal as an app for a full-screen, app-like experience.',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12, height: 1.4),
                  ),
                ),

                // 플랫폼별 가이드 카드
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        // ── 알림 지원 현황 요약 ──
                        _NotifSupportBanner(lang: lang),
                        const SizedBox(height: 12),
                        _PlatformCard(
                          icon: Icons.android,
                          iconColor: const Color(0xFF3DDC84),
                          title: 'Android (Chrome)',
                          notifSupport: _NotifSupport.none,
                          notifLabel: _notifNoneLabel(lang),
                          steps: _getAndroidSteps(lang),
                        ),
                        const SizedBox(height: 10),
                        _PlatformCard(
                          icon: Icons.apple,
                          iconColor: Colors.white,
                          title: 'iOS (Safari)',
                          notifSupport: _NotifSupport.none,
                          notifLabel: _notifNoneLabel(lang),
                          steps: _getIosSteps(lang),
                        ),
                        const SizedBox(height: 10),
                        _PlatformCard(
                          icon: Icons.desktop_windows,
                          iconColor: const Color(0xFF64B5F6),
                          title: langMap['pwa_desktop_title'] ??
                              'PC (Chrome / Edge)',
                          notifSupport: _NotifSupport.full,
                          notifLabel: _notifFullLabel(lang),
                          steps: _getDesktopSteps(lang),
                        ),
                        const SizedBox(height: 14),
                        // ── Android APK 다운로드 카드 ──
                        _ApkDownloadCard(lang: lang),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 알림 지원 라벨 ─────────────────────────────────────────────────────

  static String _notifFullLabel(String lang) {
    switch (lang) {
      case 'KR': return '알림 지원';
      case 'CN': return '支持通知';
      default:   return 'Notifications supported';
    }
  }

  static String _notifNoneLabel(String lang) {
    switch (lang) {
      case 'KR': return '알림 미지원';
      case 'CN': return '不支持通知';
      default:   return 'No notifications';
    }
  }

  // ── 플랫폼별 설치 스텝 ──────────────────────────────────────────────────

  List<_StepInfo> _getAndroidSteps(String lang) {
    switch (lang) {
      case 'KR':
        return const [
          _StepInfo(Icons.more_vert, 'Chrome에서 이 사이트를 열고 우측 상단 ⋮ 메뉴를 탭합니다.'),
          _StepInfo(Icons.add_to_home_screen, '"홈 화면에 추가" 또는 "앱 설치"를 선택합니다.'),
          _StepInfo(Icons.check_circle_outline, '"설치"를 탭하면 홈 화면에 앱 아이콘이 추가됩니다.'),
          _StepInfo(Icons.notifications_off_outlined, 'Android PWA는 현재 Push 알림을 지원하지 않습니다. 알림은 PC에서만 사용 가능합니다.'),
        ];
      case 'CN':
        return const [
          _StepInfo(Icons.more_vert, '在Chrome中打开此网站，点击右上角 ⋮ 菜单。'),
          _StepInfo(Icons.add_to_home_screen, '选择"添加到主屏幕"或"安装应用"。'),
          _StepInfo(Icons.check_circle_outline, '点击"安装"，应用图标将出现在主屏幕上。'),
          _StepInfo(Icons.notifications_off_outlined, 'Android PWA目前不支持推送通知。通知仅在PC上可用。'),
        ];
      default:
        return const [
          _StepInfo(Icons.more_vert, 'Open this site in Chrome and tap the ⋮ menu at the top right.'),
          _StepInfo(Icons.add_to_home_screen, 'Select "Add to Home screen" or "Install app".'),
          _StepInfo(Icons.check_circle_outline, 'Tap "Install" and the app icon will appear on your home screen.'),
          _StepInfo(Icons.notifications_off_outlined, 'Android PWA does not support push notifications. Notifications are only available on PC.'),
        ];
    }
  }

  List<_StepInfo> _getIosSteps(String lang) {
    switch (lang) {
      case 'KR':
        return const [
          _StepInfo(Icons.ios_share, 'Safari에서 이 사이트를 열고 하단 공유 버튼(⬆)을 탭합니다.'),
          _StepInfo(Icons.add_box_outlined, '공유 메뉴에서 "홈 화면에 추가"를 선택합니다.'),
          _StepInfo(Icons.check_circle_outline, '"추가"를 탭하면 홈 화면에 앱 아이콘이 추가됩니다.'),
          _StepInfo(Icons.warning_amber_rounded, 'iOS는 반드시 Safari를 사용해야 합니다. Chrome/Firefox에서는 설치가 불가합니다.'),
          _StepInfo(Icons.notifications_off_outlined, 'iOS PWA는 현재 Push 알림을 지원하지 않습니다. 알림은 PC에서만 사용 가능합니다.'),
        ];
      case 'CN':
        return const [
          _StepInfo(Icons.ios_share, '在Safari中打开此网站，点击底部分享按钮(⬆)。'),
          _StepInfo(Icons.add_box_outlined, '在分享菜单中选择"添加到主屏幕"。'),
          _StepInfo(Icons.check_circle_outline, '点击"添加"，应用图标将出现在主屏幕上。'),
          _StepInfo(Icons.warning_amber_rounded, 'iOS必须使用Safari。Chrome/Firefox无法安装。'),
          _StepInfo(Icons.notifications_off_outlined, 'iOS PWA目前不支持推送通知。通知仅在PC上可用。'),
        ];
      default:
        return const [
          _StepInfo(Icons.ios_share, 'Open this site in Safari and tap the share button (⬆) at the bottom.'),
          _StepInfo(Icons.add_box_outlined, 'Select "Add to Home Screen" from the share menu.'),
          _StepInfo(Icons.check_circle_outline, 'Tap "Add" and the app icon will appear on your home screen.'),
          _StepInfo(Icons.warning_amber_rounded, 'On iOS, you must use Safari. Chrome/Firefox cannot install PWAs.'),
          _StepInfo(Icons.notifications_off_outlined, 'iOS PWA does not support push notifications. Notifications are only available on PC.'),
        ];
    }
  }

  List<_StepInfo> _getDesktopSteps(String lang) {
    switch (lang) {
      case 'KR':
        return const [
          _StepInfo(Icons.install_desktop, 'Chrome 또는 Edge에서 이 사이트를 열면 주소창 오른쪽에 설치 아이콘(⊕)이 나타납니다.'),
          _StepInfo(Icons.mouse, '설치 아이콘을 클릭하거나, 메뉴 > "앱 설치"를 선택합니다.'),
          _StepInfo(Icons.check_circle_outline, '"설치"를 클릭하면 독립 앱 창으로 실행됩니다.'),
          _StepInfo(Icons.notifications_active, 'PC에서는 브라우저/PWA 알림이 지원됩니다. 설정에서 알림을 활성화하세요.'),
        ];
      case 'CN':
        return const [
          _StepInfo(Icons.install_desktop, '在Chrome或Edge中打开此网站，地址栏右侧会出现安装图标(⊕)。'),
          _StepInfo(Icons.mouse, '点击安装图标，或从菜单选择"安装应用"。'),
          _StepInfo(Icons.check_circle_outline, '点击"安装"，将以独立窗口运行。'),
          _StepInfo(Icons.notifications_active, 'PC支持浏览器/PWA通知。请在设置中启用通知。'),
        ];
      default:
        return const [
          _StepInfo(Icons.install_desktop, 'Open this site in Chrome or Edge. An install icon (⊕) appears in the address bar.'),
          _StepInfo(Icons.mouse, 'Click the install icon, or use Menu > "Install app".'),
          _StepInfo(Icons.check_circle_outline, 'Click "Install" and it will run as a standalone app window.'),
          _StepInfo(Icons.notifications_active, 'Browser/PWA notifications are supported on PC. Enable them in Settings.'),
        ];
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  알림 지원 현황 요약 배너
// ═══════════════════════════════════════════════════════════════════════════

class _NotifSupportBanner extends StatelessWidget {
  final String lang;
  const _NotifSupportBanner({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_outlined,
                  color: Colors.orange, size: 15),
              const SizedBox(width: 6),
              Text(
                _title,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 플랫폼별 한 줄 요약
          _SupportRow(
            icon: Icons.desktop_windows,
            label: 'PC (Chrome / Edge)',
            supported: true,
            statusText: _pcStatus,
          ),
          const SizedBox(height: 4),
          _SupportRow(
            icon: Icons.android,
            label: 'Android (PWA)',
            supported: false,
            statusText: _mobileStatus,
          ),
          const SizedBox(height: 4),
          _SupportRow(
            icon: Icons.apple,
            label: 'iOS (PWA)',
            supported: false,
            statusText: _mobileStatus,
          ),
          const SizedBox(height: 4),
          _SupportRow(
            icon: Icons.android,
            label: 'Android (APK)',
            supported: true,
            statusText: _apkStatus,
          ),
          const SizedBox(height: 8),
          Text(
            _footerNote,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  String get _title {
    switch (lang) {
      case 'KR': return '플랫폼별 알림 지원 현황';
      case 'CN': return '各平台通知支持状态';
      default:   return 'Notification Support by Platform';
    }
  }

  String get _pcStatus {
    switch (lang) {
      case 'KR': return '알림 지원 (탭/PWA 실행 중)';
      case 'CN': return '支持通知（标签页/PWA运行时）';
      default:   return 'Supported (while tab/PWA is open)';
    }
  }

  String get _mobileStatus {
    switch (lang) {
      case 'KR': return '설치만 가능 · 알림 미지원';
      case 'CN': return '仅可安装 · 不支持通知';
      default:   return 'Install only · No notifications';
    }
  }

  String get _apkStatus {
    switch (lang) {
      case 'KR': return '알림 완전 지원 (GitHub에서 다운로드)';
      case 'CN': return '完全支持通知（从GitHub下载）';
      default:   return 'Full notification support (GitHub download)';
    }
  }

  String get _footerNote {
    switch (lang) {
      case 'KR': return '모바일에서는 앱처럼 전체화면으로 사용할 수 있지만, 브라우저 제한으로 Push 알림은 PC에서만 동작합니다.';
      case 'CN': return '移动端可作为全屏应用使用，但由于浏览器限制，推送通知仅在PC上可用。';
      default:   return 'Mobile devices can use full-screen app mode, but push notifications only work on PC due to browser limitations.';
    }
  }
}

class _SupportRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool supported;
  final String statusText;

  const _SupportRow({
    required this.icon,
    required this.label,
    required this.supported,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ),
        Icon(
          supported ? Icons.check_circle : Icons.cancel_outlined,
          color: supported ? Colors.green : Colors.redAccent.withValues(alpha: 0.6),
          size: 13,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            statusText,
            style: TextStyle(
              color: supported ? Colors.green : Colors.white38,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  공통 타입
// ═══════════════════════════════════════════════════════════════════════════

enum _NotifSupport { full, none }

class _StepInfo {
  final IconData icon;
  final String text;
  const _StepInfo(this.icon, this.text);
}

class _PlatformCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final _NotifSupport notifSupport;
  final String notifLabel;
  final List<_StepInfo> steps;

  const _PlatformCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.notifSupport,
    required this.notifLabel,
    required this.steps,
  });

  @override
  State<_PlatformCard> createState() => _PlatformCardState();
}

class _PlatformCardState extends State<_PlatformCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isSupported = widget.notifSupport == _NotifSupport.full;
    final badgeColor = isSupported ? Colors.green : Colors.redAccent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // 플랫폼 헤더 (탭하여 펼치기/접기)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.iconColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // 알림 지원 뱃지
                        Row(
                          children: [
                            Icon(
                              isSupported
                                  ? Icons.notifications_active
                                  : Icons.notifications_off_outlined,
                              color: badgeColor.withValues(alpha: 0.7),
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.notifLabel,
                              style: TextStyle(
                                color: badgeColor.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more,
                        color: Colors.white38, size: 20),
                  ),
                ],
              ),
            ),
          ),

          // 스텝 목록 (아코디언)
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: Column(
                        children: [
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 10),
                          for (int i = 0; i < widget.steps.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _buildStepRow(i, widget.steps[i]),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(int index, _StepInfo step) {
    // 알림 관련 스텝은 별도 스타일
    final isNotifStep = step.icon == Icons.notifications_off_outlined ||
        step.icon == Icons.notifications_active ||
        step.icon == Icons.warning_amber_rounded;

    final textColor = isNotifStep ? Colors.white38 : Colors.white70;
    final iconColor = step.icon == Icons.notifications_off_outlined
        ? Colors.redAccent.withValues(alpha: 0.5)
        : step.icon == Icons.notifications_active
            ? Colors.green.withValues(alpha: 0.7)
            : step.icon == Icons.warning_amber_rounded
                ? Colors.amber.withValues(alpha: 0.7)
                : Colors.white38;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 번호 원 (알림/경고 스텝에는 아이콘 사용)
        if (isNotifStep)
          SizedBox(
            width: 22,
            height: 22,
            child: Icon(step.icon, color: iconColor, size: 16),
          )
        else
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withValues(alpha: 0.15),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(width: 10),
        if (!isNotifStep) ...[
          Icon(step.icon, color: Colors.white38, size: 16),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            step.text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              height: 1.4,
              fontStyle: isNotifStep ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Android APK 다운로드 카드
// ═══════════════════════════════════════════════════════════════════════════

class _ApkDownloadCard extends StatelessWidget {
  final String lang;
  const _ApkDownloadCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3DDC84).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF3DDC84).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.android, color: Color(0xFF3DDC84), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _title,
                  style: const TextStyle(
                    color: Color(0xFF3DDC84),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _desc,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // GitHub Releases 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openReleases(),
              icon: const Icon(Icons.download, size: 16),
              label: Text(
                _buttonLabel,
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3DDC84),
                side: BorderSide(
                    color: const Color(0xFF3DDC84).withValues(alpha: 0.4)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppConstants.githubReleasesUrl,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openReleases() async {
    final uri = Uri.parse(AppConstants.githubReleasesUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String get _title {
    switch (lang) {
      case 'KR':
        return 'Android APK 직접 설치';
      case 'CN':
        return 'Android APK 直接安装';
      default:
        return 'Android APK Direct Install';
    }
  }

  String get _desc {
    switch (lang) {
      case 'KR':
        return '모바일에서 Push 알림이 필요하다면, GitHub Releases에서 APK 파일을 다운로드하여 직접 설치하세요. APK 버전은 백그라운드 알림, 홈 위젯 등 모든 기능이 정상 동작합니다.';
      case 'CN':
        return '如果需要移动端推送通知，请从GitHub Releases下载APK文件直接安装。APK版本支持后台通知、桌面小组件等所有功能。';
      default:
        return 'If you need push notifications on mobile, download the APK from GitHub Releases. The APK version fully supports background notifications, home widgets, and all features.';
    }
  }

  String get _buttonLabel {
    switch (lang) {
      case 'KR':
        return 'GitHub Releases에서 다운로드';
      case 'CN':
        return '从 GitHub Releases 下载';
      default:
        return 'Download from GitHub Releases';
    }
  }
}
