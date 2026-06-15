import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'foreign profile renders popular stories and links to user stories',
    () async {
      final profileSource = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final profilePostCardSource = await File(
        'lib/screens/profile/widgets/profile_post_card.dart',
      ).readAsString();
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();
      final storiesScreenSource = await File(
        'lib/screens/stories/stories_screen.dart',
      ).readAsString();
      final apiSource = await File(
        'lib/core/network/post_api.dart',
      ).readAsString();

      expect(
        profileSource,
        contains(
          'static const int _foreignProfilePopularStoriesPreviewLimit = 3;',
        ),
      );
      expect(
        profileSource,
        contains('Future<List<PostVm>>? _foreignPopularStoriesFuture'),
      );
      expect(profileSource, contains('_popularStoriesFutureFor'));
      expect(profileSource, contains('getUserPopularPosts('));
      expect(
        profileSource,
        contains('limit: _foreignProfilePopularStoriesPreviewLimit'),
      );
      expect(profileSource, contains('_ForeignPopularStoriesSection('));
      expect(
        profileSource,
        contains("'/users/\${Uri.encodeComponent(userId)}/posts'"),
      );
      expect(profileSource, contains('profilePopularStoriesTitle'));
      expect(profileSource, contains('profileViewAllStories'));

      expect(profilePostCardSource, contains('class ProfilePostCard'));
      expect(
        profilePostCardSource,
        contains('StoryCoverImage(url: post.coverUrl)'),
      );
      expect(profilePostCardSource, contains('post.stats.views'));
      expect(profilePostCardSource, contains('formatStoryCountCompact'));

      expect(routerSource, contains("path: '/users/:userId/posts'"));
      expect(routerSource, contains('StoriesScreen(authorId: userId)'));

      expect(storiesScreenSource, contains('this.authorId'));
      expect(storiesScreenSource, contains('final String? authorId'));
      expect(storiesScreenSource, contains('authorId: widget.authorId'));
      expect(storiesScreenSource, contains('profileUserStoriesTitle'));

      expect(apiSource, contains('Future<List<PostVm>> getUserPopularPosts'));
      expect(apiSource, contains('Future<PostListPage> getUserPostsPage'));
      expect(apiSource, contains("sort: 'popular_desc'"));
      expect(apiSource, contains('authorId: trimmedUserId'));
    },
  );
}
