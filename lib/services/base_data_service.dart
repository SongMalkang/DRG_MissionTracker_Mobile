import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

// 조건부 임포트: 웹에서는 SharedPreferences, 네이티브에서는 파일 I/O
import '../platform/file_cache_stub.dart'
    if (dart.library.io) '../platform/file_cache_native.dart';

/// 리스너 관리 mixin — 동일한 리스너 패턴을 통합
mixin ListenerMixin {
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void notifyListeners() {
    // 콜백 내부에서 addListener/removeListener 호출 시 ConcurrentModificationError 방지
    for (final cb in List.of(_listeners)) {
      cb();
    }
  }

  void clearListeners() => _listeners.clear();
}

/// 네트워크 fetch + 재시도 mixin — 동일한 retry 로직을 통합
mixin NetworkFetchMixin {
  Future<http.Response> fetchWithRetry(
    String url, {
    int maxAttempts = AppConstants.maxRetryAttempts,
    int timeoutSeconds = AppConstants.networkTimeoutSeconds,
  }) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(
          Duration(seconds: timeoutSeconds),
        );
        if (response.statusCode == 200) return response;
      } catch (_) {
        // retry
      }
      if (attempt < maxAttempts - 1) {
        await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }
    throw Exception('Failed after $maxAttempts attempts');
  }

  /// body만 반환하는 편의 메서드 (DeepDiveService 호환)
  Future<String> fetchBodyWithRetry(
    String url, {
    int maxAttempts = AppConstants.maxRetryAttempts,
    int timeoutSeconds = AppConstants.networkTimeoutSeconds,
  }) async {
    final response = await fetchWithRetry(
      url,
      maxAttempts: maxAttempts,
      timeoutSeconds: timeoutSeconds,
    );
    return response.body;
  }
}

/// 캐시 관리 mixin — loadCacheString/saveCacheString 래퍼
mixin CacheManagementMixin {
  Future<String?> loadCache(String filename) => loadCacheString(filename);
  Future<void> saveCache(String filename, String content) =>
      saveCacheString(filename, content);
}
