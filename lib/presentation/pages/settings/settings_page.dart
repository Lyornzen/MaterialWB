import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_bloc.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_event.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_state.dart';
import 'package:material_weibo/presentation/blocs/theme/theme_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _SectionHeader(title: '外观'),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return RadioGroup<ThemeMode>(
                groupValue: themeMode,
                onChanged: (value) {
                  if (value != null) {
                    context.read<ThemeCubit>().setThemeMode(value);
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('跟随系统'),
                      value: ThemeMode.system,
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('浅色模式'),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('深色模式'),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: '关于'),
          ListTile(
            title: const Text('版本'),
            subtitle: const Text('1.0.0'),
            leading: const Icon(Icons.info_outline),
          ),
          const Divider(),
          // 根据认证状态显示不同按钮
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState.isGuest) {
                // 游客模式 → 显示「去登录」
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.login),
                    label: const Text('去登录'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                );
              }

              // 已登录（OAuth 或 Cookie）→ 显示登录方式 + 退出按钮
              final loginMethod = authState is AuthAuthenticated
                  ? authState.loginMethod
                  : 'oauth';
              final methodLabel = loginMethod == 'cookie'
                  ? 'Cookie 登录'
                  : 'OAuth 登录';

              return Column(
                children: [
                  ListTile(
                    title: const Text('登录方式'),
                    subtitle: Text(methodLabel),
                    leading: const Icon(Icons.account_circle_outlined),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: Icon(Icons.logout, color: colorScheme.error),
                      label: Text(
                        '退出登录',
                        style: TextStyle(color: colorScheme.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.error),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？退出后将返回登录页面。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              context.go('/login');
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
