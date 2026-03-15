import 'package:equatable/equatable.dart';
import 'package:material_weibo/domain/entities/weibo_post.dart';
import 'timeline_event.dart';

abstract class TimelineState extends Equatable {
  const TimelineState();
  @override
  List<Object?> get props => [];
}

class TimelineInitial extends TimelineState {
  const TimelineInitial();
}

class TimelineLoading extends TimelineState {
  const TimelineLoading();
}

class TimelineLoaded extends TimelineState {
  final List<WeiboPost> posts;
  final bool hasReachedMax;
  final int currentPage;
  final TimelineFeedType feedType;

  const TimelineLoaded({
    required this.posts,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.feedType = TimelineFeedType.recommend,
  });

  TimelineLoaded copyWith({
    List<WeiboPost>? posts,
    bool? hasReachedMax,
    int? currentPage,
    TimelineFeedType? feedType,
  }) {
    return TimelineLoaded(
      posts: posts ?? this.posts,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      feedType: feedType ?? this.feedType,
    );
  }

  @override
  List<Object?> get props => [posts, hasReachedMax, currentPage, feedType];
}

class TimelineError extends TimelineState {
  final String message;
  const TimelineError({required this.message});
  @override
  List<Object?> get props => [message];
}
