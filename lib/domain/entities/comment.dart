import 'package:equatable/equatable.dart';
import 'user.dart';

/// 评论实体
class Comment extends Equatable {
  final String id;
  final String text;
  final WeiboUser user;
  final DateTime createdAt;
  final int likeCount;
  final Comment? replyComment;

  const Comment({
    required this.id,
    required this.text,
    required this.user,
    required this.createdAt,
    this.likeCount = 0,
    this.replyComment,
  });

  @override
  List<Object?> get props => [id];
}
