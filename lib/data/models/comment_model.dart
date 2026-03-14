import 'package:intl/intl.dart';
import 'package:material_weibo/domain/entities/comment.dart';
import 'user_model.dart';

/// 评论数据模型
class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.text,
    required super.user,
    required super.createdAt,
    super.likeCount,
    super.replyComment,
    super.picUrl,
    super.source,
    super.floorNumber,
  });

  /// 解析微博时间格式
  /// 微博 API 可能返回多种格式：
  /// - ISO 8601: "2025-03-14T12:00:00.000+0800"
  /// - RFC 2822: "Fri Mar 14 12:00:00 +0800 2025"
  static DateTime _parseWeiboDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();

    // 先尝试 ISO 8601
    final iso = DateTime.tryParse(dateStr);
    if (iso != null) return iso;

    // 再尝试微博 RFC 2822 格式: "Fri Mar 14 12:00:00 +0800 2025"
    try {
      final format = DateFormat('EEE MMM dd HH:mm:ss Z yyyy', 'en_US');
      return format.parse(dateStr);
    } catch (_) {}

    // 最后回退
    return DateTime.now();
  }

  /// 从 source 字段提取 IP 属地
  /// 微博 source 格式多样：
  /// - PC web: "来自 北京" 或纯 HTML "<a ...>iPhone客户端</a>"
  /// - 也可能是 "发布于 广东" 这种格式
  static String? _parseSource(dynamic source) {
    if (source == null) return null;
    final str = source.toString().trim();
    if (str.isEmpty) return null;

    // 去除 HTML 标签
    final cleaned = str.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (cleaned.isEmpty) return null;

    return cleaned;
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    CommentModel? reply;
    if (json['reply_comment'] != null) {
      reply = CommentModel.fromJson(json['reply_comment']);
    }

    // 解析评论配图（图片回复）
    // PC web API 格式: {"pic": {"pid": "...", "url": "https://...", "large": {"url": "..."}}}
    // 也可能是字符串 URL
    String? picUrl;
    final pic = json['pic'];
    if (pic is Map<String, dynamic>) {
      // 优先取 large 大图
      final large = pic['large'];
      if (large is Map<String, dynamic> && large['url'] != null) {
        picUrl = large['url'] as String;
      } else {
        picUrl = pic['url'] as String?;
      }
    } else if (pic is String && pic.isNotEmpty) {
      picUrl = pic;
    }

    // 也检查 url_struct 中的图片
    if (picUrl == null && json['url_struct'] is List) {
      for (final urlItem in json['url_struct']) {
        if (urlItem is Map<String, dynamic>) {
          final oriUrl =
              urlItem['ori_url'] ?? urlItem['long_url'] ?? urlItem['url_title'];
          if (oriUrl is String &&
              (oriUrl.contains('.jpg') ||
                  oriUrl.contains('.png') ||
                  oriUrl.contains('.gif') ||
                  oriUrl.contains('.webp'))) {
            picUrl = oriUrl;
            break;
          }
        }
      }
    }

    // 解析 IP 属地 / 来源
    // PC web API 可能在 source 或 region_name 字段
    String? source = _parseSource(json['source']);
    // 部分 API 返回 region_name 字段（如 "发布于 广东"）
    if (source == null && json['region_name'] != null) {
      source = _parseSource(json['region_name']);
    }

    // 解析楼层号
    int? floorNumber;
    if (json['floor_number'] != null) {
      floorNumber = json['floor_number'] is int
          ? json['floor_number']
          : int.tryParse(json['floor_number'].toString());
    }

    return CommentModel(
      id: (json['id'] ?? json['idstr'] ?? '').toString(),
      text: json['text'] ?? '',
      user: json['user'] != null
          ? UserModel.fromJson(json['user'])
          : const UserModel(id: '0', screenName: '未知用户', profileImageUrl: ''),
      createdAt: _parseWeiboDate(json['created_at']),
      likeCount: json['like_count'] ?? json['like_counts'] ?? 0,
      replyComment: reply,
      picUrl: picUrl,
      source: source,
      floorNumber: floorNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'user': (user as UserModel).toJson(),
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
      if (picUrl != null) 'pic_url': picUrl,
      if (source != null) 'source': source,
      if (floorNumber != null) 'floor_number': floorNumber,
    };
  }
}
