import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _langKey = 'selected_lang';
  static const String _seasonKey = 'selected_season';
  static const String _warningsKey = 'show_warnings';

  Future<void> saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey) ?? 'KR';
  }

  Future<void> saveSeason(String season) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seasonKey, season);
  }

  Future<String> getSeason() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_seasonKey) ?? 's6';
  }

  Future<void> saveShowWarnings(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_warningsKey, show);
  }

  Future<bool> getShowWarnings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_warningsKey) ?? true;
  }
}
