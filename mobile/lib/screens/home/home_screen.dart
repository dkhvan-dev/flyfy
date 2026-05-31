import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/story_api.dart';
import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_colors.dart';
import '../../features/activities/activity_cover_url.dart';
import '../../features/activities/activity_taxonomy_resolver.dart';
import '../../features/activities/models/activity_category_vm.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/attractions/attraction_ui.dart';
import '../../features/attractions/data/attraction_api.dart';
import '../../features/attractions/models/attraction_vm.dart';
import '../../features/profile/data/guide_api.dart';
import '../../features/stories/models/story_vm.dart';
import '../../features/stories/story_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_location_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/session_provider.dart';
import '../../shared/widgets/app_localized_location_text.dart';
import '../common/app_side_drawer.dart';
import 'widgets/home_location_picker_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final GuideApi _guideApi = GuideApi();
  final AttractionApi _attractionApi = AttractionApi();
  final StoryApi _storyApi = StoryApi();
  String? _requestedHostedActivitiesForUserId;
  String? _requestedJoinedActivitiesForUserId;
  String? _requestedTopAttractionsLocale;
  String? _guideBadgeUserId;
  bool _isGuideBadgeLoading = false;
  int _guideBadgeRequestVersion = 0;
  List<AttractionVm> _topAttractions = const [];
  List<StoryVm> _topStories = const [];
  bool _topAttractionsLoading = true;
  bool _topAttractionsLoadFailed = false;
  bool _topStoriesLoading = true;
  bool _topStoriesLoadFailed = false;
  bool _topStoriesRequestStarted = false;
  bool _showGuideBadge = false;
  bool _isGuideStatusRevoked = false;
  bool _suppressGuideFallback = false;

  static const _promoYachtImageUrl =
      'https://images.unsplash.com/photo-1567899378494-47b22a2ae96a?auto=format&fit=crop&w=900&q=80';
  static const _promoMountainImageUrl =
      'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=900&q=80';

  static const _featuredStaysImageUrl =
      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=700&q=80';
  static const _carRentalsImageUrl =
      'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=700&q=80';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ActivityProvider>();
      final sessionProvider = context.read<SessionProvider>();
      context.read<HomeLocationProvider>().load(
            profile: sessionProvider.profile,
          );
      if (provider.state == ActivitiesState.initial && provider.items.isEmpty) {
        provider.loadActivities();
      }
      if (provider.categoryState == ActivitiesState.initial &&
          provider.categoryItems.isEmpty) {
        provider.loadActivityCategories();
      }
      final currentUserId = (sessionProvider.profile?.userId ?? '').trim();
      if (currentUserId.isNotEmpty &&
          provider.joinedState == ActivitiesState.initial &&
          provider.joinedItems.isEmpty) {
        provider.loadJoinedActivities();
      }
      _loadTopAttractions();
      _loadTopStories();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleHomeNavTap() {
    FocusManager.instance.primaryFocus?.unfocus();
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

  void _openExcursions() {
    context.push('/excursions');
  }

  void _openGuides() {
    context.push('/guides');
  }

  void _openStories() {
    context.push('/stories');
  }

  void _openStoryDetails(StoryVm story) {
    final slug = story.slug.trim();
    if (slug.isEmpty) {
      _openStories();
      return;
    }

    context.push('/stories/${Uri.encodeComponent(slug)}', extra: story);
  }

  void _openAttractions() {
    context.push('/attractions');
  }

  void _openCurrencyConverter() {
    context.push('/currency-converter');
  }

  void _openAttractionDetails(AttractionVm attraction) {
    context.push('/attractions/${attraction.id}', extra: attraction);
  }

  void _openActivityDetails(String activityId) {
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
      _loadTopStories(force: true),
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

  List<_FeatureEntryData> _buildFeatureEntries(AppLocalizations l10n) {
    return [
      _FeatureEntryData(
        title: l10n.homeFeaturedStays,
        imageUrl: _featuredStaysImageUrl,
        icon: Icons.bed_rounded,
        isEnabled: false,
      ),
      _FeatureEntryData(
        title: l10n.homeCarRentals,
        imageUrl: _carRentalsImageUrl,
        icon: Icons.directions_car_filled_rounded,
        isEnabled: false,
      ),
    ];
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

  Future<void> _loadTopStories({bool force = false}) async {
    if (!mounted) return;
    if (!force &&
        _topStoriesRequestStarted &&
        (_topStories.isNotEmpty || _topStoriesLoading)) {
      return;
    }

    _topStoriesRequestStarted = true;
    setState(() {
      _topStoriesLoading = _topStories.isEmpty;
      _topStoriesLoadFailed = false;
    });

    try {
      final stories = await _storyApi.listStories(sort: 'popular', limit: 5);
      if (!mounted) return;
      setState(() {
        _topStories = stories.take(5).toList(growable: false);
        _topStoriesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _topStoriesLoading = false;
        _topStoriesLoadFailed = true;
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

  Future<void> _showLanguageSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();
    final currentCode = localeProvider.locale.languageCode;
    final selectedCode = await showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      isScrollControlled: true,
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        final screenSize = mediaQuery.size;
        final screenWidth = screenSize.width;
        final screenHeight = screenSize.height;
        final textScale = _homeTextScaleFactor(sheetContext);
        final isCompact = screenWidth < 375;
        final isShortLayout = screenHeight < 700 || textScale > 1.2;
        final bottomInset = mediaQuery.viewInsets.bottom;
        final maxSheetHeight = (screenHeight - mediaQuery.viewPadding.top - 12)
            .clamp(320.0, screenHeight)
            .toDouble();
        final horizontalPadding = isCompact ? 22.0 : 26.0;
        final sheetRadius = isCompact ? 30.0 : 34.0;
        final visualScale = isShortLayout ? 0.82 : 1.0;
        final iconWrapSize = (isCompact ? 124.0 : 140.0) * visualScale;
        final glowSize = iconWrapSize + (isCompact ? 20.0 : 22.0);
        final iconSize = (isCompact ? 50.0 : 58.0) * visualScale;
        final topPadding = isShortLayout ? 20.0 : (isCompact ? 24.0 : 28.0);
        final bottomPadding = isShortLayout ? 20.0 : (isCompact ? 24.0 : 30.0);
        final handleToIconGap =
            isShortLayout ? 20.0 : (isCompact ? 26.0 : 34.0);
        final iconToTitleGap = isShortLayout ? 18.0 : (isCompact ? 22.0 : 26.0);
        final titleToOptionsGap =
            isShortLayout ? 22.0 : (isCompact ? 28.0 : 34.0);
        final optionGap = isShortLayout ? 12.0 : (isCompact ? 14.0 : 16.0);

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(sheetRadius),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF211207), Color(0xFF170D06)],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(sheetRadius),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.24),
                          blurRadius: 40,
                          offset: const Offset(0, -12),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.02),
                                    Colors.transparent,
                                  ],
                                  stops: const [0, 0.16],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -24,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Container(
                              height: 110,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(0, 0.7),
                                  radius: 0.95,
                                  colors: [
                                    AppColors.accent.withValues(alpha: 0.08),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              topPadding,
                              horizontalPadding,
                              bottomPadding,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: Container(
                                    width: 76,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.45,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.18,
                                          ),
                                          blurRadius: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: handleToIconGap),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: glowSize,
                                      height: glowSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            AppColors.accent.withValues(
                                              alpha: 0.26,
                                            ),
                                            AppColors.accent.withValues(
                                              alpha: 0.12,
                                            ),
                                            AppColors.accent.withValues(
                                              alpha: 0.04,
                                            ),
                                            Colors.transparent,
                                          ],
                                          stops: const [0, 0.3, 0.52, 0.78],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: iconWrapSize,
                                      height: iconWrapSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          center: const Alignment(0, -0.25),
                                          colors: [
                                            AppColors.accent.withValues(
                                              alpha: 0.05,
                                            ),
                                            AppColors.accent.withValues(
                                              alpha: 0.01,
                                            ),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.36,
                                          ),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.accent.withValues(
                                              alpha: 0.18,
                                            ),
                                            blurRadius: 28,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.language_rounded,
                                        size: iconSize,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: iconToTitleGap),
                                Text(
                                  l10n.appLanguageTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: isCompact ? 16 : 18,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                                ),
                                SizedBox(height: titleToOptionsGap),
                                for (final option in _languageOptions) ...[
                                  _LanguageOptionTile(
                                    label: option.label,
                                    code: option.code.toUpperCase(),
                                    isSelected: currentCode == option.code,
                                    onTap: () => Navigator.of(
                                      sheetContext,
                                    ).pop(option.code),
                                  ),
                                  if (option != _languageOptions.last)
                                    SizedBox(height: optionGap),
                                ],
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
          ),
        );
      },
    );

    if (selectedCode == null || !mounted) return;
    await localeProvider.setLocale(selectedCode);
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

  String _resolveLanguageLabel(String code) {
    return code.toUpperCase();
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
    if (!homeLocationProvider.isLoaded && !homeLocationProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<HomeLocationProvider>().load(profile: profile);
      });
    } else if (homeLocationProvider.shouldSyncProfile(profile)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<HomeLocationProvider>().syncProfileFallback(profile);
      });
    }
    final homeLocation = homeLocationProvider.effectiveLocation;
    final location = homeLocation.fallbackLabel;
    final featureEntries = _buildFeatureEntries(l10n);
    final promos = _buildPromoCards(l10n);

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

    final quickActions = [
      _QuickActionData(
        title: l10n.homeServiceActivities,
        icon: Icons.hiking_rounded,
        onTap: _openActivities,
      ),
      _QuickActionData(
        title: l10n.serviceExcursions,
        icon: Icons.travel_explore_rounded,
        onTap: _openExcursions,
      ),
      _QuickActionData(
        title: l10n.serviceGuides,
        icon: Icons.flag_rounded,
        onTap: _openGuides,
      ),
      _QuickActionData(
        title: l10n.homeServiceStories,
        icon: Icons.article_rounded,
        onTap: _openStories,
      ),
      _QuickActionData(
        title: l10n.homeServiceAttractions,
        icon: Icons.account_balance_rounded,
        onTap: _openAttractions,
      ),
      _QuickActionData(
        title: l10n.homeServiceCurrencyConverter,
        icon: Icons.currency_exchange_rounded,
        onTap: _openCurrencyConverter,
      ),
      _QuickActionData(title: l10n.homeServiceStays, icon: Icons.bed_rounded),
      _QuickActionData(
        title: l10n.serviceTransport,
        icon: Icons.directions_car_filled_rounded,
      ),
      _QuickActionData(
        title: l10n.homeServiceDelivery,
        icon: Icons.delivery_dining_rounded,
      ),
      _QuickActionData(
        title: l10n.homeServiceTaxi,
        icon: Icons.local_taxi_rounded,
      ),
    ];

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
        languageLabel: _resolveLanguageLabel(
          context.watch<LocaleProvider>().locale.languageCode,
        ),
        activeItem: AppDrawerActiveItem.none,
        onProfileTap: () => _runDrawerAction(_openProfile),
        onLanguageTap: () => _runDrawerAction(_showLanguageSheet),
        onHomeTap: () => _runDrawerAction(() => context.go('/')),
        onMyActivitiesTap: () => _runDrawerAction(_openMyActivities),
        onMyExcursionsTap: () =>
            _runDrawerAction(() => context.push('/me/excursions')),
        onMyStoriesTap: () =>
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
        onServicesTap: () {},
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
                                      SizedBox(height: isCompact ? 30 : 36),
                                      _QuickActionsGrid(actions: quickActions),
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
                                        onActionTap: _openStories,
                                      ),
                                      const SizedBox(height: 14),
                                      _TopStoriesCarousel(
                                        stories: _topStories,
                                        isLoading: _topStoriesLoading,
                                        hasError: _topStoriesLoadFailed,
                                        onStoryTap: _openStoryDetails,
                                        onRetry: () =>
                                            _loadTopStories(force: true),
                                        onEmptyTap: _openStories,
                                      ),
                                      const SizedBox(height: 14),
                                      _FeatureEntriesGrid(
                                        entries: featureEntries,
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
                                        onActivityTap: _openActivityDetails,
                                        location: homeLocation,
                                      ),
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
    final foregroundColor =
        isPrimary ? AppColors.textPrimary : const Color(0xFFD8C7B7);

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

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.actions});

  final List<_QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 375;
        final gap = isCompact ? 12.0 : 24.0;
        final tileWidth = (constraints.maxWidth - gap * 2) / 3;
        final iconSize = isCompact ? 26.0 : 31.0;
        final iconLabelGap = isCompact ? 7.0 : 9.0;
        final verticalPadding = isCompact ? 10.0 : 12.0;
        final minContentHeight =
            iconSize + iconLabelGap + 13 + verticalPadding * 2;
        final visualHeight = tileWidth * (isCompact ? 0.82 : 0.76);
        final tileHeight =
            visualHeight < minContentHeight ? minContentHeight : visualHeight;

        return GridView.builder(
          shrinkWrap: true,
          itemCount: actions.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: isCompact ? 18 : 26,
            crossAxisSpacing: gap,
            mainAxisExtent: tileHeight,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            final isEnabled = action.onTap != null;
            final foregroundColor =
                isEnabled ? AppColors.accent : const Color(0xFF8E8A84);
            final textColor =
                isEnabled ? const Color(0xFFF2E5D7) : const Color(0xFFB1AAA2);
            final backgroundColor =
                isEnabled ? const Color(0xFF43280D) : const Color(0xFF3D3935);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(16),
                splashColor: isEnabled
                    ? AppColors.accent.withValues(alpha: 0.10)
                    : Colors.transparent,
                highlightColor: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isEnabled
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 6 : 8,
                      vertical: verticalPadding,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          action.icon,
                          color: foregroundColor,
                          size: iconSize,
                        ),
                        SizedBox(height: iconLabelGap),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              action.title,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textColor,
                                fontSize: isCompact ? 11 : 12,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                separatorBuilder: (_, __) => SizedBox(width: gap),
                itemBuilder: (_, __) => SizedBox(
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
              separatorBuilder: (_, __) => SizedBox(width: gap),
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
            AspectRatio(
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
                          logicalWidth: MediaQuery.sizeOf(context).width * 0.5,
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
      errorBuilder: (_, __, ___) => const _AttractionCardImagePlaceholder(),
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

class _TopStoriesCarousel extends StatelessWidget {
  const _TopStoriesCarousel({
    required this.stories,
    required this.isLoading,
    required this.hasError,
    required this.onStoryTap,
    required this.onRetry,
    required this.onEmptyTap,
  });

  final List<StoryVm> stories;
  final bool isLoading;
  final bool hasError;
  final ValueChanged<StoryVm> onStoryTap;
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

        if (isLoading && stories.isEmpty) {
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
                separatorBuilder: (_, __) => SizedBox(width: gap),
                itemBuilder: (_, __) => SizedBox(
                  width: cardWidth,
                  child: _TopStoryLoadingCard(imageHeight: imageHeight),
                ),
              ),
            ),
          );
        }

        if (hasError && stories.isEmpty) {
          return _TopDestinationMessage(
            icon: Icons.cloud_off_rounded,
            message: l10n.storyLoadFailed,
            actionLabel: l10n.retryButton,
            onActionTap: onRetry,
          );
        }

        if (stories.isEmpty) {
          return _TopDestinationMessage(
            icon: Icons.auto_stories_rounded,
            message: l10n.storyEmptyTitle,
            actionLabel: l10n.homeSeeAll,
            onActionTap: onEmptyTap,
          );
        }

        final items = stories.take(5).toList(growable: false);
        final cardHeight = _homeStoryCardHeight(
          context: context,
          l10n: l10n,
          stories: items,
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
              separatorBuilder: (_, __) => SizedBox(width: gap),
              itemBuilder: (context, index) {
                final story = items[index];
                return SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: _TopStoryCard(
                    story: story,
                    imageHeight: imageHeight,
                    onTap: () => onStoryTap(story),
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

class _TopStoryCard extends StatelessWidget {
  const _TopStoryCard({
    required this.story,
    required this.imageHeight,
    required this.onTap,
  });

  final StoryVm story;
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
    final tagLabel = _homeStoryTagLabel(l10n, story);
    final excerpt = _truncateHomeStoryExcerpt(
      story.excerpt.trim().isNotEmpty ? story.excerpt.trim() : tagLabel,
    );
    final avatarSize = (isCompact ? 24.0 : 26.0) * textScale.clamp(1.0, 1.18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2B190D), Color(0xFF21140B)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                      StoryCoverImage(url: story.coverUrl),
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
                        child: _TopStoryTag(label: tagLabel),
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
                          story.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
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
                              label: story.author.initials,
                              imageUrl: story.author.avatarUrl,
                              size: avatarSize,
                              borderColor: AppColors.accent.withValues(
                                alpha: 0.30,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                story.author.preferredName,
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
                              formatStoryCountCompact(story.stats.views),
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
    );
  }
}

class _TopStoryTag extends StatelessWidget {
  const _TopStoryTag({required this.label});

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

class _TopStoryLoadingCard extends StatelessWidget {
  const _TopStoryLoadingCard({required this.imageHeight});

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

class _FeatureEntriesGrid extends StatelessWidget {
  const _FeatureEntriesGrid({required this.entries});

  final List<_FeatureEntryData> entries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 375;
        final gap = isCompact ? 14.0 : 19.0;

        return Row(
          children: [
            for (var index = 0; index < entries.length; index++) ...[
              Expanded(child: _TravelEntryCard(data: entries[index])),
              if (index != entries.length - 1) SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }
}

class _TravelEntryCard extends StatelessWidget {
  const _TravelEntryCard({required this.data});

  final _FeatureEntryData data;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 375;
    final foreground = data.isEnabled ? Colors.white : const Color(0xFFE0DDD8);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: isCompact ? 1.28 : 1.34,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _NetworkCardImage(
                  imageUrl: data.imageUrl,
                  overlay: Colors.black.withValues(alpha: 0.18),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: data.isEnabled
                          ? Colors.transparent
                          : const Color(0xFF6E6B66).withValues(alpha: 0.42),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0.62),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 10 : 14,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data.icon,
                          color: foreground,
                          size: isCompact ? 28 : 32,
                        ),
                        const SizedBox(height: 7),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            data.title,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: foreground,
                              fontSize: isCompact ? 16 : 18,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
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
  final ValueChanged<String> onActivityTap;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final recommendedItems = _filterHomeRecommendedItems(
      publicItems: provider.items,
      currentUserId: currentUserId,
      location: location,
    );
    final isLoadingPublic = provider.state == ActivitiesState.loading ||
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
            onTap: () => onActivityTap(items[index].id),
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
    final buttonLabel =
        isJoined ? l10n.activityDetailsJoinedBadge : l10n.activityJoinSession;

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
  const _NetworkCardImage({required this.imageUrl, this.overlay});

  final String imageUrl;
  final Color? overlay;

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
        if (overlay != null)
          DecoratedBox(decoration: BoxDecoration(color: overlay)),
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

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFA726), Color(0xFFF98C06)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppColors.accent.withValues(alpha: 0.42),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.96),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.86)
                            : AppColors.accent.withValues(alpha: 0.92),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.accent.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : AppColors.accent.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  color: isSelected ? Colors.white : AppColors.accent,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureEntryData {
  const _FeatureEntryData({
    required this.title,
    required this.imageUrl,
    required this.icon,
    this.isEnabled = false,
  });

  final String title;
  final String imageUrl;
  final IconData icon;
  final bool isEnabled;
}

class _QuickActionData {
  const _QuickActionData({required this.title, required this.icon, this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
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

class _LanguageOption {
  const _LanguageOption({required this.code, required this.label});

  final String code;
  final String label;
}

const List<_LanguageOption> _languageOptions = [
  _LanguageOption(code: 'ru', label: 'Русский'),
  _LanguageOption(code: 'en', label: 'English'),
  _LanguageOption(code: 'kk', label: 'Қазақша'),
];

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

String _homeStoryTagLabel(AppLocalizations l10n, StoryVm story) {
  final placeName = (story.placeName ?? '').trim();
  if (placeName.isNotEmpty) return placeName;

  return formatStoryCategory(l10n, story.category);
}

double _homeStoryCardHeight({
  required BuildContext context,
  required AppLocalizations l10n,
  required List<StoryVm> stories,
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

  for (final story in stories) {
    final tagLabel = _homeStoryTagLabel(l10n, story);
    final excerpt = _truncateHomeStoryExcerpt(
      story.excerpt.trim().isNotEmpty ? story.excerpt.trim() : tagLabel,
    );
    final titleHeight = _measureHomeStoryTextHeight(
      text: story.title,
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
    final excerptHeight = _measureHomeStoryTextHeight(
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
  return imageHeight + verticalPadding + contentBodyHeight + 4;
}

double _measureHomeStoryTextHeight({
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

String _truncateHomeStoryExcerpt(String value) {
  const maxLength = 100;
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.length <= maxLength) return normalized;

  return '${normalized.substring(0, maxLength).trimRight()}...';
}

List<ActivityListItemVm> _filterHomeRecommendedItems({
  required List<ActivityListItemVm> publicItems,
  required String? currentUserId,
  required HomeLocationPreference location,
}) {
  final itemsById = <String, ActivityListItemVm>{};
  final normalizedUserId = (currentUserId ?? '').trim();

  for (final item in publicItems) {
    if (_isHomeRecommendedActivity(item, normalizedUserId) &&
        _matchesHomeLocation(item, location)) {
      itemsById[item.id] = item;
    }
  }

  final merged = itemsById.values.toList(growable: false)
    ..sort((a, b) => a.startAt.compareTo(b.startAt));
  return merged;
}

bool _isHomeRecommendedActivity(ActivityListItemVm item, String currentUserId) {
  if (currentUserId.isNotEmpty && item.hostUserId.trim() == currentUserId) {
    return false;
  }
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
  final selectedCityId = (location.cityId ?? '').trim();
  if (selectedCityId.isNotEmpty) {
    return (item.cityId ?? '').trim() == selectedCityId;
  }

  final selectedCityName = _normalizeLocationText(location.cityName);
  final selectedCountryCode = _normalizeLocationText(location.countryCode);
  if (selectedCityName.isEmpty && selectedCountryCode.isEmpty) {
    return true;
  }

  final itemCityName = _normalizeLocationText(item.cityName);
  final itemCountryCode = _normalizeLocationText(item.countryCode);
  if (selectedCityName.isNotEmpty && itemCityName != selectedCityName) {
    return false;
  }
  if (selectedCountryCode.isNotEmpty &&
      itemCountryCode.isNotEmpty &&
      itemCountryCode != selectedCountryCode) {
    return false;
  }
  return selectedCityName.isNotEmpty || selectedCountryCode.isNotEmpty;
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
