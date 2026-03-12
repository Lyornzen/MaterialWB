/// 微博 API 相关常量
class ApiConstants {
  ApiConstants._();

  // 微博开放平台
  static const String officialBaseUrl = 'https://api.weibo.com/2';
  static const String oauthAuthorizeUrl =
      'https://api.weibo.com/oauth2/authorize';
  static const String oauthAccessTokenUrl =
      'https://api.weibo.com/oauth2/access_token';

  // 网页端 API (m.weibo.cn)
  static const String webBaseUrl = 'https://m.weibo.cn/api';

  // PC 网页端 API (weibo.com) — 推荐流、热搜等
  static const String pcWebBaseUrl = 'https://weibo.com';

  // OAuth 配置 —— 替换为你自己的 AppKey
  static const String appKey = 'YOUR_APP_KEY';
  static const String appSecret = 'YOUR_APP_SECRET';
  static const String redirectUri = 'https://api.weibo.com/oauth2/default.html';

  // 官方 API 路径
  static const String homeTimeline = '/statuses/home_timeline.json';
  static const String userShow = '/users/show.json';
  static const String commentsShow = '/comments/show.json';
  static const String favoritesCreate = '/favorites/create.json';
  static const String favoritesDestroy = '/favorites/destroy.json';
  static const String favoritesList = '/favorites.json';

  // 网页端 API 路径 (m.weibo.cn)
  static const String webHotSearch = '/container/getIndex';
  static const String webDetail = '/detail';
  static const String webComments = '/comments/hotflow';
  static const String webUserTimeline = '/container/getIndex';

  // PC 网页端 API 路径 (weibo.com/ajax)
  static const String pcHotTimeline = '/ajax/feed/hottimeline';
  static const String pcHotBand = '/ajax/statuses/hot_band';
  static const String pcSearch = '/ajax/side/search';
  static const String pcSearchList = '/ajax/statuses/searchList';
  static const String pcPostDetail = '/ajax/statuses/show'; // ?id=xxx
  static const String pcComments = '/ajax/statuses/buildComments'; // ?id=xxx

  // Visitor cookie 端点
  static const String visitorGenUrl =
      'https://passport.weibo.com/visitor/genvisitor';
  static const String visitorIncarnateUrl =
      'https://passport.weibo.com/visitor/visitor';
}
