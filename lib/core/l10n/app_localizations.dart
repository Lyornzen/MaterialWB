import 'package:flutter/widgets.dart';

/// 支持的语言枚举
enum AppLocale {
  zhCN('zh-CN', '简体中文', Locale('zh', 'CN')),
  zhTW('zh-TW', '繁體中文', Locale('zh', 'TW')),
  en('en', 'English', Locale('en'));

  final String code;
  final String displayName;
  final Locale locale;

  const AppLocale(this.code, this.displayName, this.locale);

  static AppLocale fromCode(String code) {
    return AppLocale.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLocale.zhCN,
    );
  }
}

/// 翻译字符串表
class S {
  static AppLocale _current = AppLocale.zhCN;

  static AppLocale get currentLocale => _current;
  // ignore: unnecessary_getters_setters — needed to sync locale on change
  static set currentLocale(AppLocale locale) => _current = locale;

  static String get(String key) {
    return _translations[_current.code]?[key] ??
        _translations['zh-CN']![key] ??
        key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'zh-CN': _zhCN,
    'zh-TW': _zhTW,
    'en': _en,
  };

  // ── 简体中文 ──
  static const _zhCN = {
    // 通用
    'app_name': 'Material 微博',
    'cancel': '取消',
    'confirm': '确定',
    'exit': '退出',
    'login': '去登录',
    'logout': '退出登录',
    'retry': '重试',
    'loading': '加载中...',
    'no_data': '暂无数据',

    // 底部导航
    'nav_home': '首页',
    'nav_discover': '发现',
    'nav_favorites': '收藏',
    'nav_me': '我的',

    // 首页
    'home_no_posts': '暂无微博',
    'exit_app': '退出应用',
    'exit_app_confirm': '确定要退出 Material 微博吗？',

    // 搜索
    'search': '搜索',
    'search_hint': '搜索微博',
    'search_no_results': '未找到相关内容',
    'hot_search': '热门搜索',

    // 收藏
    'favorites': '收藏',
    'login_required_feature': '登录后即可使用{feature}功能',

    // 我的
    'me': '我的',
    'not_logged_in': '未登录',
    'login_hint': '登录后可查看收藏、个人资料等',
    'browse_history': '浏览历史',
    'my_favorites': '我的收藏',

    // 个人资料
    'posts_count': '微博',
    'following_count': '关注',
    'followers_count': '粉丝',
    'follow': '关注',
    'following': '已关注',
    'login_to_follow': '请先登录后再操作',
    'follow_failed': '操作失败',

    // 设置
    'settings': '设置',
    'appearance': '外观',
    'follow_system': '跟随系统',
    'light_mode': '浅色模式',
    'dark_mode': '深色模式',
    'theme_color': '主题色',
    'system_default': '跟随系统 / 默认',
    'custom_color': '自定义颜色',
    'pick_custom_color': '选择自定义颜色',
    'hue': '色相',
    'font_size': '字体大小',
    'preview_text': '预览文字',
    'language': '语言',
    'about': '关于',
    'version': '版本',
    'login_method': '登录方式',
    'cookie_login': 'Cookie 登录',
    'oauth_login': 'OAuth 登录',
    'logout_confirm': '确定要退出登录吗？退出后将返回登录页面。',

    // 颜色名称
    'color_weibo_red': '微博红',
    'color_sky_blue': '天空蓝',
    'color_emerald': '翠绿',
    'color_deep_purple': '深紫',
    'color_orange': '橙色',
    'color_teal': '青色',
    'color_pink': '粉色',
    'color_indigo': '靛蓝',
    'color_brown': '棕色',
    'color_blue_grey': '蓝灰',
  };

  // ── 繁體中文 ──
  static const _zhTW = {
    // 通用
    'app_name': 'Material 微博',
    'cancel': '取消',
    'confirm': '確定',
    'exit': '退出',
    'login': '去登入',
    'logout': '登出',
    'retry': '重試',
    'loading': '載入中...',
    'no_data': '暫無資料',

    // 底部導航
    'nav_home': '首頁',
    'nav_discover': '探索',
    'nav_favorites': '收藏',
    'nav_me': '我的',

    // 首頁
    'home_no_posts': '暫無微博',
    'exit_app': '退出應用',
    'exit_app_confirm': '確定要退出 Material 微博嗎？',

    // 搜尋
    'search': '搜尋',
    'search_hint': '搜尋微博',
    'search_no_results': '未找到相關內容',
    'hot_search': '熱門搜尋',

    // 收藏
    'favorites': '收藏',
    'login_required_feature': '登入後即可使用{feature}功能',

    // 我的
    'me': '我的',
    'not_logged_in': '未登入',
    'login_hint': '登入後可查看收藏、個人資料等',
    'browse_history': '瀏覽歷史',
    'my_favorites': '我的收藏',

    // 個人資料
    'posts_count': '微博',
    'following_count': '關注',
    'followers_count': '粉絲',
    'follow': '關注',
    'following': '已關注',
    'login_to_follow': '請先登入後再操作',
    'follow_failed': '操作失敗',

    // 設定
    'settings': '設定',
    'appearance': '外觀',
    'follow_system': '跟隨系統',
    'light_mode': '淺色模式',
    'dark_mode': '深色模式',
    'theme_color': '主題色',
    'system_default': '跟隨系統 / 預設',
    'custom_color': '自訂顏色',
    'pick_custom_color': '選擇自訂顏色',
    'hue': '色相',
    'font_size': '字體大小',
    'preview_text': '預覽文字',
    'language': '語言',
    'about': '關於',
    'version': '版本',
    'login_method': '登入方式',
    'cookie_login': 'Cookie 登入',
    'oauth_login': 'OAuth 登入',
    'logout_confirm': '確定要登出嗎？登出後將返回登入頁面。',

    // 顏色名稱
    'color_weibo_red': '微博紅',
    'color_sky_blue': '天空藍',
    'color_emerald': '翠綠',
    'color_deep_purple': '深紫',
    'color_orange': '橙色',
    'color_teal': '青色',
    'color_pink': '粉色',
    'color_indigo': '靛藍',
    'color_brown': '棕色',
    'color_blue_grey': '藍灰',
  };

  // ── English ──
  static const _en = {
    // General
    'app_name': 'Material Weibo',
    'cancel': 'Cancel',
    'confirm': 'OK',
    'exit': 'Exit',
    'login': 'Login',
    'logout': 'Logout',
    'retry': 'Retry',
    'loading': 'Loading...',
    'no_data': 'No data',

    // Bottom navigation
    'nav_home': 'Home',
    'nav_discover': 'Discover',
    'nav_favorites': 'Favorites',
    'nav_me': 'Me',

    // Home
    'home_no_posts': 'No posts yet',
    'exit_app': 'Exit App',
    'exit_app_confirm': 'Are you sure you want to exit Material Weibo?',

    // Search
    'search': 'Search',
    'search_hint': 'Search Weibo',
    'search_no_results': 'No results found',
    'hot_search': 'Trending',

    // Favorites
    'favorites': 'Favorites',
    'login_required_feature': 'Login to use {feature}',

    // Me
    'me': 'Me',
    'not_logged_in': 'Not logged in',
    'login_hint': 'Login to view favorites, profile, etc.',
    'browse_history': 'History',
    'my_favorites': 'My Favorites',

    // Profile
    'posts_count': 'Posts',
    'following_count': 'Following',
    'followers_count': 'Followers',
    'follow': 'Follow',
    'following': 'Following',
    'login_to_follow': 'Please login first',
    'follow_failed': 'Operation failed',

    // Settings
    'settings': 'Settings',
    'appearance': 'Appearance',
    'follow_system': 'Follow system',
    'light_mode': 'Light mode',
    'dark_mode': 'Dark mode',
    'theme_color': 'Theme Color',
    'system_default': 'System / Default',
    'custom_color': 'Custom color',
    'pick_custom_color': 'Pick custom color',
    'hue': 'Hue',
    'font_size': 'Font Size',
    'preview_text': 'Preview text',
    'language': 'Language',
    'about': 'About',
    'version': 'Version',
    'login_method': 'Login method',
    'cookie_login': 'Cookie login',
    'oauth_login': 'OAuth login',
    'logout_confirm':
        'Are you sure you want to logout? You will be redirected to the login page.',

    // Color names
    'color_weibo_red': 'Weibo Red',
    'color_sky_blue': 'Sky Blue',
    'color_emerald': 'Emerald',
    'color_deep_purple': 'Deep Purple',
    'color_orange': 'Orange',
    'color_teal': 'Teal',
    'color_pink': 'Pink',
    'color_indigo': 'Indigo',
    'color_brown': 'Brown',
    'color_blue_grey': 'Blue Grey',
  };
}
