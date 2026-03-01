import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';

// 조건부 임포트: 웹에서는 SharedPreferences, 네이티브에서는 파일 I/O
import '../platform/file_cache_stub.dart'
    if (dart.library.io) '../platform/file_cache_native.dart';

/// 동적 i18n 로더
///
/// GitHub의 data/strings.json을 fetch하여 dynamicOverlay에 적용.
/// 앱 업데이트 없이 번역을 수정할 수 있도록 strings.dart의 값을 런타임에 덮어씀.
///
/// 업데이트 방법: GitHub repo의 data/strings.json 파일에서 수정할 키:값 쌍을 추가/변경.
class StringsService {
  static final StringsService _instance = StringsService._internal();
  factory StringsService() => _instance;
  StringsService._internal();

  static const String _cacheFile = 'cached_strings.json';
  static const String _cacheTimestampKey = 'strings_cache_timestamp';
  static const int _cacheMaxAgeHours = 12;

  /// 초기화: 캐시 즉시 로드 → 백그라운드에서 최신 버전 갱신
  Future<void> initialize() async {
    // 1. 캐시에서 즉시 로드 (앱 시작 속도에 영향 없음)
    try {
      final cached = await _loadFromCache();
      if (cached != null) _applyOverlay(cached);
    } catch (e) {
      debugPrint('StringsService: 캐시 로드 실패: $e');
    }
    // 2. 캐시가 오래됐으면 백그라운드에서 갱신 (비동기, await 없음)
    _refreshIfStale();
  }

  /// 캐시 만료 여부 확인 후 백그라운드 갱신
  void _refreshIfStale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt(_cacheTimestampKey) ?? 0;
      final ageMs = DateTime.now().millisecondsSinceEpoch - ts;
      if (ageMs < _cacheMaxAgeHours * 3600 * 1000) return; // 아직 신선함

      final data = await _fetchFromNetwork();
      if (data != null) {
        _applyOverlay(data);
        await _saveToCache(data);
        await prefs.setInt(
            _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
        debugPrint('StringsService: 번역 갱신 완료');
      }
    } catch (e) {
      debugPrint('StringsService: 백그라운드 갱신 실패: $e');
    }
  }

  /// dynamicOverlay 업데이트 (strings.dart의 t() 함수가 이 맵을 우선 참조)
  void _applyOverlay(Map<String, dynamic> data) {
    final newOverlay = <String, Map<String, String>>{};
    for (final lang in ['KR', 'EN', 'CN']) {
      final langData = data[lang];
      if (langData is Map) {
        newOverlay[lang] = Map<String, String>.from(
          langData.map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      }
    }
    dynamicOverlay = newOverlay;
  }

  Future<Map<String, dynamic>?> _fetchFromNetwork() async {
    try {
      final resp = await http
          .get(
            Uri.parse(AppConstants.stringsJsonUrl),
            headers: {'Cache-Control': 'no-cache'},
          )
          .timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map<String, dynamic>) return data;
      }
    } catch (e) {
      debugPrint('StringsService: 네트워크 fetch 실패: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _loadFromCache() async {
    try {
      final content = await loadCacheString(_cacheFile);
      if (content != null) {
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('StringsService: 캐시 읽기 실패: $e');
    }
    return null;
  }

  Future<void> _saveToCache(Map<String, dynamic> data) async {
    try {
      await saveCacheString(_cacheFile, jsonEncode(data));
    } catch (e) {
      debugPrint('StringsService: 캐시 저장 실패: $e');
    }
  }

  /// 강제 갱신 (설정 화면 등에서 수동 호출용)
  Future<void> forceRefresh() async {
    final data = await _fetchFromNetwork();
    if (data != null) {
      _applyOverlay(data);
      await _saveToCache(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    }
  }
}
