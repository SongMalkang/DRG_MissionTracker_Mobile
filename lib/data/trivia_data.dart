import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 트리비아 데이터: 바이옴/미션타입/버프/경고별 설명과 팁
/// 키: 영문 원본 이름 (strings.dart의 i18n 키와 동일)
/// 값: 언어별 { 'desc': 설명, 'tips': 팁 리스트(줄바꿈 구분) }
///
/// data/trivia.json에서 로드됨.
Map<String, Map<String, Map<String, String>>> triviaData = {};

/// 트리비아 JSON 로드 여부
bool _triviaLoaded = false;

/// data/trivia.json에서 트리비아 데이터를 로드.
/// 이미 로드된 경우 즉시 반환. 여러 곳에서 안전하게 호출 가능.
Future<void> loadTriviaData() async {
  if (_triviaLoaded) return;

  try {
    final jsonString = await rootBundle.loadString('data/trivia.json');
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

    final Map<String, Map<String, Map<String, String>>> result = {};
    for (final entry in decoded.entries) {
      final langMap = <String, Map<String, String>>{};
      final value = entry.value as Map<String, dynamic>;
      for (final langEntry in value.entries) {
        final inner = langEntry.value as Map<String, dynamic>;
        langMap[langEntry.key] = inner.map((k, v) => MapEntry(k, v as String));
      }
      result[entry.key] = langMap;
    }

    triviaData = result;
    _triviaLoaded = true;
  } catch (e) {
    debugPrint('Failed to load trivia data: $e');
  }
}
