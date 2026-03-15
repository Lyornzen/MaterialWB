/// 应用级常量
class AppConstants {
  AppConstants._();

  static const String appName = 'MaterialWeibo';
  static const String appVersion = '1.0.0';

  // SharedPreferences 键
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyThemeMode = 'theme_mode';
  static const String keyFontScale = 'font_scale';
  static const String keyImageQuality = 'image_quality';
  static const String keySeedColor = 'seed_color';
  static const String keyCookie = 'web_cookie';
  static const String keyLanguage = 'language';

  // Hive / DB 相关
  static const String dbName = 'material_weibo.db';

  // 分页
  static const int defaultPageSize = 20;

  // 缓存时长
  static const Duration cacheMaxAge = Duration(hours: 1);
}
