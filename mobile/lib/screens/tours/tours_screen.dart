import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_inline_sort_row.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../features/profile/profile_completion_gate.dart';
import '../../features/profile/profile_guard_result.dart';
import '../../features/tours/models/tour_vm.dart';
import '../../features/tours/tour_cover_url.dart';
import '../../features/tours/tour_localization.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/tour_provider.dart';

class ToursScreen extends StatefulWidget {
  const ToursScreen({super.key});

  @override
  State<ToursScreen> createState() => _ToursScreenState();
}

enum _ToursSortMode { popular, newest, affordable }

enum _ToursSortDirection { asc, desc }

enum _ToursDurationFilter { short, halfDay, fullDay, multiDay }

enum _ToursPriceFilter { budget, premium }

extension _ToursSortModeLabel on _ToursSortMode {
  String label(AppLocalizations l10n) {
    return switch (this) {
      _ToursSortMode.popular => l10n.toursSortPopular,
      _ToursSortMode.newest => l10n.toursSortNewest,
      _ToursSortMode.affordable => l10n.toursSortAffordable,
    };
  }

  _ToursSortDirection get defaultDirection {
    return switch (this) {
      _ToursSortMode.affordable => _ToursSortDirection.asc,
      _ToursSortMode.popular => _ToursSortDirection.desc,
      _ToursSortMode.newest => _ToursSortDirection.desc,
    };
  }
}

class _CategoryFilterOption {
  const _CategoryFilterOption({
    required this.slug,
    required this.icon,
  });

  final String slug;
  final IconData icon;
}

const _categoryFilterOptions = [
  _CategoryFilterOption(slug: 'adventure', icon: Icons.terrain_rounded),
  _CategoryFilterOption(slug: 'cultural', icon: Icons.account_balance_rounded),
  _CategoryFilterOption(slug: 'culinary', icon: Icons.restaurant_rounded),
  _CategoryFilterOption(slug: 'wellness', icon: Icons.spa_rounded),
];

const _languageFilterCodes = ['en', 'ru', 'kk'];

class _ToursScreenState extends State<ToursScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  _ToursSortMode _sortMode = _ToursSortMode.popular;
  _ToursSortDirection _sortDirection = _ToursSortDirection.desc;
  _ToursFilters _filters = const _ToursFilters();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TourProvider>().loadTours();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim();
    if (nextQuery == _searchQuery) return;

    setState(() {
      _searchQuery = nextQuery;
    });
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  Future<void> _handleRefresh() {
    return context.read<TourProvider>().refreshTours(query: _searchQuery);
  }

  Future<void> _onCreateTourTap() async {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.state != AuthState.authenticated) {
      context.push('/login?from=/tours/create');
      return;
    }

    final result = await ProfileCompletionGate.ensureCompleted(context);
    if (result == ProfileGuardResult.cancelled || !mounted) return;

    await context.push('/tours/create');
    if (!mounted) return;

    final lastCreatedTour = context.read<TourProvider>().lastCreatedTour;
    if (lastCreatedTour != null && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openTourDetails(TourVm tour) {
    if (tour.id.trim().isEmpty) return;

    context.push('/tours/${Uri.encodeComponent(tour.id)}', extra: tour);
  }

  void _onSortTap(_ToursSortMode mode) {
    setState(() {
      if (_sortMode == mode) {
        _sortDirection = _sortDirection == _ToursSortDirection.asc
            ? _ToursSortDirection.desc
            : _ToursSortDirection.asc;
        return;
      }

      _sortMode = mode;
      _sortDirection = mode.defaultDirection;
    });
  }

  Future<void> _showFilters() async {
    final toursSnapshot = context.read<TourProvider>().tours;
    final selectedFilters = await showModalBottomSheet<_ToursFilters>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ToursFiltersSheet(
        initialFilters: _filters,
        resultCountBuilder: (filters) => _visibleTours(
          toursSnapshot,
          filtersOverride: filters,
        ).length,
      ),
    );

    if (selectedFilters == null || !mounted) return;
    setState(() => _filters = selectedFilters);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = context.watch<SessionProvider>().profile;
    final canCreateTour = profile?.isGuide == true;

    return Scaffold(
      backgroundColor: const Color(0xFF21170D),
      bottomNavigationBar: ToursBottomNavigation(
        canCreateTour: canCreateTour,
        onCreateTourTap: _onCreateTourTap,
        onMapTap: () => context.push('/map'),
        onHomeTap: () => context.go('/'),
        onQrTap: () => context.push('/qr'),
        onServicesTap: () => context.push('/services'),
        onChatsTap: () => context.push('/chats'),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppListScreenHeader(
              title: l10n.toursDiscoverTitle,
              notificationsTooltip: l10n.attractionNotificationsTooltip,
              onBackTap: _goBack,
              onNotificationsTap: () => context.push('/notifications'),
            ),
            Expanded(
              child: Consumer<TourProvider>(
                builder: (context, provider, _) {
                  final visibleTours = _visibleTours(provider.tours);
                  final isInitialLoading =
                      provider.listState == TourListState.loading &&
                          provider.tours.isEmpty;
                  final hasInitialError =
                      provider.listState == TourListState.error &&
                          provider.tours.isEmpty;

                  if (hasInitialError) {
                    return ErrorView(
                      message:
                          provider.listErrorMessage ?? l10n.toursLoadFailed,
                      onRetry: () => context
                          .read<TourProvider>()
                          .loadTours(query: _searchQuery),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: const Color(0xFF2B1F14),
                    onRefresh: _handleRefresh,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            _horizontalPadding(context),
                            14,
                            _horizontalPadding(context),
                            0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ToursSearchField(
                                  controller: _searchController,
                                  hintText: l10n.toursSearchHint,
                                  onFilterTap: _showFilters,
                                  activeFilterCount: _filters.activeCount,
                                ),
                                const SizedBox(height: 26),
                                const Divider(
                                  height: 1,
                                  color: Color(0x1AFFFFFF),
                                ),
                                const SizedBox(height: 9),
                                _ToursSortBar(
                                  l10n: l10n,
                                  selected: _sortMode,
                                  direction: _sortDirection,
                                  onChanged: _onSortTap,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isInitialLoading)
                          _ToursLoadingGrid(
                              horizontalPadding: _horizontalPadding(context))
                        else if (visibleTours.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _ToursEmptyState(
                              title: l10n.toursEmptyTitle,
                              subtitle: _searchQuery.isEmpty
                                  ? l10n.toursEmptySubtitle
                                  : l10n.toursEmptySearchSubtitle,
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              _horizontalPadding(context),
                              26,
                              _horizontalPadding(context),
                              28,
                            ),
                            sliver: SliverGrid.builder(
                              itemCount: visibleTours.length,
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisSpacing: 18,
                                crossAxisSpacing: 18,
                                childAspectRatio: _gridAspectRatio(context),
                              ),
                              itemBuilder: (context, index) {
                                return TourListCard(
                                  tour: visibleTours[index],
                                  seed: index,
                                  onTap: () =>
                                      _openTourDetails(visibleTours[index]),
                                );
                              },
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.paddingOf(context).bottom + 20,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TourVm> _visibleTours(
    List<TourVm> tours, {
    _ToursFilters? filtersOverride,
  }) {
    final query = _searchQuery.toLowerCase();
    final filters = filtersOverride ?? _filters;
    final filtered = tours.where((tour) {
      if (!filters.matches(tour)) return false;
      if (query.isEmpty) return true;

      final haystack = [
        tour.title,
        tour.summary,
        tour.cityName,
        tour.landmarkName,
        tour.categorySlug,
        ...tour.tags,
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList(growable: false);

    final sorted = [...filtered];
    sorted.sort((a, b) {
      final comparison = switch (_sortMode) {
        _ToursSortMode.affordable => a.priceAmount.compareTo(b.priceAmount),
        _ToursSortMode.newest => a.id.compareTo(b.id),
        _ToursSortMode.popular => a.title.compareTo(b.title),
      };

      return _sortDirection == _ToursSortDirection.asc
          ? comparison
          : -comparison;
    });

    return sorted;
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 360) return 18;
    if (width >= 600) return 28;
    return 24;
  }

  double _gridAspectRatio(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 360) return 0.63;
    if (width >= 600) return 0.72;
    return 0.68;
  }
}

class ToursBottomNavigation extends StatelessWidget {
  const ToursBottomNavigation({
    super.key,
    required this.canCreateTour,
    required this.onCreateTourTap,
    required this.onMapTap,
    required this.onHomeTap,
    required this.onQrTap,
    required this.onServicesTap,
    required this.onChatsTap,
  });

  final bool canCreateTour;
  final VoidCallback onCreateTourTap;
  final VoidCallback onMapTap;
  final VoidCallback onHomeTap;
  final VoidCallback onQrTap;
  final VoidCallback onServicesTap;
  final VoidCallback onChatsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (canCreateTour) {
      return CreateActionBottomNavigationBar(
        createSemanticsLabel: l10n.toursCreateFab,
        onHomeTap: onHomeTap,
        onQrTap: onQrTap,
        onCreateTap: onCreateTourTap,
        onServicesTap: onServicesTap,
        onChatsTap: onChatsTap,
        backgroundStyle: AppBottomNavCreateBackgroundStyle.flat,
      );
    }

    return CommonBottomNavigationBar(
      onHomeTap: onHomeTap,
      onQrTap: onQrTap,
      onMapTap: onMapTap,
      onServicesTap: onServicesTap,
      onChatsTap: onChatsTap,
    );
  }
}

class _ToursSearchField extends StatelessWidget {
  const _ToursSearchField({
    required this.controller,
    required this.hintText,
    required this.onFilterTap,
    required this.activeFilterCount,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onFilterTap;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      decoration: BoxDecoration(
        color: const Color(0xFF2B1F14),
        borderRadius: BorderRadius.circular(21),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 8, 0),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.accent, size: 27),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(color: Color(0xFF9F8B7D)),
              ),
            ),
          ),
          Tooltip(
            message: AppLocalizations.of(context)!.myActivitiesFilterButton,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: onFilterTap,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                    foregroundColor: AppColors.accent,
                    minimumSize: const Size(43, 43),
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 24),
                ),
                if (activeFilterCount > 0)
                  PositionedDirectional(
                    top: 2,
                    end: 2,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        activeFilterCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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

class _ToursFilters {
  const _ToursFilters({
    this.categorySlugs = const <String>{},
    this.languageCodes = const <String>{},
    this.duration,
    this.price,
  });

  final Set<String> categorySlugs;
  final Set<String> languageCodes;
  final _ToursDurationFilter? duration;
  final _ToursPriceFilter? price;

  int get activeCount =>
      categorySlugs.length +
      languageCodes.length +
      (duration == null ? 0 : 1) +
      (price == null ? 0 : 1);

  bool matches(TourVm tour) {
    if (categorySlugs.isNotEmpty) {
      final category = tour.categorySlug?.trim().toLowerCase();
      if (category == null || !categorySlugs.contains(category)) return false;
    }

    if (languageCodes.isNotEmpty) {
      final tourLanguages = tour.languageCodes
          .map((code) => code.trim().toLowerCase())
          .where((code) => code.isNotEmpty)
          .toSet();
      if (!languageCodes.any(tourLanguages.contains)) return false;
    }

    final durationFilter = duration;
    if (durationFilter != null &&
        !_matchesDuration(durationFilter, tour.durationMinutes)) {
      return false;
    }

    final priceFilter = price;
    if (priceFilter != null && !_matchesPrice(priceFilter, tour)) return false;

    return true;
  }

  static bool _matchesDuration(_ToursDurationFilter filter, int minutes) {
    return switch (filter) {
      _ToursDurationFilter.short => minutes > 0 && minutes < 180,
      _ToursDurationFilter.halfDay => minutes >= 180 && minutes <= 360,
      _ToursDurationFilter.fullDay => minutes > 360 && minutes <= 720,
      _ToursDurationFilter.multiDay => minutes > 720,
    };
  }

  static bool _matchesPrice(_ToursPriceFilter filter, TourVm tour) {
    final priceKzt = _priceApproxKzt(tour);
    return switch (filter) {
      _ToursPriceFilter.budget => priceKzt <= 50000,
      _ToursPriceFilter.premium => priceKzt >= 100000,
    };
  }

  static double _priceApproxKzt(TourVm tour) {
    final amount = tour.priceAmount;
    switch (tour.currency.trim().toUpperCase()) {
      case 'USD':
        return amount * 450;
      case 'EUR':
        return amount * 500;
      case 'RUB':
        return amount * 5;
      case 'GBP':
        return amount * 580;
      case 'KZT':
      default:
        return amount;
    }
  }
}

class _ToursFiltersSheet extends StatefulWidget {
  const _ToursFiltersSheet({
    required this.initialFilters,
    required this.resultCountBuilder,
  });

  final _ToursFilters initialFilters;
  final int Function(_ToursFilters filters) resultCountBuilder;

  @override
  State<_ToursFiltersSheet> createState() => _ToursFiltersSheetState();
}

class _ToursFiltersSheetState extends State<_ToursFiltersSheet> {
  late _ToursFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  void _clear() {
    setState(() => _filters = const _ToursFilters());
  }

  void _toggleCategory(String slug) {
    final next = Set<String>.of(_filters.categorySlugs);
    if (!next.remove(slug)) next.add(slug);

    setState(() {
      _filters = _ToursFilters(
        categorySlugs: next,
        languageCodes: _filters.languageCodes,
        duration: _filters.duration,
        price: _filters.price,
      );
    });
  }

  void _toggleLanguage(String code) {
    final next = Set<String>.of(_filters.languageCodes);
    if (!next.remove(code)) next.add(code);

    setState(() {
      _filters = _ToursFilters(
        categorySlugs: _filters.categorySlugs,
        languageCodes: next,
        duration: _filters.duration,
        price: _filters.price,
      );
    });
  }

  void _setDuration(_ToursDurationFilter duration) {
    setState(() {
      _filters = _ToursFilters(
        categorySlugs: _filters.categorySlugs,
        languageCodes: _filters.languageCodes,
        duration: _filters.duration == duration ? null : duration,
        price: _filters.price,
      );
    });
  }

  void _setPrice(_ToursPriceFilter price) {
    setState(() {
      _filters = _ToursFilters(
        categorySlugs: _filters.categorySlugs,
        languageCodes: _filters.languageCodes,
        duration: _filters.duration,
        price: _filters.price == price ? null : price,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final resultCount = widget.resultCountBuilder(_filters);

    return AppDismissibleModalSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
          maxWidth: 520,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF21170D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0x293A270F))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppFilterSheetHeader(
                title: l10n.toursFiltersTitle,
                clearLabel: l10n.toursFiltersClear,
                onClear: _clear,
                height: 74,
                horizontalPadding: 22,
                titleFontSize: 18,
              ),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ToursFilterSection(
                        title: l10n.toursFilterCategories,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final option in _categoryFilterOptions)
                              _ToursFilterChip(
                                label: localizedTourCategoryLabel(
                                  l10n,
                                  option.slug,
                                ),
                                icon: option.icon,
                                selected: _filters.categorySlugs.contains(
                                  option.slug,
                                ),
                                onTap: () => _toggleCategory(option.slug),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      _ToursFilterSection(
                        title: l10n.toursFilterPriceRange,
                        child: _ToursSegmentGrid<_ToursPriceFilter>(
                          items: [
                            _ToursSegmentItem(
                              value: _ToursPriceFilter.budget,
                              label: l10n.toursFilterBudget,
                            ),
                            _ToursSegmentItem(
                              value: _ToursPriceFilter.premium,
                              label: l10n.toursFilterPremium,
                            ),
                          ],
                          selectedValue: _filters.price,
                          onSelected: _setPrice,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _ToursFilterSection(
                        title: l10n.toursFilterDuration,
                        child: _ToursSegmentGrid<_ToursDurationFilter>(
                          items: [
                            _ToursSegmentItem(
                              value: _ToursDurationFilter.short,
                              label: l10n.toursFilterShortDuration,
                            ),
                            _ToursSegmentItem(
                              value: _ToursDurationFilter.halfDay,
                              label: l10n.toursFilterHalfDayDuration,
                            ),
                            _ToursSegmentItem(
                              value: _ToursDurationFilter.fullDay,
                              label: l10n.toursFilterFullDayDuration,
                            ),
                            _ToursSegmentItem(
                              value: _ToursDurationFilter.multiDay,
                              label: l10n.toursFilterMultiDayDuration,
                            ),
                          ],
                          selectedValue: _filters.duration,
                          onSelected: _setDuration,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _ToursFilterSection(
                        title: l10n.toursFilterLanguage,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final code in _languageFilterCodes)
                              _ToursFilterChip(
                                label: localizedTourLanguageLabel(l10n, code),
                                selected: _filters.languageCodes.contains(code),
                                onTap: () => _toggleLanguage(code),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(22, 0, 22, bottomInset + 18),
                child: AppFilterApplyButton(
                  label: l10n.toursFiltersShowResults(resultCount),
                  onTap: () => Navigator.of(context).pop(_filters),
                  borderRadius: 14,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToursFilterSection extends StatelessWidget {
  const _ToursFilterSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _ToursFilterChip extends StatelessWidget {
  const _ToursFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : const Color(0xFF534638),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: selected ? Colors.white : const Color(0xFFD8C7B7),
                  size: 16,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFD8C7B7),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToursSegmentItem<T> {
  const _ToursSegmentItem({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class _ToursSegmentGrid<T> extends StatelessWidget {
  const _ToursSegmentGrid({
    required this.items,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<_ToursSegmentItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn = constraints.maxWidth < 330;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: useSingleColumn ? 1 : 2,
            mainAxisExtent: 48,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final selected = item.value == selectedValue;
            return _ToursSegmentButton(
              label: item.label,
              selected: selected,
              onTap: () => onSelected(item.value),
            );
          },
        );
      },
    );
  }
}

class _ToursSegmentButton extends StatelessWidget {
  const _ToursSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : const Color(0xFF4A3D31),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFD8C7B7),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToursSortBar extends StatelessWidget {
  const _ToursSortBar({
    required this.l10n,
    required this.selected,
    required this.direction,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final _ToursSortMode selected;
  final _ToursSortDirection direction;
  final ValueChanged<_ToursSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppInlineSortRow<_ToursSortMode>(
      label: l10n.toursSortLabel,
      options: [
        for (final mode in _ToursSortMode.values)
          AppInlineSortOption(value: mode, label: mode.label(l10n)),
      ],
      selectedValue: selected,
      isAscending: direction == _ToursSortDirection.asc,
      onSelected: onChanged,
    );
  }
}

class TourListCard extends StatelessWidget {
  const TourListCard({
    super.key,
    required this.tour,
    required this.seed,
    this.onTap,
  });

  final TourVm tour;
  final int seed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = _primaryLocation(tour);
    final duration = _formatDuration(context, tour.durationMinutes);
    final price = _formatPrice(context, tour);
    final category = _categoryLabel(l10n, tour.categorySlug);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF251A10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: _TourCoverArt(
                    seed: seed,
                    categorySlug: tour.categorySlug,
                    imageUrl: resolveTourCoverUrl(tour),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            tour.title.isEmpty ? category : tour.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFEADCD0),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              height: 1.16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                duration.isEmpty ? category : duration,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFB5A394),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                price,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                  height: 1,
                                ),
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

  String _primaryLocation(TourVm tour) {
    final city = tour.cityName?.trim();
    if (city != null && city.isNotEmpty) return city;

    final landmark = tour.landmarkName?.trim();
    if (landmark != null && landmark.isNotEmpty) return landmark;

    return tour.categorySlug?.trim().isNotEmpty == true
        ? tour.categorySlug!.trim()
        : 'FlyFy';
  }

  String _formatDuration(BuildContext context, int minutes) {
    if (minutes <= 0) return '';

    final l10n = AppLocalizations.of(context)!;
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    if (hours > 0 && remainder > 0) {
      return '$hours ${l10n.toursDurationHourShort} '
          '$remainder ${l10n.toursDurationMinuteShort}';
    }
    if (hours > 0) {
      return '$hours ${l10n.toursDurationHourShort}';
    }
    return '$minutes ${l10n.toursDurationMinuteShort}';
  }

  String _formatPrice(BuildContext context, TourVm tour) {
    final l10n = AppLocalizations.of(context)!;
    if (tour.priceAmount <= 0) return l10n.toursFreePrice;

    final decimalDigits =
        tour.priceAmount == tour.priceAmount.truncateToDouble() ? 0 : 2;

    try {
      return NumberFormat.simpleCurrency(
        name: tour.currency,
        decimalDigits: decimalDigits,
      ).format(tour.priceAmount);
    } catch (_) {
      return '${tour.priceAmount.toStringAsFixed(decimalDigits)} ${tour.currency}';
    }
  }

  String _categoryLabel(AppLocalizations l10n, String? categorySlug) {
    return localizedTourCategoryLabel(l10n, categorySlug);
  }
}

class _TourCoverArt extends StatelessWidget {
  const _TourCoverArt({
    required this.seed,
    required this.categorySlug,
    this.imageUrl,
  });

  final int seed;
  final String? categorySlug;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(categorySlug, seed);
    final resolvedImageUrl = imageUrl?.trim() ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (resolvedImageUrl.isNotEmpty)
          Image.network(
            resolvedImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _GeneratedTourCover(
              palette: palette,
              seed: seed,
            ),
          )
        else
          _GeneratedTourCover(palette: palette, seed: seed),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.16),
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: AppColors.accent, size: 15),
                  SizedBox(width: 3),
                  Text(
                    '4.9',
                    style: TextStyle(
                      color: Color(0xFFF4EEE8),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  _TourCoverPalette _paletteFor(String? categorySlug, int seed) {
    switch (categorySlug?.toLowerCase()) {
      case 'cultural':
        return const _TourCoverPalette(
          sky: Color(0xFF52B8D9),
          haze: Color(0xFFE1C071),
          ground: Color(0xFF8A5A2B),
          ridge: Color(0xFFB67A33),
          ridgeDark: Color(0xFF5A3419),
        );
      case 'culinary':
        return const _TourCoverPalette(
          sky: Color(0xFFFFB13B),
          haze: Color(0xFF8C4022),
          ground: Color(0xFF30160C),
          ridge: Color(0xFFE07A22),
          ridgeDark: Color(0xFF6D2812),
        );
      case 'wellness':
        return const _TourCoverPalette(
          sky: Color(0xFF7DD2C7),
          haze: Color(0xFF4F8E65),
          ground: Color(0xFF143B29),
          ridge: Color(0xFF2E7D4C),
          ridgeDark: Color(0xFF10291E),
        );
      default:
        final variants = [
          const _TourCoverPalette(
            sky: Color(0xFF43A9DF),
            haze: Color(0xFFBFE6F3),
            ground: Color(0xFF143E23),
            ridge: Color(0xFF2D8437),
            ridgeDark: Color(0xFF102E19),
          ),
          const _TourCoverPalette(
            sky: Color(0xFFF7A541),
            haze: Color(0xFFD17618),
            ground: Color(0xFF7D3508),
            ridge: Color(0xFF9B4C08),
            ridgeDark: Color(0xFF4C2206),
          ),
        ];
        return variants[seed % variants.length];
    }
  }
}

class _GeneratedTourCover extends StatelessWidget {
  const _GeneratedTourCover({
    required this.palette,
    required this.seed,
  });

  final _TourCoverPalette palette;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.sky, palette.haze, palette.ground],
            ),
          ),
        ),
        CustomPaint(painter: _TourCoverPainter(palette, seed)),
      ],
    );
  }
}

class _TourCoverPainter extends CustomPainter {
  const _TourCoverPainter(this.palette, this.seed);

  final _TourCoverPalette palette;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final ridgePaint = Paint()..color = palette.ridge;
    final ridgeDarkPaint = Paint()..color = palette.ridgeDark;
    final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.86);

    final offset = (seed % 4) * size.width * 0.05;
    final firstRidge = Path()
      ..moveTo(-size.width * 0.1, size.height)
      ..lineTo(size.width * 0.32 + offset, size.height * 0.42)
      ..lineTo(size.width * 0.78 + offset, size.height)
      ..close();

    final secondRidge = Path()
      ..moveTo(size.width * 0.22 - offset, size.height)
      ..lineTo(size.width * 0.72 - offset, size.height * 0.34)
      ..lineTo(size.width * 1.12, size.height)
      ..close();

    final snowCap = Path()
      ..moveTo(size.width * 0.72 - offset, size.height * 0.34)
      ..lineTo(size.width * 0.63 - offset, size.height * 0.48)
      ..lineTo(size.width * 0.78 - offset, size.height * 0.44)
      ..close();

    canvas
      ..drawPath(firstRidge, ridgeDarkPaint)
      ..drawPath(secondRidge, ridgePaint)
      ..drawPath(snowCap, snowPaint);

    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.54, size.height * 0.28),
          radius: math.min(size.width, size.height) * 0.2,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.54, size.height * 0.28),
      math.min(size.width, size.height) * 0.2,
      sunPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TourCoverPainter oldDelegate) {
    return oldDelegate.palette != palette || oldDelegate.seed != seed;
  }
}

class _TourCoverPalette {
  const _TourCoverPalette({
    required this.sky,
    required this.haze,
    required this.ground,
    required this.ridge,
    required this.ridgeDark,
  });

  final Color sky;
  final Color haze;
  final Color ground;
  final Color ridge;
  final Color ridgeDark;
}

class _ToursLoadingGrid extends StatelessWidget {
  const _ToursLoadingGrid({required this.horizontalPadding});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding:
          EdgeInsets.fromLTRB(horizontalPadding, 26, horizontalPadding, 28),
      sliver: SliverGrid.builder(
        itemCount: 6,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 18,
          crossAxisSpacing: 18,
          childAspectRatio:
              MediaQuery.sizeOf(context).width <= 360 ? 0.63 : 0.68,
        ),
        itemBuilder: (context, index) {
          return const _ToursSkeletonCard();
        },
      ),
    );
  }
}

class _ToursSkeletonCard extends StatelessWidget {
  const _ToursSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF251A10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _SkeletonBlock()),
            SizedBox(height: 14),
            _SkeletonLine(width: 84, height: 10),
            SizedBox(height: 10),
            _SkeletonLine(width: double.infinity, height: 18),
            SizedBox(height: 8),
            _SkeletonLine(width: 92, height: 16),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ToursEmptyState extends StatelessWidget {
  const _ToursEmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: AppColors.accent,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFA99586),
                  fontSize: 15,
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
