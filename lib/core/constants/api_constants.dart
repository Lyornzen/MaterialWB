/// 微博 API 相关常量
class ApiConstants {
  ApiConstants._();

  // 微博开放平台
  static const String officialBaseUrl = 'https://api.weibo.com/2';

  // 网页端 API (m.weibo.cn)
  static const String webBaseUrl = 'https://m.weibo.cn/api';

  // PC 网页端 API (weibo.com) — 推荐流、热搜等
  static const String pcWebBaseUrl = 'https://weibo.com';

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
  static const String webAttitudeCreate = '/attitudes/create';
  static const String webAttitudeDestroy = '/attitudes/destroy';

  // PC 网页端 API 路径 (weibo.com/ajax)
  static const String pcHotTimeline = '/ajax/feed/hottimeline';
  static const String pcHotBand = '/ajax/statuses/hot_band';
  static const String pcSearch = '/ajax/side/search';
  static const String pcSearchList = '/ajax/statuses/searchList';
  static const String pcPostDetail = '/ajax/statuses/show'; // ?id=xxx
  static const String pcComments = '/ajax/statuses/buildComments'; // ?id=xxx
  static const String pcFavorites = '/ajax/favorites/all_fav'; // 收藏列表
  static const String pcFavoriteAdd = '/ajax/statuses/setFavorite'; // 收藏
  static const String pcFavoriteRemove =
      '/ajax/statuses/destoryFavorite'; // 取消收藏
  static const String pcUserProfile = '/ajax/profile/info'; // 用户信息
  static const String pcUserTimeline = '/ajax/statuses/mymblog'; // 用户微博列表
  static const String pcSearchUser = '/ajax/user/searchUser'; // 搜索用户

  // Visitor cookie 端点
  static const String visitorGenUrl =
      'https://passport.weibo.com/visitor/genvisitor';
  static const String visitorIncarnateUrl =
      'https://passport.weibo.com/visitor/visitor';
}
