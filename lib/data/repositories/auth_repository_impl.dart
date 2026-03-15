import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_weibo/core/constants/app_constants.dart';
import 'package:material_weibo/core/constants/login_method.dart';
import 'package:material_weibo/core/network/dio_client.dart';
import 'package:material_weibo/data/datasources/local/preferences_helper.dart';
import 'package:material_weibo/data/datasources/remote/weibo_official_api.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/data/models/user_model.dart';
import 'package:material_weibo/domain/entities/user.dart';
import 'package:material_weibo/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final WeiboOfficialApi officialApi;
  final WeiboWebApi webApi;
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;
  final PreferencesHelper prefsHelper;

  AuthRepositoryImpl({
    required this.officialApi,
    required this.webApi,
    required this.dioClient,
    required this.secureStorage,
    required this.prefsHelper,
  });

  @override
  Future<String?> getSavedToken() =>
      _readTokenWithFallback();

  Future<String?> _readTokenWithFallback() async {
    try {
      final token = await secureStorage.read(key: AppConstants.keyAccessToken);
      if (token != null && token.isNotEmpty) {
        await prefsHelper.setAccessToken(token);
        return token;
      }
    } catch (_) {}
    final fallback = prefsHelper.getAccessToken();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  @override
  Future<void> saveToken(String token) async {
    await prefsHelper.setAccessToken(token);
    try {
      await secureStorage.write(key: AppConstants.keyAccessToken, value: token);
    } catch (_) {}
  }

  @override
  Future<void> saveCookie(String cookie) async {
    await prefsHelper.setCookie(cookie);
    try {
      await secureStorage.write(key: AppConstants.keyCookie, value: cookie);
    } catch (_) {}
    dioClient.updateCookie(cookie);
  }

  @override
  Future<String?> getSavedCookie() async {
    try {
      final cookie = await secureStorage.read(key: AppConstants.keyCookie);
      if (cookie != null && cookie.isNotEmpty) {
        await prefsHelper.setCookie(cookie);
        return cookie;
      }
    } catch (_) {}
    final fallback = prefsHelper.getCookie();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  @override
  Future<WeiboUser> getCurrentUser(String token) async {
    final uid = prefsHelper.getUserId();
    if (uid == null) throw Exception('用户ID未找到');
    final data = await officialApi.getUserInfo(uid);
    return UserModel.fromJson(data);
  }

  @override
  Future<WeiboUser> getCurrentUserByCookie() async {
    final data = await webApi.getLoggedInUserInfo();
    final user = UserModel.fromJson(data);
    if (user.id.isNotEmpty) {
      await prefsHelper.setUserId(user.id);
    }
    return user;
  }

  @override
  Future<void> saveLoginMethod(String method) async {
    await prefsHelper.setLoginMethod(LoginMethod.normalize(method));
  }

  @override
  String? getLoginMethod() {
    final stored = prefsHelper.getLoginMethod();
    if (stored != null && stored.isNotEmpty) {
      return LoginMethod.normalize(stored);
    }
    final cookie = prefsHelper.getCookie();
    if (cookie != null && cookie.isNotEmpty) {
      return LoginMethod.cookie;
    }
    final token = prefsHelper.getAccessToken();
    if (token != null && token.isNotEmpty) {
      return LoginMethod.token;
    }
    return null;
  }

  @override
  Future<bool> isLoggedIn() async {
    final method = getLoginMethod();
    if (LoginMethod.usesCookie(method)) {
      final cookie = await getSavedCookie();
      return cookie != null && cookie.isNotEmpty;
    }
    final token = await getSavedToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    try {
      await secureStorage.delete(key: AppConstants.keyAccessToken);
      await secureStorage.delete(key: AppConstants.keyCookie);
    } catch (_) {}
    dioClient.updateToken(null);
    dioClient.updateCookie(null);
    await prefsHelper.clearAll();
  }
}
