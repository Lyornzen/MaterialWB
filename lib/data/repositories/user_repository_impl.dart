import 'package:material_weibo/data/datasources/remote/weibo_official_api.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/data/models/user_model.dart';
import 'package:material_weibo/domain/entities/user.dart';
import 'package:material_weibo/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final WeiboOfficialApi officialApi;
  final WeiboWebApi webApi;

  UserRepositoryImpl({required this.officialApi, required this.webApi});

  @override
  Future<WeiboUser> getUserInfo({
    required String token,
    required String userId,
  }) async {
    final data = await officialApi.getUserInfo(userId);
    return UserModel.fromJson(data);
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
