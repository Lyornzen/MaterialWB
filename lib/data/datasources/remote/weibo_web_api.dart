import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:material_weibo/core/constants/api_constants.dart';
import 'package:material_weibo/core/network/dio_client.dart';

/// 微博网页端 API 数据源（补充官方API不足的接口）
class WeiboWebApi {
  final DioClient dioClient;

  /// 缓存的 visitor cookie（SUB=...）
  String? _visitorCookie;

  WeiboWebApi({required this.dioClient});

  // ─── Visitor Cookie ──────────────────────────────────────

  /// 获取或复用 visitor cookie，用于游客模式访问 weibo.com/ajax 接口
  Future<String> getVisitorCookie() async {
    if (_visitorCookie != null) return _visitorCookie!;

    // Step 1: 获取 tid
    final genResponse = await dioClient.rawPost(
      ApiConstants.visitorGenUrl,
      data: 'cb=gen_callback&fp=%7B%7D',
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
        responseType: ResponseType.plain,
      ),
    );

    final genText = genResponse.data.toString();
    final jsonMatch = RegExp(r'gen_callback\((.+)\)').firstMatch(genText);
    if (jsonMatch == null) throw Exception('获取 visitor tid 失败');

    final genData = jsonDecode(jsonMatch.group(1)!) as Map<String, dynamic>;
    final tid = genData['data']?['tid'] as String?;
    if (tid == null || tid.isEmpty) throw Exception('visitor tid 为空');

    // Step 2: 用 tid 换取 SUB cookie
    final incarnateResponse = await dioClient.rawGet(
      ApiConstants.visitorIncarnateUrl,
      queryParameters: {
        'a': 'incarnate',
        't': tid,
        'w': '2',
        'c': '095',
        'gc': '',
        'cb': 'cross_domain',
        'from': 'weibo',
      },
      options: Options(
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
        // 需要手动获取 set-cookie headers
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    // 从 response headers 提取 SUB cookie
    final setCookies = incarnateResponse.headers['set-cookie'] ?? [];
    String? subCookie;
    for (final c in setCookies) {
      final match = RegExp(r'SUB=([^;]+)').firstMatch(c);
      if (match != null) {
        subCookie = 'SUB=${match.group(1)}';
        break;
      }
    }

    if (subCookie == null) throw Exception('获取 visitor SUB cookie 失败');
    _visitorCookie = subCookie;
    // 同步到 DioClient，让 AuthInterceptor 自动附加到后续 PC web 请求
    dioClient.updateVisitorCookie(subCookie);
    return subCookie;
  }

  /// 清除缓存的 visitor cookie（在需要刷新时调用）
  void clearVisitorCookie() => _visitorCookie = null;

  // ─── 推荐流 (PC web) ─────────────────────────────────────

  /// 获取推荐时间线（使用 weibo.com/ajax 端点 + visitor cookie）
  ///
  /// 返回标准的 statuses 列表，格式与官方 API 一致。
  Future<Map<String, dynamic>> getRecommendTimeline({
    int page = 1,
    String? maxId,
  }) async {
    // 确保有 visitor cookie（cookie 在 interceptor 中自动附加）
    await getVisitorCookie();

    final response = await dioClient.pcWebGet(
      ApiConstants.pcHotTimeline,
      queryParameters: {
        'since_id': '0',
        'refresh': '0',
        'group_id': '102803',
        'containerid': '102803',
        'extparam': 'discover|new_feed',
        'max_id': maxId ?? '0',
        'count': '20',
      },
    );

    final data = response.data;
    if (data is String) {
      // 如果返回的是字符串，尝试解析
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return data as Map<String, dynamic>;
  }

  // ─── 热搜 (PC web) ──────────────────────────────────────

  /// 获取热搜榜（使用 weibo.com/ajax 端点）
  Future<Map<String, dynamic>> getHotSearch() async {
    await getVisitorCookie();
    final response = await dioClient.pcWebGet(ApiConstants.pcHotBand);
    final data = response.data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    return data as Map<String, dynamic>;
  }

  // ─── 微博详情 & 评论 (PC web) ─────────────────────────

  /// 获取微博详情（PC web 端点，游客可用）
  Future<Map<String, dynamic>> getPostDetail(String postId) async {
    await getVisitorCookie();
    final response = await dioClient.pcWebGet(
      ApiConstants.pcPostDetail,
      queryParameters: {'id': postId},
    );
    final data = response.data;
    if (data is String) {
      if (data.trimLeft().startsWith('<')) {
        throw Exception('获取微博详情失败：需要登录');
      }
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return data as Map<String, dynamic>;
  }

  /// 获取评论列表（PC web 端点，游客可用）
  Future<Map<String, dynamic>> getHotComments(
    String postId, {
    int maxId = 0,
  }) async {
    await getVisitorCookie();
    final response = await dioClient.pcWebGet(
      ApiConstants.pcComments,
      queryParameters: {
        'id': postId,
        'is_show_bulletin': '2',
        'is_mix': '0',
        'count': '20',
        'uid': '',
        'fetch_level': '0',
        'locale': 'zh-CN',
        if (maxId > 0) 'flow': '0',
        if (maxId > 0) 'max_id': maxId,
      },
    );
    final data = response.data;
    if (data is String) {
      if (data.trimLeft().startsWith('<')) {
        throw Exception('获取评论失败：需要登录');
      }
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return data as Map<String, dynamic>;
  }

  /// 搜索微博（PC web 端点优先，m.weibo.cn 回退）
  Future<Map<String, dynamic>> search(String keyword, {int page = 1}) async {
    await getVisitorCookie();

    // 尝试使用 PC web 完整搜索端点
    try {
      final response = await dioClient.pcWebGet(
        ApiConstants.pcSearchList,
        queryParameters: {'q': keyword, 'page': page, 'count': '20'},
      );
      final data = response.data;
      final parsed = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;
      // 检查是否有有效数据
      if (parsed['statuses'] != null || parsed['data'] != null) {
        return parsed;
      }
    } catch (_) {}

    // 回退到 m.weibo.cn 搜索
    try {
      final response = await dioClient.webGet(
        ApiConstants.webHotSearch,
        queryParameters: {
          'containerid': '100103type=1&q=$keyword&t=0',
          'page_type': 'searchall',
          'page': page,
        },
      );
      final data = response.data;
      final parsed = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;
      if (parsed['ok'] == 1 || parsed['data'] != null) {
        return parsed;
      }
    } catch (_) {}

    // 最终回退到侧边搜索
    final response = await dioClient.pcWebGet(
      ApiConstants.pcSearch,
      queryParameters: {'q': keyword},
    );
    final data = response.data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    return data as Map<String, dynamic>;
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
        'containerid': '107603${userId}',
        'page': page,
      },
    );
    final data = response.data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    return data as Map<String, dynamic>;
  }

  /// 获取当前 Cookie 登录用户信息
  Future<Map<String, dynamic>> getLoggedInUserInfo() async {
    // 通过 m.weibo.cn/api/config 获取用户信息
    final configResponse = await dioClient.webGet('/config');
    final data = configResponse.data is String
        ? jsonDecode(configResponse.data as String) as Map<String, dynamic>
        : configResponse.data as Map<String, dynamic>;
    final userInfo = data['data']?['login'] == true
        ? (data['data']?['user'] as Map<String, dynamic>?)
        : null;
    if (userInfo == null) throw Exception('未获取到用户信息，Cookie 可能已过期');
    return userInfo;
  }

  // ─── 收藏 (PC web) ────────────────────────────────────

  /// 获取收藏列表（PC web 端点，需要 Cookie 登录）
  Future<Map<String, dynamic>> getFavorites({int page = 1}) async {
    final response = await dioClient.pcWebGet(
      ApiConstants.pcFavorites,
      queryParameters: {'page': page, 'with_total': 'true'},
    );
    final data = response.data;
    if (data is String) {
      if (data.trimLeft().startsWith('<')) {
        throw Exception('获取收藏列表失败：需要登录');
      }
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return data as Map<String, dynamic>;
  }

  /// 收藏微博（PC web 端点）
  Future<Map<String, dynamic>> addFavorite(String postId) async {
    final response = await dioClient.pcWebPost(
      ApiConstants.pcFavoriteAdd,
      data: {'id': postId},
    );
    final data = response.data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    return data as Map<String, dynamic>;
  }

  /// 取消收藏（PC web 端点）
  Future<Map<String, dynamic>> removeFavorite(String postId) async {
    final response = await dioClient.pcWebPost(
      ApiConstants.pcFavoriteRemove,
      data: {'id': postId},
    );
    final data = response.data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    return data as Map<String, dynamic>;
  }

  // ─── 用户信息 (PC web) ───────────────────────────────

  /// 获取用户信息（PC web 端点，需要 Cookie 登录或 visitor cookie）
  Future<Map<String, dynamic>> getUserProfile(String uid) async {
    await getVisitorCookie();
    final response = await dioClient.pcWebGet(
      ApiConstants.pcUserProfile,
      queryParameters: {'uid': uid},
    );
    final data = response.data;
    if (data is String) {
      if (data.trimLeft().startsWith('<')) {
        throw Exception('获取用户信息失败：需要登录');
      }
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return data as Map<String, dynamic>;
  }

  /// 获取用户微博列表（PC web 端点）
  Future<Map<String, dynamic>> getUserTimelinePcWeb(
    String uid, {
    int page = 1,
  }) async {
    await getVisitorCookie();
    final response = await dioClient.pcWebGet(
      ApiConstants.pcUserTimeline,
      queryParameters: {'uid': uid, 'page': page, 'feature': '0'},
    );
    final data = response.data;
    if (data is String) {
      if (data.trimLeft().startsWith('<')) {
        throw Exception('获取用户微博失败：需要登录');
      }
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return data as Map<String, dynamic>;
  }

  // ─── 搜索用户 (PC web) ──────────────────────────────

  /// 搜索用户（PC web 端点）
  Future<Map<String, dynamic>> searchUsers(
    String keyword, {
    int page = 1,
  }) async {
    await getVisitorCookie();
    final response = await dioClient.pcWebGet(
      ApiConstants.pcSearchUser,
      queryParameters: {'q': keyword, 'page': page, 'count': '20'},
    );
    final data = response.data;
    if (data is String) {
      if (data.trimLeft().startsWith('<')) {
        throw Exception('搜索用户失败：需要登录');
      }
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return data as Map<String, dynamic>;
  }

  /// 点赞微博
  Future<Map<String, dynamic>> createAttitude(String postId) async {
    final response = await dioClient.webPost(
      ApiConstants.webAttitudeCreate,
      data: {'id': postId, 'attitude': 'heart', 'st': '0'},
    );
    return response.data as Map<String, dynamic>;
  }

  /// 取消点赞
  Future<Map<String, dynamic>> destroyAttitude(String postId) async {
    final response = await dioClient.webPost(
      ApiConstants.webAttitudeDestroy,
      data: {'id': postId, 'attitude': 'heart', 'st': '0'},
    );
    return response.data as Map<String, dynamic>;
  }

  // ─── 关注/取消关注 (PC web) ──────────────────────────

  /// 关注用户（需要 Cookie 登录）
  Future<Map<String, dynamic>> followUser(String uid) async {
    final response = await dioClient.pcWebPost(
      ApiConstants.pcFriendshipCreate,
      data: {'uid': uid, 'friend_uid': uid},
    );
    final data = response.data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    return data as Map<String, dynamic>;
  }

  /// 取消关注用户（需要 Cookie 登录）
  Future<Map<String, dynamic>> unfollowUser(String uid) async {
    final response = await dioClient.pcWebPost(
      ApiConstants.pcFriendshipDestroy,
      data: {'uid': uid, 'friend_uid': uid},
    );
    final data = response.data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    return data as Map<String, dynamic>;
  }
}
