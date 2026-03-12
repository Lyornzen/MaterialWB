import 'package:equatable/equatable.dart';

/// 统一失败类型（用于 Domain 层）
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = '网络连接失败，请检查网络设置'});
}
