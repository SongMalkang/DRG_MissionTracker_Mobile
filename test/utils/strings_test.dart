import 'package:flutter_test/flutter_test.dart';
import 'package:drg_mission_tracker/utils/strings.dart';

void main() {
  group('i18n map completeness', () {
    final languages = ['KR', 'EN', 'CN'];
    // Get all keys from English as the reference set
    final referenceKeys = i18n['EN']!.keys.toSet();

    for (final lang in languages) {
      test('$lang has all keys that EN has', () {
        final langKeys = i18n[lang]!.keys.toSet();
        final missing = referenceKeys.difference(langKeys);
        expect(missing, isEmpty,
            reason: '$lang is missing keys: $missing');
      });
    }

    test('all languages have the same number of keys', () {
      final enCount = i18n['EN']!.length;
      final krCount = i18n['KR']!.length;
      final cnCount = i18n['CN']!.length;
      expect(krCount, enCount, reason: 'KR key count mismatch');
      expect(cnCount, enCount, reason: 'CN key count mismatch');
    });

    test('no empty string values in any language', () {
      for (final lang in languages) {
        final emptyKeys = i18n[lang]!
            .entries
            .where((e) => e.value.isEmpty)
            .map((e) => e.key)
            .toList();
        expect(emptyKeys, isEmpty,
            reason: '$lang has empty values for: $emptyKeys');
      }
    });
  });

  group('t() translation function', () {
    test('returns translated string for known key', () {
      expect(t('live', 'EN'), 'LIVE');
      expect(t('live', 'KR'), 'Live');
    });

    test('returns key itself when not found', () {
      expect(t('nonexistent_key', 'EN'), 'nonexistent_key');
    });

    test('returns empty string for null key', () {
      expect(t(null, 'EN'), '');
    });

    test('returns empty string for empty key', () {
      expect(t('', 'EN'), '');
    });

    test('translates biome names', () {
      expect(t('Azure Weald', 'KR'), '푸른 숲');
      expect(t('Azure Weald', 'EN'), 'Azure Weald');
      expect(t('Azure Weald', 'CN'), '蔚蓝旷野');
    });

    test('translates mission types', () {
      expect(t('Mining Expedition', 'KR'), '채굴 원정');
      expect(t('Mining Expedition', 'CN'), '采矿远征');
    });

    test('translates mutators and warnings', () {
      expect(t('Double XP', 'KR'), '경험치 2배');
      expect(t('Swarmageddon', 'CN'), '异形虫灾');
    });
  });
}
