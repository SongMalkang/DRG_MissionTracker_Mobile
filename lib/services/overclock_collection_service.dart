import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 오버클럭 수집 상태 저장 서비스 (SharedPreferences 기반)
class OverclockCollectionService {
  static const String _key = 'overclock_collected';

  /// 수집된 OC ID Set 로드
  static Future<Set<String>> getCollected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_key) ?? '';
      if (str.isEmpty) return {};
      return str.split(',').where((s) => s.isNotEmpty).toSet();
    } catch (e) {
      debugPrint('OverclockCollectionService.getCollected failed: $e');
      return {};
    }
  }

  /// OC ID 토글 (추가/제거) 후 저장
  static Future<Set<String>> toggle(String id) async {
    try {
      final collected = await getCollected();
      if (collected.contains(id)) {
        collected.remove(id);
      } else {
        collected.add(id);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, collected.join(','));
      return collected;
    } catch (e) {
      debugPrint('OverclockCollectionService.toggle failed: $e');
      return {};
    }
  }

  /// 무기별 수집 카운트
  static int countForWeapon(Set<String> collected, List<String> ocIds) {
    return ocIds.where((id) => collected.contains(id)).length;
  }
}
