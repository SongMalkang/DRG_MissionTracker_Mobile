class AssetHelper {
  static String _toSnakeCase(String text) {
    // CamelCase → snake_case 처리 (예: 'ApocaBlooms' → 'apoca_blooms')
    // 소문자 뒤에 대문자가 오면 사이에 '_' 삽입
    final camelFixed = text.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]}_${m[2]}',
    );
    return camelFixed
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll("'", '');
  }

  static String getBiomeImage(String biome) {
    return 'assets/images/biomes/${_toSnakeCase(biome)}.png';
  }

  static String getMissionIcon(String type) {
    return 'assets/images/missions/${_toSnakeCase(type)}.png';
  }

  static String getMutatorIcon(String mutator) {
    return 'assets/icons/mutators/${_toSnakeCase(mutator)}.png';
  }

  static String getWarningIcon(String warning) {
    // warning is usually a comma separated string if multiple, but here we expect single key for icon
    String key = warning.contains(',') ? warning.split(',')[0].trim() : warning;
    return 'assets/icons/warnings/${_toSnakeCase(key)}.png';
  }

  static String getSecondaryIcon(String secondary) {
    return 'assets/icons/secondary/${_toSnakeCase(secondary)}.png';
  }
}
