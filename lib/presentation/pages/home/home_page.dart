import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_weibo/core/l10n/app_localizations.dart';
import 'package:material_weibo/domain/entities/user.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_bloc.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_state.dart';
import 'package:material_weibo/presentation/blocs/locale/locale_cubit.dart';
import 'package:material_weibo/presentation/pages/timeline/timeline_page.dart';
import 'package:material_weibo/presentation/pages/search/search_page.dart';
import 'package:material_weibo/presentation/pages/favorites/favorites_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _timelineKey = GlobalKey<TimelinePageState>();

  /// 上次点击首页 tab 的时间，用于检测双击
  DateTime? _lastHomeTabTap;

  /// 处理 Android 返回手势：
  /// - 如果不在首页 tab → 切回首页 tab
  /// - 如果在首页 tab → 弹出确认对话框
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.get('exit_app')),
        content: Text(S.get('exit_app_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.get('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.get('exit')),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop();
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isLoggedIn = authState.isLoggedIn;

          final pages = <Widget>[
            TimelinePage(key: _timelineKey),
            const SearchPage(),
            isLoggedIn
                ? const FavoritesPage()
                : _LoginRequiredPage(feature: S.get('nav_favorites')),
            const _MePage(),
          ];

          return BlocBuilder<LocaleCubit, AppLocale>(
            builder: (context, _) {
              return Scaffold(
                body: IndexedStack(index: _currentIndex, children: pages),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    if (index == 0 && _currentIndex == 0) {
                      // 已在首页 tab，检测双击
                      final now = DateTime.now();
                      if (_lastHomeTabTap != null &&
                          now.difference(_lastHomeTabTap!) <
                              const Duration(milliseconds: 500)) {
                        // 双击：滚动到顶部并刷新
                        _timelineKey.currentState?.scrollToTopAndRefresh();
                        _lastHomeTabTap = null;
                        return;
                      }
                      _lastHomeTabTap = now;
                      return;
                    }
                    _lastHomeTabTap = null;
                    setState(() => _currentIndex = index);
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      label: S.get('nav_home'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.search),
                      selectedIcon: const Icon(Icons.search),
                      label: S.get('nav_discover'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.star_outline),
                      selectedIcon: const Icon(Icons.star),
                      label: S.get('nav_favorites'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline),
                      selectedIcon: const Icon(Icons.person),
                      label: S.get('nav_me'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 需要登录才能使用的功能占位页
class _LoginRequiredPage extends StatelessWidget {
  final String feature;
  const _LoginRequiredPage({required this.feature});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(feature)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                S
                    .get('login_required_feature')
                    .replaceAll('{feature}', feature),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login),
                label: Text(S.get('login')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 「我的」页面
class _MePage extends StatelessWidget {
  const _MePage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.get('nav_me')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoggedIn = state.isLoggedIn;
          final user = state is AuthAuthenticated ? state.user : null;

          return ListView(
            children: [
              const SizedBox(height: 16),
              // 用户信息卡片或登录提示
              isLoggedIn
                  ? _buildUserCard(context, colorScheme, user)
                  : _buildGuestCard(context, colorScheme),
              const SizedBox(height: 16),
              if (isLoggedIn) ...[
                _buildMenuItem(
                  context,
                  icon: Icons.history,
                  title: S.get('browse_history'),
                  onTap: () => context.push('/history'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.star_outline,
                  title: S.get('my_favorites'),
                  onTap: () => context.push('/favorites'),
                ),
              ],
              // 浏览历史对游客也开放（本地数据）
              if (!isLoggedIn)
                _buildMenuItem(
                  context,
                  icon: Icons.history,
                  title: S.get('browse_history'),
                  onTap: () => context.push('/history'),
                ),
              _buildMenuItem(
                context,
                icon: Icons.settings_outlined,
                title: S.get('settings'),
                onTap: () => context.push('/settings'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.person_outline,
                size: 32,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              S.get('not_logged_in'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              S.get('login_hint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: Text(S.get('login')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    ColorScheme colorScheme,
    WeiboUser? user,
  ) {
    final screenName = user?.screenName ?? '微博用户';
    final description = user?.description ?? '点击查看个人资料';
    final avatarUrl = user?.profileImageUrl;
    final userId = user?.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: userId != null ? () => context.push('/profile/$userId') : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 32,
                            color: colorScheme.onPrimaryContainer,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                screenName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user?.verified == true)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              if (user != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      context,
                      label: S.get('posts_count'),
                      count: user.statusesCount,
                    ),
                    _buildStatItem(
                      context,
                      label: S.get('following_count'),
                      count: user.friendsCount,
                    ),
                    _buildStatItem(
                      context,
                      label: S.get('followers_count'),
                      count: user.followersCount,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required int count,
  }) {
    String formatted;
    if (count >= 10000) {
      formatted = '${(count / 10000).toStringAsFixed(1)}万';
    } else {
      formatted = count.toString();
    }
    return Column(
      children: [
        Text(
          formatted,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
