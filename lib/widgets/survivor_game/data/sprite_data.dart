import 'enemy_data.dart';

/// ASCII art sprites for Hoxxes Survival entities.
/// Rendered centered at entity position via TextPainter in monospace font.

// ═══════════════ PLAYER ═══════════════

const List<String> scoutSprite = [
  ' ┌█┐ ',
  ' █▓█ ',
  ' ╨ ╨ ',
];

const List<String> scoutLampOffSprite = [
  ' ┌█┐ ',
  ' █░█ ',
  ' ╨ ╨ ',
];

const List<String> scoutPreviewSprite = [
  '  ╔═══╗  ',
  '  ║ ▓ ║  ',
  '  ╠═══╣  ',
  '  ║ █ ║  ',
  '  ╚╦═╦╝  ',
  '   ║ ║   ',
  '   ╩ ╩   ',
];

const List<String> scoutPreviewLampOffSprite = [
  '  ╔═══╗  ',
  '  ║ ░ ║  ',
  '  ╠═══╣  ',
  '  ║ █ ║  ',
  '  ╚╦═╦╝  ',
  '   ║ ║   ',
  '   ╩ ╩   ',
];

// ═══════════════ COMMON ENEMIES ═══════════════

const List<String> gruntSprite = [
  '\\··/',
  ' ██ ',
  '/  \\',
];

const List<String> swarmerSprite = [
  '×',
];

const List<String> guardSprite = [
  '┌══┐',
  '│██│',
  '/  \\',
];

// ═══════════════ BOSS ENEMIES ═══════════════

const List<String> praetorianSprite = [
  '╔════╗',
  '║█··█║',
  '╚╦══╦╝',
  ' /  \\ ',
];

const List<String> oppressorSprite = [
  '╔══════╗',
  '║██████║',
  '║█ ·· █║',
  '╚╦════╦╝',
  ' /    \\ ',
];

const List<String> dreadnoughtSprite = [
  '╔════════╗',
  '║██ ·· ██║',
  '║████████║',
  '║██ ·· ██║',
  '╚╦══════╦╝',
  '  /    \\  ',
];

const List<String> bulkDetonatorSprite = [
  ' ╔════╗ ',
  '║░░░░░║',
  '║░░█░░║',
  '║░░░░░║',
  ' ╚╦══╦╝ ',
];

const List<String> bulkDetonatorPulseSprite = [
  ' ╔════╗ ',
  '║▒▒▒▒▒║',
  '║▒▒█▒▒║',
  '║▒▒▒▒▒║',
  ' ╚╦══╦╝ ',
];

// ═══════════════ ENVIRONMENT ═══════════════

const List<String> pitJawRevealedSprite = [
  '\\▼▼/',
  ' ▓▓ ',
  '/▲▲\\',
];

const List<String> pitJawHiddenSprite = [
  ' · ',
];

/// Get ASCII sprite for an enemy type
List<String> getEnemySprite(EnemyType type, {bool pulse = false}) {
  switch (type) {
    case EnemyType.grunt:
      return gruntSprite;
    case EnemyType.swarmer:
      return swarmerSprite;
    case EnemyType.guard:
      return guardSprite;
    case EnemyType.praetorian:
      return praetorianSprite;
    case EnemyType.oppressor:
      return oppressorSprite;
    case EnemyType.dreadnought:
      return dreadnoughtSprite;
    case EnemyType.bulkDetonator:
      return pulse ? bulkDetonatorPulseSprite : bulkDetonatorSprite;
  }
}
