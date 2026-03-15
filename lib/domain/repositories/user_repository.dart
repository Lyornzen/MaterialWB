import 'package:material_weibo/domain/entities/user.dart';

/// 用户仓库接口
abstract class UserRepository {
  /// 获取用户信息
  Future<WeiboUser> getUserInfo({
    required String token,
    required String userId,
  });
}
