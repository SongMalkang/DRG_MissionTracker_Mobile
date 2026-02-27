import 'package:flutter/material.dart';
import '../utils/strings.dart';

class SettingsScreen extends StatefulWidget {
  final String currentLang;
  final Function(String) onLangChange;

  const SettingsScreen({
    super.key,
    required this.currentLang,
    required this.onLangChange,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showWarnings = true;

  void _nextLang() {
    List<String> langs = i18n.keys.toList();
    int idx = langs.indexOf(widget.currentLang);
    String next = langs[(idx + 1) % langs.length];

    setState(() {
      widget.onLangChange(next);
    });
  }

  void _prevLang() {
    List<String> langs = i18n.keys.toList();
    int idx = langs.indexOf(widget.currentLang);
    String prev = langs[(idx - 1 + langs.length) % langs.length];

    setState(() {
      widget.onLangChange(prev);
    });
  }

  @override
  Widget build(BuildContext context) {
    final langMap = i18n[widget.currentLang]!;

    return Scaffold(
      appBar: AppBar(title: Text(langMap['settings']!)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. 시스템 언어 선택 (꺽쇠 형태)
          _buildSectionTitle(langMap['lang_select']!),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _prevLang,
                icon: const Icon(
                  Icons.chevron_left,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
              Container(
                width: 120,
                alignment: Alignment.center,
                child: Text(
                  widget.currentLang,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextLang,
                icon: const Icon(
                  Icons.chevron_right,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 40),

          // 2. 시즌 선택 (비활성화 목업)
          _buildSectionTitle(langMap['season_select']!),
          ListTile(
            title: const Text(
              'Season 06',
              style: TextStyle(color: Colors.white70),
            ),
            subtitle: Text(
              langMap['season_note']!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: const Icon(Icons.lock, color: Colors.grey),
          ),
          const Divider(color: Colors.white10, height: 40),

          // 3. 주의사항 토글
          SwitchListTile(
            title: Text(
              langMap['show_warnings']!,
              style: const TextStyle(color: Colors.white),
            ),
            activeColor: Colors.orange,
            value: _showWarnings,
            onChanged: (val) => setState(() => _showWarnings = val),
          ),
          const Divider(color: Colors.white10, height: 40),

          // 4. 후원 및 면책 조항
          _buildSectionTitle(langMap['donation']!),
          Text(
            langMap['donate_note']!,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDonateIcon('Patreon'),
              _buildDonateIcon('BuyMeCoffee'),
              _buildDonateIcon('Ko-fi'),
            ],
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white.withOpacity(0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  langMap['disclaimer_title']!,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  langMap['disclaimer_body']!,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDonateIcon(String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
