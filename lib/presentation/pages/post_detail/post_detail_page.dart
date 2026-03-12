import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_weibo/core/di/injection.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/data/models/weibo_post_model.dart';
import 'package:material_weibo/data/models/comment_model.dart';
import 'package:material_weibo/domain/entities/comment.dart';
import 'package:material_weibo/presentation/blocs/history/history_cubit.dart';
import 'package:material_weibo/presentation/widgets/weibo_card.dart';

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
        _comments = [];
        for (final json in commentList) {
          if (json is Map<String, dynamic>) {
            try {
              _comments.add(CommentModel.fromJson(json));
            } catch (_) {}
          }
        }
      } catch (_) {}

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '评论 (${_comments.length})',
                      style: Theme.of(context).textTheme.titleMedium,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                Text(
                  comment.text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                if (comment.likeCount > 0)
                  Text(
                    '${comment.likeCount} 赞',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
