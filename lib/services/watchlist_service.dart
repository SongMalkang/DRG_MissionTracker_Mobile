import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/watchlist_filter.dart';

/// Watchlist 필터 조건 CRUD 서비스 (SharedPreferences 기반)
class WatchlistService {
  static const String _enabledKey = 'watchlist_enabled';
  static const String _typesKey = 'watchlist_types';
  static const String _biomesKey = 'watchlist_biomes';
  static const String _buffsKey = 'watchlist_buffs';
  static const String _warningsKey = 'watchlist_warnings';

  // ── 마스터 스위치 ──

  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? false;
    } catch (e) {
      debugPrint('WatchlistService.isEnabled failed: $e');
      return false;
    }
  }

  Future<void> setEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (e) {
      debugPrint('WatchlistService.setEnabled failed: $e');
    }
  }

  // ── 필터 전체 로드 ──

  Future<WatchlistFilter> getFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return WatchlistFilter(
        enabled: prefs.getBool(_enabledKey) ?? false,
        missionTypes: _loadSet(prefs, _typesKey),
        biomes: _loadSet(prefs, _biomesKey),
        buffs: _loadSet(prefs, _buffsKey),
        warnings: _loadSet(prefs, _warningsKey),
      );
    } catch (e) {
      debugPrint('WatchlistService.getFilter failed: $e');
      return WatchlistFilter.empty;
    }
  }

  // ── 필터 전체 저장 ──

  Future<void> saveFilter(WatchlistFilter filter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, filter.enabled);
      await _saveSet(prefs, _typesKey, filter.missionTypes);
      await _saveSet(prefs, _biomesKey, filter.biomes);
      await _saveSet(prefs, _buffsKey, filter.buffs);
      await _saveSet(prefs, _warningsKey, filter.warnings);
    } catch (e) {
      debugPrint('WatchlistService.saveFilter failed: $e');
    }
  }

  // ── 헬퍼: 쉼표 구분 문자열 ↔ Set<String> ──

  Set<String> _loadSet(SharedPreferences prefs, String key) {
    final str = prefs.getString(key) ?? '';
    if (str.isEmpty) return {};
    return str.split(',').where((s) => s.isNotEmpty).toSet();
  }

  Future<void> _saveSet(SharedPreferences prefs, String key, Set<String> values) async {
    await prefs.setString(key, values.join(','));
  }
}
