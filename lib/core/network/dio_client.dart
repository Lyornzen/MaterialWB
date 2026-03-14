import 'package:dio/dio.dart';
import 'package:material_weibo/core/constants/api_constants.dart';
import 'package:material_weibo/core/network/api_interceptors.dart';
import 'package:material_weibo/core/errors/exceptions.dart';

/// 统一的 HTTP 客户端
class DioClient {
  late final Dio _officialDio;
  late final Dio _webDio;
  late final Dio _pcWebDio;
  late final Dio _rawDio; // 无 base URL，用于任意地址请求
  late final AuthInterceptor _authInterceptor;

  DioClient() {
    _authInterceptor = AuthInterceptor();

    _officialDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.officialBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
      ),
    );
    _officialDio.interceptors.addAll([_authInterceptor, LoggingInterceptor()]);

    _webDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.webBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
      ),
    );
    _webDio.interceptors.addAll([_authInterceptor, LoggingInterceptor()]);

    _pcWebDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.pcWebBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
      ),
    );
    _pcWebDio.interceptors.addAll([_authInterceptor, LoggingInterceptor()]);

    _rawDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    _rawDio.interceptors.add(LoggingInterceptor());
  }

  /// 更新 Token
  void updateToken(String? token) => _authInterceptor.updateToken(token);

  /// 更新 Cookie
  void updateCookie(String? cookie) => _authInterceptor.updateCookie(cookie);

  /// 更新 Visitor Cookie（游客模式）
  void updateVisitorCookie(String? cookie) =>
      _authInterceptor.updateVisitorCookie(cookie);

  /// 官方 API GET 请求
  Future<Response> officialGet(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _officialDio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 官方 API POST 请求
  Future<Response> officialPost(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _officialDio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 网页端 API GET 请求 (m.weibo.cn)
  Future<Response> webGet(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _webDio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 网页端 API POST 请求 (m.weibo.cn)
  Future<Response> webPost(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _webDio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PC 网页端 API GET 请求 (weibo.com)
  Future<Response> pcWebGet(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _pcWebDio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PC 网页端 API POST 请求 (weibo.com)
  Future<Response> pcWebPost(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _pcWebDio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 原始 GET 请求（无 base URL，支持任意完整 URL）
  Future<Response> rawGet(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _rawDio.get(
        url,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 原始 POST 请求
  Future<Response> rawPost(String url, {dynamic data, Options? options}) async {
    try {
      return await _rawDio.post(url, data: data, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 将 DioException 转换为自定义异常
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: '请求超时，请稍后重试');
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return const AuthException(message: '授权已过期，请重新登录');
        }
        return ServerException(
          message: e.response?.statusMessage ?? '服务器错误',
          statusCode: statusCode,
        );
      default:
        return ServerException(message: e.message ?? '未知错误');
    }
  }
}
