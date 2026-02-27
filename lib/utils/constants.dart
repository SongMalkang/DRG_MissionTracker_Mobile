class AppConstants {
  AppConstants._();

  // ── API URLs ──────────────────────────────────────────────────────────────
  static const String missionDataRemoteUrl =
      'https://raw.githubusercontent.com/rolfosian/drgmissions/master/data/bulk/2026-02-27.json';
  static const String deepDiveBaseUrl =
      'https://doublexp.net/static/json/DD_';
  static const String localMissionAsset = 'data/daily_missions.json';
  static const String cachedMissionFile = 'cached_missions.json';

  // ── Timing ────────────────────────────────────────────────────────────────
  static const int networkTimeoutSeconds = 10;
  static const int maxRetryAttempts = 3;
  static const int missionRotationMinutes = 30;
  static const int highlightLookbackHours = 2;
  static const int deepDiveResetHourUtc = 11;

  // ── UI ────────────────────────────────────────────────────────────────────
  static const double elapsedMissionOpacity = 0.38;

  // ── Assets ────────────────────────────────────────────────────────────────
  static const String boscoImage = 'assets/images/bosco.png';
}
