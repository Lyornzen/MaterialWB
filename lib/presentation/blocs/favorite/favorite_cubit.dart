import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_weibo/domain/entities/favorite.dart';
import 'package:material_weibo/domain/repositories/auth_repository.dart';
import 'package:material_weibo/domain/repositories/favorite_repository.dart';

// State
abstract class FavoriteState extends Equatable {
  const FavoriteState();
  @override
  List<Object?> get props => [];
}

class FavoriteInitial extends FavoriteState {
  const FavoriteInitial();
}

class FavoriteLoading extends FavoriteState {
  const FavoriteLoading();
}

class FavoriteLoaded extends FavoriteState {
  final List<Favorite> favorites;
  const FavoriteLoaded({required this.favorites});
  @override
  List<Object?> get props => [favorites];
}

class FavoriteError extends FavoriteState {
  final String message;
  const FavoriteError({required this.message});
  @override
  List<Object?> get props => [message];
}

/// 收藏功能不可用（Cookie 登录或游客模式不支持）
class FavoriteUnavailable extends FavoriteState {
  final String message;
  const FavoriteUnavailable({required this.message});
  @override
  List<Object?> get props => [message];
}

// Cubit
class FavoriteCubit extends Cubit<FavoriteState> {
  final FavoriteRepository favoriteRepository;
  final AuthRepository authRepository;

  FavoriteCubit({
    required this.favoriteRepository,
    required this.authRepository,
  }) : super(const FavoriteInitial());

  Future<void> loadFavorites({int page = 1}) async {
    // 检查登录方式 — 收藏功能仅在 OAuth 登录下可用
    final method = authRepository.getLoginMethod();
    if (method == null) {
      emit(const FavoriteUnavailable(message: '请先登录'));
      return;
    }
    if (method != 'oauth') {
      emit(
        const FavoriteUnavailable(message: '收藏功能需要 OAuth 登录，当前为 Cookie 登录模式'),
      );
      return;
    }

    emit(const FavoriteLoading());
    try {
      final token = await authRepository.getSavedToken();
      if (token == null) {
        emit(const FavoriteError(message: '请先登录'));
        return;
      }
      final favorites = await favoriteRepository.getFavorites(
        token: token,
        page: page,
      );
      emit(FavoriteLoaded(favorites: favorites));
    } catch (e) {
      emit(FavoriteError(message: e.toString()));
    }
  }

  Future<void> toggleFavorite(String postId, bool currentlyFavorited) async {
    final method = authRepository.getLoginMethod();
    if (method != 'oauth') {
      emit(const FavoriteUnavailable(message: '收藏功能需要 OAuth 登录'));
      return;
    }

    try {
      final token = await authRepository.getSavedToken();
      if (token == null) return;
      if (currentlyFavorited) {
        await favoriteRepository.removeFavorite(token: token, postId: postId);
      } else {
        await favoriteRepository.addFavorite(token: token, postId: postId);
      }
      await loadFavorites();
    } catch (e) {
      emit(FavoriteError(message: e.toString()));
    }
  }
}
