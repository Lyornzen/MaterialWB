import 'package:material_weibo/domain/entities/weibo_post.dart';
import 'user_model.dart';

/// 微博帖子数据模型
class WeiboPostModel extends WeiboPost {
  const WeiboPostModel({
    required super.id,
    required super.text,
    super.rawText,
    required super.user,
    required super.createdAt,
    super.repostsCount,
    super.commentsCount,
    super.attitudesCount,
    super.imageUrls,
    super.videoUrl,
    super.retweetedStatus,
    super.source,
    super.favorited,
  });

  factory WeiboPostModel.fromJson(Map<String, dynamic> json) {
    // 解析图片列表
    List<String> images = [];
    if (json['pic_urls'] != null) {
      images = (json['pic_urls'] as List)
          .map(
            (pic) =>
                (pic['thumbnail_pic'] as String?)?.replaceAll(
                  'thumbnail',
                  'large',
                ) ??
                '',
          )
          .where((url) => url.isNotEmpty)
          .toList();
    } else if (json['pics'] != null) {
      images = (json['pics'] as List)
          .map((pic) => (pic['large']?['url'] ?? pic['url'] ?? '') as String)
          .where((url) => url.isNotEmpty)
          .toList();
    }

    // 解析视频 URL
    String? videoUrl;
    final pageInfo = json['page_info'];
    if (pageInfo != null && pageInfo['type'] == 'video') {
      final mediaInfo = pageInfo['media_info'] ?? pageInfo['urls'];
      if (mediaInfo != null) {
        videoUrl =
            mediaInfo['mp4_720p_mp4'] ??
            mediaInfo['mp4_hd_mp4'] ??
            mediaInfo['mp4_sd_mp4'] ??
            mediaInfo['stream_url'];
      }
    }

    // 解析转发
    WeiboPostModel? retweet;
    if (json['retweeted_status'] != null) {
      retweet = WeiboPostModel.fromJson(json['retweeted_status']);
    }

    // 解析时间
    DateTime createdAt;
    try {
      final rawDate = json['created_at'] as String? ?? '';
      createdAt = _parseWeiboDate(rawDate);
    } catch (_) {
      createdAt = DateTime.now();
    }

    return WeiboPostModel(
      id: (json['id'] ?? json['idstr'] ?? '').toString(),
      text: json['text'] ?? json['status_text'] ?? '',
      rawText: json['raw_text'] as String?,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'])
          : const UserModel(id: '0', screenName: '未知用户', profileImageUrl: ''),
      createdAt: createdAt,
      repostsCount: json['reposts_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      attitudesCount: json['attitudes_count'] ?? 0,
      imageUrls: images,
      videoUrl: videoUrl,
      retweetedStatus: retweet,
      source: json['source'] as String?,
      favorited: json['favorited'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'raw_text': rawText,
      'user': (user as UserModel).toJson(),
      'created_at': createdAt.toIso8601String(),
      'reposts_count': repostsCount,
      'comments_count': commentsCount,
      'attitudes_count': attitudesCount,
      'pic_urls': imageUrls
          .map((url) => {'thumbnail_pic': url.replaceAll('large', 'thumbnail')})
          .toList(),
      'source': source,
      'favorited': favorited,
      if (retweetedStatus != null)
        'retweeted_status': (retweetedStatus as WeiboPostModel).toJson(),
    };
  }

  /// 微博日期格式解析 (如 "Mon Jan 01 12:00:00 +0800 2024")
  static DateTime _parseWeiboDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();
    // 尝试 ISO 8601 格式
    final iso = DateTime.tryParse(dateStr);
    if (iso != null) return iso;
    // 微博特有格式
    try {
      const months = {
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12,
      };
      final parts = dateStr.split(' ');
      final month = months[parts[1]] ?? 1;
      final day = int.parse(parts[2]);
      final timeParts = parts[3].split(':');
      final year = int.parse(parts[5]);
      return DateTime(
        year,
        month,
        day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (_) {
      return DateTime.now();
    }
  }
}
