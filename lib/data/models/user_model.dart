import 'package:material_weibo/domain/entities/user.dart';

/// 用户数据模型 - 处理 JSON 序列化
class UserModel extends WeiboUser {
  const UserModel({
    required super.id,
    required super.screenName,
    required super.profileImageUrl,
    super.description,
    super.followersCount,
    super.friendsCount,
    super.statusesCount,
    super.verified,
    super.verifiedReason,
    super.coverImageUrl,
    super.gender,
    super.location,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['idstr'] ?? '').toString(),
      screenName: json['screen_name'] ?? json['name'] ?? '',
      profileImageUrl:
          json['avatar_hd'] ??
          json['profile_image_url'] ??
          json['avatar_large'] ??
          '',
      description: json['description'] as String?,
      followersCount: json['followers_count'] ?? 0,
      friendsCount: json['friends_count'] ?? 0,
      statusesCount: json['statuses_count'] ?? 0,
      verified: json['verified'] as bool?,
      verifiedReason: json['verified_reason'] as String?,
      coverImageUrl: json['cover_image_phone'] as String?,
      gender: json['gender'] as String?,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'screen_name': screenName,
      'avatar_hd': profileImageUrl,
      'description': description,
      'followers_count': followersCount,
      'friends_count': friendsCount,
      'statuses_count': statusesCount,
      'verified': verified,
      'verified_reason': verifiedReason,
      'cover_image_phone': coverImageUrl,
      'gender': gender,
      'location': location,
    };
  }
}
