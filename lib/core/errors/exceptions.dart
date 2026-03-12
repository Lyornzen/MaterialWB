/// 应用自定义异常
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;

  const AuthException({required this.message});

  @override
  String toString() => 'AuthException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = '网络连接失败，请检查网络设置'});

  @override
  String toString() => 'NetworkException: $message';
}
