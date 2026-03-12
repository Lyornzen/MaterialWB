import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/data/models/weibo_post_model.dart';
import 'package:material_weibo/domain/entities/weibo_post.dart';

// Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

class SearchQuerySubmitted extends SearchEvent {
  final String query;
  const SearchQuerySubmitted({required this.query});
  @override
  List<Object?> get props => [query];
}

class SearchHotLoaded extends SearchEvent {
  const SearchHotLoaded();
}

// States
abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchHotResults extends SearchState {
  final List<Map<String, dynamic>> hotSearches;
  const SearchHotResults({required this.hotSearches});
  @override
  List<Object?> get props => [hotSearches];
}

class SearchResultLoaded extends SearchState {
  final List<WeiboPost> posts;
  final String query;
  const SearchResultLoaded({required this.posts, required this.query});
  @override
  List<Object?> get props => [posts, query];
}

class SearchError extends SearchState {
  final String message;
  const SearchError({required this.message});
  @override
  List<Object?> get props => [message];
}

// Bloc
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final WeiboWebApi webApi;

  SearchBloc({required this.webApi}) : super(const SearchInitial()) {
    on<SearchHotLoaded>(_onHotLoaded);
    on<SearchQuerySubmitted>(_onQuerySubmitted);
  }

  Future<void> _onHotLoaded(
    SearchHotLoaded event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchLoading());
    try {
      final data = await webApi.getHotSearch();
      // PC web hot_band 返回格式:
      // {"ok":1, "data":{"band_list":[{"word":"...", "raw_hot":123, ...}, ...]}}
      final bandList = (data['data']?['band_list'] as List?) ?? [];
      final List<Map<String, dynamic>> hotList = [];
      for (final item in bandList) {
        final word = item['word'] ?? item['query'] ?? '';
        if (word.toString().isEmpty) continue;
        final rawHot = item['raw_hot'] ?? item['num'] ?? 0;
        hotList.add({
          'title': word.toString(),
          'hot': rawHot.toString(),
          'icon_desc': item['icon_desc'] ?? '',
        });
      }
      emit(SearchHotResults(hotSearches: hotList));
    } catch (e) {
      emit(SearchError(message: e.toString()));
    }
  }

  Future<void> _onQuerySubmitted(
    SearchQuerySubmitted event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchLoading());
    try {
      final data = await webApi.search(event.query);
      final List<WeiboPost> posts = [];

      // 格式1: PC web searchList — {"ok":1, "statuses":[...]} 或 {"data":{...}}
      final statuses = data['statuses'] as List?;
      if (statuses != null) {
        for (final s in statuses) {
          if (s is Map<String, dynamic>) {
            try {
              posts.add(WeiboPostModel.fromJson(s));
            } catch (_) {}
          }
        }
      }

      // 格式2: 侧边搜索回退 — {"data":{"statuses":[...], ...}}
      if (posts.isEmpty) {
        final dataInner = data['data'];
        if (dataInner is Map<String, dynamic>) {
          final innerStatuses = dataInner['statuses'] as List?;
          if (innerStatuses != null) {
            for (final s in innerStatuses) {
              if (s is Map<String, dynamic>) {
                try {
                  posts.add(WeiboPostModel.fromJson(s));
                } catch (_) {}
              }
            }
          }
        }
      }

      // 格式3: m.weibo.cn cards 格式 (向后兼容)
      if (posts.isEmpty) {
        final cards = (data['data']?['cards'] as List?) ?? [];
        for (final card in cards) {
          if (card is Map<String, dynamic> && card['card_type'] == 9) {
            final mblog = card['mblog'];
            if (mblog is Map<String, dynamic>) {
              try {
                posts.add(WeiboPostModel.fromJson(mblog));
              } catch (_) {}
            }
          }
        }
      }

      emit(SearchResultLoaded(posts: posts, query: event.query));
    } catch (e) {
      emit(SearchError(message: e.toString()));
    }
  }
}
