import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/features/feed/data/feed_api.dart';
import 'package:inflap/features/feed/models/feed_block_vm.dart';
import 'package:inflap/features/feed/presentation/community_discovery_screen.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('loads communities and opens selected community', (tester) async {
    FeedCommunityVm? openedCommunity;
    final api = _FakeFeedApi(
      pages: [
        CommunityListPageVm(
          items: [
            _community(
              id: 'community-1',
              title: 'Investments',
              description: 'Practical investing guides.',
              followedByViewer: false,
            ),
            _community(
              id: 'community-2',
              title: 'Almaty weekends',
              description: 'Local plans and meetups.',
              followedByViewer: true,
            ),
          ],
          limit: 20,
          offset: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      _discoveryApp(
        api,
        onCommunityOpen: (community) {
          openedCommunity = community;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(api.listCalls, ['::0:20']);
    expect(find.text('Communities'), findsWidgets);
    expect(find.text('Investments'), findsOneWidget);
    expect(find.text('Almaty weekends'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('community-discovery-open-community-1')),
    );
    await tester.pumpAndSettle();

    expect(openedCommunity?.id, 'community-1');
  });

  testWidgets('search submission reloads discovery list in place', (
    tester,
  ) async {
    final submittedSearches = <String?>[];
    final api = _FakeFeedApi(
      onListCommunities:
          ({
            String? topic,
            String? countryCode,
            String? cityId,
            String? search,
            bool excludeFollowed = false,
            bool onlyFollowed = false,
            int limit = 20,
            int offset = 0,
          }) {
            submittedSearches.add(search);
            return Future.value(
              CommunityListPageVm(
                items: [
                  _community(
                    title: search == 'city clubs'
                        ? 'City clubs'
                        : 'Almaty creators',
                  ),
                ],
                limit: limit,
                offset: offset,
              ),
            );
          },
    );

    await tester.pumpWidget(_routerDiscoveryApp(api));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'city clubs');
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();

    expect(find.text('search route'), findsNothing);
    expect(find.text('City clubs'), findsOneWidget);
    expect(submittedSearches, [null, 'city clubs']);
  });

  testWidgets('toggles community follow from discovery list', (tester) async {
    final api = _FakeFeedApi(
      pages: [
        CommunityListPageVm(
          items: [
            _community(
              description: null,
              followedByViewer: false,
              membersCount: 42,
            ),
          ],
          limit: 20,
          offset: 0,
        ),
      ],
    );

    await tester.pumpWidget(_discoveryApp(api));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(api.followedCommunityIds, ['community-1']);
    expect(find.text('Following'), findsOneWidget);
    expect(find.textContaining('43'), findsOneWidget);
    final subscribeEvent = api.trackedEvents.singleWhere(
      (event) =>
          event.eventType == 'subscribe' && event.communityId == 'community-1',
    );
    expect(subscribeEvent.surface, 'content');
    expect(subscribeEvent.tab, 'for_you');
    expect(subscribeEvent.blockType, 'suggested_communities');
    expect(subscribeEvent.metadata, containsPair('action', 'subscribe'));
    expect(subscribeEvent.metadata, containsPair('entityType', 'community'));
    expect(subscribeEvent.metadata, containsPair('entityId', 'community-1'));
    expect(subscribeEvent.metadata, containsPair('topic', 'FINANCE'));
    expect(subscribeEvent.metadata, containsPair('countryCode', 'KZ'));
    expect(subscribeEvent.metadata, containsPair('cityId', 'almaty'));
  });

  testWidgets('shows retryable error state when communities fail to load', (
    tester,
  ) async {
    var attempts = 0;
    final api = _FakeFeedApi(
      onListCommunities:
          ({
            String? topic,
            String? countryCode,
            String? cityId,
            String? search,
            bool excludeFollowed = false,
            bool onlyFollowed = false,
            int limit = 20,
            int offset = 0,
          }) {
            attempts++;
            if (attempts == 1) {
              return Future<CommunityListPageVm>.error(
                Exception('network down'),
              );
            }
            return Future.value(
              CommunityListPageVm(
                items: [_community(title: 'Recovered community')],
                limit: limit,
                offset: offset,
              ),
            );
          },
    );

    await tester.pumpWidget(_discoveryApp(api));
    await tester.pumpAndSettle();

    expect(find.text('Could not load communities'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered community'), findsOneWidget);
  });
}

Widget _discoveryApp(
  FeedApi api, {
  ValueChanged<FeedCommunityVm>? onCommunityOpen,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CommunityDiscoveryScreen(
      feedApi: api,
      onCommunityOpen: onCommunityOpen,
    ),
  );
}

Widget _routerDiscoveryApp(FeedApi api) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => CommunityDiscoveryScreen(feedApi: api),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const Scaffold(body: Text('search route')),
      ),
    ],
  );

  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

FeedCommunityVm _community({
  String id = 'community-1',
  String title = 'Investments',
  String? description = 'Investment conversations.',
  int membersCount = 42,
  int postCount = 12,
  bool followedByViewer = false,
}) {
  return FeedCommunityVm(
    id: id,
    title: title,
    subtitle: description,
    description: description,
    topic: 'FINANCE',
    countryCode: 'KZ',
    cityId: 'almaty',
    cityName: 'Almaty',
    membersCount: membersCount,
    postCount: postCount,
    followedByViewer: followedByViewer,
    postingPolicy: 'OPEN_MEMBERS',
  );
}

class _FakeFeedApi implements FeedApi {
  _FakeFeedApi({List<CommunityListPageVm>? pages, this.onListCommunities})
    : _pages = pages ?? const [];

  final List<CommunityListPageVm> _pages;
  final Future<CommunityListPageVm> Function({
    String? topic,
    String? countryCode,
    String? cityId,
    String? search,
    bool excludeFollowed,
    bool onlyFollowed,
    int limit,
    int offset,
  })?
  onListCommunities;

  final List<String> listCalls = [];
  final List<String> followedCommunityIds = [];
  final List<String> unfollowedCommunityIds = [];
  final List<FeedEventRequest> trackedEvents = [];
  final Map<String, FeedCommunityVm> _overrides = {};

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
    listCalls.add('${topic ?? ''}:${countryCode ?? ''}:$offset:$limit');
    final handler = onListCommunities;
    if (handler != null) {
      return handler(
        topic: topic,
        countryCode: countryCode,
        cityId: cityId,
        search: search,
        excludeFollowed: excludeFollowed,
        onlyFollowed: onlyFollowed,
        limit: limit,
        offset: offset,
      );
    }
    final index = listCalls.length - 1;
    if (index >= _pages.length) {
      return Future.value(
        CommunityListPageVm(items: const [], limit: limit, offset: offset),
      );
    }
    return Future.value(_replaceOverrides(_pages[index]));
  }

  @override
  Future<FeedCommunityVm> followCommunity(String communityId) async {
    followedCommunityIds.add(communityId);
    final current = _findCommunity(communityId);
    final updated = current.copyWith(
      followedByViewer: true,
      membersCount: current.membersCount + 1,
    );
    _overrides[communityId] = updated;
    return updated;
  }

  @override
  Future<FeedCommunityVm> unfollowCommunity(String communityId) async {
    unfollowedCommunityIds.add(communityId);
    final current = _findCommunity(communityId);
    final updated = current.copyWith(
      followedByViewer: false,
      membersCount: current.membersCount - 1,
    );
    _overrides[communityId] = updated;
    return updated;
  }

  CommunityListPageVm _replaceOverrides(CommunityListPageVm page) {
    return CommunityListPageVm(
      items: [
        for (final community in page.items)
          _overrides[community.id] ?? community,
      ],
      limit: page.limit,
      offset: page.offset,
    );
  }

  FeedCommunityVm _findCommunity(String communityId) {
    final overridden = _overrides[communityId];
    if (overridden != null) {
      return overridden;
    }
    for (final page in _pages) {
      for (final community in page.items) {
        if (community.id == communityId) {
          return community;
        }
      }
    }
    return _community(id: communityId);
  }

  @override
  Future<FeedCommunityVm> getCommunity(String communityId) {
    throw UnimplementedError();
  }

  @override
  Future<FeedPageVm> getFeed({
    String surface = 'home',
    String tab = 'for_you',
    String? cursor,
    String? countryCode,
    String? cityId,
    int limit = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> trackFeedEvents(List<FeedEventRequest> events) async {
    trackedEvents.addAll(events);
    return events.length;
  }
}
