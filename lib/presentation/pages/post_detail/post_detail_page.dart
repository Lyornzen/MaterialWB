import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_weibo/core/di/injection.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/data/models/weibo_post_model.dart';
import 'package:material_weibo/data/models/comment_model.dart';
import 'package:material_weibo/domain/entities/comment.dart';
import 'package:material_weibo/presentation/blocs/history/history_cubit.dart';
import 'package:material_weibo/presentation/widgets/rich_content_text.dart';
import 'package:material_weibo/presentation/widgets/weibo_card.dart';
import 'package:timeago/timeago.dart' as timeago;

/// 评论排序方式
enum CommentSortType {
  hot, // 按热度
  time, // 按时间
}

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  WeiboPostModel? _post;
  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _error;
  CommentSortType _sortType = CommentSortType.hot;

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
      await _loadComments();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadComments() async {
    try {
      final webApi = sl<WeiboWebApi>();
      final commentData = await webApi.getHotComments(
        widget.postId,
        sortByTime: _sortType == CommentSortType.time,
      );
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
      _comments = [];
      for (final json in commentList) {
        if (json is Map<String, dynamic>) {
          try {
            _comments.add(CommentModel.fromJson(json));
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  void _onSortChanged(CommentSortType newSort) async {
    if (newSort == _sortType) return;
    setState(() {
      _sortType = newSort;
      _comments = [];
    });
    await _loadComments();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('微博详情')),
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
                  // 评论标题栏 + 排序按钮
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '评论 (${_comments.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        // 排序切换
                        _SortChip(
                          label: '热门',
                          isSelected: _sortType == CommentSortType.hot,
                          onTap: () => _onSortChanged(CommentSortType.hot),
                        ),
                        const SizedBox(width: 4),
                        _SortChip(
                          label: '最新',
                          isSelected: _sortType == CommentSortType.time,
                          onTap: () => _onSortChanged(CommentSortType.time),
                        ),
                      ],
                    ),
                  ),
                  if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          '暂无评论',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ..._comments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final comment = entry.value;
                    return _CommentItem(
                      comment: comment,
                      displayFloor: comment.floorNumber ?? (index + 1),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

/// 排序选项芯片
class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;
  final int displayFloor;

  const _CommentItem({required this.comment, required this.displayFloor});

  String _formatCount(int count) {
    if (count <= 0) return '0';
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  /// 格式化评论时间：显示具体时间而非相对时间
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      // 今天：显示 "HH:mm"
      return DateFormat('HH:mm').format(dateTime);
    } else if (diff.inDays < 365) {
      // 今年内：显示 "MM-dd HH:mm"
      return DateFormat('MM-dd HH:mm').format(dateTime);
    } else {
      // 跨年：显示 "yyyy-MM-dd HH:mm"
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    timeago.setLocaleMessages('zh', timeago.ZhMessages());

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
                // 用户名 + 楼层号
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.user.screenName,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '#$displayFloor',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                        fontSize: 11,
                      ),
                    ),
                  ],
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
                // 元信息行：时间 + IP属地 + 点赞
                Row(
                  children: [
                    // 发送时间
                    Text(
                      _formatTime(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                    // IP 属地
                    if (comment.source != null &&
                        comment.source!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          comment.source!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.outline),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
