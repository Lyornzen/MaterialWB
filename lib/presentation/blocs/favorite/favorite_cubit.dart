import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_weibo/core/di/injection.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
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

  /// 记录被点赞的帖子 ID 集合（用于 UI 乐观更新）
  final Set<String> likedPostIds;

  /// 记录被取消点赞的帖子 ID 集合
  final Set<String> unlikedPostIds;
  const FavoriteLoaded({
    required this.favorites,
    this.likedPostIds = const {},
    this.unlikedPostIds = const {},
  });
  @override
  List<Object?> get props => [favorites, likedPostIds, unlikedPostIds];

  FavoriteLoaded copyWith({
    List<Favorite>? favorites,
    Set<String>? likedPostIds,
    Set<String>? unlikedPostIds,
  }) {
    return FavoriteLoaded(
      favorites: favorites ?? this.favorites,
      likedPostIds: likedPostIds ?? this.likedPostIds,
      unlikedPostIds: unlikedPostIds ?? this.unlikedPostIds,
    );
  }
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
    // 检查登录方式 — 收藏功能在 OAuth 和 Cookie 登录下均可用
    final method = authRepository.getLoginMethod();
    if (method == null) {
      emit(const FavoriteUnavailable(message: '请先登录'));
      return;
    }

    emit(const FavoriteLoading());
    try {
      final token = await authRepository.getSavedToken();
      if (token == null && method == 'oauth') {
        emit(const FavoriteError(message: '请先登录'));
        return;
      }
      final favorites = await favoriteRepository.getFavorites(
        token: token ?? 'cookie_session',
        page: page,
      );
      emit(FavoriteLoaded(favorites: favorites));
    } catch (e) {
      emit(FavoriteError(message: e.toString()));
    }
  }

  /// 切换收藏状态（根据登录方式自动选择 API）
  Future<void> toggleFavorite(String postId, bool currentlyFavorited) async {
    final method = authRepository.getLoginMethod();
    if (method == null) {
      emit(const FavoriteUnavailable(message: '请先登录'));
      return;
    }

    try {
      final token = await authRepository.getSavedToken();
      if (token == null && method == 'oauth') return;
      if (currentlyFavorited) {
        await favoriteRepository.removeFavorite(
          token: token ?? 'cookie_session',
          postId: postId,
        );
      } else {
        await favoriteRepository.addFavorite(
          token: token ?? 'cookie_session',
          postId: postId,
        );
      }
      await loadFavorites();
    } catch (e) {
      emit(FavoriteError(message: e.toString()));
    }
  }

  /// 切换点赞状态（网页 API attitude）
  Future<void> toggleLike(String postId, bool currentlyLiked) async {
    // 乐观更新 UI
    final currentState = state;
    Set<String> liked = {};
    Set<String> unliked = {};
    List<Favorite> favorites = [];
    if (currentState is FavoriteLoaded) {
      liked = Set.from(currentState.likedPostIds);
      unliked = Set.from(currentState.unlikedPostIds);
      favorites = currentState.favorites;
    }

    if (currentlyLiked) {
      liked.remove(postId);
      unliked.add(postId);
    } else {
      unliked.remove(postId);
      liked.add(postId);
    }
    emit(
      FavoriteLoaded(
        favorites: favorites,
        likedPostIds: liked,
        unlikedPostIds: unliked,
      ),
    );

    // 发送 API 请求
    try {
      final webApi = sl<WeiboWebApi>();
      if (currentlyLiked) {
        await webApi.destroyAttitude(postId);
      } else {
        await webApi.createAttitude(postId);
      }
    } catch (e) {
      // 回滚乐观更新
      if (currentlyLiked) {
        unliked.remove(postId);
        liked.add(postId);
      } else {
        liked.remove(postId);
        unliked.add(postId);
      }
      emit(
        FavoriteLoaded(
          favorites: favorites,
          likedPostIds: liked,
          unlikedPostIds: unliked,
        ),
      );
      debugPrint('Like toggle failed: $e');
    }
  }

  /// 检查帖子是否被点赞（考虑乐观更新）
  bool isLiked(String postId, bool originalFavorited) {
    final currentState = state;
    if (currentState is FavoriteLoaded) {
      if (currentState.likedPostIds.contains(postId)) return true;
      if (currentState.unlikedPostIds.contains(postId)) return false;
    }
    return originalFavorited;
  }
}
