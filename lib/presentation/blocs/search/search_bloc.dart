import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/data/models/user_model.dart';
import 'package:material_weibo/data/models/weibo_post_model.dart';
import 'package:material_weibo/domain/entities/user.dart';
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

class SearchUserQuerySubmitted extends SearchEvent {
  final String query;
  const SearchUserQuerySubmitted({required this.query});
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

class SearchUserResultLoaded extends SearchState {
  final List<WeiboUser> users;
  final String query;
  const SearchUserResultLoaded({required this.users, required this.query});
  @override
  List<Object?> get props => [users, query];
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
    on<SearchUserQuerySubmitted>(_onUserQuerySubmitted);
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
      debugPrint('Search response keys: ${data.keys.toList()}');
      final List<WeiboPost> posts = [];

      // 格式1: PC web searchList — {"ok":1, "statuses":[...]}
      final statuses = data['statuses'] as List?;
      if (statuses != null) {
        debugPrint('Format 1: found ${statuses.length} statuses');
        for (final s in statuses) {
          if (s is Map<String, dynamic>) {
            try {
              if (!WeiboPostModel.isAdPost(s)) {
                posts.add(WeiboPostModel.fromJson(s));
              }
            } catch (e) {
              debugPrint('Parse post error: $e');
            }
          }
        }
      }

      // 格式2: 侧边搜索回退 — {"data":{"statuses":[...], ...}}
      if (posts.isEmpty) {
        final dataInner = data['data'];
        if (dataInner is Map<String, dynamic>) {
          final innerStatuses = dataInner['statuses'] as List?;
          if (innerStatuses != null) {
            debugPrint('Format 2: found ${innerStatuses.length} statuses');
            for (final s in innerStatuses) {
              if (s is Map<String, dynamic>) {
                try {
                  if (!WeiboPostModel.isAdPost(s)) {
                    posts.add(WeiboPostModel.fromJson(s));
                  }
                } catch (e) {
                  debugPrint('Parse post error: $e');
                }
              }
            }
          }
        }
      }

      // 格式3: m.weibo.cn cards 格式 (回退)
      if (posts.isEmpty) {
        final cards = (data['data']?['cards'] as List?) ?? [];
        debugPrint('Format 3: found ${cards.length} cards');
        for (final card in cards) {
          if (card is! Map<String, dynamic>) continue;
          final cardType = card['card_type'];

          // 直接包含 mblog 的卡片
          if (cardType == 9 && card['mblog'] != null) {
            try {
              final mblog = card['mblog'] as Map<String, dynamic>;
              if (!WeiboPostModel.isAdPost(mblog)) {
                posts.add(WeiboPostModel.fromJson(mblog));
              }
            } catch (e) {
              debugPrint('Parse card mblog error: $e');
            }
          }

          // card_group 内嵌的卡片（搜索结果常用此结构）
          final cardGroup = card['card_group'] as List?;
          if (cardGroup != null) {
            for (final groupItem in cardGroup) {
              if (groupItem is Map<String, dynamic> &&
                  groupItem['card_type'] == 9 &&
                  groupItem['mblog'] != null) {
                try {
                  final mblog = groupItem['mblog'] as Map<String, dynamic>;
                  if (!WeiboPostModel.isAdPost(mblog)) {
                    posts.add(WeiboPostModel.fromJson(mblog));
                  }
                } catch (e) {
                  debugPrint('Parse card_group mblog error: $e');
                }
              }
            }
          }
        }
      }

      debugPrint('Search total parsed posts: ${posts.length}');
      emit(SearchResultLoaded(posts: posts, query: event.query));
    } catch (e) {
      debugPrint('Search error: $e');
      emit(SearchError(message: '搜索失败: $e'));
    }
  }

  Future<void> _onUserQuerySubmitted(
    SearchUserQuerySubmitted event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchLoading());
    try {
      final data = await webApi.searchUsers(event.query);
      final List<WeiboUser> users = [];

      // PC web 格式: { "ok": 1, "data": { "users": [...] } }
      final userList =
          (data['data']?['users'] as List?) ??
          (data['users'] as List?) ??
          (data['data'] as List?) ??
          [];
      for (final item in userList) {
        if (item is Map<String, dynamic>) {
          try {
            users.add(UserModel.fromJson(item));
          } catch (_) {}
        }
      }

      emit(SearchUserResultLoaded(users: users, query: event.query));
    } catch (e) {
      emit(SearchError(message: e.toString()));
    }
  }
}
