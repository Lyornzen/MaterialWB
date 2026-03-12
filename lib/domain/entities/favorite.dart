import 'package:equatable/equatable.dart';
import 'weibo_post.dart';

/// 收藏实体
class Favorite extends Equatable {
  final String id;
  final WeiboPost post;
  final DateTime favoritedAt;

  const Favorite({
    required this.id,
    required this.post,
    required this.favoritedAt,
  });

  @override
  List<Object?> get props => [id];
}
