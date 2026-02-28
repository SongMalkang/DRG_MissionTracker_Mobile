import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// 업데이트 정보 모델
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool isForced; // true면 강제 업데이트 (닫기 불가)
  final String storeUrl;
  final Map<String, String> changelog; // lang → 내용

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.isForced,
    required this.storeUrl,
    required this.changelog,
  });
}

/// 버전 체크 서비스
///
/// GitHub의 data/version.json을 fetch하여 현재 앱 버전과 비교.
/// 업데이트가 있으면 UpdateInfo를 반환, 없으면 null.
///
/// 배포 방법:
///   1. pubspec.yaml에서 version 수정 (예: 1.0.0+1 → 1.1.0+2)
///   2. data/version.json에서 latest_version 수정 (예: "1.1.0")
///   3. changelog에 다국어 변경 내용 입력
///   4. 빌드 후 Play Store에 업로드
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String _lastCheckKey = 'last_update_check_ms';
  static const int _checkIntervalHours = 24;

  /// 업데이트 확인
  ///
  /// [forceCheck]: true면 24시간 인터벌 무시하고 즉시 확인 (디버그용)
  /// 반환값: 업데이트가 있으면 [UpdateInfo], 없거나 오류면 null
  Future<UpdateInfo?> checkForUpdate({bool forceCheck = false}) async {
    try {
      // 24시간 이내에 이미 확인했으면 skip (배터리/데이터 절약)
      if (!forceCheck) {
        final prefs = await SharedPreferences.getInstance();
        final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
        final elapsed = DateTime.now().millisecondsSinceEpoch - lastCheck;
        if (elapsed < _checkIntervalHours * 3600 * 1000) return null;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // pubspec의 1.0.0 부분

      final resp = await http
          .get(Uri.parse(AppConstants.versionJsonUrl))
          .timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (resp.statusCode != 200) return null;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final latestVersion = (data['latest_version'] as String?) ?? currentVersion;
      final minRequired = (data['min_required'] as String?) ?? '1.0.0';
      final forceUpdate = (data['force_update'] as bool?) ?? false;
      final storeUrl = (data['store_url'] as String?) ?? '';
      final rawChangelog = (data['changelog'] as Map<String, dynamic>?) ?? {};
      final changelog = rawChangelog.map((k, v) => MapEntry(k, v.toString()));

      // 확인 시각 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);

      final hasUpdate = _compareVersions(latestVersion, currentVersion) > 0;
      // 강제 업데이트: version.json에서 force_update=true이거나, 앱 버전이 min_required 미만
      final isForced =
          forceUpdate || _compareVersions(currentVersion, minRequired) < 0;

      if (!hasUpdate && !isForced) return null;

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        isForced: isForced,
        storeUrl: storeUrl,
        changelog: Map<String, String>.from(changelog),
      );
    } catch (e) {
      debugPrint('UpdateService: 확인 실패: $e');
      return null;
    }
  }

  /// 버전 문자열 비교 (양수: v1 > v2, 0: 동일, 음수: v1 < v2)
  static int _compareVersions(String v1, String v2) {
    final p1 = v1.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final p2 = v2.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final a = i < p1.length ? p1[i] : 0;
      final b = i < p2.length ? p2[i] : 0;
      if (a != b) return a - b;
    }
    return 0;
  }
}
