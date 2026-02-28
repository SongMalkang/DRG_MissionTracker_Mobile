class AppConstants {
  AppConstants._();

  // ── Data Source (자체 GitHub Raw) ────────────────────────────────────────
  static const String missionDataUrl =
      'https://raw.githubusercontent.com/SongMalkang/DRG_MissionTracker_Mobile/main/data/daily_missions.json';
  static const String deepDiveDataUrl =
      'https://raw.githubusercontent.com/SongMalkang/DRG_MissionTracker_Mobile/main/data/deep_dive.json';

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
}
