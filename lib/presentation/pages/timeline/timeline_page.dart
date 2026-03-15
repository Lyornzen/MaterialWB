import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_weibo/core/i18n/app_i18n.dart';
import 'package:material_weibo/presentation/blocs/timeline/timeline_bloc.dart';
import 'package:material_weibo/presentation/blocs/timeline/timeline_event.dart';
import 'package:material_weibo/presentation/blocs/timeline/timeline_state.dart';
import 'package:material_weibo/presentation/widgets/empty_state.dart';
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
  TimelineFeedType _selectedFeed = TimelineFeedType.recommend;

  @override
  void initState() {
    super.initState();
    context.read<TimelineBloc>().add(
      TimelineRefreshed(feedType: _selectedFeed),
    );
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

  Future<void> scrollToTopAndRefresh() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
    if (mounted) {
      context.read<TimelineBloc>().add(
        TimelineRefreshed(feedType: _selectedFeed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      appBar: AppBar(
        title: const Text('MaterialWeibo'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<TimelineFeedType>(
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                segments: [
                  ButtonSegment(
                    value: TimelineFeedType.recommend,
                    label: Text(i18n.tr('推荐', 'Recommend')),
                  ),
                  ButtonSegment(
                    value: TimelineFeedType.following,
                    label: Text(i18n.tr('已关注', 'Following')),
                  ),
                ],
                selected: {_selectedFeed},
                onSelectionChanged: (selection) {
                  final selected = selection.first;
                  if (selected == _selectedFeed) return;
                  setState(() => _selectedFeed = selected);
                  context.read<TimelineBloc>().add(
                    TimelineRefreshed(feedType: selected),
                  );
                },
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
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
              onRetry: () => context.read<TimelineBloc>().add(
                TimelineRefreshed(feedType: _selectedFeed),
              ),
            );
          }
          if (state is TimelineLoaded) {
            if (state.posts.isEmpty) {
              return AppEmptyState(
                icon: Icons.inbox_outlined,
                title: state.feedType == TimelineFeedType.following
                    ? i18n.tr('暂无已关注博主微博', 'No following posts yet')
                    : i18n.tr('暂无微博', 'No posts yet'),
                subtitle: state.feedType == TimelineFeedType.following
                    ? i18n.tr(
                        '当前会话里还没有可展示的关注内容',
                        'No followed posts are available in this session yet',
                      )
                    : i18n.tr(
                        '下拉刷新试试，或稍后再回来看看',
                        'Try pulling to refresh or come back later',
                      ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<TimelineBloc>().add(
                  TimelineRefreshed(feedType: _selectedFeed),
                );
              },
              child: ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.hasReachedMax
                    ? state.posts.length
                    : state.posts.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 2),
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
