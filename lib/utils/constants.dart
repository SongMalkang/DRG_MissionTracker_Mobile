class AppConstants {
  AppConstants._();

  // ── Data Source (자체 GitHub Raw) ────────────────────────────────────────
  static const String missionDataUrl =
      'https://raw.githubusercontent.com/SongMalkang/DRG_MissionTracker_Mobile/main/data/daily_missions.json';
  static const String deepDiveDataUrl =
      'https://raw.githubusercontent.com/SongMalkang/DRG_MissionTracker_Mobile/main/data/deep_dive.json';

  /// 번역 핫픽스: GitHub에서 동적으로 로드되는 i18n 오버라이드 맵
  /// 앱 업데이트 없이 번역 수정 가능 (data/strings.json에서 관리)
  static const String stringsJsonUrl =
      'https://raw.githubusercontent.com/SongMalkang/DRG_MissionTracker_Mobile/main/data/strings.json';

  /// 버전 체크: 업데이트 공지 및 changelog 표시
  static const String versionJsonUrl =
      'https://raw.githubusercontent.com/SongMalkang/DRG_MissionTracker_Mobile/main/data/version.json';

  // ── Local Assets & Cache ────────────────────────────────────────────────
  static const String localMissionAsset = 'data/daily_missions.json';
  static const String cachedMissionFile = 'cached_missions.json';
  static const String cachedDeepDiveFile = 'cached_deep_dive.json';

  // ── Cache Metadata Keys (SharedPreferences) ─────────────────────────────
  static const String cacheTimestampKey = 'mission_cache_timestamp';
  static const String deepDiveCacheTimestampKey = 'deep_dive_cache_timestamp';
  static const String deepDiveCacheThursdayKey = 'deep_dive_cache_thursday';

  // ── Timing ──────────────────────────────────────────────────────────────
  static const int networkTimeoutSeconds = 10;
  static const int maxRetryAttempts = 3;
  static const int missionRotationMinutes = 30;
  static const int highlightLookbackHours = 2;
  static const int deepDiveResetHourUtc = 11;

  // ── Refresh ─────────────────────────────────────────────────────────────
  static const int backgroundRefreshIntervalMinutes = 30;
  static const int cacheMaxAgeHours = 6;

  // ── UI ──────────────────────────────────────────────────────────────────
  static const double elapsedMissionOpacity = 0.38;

  // ── Assets ──────────────────────────────────────────────────────────────
  static const String boscoImage = 'assets/images/bosco.png';

  // ── External Links ────────────────────────────────────────────────────
  static const String privacyPolicyUrl =
      'https://songmalkang.github.io/DRG_MissionTracker_Mobile/privacy.html';
  static const String githubRepoUrl =
      'https://github.com/SongMalkang/DRG_MissionTracker_Mobile';
}
