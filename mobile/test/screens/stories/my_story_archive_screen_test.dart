import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/story_api.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/features/stories/models/story_vm.dart';
import 'package:inflap/features/stories/story_ui.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/screens/stories/my_story_archive_screen.dart';

void main() {
  testWidgets('my stories screen separates active stories and archive', (
    tester,
  ) async {
    final api = _FakeStoryApi(
      activeStories: [_story(id: 'active-one', caption: 'Сегодня в Дананге')],
      archivedStories: [_story(id: 'archive-one', caption: 'Вчерашний закат')],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MyStoryArchiveScreen(storyApi: api),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Активные'), findsOneWidget);
    expect(find.text('Архив'), findsOneWidget);
    expect(find.text('Сегодня в Дананге'), findsOneWidget);
    expect(find.text('Вчерашний закат'), findsNothing);
    expect(api.activeRequests, 1);
    expect(api.archiveRequests, 0);

    await tester.tap(find.text('Архив'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Сегодня в Дананге'), findsNothing);
    expect(find.text('Вчерашний закат'), findsOneWidget);
    expect(api.activeRequests, 1);
    expect(api.archiveRequests, 1);
  });

  testWidgets('my stories are grouped by publish date and render previews', (
    tester,
  ) async {
    final api = _FakeStoryApi(
      activeStories: [
        _story(
          id: 'published-one',
          caption: 'First day',
          createdAt: DateTime.utc(2026, 6, 14, 8),
          previewFileId: 'inline-preview-one',
        ),
        _story(
          id: 'published-two',
          caption: 'Second day',
          createdAt: DateTime.utc(2026, 6, 13, 8),
          coverImageUrl: '/api/v1/public/files/cover-two/content',
        ),
      ],
      archivedStories: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MyStoryArchiveScreen(storyApi: api),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('14 Jun 2026'), findsOneWidget);
    expect(find.text('13 Jun 2026'), findsOneWidget);
    final previewWidgets = tester.widgetList<StoryCoverImage>(
      find.byType(StoryCoverImage),
    );
    expect(
      previewWidgets.map((widget) => widget.url),
      contains(contains('inline-preview-one')),
    );
    expect(
      previewWidgets.map((widget) => widget.url),
      contains(contains('/api/v1/public/files/cover-two/content')),
    );
  });

  testWidgets('my stories tabs use primary text and empty state has no retry', (
    tester,
  ) async {
    final api = _FakeStoryApi(
      activeStories: const [],
      archivedStories: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MyStoryArchiveScreen(storyApi: api),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final activeTab = tester.widget<Text>(find.text('Активные'));
    final archiveTab = tester.widget<Text>(find.text('Архив'));
    expect(activeTab.style?.color, AppPalette.textPrimary);
    expect(archiveTab.style?.color, AppPalette.textPrimary);
    expect(find.text('Попробовать снова'), findsNothing);
  });
}

class _FakeStoryApi extends StoryApi {
  _FakeStoryApi({required this.activeStories, required this.archivedStories});

  final List<StoryVm> activeStories;
  final List<StoryVm> archivedStories;
  int activeRequests = 0;
  int archiveRequests = 0;

  @override
  Future<StoryListPage> listMyActiveStories({
    int limit = 20,
    int offset = 0,
  }) async {
    activeRequests++;
    return StoryListPage(
      items: activeStories.skip(offset).take(limit).toList(growable: false),
      limit: limit,
      offset: offset,
      hasMore: false,
    );
  }

  @override
  Future<StoryListPage> listMyArchivedStories({
    int limit = 20,
    int offset = 0,
  }) async {
    archiveRequests++;
    return StoryListPage(
      items: archivedStories.skip(offset).take(limit).toList(growable: false),
      limit: limit,
      offset: offset,
      hasMore: false,
    );
  }
}

StoryVm _story({
  required String id,
  required String caption,
  DateTime? createdAt,
  String? coverImageUrl,
  String? previewFileId,
}) {
  final created = createdAt ?? DateTime.utc(2026, 6, 14, 8);
  return StoryVm(
    id: id,
    caption: caption,
    mediaFileId: coverImageUrl == null && previewFileId == null
        ? 'file-$id'
        : '',
    coverFileId: coverImageUrl == null && previewFileId == null
        ? 'file-$id'
        : null,
    coverImageUrl: coverImageUrl,
    mediaType: 'IMAGE',
    contentBlocks: previewFileId == null
        ? const []
        : [
            {
              'type': 'image',
              'image': {'fileId': previewFileId},
            },
          ],
    author: const StoryAuthorVm(
      userId: 'author-one',
      locale: 'ru',
      timezone: 'Asia/Almaty',
    ),
    expiresAt: created.add(const Duration(hours: 24)),
    createdAt: created,
    updatedAt: created,
  );
}
