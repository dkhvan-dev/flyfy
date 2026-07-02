import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/network/post_api.dart';
import 'package:inflap/core/network/reference_api.dart';
import 'package:inflap/features/feed/data/feed_api.dart';
import 'package:inflap/features/feed/data/feed_subscriptions_api.dart';
import 'package:inflap/features/feed/models/feed_block_vm.dart';
import 'package:inflap/features/feed/presentation/feed_screen.dart';
import 'package:inflap/features/feed/widgets/community_discovery_sheet.dart';
import 'package:inflap/features/profile/models/user_profile_vm.dart';
import 'package:inflap/features/stories/models/post_vm.dart';
import 'package:inflap/features/stories/models/story_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/auth_provider.dart';
import 'package:inflap/providers/home_location_provider.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/stories/story_tray_viewer_screen.dart';
import 'package:inflap/shared/reference/app_location_label_resolver.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'feed header keeps notification action clear of device chrome',
    () async {
      final source = await File(
        'lib/features/feed/presentation/feed_screen.dart',
      ).readAsString();

      expect(source, contains('MediaQuery.paddingOf(context).top'));
      expect(source, contains('_feedHeaderTopInsetNudge'));
      expect(
        source,
        contains('toolbarHeight: kToolbarHeight + feedHeaderTopNudge'),
      );
      expect(
        source,
        contains('padding: AppEdgeInsets.only(top: feedHeaderTopNudge)'),
      );
      expect(source, contains('_feedTabsTopGap'));
      expect(source, contains('AppEdgeInsets.fromLTRB('));
    },
  );

  test('feed screen uses adaptive V2 colors only', () async {
    final source = await File(
      'lib/features/feed/presentation/feed_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('AppButtonStyles.primary(colors)'));
    expect(source, contains('colors.background'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, contains('colors.border'));
    expect(source, contains('colors.transparent'));
    expect(source, isNot(contains('AppPalette.')));
  });

  testWidgets('loads for-you feed and renders story and community blocks', (
    tester,
  ) async {
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(_feedPage());
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: _AuthenticatedAuthProvider(),
        child: _feedRouterApp(api, postApi: _PostCreateAllowedApi()),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.calls, [const _FeedCall(surface: 'home', tab: 'for_you')]);
    expect(
      find.byKey(const ValueKey('feed-tray-story-circle-silk-road-notes')),
      findsOneWidget,
    );
    expect(find.text('Your story'), findsOneWidget);
    expect(find.text('Almaty weekend hikes'), findsOneWidget);
    expect(find.text('Almaty'), findsOneWidget);
    expect(find.text('1200 members'), findsOneWidget);
    expect(
      api.trackedEvents.where((event) => event.eventType == 'impression'),
      hasLength(3),
    );
    expect(
      api.trackedEvents.map((event) => event.postId).whereType<String>(),
      contains('hidden-courtyards-of-turkistan'),
    );

    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded).first);
    await tester.pumpAndSettle();

    expect(api.followedCommunityIds, ['community-1']);
    expect(
      api.trackedEvents.any(
        (event) =>
            event.eventType == 'subscribe' &&
            event.communityId == 'community-1',
      ),
      isTrue,
    );
    expect(find.text('Almaty weekend hikes'), findsNothing);

    await tester.tap(
      find.descendant(of: find.byType(Tab), matching: find.text('Following')),
    );
    await tester.pumpAndSettle();

    expect(api.calls.last, const _FeedCall(surface: 'home', tab: 'following'));
  });

  testWidgets('uses feed nav item, plus action, and opens notifications', (
    tester,
  ) async {
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(_feedPage());
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: _AuthenticatedAuthProvider(),
        child: _feedRouterApp(api, postApi: _PostCreateAllowedApi()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.dynamic_feed_rounded), findsOneWidget);
    expect(find.text('QR'), findsNothing);
    expect(find.byIcon(Icons.map_outlined), findsNothing);
    expect(
      find.byKey(const ValueKey('bottom-nav-create-action')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('bottom-nav-create-action')));
    await tester.pumpAndSettle();

    expect(find.text('Create post route'), findsOneWidget);

    GoRouter.of(tester.element(find.text('Create post route'))).go('/');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-feed-notifications')));
    await tester.pumpAndSettle();

    expect(find.text('Notifications route'), findsOneWidget);
  });

  testWidgets('passes selected home location to feed recommendations', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final locationProvider = HomeLocationProvider();
    await locationProvider.selectCity(
      const ReferenceCity(id: 'da-nang', countryCode: 'VN', name: 'Da Nang'),
    );
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(_feedPage());
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<HomeLocationProvider>.value(
        value: locationProvider,
        child: _feedApp(api),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      api.calls.single,
      const _FeedCall(
        surface: 'home',
        tab: 'for_you',
        countryCode: 'VN',
        cityId: 'da-nang',
      ),
    );
  });

  testWidgets('passes city-name-only home location to feed recommendations', (
    tester,
  ) async {
    final locationProvider = _StaticHomeLocationProvider(
      HomeLocationPreference(
        source: HomeLocationSource.detected,
        countryCode: 'KZ',
        cityName: 'Алматы',
        updatedAt: DateTime.utc(2026, 6, 17),
      ),
    );
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(_feedPage());
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<HomeLocationProvider>.value(
        value: locationProvider,
        child: _feedApp(api),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      api.calls.single,
      const _FeedCall(
        surface: 'home',
        tab: 'for_you',
        countryCode: 'KZ',
        cityId: 'almaty',
      ),
    );
  });

  testWidgets(
    'shows my subscriptions on following tab and opens tabbed sheet',
    (tester) async {
      final subscriptionsApi = _FakeFeedSubscriptionsApi(
        FeedSubscriptionsVm(
          communities: [
            FeedCommunityVm(
              id: 'investments',
              title: 'Investments',
              countryCode: 'KZ',
              cityId: 'almaty',
              cityName: 'Almaty',
              membersCount: 6326,
              postCount: 3,
              topic: 'HOBBIES',
              followedByViewer: true,
            ),
          ],
          people: const [
            FeedPersonVm(
              userId: 'friend-1',
              nickname: 'Aigerim',
              relationship: FeedPersonRelationship.friend,
              isOnline: true,
            ),
            FeedPersonVm(
              userId: 'guide-1',
              nickname: 'Guide Nomad',
              relationship: FeedPersonRelationship.following,
            ),
          ],
        ),
      );
      final api = _FakeFeedApi(
        onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
          return Future.value(_feedPage());
        },
      );
      final locationResolver = AppLocationLabelResolver(
        countryLookup: (code, {required lang}) async =>
            ReferenceCountry(code: code, name: 'Kazakhstan'),
        cityLookup: (id, {required lang}) async =>
            ReferenceCity(id: id, countryCode: 'KZ', name: 'Almaty'),
      );

      await tester.pumpWidget(
        _feedRouterApp(
          api,
          subscriptionsApi: subscriptionsApi,
          locationLabelResolver: locationResolver,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(of: find.byType(Tab), matching: find.text('Following')),
      );
      await tester.pumpAndSettle();

      expect(subscriptionsApi.calls, 1);
      final subscriptionsBlock = find.byKey(
        const ValueKey('my-subscriptions-block'),
      );
      expect(
        find.descendant(
          of: subscriptionsBlock,
          matching: find.text('My subscriptions'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: subscriptionsBlock,
          matching: find.text('Investments'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: subscriptionsBlock, matching: find.text('Almaty')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: subscriptionsBlock,
          matching: find.text('6.3K members'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: subscriptionsBlock, matching: find.text('Aigerim')),
        findsOneWidget,
      );
      final feedSortRow = find.byKey(const ValueKey('feed-post-sort-row'));
      expect(feedSortRow, findsOneWidget);
      expect(
        tester.getTopLeft(subscriptionsBlock).dy,
        lessThan(tester.getTopLeft(feedSortRow).dy),
      );

      await tester.tap(find.byKey(const ValueKey('open-my-subscriptions')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('my-subscriptions-tab-communities')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('my-subscriptions-tab-people')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('my-subscriptions-search')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('my-subscriptions-inline-sort')),
        findsOneWidget,
      );
      expect(find.text('Most active'), findsOneWidget);
      expect(find.text('Online first'), findsNothing);
      expect(
        find.byKey(const ValueKey('my-subscriptions-sheet-summary')),
        findsOneWidget,
      );

      final subscriptionsSheet = find.byKey(
        const ValueKey('my-subscriptions-sheet'),
      );
      expect(
        find.descendant(
          of: subscriptionsSheet,
          matching: find.byIcon(Icons.close_rounded),
        ),
        findsNothing,
      );
      final communitySheetTile = find.byKey(
        const ValueKey('my-subscriptions-sheet-community-investments'),
      );
      expect(communitySheetTile, findsOneWidget);
      expect(
        find.descendant(
          of: communitySheetTile,
          matching: find.byIcon(Icons.chevron_right_rounded),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: communitySheetTile,
          matching: find.text('Almaty, Kazakhstan'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: communitySheetTile,
          matching: find.text('6.3K members'),
        ),
        findsOneWidget,
      );
      final communityToggle = find.byKey(
        const ValueKey('my-subscriptions-sheet-toggle-investments'),
      );
      expect(communityToggle, findsOneWidget);
      await tester.tap(communityToggle);
      await tester.pumpAndSettle();

      expect(api.unfollowedCommunityIds, ['investments']);
      expect(communitySheetTile, findsOneWidget);
      expect(
        find.descendant(
          of: communitySheetTile,
          matching: find.byIcon(Icons.add_rounded),
        ),
        findsOneWidget,
      );

      await tester.tap(communityToggle);
      await tester.pumpAndSettle();

      expect(api.followedCommunityIds, ['investments']);
      final subscribeEvent = api.trackedEvents.lastWhere(
        (event) =>
            event.eventType == 'subscribe' &&
            event.communityId == 'investments',
      );
      expect(subscribeEvent.surface, 'content');
      expect(subscribeEvent.tab, 'following');
      expect(subscribeEvent.blockType, 'my_subscriptions');
      expect(subscribeEvent.metadata, containsPair('action', 'subscribe'));
      expect(subscribeEvent.metadata, containsPair('entityType', 'community'));
      expect(subscribeEvent.metadata, containsPair('entityId', 'investments'));
      expect(subscribeEvent.metadata, containsPair('topic', 'HOBBIES'));
      expect(subscribeEvent.metadata, containsPair('countryCode', 'KZ'));
      expect(subscribeEvent.metadata, containsPair('cityId', 'almaty'));

      await tester.tap(
        find.descendant(
          of: subscriptionsSheet,
          matching: find.byIcon(Icons.tune_rounded),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FILTERS'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Topics'), findsOneWidget);
      expect(find.text('Sort'), findsNothing);
      expect(find.text('Additional'), findsNothing);
      expect(find.text('Subscription status'), findsNothing);
      expect(
        find.byKey(
          const ValueKey('my-subscriptions-filter-communities-active'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('my-subscriptions-topic-communities-HOBBIES'),
        ),
        findsOneWidget,
      );
      expect(find.text('Moderated'), findsNothing);
      expect(find.text('Muted'), findsNothing);
      expect(find.text('Friends'), findsNothing);
      await tester.tap(
        find.byKey(
          const ValueKey('my-subscriptions-filter-communities-active'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Show 1 community'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('my-subscriptions-apply-filters')),
      );
      await tester.pumpAndSettle();

      expect(communitySheetTile, findsOneWidget);
      expect(
        find.descendant(
          of: communitySheetTile,
          matching: find.byIcon(Icons.remove_rounded),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('my-subscriptions-tab-people')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Online first'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: subscriptionsSheet,
          matching: find.byIcon(Icons.tune_rounded),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FILTERS'), findsOneWidget);
      expect(find.text('Relationship'), findsOneWidget);
      expect(find.text('Activity'), findsNothing);
      expect(find.text('Sort'), findsNothing);
      expect(find.text('Connection type'), findsNothing);
      expect(
        find.byKey(const ValueKey('my-subscriptions-filter-friends')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('my-subscriptions-filter-following')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('my-subscriptions-filter-online')),
        findsNothing,
      );
      expect(find.text('Muted'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('my-subscriptions-filter-friends')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Show 1 person'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('my-subscriptions-apply-filters')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: subscriptionsSheet, matching: find.text('Aigerim')),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: subscriptionsSheet,
          matching: find.text('Guide Nomad'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('shows followed community posts on following tab', (
    tester,
  ) async {
    final subscriptionsApi = _FakeFeedSubscriptionsApi(
      FeedSubscriptionsVm(
        communities: [
          FeedCommunityVm(
            id: 'community-1',
            title: 'Investments',
            membersCount: 6326,
            followedByViewer: true,
          ),
        ],
      ),
    );
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        if (tab == 'following') {
          return Future.value(
            FeedPageVm(
              items: [
                _postCardBlock(
                  'Community market update',
                  authorUserId: 'community-author',
                  authorNickname: 'Community Author',
                ),
              ],
            ),
          );
        }
        return Future.value(_feedPage());
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionProvider>.value(
        value: _FakeSessionProvider(_profile(userId: 'viewer-1')),
        child: _feedRouterApp(api, subscriptionsApi: subscriptionsApi),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: find.byType(Tab), matching: find.text('Following')),
    );
    await tester.pumpAndSettle();

    expect(api.calls.last, const _FeedCall(surface: 'home', tab: 'following'));
    expect(find.text('My subscriptions'), findsOneWidget);
    expect(find.text('Community market update'), findsOneWidget);
  });

  testWidgets('keeps viewer-authored community posts on following tab', (
    tester,
  ) async {
    final subscriptionsApi = _FakeFeedSubscriptionsApi(
      FeedSubscriptionsVm(
        communities: [
          FeedCommunityVm(
            id: 'community-1',
            title: 'Investments',
            membersCount: 6326,
            followedByViewer: true,
          ),
        ],
      ),
    );
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        if (tab == 'following') {
          return Future.value(
            FeedPageVm(
              items: [
                _postCardBlock(
                  'My community update',
                  authorUserId: 'viewer-1',
                  authorNickname: 'Me',
                ),
              ],
            ),
          );
        }
        return Future.value(_feedPage());
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionProvider>.value(
        value: _FakeSessionProvider(_profile(userId: 'viewer-1')),
        child: _feedRouterApp(api, subscriptionsApi: subscriptionsApi),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: find.byType(Tab), matching: find.text('Following')),
    );
    await tester.pumpAndSettle();

    expect(find.text('My community update'), findsOneWidget);
  });

  testWidgets('uses compact suggestions without moderation controls', (
    tester,
  ) async {
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(_feedPage(viewerCanModerate: true));
      },
    );

    await tester.pumpWidget(_feedApp(api));
    await tester.pumpAndSettle();

    expect(find.text('Moderate'), findsNothing);
    expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
  });

  testWidgets('opens selected community from suggested communities', (
    tester,
  ) async {
    FeedCommunityVm? selectedCommunity;
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(_feedPage());
      },
    );

    await tester.pumpWidget(
      _feedApp(
        api,
        onCommunityOpen: (community) {
          selectedCommunity = community;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('open-suggested-community-community-1')),
    );
    await tester.pumpAndSettle();

    expect(selectedCommunity?.id, 'community-1');
    final clickEvent = api.trackedEvents.lastWhere(
      (event) =>
          event.eventType == FeedEventTypes.click &&
          event.communityId == 'community-1',
    );
    expect(clickEvent.blockType, 'suggested_communities');
    expect(clickEvent.metadata, containsPair('entityType', 'community'));
    expect(clickEvent.metadata, containsPair('entityId', 'community-1'));
  });

  testWidgets('opens community discovery sheet with search from suggestions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final locationProvider = HomeLocationProvider();
    await locationProvider.selectCity(
      const ReferenceCity(id: 'da-nang', countryCode: 'VN', name: 'Da Nang'),
    );
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(
          _feedPage(
            extraCommunities: [
              FeedCommunityVm(
                id: 'community-joined',
                title: 'Already joined',
                followedByViewer: true,
              ),
            ],
          ),
        );
      },
      onListCommunities:
          ({
            topic,
            countryCode,
            cityId,
            search,
            excludeFollowed = false,
            onlyFollowed = false,
            limit = 20,
            offset = 0,
          }) {
            return Future.value(
              CommunityListPageVm(
                items: [
                  FeedCommunityVm(
                    id: 'community-2',
                    title: 'Blockchain&Crypto · da-nang',
                    topic: 'CRYPTO',
                    countryCode: 'VN',
                    cityId: 'da-nang',
                    cityName: 'Da Nang',
                    membersCount: 2917,
                  ),
                  FeedCommunityVm(
                    id: 'community-joined',
                    title: 'Already joined',
                    followedByViewer: true,
                  ),
                ],
                limit: limit,
                offset: offset,
              ),
            );
          },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<HomeLocationProvider>.value(
        value: locationProvider,
        child: _feedApp(api),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Already joined'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('open-community-discovery-sheet')),
    );
    await tester.pumpAndSettle();

    expect(api.communityListCalls, hasLength(1));
    expect(api.communityListCalls.single.countryCode, 'VN');
    expect(api.communityListCalls.single.cityId, 'da-nang');
    expect(
      find.byKey(const ValueKey('community-discovery-sheet-search')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.text('Blockchain&Crypto'), findsOneWidget);
    expect(find.text('Blockchain&Crypto · da-nang'), findsNothing);
    expect(find.text('Da Nang'), findsOneWidget);
    expect(find.text('2917 members'), findsOneWidget);
    expect(find.text('Already joined'), findsNothing);

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.text('FILTERS'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('City'), findsWidgets);
    expect(find.text('Da Nang'), findsWidgets);
    expect(find.text('Show 1 community').last, findsOneWidget);
    await tester.tap(find.text('Show 1 community').last);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey('community-discovery-sheet-toggle-community-2'),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.followedCommunityIds, ['community-2']);
    expect(find.text('Blockchain&Crypto'), findsOneWidget);
    expect(find.text('2918 members'), findsOneWidget);
    final subscribeEvent = api.trackedEvents.lastWhere(
      (event) =>
          event.eventType == 'subscribe' && event.communityId == 'community-2',
    );
    expect(subscribeEvent.surface, 'content');
    expect(subscribeEvent.tab, 'for_you');
    expect(subscribeEvent.blockType, 'suggested_communities');
    expect(subscribeEvent.metadata, containsPair('action', 'subscribe'));
    expect(subscribeEvent.metadata, containsPair('entityType', 'community'));
    expect(subscribeEvent.metadata, containsPair('entityId', 'community-2'));
    expect(subscribeEvent.metadata, containsPair('topic', 'CRYPTO'));
    expect(subscribeEvent.metadata, containsPair('countryCode', 'VN'));
    expect(subscribeEvent.metadata, containsPair('cityId', 'da-nang'));

    await tester.tap(
      find.byKey(
        const ValueKey('community-discovery-sheet-toggle-community-2'),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.unfollowedCommunityIds, ['community-2']);
    expect(find.text('Blockchain&Crypto'), findsOneWidget);
    expect(find.text('2917 members'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('community-discovery-sheet-search')),
      'crypto',
    );
    await tester.pumpAndSettle();

    expect(api.communityListCalls.last.search, 'crypto');
  });

  testWidgets(
    'community discovery sends city filter when location has only city name',
    (tester) async {
      final locationProvider = _StaticHomeLocationProvider(
        HomeLocationPreference(
          source: HomeLocationSource.detected,
          countryCode: 'KZ',
          cityName: 'Алматы',
          updatedAt: DateTime.utc(2026, 6, 17),
        ),
      );
      final api = _FakeFeedApi(
        onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
          return Future.value(_feedPage());
        },
        onListCommunities:
            ({
              topic,
              countryCode,
              cityId,
              search,
              excludeFollowed = false,
              onlyFollowed = false,
              limit = 20,
              offset = 0,
            }) {
              return Future.value(
                CommunityListPageVm(items: const [], limit: limit, offset: 0),
              );
            },
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<HomeLocationProvider>.value(
          value: locationProvider,
          child: _feedApp(api),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('open-community-discovery-sheet')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('app-list-search-active-filter-count')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(api.communityListCalls, hasLength(1));
      expect(api.communityListCalls.single.countryCode, 'KZ');
      expect(api.communityListCalls.single.cityId, 'almaty');
    },
  );

  testWidgets(
    'does not flash raw community location before discovery labels resolve',
    (tester) async {
      final countryCompleter = Completer<ReferenceCountry?>();
      final cityCompleter = Completer<ReferenceCity?>();
      final resolver = AppLocationLabelResolver(
        countryLookup: (_, {required lang}) => countryCompleter.future,
        cityLookup: (_, {required lang}) => cityCompleter.future,
      );
      final api = _FakeFeedApi(
        onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
          return Future.value(_feedPage());
        },
        onListCommunities:
            ({
              topic,
              countryCode,
              cityId,
              search,
              excludeFollowed = false,
              onlyFollowed = false,
              limit = 20,
              offset = 0,
            }) {
              return Future.value(
                CommunityListPageVm(
                  items: [
                    FeedCommunityVm(
                      id: 'community-sf',
                      title: 'Events',
                      countryCode: 'US',
                      cityId: 'san-francisco',
                      cityName: 'San Francisco',
                    ),
                  ],
                  limit: limit,
                  offset: offset,
                ),
              );
            },
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: CommunityDiscoverySheet(
                feedApi: api,
                locationLabelResolver: resolver,
                onCommunityOpen: (_) {},
                onCommunityUpdated: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('San Francisco'), findsNothing);
      expect(find.text('San Francisco, USA'), findsNothing);
      expect(find.text('Сан-Франциско, США'), findsNothing);

      countryCompleter.complete(
        const ReferenceCountry(code: 'US', name: 'США'),
      );
      cityCompleter.complete(
        const ReferenceCity(
          id: 'san-francisco',
          countryCode: 'US',
          name: 'Сан-Франциско',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Сан-Франциско, США'), findsOneWidget);
      expect(find.text('San Francisco'), findsNothing);
    },
  );

  testWidgets('opens post cards and tracks click events', (tester) async {
    PostVm? openedPost;
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(_feedPage());
      },
    );

    await tester.pumpWidget(
      _feedApp(
        api,
        onPostOpen: (post) {
          openedPost = post;
        },
      ),
    );
    await tester.pumpAndSettle();
    final impressionCount = api.trackedEvents.length;

    final postCard = find.byKey(
      const ValueKey('open-feed-post-hidden-courtyards-of-turkistan'),
    );
    await tester.scrollUntilVisible(
      postCard,
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(postCard);
    await tester.pumpAndSettle();

    expect(openedPost?.title, 'Hidden courtyards of Turkistan');
    expect(api.trackedEvents, hasLength(impressionCount + 1));
    final click = api.trackedEvents.last;
    expect(click.eventType, 'click');
    expect(click.blockType, 'post_card');
    expect(click.postId, 'hidden-courtyards-of-turkistan');
  });

  testWidgets('tracks post dwell after returning from post details', (
    tester,
  ) async {
    var analyticsNow = DateTime.utc(2026, 6, 15, 12);
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(_feedPage());
      },
    );

    await tester.pumpWidget(
      _feedRouterApp(api, analyticsNow: () => analyticsNow),
    );
    await tester.pumpAndSettle();

    final postCard = find.byKey(
      const ValueKey('open-feed-post-hidden-courtyards-of-turkistan'),
    );
    await tester.scrollUntilVisible(
      postCard,
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(postCard);
    await tester.pumpAndSettle();

    expect(
      find.text('Post details route hidden-courtyards-of-turkistan'),
      findsOneWidget,
    );

    analyticsNow = analyticsNow.add(const Duration(milliseconds: 4200));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('close-post-details-route')));
    await tester.pumpAndSettle();

    final dwell = api.trackedEvents.lastWhere(
      (event) => event.eventType == 'dwell',
    );
    expect(dwell.blockType, 'post_card');
    expect(dwell.postId, 'hidden-courtyards-of-turkistan');
    expect(dwell.metadata, containsPair('action', 'dwell'));
    expect(dwell.metadata['dwellMs'], greaterThanOrEqualTo(4000));
  });

  testWidgets('tracks post card events with ranking metadata', (tester) async {
    final post = _post(
      title: 'Ranking context guide',
      postProfileKey: 'listing_v1',
      communityId: 'community-42',
      authorUserId: 'author-42',
      category: 'LOCAL_GUIDE',
      tags: const ['hidden-gems', ' local-food '],
      placeCountryCode: ' kz ',
      placeCityId: ' almaty ',
    );
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(
          FeedPageVm(
            items: [
              FeedBlockVm(
                id: 'ranked-post',
                type: FeedBlockType.postCard,
                data: const {'candidateSource': 'social'},
                post: post,
              ),
            ],
          ),
        );
      },
    );

    await tester.pumpWidget(_feedApp(api, onPostOpen: (_) {}));
    await tester.pumpAndSettle();

    final impression = api.trackedEvents.singleWhere(
      (event) =>
          event.eventType == 'impression' &&
          event.postId == 'ranking-context-guide',
    );
    expect(impression.communityId, 'community-42');
    expect(impression.metadata, {
      'postProfileKey': 'listing_v1',
      'communityId': 'community-42',
      'authorUserId': 'author-42',
      'cityId': 'almaty',
      'countryCode': 'KZ',
      'category': 'LOCAL_GUIDE',
      'categorySlug': 'local-guide',
      'tags': ['hidden-gems', 'local-food'],
      'postTags': ['hidden-gems', 'local-food'],
      'surface': 'content',
      'tab': 'for_you',
      'action': 'impression',
      'candidateSource': 'social',
    });

    final postCard = find.byKey(
      const ValueKey('open-feed-post-ranking-context-guide'),
    );
    await tester.scrollUntilVisible(
      postCard,
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(postCard);
    await tester.pumpAndSettle();

    final click = api.trackedEvents.last;
    expect(click.eventType, 'click');
    expect(click.communityId, 'community-42');
    expect(click.metadata, containsPair('action', 'click'));
    expect(click.metadata, containsPair('postProfileKey', 'listing_v1'));
    expect(click.metadata, containsPair('candidateSource', 'social'));
    expect(click.metadata, containsPair('authorUserId', 'author-42'));
    expect(
      click.metadata,
      containsPair('postTags', ['hidden-gems', 'local-food']),
    );
  });

  testWidgets('tracks post engagement and negative feedback actions', (
    tester,
  ) async {
    final post = _post(
      title: 'Actionable city guide',
      postProfileKey: 'listing_v1',
      communityId: 'community-42',
      authorUserId: 'author-42',
      tags: const ['food', 'events'],
      placeCountryCode: 'KZ',
      placeCityId: 'almaty',
    );
    final notInterestingPost = _post(
      title: 'Noisy promo pick',
      postProfileKey: 'quick_post_v1',
      communityId: 'community-99',
      authorUserId: 'author-99',
      tags: const ['promo'],
      placeCountryCode: 'KZ',
      placeCityId: 'almaty',
    );
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(
          FeedPageVm(
            items: [
              FeedBlockVm(
                id: 'action-post',
                type: FeedBlockType.postCard,
                post: post,
              ),
              FeedBlockVm(
                id: 'noisy-post',
                type: FeedBlockType.postCard,
                post: notInterestingPost,
              ),
            ],
          ),
        );
      },
    );
    final postApi = _FeedPostActionApi();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: _AuthenticatedAuthProvider(),
        child: _feedRouterApp(
          api,
          postApi: postApi,
          postShareLauncher: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final likeButton = find.byKey(
      const ValueKey('feed-post-like-actionable-city-guide'),
    );
    await tester.scrollUntilVisible(
      likeButton,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(likeButton);
    await tester.pumpAndSettle();

    expect(postApi.likedPostIds, ['actionable-city-guide']);
    final like = api.trackedEvents.lastWhere(
      (event) => event.eventType == 'like',
    );
    expect(like.postId, 'actionable-city-guide');
    expect(like.communityId, 'community-42');
    expect(like.metadata, containsPair('action', 'like'));
    expect(like.metadata, containsPair('postProfileKey', 'listing_v1'));

    final trackedAfterLike = api.trackedEvents.length;
    await tester.tap(likeButton);
    await tester.pumpAndSettle();

    expect(postApi.unlikedPostIds, ['actionable-city-guide']);
    expect(
      api.trackedEvents
          .skip(trackedAfterLike)
          .any((event) => event.eventType == 'unlike'),
      isFalse,
    );

    await tester.tap(
      find.byKey(const ValueKey('feed-post-share-actionable-city-guide')),
    );
    await tester.pumpAndSettle();

    expect(postApi.sharedPostIds, ['actionable-city-guide']);
    expect(
      api.trackedEvents.any(
        (event) =>
            event.eventType == 'share' &&
            event.postId == 'actionable-city-guide' &&
            event.metadata['action'] == 'share',
      ),
      isTrue,
    );

    await tester.tap(
      find.byKey(const ValueKey('feed-post-more-actionable-city-guide')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('feed-post-hide-actionable-city-guide')),
    );
    await tester.pumpAndSettle();

    final hide = api.trackedEvents.lastWhere(
      (event) => event.eventType == 'hide',
    );
    expect(hide.postId, 'actionable-city-guide');
    expect(hide.metadata, containsPair('feedbackType', 'hide'));
    expect(find.text('Actionable city guide'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('feed-post-more-noisy-promo-pick')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('feed-post-not-interested-noisy-promo-pick')),
    );
    await tester.pumpAndSettle();

    final notInterested = api.trackedEvents.lastWhere(
      (event) => event.eventType == 'not_interested',
    );
    expect(notInterested.postId, 'noisy-promo-pick');
    expect(
      notInterested.metadata,
      containsPair('feedbackType', 'not_interested'),
    );
    expect(find.text('Noisy promo pick'), findsNothing);
  });

  testWidgets('hides post card actions for unauthenticated viewers', (
    tester,
  ) async {
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(
          FeedPageVm(
            items: [
              FeedBlockVm(
                id: 'guest-post',
                type: FeedBlockType.postCard,
                post: _post(title: 'Guest readable post'),
              ),
            ],
          ),
        );
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: _UnauthenticatedAuthProvider(),
        child: _feedRouterApp(
          api,
          postApi: _FeedPostActionApi(),
          postShareLauncher: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Guest readable post'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Guest readable post'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('feed-post-like-guest-readable-post')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('feed-post-share-guest-readable-post')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('feed-post-more-guest-readable-post')),
      findsNothing,
    );
  });

  testWidgets('hides posts authored by the current user from the feed', (
    tester,
  ) async {
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(
          FeedPageVm(
            items: [
              _postCardBlock(
                'My own post',
                authorUserId: 'viewer-1',
                authorNickname: 'Me',
              ),
              _postCardBlock(
                'Interesting local tip',
                authorUserId: 'friend-1',
                authorNickname: 'Aigerim',
              ),
            ],
          ),
        );
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionProvider>.value(
        value: _FakeSessionProvider(_profile(userId: 'viewer-1')),
        child: _feedApp(api),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My own post'), findsNothing);
    expect(find.text('Interesting local tip'), findsOneWidget);
  });

  testWidgets(
    'groups system posts after recommendations and prioritizes subscriptions',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = _FakeFeedApi(
        onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
          return Future.value(
            FeedPageVm(
              items: [
                FeedBlockVm(
                  id: 'communities',
                  type: FeedBlockType.suggestedCommunities,
                  communities: [
                    FeedCommunityVm(
                      id: 'community-1',
                      title: 'Almaty weekend hikes',
                      subtitle: 'Mountain routes',
                      membersCount: 1200,
                    ),
                  ],
                ),
                _postCardBlock('Discovery pick', data: const {}),
                for (var index = 0; index < 6; index++)
                  _postCardBlock(
                    'System update $index',
                    data: const {'source': 'system'},
                    tags: const ['official'],
                    authorUserId: 'system-user',
                    authorNickname: 'Inflap',
                  ),
                _postCardBlock(
                  'Followed community post',
                  data: const {'relationship': 'following'},
                ),
              ],
            ),
          );
        },
      );

      await tester.pumpWidget(_feedRouterApp(api));
      await tester.pumpAndSettle();

      expect(find.text('Official updates'), findsOneWidget);
      expect(find.text('View all'), findsOneWidget);
      expect(find.text('System update 0'), findsOneWidget);
      expect(find.text('System update 4'), findsOneWidget);
      expect(find.text('System update 5'), findsNothing);

      expect(
        tester.getTopLeft(find.text('Almaty weekend hikes')).dy,
        lessThan(tester.getTopLeft(find.text('Official updates')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Official updates')).dy,
        lessThan(tester.getTopLeft(find.text('Followed community post')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Followed community post')).dy,
        lessThan(tester.getTopLeft(find.text('Discovery pick')).dy),
      );
      expect(
        api.trackedEvents
            .where((event) => event.postId == 'system-update-0')
            .map((event) => event.blockType),
        contains('official_news_card'),
      );

      await tester.tap(find.text('View all'));
      await tester.pumpAndSettle();
      expect(find.text('Official posts'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('System update 5'),
        220,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('System update 5'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(of: find.byType(Tab), matching: find.text('Following')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Official updates'), findsNothing);
      expect(find.text('System update 0'), findsNothing);
      expect(find.text('Followed community post'), findsOneWidget);
      expect(find.text('Discovery pick'), findsOneWidget);
    },
  );

  testWidgets('sorts feed posts below recommendations', (tester) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(
          FeedPageVm(
            items: [
              FeedBlockVm(
                id: 'communities',
                type: FeedBlockType.suggestedCommunities,
                communities: [
                  FeedCommunityVm(
                    id: 'community-1',
                    title: 'Almaty weekend hikes',
                    subtitle: 'Mountain routes',
                    membersCount: 1200,
                  ),
                ],
              ),
              _postCardBlock(
                'Fresh tip',
                publishedAt: DateTime.utc(2026, 1, 3),
                stats: PostStatsVm(views: 10, likes: 1, comments: 0, shares: 0),
              ),
              _postCardBlock(
                'Popular tip',
                publishedAt: DateTime.utc(2026, 1, 2),
                stats: PostStatsVm(
                  views: 120,
                  likes: 24,
                  comments: 2,
                  shares: 4,
                ),
              ),
              _postCardBlock(
                'Discussed tip',
                publishedAt: DateTime.utc(2026, 1, 1),
                stats: PostStatsVm(
                  views: 20,
                  likes: 2,
                  comments: 18,
                  shares: 0,
                ),
              ),
            ],
          ),
        );
      },
    );

    await tester.pumpWidget(_feedRouterApp(api));
    await tester.pumpAndSettle();

    final sortRow = find.byKey(const ValueKey('feed-post-sort-row'));
    expect(sortRow, findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Almaty weekend hikes')).dy,
      lessThan(tester.getTopLeft(sortRow).dy),
    );
    expect(
      tester.getTopLeft(sortRow).dy,
      lessThan(tester.getTopLeft(find.text('Fresh tip')).dy),
    );

    await tester.drag(sortRow, const Offset(-160, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Popular'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Popular tip')).dy,
      lessThan(tester.getTopLeft(find.text('Fresh tip')).dy),
    );

    await tester.drag(sortRow, const Offset(-160, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discussed'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Discussed tip')).dy,
      lessThan(tester.getTopLeft(find.text('Popular tip')).dy),
    );
  });

  testWidgets('renders create story circle before user and system stories', (
    tester,
  ) async {
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(
          _feedPage(
            includeSecondTrayStory: true,
            secondTrayAuthorNickname: 'Inflap',
          ),
        );
      },
    );

    await tester.pumpWidget(_feedRouterApp(api));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('feed-stories-circle-tray')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('open-feed-create-story')),
      findsOneWidget,
    );
    expect(find.text('Your story'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('feed-tray-story-circle-silk-road-notes')),
      findsOneWidget,
    );
    expect(find.text('Inflap'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-feed-create-story')));
    await tester.pumpAndSettle();

    expect(find.text('Capture story route'), findsOneWidget);
  });

  testWidgets('hides profile completion and official travel update blocks', (
    tester,
  ) async {
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(
          FeedPageVm(
            items: [
              FeedBlockVm(
                id: 'official:news:travel-updates',
                type: FeedBlockType.officialNewsCard,
                data: const {
                  'title': 'Official travel updates',
                  'subtitle': 'Visa and safety updates from verified sources.',
                  'actionLabel': 'Read updates',
                  'entityType': 'official_news',
                  'entityId': 'travel-updates',
                  'source': 'content_for_you_official_news',
                  'route': '/feed/official',
                  'semanticTags': ['official', 'travel_updates', 'trust'],
                },
              ),
              FeedBlockVm(
                id: 'profile:completion',
                type: FeedBlockType.profileCard,
                data: const {
                  'title': 'Complete your travel profile',
                  'subtitle':
                      'Personalized recommendations get better with your interests.',
                  'actionLabel': 'Complete profile',
                  'entityType': 'profile',
                  'entityId': 'completion',
                  'source': 'content_for_you_profile_completion',
                  'route': '/profile',
                  'semanticTags': ['profile', 'personalization'],
                },
              ),
            ],
          ),
        );
      },
    );

    await tester.pumpWidget(_feedRouterApp(api));
    await tester.pumpAndSettle();

    expect(find.text('Official travel updates'), findsNothing);
    expect(find.text('Complete your travel profile'), findsNothing);
    expect(
      api.trackedEvents.where((event) => event.eventType == 'impression'),
      isEmpty,
    );
    expect(
      find.byKey(const ValueKey('open-feed-conversion-profile:completion')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('open-feed-conversion-official:news:travel-updates'),
      ),
      findsNothing,
    );
  });

  testWidgets('renders seen state affordances for tray and story cards', (
    tester,
  ) async {
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(_feedPage(traySeen: true, cardSeen: true));
      },
    );

    await tester.pumpWidget(_feedApp(api));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('feed-tray-story-seen-silk-road-notes')),
      findsNothing,
    );

    final storySeenIndicator = find.byKey(
      const ValueKey('feed-post-card-seen-hidden-courtyards-of-turkistan'),
    );
    await tester.scrollUntilVisible(
      find.byKey(
        const ValueKey('open-feed-post-hidden-courtyards-of-turkistan'),
      ),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(storySeenIndicator, findsNothing);
    expect(find.text('Просмотрено'), findsNothing);
    expect(find.text('Viewed'), findsNothing);
  });

  testWidgets(
    'opens tray stories in sequential viewer with progress controls',
    (tester) async {
      final api = _FakeFeedApi(
        onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
          return Future.value(_feedPage(includeSecondTrayStory: true));
        },
      );

      await tester.pumpWidget(_feedRouterApp(api));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('open-feed-tray-story-silk-road-notes')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        find.byKey(const ValueKey('story-sequence-viewer')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('story-sequence-progress-silk-road-notes')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('story-sequence-progress-desert-market-routes'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('story-sequence-title-silk-road-notes')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('story-sequence-next')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('story-sequence-title-desert-market-routes')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('story-sequence-previous')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('story-sequence-title-silk-road-notes')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('story-sequence-close')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('story-sequence-viewer')), findsNothing);
      expect(
        find.byKey(const ValueKey('feed-tray-story-seen-silk-road-notes')),
        findsNothing,
      );

      final click = api.trackedEvents.last;
      expect(click.eventType, 'click');
      expect(click.blockType, 'stories_tray');
      expect(click.postId, isNull);
      expect(click.metadata, {
        'entityType': 'story',
        'entityId': 'silk-road-notes',
      });
    },
  );

  testWidgets('opens story tray from the first unseen slide', (tester) async {
    StoryTrayViewerRouteData? openedViewerData;
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(
          _feedPage(includeSecondTrayStory: true, traySeen: true),
        );
      },
    );

    await tester.pumpWidget(
      _feedRouterApp(
        api,
        onViewerRoute: (data) {
          openedViewerData = data;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('open-feed-tray-story-silk-road-notes')),
    );
    await tester.pump();

    expect(openedViewerData?.initialIndex, 1);
  });

  testWidgets(
    'opens story tray from the first slide when all slides are seen',
    (tester) async {
      StoryTrayViewerRouteData? openedViewerData;
      final api = _FakeFeedApi(
        onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
          return Future.value(
            _feedPage(
              includeSecondTrayStory: true,
              traySeen: true,
              secondTraySeen: true,
            ),
          );
        },
      );

      await tester.pumpWidget(
        _feedRouterApp(
          api,
          onViewerRoute: (data) {
            openedViewerData = data;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('open-feed-tray-story-silk-road-notes')),
      );
      await tester.pump();

      expect(openedViewerData?.initialIndex, 0);
    },
  );

  testWidgets('appends published story-circle to the end of its tray group', (
    tester,
  ) async {
    StoryTrayViewerRouteData? openedViewerData;
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(_feedPage(includeSecondTrayStory: true));
      },
    );

    await tester.pumpWidget(
      _feedRouterApp(
        api,
        captureResult: _story(title: 'Fresh story'),
        onViewerRoute: (data) {
          openedViewerData = data;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-feed-create-story-plus')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finish-story-capture')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('open-feed-tray-story-silk-road-notes')),
    );
    await tester.pump();

    expect(openedViewerData?.stories.map((story) => story.title), [
      'Silk Road notes',
      'Desert market routes',
      'Fresh story',
    ]);
  });

  testWidgets('expired story circles are hidden while post cards still open', (
    tester,
  ) async {
    StoryVm? openedStory;
    PostVm? openedPost;
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(_feedPage(trayExpired: true, cardExpired: true));
      },
    );

    await tester.pumpWidget(
      _feedApp(
        api,
        onStoryOpen: (story) {
          openedStory = story;
        },
        onPostOpen: (post) {
          openedPost = post;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('open-feed-tray-story-silk-road-notes')),
      findsNothing,
    );

    final postCard = find.byKey(
      const ValueKey('open-feed-post-hidden-courtyards-of-turkistan'),
    );
    await tester.scrollUntilVisible(
      postCard,
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(postCard);
    await tester.pumpAndSettle();

    expect(openedStory, isNull);
    expect(openedPost?.title, 'Hidden courtyards of Turkistan');
  });

  testWidgets('opens quick discussion post in its community with post anchor', (
    tester,
  ) async {
    Uri? openedCommunityUri;
    final quickPost = _post(
      title: 'Quick discussion',
      postProfileKey: 'quick_post_v1',
      communityId: 'community-1',
    );
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(
          FeedPageVm(
            items: [
              FeedBlockVm(
                id: 'quick-discussion',
                type: FeedBlockType.postCard,
                post: quickPost,
              ),
            ],
          ),
        );
      },
    );

    await tester.pumpWidget(
      _feedRouterApp(
        api,
        onCommunityRoute: (uri) {
          openedCommunityUri = uri;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Quick discussion'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quick discussion'));
    await tester.pumpAndSettle();

    expect(openedCommunityUri?.path, '/communities/community-1');
    expect(openedCommunityUri?.queryParameters['postId'], 'quick-discussion');
    expect(
      find.text('Community route community-1 quick-discussion'),
      findsOneWidget,
    );
  });

  testWidgets('removes story circles when their TTL expires on an open feed', (
    tester,
  ) async {
    final expiringAt = DateTime.now().toUtc().add(const Duration(seconds: 5));
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(_feedPage(trayExpiresAt: expiringAt));
      },
    );

    await tester.pumpWidget(_feedApp(api));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('open-feed-tray-story-silk-road-notes')),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('open-feed-tray-story-silk-road-notes')),
      findsNothing,
    );
  });

  testWidgets('renders post cards independently from story expiry', (
    tester,
  ) async {
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(
          FeedPageVm(
            items: [
              FeedBlockVm(
                id: 'expired-post-card',
                type: FeedBlockType.postCard,
                post: _post(
                  title: 'Expired post card',
                  expiresAt: DateTime.utc(2020),
                ),
              ),
              FeedBlockVm(
                id: 'post-card',
                type: FeedBlockType.postCard,
                post: _post(title: 'Normal post card'),
              ),
            ],
          ),
        );
      },
    );

    await tester.pumpWidget(_feedApp(api));
    await tester.pumpAndSettle();

    expect(find.text('Expired post card'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Normal post card'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Normal post card'), findsOneWidget);
  });

  testWidgets('shows error state and retries the current tab', (tester) async {
    var attempts = 0;
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        attempts += 1;
        if (attempts == 1) {
          return Future<FeedPageVm>.error(Exception('network down'));
        }
        return Future.value(_feedPage());
      },
    );

    await tester.pumpWidget(_feedApp(api));
    await tester.pumpAndSettle();

    expect(find.text('Could not load feed'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(api.calls, [
      const _FeedCall(surface: 'home', tab: 'for_you'),
      const _FeedCall(surface: 'home', tab: 'for_you'),
    ]);
    expect(
      find.byKey(const ValueKey('feed-tray-story-circle-silk-road-notes')),
      findsOneWidget,
    );
  });

  testWidgets('loads the next cursor page when scrolled near the bottom', (
    tester,
  ) async {
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        if (cursor == 'cursor-2') {
          return Future.value(
            FeedPageVm(items: [_postCardBlock('Second page post')]),
          );
        }
        return Future.value(
          FeedPageVm(
            nextCursor: 'cursor-2',
            items: [
              for (var index = 0; index < 8; index++)
                _postCardBlock('First page post $index'),
            ],
          ),
        );
      },
    );

    await tester.pumpWidget(_feedApp(api));
    await tester.pumpAndSettle();

    await _dragFeedNearBottom(tester);

    expect(
      api.calls.last,
      const _FeedCall(surface: 'home', tab: 'for_you', cursor: 'cursor-2'),
    );
    expect(find.text('Second page post'), findsOneWidget);
  });

  testWidgets('keeps feed items and retries after next page load fails', (
    tester,
  ) async {
    var nextPageAttempts = 0;
    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        if (cursor == 'cursor-2') {
          nextPageAttempts += 1;
          if (nextPageAttempts == 1) {
            return Future<FeedPageVm>.error(Exception('network down'));
          }
          return Future.value(
            FeedPageVm(items: [_postCardBlock('Recovered page post')]),
          );
        }
        return Future.value(
          FeedPageVm(
            nextCursor: 'cursor-2',
            items: [
              for (var index = 0; index < 8; index++)
                _postCardBlock('First page post $index'),
            ],
          ),
        );
      },
    );

    await tester.pumpWidget(_feedApp(api));
    await tester.pumpAndSettle();

    await _dragFeedNearBottom(tester);

    expect(find.text('First page post 7'), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
    expect(find.text('Recovered page post'), findsNothing);

    await tester.drag(_feedList(), const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(api.calls.where((call) => call.cursor == 'cursor-2'), hasLength(2));
    expect(find.text('Recovered page post'), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsNothing);
  });

  testWidgets('renders on narrow width without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeFeedApi(
      onGetFeed: ({surface = 'home', tab = 'for_you', cursor, limit = 20}) {
        return Future.value(_feedPage());
      },
    );

    await tester.pumpWidget(_feedApp(api));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('feed-tray-story-circle-silk-road-notes')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Finder _feedList() {
  return find.byKey(const PageStorageKey<String>('feed-block-list'));
}

Future<void> _dragFeedNearBottom(WidgetTester tester) async {
  for (var index = 0; index < 12; index++) {
    await tester.drag(_feedList(), const Offset(0, -900));
    await tester.pump(const Duration(milliseconds: 24));
  }
  await tester.pumpAndSettle();
}

Widget _feedApp(
  FeedApi api, {
  FeedSubscriptionsApi? subscriptionsApi,
  ValueChanged<StoryVm>? onStoryOpen,
  ValueChanged<PostVm>? onPostOpen,
  ValueChanged<FeedCommunityVm>? onCommunityOpen,
  ValueChanged<FeedCommunityVm>? onCommunityModerationOpen,
  AppLocationLabelResolver? locationLabelResolver,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: FeedScreen(
      feedApi: api,
      subscriptionsApi: subscriptionsApi,
      onStoryOpen: onStoryOpen,
      onPostOpen: onPostOpen,
      onCommunityOpen: onCommunityOpen,
      onCommunityModerationOpen: onCommunityModerationOpen,
      locationLabelResolver: locationLabelResolver,
    ),
  );
}

Widget _feedRouterApp(
  FeedApi api, {
  FeedSubscriptionsApi? subscriptionsApi,
  PostApi? postApi,
  StoryVm? captureResult,
  ValueChanged<StoryTrayViewerRouteData>? onViewerRoute,
  ValueChanged<Uri>? onCommunityRoute,
  AppLocationLabelResolver? locationLabelResolver,
  DateTime Function()? analyticsNow,
  FeedPostShareLauncher? postShareLauncher,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => FeedScreen(
          feedApi: api,
          subscriptionsApi: subscriptionsApi,
          postApi: postApi,
          locationLabelResolver: locationLabelResolver,
          analyticsNow: analyticsNow,
          postShareLauncher: postShareLauncher,
        ),
      ),
      GoRoute(
        path: '/stories/viewer',
        builder: (context, state) {
          final data = state.extra! as StoryTrayViewerRouteData;
          onViewerRoute?.call(data);
          return StoryTrayViewerScreen(data: data);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) =>
            const Scaffold(body: Text('Profile route')),
      ),
      GoRoute(
        path: '/communities/:communityId',
        builder: (context, state) {
          onCommunityRoute?.call(state.uri);
          final communityId = state.pathParameters['communityId'] ?? '';
          final postId = state.uri.queryParameters['postId'] ?? '';
          return Scaffold(body: Text('Community route $communityId $postId'));
        },
      ),
      GoRoute(
        path: '/stories/capture',
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              const Text('Capture story route'),
              ElevatedButton(
                key: const ValueKey('finish-story-capture'),
                onPressed: captureResult == null
                    ? null
                    : () => context.pop(captureResult),
                child: const Text('Finish capture'),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/posts/create',
        builder: (context, state) =>
            const Scaffold(body: Text('Create post route')),
      ),
      GoRoute(
        path: '/posts/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return Scaffold(
            body: Column(
              children: [
                Text('Post details route $slug'),
                ElevatedButton(
                  key: const ValueKey('close-post-details-route'),
                  onPressed: () => context.pop(),
                  child: const Text('Close post details'),
                ),
              ],
            ),
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) =>
            const Scaffold(body: Text('Notifications route')),
      ),
    ],
  );

  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

FeedPageVm _feedPage({
  bool viewerCanModerate = false,
  bool traySeen = false,
  bool cardSeen = false,
  bool trayExpired = false,
  DateTime? trayExpiresAt,
  bool cardExpired = false,
  bool includeSecondTrayStory = false,
  bool secondTraySeen = false,
  String secondTrayAuthorNickname = 'Aigerim',
  List<FeedCommunityVm> extraCommunities = const [],
}) {
  return FeedPageVm(
    items: [
      FeedBlockVm(
        id: 'stories',
        type: FeedBlockType.storiesTray,
        stories: [
          _story(
            title: 'Silk Road notes',
            seenByViewer: traySeen,
            expiresAt:
                trayExpiresAt ?? (trayExpired ? DateTime.utc(2020) : null),
          ),
          if (includeSecondTrayStory)
            _story(
              title: 'Desert market routes',
              excerpt: 'A late bazaar loop.',
              seenByViewer: secondTraySeen,
              authorNickname: secondTrayAuthorNickname,
              authorUserId: secondTrayAuthorNickname == 'Inflap'
                  ? 'system-user'
                  : 'user-1',
            ),
        ],
      ),
      FeedBlockVm(
        id: 'communities',
        type: FeedBlockType.suggestedCommunities,
        communities: [
          FeedCommunityVm(
            id: 'community-1',
            title: 'Almaty weekend hikes',
            subtitle: 'Mountain routes',
            countryCode: 'KZ',
            cityId: 'almaty',
            cityName: 'Almaty',
            membersCount: 1200,
            viewerRole: viewerCanModerate ? 'MODERATOR' : null,
            viewerCanModerate: viewerCanModerate,
          ),
          ...extraCommunities,
        ],
      ),
      FeedBlockVm(
        id: 'story-card',
        type: FeedBlockType.postCard,
        post: _post(
          title: 'Hidden courtyards of Turkistan',
          seenByViewer: cardSeen,
          expiresAt: cardExpired ? DateTime.utc(2020) : null,
        ),
      ),
      FeedBlockVm(id: 'unknown', type: FeedBlockType.unknown),
    ],
  );
}

FeedBlockVm _postCardBlock(
  String title, {
  Map<String, Object?> data = const {},
  List<String> tags = const ['travel'],
  String authorUserId = 'user-1',
  String authorNickname = 'Aigerim',
  PostStatsVm? stats,
  DateTime? publishedAt,
  DateTime? createdAt,
}) {
  return FeedBlockVm(
    id: title,
    type: FeedBlockType.postCard,
    data: data,
    post: _post(
      title: title,
      tags: tags,
      authorUserId: authorUserId,
      authorNickname: authorNickname,
      stats: stats,
      publishedAt: publishedAt,
      createdAt: createdAt,
    ),
  );
}

PostVm _post({
  required String title,
  bool seenByViewer = false,
  DateTime? expiresAt,
  List<String> tags = const ['travel'],
  String category = 'JOURNAL',
  String authorUserId = 'user-1',
  String authorNickname = 'Aigerim',
  String? postProfileKey,
  String? communityId,
  String? placeCountryCode,
  String? placeCityId,
  PostStatsVm? stats,
  DateTime? publishedAt,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime.utc(2026, 1, 1);
  return PostVm(
    id: title.toLowerCase().replaceAll(' ', '-'),
    slug: title.toLowerCase().replaceAll(' ', '-'),
    title: title,
    excerpt: 'A compact route for a slow travel day.',
    category: category,
    status: 'PUBLISHED',
    format: 'POST',
    postProfileKey: postProfileKey,
    tags: tags,
    stats: stats ?? PostStatsVm(views: 42, likes: 7, comments: 3, shares: 1),
    author: PostAuthorVm(
      userId: authorUserId,
      locale: 'en',
      timezone: 'Asia/Almaty',
      nickname: authorNickname,
    ),
    likedByViewer: false,
    seenByViewer: seenByViewer,
    shareUrl:
        'https://inflap.test/posts/${title.toLowerCase().replaceAll(' ', '-')}',
    communityId: communityId,
    placeCountryCode: placeCountryCode,
    placeCityId: placeCityId,
    publishedAt: publishedAt,
    expiresAt: expiresAt ?? DateTime.utc(2027),
    createdAt: now,
    updatedAt: now,
  );
}

StoryVm _story({
  required String title,
  String? excerpt,
  bool seenByViewer = false,
  DateTime? expiresAt,
  String format = 'STORY',
  String authorUserId = 'user-1',
  String authorNickname = 'Aigerim',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return StoryVm(
    id: title.toLowerCase().replaceAll(' ', '-'),
    slug: title.toLowerCase().replaceAll(' ', '-'),
    title: title,
    excerpt: excerpt ?? 'A compact route for a slow travel day.',
    category: 'JOURNAL',
    status: 'PUBLISHED',
    format: format,
    tags: const ['travel'],
    stats: StoryStatsVm(views: 42, likes: 7, comments: 3, shares: 1),
    author: StoryAuthorVm(
      userId: authorUserId,
      locale: 'en',
      timezone: 'Asia/Almaty',
      nickname: authorNickname,
    ),
    likedByViewer: false,
    seenByViewer: seenByViewer,
    seenAt: seenByViewer ? DateTime.utc(2026, 1, 2, 9) : null,
    expiresAt: expiresAt ?? DateTime.utc(2027),
    shareUrl: 'https://inflap.test/stories/$title',
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeFeedApi implements FeedApi {
  _FakeFeedApi({required this.onGetFeed, this.onListCommunities});

  final List<_FeedCall> calls = [];
  final List<_CommunityListCall> communityListCalls = [];
  final List<FeedEventRequest> trackedEvents = [];
  final List<String> followedCommunityIds = [];
  final List<String> unfollowedCommunityIds = [];
  final Future<FeedPageVm> Function({
    String surface,
    String tab,
    String? cursor,
    int limit,
  })
  onGetFeed;
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

  @override
  Future<FeedPageVm> getFeed({
    String surface = 'home',
    String tab = 'for_you',
    String? cursor,
    String? countryCode,
    String? cityId,
    int limit = 20,
  }) {
    calls.add(
      _FeedCall(
        surface: surface,
        tab: tab,
        cursor: cursor,
        countryCode: countryCode,
        cityId: cityId,
      ),
    );
    return onGetFeed(surface: surface, tab: tab, cursor: cursor, limit: limit);
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
    communityListCalls.add(
      _CommunityListCall(
        topic: topic,
        countryCode: countryCode,
        cityId: cityId,
        search: search,
        excludeFollowed: excludeFollowed,
        onlyFollowed: onlyFollowed,
      ),
    );
    final handler = onListCommunities;
    if (handler == null) {
      throw UnimplementedError();
    }
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

  @override
  Future<FeedCommunityVm> followCommunity(String communityId) async {
    followedCommunityIds.add(communityId);
    if (communityId == 'investments') {
      return FeedCommunityVm(
        id: communityId,
        title: 'Investments',
        countryCode: 'KZ',
        cityId: 'almaty',
        cityName: 'Almaty',
        membersCount: 6326,
        followedByViewer: true,
      );
    }
    if (communityId == 'community-2') {
      return FeedCommunityVm(
        id: communityId,
        title: 'Blockchain&Crypto · da-nang',
        countryCode: 'VN',
        cityId: 'da-nang',
        cityName: 'Da Nang',
        membersCount: 2918,
        followedByViewer: true,
      );
    }
    return FeedCommunityVm(
      id: communityId,
      title: 'Almaty weekend hikes',
      subtitle: 'Mountain routes',
      membersCount: 1201,
      followedByViewer: true,
    );
  }

  @override
  Future<FeedCommunityVm> unfollowCommunity(String communityId) async {
    unfollowedCommunityIds.add(communityId);
    if (communityId == 'investments') {
      return FeedCommunityVm(
        id: communityId,
        title: 'Investments',
        countryCode: 'KZ',
        cityId: 'almaty',
        cityName: 'Almaty',
        membersCount: 6325,
      );
    }
    if (communityId == 'community-2') {
      return FeedCommunityVm(
        id: communityId,
        title: 'Blockchain&Crypto · da-nang',
        countryCode: 'VN',
        cityId: 'da-nang',
        cityName: 'Da Nang',
        membersCount: 2917,
      );
    }
    return FeedCommunityVm(
      id: communityId,
      title: 'Almaty weekend hikes',
      subtitle: 'Mountain routes',
      membersCount: 1200,
    );
  }

  @override
  Future<int> trackFeedEvents(List<FeedEventRequest> events) async {
    trackedEvents.addAll(events);
    return events.length;
  }
}

class _CommunityListCall {
  const _CommunityListCall({
    this.topic,
    this.countryCode,
    this.cityId,
    this.search,
    this.excludeFollowed = false,
    this.onlyFollowed = false,
  });

  final String? topic;
  final String? countryCode;
  final String? cityId;
  final String? search;
  final bool excludeFollowed;
  final bool onlyFollowed;
}

class _FakeFeedSubscriptionsApi implements FeedSubscriptionsApi {
  _FakeFeedSubscriptionsApi(this.result);

  final FeedSubscriptionsVm result;
  var calls = 0;

  @override
  Future<FeedSubscriptionsVm> getMySubscriptions({int limit = 20}) async {
    calls += 1;
    return result;
  }
}

class _FakeSessionProvider extends SessionProvider {
  _FakeSessionProvider(this._profile);

  final UserProfileVm _profile;

  @override
  UserProfileVm? get profile => _profile;
}

class _StaticHomeLocationProvider extends HomeLocationProvider {
  _StaticHomeLocationProvider(this._location);

  final HomeLocationPreference _location;

  @override
  HomeLocationPreference get effectiveLocation => _location;
}

class _AuthenticatedAuthProvider extends AuthProvider {
  _AuthenticatedAuthProvider();

  @override
  AuthState get state => AuthState.authenticated;
}

class _UnauthenticatedAuthProvider extends AuthProvider {
  _UnauthenticatedAuthProvider();

  @override
  AuthState get state => AuthState.unauthenticated;
}

class _PostCreateAllowedApi extends PostApi {
  @override
  Future<PostCreateEligibilityVm> checkCreateEligibility() async {
    return const PostCreateEligibilityVm(
      canCreate: true,
      limit: 10,
      remaining: 10,
      window: Duration(hours: 1),
      retryAfter: Duration.zero,
    );
  }
}

class _FeedPostActionApi extends _PostCreateAllowedApi {
  final List<String> likedPostIds = [];
  final List<String> unlikedPostIds = [];
  final List<String> sharedPostIds = [];

  @override
  Future<int> likePost(String postId) async {
    likedPostIds.add(postId);
    return 2;
  }

  @override
  Future<int> unlikePost(String postId) async {
    unlikedPostIds.add(postId);
    return 1;
  }

  @override
  Future<(String shareUrl, int shares)> sharePost(String postId) async {
    sharedPostIds.add(postId);
    return ('https://inflap.test/posts/$postId', 1);
  }
}

UserProfileVm _profile({required String userId}) {
  return UserProfileVm(
    userId: userId,
    status: 'ACTIVE',
    locale: 'en',
    timezone: 'Asia/Almaty',
    isProfileCompleted: true,
    roles: const [],
    followersCount: 0,
    isFollowedByMe: false,
    friendshipStatus: UserFriendshipStatus.none,
    nickname: 'Viewer',
  );
}

class _FeedCall {
  const _FeedCall({
    required this.surface,
    required this.tab,
    this.cursor,
    this.countryCode,
    this.cityId,
  });

  final String surface;
  final String tab;
  final String? cursor;
  final String? countryCode;
  final String? cityId;

  @override
  bool operator ==(Object other) {
    return other is _FeedCall &&
        surface == other.surface &&
        tab == other.tab &&
        cursor == other.cursor &&
        countryCode == other.countryCode &&
        cityId == other.cityId;
  }

  @override
  int get hashCode => Object.hash(surface, tab, cursor, countryCode, cityId);

  @override
  String toString() =>
      '_FeedCall(surface: $surface, tab: $tab, cursor: $cursor, '
      'countryCode: $countryCode, cityId: $cityId)';
}
