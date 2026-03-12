import 'package:material_weibo/core/network/network_info.dart';
import 'package:material_weibo/data/datasources/local/weibo_local_db.dart';
import 'package:material_weibo/data/datasources/remote/weibo_official_api.dart';
import 'package:material_weibo/data/models/favorite_model.dart';
import 'package:material_weibo/domain/entities/favorite.dart';
import 'package:material_weibo/domain/repositories/favorite_repository.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final WeiboOfficialApi officialApi;
  final WeiboLocalDb localDb;
  final NetworkInfo networkInfo;

  FavoriteRepositoryImpl({
    required this.officialApi,
    required this.localDb,
    required this.networkInfo,
  });

  @override
  Future<List<Favorite>> getFavorites({
    required String token,
    int page = 1,
    int count = 20,
  }) async {
    if (await networkInfo.isConnected) {
      final data = await officialApi.getFavorites(page: page, count: count);
      final favorites = (data['favorites'] as List?) ?? [];
      final result = favorites
          .map((json) => FavoriteModel.fromJson(json as Map<String, dynamic>))
          .toList();
      if (page == 1) await cacheFavorites(result);
      return result;
    } else {
      return getCachedFavorites();
    }
  }

  @override
  Future<void> addFavorite({
    required String token,
    required String postId,
  }) async {
    await officialApi.addFavorite(postId);
  }

  @override
  Future<void> removeFavorite({
    required String token,
    required String postId,
  }) async {
    await officialApi.removeFavorite(postId);
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
