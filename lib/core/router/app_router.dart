import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );

  static String? _guard(BuildContext context, GoRouterState state) {
    // 路由守卫将在 AuthBloc 初始化后生效
    return null;
  }
}
