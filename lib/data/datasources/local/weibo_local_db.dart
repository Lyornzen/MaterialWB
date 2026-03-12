import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 简易本地数据库，使用 SharedPreferences + JSON 存储
/// 后续可替换为 Drift/SQLite 实现
class WeiboLocalDb {
  static const String _timelineCacheKey = 'cache_timeline';
  static const String _favoritesCacheKey = 'cache_favorites';
  static const String _historyKey = 'browse_history';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _getPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── 时间线缓存 ──
  Future<void> cacheTimeline(List<Map<String, dynamic>> data) async {
    final prefs = await _getPrefs;
    await prefs.setString(_timelineCacheKey, jsonEncode(data));
  }

  Future<List<Map<String, dynamic>>> getCachedTimeline() async {
    final prefs = await _getPrefs;
    final raw = prefs.getString(_timelineCacheKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // ── 收藏缓存 ──
  Future<void> cacheFavorites(List<Map<String, dynamic>> data) async {
    final prefs = await _getPrefs;
    await prefs.setString(_favoritesCacheKey, jsonEncode(data));
  }

  Future<List<Map<String, dynamic>>> getCachedFavorites() async {
    final prefs = await _getPrefs;
    final raw = prefs.getString(_favoritesCacheKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // ── 浏览历史 ──
  Future<void> addHistory(Map<String, dynamic> post) async {
    final prefs = await _getPrefs;
    final history = await getHistory();
    // 去重：如果已存在则移到最前
    history.removeWhere((item) => item['id'] == post['id']);
    history.insert(0, post);
    // 最多保留 200 条
    if (history.length > 200) {
      history.removeRange(200, history.length);
    }
    await prefs.setString(_historyKey, jsonEncode(history));
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await _getPrefs;
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> removeHistory(String postId) async {
    final prefs = await _getPrefs;
    final history = await getHistory();
    history.removeWhere((item) => item['id'] == postId);
    await prefs.setString(_historyKey, jsonEncode(history));
  }

  Future<void> clearHistory() async {
    final prefs = await _getPrefs;
    await prefs.remove(_historyKey);
  }

  Future<int> getHistoryCount() async {
    final history = await getHistory();
    return history.length;
  }

  /// 清除所有缓存
  Future<void> clearAllCache() async {
    final prefs = await _getPrefs;
    await prefs.remove(_timelineCacheKey);
    await prefs.remove(_favoritesCacheKey);
  }
}
