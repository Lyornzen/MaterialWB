import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'text_styles.dart';

/// Material Design 3 主题配置
class AppTheme {
  AppTheme._();

  /// 亮色主题
  static ThemeData light({ColorScheme? dynamicScheme, Color? seedColor}) {
    final ColorScheme colorScheme;
    if (seedColor != null) {
      // 用户自定义主题色 → 从 seed 自动生成完整配色
      colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      );
    } else {
      colorScheme = dynamicScheme ?? AppColorSchemes.lightScheme;
    }

    return _buildTheme(colorScheme);
  }

  /// 暗色主题
  static ThemeData dark({ColorScheme? dynamicScheme, Color? seedColor}) {
    final ColorScheme colorScheme;
    if (seedColor != null) {
      colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      );
    } else {
      colorScheme = dynamicScheme ?? AppColorSchemes.darkScheme;
    }

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTextStyles.textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        indicatorColor: colorScheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: colorScheme.surfaceContainerLowest,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      dividerTheme: DividerThemeData(
        thickness: 0.5,
        color: colorScheme.outlineVariant,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),
    );
  }
}
