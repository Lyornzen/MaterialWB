import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Token 认证拦截器
class AuthInterceptor extends Interceptor {
  String? _accessToken;
  String? _cookie;
  String? _visitorCookie;

  void updateToken(String? token) => _accessToken = token;
  void updateCookie(String? cookie) => _cookie = cookie;
  void updateVisitorCookie(String? cookie) => _visitorCookie = cookie;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 官方 API 使用 access_token 参数
    if (options.baseUrl.contains('api.weibo.com') && _accessToken != null) {
      options.queryParameters['access_token'] = _accessToken;
    }
    // 网页端 API 使用 Cookie (m.weibo.cn 和 weibo.com)
    if (options.baseUrl.contains('m.weibo.cn') && _cookie != null) {
      options.headers['Cookie'] = _cookie;
    } else if (options.baseUrl.contains('weibo.com') &&
        !options.baseUrl.contains('m.weibo.cn')) {
      // PC weibo.com 优先使用用户 cookie，其次使用 visitor cookie
      final effectiveCookie = _cookie ?? _visitorCookie;
      if (effectiveCookie != null) {
        options.headers['Cookie'] = effectiveCookie;
      }
    }
    // PC 端使用桌面 UA，移动端使用移动 UA
    if (options.baseUrl.contains('weibo.com') &&
        !options.baseUrl.contains('m.weibo.cn')) {
      options.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
      options.headers['Referer'] = 'https://weibo.com/';
    } else {
      options.headers['User-Agent'] =
          'Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    }
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
