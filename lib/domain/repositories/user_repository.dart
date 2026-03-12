import 'package:material_weibo/domain/entities/user.dart';

/// 用户仓库接口
abstract class UserRepository {
  /// 获取用户信息
  Future<WeiboUser> getUserInfo({
    required String token,
    required String userId,
  });

  /// 获取用户关注列表
  Future<List<WeiboUser>> getFollowing({
    required String token,
    required String userId,
    int page = 1,
    int count = 20,
  });

  /// 获取用户粉丝列表
  Future<List<WeiboUser>> getFollowers({
    required String token,
    required String userId,
    int page = 1,
    int count = 20,
  });

  /// 关注用户
  Future<void> follow({required String token, required String userId});

  /// 取消关注
  Future<void> unfollow({required String token, required String userId});
}
