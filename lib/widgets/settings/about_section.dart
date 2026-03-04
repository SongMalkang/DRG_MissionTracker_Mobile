import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/strings.dart';
import '../../utils/constants.dart';

class AboutSection extends StatelessWidget {
  final String lang;

  const AboutSection({
    super.key,
    required this.lang,
  });

  Future<void> _launchSteam() async {
    final Uri url = Uri.parse('https://steamcommunity.com/id/VonVon93/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse(AppConstants.privacyPolicyUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _copySteamLink(BuildContext context) {
    const String url = 'https://steamcommunity.com/id/VonVon93/';
    Clipboard.setData(const ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(i18n[lang]!['link_copied']!),
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langMap = i18n[lang]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 6. Steam & Community
        _buildSectionTitle(langMap['steam_profile']!),
        InkWell(
          onTap: _launchSteam,
          onLongPress: () => _copySteamLink(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF171A21),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: Image.network(
                          'https://shared.fastly.steamstatic.com/community_assets/images/items/3331000/4ef70f99c425ae03163495f923c5d452f83ba978.gif',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person,
                                  color: Colors.blueAccent, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Pinyo",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text(langMap['visit_steam']!,
                              style: const TextStyle(
                                  color: Colors.blueAccent, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new,
                        color: Colors.blueAccent, size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("steamcommunity.com/id/VonVon93/",
                        style: TextStyle(
                            color: Colors.white24,
                            fontSize: 9,
                            fontFamily: 'monospace')),
                    Text(langMap['long_press_copy']!,
                        style: const TextStyle(
                            color: Colors.white24, fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(langMap['bug_report_note']!,
            style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const Divider(color: Colors.white10, height: 24),

        // 7. Privacy Policy & GitHub
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined,
              color: Colors.grey, size: 20),
          title: Text(
            langMap['privacy_policy']!,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          trailing:
              const Icon(Icons.open_in_new, color: Colors.grey, size: 14),
          onTap: _launchPrivacyPolicy,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              color: Colors.orange,
              fontSize: 13,
              fontWeight: FontWeight.bold)),
    );
  }
}
