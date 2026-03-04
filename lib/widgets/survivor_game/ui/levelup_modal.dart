import 'package:flutter/material.dart';
import '../game_engine.dart';

class LevelUpModal extends StatelessWidget {
  final int level;
  final List<LevelUpChoice> choices;
  final ValueChanged<LevelUpChoice> onSelect;

  static const Color _termGreen = Color(0xFF00FF41);
  static const Color _termAmber = Color(0xFFFFB000);
  static const Color _termBg = Color(0xFF0A0E0A);

  const LevelUpModal({
    super.key,
    required this.level,
    required this.choices,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _termBg,
            border: Border.all(color: _termGreen, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LEVEL UP!',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  color: _termAmber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'LV.$level',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: _termGreen.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              ...choices.map((choice) => _buildChoiceButton(choice)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton(LevelUpChoice choice) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelect(choice),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: choice.type == LevelUpChoiceType.secondaryWeapon
                    ? _termAmber
                    : _termGreen.withValues(alpha: 0.6),
                width: 1,
              ),
              color: _termBg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  choice.title,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: choice.type == LevelUpChoiceType.secondaryWeapon
                        ? _termAmber
                        : _termGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  choice.description,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: _termGreen.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
