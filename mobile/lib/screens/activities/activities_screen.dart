import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_inline_sort_row.dart';
import '../../core/ui/app_list_search_field.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../core/ui/pagination_bar.dart';
import '../../core/utils/pagination.dart';
import '../../features/activities/activity_category_art.dart';
import '../../features/activities/activity_cover_url.dart';
import '../../features/activities/activity_formatters.dart';
import '../../features/activities/activity_taxonomy_resolver.dart';
import '../../features/activities/models/activity_category_vm.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/profile/data/guide_api.dart';
import '../../features/profile/profile_completion_gate.dart';
import '../../features/profile/profile_guard_result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../shared/widgets/app_localized_location_text.dart';
import '../common/app_side_drawer.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ActivityProvider>();
      provider.loadActivities();
      provider.loadActivityCategories();
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

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.logoutDialogTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l10n.logoutDialogMessage,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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

  Future<void> _showLanguageSheet() {
    return showAppLanguageSheet(context);
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

    final result = await showModalBottomSheet<_DiscoverFilters>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    final isLoggedIn = auth.state == AuthState.authenticated;
    final profile = session.profile;
    final currentUserId = (profile?.userId ?? '').trim();
    final location = resolveDrawerLocation(
      profile,
      Localizations.localeOf(context),
    );

    _ensureHostedActivitiesLoaded(currentUserId);
    _ensureGuideBadgeState(currentUserId);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF1A1008),
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: 28,
      drawerScrimColor: Colors.black.withValues(alpha: 0.42),
      drawer: AppSideDrawer(
        l10n: l10n,
        isLoggedIn: isLoggedIn,
        showGuideBadge: _showGuideBadge,
        profile: profile,
        location: location,
        languageLabel: resolveDrawerLanguageLabel(
          Localizations.localeOf(context).languageCode,
        ),
        activeItem: AppDrawerActiveItem.none,
        onProfileTap: () => _runDrawerAction(() async => _openProfile()),
        onLanguageTap: () => _runDrawerAction(_showLanguageSheet),
        onHomeTap: () => _runDrawerAction(() async => context.go('/')),
        onMyActivitiesTap: () => _runDrawerAction(_openMyActivities),
        onMyExcursionsTap: () =>
            _runDrawerAction(() async => context.push('/me/excursions')),
        onMyStoriesTap: () =>
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
                      color: AppColors.accent,
                      backgroundColor: const Color(0xFF201208),
                      onRefresh: () => _refreshActivities(currentUserId),
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
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
                                  _DiscoverSearchField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    hintText: l10n.activitiesSearchHint,
                                    activeFilterCount:
                                        _filters.activeGroupCount,
                                    onFilterTap: () => _openDiscoverFilters(
                                      context,
                                      provider.categoryItems,
                                      categoryOptions,
                                      discoverItems,
                                      categoryLabelsBySlug,
                                    ),
                                  ),
                                  SizedBox(height: layout.filterGap),
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
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          AppColors.accent.withValues(
                                            alpha: 0.16,
                                          ),
                                          AppColors.accent.withValues(
                                            alpha: 0.12,
                                          ),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty ||
                                      _filters.hasAnyValue) ...[
                                    SizedBox(
                                      height: _activitiesScaled(
                                        context,
                                        14,
                                        min: 10,
                                        max: 16,
                                      ),
                                    ),
                                    _FiltersSummaryBar(
                                      l10n: l10n,
                                      count: filteredItems.length,
                                      onClear: () {
                                        _searchController.clear();
                                        setState(() {
                                          _filters = const _DiscoverFilters();
                                          _currentPage = 1;
                                        });
                                      },
                                    ),
                                  ],
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
                                    const LinearProgressIndicator(
                                      minHeight: 2,
                                      color: AppColors.accent,
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (provider.state == ActivitiesState.loading &&
                              discoverItems.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.accent,
                                ),
                              ),
                            )
                          else if (provider.state == ActivitiesState.error &&
                              discoverItems.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
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
                                actionLabel: l10n.myActivitiesFilterClear,
                                onActionTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _filters = const _DiscoverFilters();
                                    _currentPage = 1;
                                  });
                                },
                              ),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
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
                                separatorBuilder: (_, __) =>
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
                                padding: EdgeInsets.fromLTRB(
                                  layout.horizontalPadding,
                                  0,
                                  layout.horizontalPadding,
                                  140 + safeBottomInset,
                                ),
                                child: FlyfyPaginationBar(
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

class _DiscoverScreenBackdrop extends StatelessWidget {
  const _DiscoverScreenBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final topGlowHeight = _activitiesScaled(context, 344, min: 260, max: 360);
    final topGlowInset = _activitiesScaled(context, 44, min: 24, max: 52);
    final sideGlowSize = _activitiesScaled(context, 256, min: 180, max: 272);
    final bottomGlowHeight = _activitiesScaled(
      context,
      284,
      min: 220,
      max: 300,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF281A10), Color(0xFF1C120A), Color(0xFF140B06)],
            ),
          ),
        ),
        Positioned(
          top: -_activitiesScaled(context, 144, min: 100, max: 150),
          left: -topGlowInset,
          right: -topGlowInset,
          child: IgnorePointer(
            child: SizedBox(
              height: topGlowHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.72),
                    radius: 0.94,
                    colors: [Color(0x4FFFAD42), Color(0x00FFAD42)],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: _activitiesScaled(context, 92, min: 64, max: 100),
          right: -_activitiesScaled(context, 92, min: 60, max: 98),
          child: IgnorePointer(
            child: SizedBox(
              width: sideGlowSize,
              height: sideGlowSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.08,
                    colors: [Color(0x24FF9326), Color(0x00FF9326)],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: -_activitiesScaled(context, 68, min: 42, max: 76),
          right: -_activitiesScaled(context, 68, min: 42, max: 76),
          bottom: -_activitiesScaled(context, 124, min: 92, max: 132),
          child: IgnorePointer(
            child: SizedBox(
              height: bottomGlowHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, 1.08),
                    radius: 1.04,
                    colors: [Color(0x18FFB24B), Color(0x00FFB24B)],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.58, 1],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.16),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _DiscoverSearchField extends StatelessWidget {
  const _DiscoverSearchField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.activeFilterCount,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final int activeFilterCount;
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
    );
  }
}

class _FiltersSummaryBar extends StatelessWidget {
  const _FiltersSummaryBar({
    required this.l10n,
    required this.count,
    required this.onClear,
  });

  final AppLocalizations l10n;
  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.02;

    final summaryText = Text(
      l10n.activitiesResultsCount(count),
      style: TextStyle(
        color: const Color(0xCCFFF0E0),
        fontSize: _activitiesScaled(context, 13, min: 12, max: 13),
        fontWeight: FontWeight.w600,
      ),
    );

    final clearButton = TextButton(
      onPressed: onClear,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        padding: EdgeInsets.symmetric(
          horizontal: _activitiesScaled(context, 12, min: 10, max: 12),
          vertical: _activitiesScaled(context, 8, min: 7, max: 9),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text(l10n.myActivitiesFilterClear),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          summaryText,
          SizedBox(height: _activitiesScaled(context, 8, min: 6, max: 10)),
          Align(alignment: Alignment.centerLeft, child: clearButton),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: summaryText),
        clearButton,
      ],
    );
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compactMeta =
        MediaQuery.sizeOf(context).width < 360 || textScale > 1.04;
    final artSpec = activityCardArtForItem(item);
    final badgeText = item.isFree ? l10n.createPriceFree : item.priceLabel;
    final visibilityBadge = _visibilityBadge(item.visibility, l10n);
    final dateText = DateFormat.MMMd(
      locale,
    ).add_Hm().format(item.startAt.toLocal());
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.cardRadius),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF3A220F).withValues(alpha: 0.98),
                const Color(0xFF251408).withValues(alpha: 0.99),
              ],
            ),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.26),
                blurRadius: 44,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(layout.cardRadius),
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
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: _activitiesScaled(context, 14, min: 10, max: 14),
                      left: _activitiesScaled(context, 14, min: 10, max: 14),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: badgeHorizontal,
                          vertical: badgeVertical,
                        ),
                        decoration: BoxDecoration(
                          color: visibilityBadge.background,
                          borderRadius: BorderRadius.circular(999),
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
                              style: TextStyle(
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
                        padding: EdgeInsets.symmetric(
                          horizontal: badgeHorizontal,
                          vertical: badgeVertical,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC46362A),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: item.isFree
                                ? AppColors.success
                                : AppColors.accent,
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
                padding: EdgeInsets.fromLTRB(
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
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: artSpec.colors),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Icon(
                            artSpec.icon,
                            color: Colors.white.withValues(alpha: 0.92),
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
                                style: TextStyle(
                                  color: Color(0xFFFFB64D),
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
                      style: TextStyle(
                        color: const Color(0xFFFFFAF5),
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
    final labelStyle = TextStyle(
      color: Color(0xA8FFF0E0),
      fontSize: fontSize,
      height: 1.25,
    );

    return Row(
      children: [
        Icon(data.icon, size: iconSize, color: const Color(0xB0FFF0E0)),
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
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final iconWrap = _activitiesScaled(context, 98, min: 82, max: 102);
    final iconSize = _activitiesScaled(context, 40, min: 34, max: 40);
    final titleSize = _activitiesScaled(context, 22, min: 19, max: 23);
    final bodySize = _activitiesScaled(context, 15, min: 14, max: 16);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _activitiesScaled(context, 28, min: 18, max: 30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconWrap,
              height: iconWrap,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.22),
                ),
              ),
              child: Icon(icon, size: iconSize, color: AppColors.accent),
            ),
            SizedBox(height: _activitiesScaled(context, 24, min: 18, max: 26)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: _activitiesScaled(context, 10, min: 8, max: 12)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xB3FFF0E0),
                fontSize: bodySize,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onActionTap != null) ...[
              SizedBox(
                height: _activitiesScaled(context, 22, min: 16, max: 24),
              ),
              _PrimaryPillButton(
                label: actionLabel!,
                onTap: onActionTap!,
                icon: Icons.restart_alt_rounded,
                minHeight: 50,
              ),
            ],
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
  String? _startError;
  String? _endError;
  bool _controllerUpdateInProgress = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilters;
    _selectedSlugs = Set<String>.from(initial.categorySlugs);
    _selectedVisibilities = Set<String>.from(initial.visibilities);
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
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final draftFilters = _draftFilters();
    final count = widget.previewCountBuilder(draftFilters);

    return _RangeSheetScaffold(
      title: widget.l10n.activitiesFiltersTitle,
      maxHeightFactor: 0.9,
      footerPadding: 18 + safeBottomInset,
      applyLabel: widget.l10n.activitiesShowResults(count),
      onClear: _clearAll,
      onApply: _handleApply,
      l10n: widget.l10n,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  Widget _buildCategorySection(BuildContext context) {
    if (widget.categoryOptions.isEmpty) {
      return _FilterSection(
        icon: Icons.dashboard_customize_outlined,
        title: widget.l10n.activitiesFilterCategory,
        child: Text(
          widget.l10n.activitiesAllCategories,
          style: TextStyle(
            color: const Color(0xB3FFF0E0),
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

  void _clearAll() {
    setState(() {
      _selectedSlugs.clear();
      _selectedVisibilities.clear();
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
    final foreground = selected
        ? const Color(0xFFFFFAF5)
        : const Color(0xE6FFF0E0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: _activitiesScaled(context, 58, min: 52, max: 60),
          ),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: _activitiesScaled(context, 12, min: 10, max: 12),
              vertical: _activitiesScaled(context, 10, min: 8, max: 10),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? AppColors.accent
                    : Colors.white.withValues(alpha: 0.08),
                width: selected ? 1.5 : 1.0,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? [
                        option.colors.first.withValues(alpha: 0.42),
                        option.colors.last.withValues(alpha: 0.24),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.03),
                        Colors.white.withValues(alpha: 0.015),
                      ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: iconWrap,
                  height: iconWrap,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: selected
                        ? AppColors.accent.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.04),
                  ),
                  child: Icon(
                    option.icon,
                    size: _activitiesScaled(context, 17, min: 15, max: 17),
                    color: selected ? AppColors.accent : foreground,
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
                        style: TextStyle(
                          color: foreground,
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
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFFFFC56A)
                              : const Color(0x8FFFF7EF),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: _activitiesScaled(context, 76, min: 68, max: 78),
          ),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: _activitiesScaled(context, 14, min: 12, max: 14),
              vertical: _activitiesScaled(context, 12, min: 10, max: 12),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accent.withValues(alpha: 0.26),
                        AppColors.accent.withValues(alpha: 0.12),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.03),
                        Colors.white.withValues(alpha: 0.015),
                      ],
                    ),
              border: Border.all(
                color: selected
                    ? AppColors.accent
                    : AppColors.accent.withValues(alpha: 0.18),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: iconWrap,
                  height: iconWrap,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.14)
                        : AppColors.accent.withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    icon,
                    size: _activitiesScaled(context, 18, min: 16, max: 18),
                    color: selected ? Colors.white : AppColors.accent,
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
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFFFFF9F0)
                              : const Color(0xE6F0E2D2),
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
                        style: TextStyle(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.78)
                              : const Color(0xA8FFF0E0),
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                icon,
                color: AppColors.accent,
                size: _activitiesScaled(context, 15, min: 14, max: 16),
              ),
            ),
            SizedBox(width: _activitiesScaled(context, 8, min: 7, max: 10)),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
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
      padding: EdgeInsets.symmetric(
        vertical: _activitiesScaled(context, 18, min: 14, max: 20),
      ),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withValues(alpha: 0.08),
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
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2B1808).withValues(alpha: 0.99),
                    const Color(0xFF201208),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(
                    _activitiesScaled(context, 28, min: 24, max: 30),
                  ),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
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
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          _activitiesScaled(context, 18, min: 14, max: 20),
                          horizontalPadding,
                          0,
                        ),
                        child: child,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        top: _activitiesScaled(context, 12, min: 10, max: 14),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        _activitiesScaled(context, 12, min: 10, max: 14),
                        horizontalPadding,
                        footerPadding,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.accent.withValues(alpha: 0.09),
                          ),
                        ),
                        color: Colors.black.withValues(alpha: 0.06),
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
          style: TextStyle(
            color: const Color(0xA1FFF0E0),
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
          cursorColor: AppColors.accent,
          style: TextStyle(
            color: Color(0xC2FFF0E0),
            fontSize: fieldFontSize,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(
              color: Color(0x75FFF0E0),
              fontSize: fieldFontSize,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            errorText: errorText,
            errorMaxLines: 2,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.015),
            contentPadding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            prefixIcon: showPrefix
                ? Padding(
                    padding: EdgeInsets.only(
                      left: _activitiesScaled(context, 12, min: 10, max: 12),
                      right: _activitiesScaled(context, 2, min: 2, max: 4),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        prefix,
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: fieldFontSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.22),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.22),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: AppColors.accent, width: 1.4),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: Color(0xFFE28A7E), width: 1.2),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: Color(0xFFE28A7E), width: 1.4),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.02),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Color(0xE6F0E2D2),
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
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textPrimary,
        minimumSize: Size(0, minHeight),
        padding: EdgeInsets.symmetric(
          horizontal: _activitiesScaled(context, 22, min: 16, max: 22),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(minHeight >= 70 ? 22 : 999),
        ),
        textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800),
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
    this.categorySlugs = const {},
    this.visibilities = const {},
    this.startDate,
    this.endDate,
    this.minPrice,
    this.maxPrice,
  });

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
      (categorySlugs.isNotEmpty ? 1 : 0) +
      (hasDateRange ? 1 : 0) +
      (hasPriceRange ? 1 : 0) +
      (hasVisibilityFilter ? 1 : 0);
  bool get hasAnyValue =>
      categorySlugs.isNotEmpty ||
      hasVisibilityFilter ||
      hasDateRange ||
      hasPriceRange;

  _DiscoverFilters copyWith({
    Set<String>? categorySlugs,
    Set<String>? visibilities,
    Object? startDate = _unset,
    Object? endDate = _unset,
    Object? minPrice = _unset,
    Object? maxPrice = _unset,
  }) {
    return _DiscoverFilters(
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
  String visibility,
  AppLocalizations l10n,
) {
  switch (visibility.toUpperCase()) {
    case 'PRIVATE':
      return _VisibilityBadgeStyle(
        label: l10n.createVisibilityPrivate,
        icon: Icons.lock_rounded,
        background: const Color(0x33271609),
        border: AppColors.accent.withValues(alpha: 0.26),
        foreground: const Color(0xFFFFB64D),
      );
    default:
      return _VisibilityBadgeStyle(
        label: l10n.createVisibilityPublic,
        icon: Icons.public_rounded,
        background: Colors.white.withValues(alpha: 0.08),
        border: Colors.white.withValues(alpha: 0.12),
        foreground: const Color(0xFFF7EBDD),
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
        colors: visual.colors,
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

    if (filters.startDate != null) {
      final startBoundary = DateTime(
        filters.startDate!.year,
        filters.startDate!.month,
        filters.startDate!.day,
      );
      if (item.startAt.toLocal().isBefore(startBoundary)) {
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
      if (item.startAt.toLocal().isAfter(endBoundary)) {
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
