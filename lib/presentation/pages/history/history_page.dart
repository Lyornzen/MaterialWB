import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_weibo/core/i18n/app_i18n.dart';
import 'package:material_weibo/presentation/blocs/history/history_cubit.dart';
import 'package:material_weibo/presentation/widgets/empty_state.dart';
import 'package:material_weibo/presentation/widgets/error_widget.dart';
import 'package:material_weibo/presentation/widgets/weibo_card.dart';
import 'package:material_weibo/presentation/widgets/loading_indicator.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryCubit>().loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.tr('浏览历史', 'History')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) return const LoadingIndicator();
          if (state is HistoryError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<HistoryCubit>().loadHistory(),
            );
          }
          if (state is HistoryLoaded) {
            if (state.posts.isEmpty) {
              return AppEmptyState(
                icon: Icons.history,
                title: i18n.tr('暂无浏览记录', 'No browsing history yet'),
                subtitle: i18n.tr(
                  '你看过的微博会保存在这里',
                  'Posts you viewed will be saved here',
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 2),
              itemBuilder: (context, index) =>
                  WeiboCard(post: state.posts[index]),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    final i18n = context.i18n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(i18n.tr('清除历史', 'Clear History')),
        content: Text(
          i18n.tr(
            '确定要清除所有浏览历史吗？',
            'Are you sure you want to clear all browsing history?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(i18n.tr('取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              context.read<HistoryCubit>().clearHistory();
              Navigator.pop(ctx);
            },
            child: Text(i18n.tr('确定', 'Confirm')),
          ),
        ],
      ),
    );
  }
}
