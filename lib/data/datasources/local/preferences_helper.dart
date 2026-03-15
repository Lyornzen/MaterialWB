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

  // ── 图片质量 ──
  Future<void> setImageQuality(String quality) =>
      prefs.setString(AppConstants.keyImageQuality, quality);

  String getImageQuality() =>
      prefs.getString(AppConstants.keyImageQuality) ?? 'auto';

  // ── 用户ID ──
  Future<void> setUserId(String id) =>
      prefs.setString(AppConstants.keyUserId, id);

  String? getUserId() => prefs.getString(AppConstants.keyUserId);

  // ── 认证信息兜底存储（用于 secure storage 不可用场景）──
  Future<void> setAccessToken(String token) =>
      prefs.setString(AppConstants.keyAccessToken, token);

  String? getAccessToken() => prefs.getString(AppConstants.keyAccessToken);

  Future<void> setCookie(String cookie) =>
      prefs.setString(AppConstants.keyCookie, cookie);

  String? getCookie() => prefs.getString(AppConstants.keyCookie);

  // ── 登录方式 ──
  static const String _keyLoginMethod = 'login_method';

  Future<void> setLoginMethod(String method) =>
      prefs.setString(_keyLoginMethod, method);

  String? getLoginMethod() => prefs.getString(_keyLoginMethod);

  // ── 语言 ──
  Future<void> setLanguage(String value) =>
      prefs.setString(AppConstants.keyLanguage, value);

  String getLanguage() => prefs.getString(AppConstants.keyLanguage) ?? 'system';

  // ── 清除所有 ──
  Future<void> clearAll() => prefs.clear();
}
