import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:material_weibo/domain/entities/weibo_post.dart';
import 'package:material_weibo/presentation/blocs/favorite/favorite_cubit.dart';
import 'package:material_weibo/presentation/widgets/image_grid.dart';
import 'package:material_weibo/presentation/widgets/action_bar.dart';
import 'package:material_weibo/presentation/widgets/user_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;

/// 微博卡片组件
class WeiboCard extends StatelessWidget {
  final WeiboPost post;
  final bool showFullContent;

  const WeiboCard({
    super.key,
    required this.post,
    this.showFullContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void navigateToDetail() {
      if (!showFullContent) {
        context.push('/post/${post.id}');
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息行 — 头像和更多按钮有自己的点击事件
            Row(
              children: [
                UserAvatar(
                  imageUrl: post.user.profileImageUrl,
                  size: 40,
                  onTap: () => context.push('/profile/${post.user.id}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: navigateToDetail,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.user.screenName,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (post.user.verified == true)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          _formatTime(post.createdAt),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 20),
                  onPressed: () {},
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 可点击的内容区域（正文 + 图片 + 转发）
            InkWell(
              onTap: showFullContent ? null : navigateToDetail,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 微博正文
                  Text(
                    _stripHtmlTags(post.text),
                    style: textTheme.bodyMedium,
                    maxLines: showFullContent ? null : 6,
                    overflow: showFullContent ? null : TextOverflow.ellipsis,
                  ),

                  // 图片
                  if (post.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ImageGrid(imageUrls: post.imageUrls),
                  ],

                  // 转发内容
                  if (post.retweetedStatus != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@${post.retweetedStatus!.user.screenName}',
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _stripHtmlTags(post.retweetedStatus!.text),
                            style: textTheme.bodySmall,
                            maxLines: showFullContent ? null : 3,
                            overflow: showFullContent
                                ? null
                                : TextOverflow.ellipsis,
                          ),
                          if (post.retweetedStatus!.imageUrls.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ImageGrid(
                              imageUrls: post.retweetedStatus!.imageUrls,
                              maxCount: 3,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 操作栏 — 有自己的点击事件，独立于内容区域
            const SizedBox(height: 8),
            ActionBar(
              repostCount: post.repostsCount,
              commentCount: post.commentsCount,
              likeCount: post.attitudesCount,
              isFavorited: post.favorited ?? false,
              postId: post.id,
              onRepost: () {
                final url = 'https://m.weibo.cn/detail/${post.id}';
                Share.share(
                  '${post.user.screenName}: ${_stripHtmlTags(post.text)}\n$url',
                );
              },
              onComment: showFullContent
                  ? null // 已经在详情页，不需要再跳转
                  : () => context.push('/post/${post.id}'),
              onLike: () {
                context.read<FavoriteCubit>().toggleFavorite(
                  post.id,
                  post.favorited ?? false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    timeago.setLocaleMessages('zh', timeago.ZhMessages());
    return timeago.format(dateTime, locale: 'zh');
  }

  /// 简单的 HTML 标签剥离
  String _stripHtmlTags(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }
}
