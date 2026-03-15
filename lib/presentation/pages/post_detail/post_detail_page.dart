import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_weibo/core/i18n/app_i18n.dart';
import 'package:material_weibo/core/di/injection.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/data/models/weibo_post_model.dart';
import 'package:material_weibo/data/models/comment_model.dart';
import 'package:material_weibo/domain/entities/comment.dart';
import 'package:material_weibo/presentation/blocs/history/history_cubit.dart';
import 'package:material_weibo/presentation/widgets/rich_content_text.dart';
import 'package:material_weibo/presentation/widgets/weibo_card.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  WeiboPostModel? _post;
  List<Comment> _comments = [];
  List<Comment> _rawComments = [];
  bool _isLoading = true;
  String? _error;
  _CommentSort _sort = _CommentSort.hot;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final webApi = sl<WeiboWebApi>();
      final data = await webApi.getPostDetail(widget.postId);

      // PC web /ajax/statuses/show 直接返回帖子对象
      // 但也可能包在 data 字段里，兼容两种格式
      Map<String, dynamic>? postJson;
      if (data.containsKey('text') && data.containsKey('user')) {
        // 直接是帖子对象
        postJson = data;
      } else if (data['data'] is Map<String, dynamic>) {
        postJson = data['data'] as Map<String, dynamic>;
      }

      if (postJson != null) {
        _post = WeiboPostModel.fromJson(postJson);
        // 记录浏览历史
        if (mounted) {
          context.read<HistoryCubit>().addToHistory(_post!);
        }
      }

      // 加载评论
      try {
        final commentData = await webApi.getHotComments(widget.postId);
        // PC web buildComments 返回 {"data": [...], "max_id": ...}
        // 或 {"data": {"data": [...], ...}}
        List? commentList;
        final innerData = commentData['data'];
        if (innerData is List) {
          commentList = innerData;
        } else if (innerData is Map) {
          commentList = innerData['data'] as List?;
        }
        commentList ??= [];
        _rawComments = [];
        for (final json in commentList) {
          if (json is Map<String, dynamic>) {
            try {
              _rawComments.add(CommentModel.fromJson(json));
            } catch (_) {}
          }
        }
        _applySort();
      } catch (_) {}

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _applySort() {
    final list = List<Comment>.from(_rawComments);
    if (_sort == _CommentSort.hot) {
      list.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    _comments = list;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final i18n = context.i18n;

    return Scaffold(
      appBar: AppBar(title: Text(i18n.tr('微博详情', 'Post Detail'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: TextStyle(color: colorScheme.error)),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _loadDetail, child: const Text('重试')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: ListView(
                children: [
                  if (_post != null)
                    WeiboCard(post: _post!, showFullContent: true),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${i18n.tr('评论', 'Comments')} (${_comments.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        SegmentedButton<_CommentSort>(
                          segments: [
                            ButtonSegment(
                              value: _CommentSort.hot,
                              label: Text(i18n.tr('热度', 'Hot')),
                            ),
                            ButtonSegment(
                              value: _CommentSort.time,
                              label: Text(i18n.tr('时间', 'Time')),
                            ),
                          ],
                          selected: {_sort},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _sort = selection.first;
                              _applySort();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          i18n.tr('暂无评论', 'No comments yet'),
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ..._comments.map((comment) => _CommentItem(comment: comment)),
                ],
              ),
            ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;

  const _CommentItem({required this.comment});

  String _formatCount(int count) {
    if (count <= 0) return '0';
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final i18n = context.i18n;
    final localeCode = i18n.isZh ? 'zh' : 'en';
    if (i18n.isZh) {
      timeago.setLocaleMessages('zh', timeago.ZhMessages());
    } else {
      timeago.setLocaleMessages('en', timeago.EnMessages());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: comment.user.profileImageUrl.isNotEmpty
                ? NetworkImage(comment.user.profileImageUrl)
                : null,
            child: comment.user.profileImageUrl.isEmpty
                ? Icon(
                    Icons.person,
                    size: 18,
                    color: colorScheme.onPrimaryContainer,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.user.screenName,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                ),
                const SizedBox(height: 4),
                RichContentText(
                  htmlText: comment.text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                // 显示评论配图（图片回复）
                if (comment.picUrl != null && comment.picUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 200,
                        maxHeight: 200,
                      ),
                      child: Image.network(
                        comment.picUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      timeago.format(comment.createdAt, locale: localeCode),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                    if ((comment.floorNumber ?? 0) > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        i18n.isZh
                            ? '${comment.floorNumber}楼'
                            : '#${comment.floorNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                    if (comment.ipLocation != null &&
                        comment.ipLocation!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        i18n.isZh
                            ? 'IP属地 ${comment.ipLocation}'
                            : 'IP ${comment.ipLocation}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                    const SizedBox(width: 16),
                    Icon(
                      Icons.thumb_up_outlined,
                      size: 14,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(comment.likeCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                // 显示回复评论
                if (comment.replyComment != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '@${comment.replyComment!.user.screenName}: ',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: colorScheme.primary),
                              ),
                            ],
                          ),
                        ),
                        RichContentText(
                          htmlText: comment.replyComment!.text,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        // 回复评论的配图
                        if (comment.replyComment!.picUrl != null &&
                            comment.replyComment!.picUrl!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 150,
                                maxHeight: 150,
                              ),
                              child: Image.network(
                                comment.replyComment!.picUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _CommentSort { hot, time }
