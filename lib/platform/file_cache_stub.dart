import 'package:shared_preferences/shared_preferences.dart';

/// 웹용 캐시: SharedPreferences(localStorage)에 JSON 문자열 저장
///
/// 네이티브에서는 파일 I/O를 사용하지만,
/// 웹에서는 dart:io / path_provider를 사용할 수 없으므로
/// SharedPreferences를 통해 localStorage에 저장한다.

const String _cachePrefix = 'file_cache_';

Future<String?> loadCacheString(String filename) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_cachePrefix$filename');
  } catch (_) {
    return null;
  }
}

Future<void> saveCacheString(String filename, String content) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cachePrefix$filename', content);
  } catch (_) {
    // 저장 실패 무시 (웹에서 localStorage 용량 초과 등)
  }
}
