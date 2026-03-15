import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_weibo/data/datasources/local/preferences_helper.dart';

/// 主题设置状态
class ThemeSettings extends Equatable {
  final ThemeMode themeMode;

  /// 自定义主题色（null 表示使用默认微博红 / 系统动态色）
  final Color? seedColor;

  /// 字体缩放比例（0.8 ~ 1.4）
  final double fontScale;

  /// 语言设置: system / zh / en
  final String language;

  const ThemeSettings({
    this.themeMode = ThemeMode.system,
    this.seedColor,
    this.fontScale = 1.0,
    this.language = 'system',
  });

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    Color? seedColor,
    bool clearSeedColor = false,
    double? fontScale,
    String? language,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      seedColor: clearSeedColor ? null : (seedColor ?? this.seedColor),
      fontScale: fontScale ?? this.fontScale,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [themeMode, seedColor, fontScale, language];
}

class ThemeCubit extends Cubit<ThemeSettings> {
  final PreferencesHelper prefsHelper;

  ThemeCubit({required this.prefsHelper}) : super(const ThemeSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final modeStr = prefsHelper.getThemeMode();
    final themeMode = switch (modeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final colorValue = prefsHelper.getSeedColor();
    final seedColor = colorValue != null ? Color(colorValue) : null;

    final fontScale = prefsHelper.getFontScale();
    final language = prefsHelper.getLanguage();

    emit(
      ThemeSettings(
        themeMode: themeMode,
        seedColor: seedColor,
        fontScale: fontScale,
        language: language,
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final modeStr = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefsHelper.setThemeMode(modeStr);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setSeedColor(Color? color) async {
    await prefsHelper.setSeedColor(color?.toARGB32());
    if (color == null) {
      emit(state.copyWith(clearSeedColor: true));
    } else {
      emit(state.copyWith(seedColor: color));
    }
  }

  Future<void> setFontScale(double scale) async {
    await prefsHelper.setFontScale(scale);
    emit(state.copyWith(fontScale: scale));
  }

  Future<void> setLanguage(String language) async {
    await prefsHelper.setLanguage(language);
    emit(state.copyWith(language: language));
  }
}
