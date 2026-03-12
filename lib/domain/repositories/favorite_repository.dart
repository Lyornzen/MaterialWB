import 'package:material_weibo/domain/entities/favorite.dart';

/// 收藏仓库接口
abstract class FavoriteRepository {
  /// 获取收藏列表
  Future<List<Favorite>> getFavorites({
    required String token,
    int page = 1,
    int count = 20,
  });

  /// 收藏微博
  Future<void> addFavorite({required String token, required String postId});

  /// 取消收藏
  Future<void> removeFavorite({required String token, required String postId});

  /// 获取本地缓存的收藏列表
  Future<List<Favorite>> getCachedFavorites();

  /// 缓存收藏列表
  Future<void> cacheFavorites(List<Favorite> favorites);
}
