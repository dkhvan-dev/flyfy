import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
