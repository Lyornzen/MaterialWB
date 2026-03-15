import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_weibo/core/di/injection.dart';
import 'package:material_weibo/domain/entities/weibo_post.dart';
import 'package:material_weibo/domain/repositories/auth_repository.dart';
import 'package:material_weibo/domain/repositories/timeline_repository.dart';
import 'timeline_event.dart';
import 'timeline_state.dart';

class TimelineBloc extends Bloc<TimelineEvent, TimelineState> {
  final TimelineRepository timelineRepository;
  TimelineFeedType _activeFeed = TimelineFeedType.recommend;

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
      _activeFeed = event.feedType;
      final token = await _getToken();
      final List<WeiboPost> posts = await _loadFeed(
        feedType: _activeFeed,
        token: token,
      );
      emit(
        TimelineLoaded(
          posts: posts,
          hasReachedMax: posts.length < 20,
          feedType: _activeFeed,
        ),
      );
    } catch (e) {
      // 尝试加载缓存
      try {
        final cached = await timelineRepository.getCachedTimeline();
        if (cached.isNotEmpty) {
          emit(
            TimelineLoaded(
              posts: cached,
              hasReachedMax: true,
              feedType: _activeFeed,
            ),
          );
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
      final List<WeiboPost> newPosts = await _loadFeed(
        feedType: currentState.feedType,
        token: token,
        page: nextPage,
        maxId: currentState.posts.isNotEmpty ? currentState.posts.last.id : null,
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
      emit(
        TimelineLoaded(
          posts: cached,
          hasReachedMax: true,
          feedType: _activeFeed,
        ),
      );
    }
  }

  Future<List<WeiboPost>> _loadFeed({
    required TimelineFeedType feedType,
    required String? token,
    int page = 1,
    String? maxId,
  }) async {
    if (feedType == TimelineFeedType.recommend) {
      return timelineRepository.getRecommendTimeline(page: page);
    }

    if (token != null) {
      return timelineRepository.getHomeTimeline(
        token: token,
        page: page,
        maxId: maxId,
      );
    }

    // Cookie/游客模式下没有官方关注流时，从推荐流中筛出已关注作者。
    final collected = <WeiboPost>[];
    final seenIds = <String>{};
    for (var offset = 0; offset < 4 && collected.length < 20; offset++) {
      final recommendPage = ((page - 1) * 4) + offset + 1;
      final items = await timelineRepository.getRecommendTimeline(
        page: recommendPage,
      );
      for (final post in items) {
        if (post.user.following == true && seenIds.add(post.id)) {
          collected.add(post);
        }
      }
    }
    return collected;
  }
}
