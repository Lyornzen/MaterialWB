import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_weibo/domain/entities/weibo_post.dart';
import 'package:material_weibo/domain/repositories/history_repository.dart';

// State
abstract class HistoryState extends Equatable {
  const HistoryState();
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  final List<WeiboPost> posts;
  const HistoryLoaded({required this.posts});
  @override
  List<Object?> get props => [posts];
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError({required this.message});
  @override
  List<Object?> get props => [message];
}

// Cubit
class HistoryCubit extends Cubit<HistoryState> {
  final HistoryRepository historyRepository;

  HistoryCubit({required this.historyRepository})
    : super(const HistoryInitial());

  Future<void> loadHistory({int page = 1}) async {
    emit(const HistoryLoading());
    try {
      final posts = await historyRepository.getHistory(page: page);
      emit(HistoryLoaded(posts: posts));
    } catch (e) {
      emit(HistoryError(message: e.toString()));
    }
  }

  Future<void> addToHistory(WeiboPost post) async {
    await historyRepository.addHistory(post);
  }

  Future<void> clearHistory() async {
    await historyRepository.clearHistory();
    emit(const HistoryLoaded(posts: []));
  }

  Future<void> removeFromHistory(String postId) async {
    await historyRepository.removeHistory(postId);
    await loadHistory();
  }
}
