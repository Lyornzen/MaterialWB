import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_bloc.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_event.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_state.dart';
import 'package:material_weibo/presentation/blocs/theme/theme_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  /// 预设主题色列表
  static const List<_PresetColor> _presetColors = [
    _PresetColor(name: '微博红', color: Color(0xFFE6162D)),
    _PresetColor(name: '天空蓝', color: Color(0xFF2196F3)),
    _PresetColor(name: '翠绿', color: Color(0xFF4CAF50)),
    _PresetColor(name: '深紫', color: Color(0xFF673AB7)),
    _PresetColor(name: '橙色', color: Color(0xFFFF9800)),
    _PresetColor(name: '青色', color: Color(0xFF009688)),
    _PresetColor(name: '粉色', color: Color(0xFFE91E63)),
    _PresetColor(name: '靛蓝', color: Color(0xFF3F51B5)),
    _PresetColor(name: '棕色', color: Color(0xFF795548)),
    _PresetColor(name: '蓝灰', color: Color(0xFF607D8B)),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: BlocBuilder<ThemeCubit, ThemeSettings>(
        builder: (context, settings) {
          return ListView(
            children: [
              // ── 外观模式 ──
              const _SectionHeader(title: '外观'),
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
              ),

              const Divider(),

              // ── 主题色 ──
              const _SectionHeader(title: '主题色'),
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
                      label: '跟随系统 / 默认',
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
                          label: preset.name,
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
                      label: const Text('自定义颜色'),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // ── 字体大小 ──
              const _SectionHeader(title: '字体大小'),
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
                      '预览文字 - ${(settings.fontScale * 100).round()}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const Divider(),

              // ── 关于 ──
              const _SectionHeader(title: '关于'),
              ListTile(
                title: const Text('版本'),
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
                        label: const Text('去登录'),
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
          );
        },
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

  void _showCustomColorPicker(BuildContext context) {
    final cubit = context.read<ThemeCubit>();
    double hue = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final color = HSVColor.fromAHSV(1, hue, 0.8, 0.9).toColor();
          return AlertDialog(
            title: const Text('选择自定义颜色'),
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
                    const Text('色相'),
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
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  cubit.setSeedColor(color);
                  Navigator.pop(ctx);
                },
                child: const Text('确定'),
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
  final String name;
  final Color color;
  const _PresetColor({required this.name, required this.color});
}
