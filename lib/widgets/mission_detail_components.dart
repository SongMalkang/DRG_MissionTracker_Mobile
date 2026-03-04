import 'package:flutter/material.dart';

// ── 섹션 레이블 ────────────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── 목표 행 ─────────────────────────────────────────────────────────────────
class ObjectiveRow extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isPrimary;
  final IconData fallbackIcon;

  const ObjectiveRow({
    super.key,
    required this.iconPath,
    required this.label,
    required this.isPrimary,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPrimary ? Colors.white : Colors.greenAccent.shade100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.greenAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimary
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.greenAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Image.asset(
              iconPath,
              errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon,
                  color: color.withValues(alpha: 0.5),
                  size: 26),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 길이/복잡도 아이콘 도트 (카드용) ──────────────────────────────────────────
class IconDots extends StatelessWidget {
  final int value;
  final String onIcon;
  final String offIcon;
  final double size;

  const IconDots({
    super.key,
    required this.value,
    required this.onIcon,
    required this.offIcon,
    this.size = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isOn = i < value;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Image.asset(
            isOn ? onIcon : offIcon,
            width: size,
            height: size,
            errorBuilder: (context, error, stackTrace) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOn
                    ? Colors.orange
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── 길이/복잡도 아이콘 레이팅 (모달용) ────────────────────────────────────────
class IconRating extends StatelessWidget {
  final String label;
  final int value;
  final String onIcon;
  final String offIcon;
  final double iconSize;

  const IconRating({
    super.key,
    required this.label,
    required this.value,
    required this.onIcon,
    required this.offIcon,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final isOn = i < value;
            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Image.asset(
                isOn ? onIcon : offIcon,
                width: iconSize,
                height: iconSize,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOn
                        ? Colors.orange
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── 버프/디버프 배지 행 ────────────────────────────────────────────────────────
class BadgeRow extends StatelessWidget {
  final String iconPath;
  final String label;
  final Color color;
  final IconData fallbackIcon;
  final VoidCallback? onTap;

  const BadgeRow({
    super.key,
    required this.iconPath,
    required this.label,
    required this.color,
    required this.fallbackIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: Image.asset(
            iconPath,
            errorBuilder: (context, error, stackTrace) =>
                Icon(fallbackIcon, color: color, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        if (onTap != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(Icons.info_outline,
                size: 14, color: color.withValues(alpha: 0.4)),
          ),
      ],
    ),
    );
  }
}
