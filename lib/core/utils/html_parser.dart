import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

/// 微博 HTML 内容解析工具
class WeiboHtmlParser {
  WeiboHtmlParser._();

  /// 剥离所有 HTML 标签，返回纯文本
  static String stripTags(String htmlString) {
    final document = html_parser.parseFragment(htmlString);
    return _extractText(document).trim();
  }

  /// 提取所有 @用户名 提及
  static List<String> extractMentions(String htmlString) {
    final mentions = <String>[];
    final regex = RegExp(r'@([\w\u4e00-\u9fff]+)');
    for (final match in regex.allMatches(htmlString)) {
      if (match.group(1) != null) {
        mentions.add(match.group(1)!);
      }
    }
    return mentions;
  }

  /// 提取所有 #话题#
  static List<String> extractTopics(String htmlString) {
    final topics = <String>[];
    final regex = RegExp(r'#(.+?)#');
    for (final match in regex.allMatches(htmlString)) {
      if (match.group(1) != null) {
        topics.add(match.group(1)!);
      }
    }
    return topics;
  }

  /// 提取所有链接
  static List<String> extractLinks(String htmlString) {
    final links = <String>[];
    final document = html_parser.parseFragment(htmlString);
    for (final element in document.querySelectorAll('a[href]')) {
      final href = element.attributes['href'];
      if (href != null && href.isNotEmpty) {
        links.add(href);
      }
    }
    return links;
  }

  static String _extractText(Node node) {
    if (node is Text) {
      return node.data;
    }
    if (node is Element) {
      if (node.localName == 'br') return '\n';
      return node.nodes.map(_extractText).join();
    }
    return node.nodes.map(_extractText).join();
  }
}
