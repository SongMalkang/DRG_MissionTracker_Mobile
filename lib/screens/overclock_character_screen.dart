import 'package:flutter/material.dart';
import '../models/overclock_model.dart';
import '../utils/asset_helper.dart';
import '../utils/strings.dart';
import '../widgets/overclock_detail_modal.dart';

/// 캐릭터 상세 화면 — 무기 아코디언 + 체크리스트
class OverclockCharacterScreen extends StatelessWidget {
  final DwarfCharacter character;
  final String lang;
  final Set<String> collected;
  final ValueChanged<String> onToggle;
  final VoidCallback onBack;

  const OverclockCharacterScreen({
    super.key,
    required this.character,
    required this.lang,
    required this.collected,
    required this.onToggle,
    required this.onBack,
  });

  int _countCollected(Weapon weapon) {
    return weapon.overclocks.where((oc) => collected.contains(oc.id)).length;
  }

  int get _totalCollected {
    return character.weapons
        .fold(0, (sum, w) => sum + _countCollected(w));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 상단 헤더
        _buildHeader(context),
        // 무기 리스트
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              // PRIMARY WEAPONS
              _SectionLabel(text: t('oc_primary_weapons', lang)),
              ...character.primaryWeapons.map((w) => _WeaponTile(
                    weapon: w,
                    lang: lang,
                    collected: collected,
                    onToggle: onToggle,
                  )),
              const SizedBox(height: 8),
              // SECONDARY WEAPONS
              _SectionLabel(text: t('oc_secondary_weapons', lang)),
              ...character.secondaryWeapons.map((w) => _WeaponTile(
                    weapon: w,
                    lang: lang,
                    collected: collected,
                    onToggle: onToggle,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final total = character.totalOverclocks;
    final count = _totalCollected;
    final progress = total > 0 ? count / total : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // 뒤로가기
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: onBack,
          ),
          // 캐릭터 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              character.imagePath,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: AssetHelper.assetErrorBuilder,
            ),
          ),
          const SizedBox(width: 12),
          // 이름 + 진행률
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            count == total ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count/$total',
                      style: TextStyle(
                        color: count == total ? Colors.green : Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 섹션 라벨 ──────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── 무기 아코디언 타일 ──────────────────────────────────

class _WeaponTile extends StatelessWidget {
  final Weapon weapon;
  final String lang;
  final Set<String> collected;
  final ValueChanged<String> onToggle;

  const _WeaponTile({
    required this.weapon,
    required this.lang,
    required this.collected,
    required this.onToggle,
  });

  int get _count =>
      weapon.overclocks.where((oc) => collected.contains(oc.id)).length;

  Color get _badgeColor {
    if (_count == 0) return Colors.white24;
    if (_count == weapon.overclocks.length) return Colors.green;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        color: const Color(0xFF1E1E1E),
        margin: const EdgeInsets.symmetric(vertical: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: EdgeInsets.zero,
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Image.asset(
            AssetHelper.getWeaponImage(weapon.id),
            width: 40,
            height: 40,
            errorBuilder: (ctx, e, st) =>
                const Icon(Icons.handyman, color: Colors.white24, size: 28),
          ),
          title: Text(
            weapon.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _badgeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$_count/${weapon.overclocks.length}',
              style: TextStyle(
                color: _badgeColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          children: weapon.overclocks
              .map((oc) => _OverclockRow(
                    overclock: oc,
                    lang: lang,
                    isCollected: collected.contains(oc.id),
                    onToggle: () => onToggle(oc.id),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ─── 개별 오버클럭 행 ────────────────────────────────────

class _OverclockRow extends StatelessWidget {
  final Overclock overclock;
  final String lang;
  final bool isCollected;
  final VoidCallback onToggle;

  const _OverclockRow({
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

  @override
  Widget build(BuildContext context) {
    final color = _tierColor();

    return InkWell(
      onTap: onToggle,
      onLongPress: () => showOverclockDetailModal(
        context,
        overclock: overclock,
        lang: lang,
        isCollected: isCollected,
        onToggle: onToggle,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: Row(
          children: [
            // OC 아이콘 (프레임 포함)
            SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    AssetHelper.getOverclockFrame(overclock.tier),
                    width: 36,
                    height: 36,
                    errorBuilder: (ctx, e, st) => const SizedBox.shrink(),
                  ),
                  Image.asset(
                    AssetHelper.getOverclockImage(overclock.icon),
                    width: 20,
                    height: 20,
                    errorBuilder: (ctx, e, st) =>
                        Icon(Icons.extension, color: color, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // OC 이름
            Expanded(
              child: Text(
                overclock.name,
                style: TextStyle(
                  color: isCollected ? Colors.white : Colors.white60,
                  fontSize: 13,
                  fontWeight:
                      isCollected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            // Info 아이콘
            GestureDetector(
              onTap: () => showOverclockDetailModal(
                context,
                overclock: overclock,
                lang: lang,
                isCollected: isCollected,
                onToggle: onToggle,
              ),
              child: const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.info_outline, color: Colors.white24, size: 18),
              ),
            ),
            // 체크박스
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isCollected,
                onChanged: (_) => onToggle(),
                activeColor: Colors.green,
                side: const BorderSide(color: Colors.white24),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
