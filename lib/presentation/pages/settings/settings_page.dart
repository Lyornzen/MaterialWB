import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_weibo/core/l10n/app_localizations.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_bloc.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_event.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_state.dart';
import 'package:material_weibo/presentation/blocs/locale/locale_cubit.dart';
import 'package:material_weibo/presentation/blocs/theme/theme_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  /// 预设主题色列表
  static const List<_PresetColor> _presetColors = [
    _PresetColor(nameKey: 'color_weibo_red', color: Color(0xFFE6162D)),
    _PresetColor(nameKey: 'color_sky_blue', color: Color(0xFF2196F3)),
    _PresetColor(nameKey: 'color_emerald', color: Color(0xFF4CAF50)),
    _PresetColor(nameKey: 'color_deep_purple', color: Color(0xFF673AB7)),
    _PresetColor(nameKey: 'color_orange', color: Color(0xFFFF9800)),
    _PresetColor(nameKey: 'color_teal', color: Color(0xFF009688)),
    _PresetColor(nameKey: 'color_pink', color: Color(0xFFE91E63)),
    _PresetColor(nameKey: 'color_indigo', color: Color(0xFF3F51B5)),
    _PresetColor(nameKey: 'color_brown', color: Color(0xFF795548)),
    _PresetColor(nameKey: 'color_blue_grey', color: Color(0xFF607D8B)),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(S.get('settings'))),
      body: BlocBuilder<ThemeCubit, ThemeSettings>(
        builder: (context, settings) {
          return ListView(
            children: [
              // ── 用户信息 ──
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  if (authState is AuthAuthenticated &&
                      authState.user != null) {
                    final user = authState.user!;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: colorScheme.primaryContainer,
                                backgroundImage: user.profileImageUrl.isNotEmpty
                                    ? NetworkImage(user.profileImageUrl)
                                    : null,
                                child: user.profileImageUrl.isEmpty
                                    ? Icon(
                                        Icons.person,
                                        size: 28,
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
                                            user.screenName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (user.verified == true)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 4,
                                            ),
                                            child: Icon(
                                              Icons.verified,
                                              size: 16,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (user.description != null &&
                                        user.description!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          user.description!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // ── 外观模式 ──
              _SectionHeader(title: S.get('appearance')),
              RadioGroup<ThemeMode>(
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    context.read<ThemeCubit>().setThemeMode(value);
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text(S.get('follow_system')),
                      value: ThemeMode.system,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(S.get('light_mode')),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(S.get('dark_mode')),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),

              const Divider(),

              // ── 主题色 ──
              _SectionHeader(title: S.get('theme_color')),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 跟随系统选项
                    _ColorOption(
                      label: S.get('system_default'),
                      color: null,
                      isSelected: settings.seedColor == null,
                      onTap: () {
                        context.read<ThemeCubit>().setSeedColor(null);
                      },
                    ),
                    const SizedBox(height: 12),
                    // 预设颜色网格
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _presetColors.map((preset) {
                        final isSelected =
                            settings.seedColor != null &&
                            settings.seedColor!.toARGB32() ==
                                preset.color.toARGB32();
                        return _ColorCircle(
                          color: preset.color,
                          label: S.get(preset.nameKey),
                          isSelected: isSelected,
                          onTap: () {
                            context.read<ThemeCubit>().setSeedColor(
                              preset.color,
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // 自定义颜色按钮
                    OutlinedButton.icon(
                      onPressed: () => _showCustomColorPicker(context),
                      icon: const Icon(Icons.palette_outlined, size: 18),
                      label: Text(S.get('custom_color')),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // ── 字体大小 ──
              _SectionHeader(title: S.get('font_size')),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('A', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Slider(
                            value: settings.fontScale,
                            min: 0.8,
                            max: 1.4,
                            divisions: 6,
                            label: '${(settings.fontScale * 100).round()}%',
                            onChanged: (value) {
                              context.read<ThemeCubit>().setFontScale(value);
                            },
                          ),
                        ),
                        const Text('A', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                    Text(
                      '${S.get('preview_text')} - ${(settings.fontScale * 100).round()}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const Divider(),

              // ── 语言 ──
              _SectionHeader(title: S.get('language')),
              BlocBuilder<LocaleCubit, AppLocale>(
                builder: (context, currentLocale) {
                  return RadioGroup<AppLocale>(
                    groupValue: currentLocale,
                    onChanged: (value) {
                      if (value != null) {
                        context.read<LocaleCubit>().setLocale(value);
                      }
                    },
                    child: Column(
                      children: AppLocale.values.map((locale) {
                        return RadioListTile<AppLocale>(
                          title: Text(locale.displayName),
                          value: locale,
                        );
                      }).toList(),
                    ),
                  );
                },
              ),

              const Divider(),

              // ── 关于 ──
              _SectionHeader(title: S.get('about')),
              ListTile(
                title: Text(S.get('version')),
                subtitle: const Text('1.0.0'),
                leading: const Icon(Icons.info_outline),
              ),
              const Divider(),

              // ── 登录/退出 ──
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  if (authState.isGuest) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.login),
                        label: Text(S.get('login')),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    );
                  }

                  final loginMethod = authState is AuthAuthenticated
                      ? authState.loginMethod
                      : 'oauth';
                  final methodLabel = loginMethod == 'cookie'
                      ? S.get('cookie_login')
                      : S.get('oauth_login');

                  return Column(
                    children: [
                      ListTile(
                        title: Text(S.get('login_method')),
                        subtitle: Text(methodLabel),
                        leading: const Icon(Icons.account_circle_outlined),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: OutlinedButton.icon(
                          onPressed: () => _showLogoutDialog(context),
                          icon: Icon(Icons.logout, color: colorScheme.error),
                          label: Text(
                            S.get('logout'),
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
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.get('logout')),
        content: Text(S.get('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.get('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              context.go('/login');
            },
            child: Text(S.get('confirm')),
          ),
        ],
      ),
    );
  }

  void _showCustomColorPicker(BuildContext context) {
    final cubit = context.read<ThemeCubit>();
    double hue = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final color = HSVColor.fromAHSV(1, hue, 0.8, 0.9).toColor();
          return AlertDialog(
            title: Text(S.get('pick_custom_color')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 颜色预览
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 色相滑块
                Row(
                  children: [
                    Text(S.get('hue')),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 12,
                          activeTrackColor: color,
                          inactiveTrackColor: Theme.of(
                            ctx,
                          ).colorScheme.surfaceContainerHighest,
                          thumbColor: color,
                        ),
                        child: Slider(
                          value: hue,
                          min: 0,
                          max: 360,
                          onChanged: (v) => setState(() => hue = v),
                        ),
                      ),
                    ),
                  ],
                ),
                // 色相渐变条预览
                Container(
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: List.generate(
                        37,
                        (i) =>
                            HSVColor.fromAHSV(1, i * 10.0, 0.8, 0.9).toColor(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(S.get('cancel')),
              ),
              FilledButton(
                onPressed: () {
                  cubit.setSeedColor(color);
                  Navigator.pop(ctx);
                },
                child: Text(S.get('confirm')),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 颜色选项（带标签 - 用于"跟随系统"选项）
class _ColorOption extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: color == null
                    ? const LinearGradient(
                        colors: [
                          Colors.red,
                          Colors.orange,
                          Colors.green,
                          Colors.blue,
                          Colors.purple,
                        ],
                      )
                    : null,
                color: color,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 圆形颜色选择器
class _ColorCircle extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 3,
                  )
                : Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : null,
        ),
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

class _PresetColor {
  final String nameKey;
  final Color color;
  const _PresetColor({required this.nameKey, required this.color});
}
