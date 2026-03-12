import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_weibo/data/datasources/local/preferences_helper.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final PreferencesHelper prefsHelper;

  ThemeCubit({required this.prefsHelper}) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final mode = prefsHelper.getThemeMode();
    switch (mode) {
      case 'light':
        emit(ThemeMode.light);
      case 'dark':
        emit(ThemeMode.dark);
      default:
        emit(ThemeMode.system);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final modeStr = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefsHelper.setThemeMode(modeStr);
    emit(mode);
  }
}
