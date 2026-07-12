import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/file_api.dart';
import '../../core/network/post_api.dart';
import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_notification_header_button.dart';
import '../../features/activities/activity_cover_url.dart';
import '../../features/activities/activity_taxonomy_resolver.dart';
import '../../features/activities/models/activity_category_vm.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/places/place_ui.dart';
import '../../features/places/data/place_api.dart';
import '../../features/places/models/place_vm.dart';
import '../../features/feed/data/feed_api.dart';
import '../../features/feed/models/feed_block_vm.dart';
import '../../features/feed/widgets/contextual_story_tray.dart';
import '../../features/feed/widgets/feed_post_content_card.dart';
import '../../features/feed/widgets/feed_post_card.dart';
import '../../features/feed/widgets/quick_post_thread_card.dart';
import '../../features/profile/data/guide_api.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../features/services/service_catalog.dart';
import '../../features/services/widgets/service_grid.dart';
import '../../features/stories/models/story_vm.dart';
import '../../features/stories/models/post_vm.dart';
import '../../features/stories/story_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_rate_provider.dart';
import '../../providers/home_location_provider.dart';
import '../../providers/session_provider.dart';
import '../../shared/widgets/app_city_filter_section.dart';
import '../../shared/widgets/app_localized_location_text.dart';
import 'widgets/home_location_picker_sheet.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.feedApi,
    this.postApi,
    this.placeApi,
    this.guideApi,
    this.initialDataLoadDelay = _initialHomeDataDelay,
    this.initialDataLoadStagger = _initialHomeDataStagger,
    this.waitForFirstFrameRasterized = true,
  });

  static const _initialHomeDataDelay = Duration(milliseconds: 350);
  static const _initialHomeDataStagger = Duration(milliseconds: 160);

  final FeedApi? feedApi;
  final PostApi? postApi;
  final PlaceApi? placeApi;
  final GuideApi? guideApi;
  final Duration initialDataLoadDelay;
  final Duration initialDataLoadStagger;
  final bool waitForFirstFrameRasterized;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _homeTrendingPostLimit = 3;
  static const _homeForYouPostLimit = 10;
  static const _homeFeedPageLimit = 20;
  static const _homeLocationStartupTimeout = Duration(seconds: 2);

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final ScrollController _scrollController = ScrollController();
  late final PlaceApi _placeApi = widget.placeApi ?? PlaceApi();
  late final FeedApi _feedApi = widget.feedApi ?? FeedApi();
  late final PostApi _postApi = widget.postApi ?? PostApi();
  String? _requestedHostedActivitiesForUserId;
  String? _requestedJoinedActivitiesForUserId;
  String? _requestedTopPlacesRequestKey;
  List<PlaceVm> _topPlaces = const [];
  int _topPlacesTotal = 0;
  List<StoryVm> _homeStoryTrayStories = const [];
  List<_HomePostFeedItem> _homeTrendingFeedItems = const [];
  List<_HomePostFeedItem> _homePostFeedItems = const [];
  Map<String, _HomePostFeedEventTarget> _topPostFeedTargets = const {};
  String? _homePostFeedNextCursor;
  String? _requestedHomeFeedCountryCode;
  String? _requestedHomeFeedCityId;
  bool? _requestedHomeFeedAuthenticated;
  bool _topPlacesLoading = true;
  bool _topPlacesLoadFailed = false;
  bool _topPostsLoading = true;
  bool _topPostsLoadFailed = false;
  bool _homePostFeedLoading = true;
  bool _homePostFeedLoadFailed = false;
  bool _homeTrendingHasMore = false;
  bool _homePostFeedLoadingMore = false;
  bool _homePostFeedLoadMoreFailed = false;
  bool _topPostsRequestStarted = false;
  bool _initialHomeDataLoadScheduled = false;
  int _homeFeedRequestGeneration = 0;

  static const _promoYachtImageUrl =
      'https://images.unsplash.com/photo-1567899378494-47b22a2ae96a?auto=format&fit=crop&w=900&q=80';
  static const _promoMountainImageUrl =
      'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=900&q=80';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleHomeScroll);
    _scheduleInitialDataLoad();
  }

  void _handleHomeScroll() {
    if (!_scrollController.hasClients ||
        _homePostFeedNextCursor == null ||
        _homePostFeedLoading ||
        _homePostFeedLoadingMore) {
      return;
    }

    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels > 720) {
      return;
    }
    unawaited(_loadHomeFeed(append: true));
  }

  void _scheduleInitialDataLoad() {
    if (_initialHomeDataLoadScheduled) return;
    _initialHomeDataLoadScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_runInitialDataLoad());
    });
  }

  Future<void> _runInitialDataLoad() async {
    if (widget.waitForFirstFrameRasterized) {
      await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    }
    await Future<void>.delayed(widget.initialDataLoadDelay);
    if (!mounted) return;

    final provider = context.read<ActivityProvider>();
    final sessionProvider = context.read<SessionProvider>();
    final homeLocationProvider = context.read<HomeLocationProvider>();
    final languageCode = Localizations.localeOf(context).languageCode;

    try {
      await homeLocationProvider
          .load(languageCode: languageCode)
          .timeout(_homeLocationStartupTimeout);
    } catch (_) {
      // Discovery location is a startup convenience; slow device geolocation
      // must not block public home content from loading.
    }

    if (!mounted) return;
    if (provider.categoryState == ActivitiesState.initial &&
        provider.categoryItems.isEmpty) {
      final categoryLoad = provider.loadActivityCategories();
      unawaited(categoryLoad);
    }

    await Future<void>.delayed(widget.initialDataLoadStagger);
    if (!mounted) return;
    if (provider.state == ActivitiesState.initial && provider.items.isEmpty) {
      final activitiesLoad = provider.loadActivities();
      unawaited(activitiesLoad);
    }

    await Future<void>.delayed(widget.initialDataLoadStagger);
    if (!mounted) return;
    final currentUserId = (sessionProvider.profile?.userId ?? '').trim();
    if (currentUserId.isNotEmpty &&
        provider.joinedState == ActivitiesState.initial &&
        provider.joinedItems.isEmpty) {
      final joinedLoad = provider.loadJoinedActivities();
      unawaited(joinedLoad);
    }

    await Future<void>.delayed(widget.initialDataLoadStagger);
    if (!mounted) return;
    unawaited(_loadTopPlaces());

    await Future<void>.delayed(widget.initialDataLoadStagger);
    if (!mounted) return;
    unawaited(_loadHomeFeed());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleHomeScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleHomeNavTap() {
    FocusManager.instance.primaryFocus?.unfocus();
    final refresh =
        _refreshIndicatorKey.currentState?.show() ?? _refreshActivities();
    unawaited(refresh);

    if (!_scrollController.hasClients) {
      context.go('/');
      return;
    }

    unawaited(
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _openProfile() {
    final isAuthenticated =
        context.read<AuthProvider>().state == AuthState.authenticated;
    context.push(isAuthenticated ? '/profile' : '/app-settings');
  }

  void _openActivities() {
    context.push('/activities');
  }

  void _openSearch() {
    context.push('/search');
  }

  void _openFeed() {
    context.push('/feed');
  }

  void _openTopPost(PostVm post) {
    _trackTopPostClick(post);
    if (post.isQuickPost) {
      final communityId = (post.communityId ?? '').trim();
      final postId = post.id.trim();
      if (communityId.isEmpty || postId.isEmpty) {
        return;
      }
      final uri = Uri(
        path: '/communities/${Uri.encodeComponent(communityId)}',
        queryParameters: {'postId': postId},
      );
      context.push(uri.toString());
      return;
    }

    final slug = post.slug.trim();
    if (slug.isEmpty) {
      return;
    }
    context.push('/posts/${Uri.encodeComponent(slug)}', extra: post);
  }

  void _trackTopPostClick(PostVm post) {
    _trackHomePostEvent(post, FeedEventTypes.click);
  }

  void _trackHomeQuickPostEngagement(PostVm post, String eventType) {
    final normalizedEventType = eventType.trim();
    if (normalizedEventType != FeedEventTypes.like &&
        normalizedEventType != FeedEventTypes.comment) {
      return;
    }
    _trackHomePostEvent(
      post,
      normalizedEventType,
      metadata: {'engagementType': normalizedEventType},
    );
  }

  void _trackHomePostEvent(
    PostVm post,
    String eventType, {
    Map<String, Object?> metadata = const {},
  }) {
    final postKey = _homePostKey(post);
    final postId = post.id.trim();
    if (postKey.isEmpty || postId.isEmpty) {
      return;
    }

    final target = _topPostFeedTargets[postKey];
    if (target == null) {
      return;
    }

    _trackHomeFeedEvents([
      FeedEventRequest(
        eventId: _homeFeedUuidV4(),
        eventType: eventType,
        surface: 'home',
        tab: target.tab,
        blockId: target.blockId,
        blockType: target.blockType,
        postId: postId,
        rank: target.rank,
        occurredAt: DateTime.now().toUtc(),
        metadata: {'entityType': 'post', 'entityId': postId, ...metadata},
      ),
    ]);
  }

  void _trackHomeEntityConversionClick({
    required String blockId,
    required String blockType,
    required String entityType,
    required String entityId,
    required String source,
    required int rank,
    Map<String, Object?> metadata = const {},
  }) {
    final normalizedEntityId = entityId.trim();
    if (normalizedEntityId.isEmpty) {
      return;
    }

    final eventMetadata = <String, Object?>{
      'action': 'conversion',
      'entityType': entityType.trim(),
      'entityId': normalizedEntityId,
      'source': source.trim(),
    };
    for (final entry in metadata.entries) {
      final key = entry.key.trim();
      final value = entry.value;
      if (key.isEmpty || value == null) {
        continue;
      }
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          eventMetadata[key] = trimmed;
        }
        continue;
      }
      if (value is bool || value is num) {
        eventMetadata[key] = value;
        continue;
      }
      if (value is Iterable) {
        final items = value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty && item.length <= 64)
            .take(20)
            .toList(growable: false);
        if (items.isNotEmpty) {
          eventMetadata[key] = items;
        }
      }
    }

    _trackHomeFeedEvents([
      FeedEventRequest(
        eventId: _homeFeedUuidV4(),
        eventType: 'click',
        surface: 'home',
        tab: 'for_you',
        blockId: blockId,
        blockType: blockType,
        rank: rank < 0 ? 0 : rank,
        occurredAt: DateTime.now().toUtc(),
        metadata: eventMetadata,
      ),
    ]);
  }

  void _trackHomeFeedEvents(List<FeedEventRequest> events) {
    if (events.isEmpty) {
      return;
    }
    unawaited(_sendHomeFeedEvents(events));
  }

  Future<void> _sendHomeFeedEvents(List<FeedEventRequest> events) async {
    try {
      await _feedApi.trackFeedEvents(events);
    } catch (_) {
      // Feed analytics should never block the Home browsing flow.
    }
  }

  void _openPlaces() {
    context.push('/places');
  }

  void _openServices() {
    context.push('/services');
  }

  void _openService(TravelServiceEntry service) {
    if (!service.isAvailable || service.route.trim().isEmpty) return;
    final conversionTarget = _homeServiceConversionTarget(service);
    if (conversionTarget != null) {
      _trackHomeEntityConversionClick(
        blockId: 'home:services',
        blockType: conversionTarget.blockType,
        entityType: conversionTarget.entityType,
        entityId: conversionTarget.entityId,
        source: 'home_services',
        rank: conversionTarget.rank,
        metadata: {
          'title': service.title,
          'route': service.route,
          'categorySlug': conversionTarget.categorySlug,
          'semanticTags': conversionTarget.semanticTags,
        },
      );
    }
    context.push(service.route);
  }

  void _openPlaceDetails(PlaceVm place) {
    final placeId = place.id.trim();
    final rank = _topPlaces.indexWhere((item) => item.id.trim() == placeId);
    _trackHomeEntityConversionClick(
      blockId: 'home:top_destinations',
      blockType: 'place_card',
      entityType: 'place',
      entityId: placeId,
      source: 'home_top_destinations',
      rank: rank,
      metadata: {
        'title': place.title,
        'category': place.category,
        'countryCode': place.countryCode,
        'cityId': place.cityId,
        'tags': place.tags,
      },
    );
    context.push('/places/${place.id}', extra: place);
  }

  void _openRecommendedActivityDetails(ActivityListItemVm activity, int rank) {
    final activityId = activity.id.trim();
    final localizedCopy = activity.localizedCopy(
      Localizations.localeOf(context).languageCode,
    );
    _trackHomeEntityConversionClick(
      blockId: 'home:recommended_activities',
      blockType: 'activity_card',
      entityType: 'activity',
      entityId: activityId,
      source: 'home_recommended_activities',
      rank: rank,
      metadata: {
        'title': localizedCopy.title,
        'categorySlug': activity.categorySlug,
        'format': activity.format,
        'countryCode': activity.countryCode,
        'cityId': activity.cityId,
        'tags': activity.tags,
      },
    );
    _openActivityDetailsById(activityId);
  }

  void _openActivityDetailsById(String activityId) {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.state != AuthState.authenticated) {
      context.push('/login?from=/activities/$activityId');
      return;
    }

    context.push('/activities/$activityId');
  }

  Future<void> _refreshActivities() async {
    final provider = context.read<ActivityProvider>();
    final currentUserId =
        (context.read<SessionProvider>().profile?.userId ?? '').trim();
    await provider.refreshActivities();
    await provider.loadActivityCategories(force: true);
    if (currentUserId.isNotEmpty) {
      await Future.wait<void>([
        provider.refreshMyActivities(),
        provider.refreshJoinedActivities(),
      ]);
    }
    await Future.wait<void>([
      _loadTopPlaces(force: true),
      _loadHomeFeed(force: true),
    ]);
  }

  Future<void> _openLocationSheet() async {
    final changed = await showAppModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: AppPalette.transparent,
      barrierColor: AppPalette.black.withValues(alpha: 0.58),
      builder: (_) => HomeLocationPickerSheet(
        profile: context.read<SessionProvider>().profile,
      ),
    );

    if (changed == true && mounted) {
      await context.read<ActivityProvider>().refreshActivities();
    }
  }

  List<_PromoCardData> _buildPromoCards(AppLocalizations l10n) {
    return [
      _PromoCardData(
        eyebrow: l10n.homePromoExclusive,
        title: l10n.homePromoYachtTitle,
        description: l10n.homePromoYachtDescription,
        imageUrl: _promoYachtImageUrl,
      ),
      _PromoCardData(
        eyebrow: l10n.homePromoAdventure,
        title: l10n.homePromoMountainTitle,
        description: l10n.homePromoMountainDescription,
        imageUrl: _promoMountainImageUrl,
      ),
    ];
  }

  Future<void> _loadTopPlaces({bool force = false}) async {
    if (!mounted) return;

    final locale = Localizations.localeOf(context).languageCode;
    final location = context.read<HomeLocationProvider>().effectiveLocation;
    final latitude = _validHomeLatitude(location.latitude);
    final longitude = _validHomeLongitude(location.longitude);
    final hasCoordinates = latitude != null && longitude != null;
    final countryCode = _trimmedHomeStringOrNull(location.countryCode);
    final cityId = _trimmedHomeStringOrNull(location.cityId);
    final requestKey = _topPlacesRequestKey(
      locale: locale,
      countryCode: countryCode,
      cityId: cityId,
      latitude: latitude,
      longitude: longitude,
    );
    if (!force &&
        _requestedTopPlacesRequestKey == requestKey &&
        (_topPlaces.isNotEmpty || _topPlacesLoading)) {
      return;
    }

    _requestedTopPlacesRequestKey = requestKey;
    setState(() {
      _topPlacesLoading = _topPlaces.isEmpty;
      _topPlacesLoadFailed = false;
    });

    try {
      final result = await _placeApi.getPlaces(
        countryCode: countryCode,
        cityId: cityId,
        sort: hasCoordinates ? 'distance' : 'rating',
        locale: locale,
        latitude: hasCoordinates ? latitude : null,
        longitude: hasCoordinates ? longitude : null,
        limit: 10,
      );
      if (!mounted || _requestedTopPlacesRequestKey != requestKey) return;
      final topPlaces = result.items.take(10).toList(growable: false);
      setState(() {
        _topPlaces = topPlaces;
        _topPlacesTotal = max(result.total, topPlaces.length);
        _topPlacesLoading = false;
      });
    } catch (_) {
      if (!mounted || _requestedTopPlacesRequestKey != requestKey) return;
      setState(() {
        _topPlacesLoading = false;
        _topPlacesLoadFailed = true;
      });
    }
  }

  Future<void> _loadHomeFeed({bool force = false, bool append = false}) async {
    if (!mounted) return;

    final location = context.read<HomeLocationProvider>().effectiveLocation;
    final isAuthenticated =
        context.read<AuthProvider>().state == AuthState.authenticated;
    final currentCountryCode = _trimmedHomeStringOrNull(location.countryCode);
    final currentCityId = _trimmedHomeStringOrNull(location.cityId);
    final requestCountryCode = append
        ? (_requestedHomeFeedCountryCode ?? currentCountryCode)
        : currentCountryCode;
    final requestCityId = append
        ? (_requestedHomeFeedCityId ?? currentCityId)
        : currentCityId;
    final feedContextChanged =
        !append &&
        (_requestedHomeFeedCountryCode != requestCountryCode ||
            _requestedHomeFeedCityId != requestCityId ||
            _requestedHomeFeedAuthenticated != isAuthenticated);
    final shouldForce = force || feedContextChanged;
    final cursor = append ? _homePostFeedNextCursor : null;
    if (append &&
        (!isAuthenticated ||
            cursor == null ||
            _homePostFeedLoadingMore ||
            _homePostFeedItems.length >= _homeForYouPostLimit)) {
      return;
    }
    if (!append &&
        !shouldForce &&
        _topPostsRequestStarted &&
        (_homeTrendingFeedItems.isNotEmpty ||
            _homePostFeedItems.isNotEmpty ||
            _topPostsLoading ||
            _homePostFeedLoading)) {
      return;
    }

    _topPostsRequestStarted = true;
    if (append) {
      final generation = _homeFeedRequestGeneration;
      setState(() {
        _homePostFeedLoadingMore = true;
        _homePostFeedLoadMoreFailed = false;
      });
      final result = await _requestHomeFeedPage(
        tab: 'for_you',
        cursor: cursor,
        countryCode: requestCountryCode,
        cityId: requestCityId,
        limit: _homeFeedPageLimit,
      );
      if (!mounted || generation != _homeFeedRequestGeneration) return;
      setState(() {
        _homePostFeedLoadingMore = false;
        if (result.page == null) {
          _homePostFeedLoadMoreFailed = true;
          return;
        }
        final incoming = _homePostFeedItemsFromFeedBlocks(
          result.page!.items,
          tab: 'for_you',
        );
        final deduplicated = _excludeHomePostKeys(
          incoming,
          _homeTrendingFeedItems.map((item) => _homePostKey(item.post)),
        );
        _homePostFeedItems = _mergeHomePostFeedItems(
          _homePostFeedItems,
          deduplicated,
        ).take(_homeForYouPostLimit).toList(growable: false);
        _homePostFeedNextCursor =
            _homePostFeedItems.length >= _homeForYouPostLimit
            ? null
            : _trimmedHomeStringOrNull(result.page!.nextCursor);
        _homePostFeedLoadMoreFailed = false;
        _topPostFeedTargets = _homePostEventTargets(
          _homeTrendingFeedItems,
          _homePostFeedItems,
        );
      });
      return;
    }

    final generation = ++_homeFeedRequestGeneration;
    setState(() {
      _topPostsLoading = _homeTrendingFeedItems.isEmpty || shouldForce;
      _topPostsLoadFailed = false;
      _homePostFeedLoading =
          isAuthenticated && (_homePostFeedItems.isEmpty || shouldForce);
      _homePostFeedLoadFailed = false;
      _homePostFeedLoadingMore = false;
      _homePostFeedLoadMoreFailed = false;
      _requestedHomeFeedCountryCode = requestCountryCode;
      _requestedHomeFeedCityId = requestCityId;
      _requestedHomeFeedAuthenticated = isAuthenticated;
      if (shouldForce) {
        _homePostFeedNextCursor = null;
      }
      if (!isAuthenticated) {
        _homePostFeedItems = const [];
        _homePostFeedNextCursor = null;
      }
    });

    final requests = <Future<_HomeFeedPageResult>>[
      _requestHomeFeedPage(
        tab: 'trending',
        countryCode: requestCountryCode,
        cityId: requestCityId,
        limit: _homeTrendingPostLimit + 1,
      ),
      if (isAuthenticated)
        _requestHomeFeedPage(
          tab: 'for_you',
          countryCode: requestCountryCode,
          cityId: requestCityId,
          limit: _homeFeedPageLimit,
        ),
    ];
    final results = await Future.wait(requests);
    if (!mounted || generation != _homeFeedRequestGeneration) return;

    final trendingResult = results.first;
    final forYouResult = isAuthenticated ? results[1] : null;
    setState(() {
      if (trendingResult.page != null) {
        final trendingItems = _homePostFeedItemsFromFeedBlocks(
          trendingResult.page!.items,
          tab: 'trending',
        );
        _homeTrendingHasMore =
            trendingItems.length > _homeTrendingPostLimit ||
            _trimmedHomeStringOrNull(trendingResult.page!.nextCursor) != null;
        _homeTrendingFeedItems = trendingItems
            .take(_homeTrendingPostLimit)
            .toList(growable: false);
        _topPostsLoadFailed = false;
      } else {
        _topPostsLoadFailed = true;
      }
      _topPostsLoading = false;

      if (isAuthenticated) {
        if (forYouResult?.page != null) {
          _homeStoryTrayStories = _homeStoryTrayStoriesFromFeedBlocks(
            forYouResult!.page!.items,
          );
          final forYouItems = _homePostFeedItemsFromFeedBlocks(
            forYouResult.page!.items,
            tab: 'for_you',
          );
          _homePostFeedItems = _excludeHomePostKeys(
            forYouItems,
            _homeTrendingFeedItems.map((item) => _homePostKey(item.post)),
          ).take(_homeForYouPostLimit).toList(growable: false);
          _homePostFeedNextCursor =
              _homePostFeedItems.length >= _homeForYouPostLimit
              ? null
              : _trimmedHomeStringOrNull(forYouResult.page!.nextCursor);
          _homePostFeedLoadFailed = false;
        } else {
          _homePostFeedLoadFailed = true;
        }
      }
      _homePostFeedLoading = false;
      _topPostFeedTargets = _homePostEventTargets(
        _homeTrendingFeedItems,
        _homePostFeedItems,
      );
    });
  }

  Future<_HomeFeedPageResult> _requestHomeFeedPage({
    required String tab,
    String? cursor,
    String? countryCode,
    String? cityId,
    required int limit,
  }) async {
    try {
      final page = await _feedApi.getFeed(
        surface: 'home',
        tab: tab,
        cursor: cursor,
        countryCode: countryCode,
        cityId: cityId,
        limit: limit,
      );
      return _HomeFeedPageResult.success(page);
    } catch (_) {
      return const _HomeFeedPageResult.failure();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final session = context.watch<SessionProvider>();
    final activityProvider = context.watch<ActivityProvider>();
    final homeLocationProvider = context.watch<HomeLocationProvider>();
    final isLoggedIn = auth.state == AuthState.authenticated;
    final profile = session.profile;
    final currentUserId = (profile?.userId ?? '').trim();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (!_initialHomeDataLoadScheduled &&
        !homeLocationProvider.isLoaded &&
        !homeLocationProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<HomeLocationProvider>().load(languageCode: languageCode);
      });
    }
    final homeLocation = homeLocationProvider.effectiveLocation;
    final promos = _buildPromoCards(l10n);
    final servicesPreview = _homeServicesPreview(l10n);
    final recommendedActivities = _filterHomeRecommendedItems(
      publicItems: activityProvider.items,
      location: homeLocation,
    );
    final topPosts = _homeTrendingFeedItems
        .map((item) => item.post)
        .toList(growable: false);
    final homePostStreamItems = _homePostFeedItems;
    final hasMoreTopPlaces = _topPlacesTotal > _topPlaces.length;
    final hasMoreTopPosts = _homeTrendingHasMore;
    final feedCountryCode = _trimmedHomeStringOrNull(homeLocation.countryCode);
    final feedCityId = _trimmedHomeStringOrNull(homeLocation.cityId);
    final homeFeedLocationChanged =
        _topPostsRequestStarted &&
        !_topPostsLoading &&
        !_homePostFeedLoading &&
        !_homePostFeedLoadingMore &&
        (_requestedHomeFeedCountryCode != feedCountryCode ||
            _requestedHomeFeedCityId != feedCityId ||
            _requestedHomeFeedAuthenticated != isLoggedIn);
    if (homeFeedLocationChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_loadHomeFeed(force: true));
      });
    }

    if (currentUserId.isEmpty) {
      _requestedHostedActivitiesForUserId = null;
      _requestedJoinedActivitiesForUserId = null;
    } else if (_requestedHostedActivitiesForUserId != currentUserId &&
        activityProvider.myState != ActivitiesState.loading) {
      _requestedHostedActivitiesForUserId = currentUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ActivityProvider>().loadMyActivities();
      });
    }

    if (currentUserId.isNotEmpty &&
        _requestedJoinedActivitiesForUserId != currentUserId &&
        activityProvider.joinedState != ActivitiesState.loading) {
      _requestedJoinedActivitiesForUserId = currentUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ActivityProvider>().loadJoinedActivities();
      });
    }

    final topPlacesLatitude = _validHomeLatitude(homeLocation.latitude);
    final topPlacesLongitude = _validHomeLongitude(homeLocation.longitude);
    final topPlacesRequestKey = _topPlacesRequestKey(
      locale: languageCode,
      countryCode: feedCountryCode,
      cityId: feedCityId,
      latitude: topPlacesLatitude,
      longitude: topPlacesLongitude,
    );
    if (_requestedTopPlacesRequestKey != topPlacesRequestKey &&
        !_topPlacesLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadTopPlaces(force: true);
      });
    }

    final colors = AppDesignSystem.colorsFor(context);
    final isDarkV2 = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value:
            (isDarkV2 ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(
                  statusBarColor: colors.transparent,
                  statusBarIconBrightness: isDarkV2
                      ? Brightness.light
                      : Brightness.dark,
                  statusBarBrightness: isDarkV2
                      ? Brightness.dark
                      : Brightness.light,
                ),
        child: Scaffold(
          backgroundColor: colors.background,
          bottomNavigationBar: CommonBottomNavigationBar(
            activeItem: AppBottomNavItem.home,
            onHomeTap: _handleHomeNavTap,
            onQrTap: () => context.push('/qr'),
            onMapTap: () => context.push('/map'),
            onServicesTap: _openServices,
            onChatsTap: () => context.push('/chats'),
            style: AppBottomNavigationBarStyle.v2(context),
          ),
          body: DecoratedBox(
            decoration: AppBoxDecoration(color: colors.background),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: AppBoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: _homeBackgroundGradientColors(
                            colors,
                            Theme.of(context).brightness,
                          ),
                          stops: _homeBackgroundGradientStops(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      _HomeHeader(
                        location: homeLocation,
                        profile: profile,
                        onLocationTap: _openLocationSheet,
                        onProfileTap: _openProfile,
                        onNotificationsTap: () =>
                            context.push('/notifications'),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          key: _refreshIndicatorKey,
                          color: AppPalette.primary,
                          onRefresh: _refreshActivities,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 375;
                              final horizontalPadding = isCompact ? 13.0 : 16.0;

                              return CustomScrollView(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                slivers: [
                                  SliverPadding(
                                    padding: AppEdgeInsets.fromLTRB(
                                      horizontalPadding,
                                      isCompact ? 24 : 29,
                                      horizontalPadding,
                                      32,
                                    ),
                                    sliver: SliverToBoxAdapter(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _SearchBar(
                                            hint: l10n.homeSearchHint,
                                            onTap: _openSearch,
                                          ),
                                          if (isLoggedIn) ...[
                                            const SizedBox(height: 16),
                                            ContextualStoryTrayBlock(
                                              surface: 'home',
                                              stories: _homeStoryTrayStories,
                                              viewerAvatarFileId:
                                                  profile?.avatarFileId,
                                              viewerInitials:
                                                  profile?.initials ?? 'F',
                                              viewerUserId: profile?.userId,
                                            ),
                                            SizedBox(
                                              height: isCompact ? 10 : 14,
                                            ),
                                          ] else
                                            SizedBox(
                                              height: isCompact ? 24 : 30,
                                            ),
                                          _SectionHeader(
                                            title: l10n.servicesSectionTitle,
                                          ),
                                          const SizedBox(height: 14),
                                          ServiceGrid(
                                            services: servicesPreview,
                                            style: ServiceGridStyle.v2(context),
                                            onServiceTap: _openService,
                                          ),
                                          SizedBox(height: isCompact ? 38 : 52),
                                          _PromoCarousel(promos: promos),
                                          SizedBox(height: isCompact ? 20 : 24),
                                          _SectionHeader(
                                            title: l10n.homeTopDestinations,
                                            actionLabel: _topPlaces.isNotEmpty
                                                ? l10n.homeSeeAll
                                                : null,
                                            onActionTap: _topPlaces.isNotEmpty
                                                ? _openPlaces
                                                : null,
                                          ),
                                          const SizedBox(height: 14),
                                          _TopDestinationsRow(
                                            places: _topPlaces,
                                            isLoading: _topPlacesLoading,
                                            hasError: _topPlacesLoadFailed,
                                            onPlaceTap: _openPlaceDetails,
                                            onRetry: () =>
                                                _loadTopPlaces(force: true),
                                            showAllAction: hasMoreTopPlaces,
                                            onShowAllTap: _openPlaces,
                                          ),
                                          SizedBox(height: isCompact ? 30 : 34),
                                          _SectionHeader(
                                            title: l10n.homeTopStories,
                                            actionLabel: topPosts.isNotEmpty
                                                ? l10n.homeSeeAll
                                                : null,
                                            onActionTap: topPosts.isNotEmpty
                                                ? _openFeed
                                                : null,
                                          ),
                                          const SizedBox(height: 14),
                                          _TopPostsCarousel(
                                            posts: topPosts,
                                            isLoading: _topPostsLoading,
                                            hasError: _topPostsLoadFailed,
                                            onPostTap: _openTopPost,
                                            onRetry: () =>
                                                _loadHomeFeed(force: true),
                                            showAllAction: hasMoreTopPosts,
                                            onShowAllTap: _openFeed,
                                          ),
                                          SizedBox(height: isCompact ? 30 : 34),
                                          _SectionHeader(
                                            title:
                                                l10n.homeRecommendedActivities,
                                            actionLabel:
                                                recommendedActivities.isNotEmpty
                                                ? l10n.homeSeeAll
                                                : null,
                                            onActionTap:
                                                recommendedActivities.isNotEmpty
                                                ? _openActivities
                                                : null,
                                          ),
                                          const SizedBox(height: 16),
                                          _RecommendedActivitiesSection(
                                            provider: activityProvider,
                                            recommendedItems:
                                                recommendedActivities,
                                            l10n: l10n,
                                            currentUserId: currentUserId,
                                            onRetry: () {
                                              _refreshActivities();
                                            },
                                            onActivityTap:
                                                _openRecommendedActivityDetails,
                                          ),
                                          if (isLoggedIn) ...[
                                            SizedBox(
                                              height: isCompact ? 30 : 34,
                                            ),
                                            _SectionHeader(
                                              title: l10n.homeSmartPostsTitle,
                                              actionLabel:
                                                  homePostStreamItems.isNotEmpty
                                                  ? l10n.homeSeeAll
                                                  : null,
                                              onActionTap:
                                                  homePostStreamItems.isNotEmpty
                                                  ? _openFeed
                                                  : null,
                                            ),
                                            const SizedBox(height: 16),
                                            _HomeSmartPostsSection(
                                              items: homePostStreamItems,
                                              postApi: _postApi,
                                              canInteract: isLoggedIn,
                                              isLoading:
                                                  _homePostFeedLoading &&
                                                  _homePostFeedItems.isEmpty,
                                              hasError:
                                                  _homePostFeedLoadFailed &&
                                                  _homePostFeedItems.isEmpty,
                                              isLoadingMore:
                                                  _homePostFeedLoadingMore,
                                              hasLoadMoreError:
                                                  _homePostFeedLoadMoreFailed,
                                              onPostTap: _openTopPost,
                                              onQuickPostEngagement:
                                                  _trackHomeQuickPostEngagement,
                                              onRetry: () =>
                                                  _loadHomeFeed(force: true),
                                              onLoadMoreRetry: () =>
                                                  _loadHomeFeed(append: true),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeServiceConversionTarget {
  const _HomeServiceConversionTarget({
    required this.blockType,
    required this.entityType,
    required this.entityId,
    required this.rank,
    required this.categorySlug,
    required this.semanticTags,
  });

  final String blockType;
  final String entityType;
  final String entityId;
  final int rank;
  final String categorySlug;
  final List<String> semanticTags;
}

_HomeServiceConversionTarget? _homeServiceConversionTarget(
  TravelServiceEntry service,
) {
  return switch (service.route.trim()) {
    '/excursions' => const _HomeServiceConversionTarget(
      blockType: 'tour_card',
      entityType: 'tour',
      entityId: 'excursions',
      rank: 1,
      categorySlug: 'tour',
      semanticTags: ['tour', 'excursion'],
    ),
    '/guides' => const _HomeServiceConversionTarget(
      blockType: 'guide_card',
      entityType: 'guide',
      entityId: 'guides',
      rank: 2,
      categorySlug: 'guide',
      semanticTags: ['guide', 'local_expert'],
    ),
    _ => null,
  };
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.location,
    required this.profile,
    required this.onLocationTap,
    required this.onProfileTap,
    required this.onNotificationsTap,
  });

  final HomeLocationPreference location;
  final UserProfileVm? profile;
  final VoidCallback onLocationTap;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 375;
    final buttonSize = isCompact ? 38.0 : 40.0;

    return Container(
      padding: AppEdgeInsets.fromLTRB(16, 12, 16, isCompact ? 13 : 14),
      decoration: AppBoxDecoration(
        color: AppPalette.transparent,
        border: Border(
          bottom: BorderSide(color: AppPalette.primary.withValues(alpha: 0.10)),
        ),
      ),
      child: Row(
        children: [
          _HeaderAvatarButton(
            profile: profile,
            size: buttonSize,
            onTap: onProfileTap,
          ),
          Expanded(
            child: Center(
              child: Material(
                color: AppPalette.transparent,
                child: InkWell(
                  onTap: onLocationTap,
                  borderRadius: AppBorderRadius.circular(22),
                  child: Padding(
                    padding: AppEdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 10,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isCompact ? 34 : 38,
                          height: isCompact ? 34 : 38,
                          decoration: AppBoxDecoration(
                            shape: BoxShape.circle,
                            color: AppPalette.primary.withValues(alpha: 0.13),
                            border: Border.all(
                              color: AppPalette.primary.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: AppPalette.primary,
                            size: isCompact ? 18 : 20,
                          ),
                        ),
                        SizedBox(width: isCompact ? 8 : 10),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: AppLocalizedLocationText(
                                      countryCode: location.countryCode,
                                      cityId: location.cityId,
                                      cityName: location.cityName,
                                      fallbackText: location.fallbackLabel,
                                      includeCountry: false,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyle(
                                        color: context.appColors.textPrimary,
                                        fontSize: isCompact ? 16 : 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.expand_more_rounded,
                                    color: context.appColors.textSecondary
                                        .withValues(alpha: 0.72),
                                    size: isCompact ? 14 : 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          AppNotificationHeaderButton(
            tooltip: AppLocalizations.of(context)!.notificationsTitle,
            size: buttonSize,
            onTap: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderAvatarButton extends StatelessWidget {
  const _HeaderAvatarButton({
    required this.profile,
    required this.onTap,
    required this.size,
  });

  final UserProfileVm? profile;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final avatarUrl = resolvePublicFileContentUrl(
      (profile?.avatarFileId ?? '').trim(),
    );
    final initials = _normalizedInitials(profile?.initials);
    final fallbackAvatar = profile == null
        ? _HeaderAvatarFallbackIcon(iconSize: size < 46 ? 20 : 22)
        : _HeaderAvatarInitials(initials: initials);

    return Semantics(
      key: const ValueKey('home-profile-button'),
      button: true,
      enabled: true,
      label: profile == null
          ? l10n.profileSettingsPageTitle
          : l10n.myProfileTitle,
      child: Material(
        color: AppPalette.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.circular(999),
          child: Ink(
            width: size,
            height: size,
            decoration: AppBoxDecoration(
              color: AppPalette.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppPalette.primary.withValues(alpha: 0.24),
              ),
            ),
            child: ClipOval(
              child: ExcludeSemantics(
                child: avatarUrl == null
                    ? fallbackAvatar
                    : Image.network(
                        avatarUrl,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => fallbackAvatar,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _normalizedInitials(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'I';
    return value.length <= 2 ? value.toUpperCase() : value.substring(0, 2);
  }
}

class _HeaderAvatarInitials extends StatelessWidget {
  const _HeaderAvatarInitials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(color: AppPalette.transparent),
      child: Center(
        child: Text(
          initials,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: AppTextStyle(
            color: context.appColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _HeaderAvatarFallbackIcon extends StatelessWidget {
  const _HeaderAvatarFallbackIcon({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        color: AppPalette.primary,
        size: iconSize,
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 375;
    final isDarkV2 = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: AppPalette.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: isCompact ? 50 : 55),
          child: Ink(
            padding: AppEdgeInsets.symmetric(horizontal: isCompact ? 16 : 18),
            decoration: AppBoxDecoration(
              color: context.appColors.surfaceRaised,
              borderRadius: AppBorderRadius.circular(999),
              border: Border.all(
                color: AppPalette.primary.withValues(alpha: 0.20),
              ),
              boxShadow: isDarkV2
                  ? [
                      BoxShadow(
                        color: AppPalette.black.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.search_rounded, color: AppPalette.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      color: context.appColors.textMuted,
                      fontSize: isCompact ? 15 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 375;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyle(
              color: context.appColors.textPrimary,
              fontSize: isCompact ? 19 : 20,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: AppBorderRadius.circular(999),
            child: Padding(
              padding: const AppEdgeInsets.symmetric(
                horizontal: 2,
                vertical: 4,
              ),
              child: Text(
                actionLabel!,
                style: AppTextStyle(
                  color: AppPalette.primary,
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PromoCarousel extends StatelessWidget {
  const _PromoCarousel({required this.promos});

  final List<_PromoCardData> promos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final isCompact = viewportWidth < 375;
        final textScale = _homeTextScaleFactor(context);
        final cardWidth = viewportWidth * (isCompact ? 0.86 : 0.84);
        final visualHeight = cardWidth * 0.63;
        final cardHeight = _homePromoCardHeight(
          visualHeight: visualHeight,
          isCompact: isCompact,
          textScale: textScale,
        );

        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Column(
            children: [
              SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  itemCount: promos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: cardWidth,
                      child: _PromoCard(data: promos[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.data});

  final _PromoCardData data;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 375;
    final promoScrimGradient = _homePromoImageScrimGradient(context);

    return Material(
      color: AppPalette.transparent,
      child: Ink(
        decoration: AppBoxDecoration(
          borderRadius: AppBorderRadius.circular(14),
          border: Border.all(color: context.appColors.border),
          boxShadow: _homeDarkV2CardShadow(
            context,
            alpha: 0.22,
            blurRadius: 35,
            offset: const Offset(0, 14),
          ),
        ),
        child: ClipRRect(
          borderRadius: AppBorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _NetworkCardImage(imageUrl: data.imageUrl),
              if (promoScrimGradient != null)
                DecoratedBox(
                  decoration: AppBoxDecoration(gradient: promoScrimGradient),
                ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.66,
                child: Padding(
                  padding: AppEdgeInsets.symmetric(
                    horizontal: isCompact ? 20 : 24,
                    vertical: isCompact ? 22 : 28,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final panelHorizontalPadding =
                          Theme.of(context).brightness == Brightness.dark
                          ? 0.0
                          : (isCompact ? 10.0 : 12.0);
                      final maxTextWidth =
                          constraints.maxWidth - panelHorizontalPadding * 2;

                      return _PromoTextContrastPanel(
                        isCompact: isCompact,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxTextWidth > 0
                                  ? maxTextWidth
                                  : constraints.maxWidth,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.eyebrow,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle(
                                    color: AppPalette.primary,
                                    fontSize: isCompact ? 9 : 10,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle(
                                    color: context.appColors.textPrimary,
                                    fontSize: isCompact ? 20 : 22,
                                    height: 1.08,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  data.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle(
                                    color: context.appColors.textSecondary,
                                    fontSize: isCompact ? 12 : 13,
                                    height: 1.32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoTextContrastPanel extends StatelessWidget {
  const _PromoTextContrastPanel({required this.isCompact, required this.child});

  final bool isCompact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) return child;

    final colors = AppDesignSystem.colorsFor(context);
    return ClipRRect(
      borderRadius: AppBorderRadius.circular(14),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: colors.surface.withValues(alpha: 0.82),
          borderRadius: AppBorderRadius.circular(14),
          border: Border.all(color: colors.border.withValues(alpha: 0.88)),
        ),
        child: Padding(
          padding: AppEdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 12,
            vertical: isCompact ? 8 : 10,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _TopDestinationsRow extends StatelessWidget {
  const _TopDestinationsRow({
    required this.places,
    required this.isLoading,
    required this.hasError,
    required this.onPlaceTap,
    required this.onRetry,
    required this.showAllAction,
    required this.onShowAllTap,
  });

  final List<PlaceVm> places;
  final bool isLoading;
  final bool hasError;
  final ValueChanged<PlaceVm> onPlaceTap;
  final VoidCallback onRetry;
  final bool showAllAction;
  final VoidCallback onShowAllTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 375;
        final textScale = _homeTextScaleFactor(context);
        final gap = isCompact ? 14.0 : 18.0;
        final cardWidth = (constraints.maxWidth * (isCompact ? 0.46 : 0.43))
            .clamp(142.0, 180.0)
            .toDouble();
        final imageHeight = cardWidth / 0.74;
        final cardHeight = _homeTopDestinationCardHeight(
          imageHeight: imageHeight,
          isCompact: isCompact,
          textScale: textScale,
        );

        if (isLoading && places.isEmpty) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: SizedBox(
              height: cardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                itemCount: 5,
                separatorBuilder: (_, _) => SizedBox(width: gap),
                itemBuilder: (_, _) => SizedBox(
                  width: cardWidth,
                  child: const _TopDestinationLoadingCard(),
                ),
              ),
            ),
          );
        }

        if (hasError && places.isEmpty) {
          return _TopDestinationMessage(
            icon: Icons.cloud_off_rounded,
            message: l10n.placesLoadFailed,
            actionLabel: l10n.retryButton,
            onActionTap: onRetry,
          );
        }

        if (places.isEmpty) {
          return _TopDestinationMessage(
            icon: Icons.landscape_rounded,
            message: l10n.placesNoResults,
          );
        }

        final items = places.take(10).toList(growable: false);
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: items.length + (showAllAction ? 1 : 0),
              separatorBuilder: (_, _) => SizedBox(width: gap),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return _HomeShowAllCarouselCard(
                    width: cardWidth,
                    height: cardHeight,
                    onTap: onShowAllTap,
                  );
                }
                final place = items[index];
                return SizedBox(
                  width: cardWidth,
                  child: _TopDestinationPlaceCard(
                    place: place,
                    onTap: () => onPlaceTap(place),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _TopDestinationPlaceCard extends StatelessWidget {
  const _TopDestinationPlaceCard({required this.place, required this.onTap});

  final PlaceVm place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCompact = MediaQuery.sizeOf(context).width < 375;
    final textScale = _homeTextScaleFactor(context);
    final titleFontSize = isCompact ? 16.0 : 17.0;
    final titleLineHeight = 1.16;
    final titleStyle = AppTextStyle(
      color: context.appColors.textPrimary,
      fontSize: titleFontSize,
      height: titleLineHeight,
      fontWeight: FontWeight.w900,
    );
    final titleBlockHeight = _homeTopDestinationTitleBlockHeight(
      isCompact: isCompact,
      textScale: textScale,
    );
    final coverMedia = place.coverMedia;
    final coverUrl = _resolveHomePlaceImageUrl(coverMedia);
    final categoryLabel = _homePlaceCategoryLabel(l10n, place);
    final imageScrimGradient = _homeBottomImageScrimGradient(
      context,
      darkEndAlpha: 0.58,
      stops: const [0.48, 1],
    );

    return Material(
      color: AppPalette.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: AspectRatio(
                aspectRatio: 0.74,
                child: Ink(
                  decoration: AppBoxDecoration(
                    borderRadius: AppBorderRadius.circular(10),
                    border: Border.all(color: context.appColors.border),
                    boxShadow: _homeDarkV2CardShadow(
                      context,
                      alpha: 0.24,
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: AppBorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (coverUrl == null)
                          const _PlaceCardImagePlaceholder()
                        else
                          _PlaceCardNetworkImage(
                            imageUrl: coverUrl,
                            logicalWidth:
                                MediaQuery.sizeOf(context).width * 0.5,
                          ),
                        if (imageScrimGradient != null)
                          DecoratedBox(
                            decoration: AppBoxDecoration(
                              gradient: imageScrimGradient,
                            ),
                          ),
                        const Positioned(
                          top: 9,
                          right: 9,
                          child: _DestinationBookmarkBadge(),
                        ),
                        Positioned(
                          left: isCompact ? 12 : 16,
                          right: isCompact ? 12 : 16,
                          bottom: 15,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _DestinationTag(label: categoryLabel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 13),
            SizedBox(
              height: titleBlockHeight,
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  place.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                  strutStyle: StrutStyle(
                    fontSize: titleFontSize,
                    height: titleLineHeight,
                    forceStrutHeight: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatPlacePriceLabel(
                      context,
                      l10n,
                      place,
                      preferredCurrency: context
                          .watch<SessionProvider>()
                          .profile
                          ?.currency,
                      currencyRates: context.watch<CurrencyRateProvider>(),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      color: context.appColors.secondary,
                      fontSize: isCompact ? 12 : 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '★ ${place.rating.toStringAsFixed(1)}',
                  style: AppTextStyle(
                    color: AppPalette.primary,
                    fontSize: isCompact ? 13 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationBookmarkBadge extends StatelessWidget {
  const _DestinationBookmarkBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        shape: BoxShape.circle,
        color: AppPalette.secondary.withValues(alpha: 0.24),
        border: Border.all(color: AppPalette.secondary.withValues(alpha: 0.36)),
      ),
      child: const SizedBox(
        width: 38,
        height: 38,
        child: Icon(
          Icons.bookmark_border_rounded,
          color: AppPalette.secondarySoft,
          size: 23,
        ),
      ),
    );
  }
}

class _DestinationTag extends StatelessWidget {
  const _DestinationTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.primary,
        borderRadius: AppBorderRadius.circular(999),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle(
            color: context.appColors.textPrimary,
            fontSize: 10,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PlaceCardNetworkImage extends StatelessWidget {
  const _PlaceCardNetworkImage({
    required this.imageUrl,
    required this.logicalWidth,
  });

  final String imageUrl;
  final double logicalWidth;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      headers: placeImageRequestHeaders(imageUrl),
      fit: BoxFit.cover,
      cacheWidth: placeImageTargetWidth(
        context,
        logicalWidth,
        minWidth: 360,
        maxWidth: 720,
      ),
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const _PlaceCardImagePlaceholder();
      },
      errorBuilder: (_, _, _) => const _PlaceCardImagePlaceholder(),
    );
  }
}

class _PlaceCardImagePlaceholder extends StatelessWidget {
  const _PlaceCardImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.white.withValues(alpha: 0.05),
      ),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          color: context.appColors.textMuted,
          size: 40,
        ),
      ),
    );
  }
}

class _TopDestinationLoadingCard extends StatelessWidget {
  const _TopDestinationLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 0.74,
          child: DecoratedBox(
            decoration: AppBoxDecoration(
              color: AppPalette.white.withValues(alpha: 0.07),
              borderRadius: AppBorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 13),
        const _SkeletonLine(width: double.infinity),
        const SizedBox(height: 8),
        const _SkeletonLine(width: 92),
      ],
    );
  }
}

class _TopDestinationMessage extends StatelessWidget {
  const _TopDestinationMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final textScale = _homeTextScaleFactor(context);
    final hasAction = actionLabel != null && onActionTap != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedAction = constraints.maxWidth < 340 || textScale > 1.25;

        return DecoratedBox(
          decoration: AppBoxDecoration(
            color: AppPalette.white.withValues(alpha: 0.05),
            borderRadius: AppBorderRadius.circular(22),
            border: Border.all(color: context.appColors.borderSoft),
          ),
          child: Padding(
            padding: const AppEdgeInsets.all(18),
            child: useStackedAction
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            icon,
                            color: context.appColors.textMuted,
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: _TopDestinationMessageText(message)),
                        ],
                      ),
                      if (hasAction) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _TopDestinationMessageAction(
                            label: actionLabel!,
                            onTap: onActionTap!,
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Icon(icon, color: context.appColors.textMuted, size: 28),
                      const SizedBox(width: 14),
                      Expanded(child: _TopDestinationMessageText(message)),
                      if (hasAction) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _TopDestinationMessageAction(
                              label: actionLabel!,
                              onTap: onActionTap!,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _TopDestinationMessageText extends StatelessWidget {
  const _TopDestinationMessageText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: AppTextStyle(
        color: context.appColors.textSecondary,
        fontSize: 14,
        height: 1.35,
      ),
    );
  }
}

class _TopDestinationMessageAction extends StatelessWidget {
  const _TopDestinationMessageAction({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle(
          color: AppPalette.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HomeShowAllCarouselCard extends StatelessWidget {
  const _HomeShowAllCarouselCard({
    required this.width,
    required this.height,
    required this.onTap,
  });

  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final radius = AppBorderRadius.circular(18);

    return SizedBox(
      width: width,
      height: height,
      child: Semantics(
        button: true,
        label: l10n.homeShowAllCard,
        child: Material(
          color: AppPalette.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Ink(
              decoration: AppBoxDecoration(
                color: context.appColors.surfaceRaised,
                borderRadius: radius,
                border: Border.all(color: context.appColors.borderPrimary),
              ),
              child: Padding(
                padding: const AppEdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DecoratedBox(
                      decoration: AppBoxDecoration(
                        color: context.appColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: 48,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: context.appColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.homeShowAllCard,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyle(
                        color: context.appColors.textPrimary,
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopPostsCarousel extends StatelessWidget {
  const _TopPostsCarousel({
    required this.posts,
    required this.isLoading,
    required this.hasError,
    required this.onPostTap,
    required this.onRetry,
    required this.showAllAction,
    required this.onShowAllTap,
  });

  final List<PostVm> posts;
  final bool isLoading;
  final bool hasError;
  final ValueChanged<PostVm> onPostTap;
  final VoidCallback onRetry;
  final bool showAllAction;
  final VoidCallback onShowAllTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 375;
        final textScale = _homeTextScaleFactor(context);
        final gap = isCompact ? 14.0 : 18.0;
        final cardWidth = (constraints.maxWidth * (isCompact ? 0.78 : 0.70))
            .clamp(238.0, 304.0)
            .toDouble();
        final imageHeight = (cardWidth * 0.60).clamp(142.0, 184.0).toDouble();
        final loadingCardHeight =
            imageHeight + (isCompact ? 166.0 : 170.0) * textScale;

        if (isLoading && posts.isEmpty) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: SizedBox(
              height: loadingCardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                itemCount: 5,
                separatorBuilder: (_, _) => SizedBox(width: gap),
                itemBuilder: (_, _) => SizedBox(
                  width: cardWidth,
                  child: _TopPostLoadingCard(imageHeight: imageHeight),
                ),
              ),
            ),
          );
        }

        if (hasError && posts.isEmpty) {
          return _TopDestinationMessage(
            icon: Icons.cloud_off_rounded,
            message: l10n.storyLoadFailed,
            actionLabel: l10n.retryButton,
            onActionTap: onRetry,
          );
        }

        if (posts.isEmpty) {
          return _TopDestinationMessage(
            icon: Icons.auto_stories_rounded,
            message: l10n.storyEmptyTitle,
          );
        }

        final items = posts.take(5).toList(growable: false);
        final cardHeight = _homePostCardHeight(
          context: context,
          l10n: l10n,
          posts: items,
          cardWidth: cardWidth,
          imageHeight: imageHeight,
          isCompact: isCompact,
          textScale: textScale,
        );
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: items.length + (showAllAction ? 1 : 0),
              separatorBuilder: (_, _) => SizedBox(width: gap),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return _HomeShowAllCarouselCard(
                    width: cardWidth,
                    height: cardHeight,
                    onTap: onShowAllTap,
                  );
                }
                final post = items[index];
                return SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: _TopPostCard(
                    post: post,
                    imageHeight: imageHeight,
                    onTap: () => onPostTap(post),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _TopPostCard extends StatelessWidget {
  const _TopPostCard({
    required this.post,
    required this.imageHeight,
    required this.onTap,
  });

  final PostVm post;
  final double imageHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCompact = MediaQuery.sizeOf(context).width < 375;
    final textScale = _homeTextScaleFactor(context);
    final titleFontSize = isCompact ? 16.0 : 17.0;
    final titleLineHeight = 1.14;
    final excerptFontSize = isCompact ? 12.0 : 12.5;
    final excerptLineHeight = 1.34;
    final titleStyle = AppTextStyle(
      color: context.appColors.textPrimary,
      fontSize: titleFontSize,
      height: titleLineHeight,
      fontWeight: FontWeight.w900,
    );
    final excerptStyle = AppTextStyle(
      color: context.appColors.textSecondary,
      fontSize: excerptFontSize,
      height: excerptLineHeight,
      fontWeight: FontWeight.w500,
    );
    final tagLabel = _homePostTagLabel(l10n, post);
    final excerpt = _truncateHomePostExcerpt(
      post.excerpt.trim().isNotEmpty ? post.excerpt.trim() : tagLabel,
    );
    final avatarSize = (isCompact ? 24.0 : 26.0) * textScale.clamp(1.0, 1.18);
    final isExpired = post.isExpired;
    final isInteractive = !isExpired;
    final coverScrimGradient = _homeBottomImageScrimGradient(
      context,
      darkStartAlpha: 0.08,
      darkEndAlpha: 0.62,
      stops: const [0.42, 1],
    );
    final borderColor = isExpired
        ? AppPalette.white.withValues(alpha: 0.04)
        : AppPalette.primary.withValues(alpha: 0.18);

    return Opacity(
      opacity: isExpired ? 0.56 : 1,
      child: Material(
        color: AppPalette.transparent,
        child: InkWell(
          key: ValueKey('open-home-top-post-${post.id}'),
          onTap: isInteractive ? onTap : null,
          borderRadius: AppBorderRadius.circular(24),
          child: Ink(
            decoration: AppBoxDecoration(
              borderRadius: AppBorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.appColors.surfaceRaised,
                  context.appColors.surface,
                ],
              ),
              border: Border.all(color: borderColor),
              boxShadow: _homeDarkV2CardShadow(
                context,
                alpha: 0.28,
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ),
            child: ClipRRect(
              borderRadius: AppBorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        StoryCoverImage(url: post.coverUrl),
                        if (coverScrimGradient != null)
                          DecoratedBox(
                            decoration: AppBoxDecoration(
                              gradient: coverScrimGradient,
                            ),
                          ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: _TopPostTag(label: tagLabel),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: AppEdgeInsets.fromLTRB(
                        isCompact ? 14 : 16,
                        isCompact ? 13 : 14,
                        isCompact ? 14 : 16,
                        isCompact ? 12 : 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle.copyWith(
                              color: isExpired
                                  ? context.appColors.textMuted
                                  : titleStyle.color,
                            ),
                            strutStyle: StrutStyle(
                              fontSize: titleFontSize,
                              height: titleLineHeight,
                              forceStrutHeight: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            excerpt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: excerptStyle,
                            strutStyle: StrutStyle(
                              fontSize: excerptFontSize,
                              height: excerptLineHeight,
                              forceStrutHeight: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Spacer(),
                          Row(
                            children: [
                              StoryAvatar(
                                label: post.author.initials,
                                imageUrl: post.author.avatarUrl,
                                size: avatarSize,
                                borderColor: AppPalette.primary.withValues(
                                  alpha: isExpired ? 0.16 : 0.30,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  post.author.preferredName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle(
                                    color: context.appColors.textMuted,
                                    fontSize: isCompact ? 11.5 : 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.remove_red_eye_outlined,
                                color: AppPalette.primary,
                                size: isCompact ? 15 : 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatStoryCountCompact(post.stats.views),
                                style: AppTextStyle(
                                  color: AppPalette.primary,
                                  fontSize: isCompact ? 11.5 : 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopPostTag extends StatelessWidget {
  const _TopPostTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const AppEdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: AppBoxDecoration(
          color: AppPalette.black.withValues(alpha: 0.72),
          borderRadius: AppBorderRadius.circular(999),
          border: Border.all(color: AppPalette.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              color: AppPalette.white,
              size: 13,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  color: AppPalette.white,
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopPostLoadingCard extends StatelessWidget {
  const _TopPostLoadingCard({required this.imageHeight});

  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppBoxDecoration(
        color: AppPalette.white.withValues(alpha: 0.05),
        borderRadius: AppBorderRadius.circular(24),
        border: Border.all(color: context.appColors.borderSoft),
      ),
      child: Column(
        children: [
          Container(
            height: imageHeight,
            decoration: AppBoxDecoration(
              color: AppPalette.white.withValues(alpha: 0.08),
              borderRadius: const AppBorderRadius.vertical(
                top: AppRadiusValue.circular(24),
              ),
            ),
          ),
          const Expanded(
            child: Padding(
              padding: AppEdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLine(width: double.infinity),
                  SizedBox(height: 10),
                  _SkeletonLine(width: 180),
                  SizedBox(height: 14),
                  _SkeletonLine(width: double.infinity),
                  SizedBox(height: 10),
                  _SkeletonLine(width: 150),
                  Spacer(),
                  Row(
                    children: [
                      _SkeletonLine(width: 92),
                      Spacer(),
                      _SkeletonLine(width: 42),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeEmptyStateCard extends StatelessWidget {
  const _HomeEmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final borderRadius = AppBorderRadius.circular(24);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.white.withValues(alpha: 0.05),
        borderRadius: borderRadius,
        border: Border.all(color: context.appColors.borderSoft),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: AppBoxDecoration(
                color: AppPalette.primary.withValues(alpha: 0.16),
                borderRadius: AppBorderRadius.circular(18),
              ),
              child: Icon(icon, color: AppPalette.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle(
                      color: context.appColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyle(
                      color: context.appColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSmartPostsSection extends StatelessWidget {
  const _HomeSmartPostsSection({
    required this.items,
    required this.postApi,
    required this.canInteract,
    required this.isLoading,
    required this.hasError,
    required this.isLoadingMore,
    required this.hasLoadMoreError,
    required this.onPostTap,
    required this.onQuickPostEngagement,
    required this.onRetry,
    required this.onLoadMoreRetry,
  });

  final List<_HomePostFeedItem> items;
  final PostApi postApi;
  final bool canInteract;
  final bool isLoading;
  final bool hasError;
  final bool isLoadingMore;
  final bool hasLoadMoreError;
  final ValueChanged<PostVm> onPostTap;
  final QuickPostEngagementCallback onQuickPostEngagement;
  final VoidCallback onRetry;
  final VoidCallback onLoadMoreRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (items.isEmpty && isLoading) {
      return Column(
        children: List.generate(
          3,
          (index) => const Padding(
            padding: AppEdgeInsets.only(bottom: 14),
            child: _HomeSmartPostLoadingCard(),
          ),
        ),
      );
    }

    if (items.isEmpty && hasError) {
      return _TopDestinationMessage(
        icon: Icons.cloud_off_rounded,
        message: l10n.storyLoadFailed,
        actionLabel: l10n.retryButton,
        onActionTap: onRetry,
      );
    }

    if (items.isEmpty) {
      return _HomeEmptyStateCard(
        icon: Icons.dynamic_feed_rounded,
        title: l10n.storyEmptyTitle,
        subtitle: l10n.homeSmartPostsEmpty,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          FeedPostContentCard(
            post: items[index].post,
            postApi: postApi,
            canInteract: canInteract,
            style: FeedPostCardStyle.v2(context),
            onOpen: onPostTap,
            onQuickPostEngagement: onQuickPostEngagement,
          ),
          if (index != items.length - 1) const SizedBox(height: 16),
        ],
        if (isLoadingMore || hasLoadMoreError) ...[
          const SizedBox(height: 16),
          if (isLoadingMore)
            const _HomeFeedPaginationLoading()
          else
            _HomeFeedPaginationRetry(onRetry: onLoadMoreRetry),
        ],
      ],
    );
  }
}

class _HomeSmartPostLoadingCard extends StatelessWidget {
  const _HomeSmartPostLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const AppEdgeInsets.all(18),
      decoration: AppBoxDecoration(
        color: context.appColors.surface,
        borderRadius: AppBorderRadius.circular(24),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.18)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonCircle(size: 42),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(width: 128),
                    SizedBox(height: 8),
                    _SkeletonLine(width: 84),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          _SkeletonLine(width: double.infinity),
          SizedBox(height: 10),
          _SkeletonLine(width: 220),
          SizedBox(height: 16),
          _SkeletonBlock(height: 160),
        ],
      ),
    );
  }
}

class _HomeFeedPaginationLoading extends StatelessWidget {
  const _HomeFeedPaginationLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: AppEdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppPalette.primary,
          ),
        ),
      ),
    );
  }
}

class _HomeFeedPaginationRetry extends StatelessWidget {
  const _HomeFeedPaginationRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: Text(l10n.retryButton),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.primary,
        side: BorderSide(color: AppPalette.primary.withValues(alpha: 0.34)),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _RecommendedActivitiesSection extends StatelessWidget {
  const _RecommendedActivitiesSection({
    required this.provider,
    required this.recommendedItems,
    required this.l10n,
    required this.currentUserId,
    required this.onRetry,
    required this.onActivityTap,
  });

  final ActivityProvider provider;
  final List<ActivityListItemVm> recommendedItems;
  final AppLocalizations l10n;
  final String currentUserId;
  final VoidCallback onRetry;
  final void Function(ActivityListItemVm activity, int rank) onActivityTap;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isLoadingPublic =
        provider.state == ActivitiesState.loading ||
        provider.state == ActivitiesState.initial;
    final hasLoadError = provider.state == ActivitiesState.error;

    if (recommendedItems.isEmpty && isLoadingPublic) {
      return Column(
        children: List.generate(
          3,
          (index) => const Padding(
            padding: AppEdgeInsets.only(bottom: 14),
            child: _RecommendedLoadingCard(),
          ),
        ),
      );
    }

    if (recommendedItems.isEmpty && hasLoadError) {
      return Container(
        padding: const AppEdgeInsets.all(20),
        decoration: AppBoxDecoration(
          color: AppPalette.white.withValues(alpha: 0.05),
          borderRadius: AppBorderRadius.circular(24),
          border: Border.all(color: context.appColors.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.errorMessage ?? l10n.activitiesLoadFailed,
              style: AppTextStyle(
                color: context.appColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.primary,
                side: BorderSide(
                  color: AppPalette.primary.withValues(alpha: 0.30),
                ),
              ),
              child: Text(l10n.retryButton),
            ),
          ],
        ),
      );
    }

    if (recommendedItems.isEmpty) {
      return _HomeEmptyStateCard(
        icon: Icons.explore_rounded,
        title: l10n.noActivitiesYet,
        subtitle: l10n.activitiesWillAppearHere,
      );
    }

    final items = recommendedItems.take(3).toList(growable: false);
    final joinedIds = currentUserId.isEmpty
        ? const <String>{}
        : provider.joinedItems.map((item) => item.id).toSet();
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _RecommendedActivityCard(
            item: items[index],
            categories: provider.categoryItems,
            languageCode: languageCode,
            isJoined: joinedIds.contains(items[index].id),
            onTap: () => onActivityTap(items[index], index),
          ),
          if (index != items.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _RecommendedActivityCard extends StatelessWidget {
  const _RecommendedActivityCard({
    required this.item,
    required this.categories,
    required this.languageCode,
    required this.isJoined,
    required this.onTap,
  });

  final ActivityListItemVm item;
  final List<ActivityCategoryVm> categories;
  final String languageCode;
  final bool isJoined;
  final VoidCallback onTap;

  String _durationLabel(AppLocalizations l10n) {
    final totalHours = item.endAt.difference(item.startAt).inMinutes / 60;
    final roundedHours = totalHours <= 1 ? 1 : totalHours.round();
    return l10n.homeDurationHours(roundedHours);
  }

  String _categoryLabel() {
    final categoryLabel = localizedActivityCategoryLabel(
      categories: categories,
      slug: item.categorySlug,
      languageCode: languageCode,
    ).trim();
    final subcategoryLabel = localizedActivitySubcategoryLabel(
      categories: categories,
      categorySlug: item.categorySlug,
      subcategorySlug: item.subcategorySlug,
      languageCode: languageCode,
    ).trim();

    if (subcategoryLabel.isEmpty || subcategoryLabel == categoryLabel) {
      return categoryLabel;
    }
    if (categoryLabel.isEmpty) {
      return subcategoryLabel;
    }
    return '$categoryLabel / $subcategoryLabel';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localizedCopy = item.localizedCopy(languageCode);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final buttonLabel = isJoined
        ? l10n.activityDetailsJoinedBadge
        : l10n.activityJoinSession;

    return LayoutBuilder(
      builder: (context, constraints) {
        final thumbWidth = (constraints.maxWidth * 0.24).clamp(76.0, 96.0);
        final thumbHeight = thumbWidth * 0.80;
        final buttonWidth = (constraints.maxWidth * 0.28).clamp(92.0, 126.0);

        return Material(
          color: AppPalette.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppBorderRadius.circular(18),
            child: Padding(
              padding: const AppEdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ActivityThumb(
                    item: item,
                    width: thumbWidth,
                    height: thumbHeight,
                    imageUrl: resolveActivityCoverUrl(item),
                  ),
                  SizedBox(width: isCompact ? 12 : 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizedCopy.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            color: context.appColors.textPrimary,
                            fontSize: isCompact ? 15 : 16,
                            height: 1.16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${_categoryLabel()} • ${_durationLabel(l10n)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            color: context.appColors.textMuted,
                            fontSize: isCompact ? 11.5 : 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              item.isFree ? l10n.freeLabel : item.priceLabel,
                              style: AppTextStyle(
                                color: AppPalette.primary,
                                fontSize: isCompact ? 16 : 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (!item.isFree)
                              Text(
                                l10n.createPricePerPersonHint,
                                style: AppTextStyle(
                                  color: context.appColors.textMuted,
                                  fontSize: isCompact ? 11 : 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isCompact ? 8 : 12),
                  SizedBox(
                    width: buttonWidth,
                    child: _ActivityJoinButton(
                      label: buttonLabel,
                      onTap: onTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActivityJoinButton extends StatelessWidget {
  const _ActivityJoinButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Material(
      color: AppPalette.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: isCompact ? 34 : 40),
          child: Ink(
            decoration: AppBoxDecoration(
              color: AppPalette.primary,
              borderRadius: AppBorderRadius.circular(999),
            ),
            child: Center(
              child: Padding(
                padding: AppEdgeInsets.symmetric(
                  horizontal: isCompact ? 10 : 14,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppTextStyle(
                      color: context.appColors.onPrimary,
                      fontSize: isCompact ? 12 : 13,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityThumb extends StatelessWidget {
  const _ActivityThumb({
    required this.item,
    required this.width,
    required this.height,
    this.imageUrl,
  });

  final ActivityListItemVm item;
  final double width;
  final double height;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = imageUrl?.trim() ?? '';
    final art = _homeCardArtForItem(context, item);

    return ClipRRect(
      borderRadius: AppBorderRadius.circular(height / 2),
      child: SizedBox(
        width: width,
        height: height,
        child: normalizedImageUrl.isNotEmpty
            ? _NetworkCardImage(imageUrl: normalizedImageUrl)
            : _HomeDecorativeActivityThumb(spec: art),
      ),
    );
  }
}

class _HomeDecorativeActivityThumb extends StatelessWidget {
  const _HomeDecorativeActivityThumb({required this.spec});

  final _HomeCardArtSpec spec;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: spec.colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: -22,
            top: -18,
            child: Container(
              width: 78,
              height: 78,
              decoration: AppBoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: -28,
            bottom: -24,
            child: Container(
              width: 90,
              height: 90,
              decoration: AppBoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.black.withValues(alpha: 0.16),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const AppEdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Icon(
                spec.icon,
                size: 34,
                color: AppPalette.white.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkCardImage extends StatelessWidget {
  const _NetworkCardImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: AppBoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.appColors.surfaceHigh,
                    context.appColors.surface,
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HomeCardArtSpec {
  const _HomeCardArtSpec({required this.icon, required this.colors});

  final IconData icon;
  final List<Color> colors;
}

_HomeCardArtSpec _homeCategoryVisual(BuildContext context, String slug) {
  if (slug.contains('wellness') || slug.contains('health')) {
    return const _HomeCardArtSpec(
      icon: Icons.spa_rounded,
      colors: [AppPalette.secondaryPressed, AppPalette.secondary],
    );
  }
  if (slug.contains('nature') ||
      slug.contains('outdoor') ||
      slug.contains('hiking')) {
    return _HomeCardArtSpec(
      icon: Icons.forest_rounded,
      colors: [
        context.appColors.secondaryContainer,
        AppPalette.secondaryPressed,
      ],
    );
  }
  if (slug.contains('food')) {
    return _HomeCardArtSpec(
      icon: Icons.restaurant_rounded,
      colors: [context.appColors.surfaceWarm, AppPalette.primary],
    );
  }
  if (slug.contains('culture') ||
      slug.contains('art') ||
      slug.contains('history')) {
    return _HomeCardArtSpec(
      icon: Icons.palette_outlined,
      colors: [context.appColors.surfaceHigh, AppPalette.secondaryPressed],
    );
  }
  if (slug.contains('sport') || slug.contains('adventure')) {
    return const _HomeCardArtSpec(
      icon: Icons.kayaking_rounded,
      colors: [AppPalette.primaryPressed, AppPalette.primary],
    );
  }
  if (slug.contains('workshop') ||
      slug.contains('learning') ||
      slug.contains('education')) {
    return _HomeCardArtSpec(
      icon: Icons.auto_stories_rounded,
      colors: [context.appColors.surfaceHigh, AppPalette.secondary],
    );
  }
  if (slug.contains('night') || slug.contains('social')) {
    return _HomeCardArtSpec(
      icon: Icons.celebration_rounded,
      colors: [context.appColors.surfaceHigh, AppPalette.primaryPressed],
    );
  }

  return _HomeCardArtSpec(
    icon: Icons.travel_explore_rounded,
    colors: [context.appColors.surfaceWarm, AppPalette.primaryPressed],
  );
}

_HomeCardArtSpec _homeCardArtForItem(
  BuildContext context,
  ActivityListItemVm item,
) {
  final fromCategory = _homeCategoryVisual(
    context,
    item.categorySlug.trim().toLowerCase(),
  );
  if (item.format.toUpperCase() == 'ONLINE') {
    return const _HomeCardArtSpec(
      icon: Icons.videocam_rounded,
      colors: [AppPalette.secondaryPressed, AppPalette.secondary],
    );
  }
  if (item.format.toUpperCase() == 'HYBRID') {
    return _HomeCardArtSpec(
      icon: Icons.devices_rounded,
      colors: [context.appColors.surfaceHigh, AppPalette.secondaryPressed],
    );
  }
  return fromCategory;
}

class _RecommendedLoadingCard extends StatelessWidget {
  const _RecommendedLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const AppEdgeInsets.all(14),
      decoration: AppBoxDecoration(
        color: AppPalette.white.withValues(alpha: 0.05),
        borderRadius: AppBorderRadius.circular(26),
        border: Border.all(color: context.appColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: AppBoxDecoration(
              color: AppPalette.white.withValues(alpha: 0.08),
              borderRadius: AppBorderRadius.circular(22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                _SkeletonLine(width: double.infinity),
                const SizedBox(height: 10),
                _SkeletonLine(width: 180),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Expanded(child: _SkeletonLine(width: 80)),
                    SizedBox(width: 16),
                    _SkeletonChip(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: 12,
        decoration: AppBoxDecoration(
          color: AppPalette.white.withValues(alpha: 0.08),
          borderRadius: AppBorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: AppBoxDecoration(
        color: AppPalette.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: AppBoxDecoration(
        color: AppPalette.white.withValues(alpha: 0.08),
        borderRadius: AppBorderRadius.circular(18),
      ),
    );
  }
}

class _SkeletonChip extends StatelessWidget {
  const _SkeletonChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 34,
      decoration: AppBoxDecoration(
        color: AppPalette.white.withValues(alpha: 0.08),
        borderRadius: AppBorderRadius.circular(999),
      ),
    );
  }
}

class _PromoCardData {
  const _PromoCardData({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String imageUrl;
}

List<Color> _homeBackgroundGradientColors(
  AppColors colors,
  Brightness brightness,
) {
  if (brightness == Brightness.dark) {
    return [colors.surface, colors.background, colors.background];
  }
  return colors.screenGradientColors;
}

List<double> _homeBackgroundGradientStops(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return const [0, 0.18, 1];
  }
  return const [0, 0.22, 1];
}

LinearGradient? _homePromoImageScrimGradient(BuildContext context) {
  final colors = AppDesignSystem.colorsFor(context);
  if (Theme.of(context).brightness != Brightness.dark) return null;

  return LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      colors.black.withValues(alpha: 0.82),
      colors.black.withValues(alpha: 0.38),
      colors.black.withValues(alpha: 0.05),
    ],
    stops: const [0, 0.48, 1],
  );
}

LinearGradient? _homeBottomImageScrimGradient(
  BuildContext context, {
  double darkStartAlpha = 0,
  required double darkEndAlpha,
  required List<double> stops,
}) {
  if (Theme.of(context).brightness != Brightness.dark) return null;

  final colors = AppDesignSystem.colorsFor(context);
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      darkStartAlpha <= 0
          ? colors.transparent
          : colors.black.withValues(alpha: darkStartAlpha),
      colors.black.withValues(alpha: darkEndAlpha),
    ],
    stops: stops,
  );
}

List<BoxShadow>? _homeDarkV2CardShadow(
  BuildContext context, {
  required double alpha,
  required double blurRadius,
  required Offset offset,
}) {
  if (Theme.of(context).brightness != Brightness.dark) return null;

  return [
    BoxShadow(
      color: AppPalette.black.withValues(alpha: alpha),
      blurRadius: blurRadius,
      offset: offset,
    ),
  ];
}

double _homeTextScaleFactor(BuildContext context) {
  final bodySize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;
  final scale = MediaQuery.textScalerOf(context).scale(bodySize) / bodySize;
  return scale.clamp(1.0, 1.6).toDouble();
}

double _homePromoCardHeight({
  required double visualHeight,
  required bool isCompact,
  required double textScale,
}) {
  final contentHeight = _homePromoCardContentHeight(
    isCompact: isCompact,
    textScale: textScale,
  );
  return visualHeight < contentHeight ? contentHeight : visualHeight;
}

double _homePromoCardContentHeight({
  required bool isCompact,
  required double textScale,
}) {
  final verticalPadding = isCompact ? 22.0 : 28.0;
  final eyebrowFontSize = isCompact ? 9.0 : 10.0;
  final titleFontSize = isCompact ? 20.0 : 22.0;
  final descriptionFontSize = isCompact ? 12.0 : 13.0;
  final safetyPadding = isCompact ? 4.0 : 6.0;

  return verticalPadding * 2 +
      eyebrowFontSize * 1.1 * textScale +
      8 +
      titleFontSize * 1.08 * textScale * 2 +
      7 +
      descriptionFontSize * 1.32 * textScale * 2 +
      safetyPadding;
}

double _homeTopDestinationTitleBlockHeight({
  required bool isCompact,
  required double textScale,
}) {
  final titleFontSize = isCompact ? 16.0 : 17.0;
  const titleLineHeight = 1.16;
  return titleFontSize * titleLineHeight * textScale * 2 + 4;
}

double _homeTopDestinationCardHeight({
  required double imageHeight,
  required bool isCompact,
  required double textScale,
}) {
  final titleBlockHeight = _homeTopDestinationTitleBlockHeight(
    isCompact: isCompact,
    textScale: textScale,
  );
  final footerFontSize = isCompact ? 13.0 : 14.0;
  final footerHeight = footerFontSize * textScale * 1.35;
  return imageHeight + 13 + titleBlockHeight + 8 + footerHeight + 4;
}

String? _resolveHomePlaceImageUrl(PlaceMediaVm? media) {
  if (media == null) return null;

  final fileUrl = resolvePlaceMediaUrl(media)?.trim() ?? '';
  if (fileUrl.isNotEmpty) return fileUrl;

  final externalUrl = media.externalUrl.trim();
  if (externalUrl.isNotEmpty) return externalUrl;

  final sourceUrl = media.sourceUrl.trim();
  if (sourceUrl.isNotEmpty) return sourceUrl;

  return null;
}

String _homePlaceCategoryLabel(AppLocalizations l10n, PlaceVm place) {
  switch (place.category.toUpperCase()) {
    case 'PARK':
      return l10n.placeFilterCategoryParks;
    case 'MUSEUM':
      return l10n.placeFilterCategoryMuseums;
    case 'NATURE':
      return l10n.placeFilterCategoryNature;
    case 'ARCHITECTURE':
      return l10n.placeFilterCategoryArchitecture;
    case 'BEACH':
      return l10n.placeFilterCategoryBeach;
    case 'TEMPLE':
      return l10n.placeFilterCategoryTemple;
    case 'ENTERTAINMENT':
      return l10n.placeFilterCategoryEntertainment;
    case 'FOOD':
      return l10n.placeFilterCategoryFood;
    case 'MARKET':
      return l10n.placeFilterCategoryMarket;
    case 'SHOPPING':
      return l10n.placeFilterCategoryShopping;
    case 'OTHER':
      return l10n.placeFilterCategoryOther;
    case 'PARKS':
      return l10n.placeFilterCategoryParks;
    case 'MUSEUMS':
      return l10n.placeFilterCategoryMuseums;
    case 'HISTORY':
      return l10n.placeFilterCategoryHistory;
    case 'ADVENTURE':
      return l10n.placeFilterCategoryAdventure;
    default:
      return l10n.placeFilterCategoryOther;
  }
}

String _homePostTagLabel(AppLocalizations l10n, PostVm post) {
  final placeName = (post.placeName ?? '').trim();
  if (placeName.isNotEmpty) return placeName;

  return formatStoryCategory(l10n, post.category);
}

class _HomePostFeedItem {
  const _HomePostFeedItem({required this.post, required this.eventTarget});

  final PostVm post;
  final _HomePostFeedEventTarget eventTarget;
}

class _HomeFeedPageResult {
  const _HomeFeedPageResult.success(this.page);
  const _HomeFeedPageResult.failure() : page = null;

  final FeedPageVm? page;
}

class _HomePostFeedEventTarget {
  const _HomePostFeedEventTarget({
    required this.blockId,
    required this.blockType,
    required this.rank,
    required this.tab,
  });

  final String blockId;
  final String blockType;
  final int rank;
  final String tab;
}

List<StoryVm> _homeStoryTrayStoriesFromFeedBlocks(List<FeedBlockVm> blocks) {
  for (final block in blocks) {
    if (block.type == FeedBlockType.storiesTray) {
      return block.stories;
    }
  }
  return const [];
}

List<_HomePostFeedItem> _homePostFeedItemsFromFeedBlocks(
  List<FeedBlockVm> blocks, {
  required String tab,
}) {
  final items = <_HomePostFeedItem>[];
  final seenKeys = <String>{};

  void addPost({
    required PostVm? post,
    required FeedBlockVm block,
    required String blockType,
    required int rank,
  }) {
    if (post == null || !_isHomePostViewable(post)) return;

    final key = _homePostKey(post);
    if (key.isEmpty || !seenKeys.add(key)) {
      return;
    }

    final blockId = block.id.trim().isNotEmpty ? block.id.trim() : blockType;
    items.add(
      _HomePostFeedItem(
        post: post,
        eventTarget: _HomePostFeedEventTarget(
          blockId: blockId,
          blockType: blockType,
          rank: rank,
          tab: tab,
        ),
      ),
    );
  }

  for (var blockIndex = 0; blockIndex < blocks.length; blockIndex++) {
    final block = blocks[blockIndex];
    final blockType = _homeFeedBlockTypeWire(block.type);
    if (blockType == null) {
      continue;
    }

    switch (block.type) {
      case FeedBlockType.storiesTray:
        break;
      case FeedBlockType.systemPosts:
        for (var index = 0; index < block.posts.length; index++) {
          addPost(
            post: block.posts[index],
            block: block,
            blockType: blockType,
            rank: blockIndex + index,
          );
        }
        break;
      case FeedBlockType.postCard:
        addPost(
          post: block.post,
          block: block,
          blockType: blockType,
          rank: blockIndex,
        );
        break;
      case FeedBlockType.tourCard:
      case FeedBlockType.guideCard:
      case FeedBlockType.profileCard:
      case FeedBlockType.officialNewsCard:
      case FeedBlockType.suggestedCommunities:
      case FeedBlockType.mySubscriptions:
      case FeedBlockType.unknown:
        break;
    }
  }

  return List<_HomePostFeedItem>.unmodifiable(items);
}

List<_HomePostFeedItem> _excludeHomePostKeys(
  Iterable<_HomePostFeedItem> items,
  Iterable<String> excludedKeys,
) {
  final excluded = excludedKeys.where((key) => key.isNotEmpty).toSet();
  return List<_HomePostFeedItem>.unmodifiable(
    items.where((item) => !excluded.contains(_homePostKey(item.post))),
  );
}

Map<String, _HomePostFeedEventTarget> _homePostEventTargets(
  Iterable<_HomePostFeedItem> trending,
  Iterable<_HomePostFeedItem> forYou,
) {
  return Map<String, _HomePostFeedEventTarget>.unmodifiable(
    {
      for (final item in [...trending, ...forYou])
        _homePostKey(item.post): item.eventTarget,
    }..remove(''),
  );
}

List<_HomePostFeedItem> _mergeHomePostFeedItems(
  List<_HomePostFeedItem> existing,
  List<_HomePostFeedItem> incoming,
) {
  if (existing.isEmpty) {
    return List<_HomePostFeedItem>.unmodifiable(incoming);
  }
  if (incoming.isEmpty) {
    return List<_HomePostFeedItem>.unmodifiable(existing);
  }

  final seenKeys = <String>{
    for (final item in existing) _homePostKey(item.post),
  }..remove('');
  final merged = <_HomePostFeedItem>[...existing];

  for (final item in incoming) {
    final key = _homePostKey(item.post);
    if (key.isEmpty || !seenKeys.add(key)) {
      continue;
    }
    merged.add(item);
  }

  return List<_HomePostFeedItem>.unmodifiable(merged);
}

String _homePostKey(PostVm post) {
  final id = post.id.trim();
  if (id.isNotEmpty) return id;

  return post.slug.trim();
}

String? _trimmedHomeStringOrNull(String? value) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool _isHomePostViewable(PostVm post) {
  return post.isPublished && !post.isExpired && post.slug.trim().isNotEmpty;
}

List<TravelServiceEntry> _homeServicesPreview(AppLocalizations l10n) {
  final primaryServices = buildTravelServiceCatalog(l10n)
      .where(
        (service) =>
            service.route != '/travel-checklist' &&
            service.route != '/currency-converter' &&
            service.route != '/help',
      )
      .take(5)
      .toList(growable: false);

  return List.unmodifiable([
    ...primaryServices,
    TravelServiceEntry(
      title: l10n.homeServiceAllServices,
      icon: Icons.apps_rounded,
      route: '/services',
    ),
  ]);
}

String? _homeFeedBlockTypeWire(FeedBlockType type) {
  return switch (type) {
    FeedBlockType.storiesTray => 'stories_tray',
    FeedBlockType.suggestedCommunities => 'suggested_communities',
    FeedBlockType.mySubscriptions => 'my_subscriptions',
    FeedBlockType.systemPosts => 'system_posts',
    FeedBlockType.postCard => 'post_card',
    FeedBlockType.tourCard => 'tour_card',
    FeedBlockType.guideCard => 'guide_card',
    FeedBlockType.profileCard => 'profile_card',
    FeedBlockType.officialNewsCard => 'official_news_card',
    FeedBlockType.unknown => null,
  };
}

String _homeFeedUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hexByte(int value) => value.toRadixString(16).padLeft(2, '0');
  final hex = bytes.map(hexByte).join();
  return [
    hex.substring(0, 8),
    hex.substring(8, 12),
    hex.substring(12, 16),
    hex.substring(16, 20),
    hex.substring(20),
  ].join('-');
}

double _homePostCardHeight({
  required BuildContext context,
  required AppLocalizations l10n,
  required List<PostVm> posts,
  required double cardWidth,
  required double imageHeight,
  required bool isCompact,
  required double textScale,
}) {
  final titleFontSize = isCompact ? 16.0 : 17.0;
  final titleLineHeight = 1.14;
  final excerptFontSize = isCompact ? 12.0 : 12.5;
  final excerptLineHeight = 1.34;
  final horizontalPadding = isCompact ? 14.0 : 16.0;
  final textWidth = cardWidth - horizontalPadding * 2;
  final avatarSize = (isCompact ? 24.0 : 26.0) * textScale.clamp(1.0, 1.18);
  final titleStyle = AppTextStyle(
    fontSize: titleFontSize,
    height: titleLineHeight,
    fontWeight: FontWeight.w900,
  );
  final excerptStyle = AppTextStyle(
    fontSize: excerptFontSize,
    height: excerptLineHeight,
    fontWeight: FontWeight.w500,
  );
  final textDirection = Directionality.of(context);
  var contentBodyHeight = 0.0;

  for (final post in posts) {
    final tagLabel = _homePostTagLabel(l10n, post);
    final excerpt = _truncateHomePostExcerpt(
      post.excerpt.trim().isNotEmpty ? post.excerpt.trim() : tagLabel,
    );
    final titleHeight = _measureHomePostTextHeight(
      text: post.title,
      style: titleStyle,
      strutStyle: StrutStyle(
        fontSize: titleFontSize,
        height: titleLineHeight,
        forceStrutHeight: true,
      ),
      maxWidth: textWidth,
      maxLines: 3,
      textDirection: textDirection,
      textScale: textScale,
    );
    final excerptHeight = _measureHomePostTextHeight(
      text: excerpt,
      style: excerptStyle,
      strutStyle: StrutStyle(
        fontSize: excerptFontSize,
        height: excerptLineHeight,
        forceStrutHeight: true,
      ),
      maxWidth: textWidth,
      maxLines: 2,
      textDirection: textDirection,
      textScale: textScale,
    );
    final bodyHeight = titleHeight + 8 + excerptHeight + 10 + avatarSize;
    if (bodyHeight > contentBodyHeight) {
      contentBodyHeight = bodyHeight;
    }
  }

  final verticalPadding = (isCompact ? 13.0 : 14.0) + (isCompact ? 12.0 : 14.0);
  final safetyPadding = isCompact ? 24.0 : 26.0;
  return imageHeight + verticalPadding + contentBodyHeight + safetyPadding;
}

double _measureHomePostTextHeight({
  required String text,
  required TextStyle style,
  required StrutStyle strutStyle,
  required double maxWidth,
  required int maxLines,
  required TextDirection textDirection,
  required double textScale,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: maxLines,
    textDirection: textDirection,
    strutStyle: strutStyle,
    textScaler: TextScaler.linear(textScale),
  )..layout(maxWidth: maxWidth);

  return painter.height;
}

String _truncateHomePostExcerpt(String value) {
  const maxLength = 100;
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.length <= maxLength) return normalized;

  return '${normalized.substring(0, maxLength).trimRight()}...';
}

String _topPlacesRequestKey({
  required String locale,
  required String? countryCode,
  required String? cityId,
  required double? latitude,
  required double? longitude,
}) {
  final normalizedLocale = locale.trim().toLowerCase();
  final normalizedCountryCode = (countryCode ?? '').trim().toUpperCase();
  final normalizedCityId = (cityId ?? '').trim().toLowerCase();
  final locationKey = [
    normalizedCountryCode,
    normalizedCityId,
  ].where((value) => value.isNotEmpty).join(':');
  if (latitude == null || longitude == null) {
    return '$normalizedLocale:rating:$locationKey';
  }
  return '$normalizedLocale:distance:$locationKey:${latitude.toStringAsFixed(6)}:${longitude.toStringAsFixed(6)}';
}

double? _validHomeLatitude(double? value) {
  if (value == null || !value.isFinite || value < -90 || value > 90) {
    return null;
  }
  return value;
}

double? _validHomeLongitude(double? value) {
  if (value == null || !value.isFinite || value < -180 || value > 180) {
    return null;
  }
  return value;
}

List<ActivityListItemVm> _filterHomeRecommendedItems({
  required List<ActivityListItemVm> publicItems,
  required HomeLocationPreference location,
}) {
  final itemsById = <String, ActivityListItemVm>{};
  final shouldFilterByLocation = _shouldFilterHomeRecommendationsByLocation(
    location,
  );

  for (final item in publicItems) {
    if (_isHomeRecommendedActivity(item) &&
        (!shouldFilterByLocation || _matchesHomeLocation(item, location))) {
      itemsById[item.id] = item;
    }
  }

  final merged = itemsById.values.toList(growable: false)
    ..sort((a, b) => a.startAt.compareTo(b.startAt));
  return merged;
}

bool _isHomeRecommendedActivity(ActivityListItemVm item) {
  if (!_isHomeRegistrationOpenStatus(item.status)) {
    return false;
  }

  final now = DateTime.now().toUtc();
  final closesAt = (item.registrationDeadline ?? item.startAt).toUtc();
  return now.isBefore(closesAt);
}

bool _matchesHomeLocation(
  ActivityListItemVm item,
  HomeLocationPreference location,
) {
  final selectedCity = AppCityFilterValue.fromParts(
    cityId: location.cityId,
    cityName: location.cityName,
    countryCode: location.countryCode,
  );
  if (selectedCity != null) {
    return selectedCity.matches(
      cityId: item.cityId,
      cityName: item.cityName,
      countryCode: item.countryCode,
    );
  }

  final selectedCountryCode = _normalizeLocationText(location.countryCode);
  if (selectedCountryCode.isEmpty) {
    return true;
  }

  final itemCountryCode = _normalizeLocationText(item.countryCode);
  return itemCountryCode.isEmpty || itemCountryCode == selectedCountryCode;
}

bool _shouldFilterHomeRecommendationsByLocation(
  HomeLocationPreference location,
) {
  final hasLocation =
      (location.cityId ?? '').trim().isNotEmpty ||
      (location.cityName ?? '').trim().isNotEmpty ||
      (location.countryCode ?? '').trim().isNotEmpty;
  return hasLocation && location.source != HomeLocationSource.fallback;
}

String _normalizeLocationText(String? value) {
  return (value ?? '').trim().toLowerCase();
}

bool _isHomeRegistrationOpenStatus(String status) {
  switch (status.toUpperCase()) {
    case 'PUBLISHED':
    case 'ENROLLMENT_OPEN':
      return true;
    default:
      return false;
  }
}
