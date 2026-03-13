import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:material_weibo/core/utils/html_parser.dart';

/// 富文本内容组件 - 支持话题、@提及、链接的可点击渲染
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
    // 先去除 HTML 标签并解码实体
    final plainText = _stripHtmlTags(htmlText);
    final spans = <InlineSpan>[];

    // 匹配话题 #...# 和 @用户名 和 URL
    final regex = RegExp(
      r'(#[^#]+#)|(@[\w\u4e00-\u9fff\-]+)|(https?://[^\s<>\u4e00-\u9fff]+)',
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
      if (matchStr.startsWith('#')) {
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
    // 跳转到搜索页面，搜索该话题
    // 使用 push 到搜索页面并带上关键词
    context.push('/search?q=${Uri.encodeComponent('#$topic#')}');
  }

  void _onMentionTap(BuildContext context, String username) {
    // @提及点击 - 搜索用户名
    context.push('/search?q=${Uri.encodeComponent('@$username')}');
  }

  void _onLinkTap(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _stripHtmlTags(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }
}
