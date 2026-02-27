import 'package:flutter/material.dart';
import '../utils/strings.dart';

class DeepDivesTab extends StatelessWidget {
  final String lang;
  const DeepDivesTab({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final langMap = i18n[lang]!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDeepDiveCard(context, langMap['standard_dd']!, 'Salt Pits', 'The Hidden Grudge'),
        const SizedBox(height: 24),
        _buildDeepDiveCard(context, langMap['elite_dd']!, 'Magma Core', 'Burning Hell', isElite: true),
      ],
    );
  }

  Widget _buildDeepDiveCard(BuildContext context, String type, String biome, String codename, {bool isElite = false}) {
    Color themeColor = isElite ? Colors.red : Colors.blueAccent;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(codename.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(t(biome, lang), style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          // Stages
          _buildStage(1, 'Mining Expedition', 'Morkite Seeds', 'Explosive Guts'),
          _buildStage(2, 'Egg Hunt', 'Black Box', 'Low Oxygen'),
          _buildStage(3, 'Elimination', 'Dreadnought', 'Shield Disruption'),
        ],
      ),
    );
  }

  Widget _buildStage(int stage, String primary, String secondary, String warning) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: Colors.white10, child: Text('$stage', style: const TextStyle(color: Colors.orange))),
      title: Text(t(primary, lang), style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text('${t(secondary, lang)} | ${t(warning, lang)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}