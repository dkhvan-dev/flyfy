import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/device/device_context_service.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_view.dart';
import '../../features/activities/activity_currency.dart';
import '../../features/activities/activity_cover_url.dart';
import '../../features/activities/activity_formatters.dart';
import '../../features/activities/models/activity_category_vm.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/profile/profile_completion_gate.dart';
import '../../features/profile/profile_guard_result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../common/app_side_drawer.dart';
import 'widgets/activities_bottom_bar.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final DeviceContextService _deviceContextService =
      const DeviceContextService();

  _DiscoverFilters _filters = const _DiscoverFilters();
  String _searchQuery = '';
  String? _loadedHostedUserId;
  String? _priceFilterCountryCode;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ActivityProvider>();
      provider.loadActivities();
      provider.loadActivityCategories();
      _prefillPriceFilterCountryContext();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
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
    });
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

  Future<void> _openCategoryFilter(
    BuildContext context,
    List<_DiscoverCategoryOption> categoryOptions,
    List<ActivityListItemVm> items,
  ) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CategoryFilterSheet(
          l10n: AppLocalizations.of(sheetContext)!,
          initialSelectedSlugs: _filters.categorySlugs,
          options: categoryOptions,
          previewCountBuilder: (selectedSlugs) {
            final draftFilters = _filters.copyWith(
              categorySlugs: selectedSlugs,
            );
            return _applyDiscoverFilters(
              items,
              filters: draftFilters,
              searchQuery: _searchQuery,
              categoryLabelsBySlug: {
                for (final option in categoryOptions)
                  option.slug: option.label.toLowerCase(),
              },
            ).length;
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _filters = _filters.copyWith(categorySlugs: result);
    });
  }

  Future<void> _openPriceFilter(
    BuildContext context,
    List<ActivityListItemVm> items,
    String? currentCountryCode,
    String? fallbackCurrencyCode,
  ) async {
    final result = await showModalBottomSheet<_PriceRangeFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _PriceFilterSheet(
          l10n: AppLocalizations.of(sheetContext)!,
          items: items,
          currentCountryCode: currentCountryCode,
          fallbackCurrencyCode: fallbackCurrencyCode,
          initialMinPrice: _filters.minPrice,
          initialMaxPrice: _filters.maxPrice,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _filters = _filters.copyWith(
        minPrice: result.minPrice,
        maxPrice: result.maxPrice,
      );
    });
  }

  Future<void> _prefillPriceFilterCountryContext() async {
    final profileCountryCode = normalizeActivityCountryCode(
      context.read<SessionProvider>().profile?.countryCode,
    );
    if (mounted &&
        profileCountryCode != null &&
        _priceFilterCountryCode == null) {
      setState(() {
        _priceFilterCountryCode = profileCountryCode;
      });
    }

    try {
      final suggestion = await _deviceContextService.detectLocationSuggestion(
        requestPermission: false,
      );
      final detectedCountryCode = normalizeActivityCountryCode(
        suggestion?.countryCode,
      );
      if (!mounted ||
          detectedCountryCode == null ||
          detectedCountryCode == _priceFilterCountryCode) {
        return;
      }
      setState(() {
        _priceFilterCountryCode = detectedCountryCode;
      });
    } catch (_) {
      // Keep profile country when passive geolocation is unavailable.
    }
  }

  Future<void> _openDateFilter(BuildContext context) async {
    final result = await showModalBottomSheet<_DateRangeFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _DateFilterSheet(
          l10n: AppLocalizations.of(sheetContext)!,
          initialStartDate: _filters.startDate,
          initialEndDate: _filters.endDate,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _filters = _filters.copyWith(
        startDate: result.startDate,
        endDate: result.endDate,
      );
    });
  }

  Future<void> _openVisibilityFilter(BuildContext context) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _VisibilityFilterSheet(
          l10n: AppLocalizations.of(sheetContext)!,
          initialVisibilities: _filters.visibilities,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _filters = _filters.copyWith(visibilities: result);
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
    final currentPriceFilterCountryCode =
        _priceFilterCountryCode ??
        normalizeActivityCountryCode(profile?.countryCode);
    final location = resolveDrawerLocation(
      profile,
      Localizations.localeOf(context),
    );

    _ensureHostedActivitiesLoaded(currentUserId);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF1A1008),
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: 28,
      drawerScrimColor: Colors.black.withValues(alpha: 0.42),
      drawer: AppSideDrawer(
        l10n: l10n,
        isLoggedIn: isLoggedIn,
        profile: profile,
        location: location,
        languageLabel: resolveDrawerLanguageLabel(
          Localizations.localeOf(context).languageCode,
        ),
        activeItem: AppDrawerActiveItem.activities,
        onProfileTap: () => _runDrawerAction(() async => _openProfile()),
        onLanguageTap: () => _runDrawerAction(_showLanguageSheet),
        onHomeTap: () => _runDrawerAction(() async => context.go('/')),
        onMyActivitiesTap: () => _runDrawerAction(_openMyActivities),
        onActivitiesTap: () => _runDrawerAction(() async {}),
        onLoginTap: () => _runDrawerAction(
          () async => context.push('/login?from=/activities'),
        ),
        onLogoutTap: () => _runDrawerAction(_confirmLogout),
      ),
      bottomNavigationBar: ActivitiesBottomBar(
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
                final currentPriceFilterCurrency = filterCurrencyLabel(
                  countryCode: currentPriceFilterCountryCode,
                  currency: normalizeActivityCurrencyCode(profile?.currency),
                );
                final filteredItems = _applyDiscoverFilters(
                  discoverItems,
                  filters: _filters,
                  searchQuery: _searchQuery,
                  categoryLabelsBySlug: categoryLabelsBySlug,
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
                                  _DiscoverTopBar(
                                    title: l10n.activitiesDiscoverTitle,
                                    onBackTap: _goBack,
                                  ),
                                  SizedBox(height: layout.sectionGap),
                                  _DiscoverSearchField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    hintText: l10n.activitiesSearchHint,
                                  ),
                                  SizedBox(height: layout.filterGap),
                                  _DiscoverFilterRow(
                                    l10n: l10n,
                                    filters: _filters,
                                    priceCurrencyLabel:
                                        currentPriceFilterCurrency,
                                    selectedCategoryCount:
                                        _filters.categorySlugs.length,
                                    onCategoryTap: () => _openCategoryFilter(
                                      context,
                                      categoryOptions,
                                      discoverItems,
                                    ),
                                    onDateTap: () => _openDateFilter(context),
                                    onPriceTap: () => _openPriceFilter(
                                      context,
                                      discoverItems,
                                      currentPriceFilterCountryCode,
                                      normalizeActivityCurrencyCode(
                                        profile?.currency,
                                      ),
                                    ),
                                    onVisibilityTap: () =>
                                        _openVisibilityFilter(context),
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
                                140 + safeBottomInset,
                              ),
                              sliver: SliverList.separated(
                                itemCount: filteredItems.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: layout.cardGap),
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  final categorySlug = _normalizeSlug(
                                    item.categorySlug,
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

class _DiscoverTopBar extends StatelessWidget {
  const _DiscoverTopBar({required this.title, required this.onBackTap});

  final String title;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    final layout = _ActivitiesAdaptiveLayout.of(context);
    final trailingSlot = _activitiesScaled(context, 40, min: 36, max: 42);

    return Row(
      children: [
        _CircleHeaderButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBackTap,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFFFF7EF),
              fontSize: layout.topBarTitleSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        SizedBox.square(dimension: trailingSlot),
      ],
    );
  }
}

class _CircleHeaderButton extends StatelessWidget {
  const _CircleHeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final buttonSize = _activitiesScaled(
      context,
      compact ? 38 : 40,
      min: 36,
      max: 42,
    );
    final iconSize = _activitiesScaled(
      context,
      compact ? 18 : 20,
      min: 16,
      max: 20,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: const Color(0xFFFFF7EF), size: iconSize),
        ),
      ),
    );
  }
}

class _DiscoverSearchField extends StatelessWidget {
  const _DiscoverSearchField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = _activitiesScaled(context, 18, min: 14, max: 20);
    final verticalPadding = _activitiesScaled(context, 14, min: 12, max: 16);
    final searchFontSize = _activitiesScaled(context, 14, min: 13, max: 15);
    final iconSize = _activitiesScaled(context, 20, min: 18, max: 20);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.035),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: searchFontSize,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: TextStyle(
            color: const Color(0x8CFFF0E0),
            fontSize: searchFontSize,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(
              left: _activitiesScaled(context, 12, min: 10, max: 13),
              right: _activitiesScaled(context, 10, min: 8, max: 10),
            ),
            child: Icon(
              Icons.search_rounded,
              color: Color(0x88FFF0E0),
              size: iconSize,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: controller.clear,
                  splashRadius: 20,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0x88FFF0E0),
                  ),
                ),
        ),
      ),
    );
  }
}

class _DiscoverFilterRow extends StatelessWidget {
  const _DiscoverFilterRow({
    required this.l10n,
    required this.filters,
    required this.priceCurrencyLabel,
    required this.selectedCategoryCount,
    required this.onCategoryTap,
    required this.onDateTap,
    required this.onPriceTap,
    required this.onVisibilityTap,
  });

  final AppLocalizations l10n;
  final _DiscoverFilters filters;
  final String priceCurrencyLabel;
  final int selectedCategoryCount;
  final VoidCallback onCategoryTap;
  final VoidCallback onDateTap;
  final VoidCallback onPriceTap;
  final VoidCallback onVisibilityTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _DiscoverFilterChip(
            icon: Icons.dashboard_customize_outlined,
            label: selectedCategoryCount == 0
                ? l10n.activitiesFilterCategory
                : '${l10n.activitiesFilterCategory} · $selectedCategoryCount',
            active: filters.categorySlugs.isNotEmpty,
            onTap: onCategoryTap,
          ),
          const SizedBox(width: 10),
          _DiscoverFilterChip(
            icon: Icons.calendar_month_outlined,
            label: _dateChipLabel(context, l10n),
            active: filters.hasDateRange,
            onTap: onDateTap,
          ),
          const SizedBox(width: 10),
          _DiscoverFilterChip(
            icon: Icons.payments_outlined,
            label: _priceChipLabel(),
            active: filters.hasPriceRange,
            onTap: onPriceTap,
          ),
          const SizedBox(width: 10),
          _DiscoverFilterChip(
            icon: Icons.public_rounded,
            label: _visibilityChipLabel(),
            active: filters.hasVisibilityFilter,
            onTap: onVisibilityTap,
          ),
        ],
      ),
    );
  }

  String _priceChipLabel() {
    if (!filters.hasPriceRange) {
      return l10n.activitiesFilterPricing;
    }

    if (filters.minPrice == 0 && filters.maxPrice == 0) {
      return l10n.createPriceFree;
    }

    final minText = filters.minPrice?.toStringAsFixed(0);
    final maxText = filters.maxPrice?.toStringAsFixed(0);
    if (minText != null && maxText != null) {
      return '$priceCurrencyLabel $minText-$maxText';
    }
    if (minText != null) {
      return '$priceCurrencyLabel $minText+';
    }
    if (maxText != null) {
      return '$priceCurrencyLabel 0-$maxText';
    }
    return l10n.activitiesFilterPricing;
  }

  String _dateChipLabel(BuildContext context, AppLocalizations l10n) {
    if (!filters.hasDateRange) {
      return l10n.activitiesFilterDate;
    }

    final locale = Localizations.localeOf(context).toString();
    final formatter = DateFormat('dd MMM', locale);
    final start = filters.startDate == null
        ? null
        : formatter.format(filters.startDate!);
    final end = filters.endDate == null
        ? null
        : formatter.format(filters.endDate!);

    if (start != null && end != null) {
      return '$start-$end';
    }
    return start ?? end ?? l10n.activitiesFilterDate;
  }

  String _visibilityChipLabel() {
    if (!filters.hasVisibilityFilter) {
      return l10n.activitiesFilterVisibility;
    }

    if (filters.visibilities.length == 1) {
      final value = filters.visibilities.first;
      return value == 'PRIVATE'
          ? l10n.createVisibilityPrivate
          : l10n.createVisibilityPublic;
    }

    return l10n.activitiesFilterVisibility;
  }
}

class _DiscoverFilterChip extends StatelessWidget {
  const _DiscoverFilterChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chipPaddingHorizontal = _activitiesScaled(
      context,
      14,
      min: 12,
      max: 16,
    );
    final chipPaddingVertical = _activitiesScaled(context, 9, min: 8, max: 10);
    final iconSize = _activitiesScaled(context, 16, min: 14, max: 16);
    final fontSize = _activitiesScaled(context, 14, min: 13, max: 14);
    final arrowSize = _activitiesScaled(context, 18, min: 16, max: 18);
    final foreground = active
        ? const Color(0xFF241204)
        : const Color(0xFFF3DFCA);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: chipPaddingHorizontal,
            vertical: chipPaddingVertical,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFFFFAB2D), Color(0xFFFF9800)],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.03),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
            border: active
                ? null
                : Border.all(color: AppColors.accent.withValues(alpha: 0.12)),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.24),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: foreground),
              SizedBox(width: _activitiesScaled(context, 8, min: 6, max: 8)),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: fontSize,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              SizedBox(width: _activitiesScaled(context, 4, min: 3, max: 4)),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: arrowSize,
                color: foreground,
              ),
            ],
          ),
        ),
      ),
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
    final artSpec = _cardArtForItem(item);
    final badgeText = item.isFree ? l10n.createPriceFree : item.priceLabel;
    final visibilityBadge = _visibilityBadge(item.visibility, l10n);
    final dateText = DateFormat.MMMd(
      locale,
    ).add_Hm().format(item.startAt.toLocal());
    final locationText = item.shortLocation.isNotEmpty
        ? item.shortLocation
        : formatActivityDisplayStatus(item, l10n);
    final metaItems = <_CardMetaData>[
      _CardMetaData(icon: Icons.place_outlined, label: locationText),
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
    final locationFont = _activitiesScaled(context, 13, min: 12, max: 13);

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
                      child: _DecorativeActivityCover(
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
                              SizedBox(
                                height: _activitiesScaled(
                                  context,
                                  2,
                                  min: 1,
                                  max: 3,
                                ),
                              ),
                              Text(
                                locationText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFFEEDFD2),
                                  fontSize: locationFont,
                                  fontWeight: FontWeight.w500,
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

    return Row(
      children: [
        Icon(data.icon, size: iconSize, color: const Color(0xB0FFF0E0)),
        SizedBox(width: gap),
        Expanded(
          child: Text(
            data.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xA8FFF0E0),
              fontSize: fontSize,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _DecorativeActivityCover extends StatelessWidget {
  const _DecorativeActivityCover({required this.spec, this.imageUrl});

  final _CardArtSpec spec;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = imageUrl?.trim() ?? '';
    if (normalizedImageUrl.isNotEmpty) {
      return Image.network(
        normalizedImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _DecorativeActivityCoverFallback(spec: spec),
      );
    }

    return _DecorativeActivityCoverFallback(spec: spec);
  }
}

class _DecorativeActivityCoverFallback extends StatelessWidget {
  const _DecorativeActivityCoverFallback({required this.spec});

  final _CardArtSpec spec;

  @override
  Widget build(BuildContext context) {
    final largeOrb = _activitiesScaled(context, 150, min: 112, max: 162);
    final smallOrb = _activitiesScaled(context, 170, min: 124, max: 182);
    final iconSize = _activitiesScaled(context, 66, min: 50, max: 70);
    final arrowSize = _activitiesScaled(context, 34, min: 26, max: 36);
    final horizontalInset = _activitiesScaled(context, 26, min: 18, max: 28);
    final bottomInset = _activitiesScaled(context, 14, min: 10, max: 16);

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
            left: -_activitiesScaled(context, 32, min: 20, max: 34),
            top: -_activitiesScaled(context, 34, min: 22, max: 36),
            child: Container(
              width: largeOrb,
              height: largeOrb,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: -_activitiesScaled(context, 44, min: 28, max: 46),
            bottom: -_activitiesScaled(context, 48, min: 30, max: 50),
            child: Container(
              width: smallOrb,
              height: smallOrb,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            left: horizontalInset,
            right: horizontalInset,
            bottom: bottomInset,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  spec.icon,
                  size: iconSize,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                Transform.rotate(
                  angle: -0.18,
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: arrowSize,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

class _CategoryFilterSheet extends StatefulWidget {
  const _CategoryFilterSheet({
    required this.l10n,
    required this.initialSelectedSlugs,
    required this.options,
    required this.previewCountBuilder,
  });

  final AppLocalizations l10n;
  final Set<String> initialSelectedSlugs;
  final List<_DiscoverCategoryOption> options;
  final int Function(Set<String> selectedSlugs) previewCountBuilder;

  @override
  State<_CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<_CategoryFilterSheet> {
  late Set<String> _selectedSlugs;

  @override
  void initState() {
    super.initState();
    _selectedSlugs = Set<String>.from(widget.initialSelectedSlugs);
  }

  @override
  Widget build(BuildContext context) {
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final count = widget.previewCountBuilder(_selectedSlugs);
    final titleSize = _activitiesScaled(context, 30, min: 24, max: 30);
    final footerGap = _activitiesScaled(context, 14, min: 10, max: 16);
    final compactActions =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.02;

    return _ActivitiesResponsiveTextScope(
      child: FractionallySizedBox(
        heightFactor: 0.95,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              top: _activitiesScaled(context, 18, min: 12, max: 18),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF271609).withValues(alpha: 0.98),
                    const Color(0xFF1B0E05).withValues(alpha: 0.985),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(
                    _activitiesScaled(context, 36, min: 28, max: 36),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.36),
                    blurRadius: 40,
                    offset: const Offset(0, -12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: _activitiesScaled(context, 84, min: 62, max: 84),
                      height: _activitiesScaled(context, 10, min: 6, max: 10),
                      margin: EdgeInsets.only(
                        top: _activitiesScaled(context, 14, min: 10, max: 14),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _activitiesScaled(context, 18, min: 16, max: 20),
                      _activitiesScaled(context, 20, min: 16, max: 20),
                      _activitiesScaled(context, 18, min: 16, max: 20),
                      0,
                    ),
                    child: Text(
                      widget.l10n.activitiesFiltersCategoriesTitle,
                      style: TextStyle(
                        color: const Color(0xFFFFFAF5),
                        fontSize: titleSize,
                        height: 1.05,
                        letterSpacing: -0.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        _activitiesScaled(context, 18, min: 16, max: 20),
                        _activitiesScaled(context, 22, min: 16, max: 22),
                        _activitiesScaled(context, 18, min: 16, max: 20),
                        0,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final textScale = MediaQuery.textScalerOf(
                            context,
                          ).scale(1);
                          final useSingleColumn =
                              constraints.maxWidth < 360 || textScale > 1.05;
                          final spacing = _activitiesScaled(
                            context,
                            18,
                            min: 12,
                            max: 18,
                          );
                          final gridDelegate =
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: useSingleColumn ? 1 : 2,
                                mainAxisSpacing: spacing,
                                crossAxisSpacing: spacing,
                                mainAxisExtent: _activitiesScaled(
                                  context,
                                  useSingleColumn ? 152 : 178,
                                  min: useSingleColumn ? 136 : 158,
                                  max: useSingleColumn ? 168 : 188,
                                ),
                              );

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.options.length,
                            gridDelegate: gridDelegate,
                            itemBuilder: (context, index) {
                              final option = widget.options[index];
                              final selected = _selectedSlugs.contains(
                                option.slug,
                              );

                              return _CategoryOptionCard(
                                option: option,
                                selected: selected,
                                subtitle: widget.l10n.activitiesResultsCount(
                                  option.count,
                                ),
                                onTap: () {
                                  setState(() {
                                    if (selected) {
                                      _selectedSlugs.remove(option.slug);
                                    } else {
                                      _selectedSlugs.add(option.slug);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _activitiesScaled(context, 18, min: 16, max: 20),
                      _activitiesScaled(context, 10, min: 8, max: 12),
                      _activitiesScaled(context, 18, min: 16, max: 20),
                      8,
                    ),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        2,
                        _activitiesScaled(context, 18, min: 14, max: 18),
                        2,
                        2,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final useColumn =
                              compactActions || constraints.maxWidth < 340;
                          final label = Text(
                            widget.l10n.activitiesFiltersSelectedCategories,
                            style: TextStyle(
                              color: const Color(0x80FFF7EF),
                              fontSize: _activitiesScaled(
                                context,
                                15,
                                min: 13,
                                max: 15,
                              ),
                            ),
                          );
                          final value = Text(
                            _selectedSummary(widget.options),
                            textAlign: useColumn
                                ? TextAlign.left
                                : TextAlign.right,
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: _activitiesScaled(
                                context,
                                16,
                                min: 14,
                                max: 16,
                              ),
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          );

                          if (useColumn) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                label,
                                SizedBox(height: footerGap),
                                value,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: label),
                              SizedBox(width: footerGap),
                              Expanded(child: value),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _activitiesScaled(context, 18, min: 16, max: 20),
                      6,
                      _activitiesScaled(context, 18, min: 16, max: 20),
                      18 + safeBottomInset,
                    ),
                    child: compactActions
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(<String>{}),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xB3FFF7EF),
                                  minimumSize: Size(
                                    0,
                                    _activitiesScaled(
                                      context,
                                      56,
                                      min: 50,
                                      max: 64,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  widget.l10n.myActivitiesFilterClear,
                                ),
                              ),
                              SizedBox(height: footerGap),
                              _PrimaryPillButton(
                                label: widget.l10n.activitiesShowResults(count),
                                onTap: () =>
                                    Navigator.of(context).pop(_selectedSlugs),
                                minHeight: _activitiesScaled(
                                  context,
                                  72,
                                  min: 58,
                                  max: 72,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(<String>{}),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xB3FFF7EF),
                                    minimumSize: Size(
                                      0,
                                      _activitiesScaled(
                                        context,
                                        64,
                                        min: 54,
                                        max: 64,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    widget.l10n.myActivitiesFilterClear,
                                  ),
                                ),
                              ),
                              SizedBox(width: footerGap),
                              Expanded(
                                flex: 2,
                                child: _PrimaryPillButton(
                                  label: widget.l10n.activitiesShowResults(
                                    count,
                                  ),
                                  onTap: () =>
                                      Navigator.of(context).pop(_selectedSlugs),
                                  minHeight: _activitiesScaled(
                                    context,
                                    72,
                                    min: 58,
                                    max: 72,
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
      ),
    );
  }

  String _selectedSummary(List<_DiscoverCategoryOption> options) {
    if (_selectedSlugs.isEmpty) {
      return widget.l10n.activitiesAllCategories;
    }

    final labels = options
        .where((option) => _selectedSlugs.contains(option.slug))
        .map((option) => option.label)
        .toList();
    return labels.join(', ');
  }
}

class _CategoryOptionCard extends StatelessWidget {
  const _CategoryOptionCard({
    required this.option,
    required this.selected,
    required this.subtitle,
    required this.onTap,
  });

  final _DiscoverCategoryOption option;
  final bool selected;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconWrap = _activitiesScaled(context, 40, min: 34, max: 40);
    final titleSize = _activitiesScaled(context, 16, min: 14, max: 16);
    final subtitleSize = _activitiesScaled(context, 13, min: 12, max: 13);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: EdgeInsets.all(
            _activitiesScaled(context, 18, min: 14, max: 18),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.08),
              width: selected ? 2.6 : 1.0,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: selected
                  ? [
                      option.colors.first.withValues(alpha: 0.88),
                      option.colors.last.withValues(alpha: 0.98),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.03),
                      Colors.white.withValues(alpha: 0.015),
                    ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconWrap,
                height: iconWrap,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: selected
                      ? Colors.black.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.04),
                ),
                child: Icon(
                  option.icon,
                  color: selected
                      ? AppColors.accent
                      : Colors.white.withValues(alpha: 0.86),
                ),
              ),
              const Spacer(),
              Text(
                option.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFFFFAF5),
                  fontSize: titleSize,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: _activitiesScaled(context, 6, min: 4, max: 6)),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFFFC56A)
                      : const Color(0x8FFFF7EF),
                  fontSize: subtitleSize,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceFilterSheet extends StatefulWidget {
  const _PriceFilterSheet({
    required this.l10n,
    required this.items,
    required this.currentCountryCode,
    required this.fallbackCurrencyCode,
    this.initialMinPrice,
    this.initialMaxPrice,
  });

  final AppLocalizations l10n;
  final List<ActivityListItemVm> items;
  final String? currentCountryCode;
  final String? fallbackCurrencyCode;
  final double? initialMinPrice;
  final double? initialMaxPrice;

  @override
  State<_PriceFilterSheet> createState() => _PriceFilterSheetState();
}

class _PriceFilterSheetState extends State<_PriceFilterSheet> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(
      text: widget.initialMinPrice?.toStringAsFixed(0) ?? '',
    );
    _maxController = TextEditingController(
      text: widget.initialMaxPrice?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final currencyCode = _resolvePriceFilterCurrencyCode(
      currentCountryCode: widget.currentCountryCode,
      fallbackCurrencyCode: widget.fallbackCurrencyCode,
      items: widget.items,
    );
    final currencyLabel = filterCurrencyLabel(currency: currencyCode);
    final presets = _buildPricePresets(
      currencyLabel: currencyLabel,
      nominalUnit: pricePresetNominalUnit(
        countryCode: widget.currentCountryCode,
        currency: currencyCode,
      ),
      l10n: widget.l10n,
    );

    return _RangeSheetScaffold(
      title: widget.l10n.activitiesFiltersPriceRangeTitle,
      maxHeightFactor: 0.6,
      footerPadding: 18 + safeBottomInset,
      onClear: () => Navigator.of(context).pop(const _PriceRangeFilter()),
      onApply: () {
        Navigator.of(context).pop(
          _PriceRangeFilter(
            minPrice: _parseNumeric(_minController.text),
            maxPrice: _parseNumeric(_maxController.text),
          ),
        );
      },
      l10n: widget.l10n,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final useColumn =
                  constraints.maxWidth < 360 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.02;
              if (useColumn) {
                return Column(
                  children: [
                    _RangeTextField(
                      label: widget.l10n.activitiesFilterMinPrice,
                      controller: _minController,
                      prefix: currencyLabel,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: const [_DecimalTextInputFormatter()],
                    ),
                    SizedBox(
                      height: _activitiesScaled(context, 14, min: 12, max: 16),
                    ),
                    _RangeTextField(
                      label: widget.l10n.activitiesFilterMaxPrice,
                      controller: _maxController,
                      prefix: currencyLabel,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: const [_DecimalTextInputFormatter()],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _RangeTextField(
                      label: widget.l10n.activitiesFilterMinPrice,
                      controller: _minController,
                      prefix: currencyLabel,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: const [_DecimalTextInputFormatter()],
                    ),
                  ),
                  SizedBox(
                    width: _activitiesScaled(context, 14, min: 10, max: 14),
                  ),
                  Expanded(
                    child: _RangeTextField(
                      label: widget.l10n.activitiesFilterMaxPrice,
                      controller: _maxController,
                      prefix: currencyLabel,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: const [_DecimalTextInputFormatter()],
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: _activitiesScaled(context, 22, min: 16, max: 24)),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final preset in presets)
                _PresetChip(
                  label: preset.label,
                  onTap: () {
                    setState(() {
                      _minController.text = preset.minPrice == null
                          ? ''
                          : preset.minPrice!.toStringAsFixed(0);
                      _maxController.text = preset.maxPrice == null
                          ? ''
                          : preset.maxPrice!.toStringAsFixed(0);
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateFilterSheet extends StatefulWidget {
  const _DateFilterSheet({
    required this.l10n,
    this.initialStartDate,
    this.initialEndDate,
  });

  final AppLocalizations l10n;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  @override
  State<_DateFilterSheet> createState() => _DateFilterSheetState();
}

class _DateFilterSheetState extends State<_DateFilterSheet> {
  late final TextEditingController _startController;
  late final TextEditingController _endController;

  String? _startError;
  String? _endError;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(
      text: widget.initialStartDate == null
          ? ''
          : _formatDate(widget.initialStartDate!),
    );
    _endController = TextEditingController(
      text: widget.initialEndDate == null
          ? ''
          : _formatDate(widget.initialEndDate!),
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final presets = _buildDatePresets(widget.l10n);

    return _RangeSheetScaffold(
      title: widget.l10n.myActivitiesFilterDateRange,
      maxHeightFactor: 0.6,
      footerPadding: 18 + safeBottomInset,
      onClear: () => Navigator.of(context).pop(const _DateRangeFilter()),
      onApply: _handleApply,
      l10n: widget.l10n,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final useColumn =
                  constraints.maxWidth < 360 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.02;
              if (useColumn) {
                return Column(
                  children: [
                    _RangeTextField(
                      label: widget.l10n.myActivitiesFilterStartDate,
                      controller: _startController,
                      prefix: '',
                      hintText: widget.l10n.myActivitiesFilterDatePlaceholder,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [_DateTextInputFormatter()],
                      errorText: _startError,
                    ),
                    SizedBox(
                      height: _activitiesScaled(context, 14, min: 12, max: 16),
                    ),
                    _RangeTextField(
                      label: widget.l10n.myActivitiesFilterEndDate,
                      controller: _endController,
                      prefix: '',
                      hintText: widget.l10n.myActivitiesFilterDatePlaceholder,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [_DateTextInputFormatter()],
                      errorText: _endError,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _RangeTextField(
                      label: widget.l10n.myActivitiesFilterStartDate,
                      controller: _startController,
                      prefix: '',
                      hintText: widget.l10n.myActivitiesFilterDatePlaceholder,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [_DateTextInputFormatter()],
                      errorText: _startError,
                    ),
                  ),
                  SizedBox(
                    width: _activitiesScaled(context, 14, min: 10, max: 14),
                  ),
                  Expanded(
                    child: _RangeTextField(
                      label: widget.l10n.myActivitiesFilterEndDate,
                      controller: _endController,
                      prefix: '',
                      hintText: widget.l10n.myActivitiesFilterDatePlaceholder,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [_DateTextInputFormatter()],
                      errorText: _endError,
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: _activitiesScaled(context, 22, min: 16, max: 24)),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final preset in presets)
                _PresetChip(
                  label: preset.label,
                  onTap: () {
                    setState(() {
                      _startController.text = _formatDate(preset.startDate);
                      _endController.text = _formatDate(preset.endDate);
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

  void _handleApply() {
    final startDate = _parseDate(_startController.text);
    final endDate = _parseDate(_endController.text);

    setState(() {
      _startError = _dateError(
        _startController.text,
        startDate,
        widget.l10n.myActivitiesFilterInvalidDate,
      );
      _endError = _dateError(
        _endController.text,
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

    Navigator.of(
      context,
    ).pop(_DateRangeFilter(startDate: startDate, endDate: endDate));
  }

  String _formatDate(DateTime value) => DateFormat('dd.MM.yyyy').format(value);
}

class _VisibilityFilterSheet extends StatefulWidget {
  const _VisibilityFilterSheet({
    required this.l10n,
    required this.initialVisibilities,
  });

  final AppLocalizations l10n;
  final Set<String> initialVisibilities;

  @override
  State<_VisibilityFilterSheet> createState() => _VisibilityFilterSheetState();
}

class _VisibilityFilterSheetState extends State<_VisibilityFilterSheet> {
  late Set<String> _selectedVisibilities;

  @override
  void initState() {
    super.initState();
    _selectedVisibilities = Set<String>.from(widget.initialVisibilities);
  }

  @override
  Widget build(BuildContext context) {
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;

    return _RangeSheetScaffold(
      title: widget.l10n.activitiesFiltersVisibilityTitle,
      maxHeightFactor: 0.5,
      footerPadding: 18 + safeBottomInset,
      onClear: () => Navigator.of(context).pop(<String>{}),
      onApply: () {
        final normalized = _normalizeVisibilitySelection(_selectedVisibilities);
        Navigator.of(context).pop(normalized);
      },
      l10n: widget.l10n,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useColumn = constraints.maxWidth < 360;
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

  void _toggleVisibility(String value) {
    setState(() {
      if (_selectedVisibilities.contains(value)) {
        _selectedVisibilities.remove(value);
      } else {
        _selectedVisibilities.add(value);
      }
    });
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
    final iconWrap = _activitiesScaled(context, 42, min: 36, max: 42);
    final titleSize = _activitiesScaled(context, 16, min: 14, max: 16);
    final bodySize = _activitiesScaled(context, 13, min: 12, max: 13);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.all(
            _activitiesScaled(context, 18, min: 14, max: 18),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: selected ? Colors.white : AppColors.accent,
                ),
              ),
              SizedBox(
                height: _activitiesScaled(context, 16, min: 12, max: 16),
              ),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFFFF9F0)
                      : const Color(0xE6F0E2D2),
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: _activitiesScaled(context, 8, min: 6, max: 8)),
              Text(
                description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.82)
                      : const Color(0xB3FFF0E0),
                  fontSize: bodySize,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
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
  });

  final String title;
  final Widget child;
  final VoidCallback onClear;
  final VoidCallback onApply;
  final double footerPadding;
  final AppLocalizations l10n;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;
    final titleSize = _activitiesScaled(context, 24, min: 20, max: 24);
    final horizontalPadding = _activitiesScaled(context, 24, min: 16, max: 24);
    final verticalGap = _activitiesScaled(context, 14, min: 10, max: 16);
    final compactActions =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.02;

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
                    Center(
                      child: Container(
                        width: _activitiesScaled(context, 52, min: 42, max: 52),
                        height: _activitiesScaled(context, 6, min: 5, max: 6),
                        margin: EdgeInsets.only(
                          top: _activitiesScaled(context, 10, min: 8, max: 10),
                          bottom: _activitiesScaled(context, 8, min: 6, max: 8),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppColors.accent.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        _activitiesScaled(context, 12, min: 10, max: 12),
                        horizontalPadding,
                        0,
                      ),
                      child: Text(
                        title,
                        style: TextStyle(
                          color: const Color(0xFFFFF8F1),
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          _activitiesScaled(context, 26, min: 18, max: 26),
                          horizontalPadding,
                          0,
                        ),
                        child: child,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        top: _activitiesScaled(context, 20, min: 14, max: 20),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        _activitiesScaled(context, 16, min: 12, max: 16),
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
                      child: compactActions
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextButton(
                                  onPressed: onClear,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xBDFFF0E0),
                                    minimumSize: Size(
                                      0,
                                      _activitiesScaled(
                                        context,
                                        56,
                                        min: 50,
                                        max: 58,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: Text(l10n.myActivitiesFilterClear),
                                ),
                                SizedBox(height: verticalGap),
                                _PrimaryPillButton(
                                  label: l10n.myActivitiesFilterApply,
                                  onTap: onApply,
                                  minHeight: _activitiesScaled(
                                    context,
                                    62,
                                    min: 54,
                                    max: 64,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: onClear,
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xBDFFF0E0),
                                      minimumSize: Size(
                                        0,
                                        _activitiesScaled(
                                          context,
                                          56,
                                          min: 50,
                                          max: 58,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: Text(l10n.myActivitiesFilterClear),
                                  ),
                                ),
                                SizedBox(width: verticalGap),
                                Expanded(
                                  flex: 2,
                                  child: _PrimaryPillButton(
                                    label: l10n.myActivitiesFilterApply,
                                    onTap: onApply,
                                    minHeight: _activitiesScaled(
                                      context,
                                      62,
                                      min: 54,
                                      max: 64,
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
    final labelSize = _activitiesScaled(context, 14, min: 13, max: 14);
    final fieldFontSize = _activitiesScaled(context, 18, min: 16, max: 18);
    final verticalPadding = _activitiesScaled(context, 18, min: 14, max: 18);
    final horizontalPadding = _activitiesScaled(context, 16, min: 14, max: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: const Color(0xA1FFF0E0), fontSize: labelSize),
        ),
        SizedBox(height: _activitiesScaled(context, 10, min: 8, max: 10)),
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
                      left: _activitiesScaled(context, 14, min: 12, max: 14),
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
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.22),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.22),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              borderSide: BorderSide(color: AppColors.accent, width: 1.4),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              borderSide: BorderSide(color: Color(0xFFE28A7E), width: 1.2),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
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
    final horizontal = _activitiesScaled(context, 18, min: 14, max: 18);
    final vertical = _activitiesScaled(context, 11, min: 9, max: 11);
    final fontSize = _activitiesScaled(context, 14, min: 13, max: 14);

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
  const _CardMetaData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _CardArtSpec {
  const _CardArtSpec({required this.icon, required this.colors});

  final IconData icon;
  final List<Color> colors;
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

class _PriceRangeFilter {
  const _PriceRangeFilter({this.minPrice, this.maxPrice});

  final double? minPrice;
  final double? maxPrice;
}

class _DateRangeFilter {
  const _DateRangeFilter({this.startDate, this.endDate});

  final DateTime? startDate;
  final DateTime? endDate;
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
      if (_normalizeSlug(item.categorySlug).isNotEmpty)
        _normalizeSlug(item.categorySlug),
  }.toList();

  slugs.sort();

  final counts = <String, int>{};
  for (final item in items) {
    final slug = _normalizeSlug(item.categorySlug);
    if (slug.isEmpty) {
      continue;
    }
    counts[slug] = (counts[slug] ?? 0) + 1;
  }

  final options = <_DiscoverCategoryOption>[];
  for (final slug in slugs) {
    ActivityCategoryVm? matchedCategory;
    for (final category in categories) {
      if (_normalizeSlug(category.slug) == slug) {
        matchedCategory = category;
        break;
      }
    }

    final visual = _categoryVisual(slug);
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
  required Map<String, String> categoryLabelsBySlug,
}) {
  final normalizedQuery = searchQuery.trim().toLowerCase();
  final filtered = items.where((item) {
    final slug = _normalizeSlug(item.categorySlug);
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

  filtered.sort((a, b) => a.startAt.compareTo(b.startAt));
  return filtered;
}

_CardArtSpec _categoryVisual(String slug) {
  if (slug.contains('wellness') || slug.contains('health')) {
    return const _CardArtSpec(
      icon: Icons.spa_rounded,
      colors: [Color(0xFF295E54), Color(0xFF74D2AE)],
    );
  }
  if (slug.contains('nature') ||
      slug.contains('outdoor') ||
      slug.contains('hiking')) {
    return const _CardArtSpec(
      icon: Icons.forest_rounded,
      colors: [Color(0xFF2A4B2B), Color(0xFF78C36A)],
    );
  }
  if (slug.contains('food')) {
    return const _CardArtSpec(
      icon: Icons.restaurant_rounded,
      colors: [Color(0xFF66371A), Color(0xFFFFA657)],
    );
  }
  if (slug.contains('culture') ||
      slug.contains('art') ||
      slug.contains('history')) {
    return const _CardArtSpec(
      icon: Icons.palette_outlined,
      colors: [Color(0xFF5A3055), Color(0xFFCB84BA)],
    );
  }
  if (slug.contains('sport') || slug.contains('adventure')) {
    return const _CardArtSpec(
      icon: Icons.kayaking_rounded,
      colors: [Color(0xFF5F3D1F), Color(0xFFE69B4B)],
    );
  }
  if (slug.contains('workshop') ||
      slug.contains('learning') ||
      slug.contains('education')) {
    return const _CardArtSpec(
      icon: Icons.auto_stories_rounded,
      colors: [Color(0xFF443A73), Color(0xFF9A89E2)],
    );
  }
  if (slug.contains('night') || slug.contains('social')) {
    return const _CardArtSpec(
      icon: Icons.celebration_rounded,
      colors: [Color(0xFF5A2348), Color(0xFFE07AB8)],
    );
  }

  return const _CardArtSpec(
    icon: Icons.travel_explore_rounded,
    colors: [Color(0xFF52301B), Color(0xFFCB8B50)],
  );
}

_CardArtSpec _cardArtForItem(ActivityListItemVm item) {
  final fromCategory = _categoryVisual(_normalizeSlug(item.categorySlug));
  if (item.format.toUpperCase() == 'ONLINE') {
    return const _CardArtSpec(
      icon: Icons.videocam_rounded,
      colors: [Color(0xFF1F4D8A), Color(0xFF67A8F5)],
    );
  }
  if (item.format.toUpperCase() == 'HYBRID') {
    return const _CardArtSpec(
      icon: Icons.devices_rounded,
      colors: [Color(0xFF5E3E86), Color(0xFFB08CF6)],
    );
  }
  return fromCategory;
}

String _normalizeSlug(String raw) => raw.trim().toLowerCase();

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

String _dominantCurrencyCode(List<ActivityListItemVm> items) {
  final counts = <String, int>{};
  for (final item in items) {
    final currency = item.resolvedCurrencyCode;
    if (currency == null || currency.isEmpty || item.isFree) {
      continue;
    }
    counts[currency] = (counts[currency] ?? 0) + 1;
  }

  if (counts.isEmpty) {
    return 'KZT';
  }

  var dominantCode = counts.keys.first;
  var maxCount = counts[dominantCode] ?? 0;
  counts.forEach((code, count) {
    if (count > maxCount) {
      dominantCode = code;
      maxCount = count;
    }
  });

  return dominantCode;
}

String _resolvePriceFilterCurrencyCode({
  required String? currentCountryCode,
  required String? fallbackCurrencyCode,
  required List<ActivityListItemVm> items,
}) {
  return filterCurrencyCode(
    countryCode: currentCountryCode,
    currency:
        normalizeActivityCurrencyCode(fallbackCurrencyCode) ??
        _dominantCurrencyCode(items),
  );
}

List<_PricePreset> _buildPricePresets({
  required String currencyLabel,
  required double nominalUnit,
  required AppLocalizations l10n,
}) {
  final minPaid = nominalUnit;
  final low = nominalUnit * 10;
  final medium = nominalUnit * 50;
  return [
    _PricePreset(label: l10n.createPriceFree, minPrice: 0, maxPrice: 0),
    _PricePreset(
      label:
          '$currencyLabel ${minPaid.toStringAsFixed(0)}-${low.toStringAsFixed(0)}',
      minPrice: minPaid,
      maxPrice: low,
    ),
    _PricePreset(
      label:
          '$currencyLabel ${low.toStringAsFixed(0)}-${medium.toStringAsFixed(0)}',
      minPrice: low,
      maxPrice: medium,
    ),
    _PricePreset(
      label: '$currencyLabel ${medium.toStringAsFixed(0)}+',
      minPrice: medium,
      maxPrice: null,
    ),
  ];
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
