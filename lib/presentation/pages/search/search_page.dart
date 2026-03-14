import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_weibo/presentation/blocs/search/search_bloc.dart';
import 'package:material_weibo/presentation/widgets/weibo_card.dart';
import 'package:material_weibo/presentation/widgets/loading_indicator.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  /// 0 = 微博, 1 = 用户
  int _currentTab = 0;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _currentTab = _tabController.index);
      if (_lastQuery.isNotEmpty) {
        _executeSearch(_lastQuery);
      }
    });

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _lastQuery = widget.initialQuery!;
      _executeSearch(widget.initialQuery!);
    } else {
      context.read<SearchBloc>().add(const SearchHotLoaded());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isNotEmpty) {
      _lastQuery = query.trim();
      _executeSearch(_lastQuery);
    }
  }

  void _executeSearch(String query) {
    if (_currentTab == 0) {
      context.read<SearchBloc>().add(SearchQuerySubmitted(query: query));
    } else {
      context.read<SearchBloc>().add(SearchUserQuerySubmitted(query: query));
    }
  }

  String _formatHotCount(String count) {
    final num = int.tryParse(count) ?? 0;
    if (num >= 100000000) {
      return '${(num / 100000000).toStringAsFixed(1)}亿';
    } else if (num >= 10000) {
      return '${(num / 10000).toStringAsFixed(1)}万';
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '搜索微博',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
          onSubmitted: _onSearch,
        ),
        bottom: _lastQuery.isNotEmpty
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '微博'),
                  Tab(text: '用户'),
                ],
              )
            : null,
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) return const LoadingIndicator();
          if (state is SearchError) {
            return Center(child: Text(state.message));
          }
          if (state is SearchHotResults) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.hotSearches.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '热搜榜',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }
                final item = state.hotSearches[index - 1];
                final iconDesc = item['icon_desc']?.toString() ?? '';
                return ListTile(
                  leading: Text(
                    '$index',
                    style: TextStyle(
                      color: index <= 3
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                      fontWeight: index <= 3
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(child: Text(item['title'] ?? '')),
                      if (iconDesc.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: iconDesc == '沸'
                                ? colorScheme.error
                                : iconDesc == '热'
                                ? Colors.orange
                                : colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            iconDesc,
                            style: TextStyle(
                              fontSize: 10,
                              color: iconDesc == '沸' || iconDesc == '热'
                                  ? Colors.white
                                  : colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle:
                      item['hot'] != null &&
                          item['hot'] != '' &&
                          item['hot'] != '0'
                      ? Text('${_formatHotCount(item['hot'].toString())} 热度')
                      : null,
                  onTap: () {
                    _searchController.text = item['title'] ?? '';
                    _onSearch(item['title'] ?? '');
                  },
                );
              },
            );
          }
          if (state is SearchResultLoaded) {
            if (state.posts.isEmpty) {
              return const Center(child: Text('未找到相关内容'));
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, index) =>
                  WeiboCard(post: state.posts[index]),
            );
          }
          if (state is SearchUserResultLoaded) {
            if (state.users.isEmpty) {
              return const Center(child: Text('未找到相关用户'));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.users.length,
              itemBuilder: (context, index) {
                final user = state.users[index];
                return _UserSearchCard(
                  user: user,
                  onTap: () => context.push('/profile/${user.id}'),
                );
              },
            );
          }
          return const Center(child: Text('搜索你感兴趣的内容'));
        },
      ),
    );
  }
}

/// 用户搜索结果卡片
class _UserSearchCard extends StatelessWidget {
  final dynamic user; // WeiboUser
  final VoidCallback? onTap;

  const _UserSearchCard({required this.user, this.onTap});

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: user.profileImageUrl.isNotEmpty
                    ? NetworkImage(user.profileImageUrl)
                    : null,
                child: user.profileImageUrl.isEmpty
                    ? Icon(Icons.person, color: colorScheme.onPrimaryContainer)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.screenName,
                            style: Theme.of(context).textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.verified == true) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    if (user.description != null &&
                        user.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '粉丝 ${_formatCount(user.followersCount)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.outline),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '微博 ${_formatCount(user.statusesCount)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
