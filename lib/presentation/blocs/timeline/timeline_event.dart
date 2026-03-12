import 'package:equatable/equatable.dart';

abstract class TimelineEvent extends Equatable {
  const TimelineEvent();
  @override
  List<Object?> get props => [];
}

class TimelineRefreshed extends TimelineEvent {
  const TimelineRefreshed();
}

class TimelineLoadMore extends TimelineEvent {
  const TimelineLoadMore();
}

class TimelineCacheLoaded extends TimelineEvent {
  const TimelineCacheLoaded();
}
