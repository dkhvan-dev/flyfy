import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_inline_sort_row.dart';
import '../../core/ui/app_list_search_field.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../core/ui/pagination_bar.dart';
import '../../core/time/app_time.dart';
import '../../core/utils/pagination.dart';
import '../../features/activities/activity_category_art.dart';
import '../../features/activities/activity_cover_url.dart';
import '../../features/activities/activity_formatters.dart';
import '../../features/activities/activity_taxonomy_resolver.dart';
import '../../features/activities/models/activity_category_vm.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/feed/widgets/contextual_story_tray.dart';
import '../../features/profile/data/guide_api.dart';
import '../../features/profile/profile_completion_gate.dart';
import '../../features/profile/profile_guard_result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_location_provider.dart';
import '../../providers/session_provider.dart';
import '../../shared/location/home_location_filter_defaults.dart';
import '../../shared/widgets/app_city_filter_section.dart';
import '../../shared/widgets/app_localized_location_text.dart';
import '../common/app_side_drawer.dart';
import '../map/map_screen.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

final class _ActivitiesColors {
  const _ActivitiesColors._(this.colors, {required this.isLight});

  final AppColors colors;
  final bool isLight;

  static _ActivitiesColors of(BuildContext context) {
    return _ActivitiesColors._(
      AppDesignSystem.colorsFor(context),
      isLight: Theme.of(context).brightness == Brightness.light,
    );
  }

  Color get primary => colors.primary;
  Color get primaryText => isLight ? const Color(0xFFB45309) : colors.primary;
  Color get primaryPressed => colors.primaryPressed;
  Color get primarySoft => colors.primarySoft;
  Color get primaryContainer => colors.primaryContainer;
  Color get onPrimary => colors.onPrimary;
  Color get secondary => colors.secondary;
  Color get secondaryPressed => colors.secondaryPressed;
  Color get secondarySoft => colors.secondarySoft;
  Color get secondaryContainer => colors.secondaryContainer;
  Color get secondaryText =>
      isLight ? colors.secondaryPressed : colors.secondary;
  Color get secondarySurface =>
      isLight ? colors.secondaryContainer : colors.surfaceTeal;
  Color get secondaryBorder =>
      colors.secondary.withValues(alpha: isLight ? 0.22 : 0.30);
  Color get onSecondary => colors.onSecondary;
  Color get background => colors.background;
  Color get backgroundDeep => colors.backgroundDeep;
  Color get backgroundWarm => colors.backgroundWarm;
  Color get surface => colors.surface;
  Color get surfaceRaised => colors.surfaceRaised;
  Color get surfaceHigh => colors.surfaceHigh;
  Color get surfaceWarm => colors.surfaceWarm;
  Color get surfaceTeal => colors.surfaceTeal;
  Color get activityCardSurface => colors.surfaceRaised;
  Color get activityCardBorder => colors.border;
  Color get textPrimary => colors.textPrimary;
  Color get textSecondary => colors.textSecondary;
  Color get textMuted => colors.textMuted;
  Color get textDisabled => colors.textDisabled;
  Color get border => colors.border;
  Color get borderSoft => colors.borderSoft;
  Color get borderPrimary => colors.borderPrimary;
  Color get borderSecondary => colors.borderSecondary;
  Color get success => colors.success;
  Color get warning => colors.warning;
  Color get danger => colors.danger;
  Color get transparent => colors.transparent;
  Color get black => colors.black;
  Color get white => colors.white;
  Color get scrim => colors.scrim;

  Color get amberLight03 => colors.primarySoft;
  Color get amberSoft04 => colors.primarySoft;
  Color get amberSoft16 => colors.primarySoft;
  Color get amberSoft23 => colors.primarySoft;
  Color get amberWash09 => colors.primaryContainer;
  Color get blueSurface10 => colors.secondaryContainer;
  Color get clearOrangeSoft01 => colors.primarySoft;
  Color get clearOrangeSoft02 => colors.primarySoft;
  Color get clearOrangeSoft03 => colors.primarySoft;
  Color get greenOverlayMuted01 =>
      colors.secondary.withValues(alpha: isLight ? 0.14 : 0.16);
  Color get greenSurface09 => colors.surfaceTeal;
  Color get orangeOverlayLight03 => colors.primary.withValues(alpha: 0.20);
  Color get orangeOverlaySoft01 => colors.primary.withValues(alpha: 0.14);
  Color get orangeOverlaySoft03 => colors.primary.withValues(alpha: 0.18);
  Color get orangeOverlaySoft05 => colors.primary.withValues(alpha: 0.22);
  Color get orangeOverlayWash01 => colors.primary.withValues(alpha: 0.10);
  Color get orangeOverlayWash04 => colors.primary.withValues(alpha: 0.16);
  Color get orangeOverlayWash06 => colors.primary.withValues(alpha: 0.20);
  Color get orangeOverlayWash07 => colors.primary.withValues(alpha: 0.22);
  Color get orangeOverlayWash08 => colors.primary.withValues(alpha: 0.24);
  Color get orangeOverlayWash09 => colors.primary.withValues(alpha: 0.26);
  Color get orangeOverlayWash10 => colors.primary.withValues(alpha: 0.28);
  Color get orangeOverlayWash11 => colors.primary.withValues(alpha: 0.30);
  Color get orangeWash15 => colors.textPrimary;
  Color get orangeWash29 => colors.primary;
  Color get redSoft04 => colors.danger;
  Color get surfaceCool => colors.surfaceHigh;
  Color get textCoolSecondary => colors.textSecondary;
  Color get warmInk100 => colors.backgroundDeep;
  Color get warmInk16 => colors.backgroundDeep;
  Color get warmInk35 => colors.background;
  Color get warmInk51 => colors.background;
  Color get warmInk63 => colors.backgroundDeep;
  Color get warmOverlayInk01 => colors.surface;
  Color get warmOverlaySurface10 => colors.surfaceRaised;
  Color get warmSurface06 => colors.surface;
  Color get warmSurface21 => colors.surface;
  Color get warmSurface53 => colors.surfaceRaised;
  Color get warmSurfaceHigh09 => colors.surfaceHigh;
}

extension _ActivitiesColorContext on BuildContext {
  _ActivitiesColors get activitiesColors => _ActivitiesColors.of(this);
}

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

enum _ActivitySortField { date, price }

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  static const int _discoverPageSize = 8;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GuideApi _guideApi = GuideApi();

  _DiscoverFilters _filters = const _DiscoverFilters();
  String _searchQuery = '';
  String? _loadedHostedUserId;
  String? _guideBadgeUserId;
  bool _showGuideBadge = false;
  int _currentPage = 1;
  _ActivitySortField _sortField = _ActivitySortField.date;
  bool _sortAscending = true;
  bool _hasAppliedDefaultLocationFilter = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeDefaultLocationFilter());
      final provider = context.read<ActivityProvider>();
      provider.loadActivities();
      provider.loadActivityCategories();
    });
  }

  Future<void> _initializeDefaultLocationFilter() async {
    final provider = context.read<HomeLocationProvider>();
    if (!provider.isLoaded && !provider.isLoading) {
      await provider.load(
        languageCode: Localizations.localeOf(context).languageCode,
      );
    }
    if (!mounted) return;
    _applyDefaultLocationFilter(provider);
  }

  void _applyDefaultLocationFilter(HomeLocationProvider provider) {
    if (_hasAppliedDefaultLocationFilter) {
      return;
    }
    if (_filters.country != null || _filters.city != null) {
      _hasAppliedDefaultLocationFilter = true;
      return;
    }

    final defaults = HomeLocationFilterDefaults.fromPreference(
      provider.effectiveLocation,
    );
    if (!defaults.hasValue) return;

    _hasAppliedDefaultLocationFilter = true;

    setState(() {
      _filters = _filters.copyWith(
        country: defaults.country,
        city: defaults.city,
      );
      _currentPage = 1;
    });
  }

  void _scheduleApplyDefaultLocationFilter(HomeLocationProvider provider) {
    if (_hasAppliedDefaultLocationFilter) {
      return;
    }
    if (_filters.country != null || _filters.city != null) {
      _hasAppliedDefaultLocationFilter = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyDefaultLocationFilter(provider);
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim();
    if (_searchQuery == nextQuery) {
      return;
    }
    setState(() {
      _searchQuery = nextQuery;
      _currentPage = 1;
    });
  }

  void _submitActivitySearch(String value) {
    FocusScope.of(context).unfocus();
    final nextQuery = value.trim();
    if (_searchQuery == nextQuery) {
      return;
    }
    setState(() {
      _searchQuery = nextQuery;
      _currentPage = 1;
    });
  }

  void _handleSortTap(_ActivitySortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
      _currentPage = 1;
    });
  }

  Future<void> _handleDiscoverPageChanged(int page) async {
    if (page == _currentPage) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _currentPage = page;
    });
    if (!_scrollController.hasClients) {
      return;
    }
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _onCreateTap(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.state != AuthState.authenticated) {
      context.push('/login?from=/activities/create');
      return;
    }

    final result = await ProfileCompletionGate.ensureCompleted(context);
    if (result == ProfileGuardResult.cancelled) return;
    if (!context.mounted) return;

    context.push('/activities/create');
  }

  void _openActivityDetails(BuildContext context, String activityId) {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.state != AuthState.authenticated) {
      context.push('/login?from=/activities/$activityId');
      return;
    }

    context.push('/activities/$activityId');
  }

  void _openActivitiesMap(List<MapActivityTarget> activities) {
    if (activities.isEmpty) {
      return;
    }

    context.push(
      '/map',
      extra: MapActivityCollection(
        title: AppLocalizations.of(context)!.activitiesNearbyTitle,
        activities: activities,
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();

    final confirmed = await showAppModalDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AppModalDialogCard(
          backgroundColor: context.activitiesColors.surfaceCool,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.circular(20),
          ),
          title: Text(
            l10n.logoutDialogTitle,
            style: AppTextStyle(
              color: context.activitiesColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l10n.logoutDialogMessage,
            style: AppTextStyle(
              color: context.activitiesColors.textCoolSecondary,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n.cancel,
                style: AppTextStyle(
                  color: context.activitiesColors.textCoolSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.activitiesColors.primary,
                foregroundColor: context.activitiesColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.logoutConfirmButton),
            ),
          ],
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

  Future<void> _closeDrawerIfNeeded() async {
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState == null || !scaffoldState.isDrawerOpen) return;

    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 180));
  }

  Future<void> _runDrawerAction(Future<void> Function() action) async {
    await _closeDrawerIfNeeded();
    if (!mounted) return;
    await action();
  }

  Future<void> _refreshActivities(String? currentUserId) async {
    final provider = context.read<ActivityProvider>();

    await provider.refreshActivities();
    if ((currentUserId ?? '').trim().isNotEmpty) {
      await provider.refreshMyActivities();
    }
  }

  void _ensureHostedActivitiesLoaded(String? currentUserId) {
    final normalizedUserId = (currentUserId ?? '').trim();
    if (normalizedUserId.isEmpty) {
      _loadedHostedUserId = null;
      return;
    }
    if (_loadedHostedUserId == normalizedUserId) {
      return;
    }

    _loadedHostedUserId = normalizedUserId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ActivityProvider>().loadMyActivities();
    });
  }

  void _ensureGuideBadgeState(String? currentUserId) {
    final normalizedUserId = (currentUserId ?? '').trim();
    if (normalizedUserId.isEmpty) {
      _guideBadgeUserId = null;
      _showGuideBadge = false;
      return;
    }

    if (_guideBadgeUserId == normalizedUserId) {
      return;
    }

    _guideBadgeUserId = normalizedUserId;
    _showGuideBadge = false;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final guide = await _guideApi.getMyGuideProfileOrNull();
        if (!mounted || _guideBadgeUserId != normalizedUserId) {
          return;
        }
        setState(() {
          _showGuideBadge = guide?.isVerified == true;
        });
      } catch (_) {
        if (!mounted || _guideBadgeUserId != normalizedUserId) {
          return;
        }
        setState(() {
          _showGuideBadge = false;
        });
      }
    });
  }

  Future<void> _openDiscoverFilters(
    BuildContext context,
    List<ActivityCategoryVm> categories,
    List<_DiscoverCategoryOption> categoryOptions,
    List<ActivityListItemVm> items,
    Map<String, String> categoryLabelsBySlug,
  ) async {
    FocusScope.of(context).unfocus();

    final result = await showAppModalBottomSheet<_DiscoverFilters>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: context.activitiesColors.transparent,
      builder: (sheetContext) {
        return _DiscoverFiltersSheet(
          l10n: AppLocalizations.of(sheetContext)!,
          initialFilters: _filters,
          categoryOptions: categoryOptions,
          previewCountBuilder: (draftFilters) {
            return _applyDiscoverFilters(
              items,
              filters: draftFilters,
              searchQuery: _searchQuery,
              categories: categories,
              categoryLabelsBySlug: categoryLabelsBySlug,
            ).length;
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _filters = result;
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final layout = _ActivitiesAdaptiveLayout.of(context);
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final auth = context.watch<AuthProvider>();
    final session = context.watch<SessionProvider>();
    final locationProvider = context.watch<HomeLocationProvider>();
    final isLoggedIn = auth.state == AuthState.authenticated;
    final profile = session.profile;
    final currentUserId = (profile?.userId ?? '').trim();
    final location = resolveDrawerLocation(
      profile,
      Localizations.localeOf(context),
    );

    _ensureHostedActivitiesLoaded(currentUserId);
    _ensureGuideBadgeState(currentUserId);
    _scheduleApplyDefaultLocationFilter(locationProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.activitiesColors.warmInk35,
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: 28,
      drawerScrimColor: context.activitiesColors.black.withValues(alpha: 0.42),
      drawer: AppSideDrawer(
        l10n: l10n,
        isLoggedIn: isLoggedIn,
        showGuideBadge: _showGuideBadge,
        profile: profile,
        location: location,
        activeItem: AppDrawerActiveItem.none,
        onProfileTap: () => _runDrawerAction(() async => _openProfile()),
        onHomeTap: () => _runDrawerAction(() async => context.go('/')),
        onMyActivitiesTap: () => _runDrawerAction(_openMyActivities),
        onMyExcursionsTap: () =>
            _runDrawerAction(() async => context.push('/me/excursions')),
        onMyStoriesTap: () =>
            _runDrawerAction(() async => context.push('/me/posts')),
        onMyStoryArchiveTap: () =>
            _runDrawerAction(() async => context.push('/me/stories')),
        onActivitiesTap: () => _runDrawerAction(() async {}),
        onLoginTap: () => _runDrawerAction(
          () async => context.push('/login?from=/activities'),
        ),
        onLogoutTap: () => _runDrawerAction(_confirmLogout),
      ),
      bottomNavigationBar: CreateActionBottomNavigationBar(
        onHomeTap: () => context.go('/'),
        onQrTap: () => context.push('/qr'),
        onCreateTap: () => _onCreateTap(context),
        onServicesTap: () => context.push('/services'),
        onChatsTap: () => context.push('/chats'),
      ),
      body: _DiscoverScreenBackdrop(
        child: _ActivitiesResponsiveTextScope(
          child: SafeArea(
            child: Consumer<ActivityProvider>(
              builder: (context, provider, _) {
                final discoverItems = _mergePublishedActivities(
                  publicItems: provider.items,
                  hostedItems: provider.myItems,
                  currentUserId: currentUserId,
                );
                final languageCode = Localizations.localeOf(
                  context,
                ).languageCode.toLowerCase();
                final categoryOptions = _buildCategoryOptions(
                  context,
                  provider.categoryItems,
                  discoverItems,
                  languageCode,
                  l10n,
                );
                final categoryLabelsBySlug = {
                  for (final option in categoryOptions)
                    option.slug: option.label.toLowerCase(),
                };
                final filteredItems = _sortDiscoverItems(
                  _applyDiscoverFilters(
                    discoverItems,
                    filters: _filters,
                    searchQuery: _searchQuery,
                    categories: provider.categoryItems,
                    categoryLabelsBySlug: categoryLabelsBySlug,
                  ),
                  sortField: _sortField,
                  sortAscending: _sortAscending,
                );
                final activityMapTargets = _buildActivityMapTargets(
                  filteredItems,
                  context: context,
                  categories: provider.categoryItems,
                  categoryOptions: categoryOptions,
                  l10n: l10n,
                  localeName: Localizations.localeOf(context).toString(),
                );
                final paginatedItems = paginateItems(
                  filteredItems,
                  currentPage: _currentPage,
                  pageSize: _discoverPageSize,
                );

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: RefreshIndicator(
                      color: context.activitiesColors.primary,
                      backgroundColor: context.activitiesColors.warmInk63,
                      onRefresh: () => _refreshActivities(currentUserId),
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SliverPadding(
                            padding: AppEdgeInsets.fromLTRB(
                              layout.horizontalPadding,
                              layout.topPadding,
                              layout.horizontalPadding,
                              0,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppListScreenHeader(
                                    title: l10n.activitiesDiscoverTitle,
                                    notificationsTooltip:
                                        l10n.profileNotificationsRowTitle,
                                    onBackTap: _goBack,
                                    onNotificationsTap: () =>
                                        context.push('/notifications'),
                                    horizontalPadding: 0,
                                  ),
                                  SizedBox(height: layout.sectionGap),
                                  if (isLoggedIn) ...[
                                    SurfaceStoryTray(
                                      surface: 'activities',
                                      viewerAvatarFileId: profile?.avatarFileId,
                                      viewerInitials: profile?.initials ?? 'F',
                                      viewerUserId: profile?.userId,
                                    ),
                                    SizedBox(height: layout.sectionGap),
                                  ],
                                  _DiscoverSearchField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    hintText: l10n.activitiesSearchHint,
                                    activeFilterCount:
                                        _filters.activeGroupCount,
                                    onSubmitted: _submitActivitySearch,
                                    onFilterTap: () => _openDiscoverFilters(
                                      context,
                                      provider.categoryItems,
                                      categoryOptions,
                                      discoverItems,
                                      categoryLabelsBySlug,
                                    ),
                                  ),
                                  SizedBox(height: layout.filterGap),
                                  if (filteredItems.isNotEmpty) ...[
                                    _ActivitiesNearbyMapSection(
                                      title: l10n.activitiesNearbyTitle,
                                      emptyText: l10n.activitiesNearbyMapEmpty,
                                      markers: activityMapTargets,
                                      onTap: activityMapTargets.isEmpty
                                          ? null
                                          : () => _openActivitiesMap(
                                              activityMapTargets,
                                            ),
                                    ),
                                    SizedBox(height: layout.filterGap),
                                  ],
                                  _DiscoverSortBar(
                                    l10n: l10n,
                                    sortField: _sortField,
                                    sortAscending: _sortAscending,
                                    onSortTap: _handleSortTap,
                                  ),
                                  SizedBox(
                                    height: _activitiesScaled(
                                      context,
                                      16,
                                      min: 12,
                                      max: 18,
                                    ),
                                  ),
                                  Container(
                                    height: 1,
                                    decoration: AppBoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          context.activitiesColors.transparent,
                                          context.activitiesColors.primary
                                              .withValues(alpha: 0.16),
                                          context.activitiesColors.primary
                                              .withValues(alpha: 0.12),
                                          context.activitiesColors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (provider.state ==
                                          ActivitiesState.loading &&
                                      discoverItems.isNotEmpty) ...[
                                    SizedBox(
                                      height: _activitiesScaled(
                                        context,
                                        18,
                                        min: 14,
                                        max: 20,
                                      ),
                                    ),
                                    LinearProgressIndicator(
                                      minHeight: 2,
                                      color: context.activitiesColors.primary,
                                      backgroundColor:
                                          context.activitiesColors.transparent,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (provider.state == ActivitiesState.loading &&
                              discoverItems.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: context.activitiesColors.primary,
                                ),
                              ),
                            )
                          else if (provider.state == ActivitiesState.error &&
                              discoverItems.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: AppEdgeInsets.fromLTRB(
                                  layout.horizontalPadding,
                                  12,
                                  layout.horizontalPadding,
                                  0,
                                ),
                                child: ErrorView(
                                  message:
                                      provider.errorMessage ??
                                      l10n.activitiesLoadFailed,
                                  onRetry: () async {
                                    await provider.loadActivities();
                                    if (currentUserId.isNotEmpty) {
                                      await provider.loadMyActivities();
                                    }
                                  },
                                ),
                              ),
                            )
                          else if (discoverItems.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _ActivitiesEmptyView(
                                icon: Icons.explore_rounded,
                                title: l10n.noActivitiesYet,
                                subtitle: l10n.activitiesWillAppearHere,
                              ),
                            )
                          else if (filteredItems.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _ActivitiesEmptyView(
                                icon: Icons.filter_alt_off_rounded,
                                title: l10n.activitiesFilteredEmptyTitle,
                                subtitle: l10n.activitiesFilteredEmptySubtitle,
                              ),
                            )
                          else
                            SliverPadding(
                              padding: AppEdgeInsets.fromLTRB(
                                layout.horizontalPadding,
                                _activitiesScaled(
                                  context,
                                  18,
                                  min: 14,
                                  max: 20,
                                ),
                                layout.horizontalPadding,
                                paginatedItems.hasMultiplePages
                                    ? layout.cardGap
                                    : 140 + safeBottomInset,
                              ),
                              sliver: SliverList.separated(
                                itemCount: paginatedItems.items.length,
                                separatorBuilder: (_, _) =>
                                    SizedBox(height: layout.cardGap),
                                itemBuilder: (context, index) {
                                  final item = paginatedItems.items[index];
                                  final categorySlug =
                                      resolvedActivityCategorySlug(
                                        categories: provider.categoryItems,
                                        slug: item.categorySlug,
                                      );
                                  final categoryLabel =
                                      categoryOptions
                                          .cast<_DiscoverCategoryOption?>()
                                          .firstWhere(
                                            (option) =>
                                                option?.slug == categorySlug,
                                            orElse: () => null,
                                          )
                                          ?.label ??
                                      ActivityCategoryVm.humanizeSlug(
                                        item.categorySlug,
                                      );

                                  return _DiscoverActivityCard(
                                    item: item,
                                    layout: layout,
                                    categoryLabel: categoryLabel,
                                    isOwner:
                                        currentUserId.isNotEmpty &&
                                        currentUserId == item.hostUserId,
                                    onOpenDetails: () =>
                                        _openActivityDetails(context, item.id),
                                  );
                                },
                              ),
                            ),
                          if (filteredItems.isNotEmpty &&
                              paginatedItems.hasMultiplePages)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: AppEdgeInsets.fromLTRB(
                                  layout.horizontalPadding,
                                  0,
                                  layout.horizontalPadding,
                                  140 + safeBottomInset,
                                ),
                                child: InflapPaginationBar(
                                  currentPage: paginatedItems.currentPage,
                                  totalPages: paginatedItems.totalPages,
                                  onPageChanged: _handleDiscoverPageChanged,
                                ),
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
      ),
    );
  }
}

class _ActivitiesResponsiveTextScope extends StatelessWidget {
  const _ActivitiesResponsiveTextScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortSide = mediaQuery.size.shortestSide;
    final baseScale = mediaQuery.textScaler.scale(1);

    double widthScale;
    if (shortSide <= 320) {
      widthScale = 0.9;
    } else if (shortSide <= 360) {
      widthScale = 0.95;
    } else if (shortSide <= 390) {
      widthScale = 0.98;
    } else if (shortSide >= 430) {
      widthScale = 1.04;
    } else {
      widthScale = 1;
    }

    final effectiveScale = (baseScale * widthScale).clamp(0.9, 1.16);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.linear(effectiveScale)),
      child: child,
    );
  }
}

double _activitiesUiScale(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final shortSide = mediaQuery.size.shortestSide;
  final height = mediaQuery.size.height;

  double scale;
  if (shortSide <= 320) {
    scale = 0.88;
  } else if (shortSide <= 360) {
    scale = 0.94;
  } else if (shortSide <= 390) {
    scale = 0.98;
  } else if (shortSide >= 430) {
    scale = 1.04;
  } else {
    scale = 1;
  }

  if (height < 700) {
    scale *= 0.96;
  } else if (height > 920) {
    scale *= 1.02;
  }

  return scale.clamp(0.86, 1.08);
}

double _activitiesScaled(
  BuildContext context,
  double value, {
  double? min,
  double? max,
}) {
  final scaled = value * _activitiesUiScale(context);
  if (min == null && max == null) {
    return scaled;
  }
  return scaled.clamp(min ?? scaled, max ?? scaled);
}

bool _isLightActivitiesTheme(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light;
}

List<BoxShadow>? _activitiesDarkThemeShadow(
  BuildContext context, {
  required double alpha,
  required double blurRadius,
  required Offset offset,
}) {
  if (_isLightActivitiesTheme(context)) {
    return null;
  }

  return [
    BoxShadow(
      color: context.activitiesColors.black.withValues(alpha: alpha),
      blurRadius: blurRadius,
      offset: offset,
    ),
  ];
}

class _DiscoverScreenBackdrop extends StatelessWidget {
  const _DiscoverScreenBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.activitiesColors;
    return ColoredBox(color: colors.background, child: child);
  }
}

class _DiscoverSearchField extends StatelessWidget {
  const _DiscoverSearchField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.activeFilterCount,
    required this.onSubmitted,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final int activeFilterCount;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return AppListSearchField(
      controller: controller,
      focusNode: focusNode,
      hintText: hintText,
      filterTooltip: AppLocalizations.of(context)!.activitiesFiltersTitle,
      activeFilterCount: activeFilterCount,
      showClearButton: true,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      onSubmitted: onSubmitted,
      onFilterTap: onFilterTap,
    );
  }
}

class _DiscoverSortBar extends StatelessWidget {
  const _DiscoverSortBar({
    required this.l10n,
    required this.sortField,
    required this.sortAscending,
    required this.onSortTap,
  });

  final AppLocalizations l10n;
  final _ActivitySortField sortField;
  final bool sortAscending;
  final ValueChanged<_ActivitySortField> onSortTap;

  @override
  Widget build(BuildContext context) {
    return AppInlineSortRow<_ActivitySortField>(
      label: l10n.activitiesSortLabel,
      options: [
        AppInlineSortOption(
          value: _ActivitySortField.date,
          label: l10n.activitiesSortDate,
        ),
        AppInlineSortOption(
          value: _ActivitySortField.price,
          label: l10n.activitiesSortPrice,
        ),
      ],
      selectedValue: sortField,
      isAscending: sortAscending,
      onSelected: onSortTap,
      fontSize: _activitiesScaled(context, 12, min: 11, max: 12),
      iconSize: _activitiesScaled(context, 14, min: 12, max: 14),
      labelToOptionsGap: _activitiesScaled(context, 18, min: 12, max: 18),
      optionGap: _activitiesScaled(context, 22, min: 16, max: 22),
      iconGap: _activitiesScaled(context, 5, min: 4, max: 5),
      verticalPadding: _activitiesScaled(context, 8, min: 6, max: 10),
      activeColor: context.activitiesColors.primary,
    );
  }
}

class _ActivitiesNearbyMapSection extends StatelessWidget {
  const _ActivitiesNearbyMapSection({
    required this.title,
    required this.emptyText,
    required this.markers,
    required this.onTap,
  });

  final String title;
  final String emptyText;
  final List<MapActivityTarget> markers;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = _activitiesScaled(context, 24, min: 20, max: 24);
    final previewHeight = _activitiesScaled(context, 142, min: 118, max: 150);
    final markerSize = _activitiesScaled(context, 30, min: 26, max: 32);
    final previewMarkers = markers.take(10).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: _activitiesScaled(context, 30, min: 28, max: 32),
              height: _activitiesScaled(context, 30, min: 28, max: 32),
              decoration: AppBoxDecoration(
                shape: BoxShape.circle,
                color: context.activitiesColors.secondarySurface,
                border: Border.all(
                  color: context.activitiesColors.secondaryBorder,
                ),
              ),
              child: Icon(
                Icons.near_me_rounded,
                color: context.activitiesColors.secondaryText,
                size: _activitiesScaled(context, 17, min: 15, max: 18),
              ),
            ),
            SizedBox(width: _activitiesScaled(context, 10, min: 8, max: 10)),
            Expanded(
              child: Text(
                title,
                style: AppTextStyle(
                  color: context.activitiesColors.textPrimary,
                  fontSize: _activitiesScaled(context, 18, min: 16, max: 19),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: _activitiesScaled(context, 10, min: 8, max: 10)),
        Material(
          color: context.activitiesColors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppBorderRadius.circular(radius),
            child: Ink(
              height: previewHeight,
              decoration: AppBoxDecoration(
                borderRadius: AppBorderRadius.circular(radius),
                border: Border.all(
                  color: context.activitiesColors.secondaryBorder,
                ),
                boxShadow: _activitiesDarkThemeShadow(
                  context,
                  alpha: 0.24,
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ),
              child: ClipRRect(
                borderRadius: AppBorderRadius.circular(radius),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: _ActivitiesNearbyMapPainter(
                            colors: context.activitiesColors,
                          ),
                          size: size,
                        ),
                        for (var i = 0; i < previewMarkers.length; i++)
                          Positioned(
                            left:
                                _activityPreviewOffset(
                                  marker: previewMarkers[i],
                                  markers: previewMarkers,
                                  index: i,
                                  size: size,
                                ).dx -
                                markerSize / 2,
                            top:
                                _activityPreviewOffset(
                                  marker: previewMarkers[i],
                                  markers: previewMarkers,
                                  index: i,
                                  size: size,
                                ).dy -
                                markerSize / 2,
                            width: markerSize,
                            height: markerSize,
                            child: _ActivityPreviewMarker(
                              marker: previewMarkers[i],
                            ),
                          ),
                        Positioned(
                          left: _activitiesScaled(
                            context,
                            14,
                            min: 12,
                            max: 16,
                          ),
                          right: _activitiesScaled(
                            context,
                            14,
                            min: 12,
                            max: 16,
                          ),
                          bottom: _activitiesScaled(
                            context,
                            12,
                            min: 10,
                            max: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  markers.isEmpty
                                      ? emptyText
                                      : AppLocalizations.of(
                                          context,
                                        )!.activitiesResultsCount(
                                          markers.length,
                                        ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle(
                                    color: context.activitiesColors.textPrimary,
                                    fontSize: _activitiesScaled(
                                      context,
                                      13,
                                      min: 12,
                                      max: 14,
                                    ),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (onTap != null) ...[
                                SizedBox(
                                  width: _activitiesScaled(
                                    context,
                                    10,
                                    min: 8,
                                    max: 10,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: _activitiesScaled(
                                    context,
                                    18,
                                    min: 16,
                                    max: 19,
                                  ),
                                  color: context.activitiesColors.secondaryText,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityPreviewMarker extends StatelessWidget {
  const _ActivityPreviewMarker({required this.marker});

  final MapActivityTarget marker;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        shape: BoxShape.circle,
        color: marker.accentColor,
        border: Border.all(color: context.activitiesColors.white, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: context.activitiesColors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          marker.avatarLabel ?? '',
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: AppTextStyle(
            color: context.activitiesColors.white,
            fontSize: _activitiesScaled(context, 11, min: 9, max: 12),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ActivitiesNearbyMapPainter extends CustomPainter {
  const _ActivitiesNearbyMapPainter({required this.colors});

  final _ActivitiesColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final isLight = colors.isLight;
    final backgroundColors = isLight
        ? [colors.surface, colors.surfaceHigh, colors.secondaryContainer]
        : [
            colors.greenSurface09,
            colors.warmSurfaceHigh09,
            colors.blueSurface10,
          ];
    final parkColor = isLight
        ? colors.secondaryContainer.withValues(alpha: 0.74)
        : colors.secondary.withValues(alpha: 0.16);
    final roadColor = isLight
        ? colors.primaryContainer.withValues(alpha: 0.74)
        : colors.amberLight03.withValues(alpha: 0.46);
    final sideRoadColor = isLight
        ? colors.primaryContainer.withValues(alpha: 0.56)
        : colors.amberSoft04.withValues(alpha: 0.28);

    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: backgroundColors,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final parkPaint = Paint()..color = parkColor;
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.62, -size.height * 0.18, 150, 120),
      parkPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(-size.width * 0.18, size.height * 0.42, 160, 120),
      parkPaint,
    );

    final roadPaint = Paint()
      ..color = roadColor
      ..strokeWidth = math.max(5, size.shortestSide * 0.07)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final road = Path()
      ..moveTo(-20, size.height * 0.72)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.58,
        size.width * 0.36,
        size.height * 0.86,
        size.width * 0.56,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.38,
        size.width * 0.88,
        size.height * 0.44,
        size.width + 20,
        size.height * 0.28,
      );
    canvas.drawPath(road, roadPaint);

    final sideRoadPaint = Paint()
      ..color = sideRoadColor
      ..strokeWidth = math.max(3, size.shortestSide * 0.035)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.18, -12),
      Offset(size.width * 0.48, size.height + 12),
      sideRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, -12),
      Offset(size.width * 0.28, size.height + 12),
      sideRoadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ActivitiesNearbyMapPainter oldDelegate) {
    return oldDelegate.colors.colors != colors.colors;
  }
}

class _DiscoverActivityCard extends StatelessWidget {
  const _DiscoverActivityCard({
    required this.item,
    required this.layout,
    required this.categoryLabel,
    required this.isOwner,
    required this.onOpenDetails,
  });

  final ActivityListItemVm item;
  final _ActivitiesAdaptiveLayout layout;
  final String categoryLabel;
  final bool isOwner;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final colors = context.activitiesColors;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compactMeta =
        MediaQuery.sizeOf(context).width < 360 || textScale > 1.04;
    final artSpec = activityCardArtForItem(item);
    final badgeText = item.isFree ? l10n.createPriceFree : item.priceLabel;
    final visibilityBadge = _visibilityBadge(
      context.activitiesColors,
      item.visibility,
      l10n,
    );
    final dateText = formatEventDateTime(
      item.startAt,
      timezoneId: item.timezone,
      localeName: locale,
    );
    final locationFallbackText = activityLocationFallbackText(item, l10n);
    final metaItems = <_CardMetaData>[
      _CardMetaData(
        icon: Icons.place_outlined,
        label: locationFallbackText,
        labelBuilder: (style) => AppLocalizedLocationText(
          countryCode: item.countryCode,
          cityId: item.cityId,
          cityName: item.cityName,
          fallbackText: locationFallbackText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
      _CardMetaData(
        icon: _formatIcon(item.format),
        label: formatActivityFormat(item.format, l10n),
      ),
      _CardMetaData(icon: Icons.schedule_outlined, label: dateText),
      _CardMetaData(
        icon: Icons.groups_2_outlined,
        label: item.maxParticipants == null
            ? l10n.activityUnlimitedSpots
            : l10n.activityPeopleMax(item.maxParticipants!),
      ),
    ];
    final badgeVertical = _activitiesScaled(context, 7, min: 6, max: 8);
    final badgeHorizontal = _activitiesScaled(context, 12, min: 10, max: 12);
    final badgeIcon = _activitiesScaled(context, 14, min: 12, max: 14);
    final badgeFont = _activitiesScaled(context, 12, min: 11, max: 12);
    final priceFont = _activitiesScaled(context, 13, min: 12, max: 13);
    final avatarSize = _activitiesScaled(context, 38, min: 34, max: 40);
    final avatarIcon = _activitiesScaled(context, 18, min: 16, max: 18);
    final categoryFont = _activitiesScaled(context, 11, min: 10, max: 11);

    return Material(
      color: context.activitiesColors.transparent,
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: AppBorderRadius.circular(layout.cardRadius),
        child: Ink(
          decoration: AppBoxDecoration(
            borderRadius: AppBorderRadius.circular(layout.cardRadius),
            color: context.activitiesColors.activityCardSurface,
            border: Border.all(
              color: context.activitiesColors.activityCardBorder,
            ),
            boxShadow: _activitiesDarkThemeShadow(
              context,
              alpha: 0.26,
              blurRadius: 44,
              offset: const Offset(0, 20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppBorderRadius.vertical(
                  top: AppRadiusValue.circular(layout.cardRadius),
                ),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: layout.coverAspectRatio,
                      child: ActivityDecorativeCover(
                        spec: artSpec,
                        imageUrl: resolveActivityCoverUrl(item),
                      ),
                    ),
                    Positioned(
                      top: _activitiesScaled(context, 14, min: 10, max: 14),
                      left: _activitiesScaled(context, 14, min: 10, max: 14),
                      child: Container(
                        padding: AppEdgeInsets.symmetric(
                          horizontal: badgeHorizontal,
                          vertical: badgeVertical,
                        ),
                        decoration: AppBoxDecoration(
                          color: visibilityBadge.background,
                          borderRadius: AppBorderRadius.circular(999),
                          border: Border.all(color: visibilityBadge.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              visibilityBadge.icon,
                              size: badgeIcon,
                              color: visibilityBadge.foreground,
                            ),
                            SizedBox(
                              width: _activitiesScaled(
                                context,
                                6,
                                min: 4,
                                max: 6,
                              ),
                            ),
                            Text(
                              visibilityBadge.label,
                              style: AppTextStyle(
                                color: visibilityBadge.foreground,
                                fontSize: badgeFont,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: _activitiesScaled(context, 14, min: 10, max: 14),
                      right: _activitiesScaled(context, 14, min: 10, max: 14),
                      child: Container(
                        padding: AppEdgeInsets.symmetric(
                          horizontal: badgeHorizontal,
                          vertical: badgeVertical,
                        ),
                        decoration: AppBoxDecoration(
                          color: item.isFree
                              ? context.activitiesColors.secondarySurface
                              : context.activitiesColors.warmOverlaySurface10,
                          borderRadius: AppBorderRadius.circular(999),
                          border: Border.all(
                            color: item.isFree
                                ? context.activitiesColors.secondaryBorder
                                : context.activitiesColors.transparent,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: AppTextStyle(
                            color: item.isFree
                                ? context.activitiesColors.secondaryText
                                : context.activitiesColors.primary,
                            fontSize: priceFont,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: AppEdgeInsets.fromLTRB(
                  layout.cardPadding,
                  layout.cardPadding - 2,
                  layout.cardPadding,
                  layout.cardPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: _activityCategoryAvatarDecoration(
                            context,
                            artSpec,
                            colors,
                          ),
                          child: Icon(
                            artSpec.icon,
                            color: colors.isLight
                                ? colors.onSecondary
                                : colors.white.withValues(alpha: 0.92),
                            size: avatarIcon,
                          ),
                        ),
                        SizedBox(
                          width: _activitiesScaled(
                            context,
                            10,
                            min: 8,
                            max: 10,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoryLabel.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle(
                                  color: context.activitiesColors.amberSoft16,
                                  fontSize: categoryFont,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: _activitiesScaled(context, 14, min: 10, max: 14),
                    ),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: context.activitiesColors.orangeWash29,
                        fontSize: layout.titleSize,
                        height: 1.16,
                        letterSpacing: -0.4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height: _activitiesScaled(context, 16, min: 12, max: 18),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final gap = _activitiesScaled(
                          context,
                          10,
                          min: 8,
                          max: 10,
                        );
                        final columns = compactMeta ? 1 : 2;
                        final itemWidth =
                            (constraints.maxWidth - gap * (columns - 1)) /
                            columns;

                        return Wrap(
                          spacing: gap,
                          runSpacing: _activitiesScaled(
                            context,
                            12,
                            min: 10,
                            max: 12,
                          ),
                          children: [
                            for (final meta in metaItems)
                              SizedBox(
                                width: itemWidth,
                                child: _CardMetaItem(data: meta),
                              ),
                          ],
                        );
                      },
                    ),
                    SizedBox(
                      height: _activitiesScaled(context, 18, min: 14, max: 18),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _PrimaryPillButton(
                        label: _ctaLabel(l10n),
                        onTap: onOpenDetails,
                        icon: Icons.arrow_forward_rounded,
                        minHeight: layout.ctaHeight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ctaLabel(AppLocalizations l10n) {
    if (isOwner) {
      return l10n.activityViewDetails;
    }
    return l10n.activityJoinSession;
  }
}

AppBoxDecoration _activityCategoryAvatarDecoration(
  BuildContext context,
  ActivityCardArtSpec artSpec,
  _ActivitiesColors colors,
) {
  if (colors.isLight) {
    return AppBoxDecoration(
      shape: BoxShape.circle,
      color: colors.secondary,
      border: Border.all(color: colors.borderSecondary),
    );
  }

  return AppBoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(colors: artSpec.colorsFor(context)),
    border: Border.all(color: colors.white.withValues(alpha: 0.10)),
  );
}

class _VisibilityBadgeStyle {
  const _VisibilityBadgeStyle({
    required this.label,
    required this.icon,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color border;
  final Color foreground;
}

class _CardMetaItem extends StatelessWidget {
  const _CardMetaItem({required this.data});

  final _CardMetaData data;

  @override
  Widget build(BuildContext context) {
    final iconSize = _activitiesScaled(context, 16, min: 14, max: 16);
    final gap = _activitiesScaled(context, 8, min: 6, max: 8);
    final fontSize = _activitiesScaled(context, 13, min: 12, max: 13);
    final labelStyle = AppTextStyle(
      color: context.activitiesColors.secondaryText,
      fontSize: fontSize,
      height: 1.25,
    );

    return Row(
      children: [
        Icon(
          data.icon,
          size: iconSize,
          color: context.activitiesColors.secondaryText,
        ),
        SizedBox(width: gap),
        Expanded(
          child:
              data.labelBuilder?.call(labelStyle) ??
              Text(
                data.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
        ),
      ],
    );
  }
}

class _ActivitiesEmptyView extends StatelessWidget {
  const _ActivitiesEmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final iconWrap = _activitiesScaled(context, 98, min: 82, max: 102);
    final iconSize = _activitiesScaled(context, 40, min: 34, max: 40);
    final titleSize = _activitiesScaled(context, 22, min: 19, max: 23);
    final bodySize = _activitiesScaled(context, 15, min: 14, max: 16);

    return Center(
      child: Padding(
        padding: AppEdgeInsets.symmetric(
          horizontal: _activitiesScaled(context, 28, min: 18, max: 30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconWrap,
              height: iconWrap,
              decoration: AppBoxDecoration(
                shape: BoxShape.circle,
                color: context.activitiesColors.primary.withValues(alpha: 0.10),
                border: Border.all(
                  color: context.activitiesColors.primary.withValues(
                    alpha: 0.22,
                  ),
                ),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: context.activitiesColors.primary,
              ),
            ),
            SizedBox(height: _activitiesScaled(context, 24, min: 18, max: 26)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: context.activitiesColors.textPrimary,
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: _activitiesScaled(context, 10, min: 8, max: 12)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: context.activitiesColors.textSecondary,
                fontSize: bodySize,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverFiltersSheet extends StatefulWidget {
  const _DiscoverFiltersSheet({
    required this.l10n,
    required this.initialFilters,
    required this.categoryOptions,
    required this.previewCountBuilder,
  });

  final AppLocalizations l10n;
  final _DiscoverFilters initialFilters;
  final List<_DiscoverCategoryOption> categoryOptions;
  final int Function(_DiscoverFilters filters) previewCountBuilder;

  @override
  State<_DiscoverFiltersSheet> createState() => _DiscoverFiltersSheetState();
}

class _DiscoverFiltersSheetState extends State<_DiscoverFiltersSheet> {
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late Set<String> _selectedSlugs;
  late Set<String> _selectedVisibilities;
  late AppCountryFilterValue? _selectedCountry;
  late AppCityFilterValue? _selectedCity;
  String? _startError;
  String? _endError;
  bool _controllerUpdateInProgress = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilters;
    _selectedSlugs = Set<String>.from(initial.categorySlugs);
    _selectedVisibilities = Set<String>.from(initial.visibilities);
    _selectedCountry = initial.country;
    _selectedCity = initial.city;
    _minPriceController = TextEditingController(
      text: initial.minPrice?.toStringAsFixed(0) ?? '',
    )..addListener(_handleFieldChanged);
    _maxPriceController = TextEditingController(
      text: initial.maxPrice?.toStringAsFixed(0) ?? '',
    )..addListener(_handleFieldChanged);
    _startDateController = TextEditingController(
      text: initial.startDate == null ? '' : _formatDate(initial.startDate!),
    )..addListener(_handleFieldChanged);
    _endDateController = TextEditingController(
      text: initial.endDate == null ? '' : _formatDate(initial.endDate!),
    )..addListener(_handleFieldChanged);
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _handleFieldChanged() {
    if (mounted && !_controllerUpdateInProgress) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final draftFilters = _draftFilters();
    final count = widget.previewCountBuilder(draftFilters);

    return _RangeSheetScaffold(
      title: widget.l10n.activitiesFiltersTitle,
      maxHeightFactor: 0.9,
      footerPadding: 12,
      applyLabel: widget.l10n.activitiesShowResults(count),
      onClear: _clearAll,
      onApply: _handleApply,
      l10n: widget.l10n,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCountrySection(),
          if (_selectedCountry != null) ...[
            _FilterSectionDivider(),
            _buildCitySection(),
          ],
          _FilterSectionDivider(),
          _buildCategorySection(context),
          _FilterSectionDivider(),
          _buildDateSection(context),
          _FilterSectionDivider(),
          _buildPriceSection(context),
          _FilterSectionDivider(),
          _buildVisibilitySection(context),
        ],
      ),
    );
  }

  Widget _buildCountrySection() {
    return AppCountryFilterSection(
      title: widget.l10n.activitiesFilterCountrySection,
      allCountriesLabel: widget.l10n.activitiesFilterCountryAll,
      searchHint: widget.l10n.activitiesFilterCountrySearchHint,
      noResultsText: widget.l10n.activitiesFilterCountryNoResults,
      selectedCountry: _selectedCountry,
      onChanged: _setCountry,
    );
  }

  Widget _buildCitySection() {
    return AppCityFilterSection(
      title: widget.l10n.locationFilterCitySection,
      allCitiesLabel: widget.l10n.locationFilterAllCities,
      searchHint: widget.l10n.locationFilterCitySearchHint,
      noResultsText: widget.l10n.locationFilterCityNoResults,
      selectedCity: _selectedCity,
      onChanged: _setCity,
      countryCode: _selectedCountry?.countryCode,
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    if (widget.categoryOptions.isEmpty) {
      return _FilterSection(
        icon: Icons.dashboard_customize_outlined,
        title: widget.l10n.activitiesFilterCategory,
        child: Text(
          widget.l10n.activitiesAllCategories,
          style: AppTextStyle(
            color: context.activitiesColors.textSecondary,
            fontSize: _activitiesScaled(context, 14, min: 13, max: 15),
          ),
        ),
      );
    }

    return _FilterSection(
      icon: Icons.dashboard_customize_outlined,
      title: widget.l10n.activitiesFilterCategory,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final spacing = _activitiesScaled(context, 8, min: 6, max: 10);
          final columns = constraints.maxWidth < 340 || textScale > 1.08
              ? 1
              : 2;
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final option in widget.categoryOptions)
                SizedBox(
                  width: itemWidth,
                  child: _CategoryFilterPill(
                    option: option,
                    selected: _selectedSlugs.contains(option.slug),
                    countLabel: widget.l10n.activitiesResultsCount(
                      option.count,
                    ),
                    onTap: () {
                      final selected = _selectedSlugs.contains(option.slug);
                      setState(() {
                        if (selected) {
                          _selectedSlugs.remove(option.slug);
                        } else {
                          _selectedSlugs.add(option.slug);
                        }
                      });
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateSection(BuildContext context) {
    final presets = _buildDatePresets(widget.l10n);

    return _FilterSection(
      icon: Icons.calendar_month_outlined,
      title: widget.l10n.activitiesFilterDate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResponsiveFieldPair(
            context,
            first: _RangeTextField(
              label: widget.l10n.myActivitiesFilterStartDate,
              controller: _startDateController,
              prefix: '',
              hintText: widget.l10n.activitiesFilterStartDatePlaceholder,
              keyboardType: TextInputType.number,
              inputFormatters: const [_DateTextInputFormatter()],
              errorText: _startError,
            ),
            second: _RangeTextField(
              label: widget.l10n.myActivitiesFilterEndDate,
              controller: _endDateController,
              prefix: '',
              hintText: widget.l10n.activitiesFilterEndDatePlaceholder,
              keyboardType: TextInputType.number,
              inputFormatters: const [_DateTextInputFormatter()],
              errorText: _endError,
            ),
          ),
          SizedBox(height: _activitiesScaled(context, 12, min: 10, max: 14)),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final preset in presets)
                _PresetChip(
                  label: preset.label,
                  onTap: () {
                    setState(() {
                      _updateControllers(() {
                        _startDateController.text = _formatDate(
                          preset.startDate,
                        );
                        _endDateController.text = _formatDate(preset.endDate);
                      });
                      _startError = null;
                      _endError = null;
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    final presets = _buildPricePresets(l10n: widget.l10n);

    return _FilterSection(
      icon: Icons.payments_outlined,
      title: widget.l10n.activitiesFilterPricing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResponsiveFieldPair(
            context,
            first: _RangeTextField(
              label: widget.l10n.activitiesFilterMinPrice,
              controller: _minPriceController,
              prefix: '',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [_DecimalTextInputFormatter()],
            ),
            second: _RangeTextField(
              label: widget.l10n.activitiesFilterMaxPrice,
              controller: _maxPriceController,
              prefix: '',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [_DecimalTextInputFormatter()],
            ),
          ),
          SizedBox(height: _activitiesScaled(context, 12, min: 10, max: 14)),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final preset in presets)
                _PresetChip(
                  label: preset.label,
                  onTap: () {
                    setState(() {
                      _updateControllers(() {
                        _minPriceController.text = preset.minPrice == null
                            ? ''
                            : preset.minPrice!.toStringAsFixed(0);
                        _maxPriceController.text = preset.maxPrice == null
                            ? ''
                            : preset.maxPrice!.toStringAsFixed(0);
                      });
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilitySection(BuildContext context) {
    return _FilterSection(
      icon: Icons.public_rounded,
      title: widget.l10n.activitiesFilterVisibility,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useColumn =
              constraints.maxWidth < 360 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.04;
          final options = [
            _VisibilityOptionCard(
              label: widget.l10n.createVisibilityPublic,
              description: widget.l10n.createVisibilityPublicDescription,
              icon: Icons.public_rounded,
              selected: _selectedVisibilities.contains('PUBLIC'),
              onTap: () => _toggleVisibility('PUBLIC'),
            ),
            _VisibilityOptionCard(
              label: widget.l10n.createVisibilityPrivate,
              description: widget.l10n.createVisibilityPrivateDescription,
              icon: Icons.lock_rounded,
              selected: _selectedVisibilities.contains('PRIVATE'),
              onTap: () => _toggleVisibility('PRIVATE'),
            ),
          ];

          if (useColumn) {
            return Column(
              children: [options[0], const SizedBox(height: 14), options[1]],
            );
          }

          return Row(
            children: [
              Expanded(child: options[0]),
              const SizedBox(width: 14),
              Expanded(child: options[1]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResponsiveFieldPair(
    BuildContext context, {
    required Widget first,
    required Widget second,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumn =
            constraints.maxWidth < 360 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.02;
        if (useColumn) {
          return Column(
            children: [
              first,
              SizedBox(height: _activitiesScaled(context, 10, min: 8, max: 12)),
              second,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: first),
            SizedBox(width: _activitiesScaled(context, 10, min: 8, max: 12)),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  void _toggleVisibility(String value) {
    setState(() {
      if (_selectedVisibilities.contains(value)) {
        _selectedVisibilities.remove(value);
      } else {
        _selectedVisibilities.add(value);
      }
    });
  }

  void _setCountry(AppCountryFilterValue? country) {
    setState(() {
      _selectedCountry = country;
      _selectedCity = null;
    });
  }

  void _setCity(AppCityFilterValue? city) {
    setState(() => _selectedCity = city);
  }

  void _clearAll() {
    setState(() {
      _selectedSlugs.clear();
      _selectedVisibilities.clear();
      _selectedCountry = null;
      _selectedCity = null;
      _updateControllers(() {
        _minPriceController.clear();
        _maxPriceController.clear();
        _startDateController.clear();
        _endDateController.clear();
      });
      _startError = null;
      _endError = null;
    });
  }

  void _updateControllers(VoidCallback update) {
    _controllerUpdateInProgress = true;
    try {
      update();
    } finally {
      _controllerUpdateInProgress = false;
    }
  }

  void _handleApply() {
    final startDate = _parseDate(_startDateController.text);
    final endDate = _parseDate(_endDateController.text);

    setState(() {
      _startError = _dateError(
        _startDateController.text,
        startDate,
        widget.l10n.myActivitiesFilterInvalidDate,
      );
      _endError = _dateError(
        _endDateController.text,
        endDate,
        widget.l10n.myActivitiesFilterInvalidDate,
      );

      if (_startError == null &&
          _endError == null &&
          startDate != null &&
          endDate != null &&
          endDate.isBefore(startDate)) {
        _endError = widget.l10n.myActivitiesFilterInvalidRange;
      }
    });

    if (_startError != null || _endError != null) {
      return;
    }

    Navigator.of(context).pop(
      _DiscoverFilters(
        country: _selectedCountry,
        city: _selectedCity,
        categorySlugs: Set<String>.unmodifiable(_selectedSlugs),
        visibilities: Set<String>.unmodifiable(
          _normalizeVisibilitySelection(_selectedVisibilities),
        ),
        startDate: startDate,
        endDate: endDate,
        minPrice: _parseNumeric(_minPriceController.text),
        maxPrice: _parseNumeric(_maxPriceController.text),
      ),
    );
  }

  _DiscoverFilters _draftFilters() {
    return _DiscoverFilters(
      country: _selectedCountry,
      city: _selectedCity,
      categorySlugs: _selectedSlugs,
      visibilities: _normalizeVisibilitySelection(_selectedVisibilities),
      startDate: _parseDate(_startDateController.text),
      endDate: _parseDate(_endDateController.text),
      minPrice: _parseNumeric(_minPriceController.text),
      maxPrice: _parseNumeric(_maxPriceController.text),
    );
  }

  String _formatDate(DateTime value) => DateFormat('dd.MM.yyyy').format(value);
}

class _CategoryFilterPill extends StatelessWidget {
  const _CategoryFilterPill({
    required this.option,
    required this.selected,
    required this.countLabel,
    required this.onTap,
  });

  final _DiscoverCategoryOption option;
  final bool selected;
  final String countLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconWrap = _activitiesScaled(context, 34, min: 30, max: 34);
    final titleSize = _activitiesScaled(context, 13, min: 12, max: 14);
    final countSize = _activitiesScaled(context, 11, min: 10, max: 11);
    final cardBackground = selected
        ? context.activitiesColors.primaryContainer
        : context.activitiesColors.surfaceRaised;
    final cardBorder = selected
        ? context.activitiesColors.primary
        : context.activitiesColors.border;
    final iconBackground = selected
        ? context.activitiesColors.primary.withValues(alpha: 0.16)
        : context.activitiesColors.secondarySurface;
    final iconColor = selected
        ? context.activitiesColors.primary
        : context.activitiesColors.secondaryText;

    return Material(
      color: context.activitiesColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: _activitiesScaled(context, 58, min: 52, max: 60),
          ),
          child: Ink(
            padding: AppEdgeInsets.symmetric(
              horizontal: _activitiesScaled(context, 12, min: 10, max: 12),
              vertical: _activitiesScaled(context, 10, min: 8, max: 10),
            ),
            decoration: AppBoxDecoration(
              borderRadius: AppBorderRadius.circular(18),
              color: cardBackground,
              border: Border.all(color: cardBorder, width: selected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: iconWrap,
                  height: iconWrap,
                  decoration: AppBoxDecoration(
                    borderRadius: AppBorderRadius.circular(12),
                    color: iconBackground,
                    border: Border.all(
                      color: selected
                          ? context.activitiesColors.primary.withValues(
                              alpha: 0.28,
                            )
                          : context.activitiesColors.secondaryBorder,
                    ),
                  ),
                  child: Icon(
                    option.icon,
                    size: _activitiesScaled(context, 17, min: 15, max: 17),
                    color: iconColor,
                  ),
                ),
                SizedBox(
                  width: _activitiesScaled(context, 10, min: 8, max: 10),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: context.activitiesColors.textPrimary,
                          fontSize: titleSize,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(
                        height: _activitiesScaled(context, 3, min: 2, max: 4),
                      ),
                      Text(
                        countLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: selected
                              ? context.activitiesColors.primarySoft
                              : context.activitiesColors.textSecondary,
                          fontSize: countSize,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
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

class _VisibilityOptionCard extends StatelessWidget {
  const _VisibilityOptionCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconWrap = _activitiesScaled(context, 36, min: 32, max: 36);
    final titleSize = _activitiesScaled(context, 14, min: 13, max: 15);
    final bodySize = _activitiesScaled(context, 12, min: 11, max: 12);
    final cardBackground = selected
        ? context.activitiesColors.primaryContainer
        : context.activitiesColors.surfaceRaised;
    final cardBorder = selected
        ? context.activitiesColors.primary
        : context.activitiesColors.border;
    final iconBackground = selected
        ? context.activitiesColors.primary.withValues(alpha: 0.16)
        : context.activitiesColors.secondarySurface;
    final iconColor = selected
        ? context.activitiesColors.primary
        : context.activitiesColors.secondaryText;

    return Material(
      color: context.activitiesColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: _activitiesScaled(context, 76, min: 68, max: 78),
          ),
          child: Ink(
            padding: AppEdgeInsets.symmetric(
              horizontal: _activitiesScaled(context, 14, min: 12, max: 14),
              vertical: _activitiesScaled(context, 12, min: 10, max: 12),
            ),
            decoration: AppBoxDecoration(
              borderRadius: AppBorderRadius.circular(18),
              color: cardBackground,
              border: Border.all(color: cardBorder, width: selected ? 1.5 : 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: iconWrap,
                  height: iconWrap,
                  decoration: AppBoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBackground,
                    border: Border.all(
                      color: selected
                          ? context.activitiesColors.primary.withValues(
                              alpha: 0.28,
                            )
                          : context.activitiesColors.secondaryBorder,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: _activitiesScaled(context, 18, min: 16, max: 18),
                    color: iconColor,
                  ),
                ),
                SizedBox(
                  width: _activitiesScaled(context, 10, min: 8, max: 10),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: context.activitiesColors.textPrimary,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(
                        height: _activitiesScaled(context, 4, min: 3, max: 5),
                      ),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: context.activitiesColors.textSecondary,
                          fontSize: bodySize,
                          height: 1.25,
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

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final iconWrap = _activitiesScaled(context, 30, min: 28, max: 32);
    final titleSize = _activitiesScaled(context, 14, min: 13, max: 15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: iconWrap,
              height: iconWrap,
              decoration: AppBoxDecoration(
                shape: BoxShape.circle,
                color: context.activitiesColors.primary.withValues(alpha: 0.10),
                border: Border.all(
                  color: context.activitiesColors.primary.withValues(
                    alpha: 0.18,
                  ),
                ),
              ),
              child: Icon(
                icon,
                color: context.activitiesColors.primary,
                size: _activitiesScaled(context, 15, min: 14, max: 16),
              ),
            ),
            SizedBox(width: _activitiesScaled(context, 8, min: 7, max: 10)),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  color: context.activitiesColors.textPrimary,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: _activitiesScaled(context, 10, min: 8, max: 12)),
        child,
      ],
    );
  }
}

class _FilterSectionDivider extends StatelessWidget {
  const _FilterSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppEdgeInsets.symmetric(
        vertical: _activitiesScaled(context, 18, min: 14, max: 20),
      ),
      child: Divider(
        height: 1,
        thickness: 1,
        color: context.activitiesColors.white.withValues(alpha: 0.08),
      ),
    );
  }
}

class _FilterSheetHeader extends StatelessWidget {
  const _FilterSheetHeader({
    required this.title,
    required this.clearLabel,
    required this.onClear,
  });

  final String title;
  final String clearLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppFilterSheetHeader(
      title: title,
      clearLabel: clearLabel,
      onClear: onClear,
      height: _activitiesScaled(context, 46, min: 44, max: 50),
      horizontalPadding: _activitiesScaled(context, 18, min: 16, max: 24),
      titleFontSize: _activitiesScaled(context, 16, min: 14, max: 17),
      clearFontSize: _activitiesScaled(context, 12, min: 11, max: 12),
    );
  }
}

class _RangeSheetScaffold extends StatelessWidget {
  const _RangeSheetScaffold({
    required this.title,
    required this.child,
    required this.onClear,
    required this.onApply,
    required this.footerPadding,
    required this.l10n,
    this.maxHeightFactor = 0.82,
    this.applyLabel,
  });

  final String title;
  final Widget child;
  final VoidCallback onClear;
  final VoidCallback onApply;
  final double footerPadding;
  final AppLocalizations l10n;
  final double maxHeightFactor;
  final String? applyLabel;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;
    final horizontalPadding = _activitiesScaled(context, 20, min: 16, max: 22);

    return _ActivitiesResponsiveTextScope(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: AppEdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            color: context.activitiesColors.transparent,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              decoration: AppBoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.activitiesColors.warmSurface21.withValues(
                      alpha: 0.99,
                    ),
                    context.activitiesColors.warmInk63,
                  ],
                ),
                borderRadius: AppBorderRadius.vertical(
                  top: AppRadiusValue.circular(
                    _activitiesScaled(context, 28, min: 24, max: 30),
                  ),
                ),
                border: Border.all(
                  color: context.activitiesColors.white.withValues(alpha: 0.04),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterSheetHeader(
                      title: title,
                      clearLabel: l10n.myActivitiesFilterClear,
                      onClear: onClear,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: AppEdgeInsets.fromLTRB(
                          horizontalPadding,
                          _activitiesScaled(context, 18, min: 14, max: 20),
                          horizontalPadding,
                          0,
                        ),
                        child: child,
                      ),
                    ),
                    Container(
                      margin: AppEdgeInsets.only(
                        top: _activitiesScaled(context, 12, min: 10, max: 14),
                      ),
                      padding: AppEdgeInsets.fromLTRB(
                        horizontalPadding,
                        _activitiesScaled(context, 12, min: 10, max: 14),
                        horizontalPadding,
                        footerPadding,
                      ),
                      decoration: AppBoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: context.activitiesColors.primary.withValues(
                              alpha: 0.09,
                            ),
                          ),
                        ),
                        color: context.activitiesColors.black.withValues(
                          alpha: 0.06,
                        ),
                      ),
                      child: AppFilterApplyButton(
                        label: applyLabel ?? l10n.myActivitiesFilterApply,
                        onTap: onApply,
                        minHeight: _activitiesScaled(
                          context,
                          56,
                          min: 50,
                          max: 58,
                        ),
                        fontSize: _activitiesScaled(
                          context,
                          17,
                          min: 15,
                          max: 17,
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
  }
}

class _RangeTextField extends StatelessWidget {
  const _RangeTextField({
    required this.label,
    required this.controller,
    required this.prefix,
    required this.keyboardType,
    required this.inputFormatters,
    this.hintText,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final String prefix;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final String? hintText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final showPrefix = prefix.isNotEmpty;
    final labelSize = _activitiesScaled(context, 12, min: 11, max: 13);
    final fieldFontSize = _activitiesScaled(context, 16, min: 14, max: 16);
    final verticalPadding = _activitiesScaled(context, 13, min: 11, max: 14);
    final horizontalPadding = _activitiesScaled(context, 14, min: 12, max: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle(
            color: context.activitiesColors.textSecondary,
            fontSize: labelSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: _activitiesScaled(context, 7, min: 6, max: 8)),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          cursorColor: context.activitiesColors.primary,
          style: AppTextStyle(
            color: context.activitiesColors.textPrimary,
            fontSize: fieldFontSize,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          decoration: AppInputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: AppTextStyle(
              color: context.activitiesColors.textMuted,
              fontSize: fieldFontSize,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            errorText: errorText,
            errorMaxLines: 2,
            filled: true,
            fillColor: context.activitiesColors.surfaceRaised,
            contentPadding: AppEdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            prefixIcon: showPrefix
                ? Padding(
                    padding: AppEdgeInsets.only(
                      left: _activitiesScaled(context, 12, min: 10, max: 12),
                      right: _activitiesScaled(context, 2, min: 2, max: 4),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        prefix,
                        style: AppTextStyle(
                          color: context.activitiesColors.primary,
                          fontSize: fieldFontSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            border: OutlineInputBorder(
              borderRadius: AppBorderRadius.circular(16),
              borderSide: BorderSide(color: context.activitiesColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.circular(16),
              borderSide: BorderSide(color: context.activitiesColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.all(AppRadiusValue.circular(16)),
              borderSide: BorderSide(
                color: context.activitiesColors.primary,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.all(AppRadiusValue.circular(16)),
              borderSide: BorderSide(
                color: context.activitiesColors.redSoft04,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.all(AppRadiusValue.circular(16)),
              borderSide: BorderSide(
                color: context.activitiesColors.redSoft04,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final horizontal = _activitiesScaled(context, 14, min: 12, max: 15);
    final vertical = _activitiesScaled(context, 8, min: 7, max: 9);
    final fontSize = _activitiesScaled(context, 12, min: 11, max: 13);

    return Material(
      color: context.activitiesColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(999),
        child: Ink(
          padding: AppEdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
          decoration: AppBoxDecoration(
            borderRadius: AppBorderRadius.circular(999),
            color: context.activitiesColors.surfaceRaised,
            border: Border.all(
              color: context.activitiesColors.primary.withValues(alpha: 0.34),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyle(
              color: context.activitiesColors.textPrimary,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.minHeight = 52,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final fontSize = _activitiesScaled(context, 17, min: 15, max: 17);
    final iconSize = _activitiesScaled(context, 18, min: 16, max: 18);

    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: context.activitiesColors.primary,
        foregroundColor: context.activitiesColors.textPrimary,
        minimumSize: Size(0, minHeight),
        padding: AppEdgeInsets.symmetric(
          horizontal: _activitiesScaled(context, 22, min: 16, max: 22),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.circular(minHeight >= 70 ? 22 : 999),
        ),
        textStyle: AppTextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (icon != null) ...[
            SizedBox(width: _activitiesScaled(context, 8, min: 6, max: 8)),
            Icon(icon, size: iconSize),
          ],
        ],
      ),
    );
  }
}

class _DiscoverFilters {
  static const Object _unset = Object();

  const _DiscoverFilters({
    this.country,
    this.city,
    this.categorySlugs = const {},
    this.visibilities = const {},
    this.startDate,
    this.endDate,
    this.minPrice,
    this.maxPrice,
  });

  final AppCountryFilterValue? country;
  final AppCityFilterValue? city;
  final Set<String> categorySlugs;
  final Set<String> visibilities;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minPrice;
  final double? maxPrice;

  bool get hasDateRange => startDate != null || endDate != null;
  bool get hasPriceRange => minPrice != null || maxPrice != null;
  bool get hasVisibilityFilter => visibilities.isNotEmpty;
  int get activeGroupCount =>
      (country == null ? 0 : 1) +
      (city == null ? 0 : 1) +
      (categorySlugs.isNotEmpty ? 1 : 0) +
      (hasDateRange ? 1 : 0) +
      (hasPriceRange ? 1 : 0) +
      (hasVisibilityFilter ? 1 : 0);
  bool get hasAnyValue =>
      categorySlugs.isNotEmpty ||
      country != null ||
      city != null ||
      hasVisibilityFilter ||
      hasDateRange ||
      hasPriceRange;

  _DiscoverFilters copyWith({
    Object? country = _unset,
    Object? city = _unset,
    Set<String>? categorySlugs,
    Set<String>? visibilities,
    Object? startDate = _unset,
    Object? endDate = _unset,
    Object? minPrice = _unset,
    Object? maxPrice = _unset,
  }) {
    return _DiscoverFilters(
      country: identical(country, _unset)
          ? this.country
          : country as AppCountryFilterValue?,
      city: identical(city, _unset) ? this.city : city as AppCityFilterValue?,
      categorySlugs: categorySlugs ?? this.categorySlugs,
      visibilities: visibilities ?? this.visibilities,
      startDate: identical(startDate, _unset)
          ? this.startDate
          : startDate as DateTime?,
      endDate: identical(endDate, _unset) ? this.endDate : endDate as DateTime?,
      minPrice: identical(minPrice, _unset)
          ? this.minPrice
          : minPrice as double?,
      maxPrice: identical(maxPrice, _unset)
          ? this.maxPrice
          : maxPrice as double?,
    );
  }
}

class _DiscoverCategoryOption {
  const _DiscoverCategoryOption({
    required this.slug,
    required this.label,
    required this.icon,
    required this.colors,
    required this.count,
  });

  final String slug;
  final String label;
  final IconData icon;
  final List<Color> colors;
  final int count;
}

class _CardMetaData {
  const _CardMetaData({
    required this.icon,
    required this.label,
    this.labelBuilder,
  });

  final IconData icon;
  final String label;
  final Widget Function(TextStyle style)? labelBuilder;
}

class _ActivitiesAdaptiveLayout {
  const _ActivitiesAdaptiveLayout._(this.width);

  final double width;

  static _ActivitiesAdaptiveLayout of(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width, 460.0);
    return _ActivitiesAdaptiveLayout._(width);
  }

  bool get isCompact => width < 360;
  double get uiScale {
    if (width <= 320) {
      return 0.88;
    }
    if (width <= 360) {
      return 0.94;
    }
    if (width <= 390) {
      return 0.98;
    }
    if (width >= 430) {
      return 1.04;
    }
    return 1;
  }

  double scaled(double value, {double? min, double? max}) {
    final scaledValue = value * uiScale;
    if (min == null && max == null) {
      return scaledValue;
    }
    return scaledValue.clamp(min ?? scaledValue, max ?? scaledValue);
  }

  double get horizontalPadding => scaled(isCompact ? 14 : 18, min: 14, max: 18);
  double get topPadding => scaled(isCompact ? 14 : 16, min: 12, max: 16);
  double get sectionGap => scaled(isCompact ? 14 : 16, min: 12, max: 16);
  double get filterGap => scaled(isCompact ? 14 : 16, min: 12, max: 16);
  double get cardGap => scaled(isCompact ? 18 : 22, min: 16, max: 22);
  double get cardRadius => scaled(isCompact ? 28 : 34, min: 24, max: 34);
  double get cardPadding => scaled(isCompact ? 16 : 18, min: 14, max: 18);
  double get topBarTitleSize => scaled(isCompact ? 18 : 20, min: 17, max: 20);
  double get titleSize => scaled(isCompact ? 20 : 22, min: 18, max: 22);
  double get ctaHeight => scaled(isCompact ? 48 : 52, min: 46, max: 54);
  double get coverAspectRatio => isCompact ? 1.46 : 1.55;
}

class _PricePreset {
  const _PricePreset({
    required this.label,
    required this.minPrice,
    required this.maxPrice,
  });

  final String label;
  final double? minPrice;
  final double? maxPrice;
}

class _DatePreset {
  const _DatePreset({
    required this.label,
    required this.startDate,
    required this.endDate,
  });

  final String label;
  final DateTime startDate;
  final DateTime endDate;
}

class _DecimalTextInputFormatter extends TextInputFormatter {
  const _DecimalTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (!RegExp(r'^[0-9]*([.,][0-9]{0,2})?$').hasMatch(text)) {
      return oldValue;
    }
    return newValue;
  }
}

class _DateTextInputFormatter extends TextInputFormatter {
  const _DateTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final clampedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < clampedDigits.length; i++) {
      buffer.write(clampedDigits[i]);
      if ((i == 1 || i == 3) && i != clampedDigits.length - 1) {
        buffer.write('.');
      }
    }

    final formatted = buffer.toString();
    final digitsBeforeSelection = newValue.selection.end <= 0
        ? 0
        : newValue.text
              .substring(0, newValue.selection.end)
              .replaceAll(RegExp(r'[^0-9]'), '')
              .length;

    var selectionOffset = 0;
    var seenDigits = 0;
    while (selectionOffset < formatted.length &&
        seenDigits < digitsBeforeSelection) {
      if (RegExp(r'[0-9]').hasMatch(formatted[selectionOffset])) {
        seenDigits++;
      }
      selectionOffset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}

List<ActivityListItemVm> _mergePublishedActivities({
  required List<ActivityListItemVm> publicItems,
  required List<ActivityListItemVm> hostedItems,
  required String? currentUserId,
}) {
  final itemsById = <String, ActivityListItemVm>{};

  for (final item in publicItems) {
    if (!_isDiscoverListStatus(item.status) ||
        !_isDiscoverRegistrationOpen(item) ||
        !_isDiscoverVisibility(item.visibility)) {
      continue;
    }
    itemsById[item.id] = item;
  }

  final normalizedUserId = (currentUserId ?? '').trim();
  if (normalizedUserId.isNotEmpty) {
    for (final item in hostedItems) {
      if (item.hostUserId != normalizedUserId) {
        continue;
      }
      if (!_isDiscoverListStatus(item.status) ||
          !_isDiscoverRegistrationOpen(item) ||
          !_isDiscoverVisibility(item.visibility)) {
        continue;
      }
      itemsById[item.id] = item;
    }
  }

  final merged = itemsById.values.toList()
    ..sort((a, b) => a.startAt.compareTo(b.startAt));
  return merged;
}

List<MapActivityTarget> _buildActivityMapTargets(
  List<ActivityListItemVm> items, {
  required BuildContext context,
  required List<ActivityCategoryVm> categories,
  required List<_DiscoverCategoryOption> categoryOptions,
  required AppLocalizations l10n,
  required String localeName,
}) {
  final targets = <MapActivityTarget>[];

  for (final item in items) {
    if (!_hasUsableActivityCoordinates(item)) {
      continue;
    }

    final categoryLabel = _activityCategoryLabel(
      item: item,
      categories: categories,
      categoryOptions: categoryOptions,
    );
    final artSpec = activityCardArtForItem(item);
    final dateLabel = formatEventDateTime(
      item.startAt,
      timezoneId: item.timezone,
      localeName: localeName,
    );
    final priceLabel = item.isFree
        ? l10n.createPriceFree
        : item.formattedPriceLabel(localeName);

    targets.add(
      MapActivityTarget(
        id: item.id,
        title: item.title,
        latitude: item.latitude!,
        longitude: item.longitude!,
        detailRoute: '/activities/${Uri.encodeComponent(item.id)}',
        categoryLabel: categoryLabel,
        metaLabel: '$categoryLabel · $dateLabel · $priceLabel',
        startLabel: dateLabel,
        priceLabel: priceLabel,
        avatarLabel: _activityAvatarLabel(item.title),
        icon: artSpec.icon,
        accentColor: artSpec.colorsFor(context).last,
      ),
    );

    if (targets.length >= 60) {
      break;
    }
  }

  return targets;
}

bool _hasUsableActivityCoordinates(ActivityListItemVm item) {
  final latitude = item.latitude;
  final longitude = item.longitude;
  if (latitude == null || longitude == null) {
    return false;
  }
  return latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      (latitude != 0 || longitude != 0);
}

String _activityCategoryLabel({
  required ActivityListItemVm item,
  required List<ActivityCategoryVm> categories,
  required List<_DiscoverCategoryOption> categoryOptions,
}) {
  final categorySlug = resolvedActivityCategorySlug(
    categories: categories,
    slug: item.categorySlug,
  );
  return categoryOptions
          .cast<_DiscoverCategoryOption?>()
          .firstWhere(
            (option) => option?.slug == categorySlug,
            orElse: () => null,
          )
          ?.label ??
      ActivityCategoryVm.humanizeSlug(item.categorySlug);
}

String? _activityAvatarLabel(String title) {
  final normalized = title.trim();
  if (normalized.isEmpty) {
    return null;
  }
  return normalized.substring(0, 1).toUpperCase();
}

Offset _activityPreviewOffset({
  required MapActivityTarget marker,
  required List<MapActivityTarget> markers,
  required int index,
  required Size size,
}) {
  if (markers.length == 1) {
    return Offset(size.width * 0.5, size.height * 0.46);
  }

  var minLat = markers.first.latitude;
  var maxLat = markers.first.latitude;
  var minLon = markers.first.longitude;
  var maxLon = markers.first.longitude;

  for (final item in markers.skip(1)) {
    minLat = math.min(minLat, item.latitude);
    maxLat = math.max(maxLat, item.latitude);
    minLon = math.min(minLon, item.longitude);
    maxLon = math.max(maxLon, item.longitude);
  }

  final latSpread = maxLat - minLat;
  final lonSpread = maxLon - minLon;
  final fallbackAngle = (index / math.max(1, markers.length)) * math.pi * 2;
  final normalizedX = lonSpread.abs() < 0.00001
      ? 0.5 + math.cos(fallbackAngle) * 0.22
      : (marker.longitude - minLon) / lonSpread;
  final normalizedY = latSpread.abs() < 0.00001
      ? 0.5 + math.sin(fallbackAngle) * 0.18
      : 1 - ((marker.latitude - minLat) / latSpread);

  final horizontalPadding = size.width * 0.16;
  final verticalPadding = size.height * 0.22;
  return Offset(
    horizontalPadding +
        normalizedX.clamp(0.0, 1.0) * (size.width - horizontalPadding * 2),
    verticalPadding +
        normalizedY.clamp(0.0, 1.0) * (size.height - verticalPadding * 2),
  );
}

bool _isDiscoverVisibility(String visibility) {
  switch (visibility.toUpperCase()) {
    case 'PUBLIC':
    case 'PRIVATE':
      return true;
    default:
      return false;
  }
}

Set<String> _normalizeVisibilitySelection(Set<String> values) {
  final normalized = values
      .map((value) => value.trim().toUpperCase())
      .where((value) => value == 'PUBLIC' || value == 'PRIVATE')
      .toSet();

  if (normalized.isEmpty || normalized.length == 2) {
    return <String>{};
  }

  return normalized;
}

_VisibilityBadgeStyle _visibilityBadge(
  _ActivitiesColors colors,
  String visibility,
  AppLocalizations l10n,
) {
  final readableBackground = colors.isLight
      ? colors.white.withValues(alpha: 0.92)
      : colors.surfaceRaised.withValues(alpha: 0.88);
  final readableBorder = colors.isLight
      ? colors.borderSoft
      : colors.white.withValues(alpha: 0.14);

  switch (visibility.toUpperCase()) {
    case 'PRIVATE':
      return _VisibilityBadgeStyle(
        label: l10n.createVisibilityPrivate,
        icon: Icons.lock_rounded,
        background: readableBackground,
        border: colors.primary.withValues(alpha: 0.26),
        foreground: colors.textPrimary,
      );
    default:
      return _VisibilityBadgeStyle(
        label: l10n.createVisibilityPublic,
        icon: Icons.public_rounded,
        background: readableBackground,
        border: readableBorder,
        foreground: colors.textPrimary,
      );
  }
}

bool _isDiscoverListStatus(String status) {
  switch (status.toUpperCase()) {
    case 'PUBLISHED':
    case 'ENROLLMENT_OPEN':
      return true;
    default:
      return false;
  }
}

bool _isDiscoverRegistrationOpen(ActivityListItemVm item) {
  final now = DateTime.now().toUtc();
  final closesAt = (item.registrationDeadline ?? item.startAt).toUtc();
  return now.isBefore(closesAt);
}

List<_DiscoverCategoryOption> _buildCategoryOptions(
  BuildContext context,
  List<ActivityCategoryVm> categories,
  List<ActivityListItemVm> items,
  String languageCode,
  AppLocalizations l10n,
) {
  final slugs = <String>{
    for (final category in categories)
      if (category.slug.trim().isNotEmpty) category.slug.trim().toLowerCase(),
    for (final item in items)
      if (resolvedActivityCategorySlug(
        categories: categories,
        slug: item.categorySlug,
      ).isNotEmpty)
        resolvedActivityCategorySlug(
          categories: categories,
          slug: item.categorySlug,
        ),
  }.toList();

  slugs.sort();

  final counts = <String, int>{};
  for (final item in items) {
    final slug = resolvedActivityCategorySlug(
      categories: categories,
      slug: item.categorySlug,
    );
    if (slug.isEmpty) {
      continue;
    }
    counts[slug] = (counts[slug] ?? 0) + 1;
  }

  final options = <_DiscoverCategoryOption>[];
  for (final slug in slugs) {
    final matchedCategory = findActivityCategoryBySlug(
      categories: categories,
      slug: slug,
    );

    final visual = activityCategoryVisual(slug);
    options.add(
      _DiscoverCategoryOption(
        slug: slug,
        label:
            matchedCategory?.localizedName(languageCode).trim().isNotEmpty ==
                true
            ? matchedCategory!.localizedName(languageCode)
            : ActivityCategoryVm.humanizeSlug(slug),
        icon: visual.icon,
        colors: visual.colorsFor(context),
        count: counts[slug] ?? 0,
      ),
    );
  }

  options.sort((a, b) {
    final countCompare = b.count.compareTo(a.count);
    if (countCompare != 0) {
      return countCompare;
    }
    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  });

  return options;
}

List<ActivityListItemVm> _applyDiscoverFilters(
  List<ActivityListItemVm> items, {
  required _DiscoverFilters filters,
  required String searchQuery,
  required List<ActivityCategoryVm> categories,
  required Map<String, String> categoryLabelsBySlug,
}) {
  final normalizedQuery = searchQuery.trim().toLowerCase();
  final filtered = items.where((item) {
    final slug = resolvedActivityCategorySlug(
      categories: categories,
      slug: item.categorySlug,
    );
    final visibility = item.visibility.toUpperCase();

    if (filters.categorySlugs.isNotEmpty &&
        !filters.categorySlugs.contains(slug)) {
      return false;
    }

    if (filters.visibilities.isNotEmpty &&
        !filters.visibilities.contains(visibility)) {
      return false;
    }

    if (filters.country != null &&
        !filters.country!.matches(countryCode: item.countryCode)) {
      return false;
    }

    if (filters.city != null &&
        !filters.city!.matches(
          cityId: item.cityId,
          cityName: item.cityName,
          countryCode: item.countryCode,
        )) {
      return false;
    }

    if (filters.startDate != null) {
      final startBoundary = DateTime(
        filters.startDate!.year,
        filters.startDate!.month,
        filters.startDate!.day,
      );
      if (eventDateOnly(item.startAt, item.timezone).isBefore(startBoundary)) {
        return false;
      }
    }

    if (filters.endDate != null) {
      final endBoundary = DateTime(
        filters.endDate!.year,
        filters.endDate!.month,
        filters.endDate!.day,
        23,
        59,
        59,
        999,
      );
      if (eventDateOnly(item.startAt, item.timezone).isAfter(endBoundary)) {
        return false;
      }
    }

    final priceValue = _numericPrice(item);
    if (filters.minPrice != null && priceValue < filters.minPrice!) {
      return false;
    }
    if (filters.maxPrice != null && priceValue > filters.maxPrice!) {
      return false;
    }

    if (normalizedQuery.isEmpty) {
      return true;
    }

    final haystack = [
      item.title,
      item.description,
      item.shortLocation,
      categoryLabelsBySlug[slug] ?? '',
      item.tags.join(' '),
    ].join(' ').toLowerCase();

    return haystack.contains(normalizedQuery);
  }).toList();

  return filtered;
}

List<ActivityListItemVm> _sortDiscoverItems(
  List<ActivityListItemVm> items, {
  required _ActivitySortField sortField,
  required bool sortAscending,
}) {
  final sorted = List<ActivityListItemVm>.from(items);
  sorted.sort((a, b) {
    final primaryCompare = switch (sortField) {
      _ActivitySortField.date => a.startAt.compareTo(b.startAt),
      _ActivitySortField.price => _numericPrice(a).compareTo(_numericPrice(b)),
    };

    final compare = primaryCompare == 0
        ? a.startAt.compareTo(b.startAt)
        : primaryCompare;
    return sortAscending ? compare : -compare;
  });
  return sorted;
}

double _numericPrice(ActivityListItemVm item) {
  if (item.isFree) {
    return 0;
  }
  return item.priceAmount ?? 0;
}

IconData _formatIcon(String format) {
  switch (format.toUpperCase()) {
    case 'ONLINE':
      return Icons.videocam_outlined;
    case 'HYBRID':
      return Icons.devices_outlined;
    default:
      return Icons.location_on_outlined;
  }
}

List<_PricePreset> _buildPricePresets({required AppLocalizations l10n}) {
  return [_PricePreset(label: l10n.createPriceFree, minPrice: 0, maxPrice: 0)];
}

List<_DatePreset> _buildDatePresets(AppLocalizations l10n) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final weekEnd = today.add(
    Duration(days: DateTime.daysPerWeek - today.weekday),
  );
  final weekendStart = today.add(
    Duration(days: (DateTime.saturday - today.weekday) % 7),
  );
  final weekendEnd = weekendStart.add(const Duration(days: 1));
  final monthEnd = DateTime(now.year, now.month + 1, 0);

  return [
    _DatePreset(
      label: l10n.activitiesDatePresetToday,
      startDate: today,
      endDate: today,
    ),
    _DatePreset(
      label: l10n.activitiesDatePresetTomorrow,
      startDate: tomorrow,
      endDate: tomorrow,
    ),
    _DatePreset(
      label: l10n.activitiesDatePresetThisWeekend,
      startDate: weekendStart,
      endDate: weekendEnd,
    ),
    _DatePreset(
      label: l10n.activitiesDatePresetThisWeek,
      startDate: today,
      endDate: weekEnd,
    ),
    _DatePreset(
      label: l10n.activitiesDatePresetThisMonth,
      startDate: today,
      endDate: monthEnd,
    ),
  ];
}

double? _parseNumeric(String raw) {
  final normalized = raw.trim().replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}

DateTime? _parseDate(String raw) {
  final normalized = raw.trim();
  if (normalized.isEmpty || normalized.length != 10) {
    return null;
  }

  final parts = normalized.split('.');
  if (parts.length != 3) {
    return null;
  }

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) {
    return null;
  }

  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }

  return parsed;
}

String? _dateError(String raw, DateTime? parsed, String invalidDateMessage) {
  final normalized = raw.trim();
  if (normalized.isEmpty) {
    return null;
  }
  if (normalized.length != 10 || parsed == null) {
    return invalidDateMessage;
  }
  return null;
}
