import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/features/activities/models/activity_category_vm.dart';
import 'package:inflap/features/activities/models/activity_list_item_vm.dart';
import 'package:inflap/features/attractions/data/attraction_api.dart';
import 'package:inflap/features/attractions/models/attraction_vm.dart';
import 'package:inflap/features/feed/data/feed_api.dart';
import 'package:inflap/features/feed/models/feed_block_vm.dart';
import 'package:inflap/features/stories/models/post_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/activity_provider.dart';
import 'package:inflap/providers/auth_provider.dart';
import 'package:inflap/providers/home_location_provider.dart';
import 'package:inflap/providers/locale_provider.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('loads home top posts from feed surface and ignores stories', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final feedApi = _FakeFeedApi(
      page: FeedPageVm(
        items: [
          FeedBlockVm(
            id: 'home-stories-tray',
            type: FeedBlockType.storiesTray,
            stories: const [],
          ),
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
          attractionApi: _FakeAttractionApi(),
          initialDataLoadDelay: Duration.zero,
          initialDataLoadStagger: Duration.zero,
          waitForFirstFrameRasterized: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(feedApi.calls, [
      const _FeedCall(surface: 'home', tab: 'for_you', limit: 20),
    ]);
    expect(find.text('Top Posts'), findsOneWidget);
    expect(find.text('Hidden courtyards of Turkistan'), findsOneWidget);
    expect(find.text('Silk Road notes'), findsNothing);
  });

  testWidgets('tracks home top post clicks with feed block metadata', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final feedApi = _FakeFeedApi(
      page: FeedPageVm(
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
          attractionApi: _FakeAttractionApi(),
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
    expect(event.tab, 'for_you');
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
      page: FeedPageVm(
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
          attractionApi: _FakeAttractionApi(),
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
      page: FeedPageVm(
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
          attractionApi: _FakeAttractionApi(),
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
          attractionApi: _FakeAttractionApi(items: [_attraction()]),
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
    expect(event.blockType, 'attraction_card');
    expect(event.postId, isNull);
    expect(event.rank, 0);
    expect(event.metadata['action'], 'conversion');
    expect(event.metadata['entityType'], 'attraction');
    expect(event.metadata['entityId'], 'attraction-1');
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
          attractionApi: _FakeAttractionApi(),
          initialDataLoadDelay: Duration.zero,
          initialDataLoadStagger: Duration.zero,
          waitForFirstFrameRasterized: false,
        ),
        activityProvider: _FakeActivityProvider(items: [_activity()]),
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
        attractionApi: _FakeAttractionApi(),
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

Widget _homeApp(Widget home, {ActivityProvider? activityProvider}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      GoRoute(
        path: '/posts/:slug',
        builder: (context, state) =>
            Scaffold(body: Text('Post route ${state.pathParameters['slug']}')),
      ),
      GoRoute(
        path: '/attractions/:id',
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
        path: '/login',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<SessionProvider>(create: (_) => SessionProvider()),
      ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
      ChangeNotifierProvider<HomeLocationProvider>(
        create: (_) => _NoopHomeLocationProvider(),
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

class _NoopHomeLocationProvider extends HomeLocationProvider {
  @override
  Future<void> load({
    String languageCode = 'en',
    HomeLocationPreference? profileFallback,
  }) async {}
}

class _NoopActivityProvider extends ActivityProvider {
  @override
  Future<void> loadActivityCategories({bool force = false}) async {}

  @override
  Future<void> loadActivities() async {}

  @override
  Future<void> loadJoinedActivities() async {}

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
  Future<void> refreshActivities() async {}
}

class _FakeAttractionApi extends AttractionApi {
  _FakeAttractionApi({this.items = const []});

  final List<AttractionVm> items;

  @override
  Future<({List<AttractionVm> items, int total})> getAttractions({
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
    int limit = 20,
    int offset = 0,
  }) async {
    return (items: items, total: items.length);
  }
}

class _FakeFeedApi implements FeedApi {
  _FakeFeedApi({required this.page});

  final FeedPageVm page;
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

PostVm _post(String id, {bool seenByViewer = false}) {
  final now = DateTime.utc(2026, 1, 1);
  return PostVm(
    id: id,
    slug: id,
    title: 'Hidden courtyards of Turkistan',
    excerpt: 'A compact route for a slow travel day.',
    category: 'JOURNAL',
    status: 'PUBLISHED',
    format: 'ARTICLE',
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

AttractionVm _attraction() {
  return AttractionVm(
    id: 'attraction-1',
    locale: 'en',
    defaultLocale: 'en',
    title: 'Dragon Bridge',
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
    visitInfo: AttractionVisitInfoVm.empty,
    translations: const {},
    media: const [],
    author: const AttractionAuthorVm(userId: 'author-1'),
    createdAt: '2026-05-27T00:00:00Z',
    updatedAt: '2026-05-27T00:00:00Z',
  );
}

ActivityListItemVm _activity() {
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
    startAt: DateTime.utc(2026, 6, 20, 5),
    endAt: DateTime.utc(2026, 6, 20, 8),
    capacityType: 'LIMITED',
    priceType: 'FREE',
    requiresProfileCompletion: false,
    requiresAttendanceConfirmation: false,
    cityName: 'Almaty',
    cityId: 'almaty',
    countryCode: 'KZ',
  );
}
