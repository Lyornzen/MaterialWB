import 'package:material_weibo/core/network/network_info.dart';
import 'package:material_weibo/data/datasources/local/weibo_local_db.dart';
import 'package:material_weibo/data/datasources/remote/weibo_official_api.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/data/models/weibo_post_model.dart';
import 'package:material_weibo/domain/entities/weibo_post.dart';
import 'package:material_weibo/domain/repositories/timeline_repository.dart';

class TimelineRepositoryImpl implements TimelineRepository {
  final WeiboOfficialApi officialApi;
  final WeiboWebApi webApi;
  final WeiboLocalDb localDb;
  final NetworkInfo networkInfo;

  TimelineRepositoryImpl({
    required this.officialApi,
    required this.webApi,
    required this.localDb,
    required this.networkInfo,
  });

  @override
  Future<List<WeiboPost>> getHomeTimeline({
    required String token,
    int page = 1,
    int count = 20,
    String? sinceId,
    String? maxId,
  }) async {
    final data = await officialApi.getHomeTimeline(
      page: page,
      count: count,
      sinceId: sinceId,
      maxId: maxId,
    );
    final statuses = (data['statuses'] as List?) ?? [];
    final posts = statuses
        .map((json) => WeiboPostModel.fromJson(json as Map<String, dynamic>))
        .toList();
    // 缓存第一页
    if (page == 1) {
      await cacheTimeline(posts);
    }
    return posts;
  }

  @override
  Future<List<WeiboPost>> getUserTimeline({
    required String token,
    required String userId,
    int page = 1,
    int count = 20,
  }) async {
    try {
      // 尝试网页端 API（更稳定）
      final data = await webApi.getUserTimeline(userId, page: page);
      final cards = (data['data']?['cards'] as List?) ?? [];
      return cards
          .where((card) => card['card_type'] == 9)
          .map(
            (card) =>
                WeiboPostModel.fromJson(card['mblog'] as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<WeiboPost>> getCachedTimeline() async {
    final cached = await localDb.getCachedTimeline();
    return cached.map((json) => WeiboPostModel.fromJson(json)).toList();
  }

  @override
  Future<void> cacheTimeline(List<WeiboPost> posts) async {
    final data = posts
        .map((post) => (post as WeiboPostModel).toJson())
        .toList();
    await localDb.cacheTimeline(data);
  }
}
