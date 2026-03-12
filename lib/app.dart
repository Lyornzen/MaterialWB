import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/blocs/timeline/timeline_bloc.dart';
import 'presentation/blocs/favorite/favorite_cubit.dart';
import 'presentation/blocs/history/history_cubit.dart';
import 'presentation/blocs/search/search_bloc.dart';

class MaterialWeiboApp extends StatelessWidget {
  const MaterialWeiboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(const AuthCheckStatus()),
        ),
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
        BlocProvider<TimelineBloc>(create: (_) => sl<TimelineBloc>()),
        BlocProvider<FavoriteCubit>(create: (_) => sl<FavoriteCubit>()),
        BlocProvider<HistoryCubit>(create: (_) => sl<HistoryCubit>()),
        BlocProvider<SearchBloc>(create: (_) => sl<SearchBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              return MaterialApp.router(
                title: 'Material 微博',
                debugShowCheckedModeBanner: false,
                themeMode: themeMode,
                theme: AppTheme.light(dynamicScheme: lightDynamic),
                darkTheme: AppTheme.dark(dynamicScheme: darkDynamic),
                routerConfig: AppRouter.router,
              );
            },
          );
        },
      ),
    );
  }
}
