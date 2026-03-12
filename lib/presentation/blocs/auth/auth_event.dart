import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckStatus extends AuthEvent {
  const AuthCheckStatus();
}

class AuthLoginRequested extends AuthEvent {
  final String code;
  const AuthLoginRequested({required this.code});
  @override
  List<Object?> get props => [code];
}

class AuthCookieSaved extends AuthEvent {
  final String cookie;
  const AuthCookieSaved({required this.cookie});
  @override
  List<Object?> get props => [cookie];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
