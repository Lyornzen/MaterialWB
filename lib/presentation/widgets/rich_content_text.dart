import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// 富文本内容组件 - 支持话题、@提及、链接、emoji 的可点击渲染
class RichContentText extends StatelessWidget {
  final String htmlText;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const RichContentText({
    super.key,
    required this.htmlText,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultStyle = style ?? Theme.of(context).textTheme.bodyMedium!;
    final linkStyle = defaultStyle.copyWith(color: colorScheme.primary);

    final spans = _buildSpans(context, defaultStyle, linkStyle);

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  List<InlineSpan> _buildSpans(
    BuildContext context,
    TextStyle defaultStyle,
    TextStyle linkStyle,
  ) {
    // 先将 <img> 标签中的 alt 属性提取为文本（保留 emoji 如 [笑cry]）
    // 然后去除剩余 HTML 标签并解码实体
    final plainText = _processHtmlToPlainText(htmlText);
    final spans = <InlineSpan>[];

    // 匹配: emoji [xxx]、话题 #...#、@用户名、URL
    final regex = RegExp(
      r'(\[[^\[\]]+\])|(#[^#]+#)|(@[\w\u4e00-\u9fff\-]+)|(https?://[^\s<>\u4e00-\u9fff]+)',
    );

    int lastEnd = 0;
    for (final match in regex.allMatches(plainText)) {
      // 添加普通文本
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: plainText.substring(lastEnd, match.start),
            style: defaultStyle,
          ),
        );
      }

      final matchStr = match.group(0)!;
      if (match.group(1) != null) {
        // Emoji 如 [笑cry] — 用普通样式显示
        spans.add(TextSpan(text: matchStr, style: defaultStyle));
      } else if (matchStr.startsWith('#')) {
        // 话题
        final topic = matchStr.substring(1, matchStr.length - 1);
        spans.add(
          TextSpan(
            text: matchStr,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _onTopicTap(context, topic),
          ),
        );
      } else if (matchStr.startsWith('@')) {
        // @提及
        spans.add(
          TextSpan(
            text: matchStr,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _onMentionTap(context, matchStr.substring(1)),
          ),
        );
      } else {
        // URL 链接
        spans.add(
          TextSpan(
            text: '网页链接',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _onLinkTap(matchStr),
          ),
        );
      }
      lastEnd = match.end;
    }

    // 添加剩余文本
    if (lastEnd < plainText.length) {
      spans.add(
        TextSpan(text: plainText.substring(lastEnd), style: defaultStyle),
      );
    }

    return spans;
  }

  void _onTopicTap(BuildContext context, String topic) {
    context.push('/search?q=${Uri.encodeComponent('#$topic#')}');
  }

  void _onMentionTap(BuildContext context, String username) {
    context.push('/search?q=${Uri.encodeComponent('@$username')}');
  }

  void _onLinkTap(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 将 HTML 转为纯文本，但保留 emoji 的 alt 文本（如 [笑cry]）
  /// 微博 emoji 格式: <span class="url-icon"><img alt="[emoji]" src="..."></span>
  /// 或直接: <img alt="[emoji]" src="...">
  static String processHtmlToPlainText(String htmlString) {
    return _processHtmlToPlainText(htmlString);
  }

  static String _processHtmlToPlainText(String htmlString) {
    // Step 1: 将 <img> 标签替换为其 alt 属性值
    // 匹配 <img ... alt="[xxx]" ... > 或 <img ... alt="[xxx]" ... />
    var result = htmlString.replaceAllMapped(
      RegExp(r'<img[^>]*alt="([^"]*)"[^>]*/?>'),
      (match) => match.group(1) ?? '',
    );

    // Step 2: 将 <br> / <br/> 替换为换行
    result = result.replaceAll(RegExp(r'<br\s*/?>'), '\n');

    // Step 3: 去除剩余 HTML 标签
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');

    // Step 4: 解码 HTML 实体
    result = result
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    return result.trim();
  }
}
