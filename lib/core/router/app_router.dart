import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_state.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_bloc.dart';
import 'package:material_weibo/presentation/pages/splash/splash_page.dart';
import 'package:material_weibo/presentation/pages/login/login_page.dart';
import 'package:material_weibo/presentation/pages/home/home_page.dart';
import 'package:material_weibo/presentation/pages/post_detail/post_detail_page.dart';
import 'package:material_weibo/presentation/pages/profile/profile_page.dart';
import 'package:material_weibo/presentation/pages/favorites/favorites_page.dart';
import 'package:material_weibo/presentation/pages/history/history_page.dart';
import 'package:material_weibo/presentation/pages/search/search_page.dart';
import 'package:material_weibo/presentation/pages/settings/settings_page.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// 不需要任何认证即可访问的路由
  static const _publicPaths = {'/splash', '/login'};

  /// 游客可以访问的路由（无需登录）
  static const _guestAllowedPaths = {
    '/home',
    '/search',
    '/settings',
    '/post', // 前缀匹配
    '/profile', // 前缀匹配
  };

  /// 需要已登录（OAuth / Cookie）才能访问的路由
  static const _authRequiredPaths = {'/favorites', '/history'};

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: _guard,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/post/:id',
        name: 'postDetail',
        builder: (context, state) =>
            PostDetailPage(postId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile/:uid',
        name: 'profile',
        builder: (context, state) =>
            ProfilePage(userId: state.pathParameters['uid']!),
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) => const FavoritesPage(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return SearchPage(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );

  static String? _guard(BuildContext context, GoRouterState state) {
    final path = state.matchedLocation;

    // 公开路由，直接放行
    if (_publicPaths.contains(path)) return null;

    // 尝试读取 AuthBloc 状态；若 Bloc 尚未就绪（splash 阶段）则放行
    final AuthState authState;
    try {
      authState = context.read<AuthBloc>().state;
    } catch (_) {
      // BlocProvider 尚未挂载（不应发生，但做防御处理）
      return null;
    }

    // 仍在初始化中，让 splash 处理导航
    if (authState is AuthInitial || authState is AuthLoading) return null;

    final isLoggedIn = authState.isLoggedIn;
    final isGuest = authState.isGuest;
    final isUnauthenticated =
        authState is AuthUnauthenticated || authState is AuthError;

    // 完全未认证（既非游客也非已登录）→ 只能去登录页
    if (isUnauthenticated) {
      return '/login';
    }

    // 游客模式访问需要登录的页面 → 重定向到登录页
    if (isGuest && _isAuthRequired(path)) {
      return '/login';
    }

    // 已登录用户尝试访问登录页 → 重定向到首页
    if (isLoggedIn && path == '/login') {
      return '/home';
    }

    return null;
  }

  /// 检查路径是否需要已登录用户权限
  static bool _isAuthRequired(String path) {
    // 精确匹配
    if (_authRequiredPaths.contains(path)) return true;
    // 不在游客可访问列表中的非公开路由也需要登录
    // 对带参数的路径做前缀匹配
    for (final allowed in _guestAllowedPaths) {
      if (path == allowed || path.startsWith('$allowed/')) return false;
    }
    // 既不公开也不在游客白名单 → 需要登录
    return true;
  }
}
