import 'package:material_weibo/core/constants/api_constants.dart';
import 'package:material_weibo/core/network/dio_client.dart';

/// 微博网页端 API 数据源（补充官方API不足的接口）
class WeiboWebApi {
  final DioClient dioClient;

  WeiboWebApi({required this.dioClient});

  /// 获取推荐时间线（无需登录）
  Future<Map<String, dynamic>> getRecommendTimeline({int page = 1}) async {
    final response = await dioClient.webGet(
      ApiConstants.webHotSearch,
      queryParameters: {'containerid': '102803', 'page': page},
    );
    return response.data as Map<String, dynamic>;
  }

  /// 获取热搜榜
  Future<Map<String, dynamic>> getHotSearch() async {
    final response = await dioClient.webGet(
      ApiConstants.webHotSearch,
      queryParameters: {
        'containerid':
            '106003type=25&t=3&disable_hot=1&filter_type=realtimehot',
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// 获取微博详情（网页版）
  Future<Map<String, dynamic>> getPostDetail(String postId) async {
    final response = await dioClient.webGet(
      '${ApiConstants.webDetail}/$postId',
    );
    return response.data as Map<String, dynamic>;
  }

  /// 获取热评（网页版）
  Future<Map<String, dynamic>> getHotComments(
    String postId, {
    int maxId = 0,
  }) async {
    final response = await dioClient.webGet(
      ApiConstants.webComments,
      queryParameters: {
        'id': postId,
        'mid': postId,
        'max_id_type': 0,
        if (maxId > 0) 'max_id': maxId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// 搜索微博
  Future<Map<String, dynamic>> search(String keyword, {int page = 1}) async {
    final response = await dioClient.webGet(
      ApiConstants.webHotSearch,
      queryParameters: {
        'containerid': '100103type=1&q=$keyword',
        'page_type': 'searchall',
        'page': page,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// 获取用户时间线（网页版）
  Future<Map<String, dynamic>> getUserTimeline(
    String userId, {
    int page = 1,
  }) async {
    final response = await dioClient.webGet(
      ApiConstants.webUserTimeline,
      queryParameters: {
        'type': 'uid',
        'value': userId,
        'containerid': '107603$userId',
        'page': page,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// 获取当前 Cookie 登录用户信息
  Future<Map<String, dynamic>> getLoggedInUserInfo() async {
    // 通过 /api/config 获取用户信息
    final configResponse = await dioClient.webGet('/config');
    final data = configResponse.data as Map<String, dynamic>;
    final userInfo = data['data']?['login'] == true
        ? (data['data']?['user'] as Map<String, dynamic>?)
        : null;
    if (userInfo == null) throw Exception('未获取到用户信息，Cookie 可能已过期');
    return userInfo;
  }
}
