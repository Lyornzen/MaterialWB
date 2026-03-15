import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_weibo/core/constants/login_method.dart';
import 'package:material_weibo/core/di/injection.dart';
import 'package:material_weibo/core/i18n/app_i18n.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/data/models/user_model.dart';
import 'package:material_weibo/domain/entities/user.dart';
import 'package:material_weibo/domain/repositories/auth_repository.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_bloc.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_state.dart';
import 'package:material_weibo/presentation/pages/timeline/timeline_page.dart';
import 'package:material_weibo/presentation/pages/search/search_page.dart';
import 'package:material_weibo/presentation/pages/favorites/favorites_page.dart';
import 'package:material_weibo/presentation/widgets/empty_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _timelinePageKey = GlobalKey<TimelinePageState>();
  DateTime? _lastHomeTapTime;

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
        title: Text(context.i18n.tr('退出应用', 'Exit App')),
        content: Text(
          context.i18n.tr(
            '确定要退出 Material 微博吗？',
            'Are you sure you want to exit Material Weibo?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.i18n.tr('取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.i18n.tr('退出', 'Exit')),
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
    final i18n = context.i18n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop();
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isLoggedIn = authState.isLoggedIn;

          final pages = <Widget>[
            TimelinePage(key: _timelinePageKey),
            const SearchPage(),
            isLoggedIn
                ? const FavoritesPage()
                : const _LoginRequiredPage(),
            const _MePage(),
          ];

          return Scaffold(
            body: IndexedStack(index: _currentIndex, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                if (index == 0 && _currentIndex == 0) {
                  final now = DateTime.now();
                  final isDoubleTap =
                      _lastHomeTapTime != null &&
                      now.difference(_lastHomeTapTime!).inMilliseconds < 350;
                  _lastHomeTapTime = now;
                  if (isDoubleTap) {
                    _timelinePageKey.currentState?.scrollToTopAndRefresh();
                    return;
                  }
                }
                setState(() => _currentIndex = index);
              },
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: i18n.tr('首页', 'Home'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.search),
                  selectedIcon: Icon(Icons.search),
                  label: i18n.tr('发现', 'Discover'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.star_outline),
                  selectedIcon: Icon(Icons.star),
                  label: i18n.tr('收藏', 'Favorites'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: i18n.tr('我的', 'Me'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 需要登录才能使用的功能占位页
class _LoginRequiredPage extends StatelessWidget {
  const _LoginRequiredPage();

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      appBar: AppBar(title: Text(i18n.tr('需要登录', 'Sign In Required'))),
      body: AppEmptyState(
        icon: Icons.lock_outline,
        title: i18n.tr('登录后即可使用此功能', 'Sign in to use this feature'),
        subtitle: i18n.tr(
          '完成登录后即可同步更多个人数据',
          'Sign in to sync more personal data',
        ),
        actionLabel: i18n.tr('去登录', 'Sign In'),
        actionIcon: Icons.login,
        onAction: () => context.go('/login'),
      ),
    );
  }
}

/// 「我的」页面
class _MePage extends StatefulWidget {
  const _MePage();

  @override
  State<_MePage> createState() => _MePageState();
}

class _MePageState extends State<_MePage> {
  Future<WeiboUser?>? _fallbackUserFuture;

  Future<WeiboUser?> _resolveCurrentUser() async {
    final authRepo = sl<AuthRepository>();
    final method = authRepo.getLoginMethod();
    try {
      if (LoginMethod.usesCookie(method)) {
        final data = await sl<WeiboWebApi>().getLoggedInUserInfo();
        return UserModel.fromJson(data);
      }
      final token = await authRepo.getSavedToken();
      if (token != null && token.isNotEmpty) {
        return authRepo.getCurrentUser(token);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.i18n.tr('我的', 'Me')),
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
          final authUser = state is AuthAuthenticated ? state.user : null;
          if (!isLoggedIn || authUser != null) {
            _fallbackUserFuture = null;
          }
          if (isLoggedIn && authUser == null && _fallbackUserFuture == null) {
            _fallbackUserFuture = _resolveCurrentUser();
          }

          return ListView(
            children: [
              const SizedBox(height: 16),
              // 用户信息卡片或登录提示
              if (!isLoggedIn)
                _buildGuestCard(context, colorScheme)
              else if (authUser != null)
                _buildUserCard(context, colorScheme, authUser)
              else
                FutureBuilder<WeiboUser?>(
                  future: _fallbackUserFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return _buildUserLoadingCard(context, colorScheme);
                    }
                    final user = snapshot.data;
                    if (user == null) {
                      return _buildUserUnavailableCard(context, colorScheme);
                    }
                    return _buildUserCard(context, colorScheme, user);
                  },
                ),
              const SizedBox(height: 16),
              if (isLoggedIn) ...[
                _buildMenuItem(
                  context,
                  icon: Icons.history,
                  title: context.i18n.tr('浏览历史', 'History'),
                  onTap: () => context.push('/history'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.star_outline,
                  title: context.i18n.tr('我的收藏', 'My Favorites'),
                  onTap: () => context.push('/favorites'),
                ),
              ],
              // 浏览历史对游客也开放（本地数据）
              if (!isLoggedIn)
                _buildMenuItem(
                  context,
                  icon: Icons.history,
                  title: context.i18n.tr('浏览历史', 'History'),
                  onTap: () => context.push('/history'),
                ),
              _buildMenuItem(
                context,
                icon: Icons.settings_outlined,
                title: context.i18n.tr('设置', 'Settings'),
                onTap: () => context.push('/settings'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context, ColorScheme colorScheme) {
    final i18n = context.i18n;
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
              i18n.tr('未登录', 'Not signed in'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              i18n.tr(
                '登录后可查看收藏、个人资料等',
                'Sign in to view favorites and personal profile details',
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: Text(i18n.tr('去登录', 'Sign In')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserLoadingCard(BuildContext context, ColorScheme colorScheme) {
    final i18n = context.i18n;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i18n.tr('正在同步账号信息', 'Syncing account details'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    i18n.tr(
                      '这通常只需要几秒钟',
                      'This usually takes just a few seconds',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserUnavailableCard(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final i18n = context.i18n;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: colorScheme.errorContainer,
              child: Icon(
                Icons.person_off_outlined,
                size: 30,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              i18n.tr('暂时无法获取账号信息', 'Unable to load account details'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              i18n.tr(
                '请稍后重试，或重新登录以刷新会话',
                'Please try again later or sign in again to refresh the session',
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _fallbackUserFuture = _resolveCurrentUser();
                });
              },
              icon: const Icon(Icons.refresh),
              label: Text(i18n.tr('重试', 'Retry')),
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
    final i18n = context.i18n;
    final screenName = user?.screenName ?? i18n.tr('微博用户', 'Weibo User');
    final description =
        user?.description ?? i18n.tr('点击查看个人资料', 'Tap to view profile');
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
                      label: i18n.tr('微博', 'Posts'),
                      count: user.statusesCount,
                    ),
                    _buildStatItem(
                      context,
                      label: i18n.tr('关注', 'Following'),
                      count: user.friendsCount,
                    ),
                    _buildStatItem(
                      context,
                      label: i18n.tr('粉丝', 'Followers'),
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
