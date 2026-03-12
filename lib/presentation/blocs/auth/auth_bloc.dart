import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_weibo/domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthCookieSaved>(_onCookieSaved);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        final token = await authRepository.getSavedToken();
        if (token != null) {
          try {
            final user = await authRepository.getCurrentUser(token);
            emit(AuthAuthenticated(token: token, user: user));
          } catch (_) {
            emit(AuthAuthenticated(token: token));
          }
        } else {
          emit(const AuthUnauthenticated());
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

  Future<void> _onCookieSaved(
    AuthCookieSaved event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.saveCookie(event.cookie);
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.logout();
    emit(const AuthUnauthenticated());
  }
}
