import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckStatus extends AuthEvent {
  const AuthCheckStatus();
}

/// Web Cookie 登录
class AuthCookieLoginRequested extends AuthEvent {
  final String cookie;
  const AuthCookieLoginRequested({required this.cookie});
  @override
  List<Object?> get props => [cookie];
}

/// 进入游客模式
class AuthGuestRequested extends AuthEvent {
  const AuthGuestRequested();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
