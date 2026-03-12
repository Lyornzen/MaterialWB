import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:material_weibo/core/constants/api_constants.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_bloc.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_event.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _WebViewMode { none, oauth, cookie }

class _LoginPageState extends State<LoginPage> {
  _WebViewMode _webViewMode = _WebViewMode.none;
  late final WebViewController _oauthController;
  late final WebViewController _cookieController;

  @override
  void initState() {
    super.initState();

    // OAuth WebView 控制器
    _oauthController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            if (request.url.startsWith(ApiConstants.redirectUri)) {
              final code = uri.queryParameters['code'];
              if (code != null && mounted) {
                context.read<AuthBloc>().add(AuthLoginRequested(code: code));
                setState(() => _webViewMode = _WebViewMode.none);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // Cookie 登录 WebView 控制器
    _cookieController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (url) => _checkCookieLogin(url)),
      );
  }

  /// 检查 Cookie 登录是否成功
  Future<void> _checkCookieLogin(String url) async {
    // 用户登录成功后会跳转到 m.weibo.cn 主页
    if (url.contains('m.weibo.cn') &&
        !url.contains('login') &&
        !url.contains('passport')) {
      // 通过 JS 获取 document.cookie
      try {
        final cookie = await _cookieController.runJavaScriptReturningResult(
          'document.cookie',
        );
        final cookieStr = cookie.toString().replaceAll('"', '');
        if (cookieStr.contains('SUB=') && mounted) {
          context.read<AuthBloc>().add(
            AuthCookieLoginRequested(cookie: cookieStr),
          );
          setState(() => _webViewMode = _WebViewMode.none);
        }
      } catch (_) {}
    }
  }

  void _startOAuthLogin() {
    final authBloc = context.read<AuthBloc>();
    final url = (authBloc.authRepository).getAuthorizeUrl();
    _oauthController.loadRequest(Uri.parse(url));
    setState(() => _webViewMode = _WebViewMode.oauth);
  }

  void _startCookieLogin() {
    _cookieController.loadRequest(
      Uri.parse('https://passport.weibo.cn/signin/login'),
    );
    setState(() => _webViewMode = _WebViewMode.cookie);
  }

  void _enterGuestMode() {
    context.read<AuthBloc>().add(const AuthGuestRequested());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthGuest) {
          context.go('/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        body: _webViewMode != _WebViewMode.none
            ? _buildWebView(context)
            : _buildLoginMenu(context, colorScheme),
      ),
    );
  }

  Widget _buildWebView(BuildContext context) {
    final isOAuth = _webViewMode == _WebViewMode.oauth;
    final controller = isOAuth ? _oauthController : _cookieController;
    final title = isOAuth ? '微博 OAuth 登录' : '微博账号登录';

    return SafeArea(
      child: Column(
        children: [
          AppBar(
            title: Text(title),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _webViewMode = _WebViewMode.none),
            ),
          ),
          Expanded(child: WebViewWidget(controller: controller)),
        ],
      ),
    );
  }

  Widget _buildLoginMenu(BuildContext context, ColorScheme colorScheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(Icons.flutter_dash, size: 100, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'MaterialWeibo',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '轻量级微博客户端',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),

            // Web Cookie 登录（推荐，不需要开发者 Key）
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _startCookieLogin,
                icon: const Icon(Icons.login),
                label: const Text('使用微博账号登录'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // OAuth 登录（需要开发者 Key）
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _startOAuthLogin,
                icon: const Icon(Icons.key),
                label: const Text('开发者 OAuth 登录'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 游客模式
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _enterGuestMode,
                child: Text(
                  '随便看看',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              '登录即表示同意微博用户协议',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
