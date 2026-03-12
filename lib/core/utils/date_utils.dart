import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

/// 日期/时间格式化工具
class WeiboDateUtils {
  WeiboDateUtils._();

  /// 格式化为相对时间（如 "3 分钟前"）
  static String formatRelative(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'zh_CN');
  }

  /// 格式化为完整日期时间（如 "2025-03-12 14:30"）
  static String formatFull(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  /// 格式化为简短日期（如 "3月12日"）
  static String formatShort(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.year == now.year) {
      return DateFormat('M月d日').format(dateTime);
    }
    return DateFormat('yyyy年M月d日').format(dateTime);
  }

  /// 智能格式化：24h 内显示相对时间，否则显示日期
  static String formatSmart(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inHours < 24) {
      return formatRelative(dateTime);
    }
    return formatShort(dateTime);
  }
}
