import 'package:flutter_test/flutter_test.dart';
import 'package:drg_mission_tracker/utils/constants.dart';

void main() {
  group('AppConstants', () {
    test('network timeout is reasonable', () {
      expect(AppConstants.networkTimeoutSeconds, greaterThanOrEqualTo(5));
      expect(AppConstants.networkTimeoutSeconds, lessThanOrEqualTo(30));
    });

    test('retry attempts is reasonable', () {
      expect(AppConstants.maxRetryAttempts, greaterThanOrEqualTo(1));
      expect(AppConstants.maxRetryAttempts, lessThanOrEqualTo(5));
    });

    test('mission rotation is 30 minutes', () {
      expect(AppConstants.missionRotationMinutes, 30);
    });

    test('deep dive reset hour is 11 UTC', () {
      expect(AppConstants.deepDiveResetHourUtc, 11);
    });

    test('elapsed mission opacity is between 0 and 1', () {
      expect(AppConstants.elapsedMissionOpacity, greaterThan(0.0));
      expect(AppConstants.elapsedMissionOpacity, lessThan(1.0));
    });

    test('API URLs are not empty', () {
      expect(AppConstants.missionDataUrl, isNotEmpty);
      expect(AppConstants.deepDiveDataUrl, isNotEmpty);
      expect(AppConstants.localMissionAsset, isNotEmpty);
      expect(AppConstants.cachedMissionFile, isNotEmpty);
    });

    test('bosco image path is valid', () {
      expect(AppConstants.boscoImage, startsWith('assets/'));
      expect(AppConstants.boscoImage, endsWith('.png'));
    });
  });
}
