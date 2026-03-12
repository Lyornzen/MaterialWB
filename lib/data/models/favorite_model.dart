import 'package:material_weibo/domain/entities/favorite.dart';
import 'weibo_post_model.dart';

/// 收藏数据模型
class FavoriteModel extends Favorite {
  const FavoriteModel({
    required super.id,
    required super.post,
    required super.favoritedAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: (json['status']?['id'] ?? '').toString(),
      post: WeiboPostModel.fromJson(json['status'] ?? json),
      favoritedAt:
          DateTime.tryParse(json['favorited_time'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': (post as WeiboPostModel).toJson(),
      'favorited_time': favoritedAt.toIso8601String(),
    };
  }
}
