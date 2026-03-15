import 'package:flutter/material.dart';

/// 微博操作栏（转发/评论/点赞）
class ActionBar extends StatelessWidget {
  final int repostCount;
  final int commentCount;
  final int likeCount;
  final bool isFavorited;
  final String postId;
  final VoidCallback? onRepost;
  final VoidCallback? onComment;
  final VoidCallback? onLike;

  const ActionBar({
    super.key,
    required this.repostCount,
    required this.commentCount,
    required this.likeCount,
    this.isFavorited = false,
    required this.postId,
    this.onRepost,
    this.onComment,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionButton(
          icon: Icons.repeat,
          label: _formatCount(repostCount),
          style: style,
          color: colorScheme.onSurfaceVariant,
          onTap: onRepost ?? () {},
        ),
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: _formatCount(commentCount),
          style: style,
          color: colorScheme.onSurfaceVariant,
          onTap: onComment ?? () {},
        ),
        _ActionButton(
          icon: isFavorited ? Icons.favorite : Icons.favorite_outline,
          label: _formatCount(likeCount),
          style: style,
          color: isFavorited ? colorScheme.error : colorScheme.onSurfaceVariant,
          onTap: onLike ?? () {},
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count <= 0) return '';
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextStyle? style;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.style,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = color.withValues(alpha: 0.08);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(label, style: style),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
