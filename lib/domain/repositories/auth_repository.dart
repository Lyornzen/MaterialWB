import 'package:material_weibo/domain/entities/user.dart';

/// 认证仓库接口
abstract class AuthRepository {
  /// 获取 OAuth 授权 URL
  String getAuthorizeUrl();

  /// 通过授权码换取 Token
  Future<String> getAccessToken(String code);

  /// 获取存储的 Token
  Future<String?> getSavedToken();

  /// 保存 Token
  Future<void> saveToken(String token);

  /// 保存网页端 Cookie
  Future<void> saveCookie(String cookie);

  /// 获取网页端 Cookie
  Future<String?> getSavedCookie();

  /// 获取当前登录用户信息
  Future<WeiboUser> getCurrentUser(String token);

  /// 是否已登录
  Future<bool> isLoggedIn();

  /// 退出登录
  Future<void> logout();
}
