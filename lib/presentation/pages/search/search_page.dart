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
                  title: Text(item['title'] ?? ''),
                  subtitle: item['hot'] != null && item['hot'] != ''
                      ? Text(item['hot'].toString())
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
