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
  final int? floorNumber;
  final String? ipLocation;

  /// 评论配图 URL（图片回复）
  final String? picUrl;

  const Comment({
    required this.id,
    required this.text,
    required this.user,
    required this.createdAt,
    this.likeCount = 0,
    this.replyComment,
    this.floorNumber,
    this.ipLocation,
    this.picUrl,
  });

  @override
  List<Object?> get props => [id];
}
