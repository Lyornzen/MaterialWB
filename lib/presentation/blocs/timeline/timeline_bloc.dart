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

  Future<void> _onRefreshed(
    TimelineRefreshed event,
    Emitter<TimelineState> emit,
  ) async {
    emit(const TimelineLoading());
    try {
      final token = await sl<AuthRepository>().getSavedToken();
      if (token == null) {
        emit(const TimelineError(message: '请先登录'));
        return;
      }
      final posts = await timelineRepository.getHomeTimeline(token: token);
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
      final token = await sl<AuthRepository>().getSavedToken();
      if (token == null) return;
      final nextPage = currentState.currentPage + 1;
      final maxId = currentState.posts.isNotEmpty
          ? currentState.posts.last.id
          : null;
      final newPosts = await timelineRepository.getHomeTimeline(
        token: token,
        page: nextPage,
        maxId: maxId,
      );
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
