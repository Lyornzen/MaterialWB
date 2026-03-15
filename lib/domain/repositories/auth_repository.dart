import 'package:material_weibo/domain/entities/user.dart';

/// 认证仓库接口
abstract class AuthRepository {
  /// 获取存储的 Token
  Future<String?> getSavedToken();

  /// 保存 Token
  Future<void> saveToken(String token);

  /// 保存网页端 Cookie
  Future<void> saveCookie(String cookie);

  /// 获取网页端 Cookie
  Future<String?> getSavedCookie();

  /// 获取当前登录用户信息（官方 API）
  Future<WeiboUser> getCurrentUser(String token);

  /// 通过 Cookie 获取当前登录用户信息（网页端 API）
  Future<WeiboUser> getCurrentUserByCookie();

  /// 保存登录方式 ('token' | 'cookie')
  Future<void> saveLoginMethod(String method);

  /// 获取保存的登录方式
  String? getLoginMethod();

  /// 是否已登录
  Future<bool> isLoggedIn();

  /// 退出登录
  Future<void> logout();
}
