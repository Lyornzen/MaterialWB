import 'package:material_weibo/domain/entities/comment.dart';
import 'user_model.dart';

/// 评论数据模型
class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.text,
    required super.user,
    required super.createdAt,
    super.likeCount,
    super.replyComment,
    super.picUrl,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    CommentModel? reply;
    if (json['reply_comment'] != null) {
      reply = CommentModel.fromJson(json['reply_comment']);
    }

    // 解析评论配图（图片回复）
    // PC web API 格式: {"pic": {"pid": "...", "url": "https://...", "large": {"url": "..."}}}
    // 也可能是字符串 URL
    String? picUrl;
    final pic = json['pic'];
    if (pic is Map<String, dynamic>) {
      // 优先取 large 大图
      final large = pic['large'];
      if (large is Map<String, dynamic> && large['url'] != null) {
        picUrl = large['url'] as String;
      } else {
        picUrl = pic['url'] as String?;
      }
    } else if (pic is String && pic.isNotEmpty) {
      picUrl = pic;
    }

    // 也检查 url_struct 中的图片
    if (picUrl == null && json['url_struct'] is List) {
      for (final urlItem in json['url_struct']) {
        if (urlItem is Map<String, dynamic>) {
          final oriUrl =
              urlItem['ori_url'] ?? urlItem['long_url'] ?? urlItem['url_title'];
          if (oriUrl is String &&
              (oriUrl.contains('.jpg') ||
                  oriUrl.contains('.png') ||
                  oriUrl.contains('.gif') ||
                  oriUrl.contains('.webp'))) {
            picUrl = oriUrl;
            break;
          }
        }
      }
    }

    return CommentModel(
      id: (json['id'] ?? json['idstr'] ?? '').toString(),
      text: json['text'] ?? '',
      user: json['user'] != null
          ? UserModel.fromJson(json['user'])
          : const UserModel(id: '0', screenName: '未知用户', profileImageUrl: ''),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      likeCount: json['like_count'] ?? json['like_counts'] ?? 0,
      replyComment: reply,
      picUrl: picUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'user': (user as UserModel).toJson(),
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
      if (picUrl != null) 'pic_url': picUrl,
    };
  }
}
