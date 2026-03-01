import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 네이티브용 캐시: 파일 시스템에 JSON 문자열 저장
///
/// getApplicationDocumentsDirectory()를 통해 앱 전용 디렉토리에 캐시 파일 관리.

Future<String?> loadCacheString(String filename) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    if (await file.exists()) {
      return await file.readAsString();
    }
  } catch (e) {
    debugPrint('Cache load failed ($filename): $e');
  }
  return null;
}

Future<void> saveCacheString(String filename, String content) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
  } catch (e) {
    debugPrint('Cache save failed ($filename): $e');
  }
}
