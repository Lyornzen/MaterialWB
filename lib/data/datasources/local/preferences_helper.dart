import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_weibo/core/constants/app_constants.dart';

/// SharedPreferences 封装
class PreferencesHelper {
  final SharedPreferences prefs;

  PreferencesHelper({required this.prefs});

  // ── 主题 ──
  Future<void> setThemeMode(String mode) =>
      prefs.setString(AppConstants.keyThemeMode, mode);

  String getThemeMode() =>
      prefs.getString(AppConstants.keyThemeMode) ?? 'system';

  // ── 字体缩放 ──
  Future<void> setFontScale(double scale) =>
      prefs.setDouble(AppConstants.keyFontScale, scale);

  double getFontScale() => prefs.getDouble(AppConstants.keyFontScale) ?? 1.0;

  // ── 图片质量 ──
  Future<void> setImageQuality(String quality) =>
      prefs.setString(AppConstants.keyImageQuality, quality);

  String getImageQuality() =>
      prefs.getString(AppConstants.keyImageQuality) ?? 'auto';

  // ── 用户ID ──
  Future<void> setUserId(String id) =>
      prefs.setString(AppConstants.keyUserId, id);

  String? getUserId() => prefs.getString(AppConstants.keyUserId);

  // ── 登录方式 ──
  static const String _keyLoginMethod = 'login_method';

  Future<void> setLoginMethod(String method) =>
      prefs.setString(_keyLoginMethod, method);

  String? getLoginMethod() => prefs.getString(_keyLoginMethod);

  // ── 清除所有 ──
  Future<void> clearAll() => prefs.clear();
}
