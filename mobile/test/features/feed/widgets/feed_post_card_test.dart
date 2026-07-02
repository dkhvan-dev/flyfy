import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/features/feed/widgets/feed_post_card.dart';
import 'package:inflap/features/stories/models/post_vm.dart';

void main() {
  testWidgets('opens regular posts from the feed card', (tester) async {
    PostVm? openedPost;
    final post = _post('article-1');

    await tester.pumpWidget(
      _app(
        FeedPostCard(
          post: post,
          onOpen: (value) {
            openedPost = value;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-feed-post-article-1')));
    await tester.pumpAndSettle();

    expect(openedPost?.id, 'article-1');
  });

  testWidgets('opens quick posts from the feed card for community routing', (
    tester,
  ) async {
    PostVm? openedPost;
    final post = _post('quick-1', postProfileKey: 'quick_post_v1');

    await tester.pumpWidget(
      _app(
        FeedPostCard(
          post: post,
          onOpen: (value) {
            openedPost = value;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-feed-post-quick-1')));
    await tester.pumpAndSettle();

    expect(openedPost?.id, 'quick-1');
  });

  testWidgets(
    'adaptive v2 feed cards disable external shadows in light theme',
    (tester) async {
      late FeedPostCardStyle lightStyle;
      late FeedPostCardStyle darkStyle;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppDesignSystem.lightTheme(),
          home: Builder(
            builder: (context) {
              lightStyle = FeedPostCardStyle.v2(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        Theme(
          data: AppDesignSystem.darkTheme(),
          child: Builder(
            builder: (context) {
              darkStyle = FeedPostCardStyle.v2(context);
              return const Directionality(
                textDirection: TextDirection.ltr,
                child: SizedBox.shrink(),
              );
            },
          ),
        ),
      );

      expect(lightStyle.shadowColor, Colors.transparent);
      expect(lightStyle.glowColor, Colors.transparent);
      expect(lightStyle.coverScrimGradient, isNull);
      expect(lightStyle.hasShadow, isFalse);
      expect(darkStyle.shadowColor, isNot(Colors.transparent));
      expect(darkStyle.glowColor, isNot(Colors.transparent));
      expect(darkStyle.coverScrimGradient, isNotNull);
      expect(darkStyle.hasShadow, isTrue);
    },
  );

  test(
    'feed post card only paints external shadows and image scrims when style allows it',
    () async {
      final source = await File(
        'lib/features/feed/widgets/feed_post_card.dart',
      ).readAsString();

      expect(source, contains('required this.hasShadow'));
      expect(source, contains('final bool hasShadow'));
      expect(source, contains('required this.coverScrimGradient'));
      expect(source, contains('final Gradient? coverScrimGradient'));
      expect(source, contains('boxShadow: style.hasShadow'));
      expect(source, contains('if (style.coverScrimGradient != null)'));
    },
  );

  test('feed post card defaults to adaptive V2 colors', () async {
    final source = await File(
      'lib/features/feed/widgets/feed_post_card.dart',
    ).readAsString();

    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('widget.style ?? FeedPostCardStyle.v2(context)'));
    expect(source, contains('color: foreground'));
    expect(source, isNot(contains('FeedPostCardStyle.legacy')));
    expect(source, isNot(contains('AppPalette.')));
  });
}

Widget _app(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

PostVm _post(String id, {String? postProfileKey}) {
  return PostVm(
    id: id,
    slug: id,
    title: 'Post $id',
    excerpt: 'Post excerpt',
    category: 'JOURNAL',
    status: 'PUBLISHED',
    postProfileKey: postProfileKey,
    tags: const [],
    stats: PostStatsVm(views: 10, likes: 1, comments: 2, shares: 0),
    author: PostAuthorVm(
      userId: 'author-1',
      nickname: 'Author',
      locale: 'en',
      timezone: 'Asia/Almaty',
    ),
    likedByViewer: false,
    shareUrl: 'https://inflap.test/posts/$id',
    createdAt: DateTime.utc(2026, 6, 13),
    updatedAt: DateTime.utc(2026, 6, 13),
  );
}
