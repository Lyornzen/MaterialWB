import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_weibo/presentation/blocs/search/search_bloc.dart';
import 'package:material_weibo/presentation/widgets/weibo_card.dart';
import 'package:material_weibo/presentation/widgets/loading_indicator.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SearchBloc>().add(const SearchHotLoaded());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.read<SearchBloc>().add(SearchQuerySubmitted(query: query.trim()));
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
              separatorBuilder: (_, _) => const SizedBox(height: 2),
              itemBuilder: (context, index) =>
                  WeiboCard(post: state.posts[index]),
            );
          }
          return const Center(child: Text('搜索你感兴趣的内容'));
        },
      ),
    );
  }
}
