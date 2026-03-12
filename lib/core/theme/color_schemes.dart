import 'package:flutter/material.dart';

/// Material Design 3 配色方案
class AppColorSchemes {
  AppColorSchemes._();

  /// 微博红作为 seed color
  static const Color seedColor = Color(0xFFE6162D);

  /// 亮色方案
  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  );

  /// 暗色方案
  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  );
}
