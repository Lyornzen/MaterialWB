import 'package:material_weibo/domain/entities/weibo_post.dart';

/// 时间线仓库接口
abstract class TimelineRepository {
  /// 获取首页时间线（需要登录）
  Future<List<WeiboPost>> getHomeTimeline({
    required String token,
    int page = 1,
    int count = 20,
    String? sinceId,
    String? maxId,
  });

  /// 获取推荐时间线（无需登录，Web API）
  Future<List<WeiboPost>> getRecommendTimeline({int page = 1});

  /// 获取用户微博列表
  Future<List<WeiboPost>> getUserTimeline({
    required String token,
    required String userId,
    int page = 1,
    int count = 20,
  });

  /// 获取缓存的时间线
  Future<List<WeiboPost>> getCachedTimeline();

  /// 缓存时间线数据
  Future<void> cacheTimeline(List<WeiboPost> posts);
}
