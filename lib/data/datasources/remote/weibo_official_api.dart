import 'package:material_weibo/core/constants/api_constants.dart';
import 'package:material_weibo/core/network/dio_client.dart';

/// 微博官方开放平台 API 数据源
class WeiboOfficialApi {
  final DioClient dioClient;

  WeiboOfficialApi({required this.dioClient});

  /// 获取首页时间线
  Future<Map<String, dynamic>> getHomeTimeline({
    int page = 1,
    int count = 20,
    String? sinceId,
    String? maxId,
  }) async {
    final params = <String, dynamic>{'page': page, 'count': count};
    if (sinceId != null) params['since_id'] = sinceId;
    if (maxId != null) params['max_id'] = maxId;

    final response = await dioClient.officialGet(
      ApiConstants.homeTimeline,
      queryParameters: params,
    );
    return response.data as Map<String, dynamic>;
  }

  /// 获取用户信息
  Future<Map<String, dynamic>> getUserInfo(String uid) async {
    final response = await dioClient.officialGet(
      ApiConstants.userShow,
      queryParameters: {'uid': uid},
    );
    return response.data as Map<String, dynamic>;
  }

  /// 获取微博评论
  Future<Map<String, dynamic>> getComments(
    String postId, {
    int page = 1,
  }) async {
    final response = await dioClient.officialGet(
      ApiConstants.commentsShow,
      queryParameters: {'id': postId, 'page': page, 'count': 20},
    );
    return response.data as Map<String, dynamic>;
  }

  /// 收藏微博
  Future<Map<String, dynamic>> addFavorite(String postId) async {
    final response = await dioClient.officialPost(
      ApiConstants.favoritesCreate,
      data: {'id': postId},
    );
    return response.data as Map<String, dynamic>;
  }

  /// 取消收藏
  Future<Map<String, dynamic>> removeFavorite(String postId) async {
    final response = await dioClient.officialPost(
      ApiConstants.favoritesDestroy,
      data: {'id': postId},
    );
    return response.data as Map<String, dynamic>;
  }

  /// 获取收藏列表
  Future<Map<String, dynamic>> getFavorites({
    int page = 1,
    int count = 20,
  }) async {
    final response = await dioClient.officialGet(
      ApiConstants.favoritesList,
      queryParameters: {'page': page, 'count': count},
    );
    return response.data as Map<String, dynamic>;
  }
}
