import 'package:material_weibo/core/network/network_info.dart';
import 'package:material_weibo/data/datasources/local/weibo_local_db.dart';
import 'package:material_weibo/data/datasources/remote/weibo_official_api.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/data/models/favorite_model.dart';
import 'package:material_weibo/data/models/weibo_post_model.dart';
import 'package:material_weibo/domain/entities/favorite.dart';
import 'package:material_weibo/domain/repositories/auth_repository.dart';
import 'package:material_weibo/domain/repositories/favorite_repository.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final WeiboOfficialApi officialApi;
  final WeiboWebApi webApi;
  final WeiboLocalDb localDb;
  final NetworkInfo networkInfo;
  final AuthRepository authRepository;

  FavoriteRepositoryImpl({
    required this.officialApi,
    required this.webApi,
    required this.localDb,
    required this.networkInfo,
    required this.authRepository,
  });

  @override
  Future<List<Favorite>> getFavorites({
    required String token,
    int page = 1,
    int count = 20,
  }) async {
    if (await networkInfo.isConnected) {
      final method = authRepository.getLoginMethod();
      if (method == 'oauth') {
        // OAuth 登录 — 使用官方 API
        final data = await officialApi.getFavorites(page: page, count: count);
        final favorites = (data['favorites'] as List?) ?? [];
        final result = favorites
            .map((json) => FavoriteModel.fromJson(json as Map<String, dynamic>))
            .toList();
        if (page == 1) await cacheFavorites(result);
        return result;
      } else {
        // Cookie 登录 — 使用 PC web API
        final data = await webApi.getFavorites(page: page);
        // PC web 格式: { "data": [ { status 对象 }, ... ], "total_number": N }
        // 或 { "data": [{ "status": {...}, "favorited_time": "..." }] }
        final rawList = (data['data'] as List?) ?? [];
        final result = rawList.map((item) {
          final json = item as Map<String, dynamic>;
          // PC web 收藏列表直接返回微博对象（非嵌套在 status 中）
          if (json.containsKey('status')) {
            return FavoriteModel.fromJson(json);
          }
          // 直接是微博对象
          return FavoriteModel(
            id: (json['id'] ?? json['idstr'] ?? '').toString(),
            post: WeiboPostModel.fromJson(json),
            favoritedAt: DateTime.now(),
          );
        }).toList();
        if (page == 1) await cacheFavorites(result);
        return result;
      }
    } else {
      return getCachedFavorites();
    }
  }

  @override
  Future<void> addFavorite({
    required String token,
    required String postId,
  }) async {
    final method = authRepository.getLoginMethod();
    if (method == 'oauth') {
      await officialApi.addFavorite(postId);
    } else {
      await webApi.addFavorite(postId);
    }
  }

  @override
  Future<void> removeFavorite({
    required String token,
    required String postId,
  }) async {
    final method = authRepository.getLoginMethod();
    if (method == 'oauth') {
      await officialApi.removeFavorite(postId);
    } else {
      await webApi.removeFavorite(postId);
    }
  }

  @override
  Future<List<Favorite>> getCachedFavorites() async {
    final cached = await localDb.getCachedFavorites();
    return cached.map((json) => FavoriteModel.fromJson(json)).toList();
  }

  @override
  Future<void> cacheFavorites(List<Favorite> favorites) async {
    final data = favorites
        .map((fav) => (fav as FavoriteModel).toJson())
        .toList();
    await localDb.cacheFavorites(data);
  }
}
