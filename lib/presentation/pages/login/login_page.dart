import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_bloc.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_event.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _WebViewMode { none, cookie }

class _LoginPageState extends State<LoginPage> {
  _WebViewMode _webViewMode = _WebViewMode.none;
  bool _isProcessingLogin = false;
  late final WebViewController _cookieController;

  @override
  void initState() {
    super.initState();

    // 微博网页登录 WebView 控制器
    _cookieController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  static const _cookieChannel = MethodChannel('com.materialweibo/cookie');

  /// 通过原生 Android CookieManager 获取指定 URL 的所有 cookie（包括 HttpOnly）
  Future<String?> _getNativeCookie(String url) async {
    try {
      final result = await _cookieChannel.invokeMethod<String>('getCookie', {
        'url': url,
      });
      return result;
    } catch (_) {
      return null;
    }
  }

  /// 手动触发 Cookie 检测（用户按下按钮时调用）
  Future<void> _manualCheckCookie() async {
    if (_isProcessingLogin) return;

    // 尝试从多个微博域名读取 cookie（原生 API 可读 HttpOnly cookie）
    final urls = [
      'https://weibo.com',
      'https://m.weibo.cn',
      'https://weibo.cn',
      'https://passport.weibo.cn',
    ];

    String? combinedCookie;
    for (final url in urls) {
      final cookie = await _getNativeCookie(url);
      if (cookie != null && cookie.contains('SUB=')) {
        combinedCookie = cookie;
        break;
      }
    }

    if (combinedCookie != null && mounted) {
      setState(() {
        _isProcessingLogin = true;
        _webViewMode = _WebViewMode.none;
      });
      if (mounted) {
        context.read<AuthBloc>().add(
          AuthCookieLoginRequested(cookie: combinedCookie),
        );
      }
    } else if (mounted) {
      // 如果原生也读不到，fallback 尝试 JS 方式（非 HttpOnly cookie）
      try {
        final jsCookie = await _cookieController.runJavaScriptReturningResult(
          'document.cookie',
        );
        final jsStr = jsCookie.toString().replaceAll('"', '');
        if (jsStr.contains('SUB=') && mounted) {
          setState(() {
            _isProcessingLogin = true;
            _webViewMode = _WebViewMode.none;
          });
          if (mounted) {
            context.read<AuthBloc>().add(
              AuthCookieLoginRequested(cookie: jsStr),
            );
          }
          return;
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('未检测到登录状态，请先完成登录')));
      }
    }
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // 如果在 WebView 界面，返回到登录菜单
          if (_webViewMode != _WebViewMode.none) {
            setState(() => _webViewMode = _WebViewMode.none);
          } else {
            // 在登录菜单界面按返回，以游客模式进入主页
            context.read<AuthBloc>().add(const AuthGuestRequested());
          }
        }
      },
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated || state is AuthGuest) {
            context.go('/home');
          } else if (state is AuthError) {
            if (mounted) {
              setState(() => _isProcessingLogin = false);
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Scaffold(
          body: _isProcessingLogin
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在登录...'),
                    ],
                  ),
                )
              : _webViewMode != _WebViewMode.none
              ? _buildWebView(context)
              : _buildLoginMenu(context, colorScheme),
        ),
      ),
    );
  }

  Widget _buildWebView(BuildContext context) {
    final controller = _cookieController;
    final title = '微博账号登录';
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          AppBar(
            title: Text(title),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _webViewMode = _WebViewMode.none),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.icon(
                  onPressed: _manualCheckCookie,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('登录完成'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
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

            // 通过微博网页登录同步 Cookie 会话
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
              '使用网页端登录态同步信息，避免依赖无效配置项',
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
