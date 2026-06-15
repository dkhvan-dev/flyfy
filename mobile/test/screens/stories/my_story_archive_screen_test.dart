import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/story_api.dart';
import 'package:inflap/features/stories/models/story_vm.dart';
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

StoryVm _story({required String id, required String caption}) {
  final createdAt = DateTime.utc(2026, 6, 14, 8);
  return StoryVm(
    id: id,
    caption: caption,
    mediaFileId: 'file-$id',
    coverFileId: 'file-$id',
    coverImageUrl: '',
    mediaType: 'IMAGE',
    author: const StoryAuthorVm(
      userId: 'author-one',
      locale: 'ru',
      timezone: 'Asia/Almaty',
    ),
    expiresAt: createdAt.add(const Duration(hours: 24)),
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
