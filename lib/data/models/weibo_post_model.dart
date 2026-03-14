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
    super.videoThumbnailUrl,
    super.retweetedStatus,
    super.source,
    super.favorited,
  });

  factory WeiboPostModel.fromJson(Map<String, dynamic> json) {
    // 解析图片列表
    List<String> images = [];
    if (json['pic_urls'] != null) {
      // m.weibo.cn 格式: [{"thumbnail_pic": "url"}]
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
    } else if (json['pic_infos'] != null && json['pic_infos'] is Map) {
      // PC web 格式: pic_infos 是 Map<picId, {large: {url}, original: {url}, ...}>
      // 使用 pic_ids 保持顺序，如果存在的话
      final picInfos = json['pic_infos'] as Map<String, dynamic>;
      final picIds = json['pic_ids'] as List?;
      final orderedKeys =
          picIds?.map((e) => e.toString()).toList() ?? picInfos.keys.toList();
      for (final key in orderedKeys) {
        final info = picInfos[key];
        if (info == null) continue;
        final url =
            (info['large']?['url'] ??
                    info['original']?['url'] ??
                    info['mw2000']?['url'] ??
                    '')
                as String;
        if (url.isNotEmpty) images.add(url);
      }
    } else if (json['pics'] != null && json['pics'] is List) {
      // 旧格式: pics 数组 [{large: {url}, url: "..."}]
      images = (json['pics'] as List)
          .map((pic) => (pic['large']?['url'] ?? pic['url'] ?? '') as String)
          .where((url) => url.isNotEmpty)
          .toList();
    } else if (json['pic_ids'] != null &&
        (json['pic_ids'] as List).isNotEmpty) {
      // 仅有 pic_ids，没有 pic_infos/pics — 从 pic_id 构建 URL
      // 格式: https://wx1.sinaimg.cn/large/{pic_id}.jpg
      images = (json['pic_ids'] as List)
          .map((id) => 'https://wx1.sinaimg.cn/large/$id.jpg')
          .toList();
    }

    // 解析视频 URL
    String? videoUrl;
    String? videoThumbnailUrl;
    final pageInfo = json['page_info'];
    if (pageInfo != null && pageInfo['type'] == 'video') {
      videoUrl = _extractVideoUrl(pageInfo);
      // 视频封面图
      videoThumbnailUrl =
          (pageInfo['page_pic']?['url'] ?? pageInfo['page_pic']) as String?;
    }

    // mix_media_info: 新版混合媒体格式（图片+视频混排的轮播帖）
    if (videoUrl == null && json['mix_media_info'] != null) {
      final mixItems = json['mix_media_info']['items'] as List?;
      if (mixItems != null) {
        for (final item in mixItems) {
          if (item['type'] == 'video' || item['type'] == 'pic') {
            final extracted = _extractVideoUrlFromMixItem(item);
            if (extracted != null) {
              videoUrl = extracted;
              videoThumbnailUrl ??=
                  (item['cover']?['url'] ?? item['pic']?['url']) as String?;
              break;
            }
          }
        }
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
      videoThumbnailUrl: videoThumbnailUrl,
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

  /// 检测一条微博 JSON 是否为广告/推广内容
  /// 在解析前调用，以便直接跳过广告帖子
  static bool isAdPost(Map<String, dynamic> json) {
    // 推广标记字段
    if (json['promotion'] != null) return true;
    if (json['ad'] != null) return true;
    if (json['_adInfo'] != null) return true;

    // mblogtype 为广告类型（1 = 推广微博）
    final mblogtype = json['mblogtype'];
    if (mblogtype == 1) return true;

    // 页面信息中的广告标记
    final pageInfo = json['page_info'];
    if (pageInfo != null) {
      if (pageInfo['type'] == 'ad') return true;
      final objectType = pageInfo['object_type'];
      if (objectType != null && objectType.toString().contains('ad')) {
        return true;
      }
    }

    // 微博来源包含推广关键词
    final source = (json['source'] ?? '') as String;
    if (source.contains('广告') ||
        source.contains('推广') ||
        source.contains('粉丝通')) {
      return true;
    }

    // 标题包含推广关键词
    final title = json['title'];
    if (title != null) {
      final titleText =
          (title is Map ? title['text'] : title)?.toString() ?? '';
      if (titleText.contains('广告') ||
          titleText.contains('推广') ||
          titleText.contains('热推')) {
        return true;
      }
    }

    // 存在 admark_info 或 common_struct 中的广告标识
    if (json['admark_info'] != null) return true;
    if (json['common_struct'] != null) {
      final commonStruct = json['common_struct'] as List?;
      if (commonStruct != null) {
        for (final item in commonStruct) {
          if (item['name'] == 'ad' || item['name'] == 'promote') return true;
        }
      }
    }

    return false;
  }

  /// 从 page_info 中提取最佳画质视频 URL
  static String? _extractVideoUrl(Map<String, dynamic> pageInfo) {
    // 1. 尝试 playback_list（PC web 高清格式）
    final playbackList =
        pageInfo['media_info']?['playback_list'] as List? ??
        pageInfo['playback_list'] as List?;
    if (playbackList != null && playbackList.isNotEmpty) {
      // playback_list 按画质从高到低排列
      for (final item in playbackList) {
        final playInfo = item['play_info'];
        if (playInfo != null) {
          final url = playInfo['url'] as String?;
          if (url != null && url.isNotEmpty) return url;
        }
      }
    }

    // 2. 尝试 media_info / urls 中的直链
    final mediaInfo = pageInfo['media_info'] ?? pageInfo['urls'];
    if (mediaInfo != null) {
      // 按画质优先级: 1080p > 720p > HD > SD > stream_url_hd > stream_url
      final url =
          mediaInfo['mp4_1080p_mp4'] ??
          mediaInfo['mp4_720p_mp4'] ??
          mediaInfo['mp4_hd_mp4'] ??
          mediaInfo['hevc_mp4_hd'] ??
          mediaInfo['mp4_sd_mp4'] ??
          mediaInfo['mp4_ld_mp4'] ??
          mediaInfo['stream_url_hd'] ??
          mediaInfo['stream_url'];
      if (url != null && (url as String).isNotEmpty) return url;

      // 3. 尝试 video_details（部分 PC web 格式）
      final videoDetails = mediaInfo['video_details'] as List?;
      if (videoDetails != null) {
        for (final detail in videoDetails) {
          final label = (detail['label'] ?? '').toString();
          // 优先选择 1080p/720p
          if (label.contains('1080') || label.contains('720')) {
            final detailUrl = detail['url'] as String?;
            if (detailUrl != null && detailUrl.isNotEmpty) return detailUrl;
          }
        }
        // 回退到任意可用的 video_detail
        for (final detail in videoDetails) {
          final detailUrl = detail['url'] as String?;
          if (detailUrl != null && detailUrl.isNotEmpty) return detailUrl;
        }
      }
    }

    return null;
  }

  /// 从 mix_media_info 的单个 item 中提取视频 URL
  static String? _extractVideoUrlFromMixItem(Map<String, dynamic> item) {
    // mix item 可能有 video_info 子对象
    final videoInfo = item['video_info'] as Map<String, dynamic>?;
    if (videoInfo != null) {
      // 尝试 playback_list
      final playbackList = videoInfo['playback_list'] as List?;
      if (playbackList != null) {
        for (final pb in playbackList) {
          final url = pb['play_info']?['url'] as String?;
          if (url != null && url.isNotEmpty) return url;
        }
      }
      // 尝试 media_info
      final mediaInfo = videoInfo['media_info'] as Map<String, dynamic>?;
      if (mediaInfo != null) {
        final url =
            mediaInfo['mp4_720p_mp4'] ??
            mediaInfo['mp4_hd_mp4'] ??
            mediaInfo['mp4_sd_mp4'] ??
            mediaInfo['stream_url_hd'] ??
            mediaInfo['stream_url'];
        if (url != null && (url as String).isNotEmpty) return url;
      }
      // 直接 stream_url
      final streamUrl = videoInfo['stream_url'] as String?;
      if (streamUrl != null && streamUrl.isNotEmpty) return streamUrl;
    }

    // 部分 mix item 直接带 url 字段
    final directUrl = item['stream_url'] as String?;
    if (directUrl != null && directUrl.isNotEmpty) return directUrl;

    return null;
  }
}
