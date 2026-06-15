import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/feed/data/feed_api.dart';
import 'package:inflap/features/feed/models/feed_block_vm.dart';
import 'package:inflap/features/feed/widgets/contextual_story_tray.dart';
import 'package:inflap/features/stories/models/story_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('loads story circles from the requested feed surface', (
    tester,
  ) async {
    final api = _FakeFeedApi(
      page: FeedPageVm(
        items: [
          FeedBlockVm(
            id: 'posts:tray:activities',
            type: FeedBlockType.storiesTray,
            stories: [_story(id: 'story-1', nickname: 'devdone')],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SurfaceStoryTray(
            surface: 'activities',
            feedApi: api,
            viewerUserId: 'viewer-user',
            viewerInitials: 'V',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.calls, [
      const _FeedCall(surface: 'activities', tab: 'for_you', limit: 10),
    ]);
    expect(
      find.byKey(const ValueKey('feed-stories-circle-tray')),
      findsOneWidget,
    );
    expect(find.text('devdone'), findsOneWidget);
  });
}

StoryVm _story({required String id, required String nickname}) {
  final now = DateTime.utc(2026, 6, 14, 10);
  return StoryVm(
    id: id,
    caption: 'Story',
    mediaFileId: 'file-$id',
    mediaType: 'IMAGE',
    author: StoryAuthorVm(
      userId: 'author-$id',
      nickname: nickname,
      locale: 'ru',
      timezone: 'Asia/Almaty',
    ),
    expiresAt: now.add(const Duration(hours: 24)),
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeFeedApi implements FeedApi {
  _FakeFeedApi({required this.page});

  final FeedPageVm page;
  final List<_FeedCall> calls = [];

  @override
  Future<FeedPageVm> getFeed({
    String surface = 'home',
    String tab = 'for_you',
    String? cursor,
    String? countryCode,
    String? cityId,
    int limit = 20,
  }) async {
    calls.add(_FeedCall(surface: surface, tab: tab, limit: limit));
    return page;
  }

  @override
  Future<FeedCommunityVm> getCommunity(String communityId) {
    throw UnimplementedError();
  }

  @override
  Future<CommunityListPageVm> listCommunities({
    String? topic,
    String? countryCode,
    String? cityId,
    String? search,
    bool excludeFollowed = false,
    bool onlyFollowed = false,
    int limit = 20,
    int offset = 0,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FeedCommunityVm> followCommunity(String communityId) {
    throw UnimplementedError();
  }

  @override
  Future<FeedCommunityVm> unfollowCommunity(String communityId) {
    throw UnimplementedError();
  }

  @override
  Future<int> trackFeedEvents(List<FeedEventRequest> events) async {
    return events.length;
  }
}

class _FeedCall {
  const _FeedCall({
    required this.surface,
    required this.tab,
    required this.limit,
  });

  final String surface;
  final String tab;
  final int limit;

  @override
  bool operator ==(Object other) {
    return other is _FeedCall &&
        other.surface == surface &&
        other.tab == tab &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(surface, tab, limit);

  @override
  String toString() {
    return '_FeedCall(surface: $surface, tab: $tab, limit: $limit)';
  }
}
