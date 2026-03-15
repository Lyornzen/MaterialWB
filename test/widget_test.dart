import 'package:flutter_test/flutter_test.dart';
import 'package:material_weibo/core/constants/login_method.dart';
import 'package:material_weibo/data/models/user_model.dart';
import 'package:material_weibo/data/models/weibo_post_model.dart';
import 'package:material_weibo/presentation/widgets/rich_content_text.dart';

void main() {
  group('LoginMethod', () {
    test('normalizes legacy oauth sessions to token', () {
      expect(LoginMethod.normalize('oauth'), LoginMethod.token);
      expect(LoginMethod.usesToken('oauth'), isTrue);
      expect(LoginMethod.usesCookie(LoginMethod.cookie), isTrue);
    });
  });

  group('UserModel', () {
    test('parses following flag from multiple shapes', () {
      final first = UserModel.fromJson({
        'id': 1,
        'screen_name': 'Alice',
        'avatar_hd': '',
        'follow': 1,
      });
      final second = UserModel.fromJson({
        'id': 2,
        'screen_name': 'Bob',
        'avatar_hd': '',
        'relation': {'is_follow': true},
      });

      expect(first.following, isTrue);
      expect(second.following, isTrue);
    });
  });

  group('WeiboPostModel', () {
    test('prefers long text fields when available', () {
      final post = WeiboPostModel.fromJson({
        'id': '123',
        'text': 'short text',
        'full_text': 'this is the full text',
        'created_at': '2025-01-01T12:00:00Z',
        'user': {
          'id': 'u1',
          'screen_name': 'tester',
          'avatar_hd': '',
        },
      });

      expect(post.text, 'this is the full text');
      expect(post.fullText, 'this is the full text');
      expect(post.isLongText, isTrue);
    });

    test('extracts video url from page info fallbacks', () {
      final post = WeiboPostModel.fromJson({
        'id': 'video1',
        'text': 'video post',
        'created_at': '2025-01-01T12:00:00Z',
        'user': {
          'id': 'u1',
          'screen_name': 'tester',
          'avatar_hd': '',
        },
        'page_info': {
          'type': 'video',
          'page_pic': {'url': 'https://example.com/cover.jpg'},
          'media_info': {
            'video_url': 'https://example.com/demo.mp4',
          },
        },
      });

      expect(post.videoUrl, 'https://example.com/demo.mp4');
      expect(post.videoThumbnailUrl, 'https://example.com/cover.jpg');
    });
  });

  group('RichContentText', () {
    test('converts emoji image tags to alt text in plain text mode', () {
      const html =
          'hello <img alt="[笑cry]" src="https://example.com/emoji.png" /> world';

      expect(
        RichContentText.processHtmlToPlainText(html),
        'hello [笑cry] world',
      );
    });

    test('supports single quoted alt attributes', () {
      const html =
          "hey <img alt='[doge]' src='https://example.com/doge.png' /> there";

      expect(RichContentText.processHtmlToPlainText(html), 'hey [doge] there');
    });
  });
}
