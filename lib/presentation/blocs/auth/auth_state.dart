import 'package:equatable/equatable.dart';
import 'package:material_weibo/domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];

  /// 是否已登录（非游客）
  bool get isLoggedIn => false;

  /// 是否为游客模式
  bool get isGuest => false;
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final String token;
  final WeiboUser? user;

  /// 登录方式: 'oauth' 或 'cookie'
  final String loginMethod;
  const AuthAuthenticated({
    required this.token,
    this.user,
    this.loginMethod = 'oauth',
  });

  @override
  bool get isLoggedIn => true;

  @override
  List<Object?> get props => [token, user, loginMethod];
}

/// 游客模式 — 可以浏览推荐流，但不能使用需要登录的功能
class AuthGuest extends AuthState {
  const AuthGuest();

  @override
  bool get isGuest => true;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}
