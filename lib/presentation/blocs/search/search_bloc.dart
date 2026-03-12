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
      final cards = (data['data']?['cards'] as List?) ?? [];
      final List<Map<String, dynamic>> hotList = [];
      for (final card in cards) {
        final cardGroup = card['card_group'] as List?;
        if (cardGroup != null) {
          for (final item in cardGroup) {
            if (item['desc'] != null) {
              hotList.add({
                'title': item['desc'] ?? '',
                'hot': item['desc_extr'] ?? '',
                'scheme': item['scheme'] ?? '',
              });
            }
          }
        }
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
      final cards = (data['data']?['cards'] as List?) ?? [];
      final posts = cards
          .where((card) => card['card_type'] == 9)
          .map(
            (card) =>
                WeiboPostModel.fromJson(card['mblog'] as Map<String, dynamic>),
          )
          .toList();
      emit(
        SearchResultLoaded(posts: posts.cast<WeiboPost>(), query: event.query),
      );
    } catch (e) {
      emit(SearchError(message: e.toString()));
    }
  }
}
