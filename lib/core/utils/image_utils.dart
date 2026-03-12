/// 微博图片 URL 工具
class WeiboImageUtils {
  WeiboImageUtils._();

  /// 微博图片质量枚举
  static const String thumbnail = 'thumbnail'; // 缩略图 ~120px
  static const String bmiddle = 'bmiddle'; // 中等 ~440px
  static const String large = 'large'; // 大图 ~1080px
  static const String original = 'original'; // 原图

  /// 将图片 URL 转换为指定质量
  /// 微博图片 URL 格式: https://wx1.sinaimg.cn/{quality}/{pic_id}.jpg
  static String convertQuality(String url, String quality) {
    final qualityPattern = RegExp(
      r'/(thumbnail|bmiddle|large|original|orj360|orj480|mw690|mw1024)/',
    );
    if (qualityPattern.hasMatch(url)) {
      return url.replaceFirst(qualityPattern, '/$quality/');
    }
    return url;
  }

  /// 获取缩略图 URL
  static String getThumbnail(String url) => convertQuality(url, thumbnail);

  /// 获取中等质量 URL
  static String getMedium(String url) => convertQuality(url, bmiddle);

  /// 获取大图 URL
  static String getLarge(String url) => convertQuality(url, large);

  /// 获取原图 URL
  static String getOriginal(String url) => convertQuality(url, original);

  /// 根据显示宽度选择合适的图片质量
  static String getOptimalUrl(String url, double displayWidth) {
    if (displayWidth <= 120) return getThumbnail(url);
    if (displayWidth <= 440) return getMedium(url);
    if (displayWidth <= 1080) return getLarge(url);
    return getOriginal(url);
  }

  /// 判断 URL 是否为 GIF 图片
  static bool isGif(String url) {
    return url.toLowerCase().endsWith('.gif');
  }

  /// 从 pic_id 构建图片 URL
  static String buildUrl(String picId, {String quality = bmiddle}) {
    return 'https://wx1.sinaimg.cn/$quality/$picId.jpg';
  }
}
