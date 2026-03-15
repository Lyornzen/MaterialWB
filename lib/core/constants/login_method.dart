class LoginMethod {
  const LoginMethod._();

  static const cookie = 'cookie';
  static const token = 'token';
  static const legacyOAuth = 'oauth';

  static String normalize(String method) {
    if (method == cookie) return cookie;
    if (method == token || method == legacyOAuth) return token;
    return token;
  }

  static bool usesCookie(String? method) => method == cookie;

  static bool usesToken(String? method) =>
      method != null && normalize(method) == token;
}
