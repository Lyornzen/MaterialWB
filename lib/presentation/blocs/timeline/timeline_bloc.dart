import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_weibo/core/di/injection.dart';
import 'package:material_weibo/domain/repositories/auth_repository.dart';
import 'package:material_weibo/domain/repositories/timeline_repository.dart';
import 'timeline_event.dart';
import 'timeline_state.dart';

class TimelineBloc extends Bloc<TimelineEvent, TimelineState> {
  final TimelineRepository timelineRepository;

  TimelineBloc({required this.timelineRepository})
    : super(const TimelineInitial()) {
    on<TimelineRefreshed>(_onRefreshed);
    on<TimelineLoadMore>(_onLoadMore);
    on<TimelineCacheLoaded>(_onCacheLoaded);
  }

  /// 判断当前是否有有效的 OAuth Token
  Future<String?> _getToken() async {
    final authRepo = sl<AuthRepository>();
    final method = authRepo.getLoginMethod();
    if (method == 'cookie') return null; // Cookie 登录不使用官方 API
    return authRepo.getSavedToken();
  }

  Future<void> _onRefreshed(
    TimelineRefreshed event,
    Emitter<TimelineState> emit,
  ) async {
    emit(const TimelineLoading());
    try {
      final token = await _getToken();
      final posts = token != null
          ? await timelineRepository.getHomeTimeline(token: token)
          : await timelineRepository.getRecommendTimeline();
      emit(TimelineLoaded(posts: posts, hasReachedMax: posts.length < 20));
    } catch (e) {
      // 尝试加载缓存
      try {
        final cached = await timelineRepository.getCachedTimeline();
        if (cached.isNotEmpty) {
          emit(TimelineLoaded(posts: cached, hasReachedMax: true));
        } else {
          emit(TimelineError(message: e.toString()));
        }
      } catch (_) {
        emit(TimelineError(message: e.toString()));
      }
    }
  }

  Future<void> _onLoadMore(
    TimelineLoadMore event,
    Emitter<TimelineState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TimelineLoaded || currentState.hasReachedMax) return;

    try {
      final nextPage = currentState.currentPage + 1;
      final token = await _getToken();

      final newPosts = token != null
          ? await timelineRepository.getHomeTimeline(
              token: token,
              page: nextPage,
              maxId: currentState.posts.isNotEmpty
                  ? currentState.posts.last.id
                  : null,
            )
          : await timelineRepository.getRecommendTimeline(page: nextPage);

      emit(
        currentState.copyWith(
          posts: [...currentState.posts, ...newPosts],
          hasReachedMax: newPosts.length < 20,
          currentPage: nextPage,
        ),
      );
    } catch (e) {
      // 加载更多失败不改变状态，只保持当前
    }
  }

  Future<void> _onCacheLoaded(
    TimelineCacheLoaded event,
    Emitter<TimelineState> emit,
  ) async {
    final cached = await timelineRepository.getCachedTimeline();
    if (cached.isNotEmpty) {
      emit(TimelineLoaded(posts: cached, hasReachedMax: true));
    }
  }
}
