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

  // ── 主题色 ──
  Future<void> setSeedColor(int? colorValue) {
    if (colorValue == null) {
      return prefs.remove(AppConstants.keySeedColor);
    }
    return prefs.setInt(AppConstants.keySeedColor, colorValue);
  }

  int? getSeedColor() => prefs.getInt(AppConstants.keySeedColor);

  // ── 语言 ──
  Future<void> setLocale(String locale) =>
      prefs.setString(AppConstants.keyLocale, locale);

  String getLocale() => prefs.getString(AppConstants.keyLocale) ?? 'zh-CN';

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

  /// 只清除认证相关数据，保留用户偏好（主题、字体、颜色等）
  Future<void> clearAuthData() async {
    await prefs.remove(_keyLoginMethod);
    await prefs.remove(AppConstants.keyUserId);
  }
}
