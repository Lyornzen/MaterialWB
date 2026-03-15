import 'package:equatable/equatable.dart';

abstract class TimelineEvent extends Equatable {
  const TimelineEvent();
  @override
  List<Object?> get props => [];
}

class TimelineRefreshed extends TimelineEvent {
  final TimelineFeedType feedType;
  const TimelineRefreshed({this.feedType = TimelineFeedType.recommend});

  @override
  List<Object?> get props => [feedType];
}

class TimelineLoadMore extends TimelineEvent {
  const TimelineLoadMore();
}

class TimelineCacheLoaded extends TimelineEvent {
  const TimelineCacheLoaded();
}

enum TimelineFeedType { recommend, following }
