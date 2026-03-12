import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_weibo/core/constants/app_constants.dart';
import 'package:material_weibo/data/datasources/local/preferences_helper.dart';
import 'package:material_weibo/data/datasources/remote/weibo_official_api.dart';
import 'package:material_weibo/data/models/user_model.dart';
import 'package:material_weibo/domain/entities/user.dart';
import 'package:material_weibo/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final WeiboOfficialApi officialApi;
  final FlutterSecureStorage secureStorage;
  final PreferencesHelper prefsHelper;

  AuthRepositoryImpl({
    required this.officialApi,
    required this.secureStorage,
    required this.prefsHelper,
  });

  @override
  String getAuthorizeUrl() => officialApi.getAuthorizeUrl();

  @override
  Future<String> getAccessToken(String code) async {
    final data = await officialApi.getAccessToken(code);
    final token = data['access_token'] as String;
    final uid = data['uid']?.toString() ?? '';
    await saveToken(token);
    if (uid.isNotEmpty) {
      await prefsHelper.setUserId(uid);
    }
    return token;
  }

  @override
  Future<String?> getSavedToken() =>
      secureStorage.read(key: AppConstants.keyAccessToken);

  @override
  Future<void> saveToken(String token) =>
      secureStorage.write(key: AppConstants.keyAccessToken, value: token);

  @override
  Future<void> saveCookie(String cookie) =>
      secureStorage.write(key: AppConstants.keyCookie, value: cookie);

  @override
  Future<String?> getSavedCookie() =>
      secureStorage.read(key: AppConstants.keyCookie);

  @override
  Future<WeiboUser> getCurrentUser(String token) async {
    final uid = prefsHelper.getUserId();
    if (uid == null) throw Exception('用户ID未找到');
    final data = await officialApi.getUserInfo(uid);
    return UserModel.fromJson(data);
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await getSavedToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    await secureStorage.delete(key: AppConstants.keyAccessToken);
    await secureStorage.delete(key: AppConstants.keyCookie);
    await prefsHelper.clearAll();
  }
}
