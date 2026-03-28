import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/error_view.dart';
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

  _DiscoverFilters _filters = const _DiscoverFilters();
  String _searchQuery = '';
  String? _loadedHostedUserId;

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
    super.dispose();
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

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
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
  ) async {
    final result = await showModalBottomSheet<_PriceRangeFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _PriceFilterSheet(
          l10n: AppLocalizations.of(sheetContext)!,
          items: items,
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
                                  onMenuTap: _openDrawer,
                                  onNotificationsTap: () =>
                                      context.push('/notifications'),
                                ),
                                SizedBox(height: layout.sectionGap),
                                _DiscoverSearchField(
                                  controller: _searchController,
                                  hintText: l10n.activitiesSearchHint,
                                ),
                                SizedBox(height: layout.filterGap),
                                _DiscoverFilterRow(
                                  l10n: l10n,
                                  filters: _filters,
                                  selectedCategoryCount:
                                      _filters.categorySlugs.length,
                                  onCategoryTap: () => _openCategoryFilter(
                                    context,
                                    categoryOptions,
                                    discoverItems,
                                  ),
                                  onDateTap: () => _openDateFilter(context),
                                  onPriceTap: () =>
                                      _openPriceFilter(context, discoverItems),
                                  onVisibilityTap: () =>
                                      _openVisibilityFilter(context),
                                ),
                                const SizedBox(height: 16),
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
                                  const SizedBox(height: 14),
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
                                if (provider.state == ActivitiesState.loading &&
                                    discoverItems.isNotEmpty) ...[
                                  const SizedBox(height: 18),
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
                                message: provider.errorMessage ??
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
                              18,
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
                                final categoryLabel = categoryOptions
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
                                  isOwner: currentUserId.isNotEmpty &&
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
    );
  }
}

class _DiscoverScreenBackdrop extends StatelessWidget {
  const _DiscoverScreenBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
        const Positioned(
          top: -144,
          left: -44,
          right: -44,
          child: IgnorePointer(
            child: SizedBox(
              height: 344,
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
        const Positioned(
          top: 92,
          right: -92,
          child: IgnorePointer(
            child: SizedBox(
              width: 256,
              height: 256,
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
        const Positioned(
          left: -68,
          right: -68,
          bottom: -124,
          child: IgnorePointer(
            child: SizedBox(
              height: 284,
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
  const _DiscoverTopBar({
    required this.title,
    required this.onMenuTap,
    required this.onNotificationsTap,
  });

  final String title;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleHeaderButton(icon: Icons.menu_rounded, onTap: onMenuTap),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFF7EF),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _CircleHeaderButton(
          icon: Icons.notifications_none_rounded,
          onTap: onNotificationsTap,
        ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.04),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
      ),
    );
  }
}

class _DiscoverSearchField extends StatelessWidget {
  const _DiscoverSearchField({
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
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
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0x8CFFF0E0), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 10),
            child: Icon(
              Icons.search_rounded,
              color: Color(0x88FFF0E0),
              size: 20,
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
    required this.selectedCategoryCount,
    required this.onCategoryTap,
    required this.onDateTap,
    required this.onPriceTap,
    required this.onVisibilityTap,
  });

  final AppLocalizations l10n;
  final _DiscoverFilters filters;
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

    final minText = filters.minPrice?.toStringAsFixed(0);
    final maxText = filters.maxPrice?.toStringAsFixed(0);
    if (minText != null && maxText != null) {
      return '$minText-$maxText';
    }
    if (minText != null) {
      return '$minText+';
    }
    if (maxText != null) {
      return '0-$maxText';
    }
    return l10n.activitiesFilterPricing;
  }

  String _dateChipLabel(BuildContext context, AppLocalizations l10n) {
    if (!filters.hasDateRange) {
      return l10n.activitiesFilterDate;
    }

    final locale = Localizations.localeOf(context).toString();
    final formatter = DateFormat('dd MMM', locale);
    final start =
        filters.startDate == null ? null : formatter.format(filters.startDate!);
    final end =
        filters.endDate == null ? null : formatter.format(filters.endDate!);

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
    final foreground =
        active ? const Color(0xFF241204) : const Color(0xFFF3DFCA);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
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
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.activitiesResultsCount(count),
            style: const TextStyle(
              color: Color(0xCCFFF0E0),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: onClear,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Text(l10n.myActivitiesFilterClear),
        ),
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
    final artSpec = _cardArtForItem(item);
    final badgeText = item.isFree ? l10n.createPriceFree : item.priceLabel;
    final visibilityBadge = _visibilityBadge(item.visibility, l10n);
    final dateText = DateFormat.MMMd(locale).add_Hm().format(item.startAt.toLocal());
    final locationText = item.shortLocation.isNotEmpty
        ? item.shortLocation
        : formatActivityStatus(item.status, l10n);
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
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
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
                              size: 14,
                              color: visibilityBadge.foreground,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              visibilityBadge.label,
                              style: TextStyle(
                                color: visibilityBadge.foreground,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC46362A),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: item.isFree
                                ? const Color(0xFFFFC56A)
                                : AppColors.accent,
                            fontSize: 13,
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
                          width: 38,
                          height: 38,
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
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoryLabel.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFFFB64D),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                locationText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFEEDFD2),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final gap = 10.0;
                        final itemWidth = (constraints.maxWidth - gap) / 2;

                        return Wrap(
                          spacing: gap,
                          runSpacing: 12,
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
                    const SizedBox(height: 18),
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
    return Row(
      children: [
        Icon(data.icon, size: 16, color: const Color(0xB0FFF0E0)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            data.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xA8FFF0E0),
              fontSize: 13,
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
            left: -32,
            top: -34,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: -44,
            bottom: -48,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            left: 26,
            right: 26,
            bottom: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  spec.icon,
                  size: 66,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                Transform.rotate(
                  angle: -0.18,
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: 34,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.22),
                ),
              ),
              child: Icon(icon, size: 40, color: AppColors.accent),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xB3FFF0E0),
                fontSize: 15,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onActionTap != null) ...[
              const SizedBox(height: 22),
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

    return FractionallySizedBox(
      heightFactor: 0.95,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 18),
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(36),
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
                    width: 84,
                    height: 10,
                    margin: const EdgeInsets.only(top: 14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                  child: Text(
                    widget.l10n.activitiesFiltersCategoriesTitle,
                    style: const TextStyle(
                      color: Color(0xFFFFFAF5),
                      fontSize: 30,
                      height: 1.05,
                      letterSpacing: -0.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                    child: Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.options.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 18,
                            childAspectRatio: 0.94,
                          ),
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
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(2, 18, 2, 2),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.l10n.activitiesFiltersSelectedCategories,
                            style: const TextStyle(
                              color: Color(0x80FFF7EF),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _selectedSummary(widget.options),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 16,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(18, 6, 18, 18 + safeBottomInset),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(<String>{}),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xB3FFF7EF),
                            minimumSize: const Size(0, 64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(widget.l10n.myActivitiesFilterClear),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _PrimaryPillButton(
                          label: widget.l10n.activitiesShowResults(count),
                          onTap: () =>
                              Navigator.of(context).pop(_selectedSlugs),
                          minHeight: 72,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
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
                width: 40,
                height: 40,
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
                style: const TextStyle(
                  color: Color(0xFFFFFAF5),
                  fontSize: 16,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFFFC56A)
                      : const Color(0x8FFFF7EF),
                  fontSize: 13,
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
    this.initialMinPrice,
    this.initialMaxPrice,
  });

  final AppLocalizations l10n;
  final List<ActivityListItemVm> items;
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
    final dominantCurrency = _dominantCurrency(widget.items);
    final presets = _buildPricePresets(
      widget.items,
      dominantCurrency,
      widget.l10n,
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
          Row(
            children: [
              Expanded(
                child: _RangeTextField(
                  label: widget.l10n.activitiesFilterMinPrice,
                  controller: _minController,
                  prefix: dominantCurrency,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [_DecimalTextInputFormatter()],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _RangeTextField(
                  label: widget.l10n.activitiesFilterMaxPrice,
                  controller: _maxController,
                  prefix: dominantCurrency,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [_DecimalTextInputFormatter()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
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
          Row(
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
              const SizedBox(width: 14),
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
          ),
          const SizedBox(height: 22),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
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
                width: 42,
                height: 42,
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
              const SizedBox(height: 16),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFFFF9F0)
                      : const Color(0xE6F0E2D2),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.82)
                      : const Color(0xB3FFF0E0),
                  fontSize: 13,
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

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
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
                      width: 52,
                      height: 6,
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: AppColors.accent.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFFFF8F1),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                      child: child,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: EdgeInsets.fromLTRB(24, 16, 24, footerPadding),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.09),
                        ),
                      ),
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: onClear,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xBDFFF0E0),
                              minimumSize: const Size(0, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(l10n.myActivitiesFilterClear),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: _PrimaryPillButton(
                            label: l10n.myActivitiesFilterApply,
                            onTap: onApply,
                            minHeight: 62,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xA1FFF0E0), fontSize: 14),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          cursorColor: AppColors.accent,
          style: const TextStyle(
            color: Color(0xC2FFF0E0),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0x75FFF0E0),
              fontSize: 18,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            errorText: errorText,
            errorMaxLines: 2,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.015),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            prefixIcon: showPrefix
                ? Padding(
                    padding: const EdgeInsets.only(left: 14, right: 2),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        prefix,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 18,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.02),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xE6F0E2D2),
              fontSize: 14,
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
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textPrimary,
        minimumSize: Size(0, minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(minHeight >= 70 ? 22 : 999),
        ),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
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
      minPrice:
          identical(minPrice, _unset) ? this.minPrice : minPrice as double?,
      maxPrice:
          identical(maxPrice, _unset) ? this.maxPrice : maxPrice as double?,
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
  double get horizontalPadding => isCompact ? 14 : 18;
  double get topPadding => isCompact ? 14 : 16;
  double get sectionGap => isCompact ? 14 : 16;
  double get filterGap => isCompact ? 14 : 16;
  double get cardGap => isCompact ? 18 : 22;
  double get cardRadius => isCompact ? 28 : 34;
  double get cardPadding => isCompact ? 16 : 18;
  double get titleSize => isCompact ? 20 : 22;
  double get ctaHeight => isCompact ? 48 : 52;
  double get coverAspectRatio => isCompact ? 1.48 : 1.55;
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
    itemsById[item.id] = item;
  }

  final normalizedUserId = (currentUserId ?? '').trim();
  if (normalizedUserId.isNotEmpty) {
    for (final item in hostedItems) {
      if (item.hostUserId != normalizedUserId) {
        continue;
      }
      if (!_isDiscoverListStatus(item.status) ||
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
    case 'FULL':
    case 'STARTED':
    case 'COMPLETED':
      return true;
    default:
      return false;
  }
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
        label: matchedCategory?.localizedName(languageCode).trim().isNotEmpty ==
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

String _dominantCurrency(List<ActivityListItemVm> items) {
  final counts = <String, int>{};
  for (final item in items) {
    final currency = (item.currency ?? '').trim().toUpperCase();
    if (currency.isEmpty || item.isFree) {
      continue;
    }
    counts[currency] = (counts[currency] ?? 0) + 1;
  }

  if (counts.isEmpty) {
    return '₸';
  }

  var dominantCode = counts.keys.first;
  var maxCount = counts[dominantCode] ?? 0;
  counts.forEach((code, count) {
    if (count > maxCount) {
      dominantCode = code;
      maxCount = count;
    }
  });

  switch (dominantCode) {
    case 'USD':
      return r'$';
    case 'EUR':
      return '€';
    case 'RUB':
      return '₽';
    case 'KZT':
      return '₸';
    default:
      return dominantCode;
  }
}

List<_PricePreset> _buildPricePresets(
  List<ActivityListItemVm> items,
  String currencySymbol,
  AppLocalizations l10n,
) {
  final values = items
      .where((item) => !item.isFree && (item.priceAmount ?? 0) > 0)
      .map((item) => item.priceAmount!)
      .toList()
    ..sort();

  if (values.isEmpty) {
    return [
      _PricePreset(label: l10n.createPriceFree, minPrice: 0, maxPrice: 0),
      _PricePreset(label: '$currencySymbol 0-100', minPrice: 0, maxPrice: 100),
      _PricePreset(
        label: '$currencySymbol 100+',
        minPrice: 100,
        maxPrice: null,
      ),
    ];
  }

  final maxValue = values.last;
  final low = (maxValue * 0.25).clamp(1, maxValue).roundToDouble();
  final medium = (maxValue * 0.60).clamp(low, maxValue).roundToDouble();

  return [
    _PricePreset(label: l10n.createPriceFree, minPrice: 0, maxPrice: 0),
    _PricePreset(
      label: '$currencySymbol 0-${low.toStringAsFixed(0)}',
      minPrice: 0,
      maxPrice: low,
    ),
    _PricePreset(
      label:
          '$currencySymbol ${low.toStringAsFixed(0)}-${medium.toStringAsFixed(0)}',
      minPrice: low,
      maxPrice: medium,
    ),
    _PricePreset(
      label: '$currencySymbol ${medium.toStringAsFixed(0)}+',
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
