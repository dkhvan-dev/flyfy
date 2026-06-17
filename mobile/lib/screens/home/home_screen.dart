import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_colors.dart';
import '../../features/activities/activity_cover_url.dart';
import '../../features/activities/activity_taxonomy_resolver.dart';
import '../../features/activities/models/activity_category_vm.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/attractions/attraction_ui.dart';
import '../../features/attractions/data/attraction_api.dart';
import '../../features/attractions/models/attraction_vm.dart';
import '../../features/feed/data/feed_api.dart';
import '../../features/feed/models/feed_block_vm.dart';
import '../../features/feed/widgets/contextual_story_tray.dart';
import '../../features/feed/widgets/feed_post_card.dart';
import '../../features/profile/data/guide_api.dart';
import '../../features/services/service_catalog.dart';
import '../../features/services/widgets/service_grid.dart';
import '../../features/stories/models/story_vm.dart';
import '../../features/stories/models/post_vm.dart';
import '../../features/stories/story_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_location_provider.dart';
import '../../providers/session_provider.dart';
import '../../shared/widgets/app_city_filter_section.dart';
import '../../shared/widgets/app_localized_location_text.dart';
import '../common/app_side_drawer.dart';
import 'widgets/home_location_picker_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.feedApi,
    this.attractionApi,
    this.guideApi,
    this.initialDataLoadDelay = _initialHomeDataDelay,
    this.initialDataLoadStagger = _initialHomeDataStagger,
    this.waitForFirstFrameRasterized = true,
  });

  static const _initialHomeDataDelay = Duration(milliseconds: 350);
  static const _initialHomeDataStagger = Duration(milliseconds: 160);

  final FeedApi? feedApi;
  final AttractionApi? attractionApi;
  final GuideApi? guideApi;
  final Duration initialDataLoadDelay;
  final Duration initialDataLoadStagger;
  final bool waitForFirstFrameRasterized;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _homeTrendingPostLimit = 3;
  static const _homeFeedPageLimit = 20;
  static const _homeLocationStartupTimeout = Duration(seconds: 2);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final ScrollController _scrollController = ScrollController();
  late final GuideApi _guideApi = widget.guideApi ?? GuideApi();
  late final AttractionApi _attractionApi =
      widget.attractionApi ?? AttractionApi();
  late final FeedApi _feedApi = widget.feedApi ?? FeedApi();
  String? _requestedHostedActivitiesForUserId;
  String? _requestedJoinedActivitiesForUserId;
  String? _requestedTopAttractionsLocale;
  String? _guideBadgeUserId;
  bool _isGuideBadgeLoading = false;
  int _guideBadgeRequestVersion = 0;
  List<AttractionVm> _topAttractions = const [];
  List<StoryVm> _homeStoryTrayStories = const [];
  List<PostVm> _topPosts = const [];
  List<_HomePostFeedItem> _homePostFeedItems = const [];
  Map<String, _HomePostFeedEventTarget> _topPostFeedTargets = const {};
  String? _homePostFeedNextCursor;
  String? _requestedHomeFeedCountryCode;
  String? _requestedHomeFeedCityId;
  bool _topAttractionsLoading = true;
  bool _topAttractionsLoadFailed = false;
  bool _topPostsLoading = true;
  bool _topPostsLoadFailed = false;
  bool _homePostFeedLoadingMore = false;
  bool _homePostFeedLoadMoreFailed = false;
  bool _topPostsRequestStarted = false;
  bool _showGuideBadge = false;
  bool _isGuideStatusRevoked = false;
  bool _suppressGuideFallback = false;
  bool _initialHomeDataLoadScheduled = false;

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
        _topPostsLoading ||
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
    unawaited(_loadTopAttractions());

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

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _LogoutConfirmDialog(
          title: l10n.logoutDialogTitle,
          message: l10n.logoutDialogMessage,
          cancelLabel: l10n.cancel,
          confirmLabel: l10n.logoutConfirmButton,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await authProvider.logout();
    await sessionProvider.clearSession();

    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _openMyActivities() async {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.state != AuthState.authenticated) {
      context.push('/login?from=/me/activities');
      return;
    }

    context.push('/me/activities');
  }

  void _openProfile() {
    context.push('/profile');
  }

  void _openActivities() {
    context.push('/activities');
  }

  void _openFeed() {
    context.push('/feed');
  }

  void _openTopPost(PostVm post) {
    _trackTopPostClick(post);
    final slug = post.slug.trim();
    if (slug.isEmpty) {
      return;
    }
    context.push('/posts/${Uri.encodeComponent(slug)}', extra: post);
  }

  void _trackTopPostClick(PostVm post) {
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
        eventType: 'click',
        surface: 'home',
        tab: 'for_you',
        blockId: target.blockId,
        blockType: target.blockType,
        postId: postId,
        rank: target.rank,
        occurredAt: DateTime.now().toUtc(),
        metadata: {'entityType': 'post', 'entityId': postId},
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

  void _openAttractions() {
    context.push('/attractions');
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

  void _openAttractionDetails(AttractionVm attraction) {
    final attractionId = attraction.id.trim();
    final rank = _topAttractions.indexWhere(
      (item) => item.id.trim() == attractionId,
    );
    _trackHomeEntityConversionClick(
      blockId: 'home:top_destinations',
      blockType: 'attraction_card',
      entityType: 'attraction',
      entityId: attractionId,
      source: 'home_top_destinations',
      rank: rank,
      metadata: {
        'title': attraction.title,
        'category': attraction.category,
        'countryCode': attraction.countryCode,
        'cityId': attraction.cityId,
        'tags': attraction.tags,
      },
    );
    context.push('/attractions/${attraction.id}', extra: attraction);
  }

  void _openRecommendedActivityDetails(ActivityListItemVm activity, int rank) {
    final activityId = activity.id.trim();
    _trackHomeEntityConversionClick(
      blockId: 'home:recommended_activities',
      blockType: 'activity_card',
      entityType: 'activity',
      entityId: activityId,
      source: 'home_recommended_activities',
      rank: rank,
      metadata: {
        'title': activity.title,
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
      _loadTopAttractions(force: true),
      _loadHomeFeed(force: true),
    ]);
  }

  Future<void> _openLocationSheet() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
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

  Future<void> _loadTopAttractions({bool force = false}) async {
    if (!mounted) return;

    final locale = Localizations.localeOf(context).languageCode;
    if (!force &&
        _requestedTopAttractionsLocale == locale &&
        (_topAttractions.isNotEmpty || _topAttractionsLoading)) {
      return;
    }

    _requestedTopAttractionsLocale = locale;
    setState(() {
      _topAttractionsLoading = _topAttractions.isEmpty;
      _topAttractionsLoadFailed = false;
    });

    try {
      final result = await _attractionApi.getAttractions(
        sort: 'rating',
        locale: locale,
        limit: 10,
      );
      if (!mounted || _requestedTopAttractionsLocale != locale) return;
      setState(() {
        _topAttractions = result.items.take(10).toList(growable: false);
        _topAttractionsLoading = false;
      });
    } catch (_) {
      if (!mounted || _requestedTopAttractionsLocale != locale) return;
      setState(() {
        _topAttractionsLoading = false;
        _topAttractionsLoadFailed = true;
      });
    }
  }

  Future<void> _loadHomeFeed({bool force = false, bool append = false}) async {
    if (!mounted) return;

    final location = context.read<HomeLocationProvider>().effectiveLocation;
    final currentCountryCode = _trimmedHomeStringOrNull(location.countryCode);
    final currentCityId = _trimmedHomeStringOrNull(location.cityId);
    final requestCountryCode = append
        ? (_requestedHomeFeedCountryCode ?? currentCountryCode)
        : currentCountryCode;
    final requestCityId = append
        ? (_requestedHomeFeedCityId ?? currentCityId)
        : currentCityId;
    final locationChanged =
        !append &&
        (_requestedHomeFeedCountryCode != requestCountryCode ||
            _requestedHomeFeedCityId != requestCityId);
    final shouldForce = force || locationChanged;
    final cursor = append ? _homePostFeedNextCursor : null;
    if (append && (cursor == null || _homePostFeedLoadingMore)) {
      return;
    }
    if (!append &&
        !shouldForce &&
        _topPostsRequestStarted &&
        (_topPosts.isNotEmpty || _topPostsLoading)) {
      return;
    }

    _topPostsRequestStarted = true;
    setState(() {
      if (append) {
        _homePostFeedLoadingMore = true;
        _homePostFeedLoadMoreFailed = false;
      } else {
        _topPostsLoading = _topPosts.isEmpty || shouldForce;
        _topPostsLoadFailed = false;
        _homePostFeedLoadMoreFailed = false;
        _requestedHomeFeedCountryCode = requestCountryCode;
        _requestedHomeFeedCityId = requestCityId;
        if (shouldForce) {
          _homePostFeedNextCursor = null;
        }
      }
    });

    try {
      final page = await _feedApi.getFeed(
        surface: 'home',
        tab: 'for_you',
        cursor: cursor,
        countryCode: requestCountryCode,
        cityId: requestCityId,
        limit: _homeFeedPageLimit,
      );
      final storyTrayStories = _homeStoryTrayStoriesFromFeedBlocks(page.items);
      final feedItems = _homePostFeedItemsFromFeedBlocks(page.items);
      final mergedItems = append
          ? _mergeHomePostFeedItems(_homePostFeedItems, feedItems)
          : feedItems;
      final topItems = mergedItems
          .take(_homeTrendingPostLimit)
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        if (!append) {
          _homeStoryTrayStories = storyTrayStories;
        }
        _homePostFeedItems = mergedItems;
        _homePostFeedNextCursor = _trimmedHomeStringOrNull(page.nextCursor);
        _topPosts = topItems.map((item) => item.post).toList(growable: false);
        _topPostFeedTargets =
            Map<String, _HomePostFeedEventTarget>.unmodifiable({
              for (final item in mergedItems)
                _homePostKey(item.post): item.eventTarget,
            });
        _topPostsLoading = false;
        _homePostFeedLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (append) {
          _homePostFeedLoadingMore = false;
          _homePostFeedLoadMoreFailed = true;
        } else {
          _topPostsLoading = false;
          _topPostsLoadFailed = true;
        }
      });
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _closeDrawerIfNeeded() async {
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState == null || !scaffoldState.isDrawerOpen) return;

    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 180));
  }

  Future<void> _runDrawerAction(FutureOr<void> Function() action) async {
    await _closeDrawerIfNeeded();
    if (!mounted) return;
    await action();
  }

  void _ensureGuideBadgeState(String? currentUserId, {bool force = false}) {
    final normalizedUserId = (currentUserId ?? '').trim();
    if (normalizedUserId.isEmpty) {
      _guideBadgeUserId = null;
      _isGuideBadgeLoading = false;
      _guideBadgeRequestVersion++;
      _showGuideBadge = false;
      _isGuideStatusRevoked = false;
      _suppressGuideFallback = false;
      return;
    }

    final isNewUser = _guideBadgeUserId != normalizedUserId;
    if (!force && !isNewUser) {
      return;
    }
    if (_isGuideBadgeLoading && !isNewUser) return;

    _guideBadgeUserId = normalizedUserId;
    _isGuideBadgeLoading = true;
    final requestVersion = ++_guideBadgeRequestVersion;
    if (isNewUser) {
      _showGuideBadge = false;
      _isGuideStatusRevoked = false;
      _suppressGuideFallback = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final guide = await _guideApi.getMyGuideProfileOrNull();
        if (!mounted ||
            _guideBadgeUserId != normalizedUserId ||
            _guideBadgeRequestVersion != requestVersion) {
          return;
        }
        setState(() {
          _isGuideBadgeLoading = false;
          _showGuideBadge = guide?.isVerified == true;
          _isGuideStatusRevoked = guide?.isRevoked == true;
          _suppressGuideFallback = guide != null && !guide.isVerified;
        });
      } catch (_) {
        if (!mounted ||
            _guideBadgeUserId != normalizedUserId ||
            _guideBadgeRequestVersion != requestVersion) {
          return;
        }
        setState(() {
          _isGuideBadgeLoading = false;
          _showGuideBadge = false;
          _isGuideStatusRevoked = false;
          _suppressGuideFallback = false;
        });
      }
    });
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
    final location = homeLocation.fallbackLabel;
    final promos = _buildPromoCards(l10n);
    final servicesPreview = buildTravelServiceCatalog(
      l10n,
    ).take(6).toList(growable: false);
    final homePostStreamItems = _homePostFeedItems
        .skip(_homeTrendingPostLimit)
        .toList(growable: false);
    final feedCountryCode = _trimmedHomeStringOrNull(homeLocation.countryCode);
    final feedCityId = _trimmedHomeStringOrNull(homeLocation.cityId);
    final homeFeedLocationChanged =
        _topPostsRequestStarted &&
        !_topPostsLoading &&
        !_homePostFeedLoadingMore &&
        (_requestedHomeFeedCountryCode != feedCountryCode ||
            _requestedHomeFeedCityId != feedCityId);
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

    _ensureGuideBadgeState(currentUserId);
    if (_requestedTopAttractionsLocale != languageCode &&
        !_topAttractionsLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadTopAttractions(force: true);
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF160D07),
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: 28,
      drawerScrimColor: Colors.black.withValues(alpha: 0.42),
      onDrawerChanged: (isOpened) {
        if (!isOpened) return;
        _ensureGuideBadgeState(currentUserId, force: true);
      },
      drawer: AppSideDrawer(
        l10n: l10n,
        isLoggedIn: isLoggedIn,
        showGuideBadge: _showGuideBadge,
        isGuideStatusRevoked: _isGuideStatusRevoked,
        suppressGuideFallback: _suppressGuideFallback,
        profile: profile,
        location: location,
        activeItem: AppDrawerActiveItem.none,
        onProfileTap: () => _runDrawerAction(_openProfile),
        onHomeTap: () => _runDrawerAction(() => context.go('/')),
        onMyActivitiesTap: () => _runDrawerAction(_openMyActivities),
        onMyExcursionsTap: () =>
            _runDrawerAction(() => context.push('/me/excursions')),
        onMyStoriesTap: () => _runDrawerAction(() => context.push('/me/posts')),
        onMyStoryArchiveTap: () =>
            _runDrawerAction(() => context.push('/me/stories')),
        onActivitiesTap: () => _runDrawerAction(_openActivities),
        onLoginTap: () => _runDrawerAction(() => context.push('/login')),
        onLogoutTap: () => _runDrawerAction(_confirmLogout),
      ),
      bottomNavigationBar: CommonBottomNavigationBar(
        activeItem: AppBottomNavItem.home,
        onHomeTap: _handleHomeNavTap,
        onQrTap: () => context.push('/qr'),
        onMapTap: () => context.push('/map'),
        onServicesTap: _openServices,
        onChatsTap: () => context.push('/chats'),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF21180D)),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF21180D), Color(0xFF21180D)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -120,
              left: -48,
              right: -48,
              child: IgnorePointer(
                child: Container(
                  height: 310,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.55),
                      radius: 1.0,
                      colors: [
                        AppColors.accent.withValues(alpha: 0.08),
                        AppColors.accent.withValues(alpha: 0.02),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.36, 1],
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
                    currentLocationLabel: l10n.homeCurrentLocationLabel,
                    onLocationTap: _openLocationSheet,
                    onMenuTap: _openDrawer,
                    onNotificationsTap: () => context.push('/notifications'),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      key: _refreshIndicatorKey,
                      color: AppColors.accent,
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
                                padding: EdgeInsets.fromLTRB(
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
                                        onTap: _openActivities,
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
                                        SizedBox(height: isCompact ? 24 : 30),
                                      ] else
                                        SizedBox(height: isCompact ? 24 : 30),
                                      _SectionHeader(
                                        title: l10n.servicesSectionTitle,
                                        actionLabel: l10n.servicesAllButton,
                                        onActionTap: _openServices,
                                      ),
                                      const SizedBox(height: 14),
                                      ServiceGrid(
                                        services: servicesPreview,
                                        onServiceTap: _openService,
                                      ),
                                      SizedBox(height: isCompact ? 38 : 52),
                                      _PromoCarousel(promos: promos),
                                      SizedBox(height: isCompact ? 20 : 24),
                                      _SectionHeader(
                                        title: l10n.homeTopDestinations,
                                        actionLabel: l10n.homeSeeAll,
                                        onActionTap: _openAttractions,
                                      ),
                                      const SizedBox(height: 14),
                                      _TopDestinationsRow(
                                        attractions: _topAttractions,
                                        isLoading: _topAttractionsLoading,
                                        hasError: _topAttractionsLoadFailed,
                                        onAttractionTap: _openAttractionDetails,
                                        onRetry: () =>
                                            _loadTopAttractions(force: true),
                                      ),
                                      SizedBox(height: isCompact ? 30 : 34),
                                      _SectionHeader(
                                        title: l10n.homeTopStories,
                                        actionLabel: l10n.homeSeeAll,
                                        onActionTap: _openFeed,
                                      ),
                                      const SizedBox(height: 14),
                                      _TopPostsCarousel(
                                        posts: _topPosts,
                                        isLoading: _topPostsLoading,
                                        hasError: _topPostsLoadFailed,
                                        onPostTap: _openTopPost,
                                        onRetry: () =>
                                            _loadHomeFeed(force: true),
                                        onEmptyTap: _openFeed,
                                      ),
                                      SizedBox(height: isCompact ? 30 : 34),
                                      _SectionHeader(
                                        title: l10n.homeRecommendedActivities,
                                        actionLabel: l10n.homeSeeAll,
                                        onActionTap: _openActivities,
                                      ),
                                      const SizedBox(height: 16),
                                      _RecommendedActivitiesSection(
                                        provider: activityProvider,
                                        l10n: l10n,
                                        currentUserId: currentUserId,
                                        onRetry: () {
                                          _refreshActivities();
                                        },
                                        onEmptyTap: _openActivities,
                                        onActivityTap:
                                            _openRecommendedActivityDetails,
                                        location: homeLocation,
                                      ),
                                      if (isLoggedIn) ...[
                                        SizedBox(height: isCompact ? 30 : 34),
                                        _SectionHeader(
                                          title: l10n.homeSmartPostsTitle,
                                          actionLabel: l10n.homeSeeAll,
                                          onActionTap: _openFeed,
                                        ),
                                        const SizedBox(height: 16),
                                        _HomeSmartPostsSection(
                                          items: homePostStreamItems,
                                          isLoading:
                                              _topPostsLoading &&
                                              _homePostFeedItems.isEmpty,
                                          hasError:
                                              _topPostsLoadFailed &&
                                              _homePostFeedItems.isEmpty,
                                          isLoadingMore:
                                              _homePostFeedLoadingMore,
                                          hasLoadMoreError:
                                              _homePostFeedLoadMoreFailed,
                                          onPostTap: _openTopPost,
                                          onRetry: () =>
                                              _loadHomeFeed(force: true),
                                          onLoadMoreRetry: () =>
                                              _loadHomeFeed(append: true),
                                          onEmptyTap: _openFeed,
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

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final textScale = _homeTextScaleFactor(context);
    final isCompact = screenWidth < 375;
    final maxDialogHeight =
        (screenHeight - mediaQuery.viewPadding.vertical - 48)
            .clamp(320.0, screenHeight)
            .toDouble();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 386, maxHeight: maxDialogHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF21170D),
              border: Border.all(color: const Color(0x293A270F)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -72,
                  right: -80,
                  child: IgnorePointer(
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -98,
                  left: -88,
                  child: IgnorePointer(
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 22 : 26,
                      isCompact ? 22 : 26,
                      isCompact ? 22 : 26,
                      isCompact ? 20 : 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: isCompact ? 54 : 58,
                          height: isCompact ? 54 : 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2C2118),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.14),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.accent,
                            size: 27,
                          ),
                        ),
                        SizedBox(height: isCompact ? 18 : 20),
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFFFF7EC),
                            fontSize: isCompact ? 21 : 23,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message,
                          style: TextStyle(
                            color: const Color(
                              0xFFE0D4C6,
                            ).withValues(alpha: 0.88),
                            fontSize: isCompact ? 14 : 15,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: isCompact ? 22 : 26),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final useStackedActions =
                                constraints.maxWidth < 318 || textScale > 1.25;
                            final actionWidth = useStackedActions
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 12) / 2;

                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.end,
                              children: [
                                SizedBox(
                                  width: actionWidth,
                                  child: _LogoutDialogActionButton(
                                    label: cancelLabel,
                                    onTap: onCancel,
                                    isPrimary: false,
                                  ),
                                ),
                                SizedBox(
                                  width: actionWidth,
                                  child: _LogoutDialogActionButton(
                                    label: confirmLabel,
                                    onTap: onConfirm,
                                    isPrimary: true,
                                  ),
                                ),
                              ],
                            );
                          },
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
    );
  }
}

class _LogoutDialogActionButton extends StatelessWidget {
  const _LogoutDialogActionButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isPrimary
        ? AppColors.textPrimary
        : const Color(0xFFD8C7B7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Ink(
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.accent : const Color(0xFF2C2118),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPrimary ? AppColors.accent : const Color(0xFF3B260D),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 15,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.location,
    required this.currentLocationLabel,
    required this.onLocationTap,
    required this.onMenuTap,
    required this.onNotificationsTap,
  });

  final HomeLocationPreference location;
  final String currentLocationLabel;
  final VoidCallback onLocationTap;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 375;
    final buttonSize = isCompact ? 38.0 : 40.0;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, isCompact ? 13 : 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.accent.withValues(alpha: 0.08)),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accent.withValues(alpha: 0.03),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          _HeaderActionButton(
            icon: Icons.menu_rounded,
            size: buttonSize,
            onTap: onMenuTap,
          ),
          Expanded(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onLocationTap,
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 10,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isCompact ? 34 : 38,
                          height: isCompact ? 34 : 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withValues(alpha: 0.08),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: AppColors.accent,
                            size: isCompact ? 18 : 20,
                          ),
                        ),
                        SizedBox(width: isCompact ? 8 : 10),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentLocationLabel,
                                style: TextStyle(
                                  color: const Color(0xFFFFB347),
                                  fontSize: isCompact ? 10 : 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
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
                                      style: TextStyle(
                                        color: const Color(0xFFFFF7EF),
                                        fontSize: isCompact ? 16 : 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.expand_more_rounded,
                                    color: Colors.white.withValues(alpha: 0.72),
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
          _HeaderActionButton(
            icon: Icons.notifications_none_rounded,
            size: buttonSize,
            onTap: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: AppColors.accent, size: size < 46 ? 20 : 22),
        ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: isCompact ? 50 : 55),
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 18),
            decoration: BoxDecoration(
              color: const Color(0xFF43280D),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.02),
                  blurRadius: 0,
                  spreadRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.search_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF927C67),
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
            style: TextStyle(
              color: Color(0xFFF5EFE8),
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
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: AppColors.accent,
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

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 35,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _NetworkCardImage(imageUrl: data.imageUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF1C150C).withValues(alpha: 0.90),
                      const Color(0xFF1C150C).withValues(alpha: 0.38),
                      const Color(0xFF1C150C).withValues(alpha: 0.05),
                    ],
                    stops: const [0, 0.48, 1],
                  ),
                ),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.66,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 20 : 24,
                    vertical: isCompact ? 22 : 28,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.eyebrow,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.accent,
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
                                style: TextStyle(
                                  color: const Color(0xFFFFFBF6),
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
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: isCompact ? 12 : 13,
                                  height: 1.32,
                                ),
                              ),
                            ],
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

class _TopDestinationsRow extends StatelessWidget {
  const _TopDestinationsRow({
    required this.attractions,
    required this.isLoading,
    required this.hasError,
    required this.onAttractionTap,
    required this.onRetry,
  });

  final List<AttractionVm> attractions;
  final bool isLoading;
  final bool hasError;
  final ValueChanged<AttractionVm> onAttractionTap;
  final VoidCallback onRetry;

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

        if (isLoading && attractions.isEmpty) {
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

        if (hasError && attractions.isEmpty) {
          return _TopDestinationMessage(
            icon: Icons.cloud_off_rounded,
            message: l10n.attractionsLoadFailed,
            actionLabel: l10n.retryButton,
            onActionTap: onRetry,
          );
        }

        if (attractions.isEmpty) {
          return _TopDestinationMessage(
            icon: Icons.landscape_rounded,
            message: l10n.attractionsNoResults,
            actionLabel: l10n.homeSeeAll,
            onActionTap: onRetry,
          );
        }

        final items = attractions.take(10).toList(growable: false);
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
              itemCount: items.length,
              separatorBuilder: (_, _) => SizedBox(width: gap),
              itemBuilder: (context, index) {
                final attraction = items[index];
                return SizedBox(
                  width: cardWidth,
                  child: _TopDestinationAttractionCard(
                    attraction: attraction,
                    onTap: () => onAttractionTap(attraction),
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

class _TopDestinationAttractionCard extends StatelessWidget {
  const _TopDestinationAttractionCard({
    required this.attraction,
    required this.onTap,
  });

  final AttractionVm attraction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCompact = MediaQuery.sizeOf(context).width < 375;
    final textScale = _homeTextScaleFactor(context);
    final titleFontSize = isCompact ? 16.0 : 17.0;
    final titleLineHeight = 1.16;
    final titleStyle = TextStyle(
      color: const Color(0xFFF7F2EA),
      fontSize: titleFontSize,
      height: titleLineHeight,
      fontWeight: FontWeight.w900,
    );
    final titleBlockHeight = _homeTopDestinationTitleBlockHeight(
      isCompact: isCompact,
      textScale: textScale,
    );
    final coverMedia = attraction.coverMedia;
    final coverUrl = _resolveHomeAttractionImageUrl(coverMedia);
    final categoryLabel = _homeAttractionCategoryLabel(l10n, attraction);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: AspectRatio(
                aspectRatio: 0.74,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.24),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (coverUrl == null)
                          const _AttractionCardImagePlaceholder()
                        else
                          _AttractionCardNetworkImage(
                            imageUrl: coverUrl,
                            logicalWidth:
                                MediaQuery.sizeOf(context).width * 0.5,
                          ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.58),
                              ],
                              stops: const [0.48, 1],
                            ),
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
                  attraction.title,
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
                    formatAttractionPriceLabel(context, l10n, attraction),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFA79D93),
                      fontSize: isCompact ? 12 : 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '★ ${attraction.rating.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: AppColors.accent,
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1B2D32).withValues(alpha: 0.70),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: const SizedBox(
        width: 38,
        height: 38,
        child: Icon(
          Icons.bookmark_border_rounded,
          color: Colors.white,
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
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFFFE5BC),
            fontSize: 10,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AttractionCardNetworkImage extends StatelessWidget {
  const _AttractionCardNetworkImage({
    required this.imageUrl,
    required this.logicalWidth,
  });

  final String imageUrl;
  final double logicalWidth;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      headers: attractionImageRequestHeaders(imageUrl),
      fit: BoxFit.cover,
      cacheWidth: attractionImageTargetWidth(
        context,
        logicalWidth,
        minWidth: 360,
        maxWidth: 720,
      ),
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const _AttractionCardImagePlaceholder();
      },
      errorBuilder: (_, _, _) => const _AttractionCardImagePlaceholder(),
    );
  }
}

class _AttractionCardImagePlaceholder extends StatelessWidget {
  const _AttractionCardImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05)),
      child: const Center(
        child: Icon(
          Icons.landscape_rounded,
          color: AppColors.textCaption,
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
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
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
    required this.actionLabel,
    required this.onActionTap,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final textScale = _homeTextScaleFactor(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedAction = constraints.maxWidth < 340 || textScale > 1.25;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: useStackedAction
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: AppColors.textCaption, size: 28),
                          const SizedBox(width: 14),
                          Expanded(child: _TopDestinationMessageText(message)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _TopDestinationMessageAction(
                          label: actionLabel,
                          onTap: onActionTap,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(icon, color: AppColors.textCaption, size: 28),
                      const SizedBox(width: 14),
                      Expanded(child: _TopDestinationMessageText(message)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _TopDestinationMessageAction(
                            label: actionLabel,
                            onTap: onActionTap,
                          ),
                        ),
                      ),
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
      style: const TextStyle(
        color: AppColors.textSecondary,
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
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w800,
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
    required this.onEmptyTap,
  });

  final List<PostVm> posts;
  final bool isLoading;
  final bool hasError;
  final ValueChanged<PostVm> onPostTap;
  final VoidCallback onRetry;
  final VoidCallback onEmptyTap;

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
            actionLabel: l10n.homeSeeAll,
            onActionTap: onEmptyTap,
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
              itemCount: items.length,
              separatorBuilder: (_, _) => SizedBox(width: gap),
              itemBuilder: (context, index) {
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
    final titleStyle = TextStyle(
      color: const Color(0xFFFFFAF4),
      fontSize: titleFontSize,
      height: titleLineHeight,
      fontWeight: FontWeight.w900,
    );
    final excerptStyle = TextStyle(
      color: const Color(0xFFCDB9A5),
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
    final borderColor = isExpired
        ? Colors.white.withValues(alpha: 0.04)
        : AppColors.accent.withValues(alpha: 0.18);

    return Opacity(
      opacity: isExpired ? 0.56 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('open-home-top-post-${post.id}'),
          onTap: isInteractive ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2B190D), Color(0xFF21140B)],
              ),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
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
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.08),
                                Colors.black.withValues(alpha: 0.62),
                              ],
                              stops: const [0.42, 1],
                            ),
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
                      padding: EdgeInsets.fromLTRB(
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
                                  ? const Color(0xFFD9C8B8)
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
                                borderColor: AppColors.accent.withValues(
                                  alpha: isExpired ? 0.16 : 0.30,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  post.author.preferredName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: const Color(0xFFD9C8B8),
                                    fontSize: isCompact ? 11.5 : 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.remove_red_eye_outlined,
                                color: AppColors.accent,
                                size: isCompact ? 15 : 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatStoryCountCompact(post.stats.views),
                                style: TextStyle(
                                  color: AppColors.accent,
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xD01F1710),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 13,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            height: imageHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 14),
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

class _HomeSmartPostsSection extends StatelessWidget {
  const _HomeSmartPostsSection({
    required this.items,
    required this.isLoading,
    required this.hasError,
    required this.isLoadingMore,
    required this.hasLoadMoreError,
    required this.onPostTap,
    required this.onRetry,
    required this.onLoadMoreRetry,
    required this.onEmptyTap,
  });

  final List<_HomePostFeedItem> items;
  final bool isLoading;
  final bool hasError;
  final bool isLoadingMore;
  final bool hasLoadMoreError;
  final ValueChanged<PostVm> onPostTap;
  final VoidCallback onRetry;
  final VoidCallback onLoadMoreRetry;
  final VoidCallback onEmptyTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (items.isEmpty && isLoading) {
      return Column(
        children: List.generate(
          3,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 14),
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
      return _TopDestinationMessage(
        icon: Icons.dynamic_feed_rounded,
        message: l10n.homeSmartPostsEmpty,
        actionLabel: l10n.homeSeeAll,
        onActionTap: onEmptyTap,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          FeedPostCard(post: items[index].post, onOpen: onPostTap),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF26170C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
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
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.accent,
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
        foregroundColor: AppColors.accent,
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.34)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _RecommendedActivitiesSection extends StatelessWidget {
  const _RecommendedActivitiesSection({
    required this.provider,
    required this.l10n,
    required this.currentUserId,
    required this.location,
    required this.onRetry,
    required this.onEmptyTap,
    required this.onActivityTap,
  });

  final ActivityProvider provider;
  final AppLocalizations l10n;
  final String currentUserId;
  final HomeLocationPreference location;
  final VoidCallback onRetry;
  final VoidCallback onEmptyTap;
  final void Function(ActivityListItemVm activity, int rank) onActivityTap;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final recommendedItems = _filterHomeRecommendedItems(
      publicItems: provider.items,
      location: location,
    );
    final isLoadingPublic =
        provider.state == ActivitiesState.loading ||
        provider.state == ActivitiesState.initial;
    final hasLoadError = provider.state == ActivitiesState.error;

    if (recommendedItems.isEmpty && isLoadingPublic) {
      return Column(
        children: List.generate(
          3,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: _RecommendedLoadingCard(),
          ),
        ),
      );
    }

    if (recommendedItems.isEmpty && hasLoadError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.errorMessage ?? l10n.activitiesLoadFailed,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.30),
                ),
              ),
              child: Text(l10n.retryButton),
            ),
          ],
        ),
      );
    }

    if (recommendedItems.isEmpty) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEmptyTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.explore_rounded,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.noActivitiesYet,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.activitiesWillAppearHere,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textCaption,
                ),
              ],
            ),
          ),
        ),
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
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
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
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFFFF7EF),
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
                          style: TextStyle(
                            color: const Color(0xFFAFA5BA),
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
                              style: TextStyle(
                                color: const Color(0xFFFF9F1A),
                                fontSize: isCompact ? 16 : 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (!item.isFree)
                              Text(
                                l10n.createPricePerPersonHint,
                                style: TextStyle(
                                  color: const Color(0xFFAFA5BA),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: isCompact ? 34 : 40),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
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
    final art = _homeCardArtForItem(item);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
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
      decoration: BoxDecoration(
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: -28,
            bottom: -24,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.16),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Icon(
                spec.icon,
                size: 34,
                color: Colors.white.withValues(alpha: 0.3),
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5A3519), Color(0xFF2D1A0D)],
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

_HomeCardArtSpec _homeCategoryVisual(String slug) {
  if (slug.contains('wellness') || slug.contains('health')) {
    return const _HomeCardArtSpec(
      icon: Icons.spa_rounded,
      colors: [Color(0xFF295E54), Color(0xFF74D2AE)],
    );
  }
  if (slug.contains('nature') ||
      slug.contains('outdoor') ||
      slug.contains('hiking')) {
    return const _HomeCardArtSpec(
      icon: Icons.forest_rounded,
      colors: [Color(0xFF2A4B2B), Color(0xFF78C36A)],
    );
  }
  if (slug.contains('food')) {
    return const _HomeCardArtSpec(
      icon: Icons.restaurant_rounded,
      colors: [Color(0xFF66371A), Color(0xFFFFA657)],
    );
  }
  if (slug.contains('culture') ||
      slug.contains('art') ||
      slug.contains('history')) {
    return const _HomeCardArtSpec(
      icon: Icons.palette_outlined,
      colors: [Color(0xFF5A3055), Color(0xFFCB84BA)],
    );
  }
  if (slug.contains('sport') || slug.contains('adventure')) {
    return const _HomeCardArtSpec(
      icon: Icons.kayaking_rounded,
      colors: [Color(0xFF5F3D1F), Color(0xFFE69B4B)],
    );
  }
  if (slug.contains('workshop') ||
      slug.contains('learning') ||
      slug.contains('education')) {
    return const _HomeCardArtSpec(
      icon: Icons.auto_stories_rounded,
      colors: [Color(0xFF443A73), Color(0xFF9A89E2)],
    );
  }
  if (slug.contains('night') || slug.contains('social')) {
    return const _HomeCardArtSpec(
      icon: Icons.celebration_rounded,
      colors: [Color(0xFF5A2348), Color(0xFFE07AB8)],
    );
  }

  return const _HomeCardArtSpec(
    icon: Icons.travel_explore_rounded,
    colors: [Color(0xFF52301B), Color(0xFFCB8B50)],
  );
}

_HomeCardArtSpec _homeCardArtForItem(ActivityListItemVm item) {
  final fromCategory = _homeCategoryVisual(
    item.categorySlug.trim().toLowerCase(),
  );
  if (item.format.toUpperCase() == 'ONLINE') {
    return const _HomeCardArtSpec(
      icon: Icons.videocam_rounded,
      colors: [Color(0xFF1F4D8A), Color(0xFF67A8F5)],
    );
  }
  if (item.format.toUpperCase() == 'HYBRID') {
    return const _HomeCardArtSpec(
      icon: Icons.devices_rounded,
      colors: [Color(0xFF5E3E86), Color(0xFFB08CF6)],
    );
  }
  return fromCategory;
}

class _RecommendedLoadingCard extends StatelessWidget {
  const _RecommendedLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
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
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
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

String? _resolveHomeAttractionImageUrl(AttractionMediaVm? media) {
  if (media == null) return null;

  final fileUrl = resolveAttractionMediaUrl(media)?.trim() ?? '';
  if (fileUrl.isNotEmpty) return fileUrl;

  final externalUrl = media.externalUrl.trim();
  if (externalUrl.isNotEmpty) return externalUrl;

  final sourceUrl = media.sourceUrl.trim();
  if (sourceUrl.isNotEmpty) return sourceUrl;

  return null;
}

String _homeAttractionCategoryLabel(
  AppLocalizations l10n,
  AttractionVm attraction,
) {
  switch (attraction.category.toUpperCase()) {
    case 'PARK':
      return l10n.attractionFilterCategoryParks;
    case 'MUSEUM':
      return l10n.attractionFilterCategoryMuseums;
    case 'NATURE':
      return l10n.attractionFilterCategoryNature;
    case 'ARCHITECTURE':
      return l10n.attractionFilterCategoryArchitecture;
    case 'BEACH':
      return l10n.attractionFilterCategoryBeach;
    case 'TEMPLE':
      return l10n.attractionFilterCategoryTemple;
    case 'ENTERTAINMENT':
      return l10n.attractionFilterCategoryEntertainment;
    case 'FOOD':
      return l10n.attractionFilterCategoryFood;
    case 'MARKET':
      return l10n.attractionFilterCategoryMarket;
    case 'SHOPPING':
      return l10n.attractionFilterCategoryShopping;
    case 'OTHER':
      return l10n.attractionFilterCategoryOther;
    case 'PARKS':
      return l10n.attractionFilterCategoryParks;
    case 'MUSEUMS':
      return l10n.attractionFilterCategoryMuseums;
    case 'HISTORY':
      return l10n.attractionFilterCategoryHistory;
    case 'ADVENTURE':
      return l10n.attractionFilterCategoryAdventure;
    default:
      return l10n.attractionFilterCategoryOther;
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

class _HomePostFeedEventTarget {
  const _HomePostFeedEventTarget({
    required this.blockId,
    required this.blockType,
    required this.rank,
  });

  final String blockId;
  final String blockType;
  final int rank;
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
  List<FeedBlockVm> blocks,
) {
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
  final titleStyle = TextStyle(
    fontSize: titleFontSize,
    height: titleLineHeight,
    fontWeight: FontWeight.w900,
  );
  final excerptStyle = TextStyle(
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
