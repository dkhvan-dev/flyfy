import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/feed/widgets/story_tray_block.dart';
import 'package:inflap/features/stories/models/story_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'own stories stay inside your story circle and plus opens camera',
    (tester) async {
      var createCount = 0;
      StoryVm? openedStory;
      int? openedIndex;
      List<StoryVm>? openedStories;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StoryTrayBlock(
              viewerUserId: 'viewer',
              viewerInitials: 'ME',
              onCreateStory: () => createCount += 1,
              onStoryOpen: (story, stories, index) {
                openedStory = story;
                openedStories = stories;
                openedIndex = index;
              },
              stories: [
                _story('own-unseen', authorUserId: 'viewer'),
                _story('own-seen', authorUserId: 'viewer', seenByViewer: true),
                _story('other-story', authorUserId: 'other'),
              ],
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('open-feed-tray-story-own-unseen')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('open-feed-tray-story-own-seen')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('open-feed-tray-story-other-story')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('feed-tray-story-seen-own-seen')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('open-feed-create-story')));
      await tester.pump();

      expect(createCount, 0);
      expect(openedStory?.id, 'own-unseen');
      expect(openedIndex, 0);
      expect(openedStories?.map((story) => story.id), [
        'own-unseen',
        'own-seen',
      ]);

      await tester.tap(
        find.byKey(const ValueKey('open-feed-create-story-plus')),
      );
      await tester.pump();

      expect(createCount, 1);
    },
  );

  testWidgets('groups other stories by author and hides inactive authors', (
    tester,
  ) async {
    StoryVm? openedStory;
    List<StoryVm>? openedStories;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StoryTrayBlock(
            viewerUserId: 'viewer',
            onCreateStory: () {},
            onStoryOpen: (story, stories, index) {
              openedStory = story;
              openedStories = stories;
            },
            stories: [
              _story(
                'author-old',
                authorUserId: 'author',
                createdAt: DateTime.utc(2026, 1, 1),
              ),
              _story(
                'author-new',
                authorUserId: 'author',
                createdAt: DateTime.utc(2026, 1, 2),
              ),
              _story(
                'expired',
                authorUserId: 'expired-author',
                expiresAt: DateTime.utc(2020),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('open-feed-tray-story-author-new')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('open-feed-tray-story-author-old')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('open-feed-tray-story-expired')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('open-feed-tray-story-author-new')),
    );
    await tester.pump();

    expect(openedStory?.id, 'author-new');
    expect(openedStories?.map((story) => story.id), [
      'author-new',
      'author-old',
    ]);
  });

  testWidgets('orders unseen system stories before seen story circles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StoryTrayBlock(
            viewerUserId: 'viewer',
            onCreateStory: () {},
            stories: [
              _story(
                'seen-friend',
                authorUserId: 'friend',
                nickname: 'Friend',
                seenByViewer: true,
                views: 900,
              ),
              _story(
                'unseen-friend',
                authorUserId: 'popular',
                nickname: 'Popular',
                views: 1,
              ),
              _story(
                'system-unseen',
                authorUserId: 'system',
                nickname: 'Inflap',
                views: 1,
              ),
            ],
          ),
        ),
      ),
    );

    final systemX = tester
        .getTopLeft(
          find.byKey(const ValueKey('open-feed-tray-story-system-unseen')),
        )
        .dx;
    final unseenX = tester
        .getTopLeft(
          find.byKey(const ValueKey('open-feed-tray-story-unseen-friend')),
        )
        .dx;
    final seenX = tester
        .getTopLeft(
          find.byKey(const ValueKey('open-feed-tray-story-seen-friend')),
        )
        .dx;

    expect(systemX, lessThan(unseenX));
    expect(unseenX, lessThan(seenX));
  });
}

StoryVm _story(
  String id, {
  required String authorUserId,
  bool seenByViewer = false,
  String? nickname,
  DateTime? createdAt,
  DateTime? expiresAt,
  int views = 1,
}) {
  final now = createdAt ?? DateTime.utc(2026, 1, 1);
  return StoryVm(
    id: id,
    slug: id,
    title: id,
    excerpt: 'Story $id',
    category: 'JOURNAL',
    status: 'PUBLISHED',
    tags: const ['travel'],
    stats: StoryStatsVm(views: views, likes: 0, comments: 0, shares: 0),
    author: StoryAuthorVm(
      userId: authorUserId,
      locale: 'en',
      timezone: 'Asia/Almaty',
      nickname: nickname ?? authorUserId,
    ),
    likedByViewer: false,
    seenByViewer: seenByViewer,
    expiresAt: expiresAt ?? DateTime.utc(2027),
    shareUrl: 'https://inflap.test/stories/$id',
    createdAt: now,
    updatedAt: now,
  );
}
