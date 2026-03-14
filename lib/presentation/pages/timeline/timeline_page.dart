import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_weibo/core/l10n/app_localizations.dart';
import 'package:material_weibo/presentation/blocs/timeline/timeline_bloc.dart';
import 'package:material_weibo/presentation/blocs/timeline/timeline_event.dart';
import 'package:material_weibo/presentation/blocs/timeline/timeline_state.dart';
import 'package:material_weibo/presentation/widgets/weibo_card.dart';
import 'package:material_weibo/presentation/widgets/loading_indicator.dart';
import 'package:material_weibo/presentation/widgets/error_widget.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => TimelinePageState();
}

class TimelinePageState extends State<TimelinePage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<TimelineBloc>().add(const TimelineRefreshed());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<TimelineBloc>().add(const TimelineLoadMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  /// 滚动到顶部并刷新（供外部调用，如双击首页 tab）
  void scrollToTopAndRefresh() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    context.read<TimelineBloc>().add(const TimelineRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MaterialWeibo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: BlocBuilder<TimelineBloc, TimelineState>(
        builder: (context, state) {
          if (state is TimelineLoading) {
            return const LoadingIndicator();
          }
          if (state is TimelineError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () =>
                  context.read<TimelineBloc>().add(const TimelineRefreshed()),
            );
          }
          if (state is TimelineLoaded) {
            if (state.posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      S.get('home_no_posts'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<TimelineBloc>().add(const TimelineRefreshed());
              },
              child: ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.hasReachedMax
                    ? state.posts.length
                    : state.posts.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  if (index >= state.posts.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return WeiboCard(post: state.posts[index]);
                },
              ),
            );
          }
          return const LoadingIndicator();
        },
      ),
    );
  }
}
