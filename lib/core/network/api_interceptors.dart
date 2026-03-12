import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Token 认证拦截器
class AuthInterceptor extends Interceptor {
  String? _accessToken;
  String? _cookie;

  void updateToken(String? token) => _accessToken = token;
  void updateCookie(String? cookie) => _cookie = cookie;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 官方 API 使用 access_token 参数
    if (options.baseUrl.contains('api.weibo.com') && _accessToken != null) {
      options.queryParameters['access_token'] = _accessToken;
    }
    // 网页端 API 使用 Cookie
    if (options.baseUrl.contains('m.weibo.cn') && _cookie != null) {
      options.headers['Cookie'] = _cookie;
    }
    options.headers['User-Agent'] =
        'Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('API Error: ${err.requestOptions.uri} -> ${err.message}');
    handler.next(err);
  }
}

/// 日志拦截器（仅 debug 模式）
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('→ ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('✗ ${err.requestOptions.uri} → ${err.message}');
    }
    handler.next(err);
  }
}
