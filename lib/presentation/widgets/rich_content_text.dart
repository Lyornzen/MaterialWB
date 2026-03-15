import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';

/// 富文本内容组件 - 支持微博表情、话题、@提及、链接
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

    return Text.rich(
      TextSpan(children: _buildSpans(context, defaultStyle, linkStyle)),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  List<InlineSpan> _buildSpans(
    BuildContext context,
    TextStyle defaultStyle,
    TextStyle linkStyle,
  ) {
    final fragment = html_parser.parseFragment(htmlText);
    final spans = <InlineSpan>[];
    for (final node in fragment.nodes) {
      spans.addAll(_buildNodeSpans(context, node, defaultStyle, linkStyle));
    }
    return spans;
  }

  List<InlineSpan> _buildNodeSpans(
    BuildContext context,
    dom.Node node,
    TextStyle defaultStyle,
    TextStyle linkStyle,
  ) {
    if (node is dom.Text) {
      return _buildTokenizedText(context, node.text, defaultStyle, linkStyle);
    }

    if (node is! dom.Element) {
      return const [];
    }

    if (node.localName == 'br') {
      return [TextSpan(text: '\n', style: defaultStyle)];
    }

    if (node.localName == 'img') {
      return [_buildEmojiSpan(node, defaultStyle)];
    }

    if (node.localName == 'a') {
      final href = node.attributes['href'];
      final text = node.text;
      if (href != null && href.isNotEmpty) {
        return [
          TextSpan(
            text: text.isNotEmpty ? text : '网页链接',
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = () => _onLinkTap(href),
          ),
        ];
      }
    }

    final spans = <InlineSpan>[];
    for (final child in node.nodes) {
      spans.addAll(_buildNodeSpans(context, child, defaultStyle, linkStyle));
    }
    return spans;
  }

  InlineSpan _buildEmojiSpan(dom.Element element, TextStyle defaultStyle) {
    final alt = element.attributes['alt'] ?? '';
    final src = element.attributes['src'] ?? '';
    final normalizedSrc = src.startsWith('//') ? 'https:$src' : src;
    if (normalizedSrc.isEmpty) {
      return TextSpan(text: alt, style: defaultStyle);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: CachedNetworkImage(
          imageUrl: normalizedSrc,
          width: (defaultStyle.fontSize ?? 14) * 1.35,
          height: (defaultStyle.fontSize ?? 14) * 1.35,
          fit: BoxFit.contain,
          errorWidget: (_, _, _) => Text(alt, style: defaultStyle),
        ),
      ),
    );
  }

  List<InlineSpan> _buildTokenizedText(
    BuildContext context,
    String plainText,
    TextStyle defaultStyle,
    TextStyle linkStyle,
  ) {
    final spans = <InlineSpan>[];
    final regex = RegExp(
      r'(#[^#\n]+#)|(@[\w\u4e00-\u9fff\-\_]+)|(https?://[^\s<>\u4e00-\u9fff]+)',
    );

    var lastEnd = 0;
    for (final match in regex.allMatches(plainText)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: _decodeEntities(plainText.substring(lastEnd, match.start)),
            style: defaultStyle,
          ),
        );
      }

      final matchStr = match.group(0)!;
      if (matchStr.startsWith('#')) {
        final topic = matchStr.substring(1, matchStr.length - 1);
        spans.add(
          TextSpan(
            text: _decodeEntities(matchStr),
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _onTopicTap(context, topic),
          ),
        );
      } else if (matchStr.startsWith('@')) {
        final username = matchStr.substring(1);
        spans.add(
          TextSpan(
            text: _decodeEntities(matchStr),
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _onMentionTap(context, username),
          ),
        );
      } else {
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

    if (lastEnd < plainText.length) {
      spans.add(
        TextSpan(
          text: _decodeEntities(plainText.substring(lastEnd)),
          style: defaultStyle,
        ),
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
    final normalizedUrl = url.startsWith('//') ? 'https:$url' : url;
    final uri = Uri.tryParse(normalizedUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 将 HTML 转为纯文本，但保留 emoji 的 alt 文本（如 [笑cry]）
  static String processHtmlToPlainText(String htmlString) {
    var result = htmlString
        .replaceAllMapped(
          RegExp(r'<img[^>]*alt="([^"]*)"[^>]*/?>'),
          (match) => match.group(1) ?? '',
        )
        .replaceAllMapped(
          RegExp(r"<img[^>]*alt='([^']*)'[^>]*/?>"),
          (match) => match.group(1) ?? '',
        );
    result = result.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');
    return _decodeEntities(result).trim();
  }

  static String _decodeEntities(String input) {
    return input
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }
}
