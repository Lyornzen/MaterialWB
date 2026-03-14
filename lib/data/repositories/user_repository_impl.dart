import 'package:material_weibo/data/datasources/remote/weibo_official_api.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/data/models/user_model.dart';
import 'package:material_weibo/domain/entities/user.dart';
import 'package:material_weibo/domain/repositories/auth_repository.dart';
import 'package:material_weibo/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final WeiboOfficialApi officialApi;
  final WeiboWebApi webApi;
  final AuthRepository authRepository;

  UserRepositoryImpl({
    required this.officialApi,
    required this.webApi,
    required this.authRepository,
  });

  @override
  Future<WeiboUser> getUserInfo({
    required String token,
    required String userId,
  }) async {
    final method = authRepository.getLoginMethod();
    if (method == 'oauth') {
      // OAuth 登录 — 使用官方 API
      final data = await officialApi.getUserInfo(userId);
      return UserModel.fromJson(data);
    } else {
      // Cookie 登录 — 使用 PC web API
      try {
        final data = await webApi.getUserProfile(userId);
        // PC web 格式: { "ok": 1, "data": { "user": { ... } } }
        final userData = data['data']?['user'] as Map<String, dynamic>?;
        if (userData != null) {
          return UserModel.fromJson(userData);
        }
        // 如果没有嵌套 user 字段，尝试直接解析 data
        final directData = data['data'] as Map<String, dynamic>?;
        if (directData != null && directData.containsKey('screen_name')) {
          return UserModel.fromJson(directData);
        }
        throw Exception('用户信息格式异常');
      } catch (_) {
        // 回退到 m.weibo.cn 获取已登录用户信息
        final webUserInfo = await webApi.getLoggedInUserInfo();
        return UserModel.fromJson(webUserInfo);
      }
    }
  }

  @override
  Future<List<WeiboUser>> getFollowing({
    required String token,
    required String userId,
    int page = 1,
    int count = 20,
  }) async {
    // TODO: 实现关注列表（需要网页端API补充）
    return [];
  }

  @override
  Future<List<WeiboUser>> getFollowers({
    required String token,
    required String userId,
    int page = 1,
    int count = 20,
  }) async {
    // TODO: 实现粉丝列表
    return [];
  }

  @override
  Future<void> follow({required String token, required String userId}) async {
    // TODO: 实现关注功能
  }

  @override
  Future<void> unfollow({required String token, required String userId}) async {
    // TODO: 实现取消关注功能
  }
}
