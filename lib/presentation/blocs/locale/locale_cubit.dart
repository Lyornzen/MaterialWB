import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_weibo/core/l10n/app_localizations.dart';
import 'package:material_weibo/data/datasources/local/preferences_helper.dart';

class LocaleCubit extends Cubit<AppLocale> {
  final PreferencesHelper prefsHelper;

  LocaleCubit({required this.prefsHelper}) : super(AppLocale.zhCN) {
    _loadLocale();
  }

  void _loadLocale() {
    final code = prefsHelper.getLocale();
    final locale = AppLocale.fromCode(code);
    S.currentLocale = locale;
    emit(locale);
  }

  Future<void> setLocale(AppLocale locale) async {
    await prefsHelper.setLocale(locale.code);
    S.currentLocale = locale;
    emit(locale);
  }
}
