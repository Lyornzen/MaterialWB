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

  /// 评论配图 URL（图片回复）
  final String? picUrl;

  /// IP 属地 / 来源（如 "来自 北京"）
  final String? source;

  /// 楼层号
  final int? floorNumber;

  const Comment({
    required this.id,
    required this.text,
    required this.user,
    required this.createdAt,
    this.likeCount = 0,
    this.replyComment,
    this.picUrl,
    this.source,
    this.floorNumber,
  });

  @override
  List<Object?> get props => [id];
}
