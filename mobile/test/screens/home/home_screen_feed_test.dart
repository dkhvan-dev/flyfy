import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/network/post_api.dart';
import 'package:inflap/features/activities/models/activity_category_vm.dart';
import 'package:inflap/features/activities/models/activity_list_item_vm.dart';
import 'package:inflap/features/places/data/place_api.dart';
import 'package:inflap/features/places/models/place_vm.dart';
import 'package:inflap/features/feed/data/feed_api.dart';
import 'package:inflap/features/feed/models/feed_block_vm.dart';
import 'package:inflap/features/profile/data/guide_api.dart';
import 'package:inflap/features/profile/models/guide_profile_vm.dart';
import 'package:inflap/features/profile/models/user_profile_vm.dart';
import 'package:inflap/features/stories/models/post_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/activity_provider.dart';
import 'package:inflap/providers/auth_provider.dart';
import 'package:inflap/providers/currency_rate_provider.dart';
import 'package:inflap/providers/home_location_provider.dart';
import 'package:inflap/providers/locale_provider.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/home/home_screen.dart';
import 'package:inflap/shared/widgets/app_localized_location_text.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('guest profile button opens public app settings', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      _homeApp(
        HomeScreen(
          feedApi: _FakeFeedApi(page: FeedPageVm(items: const [])),
          placeApi: _FakePlaceApi(),
          initialDataLoadDelay: Duration.zero,
          initialDataLoadStagger: Duration.zero,
          waitForFirstFrameRasterized: false,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-profile-button')));
    await tester.pumpAndSettle();

    expect(find.text('App settings route'), findsOneWidget);
  });

  testWidgets(
    'loads guest home trending posts from feed surface with location',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final feedApi = _FakeFeedApi(
        trendingPage: FeedPageVm(
          items: [
            FeedBlockVm(
              id: 'home-stories-tray',
              type: FeedBlockType.storiesTray,
              stories: const [],
            ),
            FeedBlockVm(
              id: 'home-post-card',
              type: FeedBlockType.postCard,
              post: _post(
                'hidden-courtyards-of-turkistan',
                postProfileKey: 'quick_post_v1',
              ),
            ),
            FeedBlockVm(
              id: 'home-post-card-2',
              type: FeedBlockType.postCard,
              post: _post(
                'danang-weekend-markets',
                title: 'Da Nang weekend markets',
              ),
            ),
            FeedBlockVm(
              id: 'home-post-card-3',
              type: FeedBlockType.postCard,
              post: _post('almaty-photo-walk', title: 'Almaty photo walk'),
            ),
            FeedBlockVm(
              id: 'home-post-card-4',
              type: FeedBlockType.postCard,
              post: _post('local-cafe-notes', title: 'Local cafe notes'),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        _homeApp(
          HomeScreen(
            feedApi: feedApi,
            placeApi: _FakePlaceApi(),
            initialDataLoadDelay: Duration.zero,
            initialDataLoadStagger: Duration.zero,
            waitForFirstFrameRasterized: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(feedApi.calls, [
        const _FeedCall(
          surface: 'home',
          tab: 'trending',
          countryCode: 'KZ',
          cityId: 'almaty',
          limit: 4,
        ),
      ]);
      expect(find.text('Trending now'), findsOneWidget);
      expect(find.text('For you'), findsNothing);
      expect(find.text('Hidden courtyards of Turkistan'), findsOneWidget);
      expect(find.text('Almaty photo walk'), findsOneWidget);
      expect(find.text('Local cafe notes'), findsNothing);
      expect(find.text('Silk Road notes'), findsNothing);

      await _revealLastHorizontalItem(
        tester,
        sectionTitle: find.text('Trending now'),
        dragCount: 3,
      );
      expect(find.text('Show all'), findsOneWidget);
    },
  );

  testWidgets(
    'reserves sparse cold-start posts for authenticated For you section',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final feedApi = _FakeFeedApi(
        page: FeedPageVm(
          items: [
            for (var index = 1; index <= 3; index++)
              FeedBlockVm(
                id: 'cold-start-post-$index',
                type: FeedBlockType.postCard,
                post: _post(
                  'cold-start-$index',
                  title: 'Cold start post $index',
                ),
              ),
          ],
        ),
      );

      await tester.pumpWidget(
        _homeApp(
          HomeScreen(
            feedApi: feedApi,
            placeApi: _FakePlaceApi(),
            initialDataLoadDelay: Duration.zero,
            initialDataLoadStagger: Duration.zero,
            waitForFirstFrameRasterized: false,
          ),
          authenticated: true,
        ),
      );

      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('For you'),
        520,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('For you'), findsOneWidget);
      expect(find.text('Posts picked for you will appear here.'), findsNothing);
      expect(find.text('Cold start post 2'), findsOneWidget);
      expect(find.text('Cold start post 3'), findsOneWidget);
    },
  );

  testWidgets(
    'loads independent trending and For you feeds without duplicates',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final feedApi = _FakeFeedApi(
        trendingPage: FeedPageVm(
          items: [
            FeedBlockVm(
              id: 'trending-shared',
              type: FeedBlockType.postCard,
              post: _post('shared-post', title: 'Shared ranking post'),
            ),
            FeedBlockVm(
              id: 'trending-2',
              type: FeedBlockType.postCard,
              post: _post('trending-2', title: 'Trending post 2'),
            ),
            FeedBlockVm(
              id: 'trending-3',
              type: FeedBlockType.postCard,
              post: _post('trending-3', title: 'Trending post 3'),
            ),
          ],
        ),
        page: FeedPageVm(
          items: [
            FeedBlockVm(
              id: 'for-you-shared',
              type: FeedBlockType.postCard,
              post: _post('shared-post', title: 'Shared ranking post'),
            ),
            for (var index = 1; index <= 11; index++)
              FeedBlockVm(
                id: 'for-you-$index',
                type: FeedBlockType.postCard,
                post: _post(
                  'personalized-$index',
                  title: 'Personalized post $index',
                ),
              ),
          ],
        ),
      );

      await tester.pumpWidget(
        _homeApp(
          HomeScreen(
            feedApi: feedApi,
            placeApi: _FakePlaceApi(),
            initialDataLoadDelay: Duration.zero,
            initialDataLoadStagger: Duration.zero,
            waitForFirstFrameRasterized: false,
          ),
          authenticated: true,
        ),
      );

      await tester.pumpAndSettle();

      expect(feedApi.calls, [
        const _FeedCall(
          surface: 'home',
          tab: 'trending',
          countryCode: 'KZ',
          cityId: 'almaty',
          limit: 4,
        ),
        const _FeedCall(
          surface: 'home',
          tab: 'for_you',
          countryCode: 'KZ',
          cityId: 'almaty',
          limit: 20,
        ),
      ]);
      expect(find.text('Shared ranking post'), findsOneWidget);
      for (var index = 1; index <= 10; index++) {
        expect(find.text('Personalized post $index'), findsOneWidget);
      }
      expect(find.text('Personalized post 11'), findsNothing);
    },
  );

  testWidgets(
    'renders smart quick discussions inline and opens the anchored community',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final feedApi = _FakeFeedApi(
        page: FeedPageVm(
          items: [
            FeedBlockVm(
              id: 'article-post',
              type: FeedBlockType.postCard,
              post: _post('article-post', title: 'City guide'),
            ),
            FeedBlockVm(
              id: 'quick-smart',
              type: FeedBlockType.postCard,
              post: _post(
                'quick-smart',
                title: 'Who wants to walk?',
                postProfileKey: 'quick_post_v1',
                communityId: 'community-1',
              ),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        _homeApp(
          HomeScreen(
            feedApi: feedApi,
            postApi: _FakePostApi(),
            placeApi: _FakePlaceApi(),
            initialDataLoadDelay: Duration.zero,
            initialDataLoadStagger: Duration.zero,
            waitForFirstFrameRasterized: false,
          ),
          authenticated: true,
        ),
      );

      await tester.pumpAndSettle();
      final quickPostCard = find.byKey(
        const ValueKey('quick-post-thread-quick-smart'),
      );
      await tester.scrollUntilVisible(
        quickPostCard,
        520,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(quickPostCard, findsOneWidget);
      final quickPostCardRect = tester.getRect(quickPostCard);
      await tester.tapAt(
        Offset(quickPostCardRect.right - 20, quickPostCardRect.top + 20),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Community route community-1 quick-smart'),
        findsOneWidget,
      );
      expect(find.text('Post route quick-smart'), findsNothing);
      expect(
        feedApi.trackedEvents,
        contains(
          isA<FeedEventRequest>()
              .having((event) => event.eventType, 'eventType', 'click')
              .having((event) => event.postId, 'postId', 'quick-smart'),
        ),
      );
    },
  );

  testWidgets('home header displays only the current city', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      _homeApp(
        HomeScreen(
          feedApi: _FakeFeedApi(page: FeedPageVm(items: const [])),
          placeApi: _FakePlaceApi(),
          initialDataLoadDelay: Duration.zero,
          initialDataLoadStagger: Duration.zero,
          waitForFirstFrameRasterized: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final headerLocation = tester.widget<AppLocalizedLocationText>(
      find.byType(AppLocalizedLocationText),
    );
    expect(headerLocation.cityName, 'Almaty');
    expect(headerLocation.countryCode, 'KZ');
    expect(headerLocation.includeCountry, isFalse);
  });

  testWidgets('home services preview opens all services instead of rates', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      _homeApp(
        HomeScreen(
          feedApi: _FakeFeedApi(page: FeedPageVm(items: const [])),
          placeApi: _FakePlaceApi(),
          initialDataLoadDelay: Duration.zero,
          initialDataLoadStagger: Duration.zero,
          waitForFirstFrameRasterized: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Services'), findsWidgets);
    expect(find.text('Help Center'), findsNothing);
    expect(find.text('Exchange Rates'), findsNothing);
    expect(find.text('All'), findsNothing);
    expect(find.text('Show all'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('All services'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('All services'));
    await tester.pumpAndSettle();

    expect(find.text('Services route'), findsOneWidget);
  });

  testWidgets('loads top destinations around current device coordinates', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final placeApi = _FakePlaceApi();

    await tester.pumpWidget(
      _homeApp(
        HomeScreen(
          feedApi: _FakeFeedApi(page: FeedPageVm(items: const [])),
          placeApi: placeApi,
          initialDataLoadDelay: Duration.zero,
          initialDataLoadStagger: Duration.zero,
          waitForFirstFrameRasterized: false,
        ),
        location: HomeLocationPreference(
          source: HomeLocationSource.detected,
          countryCode: 'KZ',
          cityId: 'almaty',
          cityName: 'Almaty',
          latitude: 43.238949,
          longitude: 76.889709,
          updatedAt: DateTime.utc(2026, 6, 17),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(placeApi.calls.single, {
      'countryCode': 'KZ',
      'cityId': 'almaty',
      'latitude': 43.238949,
      'longitude': 76.889709,
      'sort': 'distance',
      'locale': 'en',
      'limit': 10,
    });
  });

  testWidgets('top destinations append show all only when more places exist', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final places = List.generate(
      10,
      (index) => _place(id: 'place-$index', title: 'Destination $index'),
    );

    await tester.pumpWidget(
      _homeApp(
        HomeScreen(
          feedApi: _FakeFeedApi(page: FeedPageVm(items: const [])),
          placeApi: _FakePlaceApi(items: places, total: 11),
          initialDataLoadDelay: Duration.zero,
          initialDataLoadStagger: Duration.zero,
          waitForFirstFrameRasterized: false,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _revealLastHorizontalItem(
      tester,
      sectionTitle: find.text('Top Destinations'),
      dragCount: 8,
    );
    expect(find.text('Show all'), findsOneWidget);
    await tester.tap(find.text('Show all'));
    await tester.pumpAndSettle();

    expect(find.text('Places route'), findsOneWidget);
  });

  testWidgets(
    'loads top destinations within selected city when GPS is absent',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final placeApi = _FakePlaceApi();

      await tester.pumpWidget(
        _homeApp(
          HomeScreen(
            feedApi: _FakeFeedApi(page: FeedPageVm(items: const [])),
            placeApi: placeApi,
            initialDataLoadDelay: Duration.zero,
            initialDataLoadStagger: Duration.zero,
            waitForFirstFrameRasterized: false,
          ),
          location: HomeLocationPreference(
            source: HomeLocationSource.detected,
            countryCode: 'KZ',
            cityId: 'almaty',
            cityName: 'Almaty',
            updatedAt: DateTime.utc(2026, 6, 17),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(placeApi.calls.single, {
        'countryCode': 'KZ',
        'cityId': 'almaty',
        'sort': 'rating',
        'locale': 'en',
        'limit': 10,
      });
    },
  );

  testWidgets('loads the next home smart post page from feed cursor', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final feedApi = _FakeFeedApi(
      pages: [
        FeedPageVm(
          nextCursor: 'page-2',
          items: [
            for (final id in [
              'post-1',
              'post-2',
              'post-3',
              'post-4',
              'post-5',
              'post-6',
            ])
              FeedBlockVm(
                id: 'home-$id',
                type: FeedBlockType.postCard,
                post: _post(id, title: 'Home post $id'),
              ),
          ],
        ),
        FeedPageVm(
          items: [
            FeedBlockVm(
              id: 'home-post-7',
              type: FeedBlockType.postCard,
              post: _post('post-7', title: 'Home post post-7'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      _homeApp(
        HomeScreen(
          feedApi: feedApi,
          placeApi: _FakePlaceApi(),
          guideApi: _FakeGuideApi(),
          initialDataLoadDelay: Duration.zero,
          initialDataLoadStagger: Duration.zero,
          waitForFirstFrameRasterized: false,
        ),
        authenticated: true,
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Home post post-6'),
      520,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(feedApi.calls, [
      const _FeedCall(
        surface: 'home',
        tab: 'trending',
        countryCode: 'KZ',
        cityId: 'almaty',
        limit: 4,
      ),
      const _FeedCall(
        surface: 'home',
        tab: 'for_you',
        countryCode: 'KZ',
        cityId: 'almaty',
        limit: 20,
      ),
      const _FeedCall(
        surface: 'home',
        tab: 'for_you',
        cursor: 'page-2',
        countryCode: 'KZ',
        cityId: 'almaty',
        limit: 20,
      ),
    ]);
    expect(find.text('Home post post-7'), findsOneWidget);
  });

  testWidgets('tracks home top post clicks with feed block metadata', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final feedApi = _FakeFeedApi(
      trendingPage: FeedPageVm(
        items: [
          FeedBlockVm(
            id: 'home-post-card',
            type: FeedBlockType.postCard,
            post: _post('hidden-courtyards-of-turkistan'),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      _homeApp(
        HomeScreen(
          feedApi: feedApi,
          placeApi: _FakePlaceApi(),
          guideApi: _FakeGuideApi(),
          initialDataLoadDelay: Duration.zero,
          initialDataLoadStagger: Duration.zero,
          waitForFirstFrameRasterized: false,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Hidden courtyards of Turkistan'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hidden courtyards of Turkistan'));
    await tester.pumpAndSettle();

    expect(feedApi.trackedEvents, hasLength(1));
    final event = feedApi.trackedEvents.single;
    expect(event.eventType, 'click');
    expect(event.surface, 'home');
    expect(event.tab, 'trending');
    expect(event.blockId, 'home-post-card');
    expect(event.blockType, 'post_card');
    expect(event.postId, 'hidden-courtyards-of-turkistan');
    expect(event.metadata, {
      'entityType': 'post',
      'entityId': 'hidden-courtyards-of-turkistan',
    });
    expect(event.rank, 0);
  });

  testWidgets('opens home top posts through the post route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final feedApi = _FakeFeedApi(
      trendingPage: FeedPageVm(
        items: [
          FeedBlockVm(
            id: 'home-post-card',
            type: FeedBlockType.postCard,
            post: _post('hidden-courtyards-of-turkistan'),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      _homeApp(
        HomeScreen(
          feedApi: feedApi,
          placeApi: _FakePlaceApi(),
          guideApi: _FakeGuideApi(),
          initialDataLoadDelay: Duration.zero,
          initialDataLoadStagger: Duration.zero,
          waitForFirstFrameRasterized: false,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Hidden courtyards of Turkistan'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hidden courtyards of Turkistan'));
    await tester.pumpAndSettle();

    expect(
      find.text('Post route hidden-courtyards-of-turkistan'),
      findsOneWidget,
    );

    final click = feedApi.trackedEvents.single;
    expect(click.eventType, 'click');
    expect(click.blockType, 'post_card');
    expect(click.postId, 'hidden-courtyards-of-turkistan');
    expect(click.metadata, {
      'entityType': 'post',
      'entityId': 'hidden-courtyards-of-turkistan',
    });
  });

  testWidgets('does not render seen checkmarks on home top post cards', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final feedApi = _FakeFeedApi(
      trendingPage: FeedPageVm(
        items: [
          FeedBlockVm(
            id: 'home-post-card',
            type: FeedBlockType.postCard,
            post: _post('hidden-courtyards-of-turkistan', seenByViewer: true),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      _homeApp(
        HomeScreen(
          feedApi: feedApi,
          placeApi: _FakePlaceApi(),
          guideApi: _FakeGuideApi(),
          initialDataLoadDelay: Duration.zero,
          initialDataLoadStagger: Duration.zero,
          waitForFirstFrameRasterized: false,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Hidden courtyards of Turkistan'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('home-top-post-seen-hidden-courtyards-of-turkistan'),
      ),
      findsNothing,
    );
  });

  testWidgets('tracks top destination clicks as home conversion events', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final feedApi = _FakeFeedApi(page: FeedPageVm(items: const []));

    await tester.pumpWidget(
      _homeApp(
        HomeScreen(
          feedApi: feedApi,
          placeApi: _FakePlaceApi(items: [_place()]),
          initialDataLoadDelay: Duration.zero,
          initialDataLoadStagger: Duration.zero,
          waitForFirstFrameRasterized: false,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Dragon Bridge'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dragon Bridge'));
    await tester.pumpAndSettle();

    expect(feedApi.trackedEvents, hasLength(1));
    final event = feedApi.trackedEvents.single;
    expect(event.eventType, 'click');
    expect(event.surface, 'home');
    expect(event.tab, 'for_you');
    expect(event.blockId, 'home:top_destinations');
    expect(event.blockType, 'place_card');
    expect(event.postId, isNull);
    expect(event.rank, 0);
    expect(event.metadata['action'], 'conversion');
    expect(event.metadata['entityType'], 'place');
    expect(event.metadata['entityId'], 'place-1');
    expect(event.metadata['source'], 'home_top_destinations');
    expect(event.metadata['title'], 'Dragon Bridge');
    expect(event.metadata['tags'], ['bridge']);
  });

  testWidgets('tracks recommended activity clicks as home conversion events', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final feedApi = _FakeFeedApi(page: FeedPageVm(items: const []));

    await tester.pumpWidget(
      _homeApp(
        HomeScreen(
          feedApi: feedApi,
          placeApi: _FakePlaceApi(),
          guideApi: _FakeGuideApi(),
          initialDataLoadDelay: Duration.zero,
          initialDataLoadStagger: Duration.zero,
          waitForFirstFrameRasterized: false,
        ),
        activityProvider: _FakeActivityProvider(items: [_activity()]),
        authenticated: true,
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sunrise canyon walk'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunrise canyon walk'));
    await tester.pumpAndSettle();

    expect(feedApi.trackedEvents, hasLength(1));
    final event = feedApi.trackedEvents.single;
    expect(event.eventType, 'click');
    expect(event.surface, 'home');
    expect(event.tab, 'for_you');
    expect(event.blockId, 'home:recommended_activities');
    expect(event.blockType, 'activity_card');
    expect(event.postId, isNull);
    expect(event.rank, 0);
    expect(event.metadata['action'], 'conversion');
    expect(event.metadata['entityType'], 'activity');
    expect(event.metadata['entityId'], 'activity-1');
    expect(event.metadata['source'], 'home_recommended_activities');
    expect(event.metadata['title'], 'Sunrise canyon walk');
    expect(event.metadata['categorySlug'], 'walks');
    expect(event.metadata['tags'], ['hiking', 'family']);
  });

  testWidgets('tracks excursions service clicks as tour conversion events', (
    tester,
  ) async {
    final feedApi = await _tapHomeService(tester, 'Excursions');

    expect(feedApi.trackedEvents, hasLength(1));
    final tourEvent = feedApi.trackedEvents.single;
    expect(tourEvent.eventType, 'click');
    expect(tourEvent.blockId, 'home:services');
    expect(tourEvent.blockType, 'tour_card');
    expect(tourEvent.rank, 1);
    expect(tourEvent.metadata['action'], 'conversion');
    expect(tourEvent.metadata['entityType'], 'tour');
    expect(tourEvent.metadata['entityId'], 'excursions');
    expect(tourEvent.metadata['source'], 'home_services');
    expect(tourEvent.metadata['semanticTags'], ['tour', 'excursion']);
  });

  testWidgets('tracks guides service clicks as guide conversion events', (
    tester,
  ) async {
    final feedApi = await _tapHomeService(tester, 'Guides');

    expect(feedApi.trackedEvents, hasLength(1));
    final guideEvent = feedApi.trackedEvents.single;
    expect(guideEvent.eventType, 'click');
    expect(guideEvent.blockId, 'home:services');
    expect(guideEvent.blockType, 'guide_card');
    expect(guideEvent.rank, 2);
    expect(guideEvent.metadata['action'], 'conversion');
    expect(guideEvent.metadata['entityType'], 'guide');
    expect(guideEvent.metadata['entityId'], 'guides');
    expect(guideEvent.metadata['source'], 'home_services');
    expect(guideEvent.metadata['semanticTags'], ['guide', 'local_expert']);
  });
}

Finder _horizontalScrollables() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable &&
        (widget.axisDirection == AxisDirection.right ||
            widget.axisDirection == AxisDirection.left),
  );
}

Future<void> _revealLastHorizontalItem(
  WidgetTester tester, {
  required Finder sectionTitle,
  required int dragCount,
}) async {
  await tester.ensureVisible(sectionTitle);
  await tester.pumpAndSettle();

  final scrollable = _horizontalScrollables().last;
  for (var index = 0; index < dragCount; index++) {
    await tester.drag(scrollable, const Offset(-520, 0), warnIfMissed: false);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<_FakeFeedApi> _tapHomeService(
  WidgetTester tester,
  String serviceLabel,
) async {
  SharedPreferences.setMockInitialValues({});
  final feedApi = _FakeFeedApi(page: FeedPageVm(items: const []));

  await tester.pumpWidget(
    _homeApp(
      HomeScreen(
        feedApi: feedApi,
        placeApi: _FakePlaceApi(),
        initialDataLoadDelay: Duration.zero,
        initialDataLoadStagger: Duration.zero,
        waitForFirstFrameRasterized: false,
      ),
    ),
  );

  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text(serviceLabel),
    320,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(serviceLabel));
  await tester.pumpAndSettle();
  return feedApi;
}

Widget _homeApp(
  Widget home, {
  ActivityProvider? activityProvider,
  bool authenticated = false,
  HomeLocationPreference? location,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      GoRoute(
        path: '/posts/:slug',
        builder: (context, state) =>
            Scaffold(body: Text('Post route ${state.pathParameters['slug']}')),
      ),
      GoRoute(
        path: '/communities/:communityId',
        builder: (context, state) => Scaffold(
          body: Text(
            'Community route ${state.pathParameters['communityId']} '
            '${state.uri.queryParameters['postId']}',
          ),
        ),
      ),
      GoRoute(
        path: '/places/:id',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/activities/:id',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/excursions',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/guides',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/services',
        builder: (context, state) =>
            const Scaffold(body: Text('Services route')),
      ),
      GoRoute(
        path: '/places',
        builder: (context, state) => const Scaffold(body: Text('Places route')),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/app-settings',
        builder: (context, state) =>
            const Scaffold(body: Text('App settings route')),
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _FakeAuthProvider(
          authenticated ? AuthState.authenticated : AuthState.unauthenticated,
        ),
      ),
      ChangeNotifierProvider<SessionProvider>(
        create: (_) => _FakeSessionProvider(
          authenticated ? _profile() : null,
          authenticated
              ? SessionStatus.authenticated
              : SessionStatus.unauthenticated,
        ),
      ),
      ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
      ChangeNotifierProvider<CurrencyRateProvider>(
        create: (_) => CurrencyRateProvider(),
      ),
      ChangeNotifierProvider<HomeLocationProvider>(
        create: (_) => _FakeHomeLocationProvider(
          location ??
              HomeLocationPreference(
                source: HomeLocationSource.detected,
                countryCode: 'KZ',
                cityId: 'almaty',
                cityName: 'Almaty',
                updatedAt: DateTime.utc(2026, 6, 17),
              ),
        ),
      ),
      ChangeNotifierProvider<ActivityProvider>(
        create: (_) => activityProvider ?? _NoopActivityProvider(),
      ),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider(this._state);

  final AuthState _state;

  @override
  AuthState get state => _state;
}

class _FakeSessionProvider extends SessionProvider {
  _FakeSessionProvider(this._profile, this._status);

  final UserProfileVm? _profile;
  final SessionStatus _status;

  @override
  UserProfileVm? get profile => _profile;

  @override
  SessionStatus get status => _status;

  @override
  bool get isAuthenticated => _status == SessionStatus.authenticated;
}

class _FakeHomeLocationProvider extends HomeLocationProvider {
  _FakeHomeLocationProvider(this._location);

  final HomeLocationPreference _location;

  @override
  HomeLocationPreference get effectiveLocation => _location;

  @override
  bool get isLoaded => true;

  @override
  Future<void> load({String languageCode = 'en'}) async {}
}

class _NoopActivityProvider extends ActivityProvider {
  @override
  Future<void> loadActivityCategories({bool force = false}) async {}

  @override
  Future<void> loadActivities() async {}

  @override
  Future<void> loadJoinedActivities() async {}

  @override
  Future<void> loadMyActivities() async {}

  @override
  Future<void> refreshActivities() async {}
}

class _FakeActivityProvider extends ActivityProvider {
  _FakeActivityProvider({required this._items});

  final List<ActivityListItemVm> _items;

  @override
  ActivitiesState get state => ActivitiesState.success;

  @override
  List<ActivityListItemVm> get items => _items;

  @override
  List<ActivityCategoryVm> get categoryItems => const [];

  @override
  List<ActivityListItemVm> get joinedItems => const [];

  @override
  Future<void> loadActivityCategories({bool force = false}) async {}

  @override
  Future<void> loadActivities() async {}

  @override
  Future<void> loadJoinedActivities() async {}

  @override
  Future<void> loadMyActivities() async {}

  @override
  Future<void> refreshActivities() async {}
}

class _FakeGuideApi extends GuideApi {
  @override
  Future<GuideProfileVm?> getMyGuideProfileOrNull() async => null;
}

class _FakePlaceApi extends PlaceApi {
  _FakePlaceApi({this.items = const [], this.total});

  final List<PlaceVm> items;
  final int? total;
  final List<Map<String, Object?>> calls = [];

  @override
  Future<({List<PlaceVm> items, int total})> getPlaces({
    String? search,
    String? category,
    String? countryCode,
    String? cityId,
    String? accessCityId,
    double? priceMin,
    double? priceMax,
    int? durationMin,
    int? durationMax,
    String? durationUnit,
    int? spotsMin,
    double? minRating,
    String? sort,
    String? locale,
    double? latitude,
    double? longitude,
    int limit = 20,
    int offset = 0,
  }) async {
    calls.add(
      {
        'search': search,
        'category': category,
        'countryCode': countryCode,
        'cityId': cityId,
        'accessCityId': accessCityId,
        'priceMin': priceMin,
        'priceMax': priceMax,
        'durationMin': durationMin,
        'durationMax': durationMax,
        'durationUnit': durationUnit,
        'spotsMin': spotsMin,
        'minRating': minRating,
        'sort': sort,
        'locale': locale,
        'latitude': latitude,
        'longitude': longitude,
        'limit': limit,
        'offset': offset,
      }..removeWhere((_, value) => value == null || value == 0),
    );
    return (items: items, total: total ?? items.length);
  }
}

class _FakeFeedApi implements FeedApi {
  _FakeFeedApi({
    FeedPageVm? page,
    List<FeedPageVm>? pages,
    FeedPageVm? trendingPage,
  }) : _forYouPages = pages ?? [page ?? FeedPageVm(items: const [])],
       _trendingPage = trendingPage ?? FeedPageVm(items: const []);

  final List<FeedPageVm> _forYouPages;
  final FeedPageVm _trendingPage;
  int _forYouPageIndex = 0;
  final List<_FeedCall> calls = [];
  final List<FeedEventRequest> trackedEvents = [];

  @override
  Future<FeedPageVm> getFeed({
    String surface = 'home',
    String tab = 'for_you',
    String? cursor,
    String? countryCode,
    String? cityId,
    int limit = 20,
  }) async {
    calls.add(
      _FeedCall(
        surface: surface,
        tab: tab,
        cursor: cursor,
        countryCode: countryCode,
        cityId: cityId,
        limit: limit,
      ),
    );
    if (tab == 'trending') {
      return _trendingPage;
    }
    if (_forYouPageIndex >= _forYouPages.length) {
      return FeedPageVm(items: const []);
    }
    final page = _forYouPages[_forYouPageIndex];
    _forYouPageIndex += 1;
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
    trackedEvents.addAll(events);
    return events.length;
  }
}

class _FakePostApi extends PostApi {
  @override
  Future<List<PostCommentVm>> listComments(
    String postId, {
    int limit = 20,
    int offset = 0,
  }) async => const [];
}

class _FeedCall {
  const _FeedCall({
    required this.surface,
    required this.tab,
    required this.limit,
    this.cursor,
    this.countryCode,
    this.cityId,
  });

  final String surface;
  final String tab;
  final int limit;
  final String? cursor;
  final String? countryCode;
  final String? cityId;

  @override
  bool operator ==(Object other) {
    return other is _FeedCall &&
        surface == other.surface &&
        tab == other.tab &&
        limit == other.limit &&
        cursor == other.cursor &&
        countryCode == other.countryCode &&
        cityId == other.cityId;
  }

  @override
  int get hashCode =>
      Object.hash(surface, tab, limit, cursor, countryCode, cityId);

  @override
  String toString() {
    return '_FeedCall(surface: $surface, tab: $tab, limit: $limit, '
        'cursor: $cursor, countryCode: $countryCode, cityId: $cityId)';
  }
}

PostVm _post(
  String id, {
  String? title,
  bool seenByViewer = false,
  String postProfileKey = 'article_v1',
  String? communityId,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return PostVm(
    id: id,
    slug: id,
    title: title ?? 'Hidden courtyards of Turkistan',
    excerpt: 'A compact route for a slow travel day.',
    category: 'JOURNAL',
    status: 'PUBLISHED',
    format: 'ARTICLE',
    postProfileKey: postProfileKey,
    communityId: communityId,
    tags: const ['travel'],
    stats: PostStatsVm(views: 1, likes: 0, comments: 0, shares: 0),
    author: PostAuthorVm(
      userId: 'author-$id',
      locale: 'en',
      timezone: 'Asia/Almaty',
      nickname: 'Author',
    ),
    likedByViewer: false,
    seenByViewer: seenByViewer,
    shareUrl: 'https://inflap.test/posts/$id',
    createdAt: now,
    updatedAt: now,
  );
}

PlaceVm _place({String id = 'place-1', String title = 'Dragon Bridge'}) {
  return PlaceVm(
    id: id,
    locale: 'en',
    defaultLocale: 'en',
    title: title,
    description: 'A modern bridge across the Han River.',
    countryCode: 'VN',
    cityId: 'danang',
    locationSourceUrl: 'https://maps.example.test/dragon-bridge',
    category: 'architecture',
    rating: 4.8,
    reviewCount: 120,
    source: 'IMPORT',
    status: 'PUBLISHED',
    tags: const ['bridge'],
    visitInfo: PlaceVisitInfoVm.empty,
    translations: const {},
    media: const [],
    author: const PlaceAuthorVm(userId: 'author-1'),
    createdAt: '2026-05-27T00:00:00Z',
    updatedAt: '2026-05-27T00:00:00Z',
  );
}

ActivityListItemVm _activity() {
  final startAt = DateTime.now().toUtc().add(const Duration(days: 7));
  return ActivityListItemVm(
    id: 'activity-1',
    hostUserId: 'host-1',
    title: 'Sunrise canyon walk',
    description: 'Morning route with a local guide.',
    format: 'OFFLINE',
    status: 'PUBLISHED',
    moderationStatus: 'APPROVED',
    visibility: 'PUBLIC',
    joinMode: 'OPEN',
    categorySlug: 'walks',
    tags: const ['hiking', 'family'],
    languageCode: 'en',
    timezone: 'Asia/Almaty',
    startAt: startAt,
    endAt: startAt.add(const Duration(hours: 3)),
    capacityType: 'LIMITED',
    priceType: 'FREE',
    requiresProfileCompletion: false,
    requiresAttendanceConfirmation: false,
    cityName: 'Almaty',
    cityId: 'almaty',
    countryCode: 'KZ',
  );
}

UserProfileVm _profile() {
  return UserProfileVm(
    userId: 'viewer-1',
    status: 'ACTIVE',
    locale: 'en',
    timezone: 'Asia/Almaty',
    isProfileCompleted: true,
    roles: const [],
    followersCount: 0,
    isFollowedByMe: false,
    friendshipStatus: UserFriendshipStatus.none,
    nickname: 'Viewer',
    countryCode: 'KZ',
  );
}
