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
      final List<WeiboPost> posts = [];
      final seenIds = <String>{};

      void tryAddPost(dynamic raw) {
        if (raw is! Map<String, dynamic>) return;
        try {
          if (WeiboPostModel.isAdPost(raw)) return;
          final post = WeiboPostModel.fromJson(raw);
          if (post.id.isEmpty || seenIds.contains(post.id)) return;
          seenIds.add(post.id);
          posts.add(post);
        } catch (_) {}
      }

      // 格式1: PC web searchList — {"ok":1, "statuses":[...]}
      final statuses = data['statuses'] as List?;
      if (statuses != null) {
        for (final s in statuses) {
          tryAddPost(s);
        }
      }

      // 格式2: 侧边搜索回退 — {"data":{"statuses":[...], ...}}
      if (posts.isEmpty) {
        final dataInner = data['data'];
        if (dataInner is Map<String, dynamic>) {
          final innerStatuses = dataInner['statuses'] as List?;
          if (innerStatuses != null) {
            for (final s in innerStatuses) {
              tryAddPost(s);
            }
          }
        }
      }

      // 格式2.1: PC web 部分版本返回 data.list
      if (posts.isEmpty) {
        final dataInner = data['data'];
        if (dataInner is Map<String, dynamic>) {
          final innerList = dataInner['list'] as List?;
          if (innerList != null) {
            for (final item in innerList) {
              if (item is Map<String, dynamic>) {
                tryAddPost(item['mblog'] ?? item['status'] ?? item);
              }
            }
          }
        }
      }

      // 格式3: m.weibo.cn cards 格式 (回退)
      if (posts.isEmpty) {
        final cards =
            (data['cards'] as List?) ?? (data['data']?['cards'] as List?) ?? [];
        for (final card in cards) {
          if (card is! Map<String, dynamic>) continue;
          final cardType = card['card_type'];

          // 直接包含 mblog 的卡片
          if (cardType == 9 && card['mblog'] != null) {
            tryAddPost(card['mblog']);
          }

          // card_type 11 常见于搜索结果列表，包含 scheme/items
          if (cardType == 11 && card['itemid'] != null) {
            tryAddPost(card['status'] ?? card['mblog']);
          }

          // card_group 内嵌的卡片（搜索结果常用此结构）
          final cardGroup = card['card_group'] as List?;
          if (cardGroup != null) {
            for (final groupItem in cardGroup) {
              if (groupItem is Map<String, dynamic>) {
                if (groupItem['card_type'] == 9 && groupItem['mblog'] != null) {
                  tryAddPost(groupItem['mblog']);
                }
                tryAddPost(groupItem['status'] ?? groupItem['mblog']);
              }
            }
          }
        }
      }

      // 格式4: 递归兜底（接口结构变更时）
      if (posts.isEmpty) {
        void walk(dynamic node) {
          if (node is Map<String, dynamic>) {
            // 常见微博节点
            if (node.containsKey('user') &&
                node.containsKey('id') &&
                node.containsKey('text')) {
              tryAddPost(node);
            }
            if (node['mblog'] is Map<String, dynamic>) {
              tryAddPost(node['mblog']);
            }
            if (node['status'] is Map<String, dynamic>) {
              tryAddPost(node['status']);
            }
            for (final value in node.values) {
              walk(value);
            }
          } else if (node is List) {
            for (final item in node) {
              walk(item);
            }
          }
        }

        walk(data);
      }

      emit(SearchResultLoaded(posts: posts, query: event.query));
    } catch (e) {
      emit(SearchError(message: e.toString()));
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
      final seenIds = <String>{};

      void tryAddUser(dynamic raw) {
        if (raw is! Map<String, dynamic>) return;
        try {
          final user = UserModel.fromJson(raw);
          if (user.id.isEmpty || seenIds.contains(user.id)) return;
          seenIds.add(user.id);
          users.add(user);
        } catch (_) {}
      }

      // PC web 格式: { "ok": 1, "data": { "users": [...] } }
      final userList =
          (data['data']?['users'] as List?) ??
          (data['users'] as List?) ??
          (data['data'] as List?) ??
          [];
      for (final item in userList) {
        tryAddUser(item);
      }

      if (users.isEmpty) {
        final dataInner = data['data'];
        if (dataInner is Map<String, dynamic> && dataInner['list'] is List) {
          for (final item in dataInner['list'] as List) {
            if (item is Map<String, dynamic>) {
              tryAddUser(item['user'] ?? item);
            }
          }
        }
      }

      if (users.isEmpty) {
        void walk(dynamic node) {
          if (node is Map<String, dynamic>) {
            final hasIdentity =
                node.containsKey('id') &&
                (node.containsKey('screen_name') || node.containsKey('name'));
            if (hasIdentity) {
              tryAddUser(node);
            }
            if (node['user'] is Map<String, dynamic>) {
              tryAddUser(node['user']);
            }
            for (final value in node.values) {
              walk(value);
            }
          } else if (node is List) {
            for (final item in node) {
              walk(item);
            }
          }
        }

        walk(data);
      }

      emit(SearchUserResultLoaded(users: users, query: event.query));
    } catch (e) {
      emit(SearchError(message: e.toString()));
    }
  }
}
