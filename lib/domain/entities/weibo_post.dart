import 'package:equatable/equatable.dart';
import 'user.dart';

/// 微博帖子实体
class WeiboPost extends Equatable {
  final String id;
  final String text;
  final String? rawText;
  final String? fullText;
  final WeiboUser user;
  final DateTime createdAt;
  final int repostsCount;
  final int commentsCount;
  final int attitudesCount;
  final List<String> imageUrls;
  final String? videoUrl;
  final String? videoThumbnailUrl;
  final WeiboPost? retweetedStatus;
  final String? source;
  final bool? favorited;
  final bool isLongText;

  const WeiboPost({
    required this.id,
    required this.text,
    this.rawText,
    this.fullText,
    required this.user,
    required this.createdAt,
    this.repostsCount = 0,
    this.commentsCount = 0,
    this.attitudesCount = 0,
    this.imageUrls = const [],
    this.videoUrl,
    this.videoThumbnailUrl,
    this.retweetedStatus,
    this.source,
    this.favorited,
    this.isLongText = false,
  });

  @override
  List<Object?> get props => [id];
}
