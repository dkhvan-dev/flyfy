import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'foreign profile renders popular stories and links to user stories',
    () async {
      final profileSource = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final profileStoryCardSource = await File(
        'lib/screens/profile/widgets/profile_story_card.dart',
      ).readAsString();
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();
      final storiesScreenSource = await File(
        'lib/screens/stories/stories_screen.dart',
      ).readAsString();
      final apiSource = await File(
        'lib/core/network/story_api.dart',
      ).readAsString();

      expect(
        profileSource,
        contains(
          'static const int _foreignProfilePopularStoriesPreviewLimit = 3;',
        ),
      );
      expect(
        profileSource,
        contains('Future<List<StoryVm>>? _foreignPopularStoriesFuture'),
      );
      expect(profileSource, contains('_popularStoriesFutureFor'));
      expect(profileSource, contains('getUserPopularStories('));
      expect(
        profileSource,
        contains('limit: _foreignProfilePopularStoriesPreviewLimit'),
      );
      expect(profileSource, contains('_ForeignPopularStoriesSection('));
      expect(
        profileSource,
        contains("'/users/\${Uri.encodeComponent(userId)}/stories'"),
      );
      expect(profileSource, contains('profilePopularStoriesTitle'));
      expect(profileSource, contains('profileViewAllStories'));

      expect(profileStoryCardSource, contains('class ProfileStoryCard'));
      expect(
        profileStoryCardSource,
        contains('StoryCoverImage(url: story.coverUrl)'),
      );
      expect(profileStoryCardSource, contains('story.stats.views'));
      expect(profileStoryCardSource, contains('formatStoryCountCompact'));

      expect(routerSource, contains("path: '/users/:userId/stories'"));
      expect(routerSource, contains('StoriesScreen(authorId: userId)'));

      expect(storiesScreenSource, contains('this.authorId'));
      expect(storiesScreenSource, contains('final String? authorId'));
      expect(storiesScreenSource, contains('authorId: widget.authorId'));
      expect(storiesScreenSource, contains('profileUserStoriesTitle'));

      expect(
        apiSource,
        contains('Future<List<StoryVm>> getUserPopularStories'),
      );
      expect(apiSource, contains('Future<StoryListPage> getUserStoriesPage'));
      expect(apiSource, contains("sort: 'popular_desc'"));
      expect(apiSource, contains('authorId: trimmedUserId'));
    },
  );
}
