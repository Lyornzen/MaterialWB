import 'package:equatable/equatable.dart';

/// 微博用户实体
class WeiboUser extends Equatable {
  final String id;
  final String screenName;
  final String profileImageUrl;
  final String? description;
  final int followersCount;
  final int friendsCount;
  final int statusesCount;
  final bool? verified;
  final String? verifiedReason;
  final String? coverImageUrl;
  final String? gender;
  final String? location;
  final bool? following;

  const WeiboUser({
    required this.id,
    required this.screenName,
    required this.profileImageUrl,
    this.description,
    this.followersCount = 0,
    this.friendsCount = 0,
    this.statusesCount = 0,
    this.verified,
    this.verifiedReason,
    this.coverImageUrl,
    this.gender,
    this.location,
    this.following,
  });

  @override
  List<Object?> get props => [id];
}
