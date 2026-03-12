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
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    CommentModel? reply;
    if (json['reply_comment'] != null) {
      reply = CommentModel.fromJson(json['reply_comment']);
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'user': (user as UserModel).toJson(),
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
    };
  }
}
