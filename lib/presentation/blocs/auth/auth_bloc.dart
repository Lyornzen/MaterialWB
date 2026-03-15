import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_weibo/core/di/injection.dart';
import 'package:material_weibo/core/network/dio_client.dart';
import 'package:material_weibo/data/datasources/local/preferences_helper.dart';
import 'package:material_weibo/domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthCookieLoginRequested>(_onCookieLoginRequested);
    on<AuthCookieSaved>(_onCookieSaved);
    on<AuthGuestRequested>(_onGuestRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  /// 将 token 和 cookie 同步到 DioClient 拦截器
  Future<void> _syncCredentials(String token) async {
    final dioClient = sl<DioClient>();
    dioClient.updateToken(token);
    // 同步 cookie（如果存在）
    final cookie = await authRepository.getSavedCookie();
    if (cookie != null && cookie.isNotEmpty) {
      dioClient.updateCookie(cookie);
    }
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        final method = authRepository.getLoginMethod() ?? 'oauth';
        if (method == 'cookie') {
          // Cookie 登录，同步 cookie 到拦截器并获取用户信息
          final cookie = await authRepository.getSavedCookie();
          if (cookie != null && cookie.isNotEmpty) {
            sl<DioClient>().updateCookie(cookie);
          }
          try {
            final cookie = await authRepository.getSavedCookie();
            if (cookie != null) {
              final user = await authRepository.getCurrentUserByCookie();
              emit(
                AuthAuthenticated(
                  token: cookie,
                  user: user,
                  loginMethod: 'cookie',
                ),
              );
            } else {
              emit(const AuthUnauthenticated());
            }
          } catch (_) {
            // 用户资料接口可能暂时失败，不直接清空登录态
            final cookie = await authRepository.getSavedCookie();
            if (cookie != null && cookie.isNotEmpty) {
              emit(
                AuthAuthenticated(
                  token: cookie,
                  loginMethod: 'cookie',
                ),
              );
            } else {
              emit(const AuthUnauthenticated());
            }
          }
        } else {
          // OAuth 登录
          final token = await authRepository.getSavedToken();
          if (token != null) {
            await _syncCredentials(token);
            try {
              final user = await authRepository.getCurrentUser(token);
              emit(AuthAuthenticated(token: token, user: user));
            } catch (_) {
              emit(AuthAuthenticated(token: token));
            }
          } else {
            emit(const AuthUnauthenticated());
          }
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final token = await authRepository.getAccessToken(event.code);
      // 同步 token 到拦截器
      await _syncCredentials(token);
      try {
        final user = await authRepository.getCurrentUser(token);
        emit(AuthAuthenticated(token: token, user: user));
      } catch (_) {
        emit(AuthAuthenticated(token: token));
      }
    } catch (e) {
      emit(AuthError(message: '登录失败: ${e.toString()}'));
    }
  }

  Future<void> _onCookieLoginRequested(
    AuthCookieLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await authRepository.saveCookie(event.cookie);
      await authRepository.saveLoginMethod('cookie');
      // Cookie 登录也保存一个稳定 token，避免下游逻辑判空失败。
      await authRepository.saveToken('cookie_session');
      try {
        final user = await authRepository.getCurrentUserByCookie();
        final uid = user.id;
        // 保存 uid 供后续使用
        if (uid.isNotEmpty) {
          await authRepository.saveToken('cookie_$uid');
        }
        emit(
          AuthAuthenticated(
            token: event.cookie,
            user: user,
            loginMethod: 'cookie',
          ),
        );
      } catch (_) {
        final uid = _extractUidFromCookie(event.cookie);
        if (uid != null && uid.isNotEmpty) {
          await sl<PreferencesHelper>().setUserId(uid);
          await authRepository.saveToken('cookie_$uid');
        }
        emit(AuthAuthenticated(token: event.cookie, loginMethod: 'cookie'));
      }
    } catch (e) {
      emit(AuthError(message: 'Cookie 登录失败: ${e.toString()}'));
    }
  }

  String? _extractUidFromCookie(String cookie) {
    final match = RegExp(r'DedeUserID=([^;]+)').firstMatch(cookie);
    return match?.group(1);
  }

  Future<void> _onCookieSaved(
    AuthCookieSaved event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.saveCookie(event.cookie);
    // 同步 cookie 到拦截器
    sl<DioClient>().updateCookie(event.cookie);
  }

  Future<void> _onGuestRequested(
    AuthGuestRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthGuest());
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.logout();
    // 清除拦截器中的认证信息
    final dioClient = sl<DioClient>();
    dioClient.updateToken(null);
    dioClient.updateCookie(null);
    emit(const AuthUnauthenticated());
  }
}
