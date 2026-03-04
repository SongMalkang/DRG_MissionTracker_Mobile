import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _langKey = 'selected_lang';
  static const String _seasonKey = 'selected_season';
  static const String _warningsKey = 'show_warnings';

  /// 기기 로케일 기반 기본 언어 결정 (저장된 값 없을 때 최초 1회 사용)
  static String _detectDeviceLang() {
    final locale = PlatformDispatcher.instance.locale;
    if (locale.languageCode == 'ko') return 'KR';
    if (locale.languageCode == 'zh') return 'CN';
    return 'EN';
  }

  Future<void> saveLanguage(String lang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_langKey, lang);
    } catch (e) {
      debugPrint('SettingsService.saveLanguage failed: $e');
    }
  }

  Future<String> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 저장된 값이 있으면 사용, 없으면 기기 로케일로 자동 감지
      return prefs.getString(_langKey) ?? _detectDeviceLang();
    } catch (e) {
      debugPrint('SettingsService.getLanguage failed: $e');
      return _detectDeviceLang();
    }
  }

  Future<void> saveSeason(String season) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seasonKey, season);
    } catch (e) {
      debugPrint('SettingsService.saveSeason failed: $e');
    }
  }

  Future<String> getSeason() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_seasonKey) ?? 's6';
    } catch (e) {
      debugPrint('SettingsService.getSeason failed: $e');
      return 's6';
    }
  }

  Future<void> saveShowWarnings(bool show) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_warningsKey, show);
    } catch (e) {
      debugPrint('SettingsService.saveShowWarnings failed: $e');
    }
  }

  Future<bool> getShowWarnings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_warningsKey) ?? true;
    } catch (e) {
      debugPrint('SettingsService.getShowWarnings failed: $e');
      return true;
    }
  }
}
