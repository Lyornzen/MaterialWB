import 'package:get_it/get_it.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:material_weibo/core/network/dio_client.dart';
import 'package:material_weibo/core/network/network_info.dart';
import 'package:material_weibo/data/datasources/remote/weibo_official_api.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/data/datasources/local/preferences_helper.dart';
import 'package:material_weibo/data/datasources/local/weibo_local_db.dart';
import 'package:material_weibo/data/repositories/auth_repository_impl.dart';
import 'package:material_weibo/data/repositories/timeline_repository_impl.dart';
import 'package:material_weibo/data/repositories/user_repository_impl.dart';
import 'package:material_weibo/data/repositories/favorite_repository_impl.dart';
import 'package:material_weibo/data/repositories/history_repository_impl.dart';
import 'package:material_weibo/domain/repositories/auth_repository.dart';
import 'package:material_weibo/domain/repositories/timeline_repository.dart';
import 'package:material_weibo/domain/repositories/user_repository.dart';
import 'package:material_weibo/domain/repositories/favorite_repository.dart';
import 'package:material_weibo/domain/repositories/history_repository.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_bloc.dart';
import 'package:material_weibo/presentation/blocs/timeline/timeline_bloc.dart';
import 'package:material_weibo/presentation/blocs/favorite/favorite_cubit.dart';
import 'package:material_weibo/presentation/blocs/history/history_cubit.dart';
import 'package:material_weibo/presentation/blocs/search/search_bloc.dart';
import 'package:material_weibo/presentation/blocs/theme/theme_cubit.dart';
import 'package:material_weibo/presentation/blocs/locale/locale_cubit.dart';
import 'package:material_weibo/presentation/blocs/profile/profile_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── External ──
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);
  sl.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
  sl.registerSingleton<Connectivity>(Connectivity());

  // ── Core ──
  sl.registerSingleton<NetworkInfo>(NetworkInfoImpl(sl<Connectivity>()));
  sl.registerSingleton<DioClient>(DioClient());

  // ── Data Sources ──
  sl.registerSingleton<PreferencesHelper>(
    PreferencesHelper(prefs: sl<SharedPreferences>()),
  );
  sl.registerSingleton<WeiboLocalDb>(WeiboLocalDb());
  sl.registerSingleton<WeiboOfficialApi>(
    WeiboOfficialApi(dioClient: sl<DioClient>()),
  );
  sl.registerSingleton<WeiboWebApi>(WeiboWebApi(dioClient: sl<DioClient>()));

  // ── Repositories ──
  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      officialApi: sl<WeiboOfficialApi>(),
      webApi: sl<WeiboWebApi>(),
      dioClient: sl<DioClient>(),
      secureStorage: sl<FlutterSecureStorage>(),
      prefsHelper: sl<PreferencesHelper>(),
    ),
  );
  sl.registerSingleton<TimelineRepository>(
    TimelineRepositoryImpl(
      officialApi: sl<WeiboOfficialApi>(),
      webApi: sl<WeiboWebApi>(),
      localDb: sl<WeiboLocalDb>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerSingleton<UserRepository>(
    UserRepositoryImpl(
      officialApi: sl<WeiboOfficialApi>(),
      webApi: sl<WeiboWebApi>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
  sl.registerSingleton<FavoriteRepository>(
    FavoriteRepositoryImpl(
      officialApi: sl<WeiboOfficialApi>(),
      webApi: sl<WeiboWebApi>(),
      localDb: sl<WeiboLocalDb>(),
      networkInfo: sl<NetworkInfo>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
  sl.registerSingleton<HistoryRepository>(
    HistoryRepositoryImpl(localDb: sl<WeiboLocalDb>()),
  );

  // ── Blocs / Cubits ──
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<TimelineBloc>(
    () => TimelineBloc(timelineRepository: sl<TimelineRepository>()),
  );
  sl.registerFactory<FavoriteCubit>(
    () => FavoriteCubit(
      favoriteRepository: sl<FavoriteRepository>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
  sl.registerFactory<HistoryCubit>(
    () => HistoryCubit(historyRepository: sl<HistoryRepository>()),
  );
  sl.registerFactory<SearchBloc>(() => SearchBloc(webApi: sl<WeiboWebApi>()));
  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(userRepository: sl<UserRepository>()),
  );
  sl.registerSingleton<ThemeCubit>(
    ThemeCubit(prefsHelper: sl<PreferencesHelper>()),
  );
  sl.registerSingleton<LocaleCubit>(
    LocaleCubit(prefsHelper: sl<PreferencesHelper>()),
  );
}
