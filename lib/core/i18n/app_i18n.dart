import 'package:flutter/material.dart';

class AppI18n {
  final Locale locale;

  const AppI18n(this.locale);

  bool get isZh => locale.languageCode.toLowerCase().startsWith('zh');

  static AppI18n of(BuildContext context) =>
      AppI18n(Localizations.localeOf(context));

  String tr(String zh, String en) => isZh ? zh : en;
}

extension AppI18nX on BuildContext {
  AppI18n get i18n => AppI18n.of(this);
}
