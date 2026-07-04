import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/file_api.dart';
import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_inline_sort_row.dart';
import '../../core/ui/app_list_search_field.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/error_dialog.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../core/ui/pagination_bar.dart';
import '../../features/guides/data/guide_discovery_api.dart';
import '../../features/guides/guide_filter_options.dart';
import '../../features/guides/guide_localization.dart';
import '../../features/guides/guide_search.dart';
import '../../features/guides/models/public_guide_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/home_location_provider.dart';
import '../../shared/location/home_location_filter_defaults.dart';
import '../../shared/widgets/app_city_filter_section.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

enum _GuideSortMode { rating, experience }

enum _GuideSortDirection { asc, desc }

extension _GuideSortModeX on _GuideSortMode {
  String label(AppLocalizations l10n) {
    return switch (this) {
      _GuideSortMode.rating => l10n.guidesSortRating,
      _GuideSortMode.experience => l10n.guidesSortExperience,
    };
  }

  _GuideSortDirection get defaultDirection {
    return switch (this) {
      _GuideSortMode.rating => _GuideSortDirection.desc,
      _GuideSortMode.experience => _GuideSortDirection.desc,
    };
  }

  String get queryKey {
    return switch (this) {
      _GuideSortMode.rating => 'rating',
      _GuideSortMode.experience => 'experience',
    };
  }
}

extension _GuideSortDirectionX on _GuideSortDirection {
  String get queryKey {
    return switch (this) {
      _GuideSortDirection.asc => 'asc',
      _GuideSortDirection.desc => 'desc',
    };
  }
}

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  static const _pageSize = 8;

  final GuideDiscoveryApi _api = GuideDiscoveryApi();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<PublicGuideVm> _guides = const [];
  int _totalGuides = 0;
  bool _loading = true;
  bool _isRefreshingList = false;
  bool _hasAppliedDefaultCityFilter = false;
  String? _error;
  String _searchQuery = '';
  Timer? _searchDebounce;
  int _loadGuidesRequestId = 0;
  GuideFilterOptions _filterOptions = GuideFilterOptions.fallback;
  _GuideFilters _filters = const _GuideFilters();
  _GuideSortMode _sortMode = _GuideSortMode.rating;
  _GuideSortDirection _sortDirection = _GuideSortDirection.desc;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeGuides());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeGuides() async {
    if (!mounted) return;

    final locationProvider = context.read<HomeLocationProvider>();
    final startupLoads = <Future<void>>[_loadGuideFilterOptions()];
    if (!locationProvider.isLoaded && !locationProvider.isLoading) {
      startupLoads.add(
        locationProvider.load(
          languageCode: Localizations.localeOf(context).languageCode,
        ),
      );
    }
    await Future.wait(startupLoads);
    if (!mounted) return;
    _applyDefaultCityFilter(locationProvider);
    await _loadGuides();
  }

  Future<void> _loadGuideFilterOptions() async {
    try {
      final options = await _api.listPublicGuideFilterOptions();
      if (!mounted || options.isEmpty) return;
      setState(() => _filterOptions = options);
    } catch (_) {
      // Keep local fallback options; filters remain usable offline/poor network.
    }
  }

  void _applyDefaultCityFilter(HomeLocationProvider provider) {
    if (_hasAppliedDefaultCityFilter) {
      _hasAppliedDefaultCityFilter = true;
      return;
    }
    if (_filters.country != null || _filters.city != null) {
      _hasAppliedDefaultCityFilter = true;
      return;
    }
    final defaults = HomeLocationFilterDefaults.fromPreference(
      provider.effectiveLocation,
    );
    if (!defaults.hasValue) return;
    _hasAppliedDefaultCityFilter = true;
    if (!mounted) return;

    setState(() {
      _filters = _filters.copyWith(
        country: defaults.country,
        city: defaults.city,
      );
      _currentPage = 1;
    });
  }

  void _scheduleApplyDefaultCityFilter(HomeLocationProvider provider) {
    if (_hasAppliedDefaultCityFilter) {
      return;
    }
    if (_filters.country != null || _filters.city != null) {
      _hasAppliedDefaultCityFilter = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final wasApplied = _hasAppliedDefaultCityFilter;
      _applyDefaultCityFilter(provider);
      if (!wasApplied && _hasAppliedDefaultCityFilter) {
        unawaited(_loadGuides(page: 1));
      }
    });
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      final next = _searchController.text.trim();
      if (next == _searchQuery) return;
      setState(() {
        _searchQuery = next;
        _currentPage = 1;
      });
      _loadGuides(page: 1);
    });
  }

  Future<void> _loadGuides({int page = 1}) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final normalizedPage = page < 1 ? 1 : page;
    final requestId = ++_loadGuidesRequestId;
    final hadGuides = _guides.isNotEmpty;
    setState(() {
      _loading = !hadGuides;
      _isRefreshingList = hadGuides;
      _error = null;
    });

    try {
      final result = await _api.listPublicGuides(
        limit: _pageSize,
        offset: (normalizedPage - 1) * _pageSize,
        query: _backendSearchQuery(l10n),
        sort: _sortQuery,
        minRating: _filters.minRating,
        minExperienceYears: _filters.minExperienceYears,
        cityId: _filters.city?.cityId,
        cityName: _filters.city?.cityName,
        cityCountryCode: _filters.city?.countryCode,
        countryCodes: _filters.countryCodes,
        languageCodes: _filters.languageCodes,
        specializationCodes: _filters.specializations,
      );
      if (!mounted || requestId != _loadGuidesRequestId) return;
      final totalPages = math.max(1, (result.total / _pageSize).ceil());
      if (result.total > 0 && normalizedPage > totalPages) {
        await _loadGuides(page: totalPages);
        return;
      }
      setState(() {
        _guides = result.items;
        _totalGuides = result.total;
        _loading = false;
        _isRefreshingList = false;
        _currentPage = normalizedPage;
      });
    } catch (_) {
      if (!mounted || requestId != _loadGuidesRequestId) return;
      setState(() {
        _error = 'load_failed';
        _loading = false;
        _isRefreshingList = false;
      });
      if (_guides.isNotEmpty) {
        await showErrorDialog(
          context,
          title: l10n.error,
          message: l10n.guidesLoadFailed,
        );
      }
    }
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    if (_searchQuery.isEmpty && _currentPage == 1) return;
    setState(() {
      _searchQuery = '';
      _currentPage = 1;
    });
    _loadGuides(page: 1);
  }

  void _clearFilters() {
    if (_filters.activeCount == 0 && _currentPage == 1) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _filters = const _GuideFilters();
      _currentPage = 1;
    });
    _loadGuides(page: 1);
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  void _onSortTap(_GuideSortMode mode) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (_sortMode == mode) {
        _sortDirection = _sortDirection == _GuideSortDirection.asc
            ? _GuideSortDirection.desc
            : _GuideSortDirection.asc;
      } else {
        _sortMode = mode;
        _sortDirection = mode.defaultDirection;
      }
      _currentPage = 1;
    });
    _loadGuides(page: 1);
  }

  Future<void> _showFilters() async {
    FocusScope.of(context).unfocus();
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final selected = await showAppModalBottomSheet<_GuideFilters>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: AppDesignSystem.colorsFor(context).transparent,
      builder: (context) => _GuidesFiltersSheet(
        initialFilters: _filters,
        filterOptions: _filterOptions,
        fallbackResultCount: _totalGuides,
        resultCountLoader: (filters) async {
          final result = await _api.listPublicGuides(
            limit: 1,
            offset: 0,
            query: _backendSearchQuery(l10n),
            sort: _sortQuery,
            minRating: filters.minRating,
            minExperienceYears: filters.minExperienceYears,
            cityId: filters.city?.cityId,
            cityName: filters.city?.cityName,
            cityCountryCode: filters.city?.countryCode,
            countryCodes: filters.countryCodes,
            languageCodes: filters.languageCodes,
            specializationCodes: filters.specializations,
          );
          return result.total;
        },
      ),
    );

    if (selected == null || !mounted) return;
    setState(() {
      _filters = selected;
      _currentPage = 1;
    });
    await _loadGuides(page: 1);
  }

  void _openProfile(PublicGuideVm guide) {
    final userId = guide.userId.trim();
    if (userId.isEmpty) return;
    context.push('/users/${Uri.encodeComponent(userId)}/profile');
  }

  Future<void> _handlePageChanged(int page) async {
    if (page == _currentPage) return;
    FocusScope.of(context).unfocus();
    setState(() => _currentPage = page);
    await _loadGuides(page: page);
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = context.watch<HomeLocationProvider>();
    final totalPages = math.max(1, (_totalGuides / _pageSize).ceil());
    final activePage = _currentPage.clamp(1, totalPages).toInt();
    final pageGuides = _guides;
    final theme = AppDesignSystem.themeFor(context);
    final colors = AppDesignSystem.colorsFor(context);

    _scheduleApplyDefaultCityFilter(locationProvider);

    return Theme(
      data: theme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: colors.background,
          bottomNavigationBar: CommonBottomNavigationBar(
            onHomeTap: () => context.go('/'),
            onQrTap: () => context.push('/qr'),
            onMapTap: () => context.push('/map'),
            onServicesTap: () => context.push('/services'),
            onChatsTap: () => context.push('/chats'),
          ),
          body: DecoratedBox(
            decoration: AppBoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors.screenGradientColors,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  AppListScreenHeader(
                    title: l10n.guidesTitle,
                    notificationsTooltip: l10n.profileNotificationsRowTitle,
                    onBackTap: _goBack,
                    onNotificationsTap: () => context.push('/notifications'),
                  ),
                  Expanded(
                    child: _buildBody(
                      l10n: l10n,
                      pageGuides: pageGuides,
                      totalVisible: _totalGuides,
                      totalPages: totalPages,
                      activePage: activePage,
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

  Widget _buildBody({
    required AppLocalizations l10n,
    required List<PublicGuideVm> pageGuides,
    required int totalVisible,
    required int totalPages,
    required int activePage,
  }) {
    if (_loading && _guides.isEmpty) {
      return _buildInitialLoadingBody(l10n);
    }

    if (_error != null && _guides.isEmpty) {
      return ErrorView(
        message: l10n.guidesLoadFailed,
        onRetry: () => _loadGuides(page: _currentPage),
      );
    }

    final padX = _horizontalPadding(context);

    final colors = AppDesignSystem.colorsFor(context);

    return RefreshIndicator(
      color: colors.primary,
      backgroundColor: colors.surface,
      onRefresh: () => _loadGuides(page: _currentPage),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: AppEdgeInsets.fromLTRB(padX, 22, padX, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GuidesSearchField(
                    controller: _searchController,
                    hintText: l10n.guidesSearchHint,
                    onFilterTap: _showFilters,
                    onClear: _clearSearch,
                    activeFilterCount: _filters.activeCount,
                  ),
                  const SizedBox(height: 23),
                  _GuidesSortBar(
                    l10n: l10n,
                    selected: _sortMode,
                    direction: _sortDirection,
                    onChanged: _onSortTap,
                  ),
                ],
              ),
            ),
          ),
          if (_isRefreshingList)
            SliverPadding(
              padding: AppEdgeInsets.fromLTRB(padX, 14, padX, 0),
              sliver: SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: const AppBorderRadius.all(
                    AppRadiusValue.circular(999),
                  ),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: colors.primary,
                    backgroundColor: colors.surfaceHigh,
                  ),
                ),
              ),
            ),
          if (_error != null && _guides.isNotEmpty)
            SliverPadding(
              padding: AppEdgeInsets.fromLTRB(padX, 14, padX, 0),
              sliver: SliverToBoxAdapter(
                child: _GuidesInlineError(
                  message: l10n.guidesLoadFailed,
                  retryLabel: l10n.retryButton,
                  onRetry: () => _loadGuides(page: _currentPage),
                ),
              ),
            ),
          if (pageGuides.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _GuidesEmptyState(
                title: _searchQuery.isEmpty && _filters.activeCount == 0
                    ? l10n.guidesEmptyTitle
                    : l10n.guidesNoResultsTitle,
                subtitle: _searchQuery.isEmpty && _filters.activeCount == 0
                    ? l10n.guidesEmptySubtitle
                    : l10n.guidesNoResultsSubtitle,
                clearSearchLabel: l10n.guidesClearSearch,
                clearFiltersLabel: l10n.guidesFiltersClear,
                showClearFiltersAction: _filters.activeCount > 0,
                onClearSearch: _searchQuery.isEmpty ? null : _clearSearch,
                onClearFilters: _clearFilters,
              ),
            )
          else
            SliverPadding(
              padding: AppEdgeInsets.fromLTRB(padX, 28, padX, 24),
              sliver: _GuidesGrid(guides: pageGuides, onGuideTap: _openProfile),
            ),
          if (totalVisible > _pageSize)
            SliverToBoxAdapter(
              child: Padding(
                padding: AppEdgeInsets.fromLTRB(padX, 5, padX, 34),
                child: Column(
                  children: [
                    InflapPaginationBar(
                      currentPage: activePage,
                      totalPages: totalPages,
                      onPageChanged: _handlePageChanged,
                      showLabel: false,
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 18),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialLoadingBody(AppLocalizations l10n) {
    final padX = _horizontalPadding(context);

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: AppEdgeInsets.fromLTRB(padX, 22, padX, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GuidesSearchField(
                  controller: _searchController,
                  hintText: l10n.guidesSearchHint,
                  onFilterTap: _showFilters,
                  onClear: _clearSearch,
                  activeFilterCount: _filters.activeCount,
                ),
                const SizedBox(height: 23),
                _GuidesSortBar(
                  l10n: l10n,
                  selected: _sortMode,
                  direction: _sortDirection,
                  onChanged: _onSortTap,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: AppEdgeInsets.fromLTRB(padX, 28, padX, 24),
          sliver: const _GuidesSkeletonGrid(),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 18),
        ),
      ],
    );
  }

  String get _sortQuery => '${_sortMode.queryKey}_${_sortDirection.queryKey}';

  String _backendSearchQuery(AppLocalizations l10n) {
    final query = _searchQuery.trim();
    if (query.isEmpty) return query;

    for (final code in _filterOptions.specializationCodes) {
      if (guideSearchMatches(query, [
        code,
        localizedGuideSpecializationLabel(l10n, code),
      ])) {
        return code;
      }
    }

    for (final code in _filterOptions.languageCodes) {
      if (guideSearchMatches(query, [
        code,
        localizedGuideLanguageLabel(l10n, code),
        ..._filterOptions.languageAliases(code),
      ])) {
        return code;
      }
    }

    return query;
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 360) return 18;
    if (width >= 600) return 28;
    return 24;
  }
}

class _GuidesSearchField extends StatelessWidget {
  const _GuidesSearchField({
    required this.controller,
    required this.hintText,
    required this.onFilterTap,
    required this.onClear,
    required this.activeFilterCount,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onFilterTap;
  final VoidCallback onClear;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {
    return AppListSearchField(
      controller: controller,
      hintText: hintText,
      filterTooltip: AppLocalizations.of(context)!.guidesFiltersTitle,
      activeFilterCount: activeFilterCount,
      onFilterTap: onFilterTap,
      showClearButton: true,
      onClear: onClear,
    );
  }
}

class _GuidesSortBar extends StatelessWidget {
  const _GuidesSortBar({
    required this.l10n,
    required this.selected,
    required this.direction,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final _GuideSortMode selected;
  final _GuideSortDirection direction;
  final ValueChanged<_GuideSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return AppInlineSortRow<_GuideSortMode>(
      label: l10n.guidesSortLabel,
      options: [
        for (final mode in _GuideSortMode.values)
          AppInlineSortOption(value: mode, label: mode.label(l10n)),
      ],
      selectedValue: selected,
      isAscending: direction == _GuideSortDirection.asc,
      onSelected: onChanged,
      wrap: true,
      fontSize: 14,
      iconSize: 15,
      labelToOptionsGap: 14,
      optionGap: 18,
      letterSpacing: 0,
      labelColor: colors.textMuted,
      inactiveColor: colors.textSecondary,
    );
  }
}

int _guideGridColumnCount({required double width, required double textScale}) {
  if (textScale >= 1.3 && width < 600) return 1;
  if (width < 335) return 1;
  if (width >= 680) return 3;
  return 2;
}

class _GuidesGrid extends StatelessWidget {
  const _GuidesGrid({required this.guides, required this.onGuideTap});

  final List<PublicGuideVm> guides;
  final ValueChanged<PublicGuideVm> onGuideTap;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final columns = _guideGridColumnCount(
          width: constraints.crossAxisExtent,
          textScale: textScale,
        );
        final spacing = constraints.crossAxisExtent < 370 ? 12.0 : 16.0;
        final cardWidth =
            (constraints.crossAxisExtent - spacing * (columns - 1)) / columns;
        final imageHeight = (cardWidth * 0.82).clamp(118.0, 156.0);
        final cardHeight = imageHeight + _guideCardBodyHeight(context);

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 18,
            crossAxisSpacing: spacing,
            mainAxisExtent: cardHeight,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _GuideCard(
              guide: guides[index],
              imageHeight: imageHeight,
              onTap: () => onGuideTap(guides[index]),
            ),
            childCount: guides.length,
          ),
        );
      },
    );
  }
}

class _GuidesSkeletonGrid extends StatelessWidget {
  const _GuidesSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final columns = _guideGridColumnCount(
          width: constraints.crossAxisExtent,
          textScale: textScale,
        );
        final spacing = constraints.crossAxisExtent < 370 ? 12.0 : 16.0;
        final cardWidth =
            (constraints.crossAxisExtent - spacing * (columns - 1)) / columns;
        final imageHeight = (cardWidth * 0.82).clamp(118.0, 156.0);
        final cardHeight = imageHeight + _guideCardBodyHeight(context);

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 18,
            crossAxisSpacing: spacing,
            mainAxisExtent: cardHeight,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => const _GuideSkeletonCard(),
            childCount: columns * 3,
          ),
        );
      },
    );
  }
}

class _GuideSkeletonCard extends StatelessWidget {
  const _GuideSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.surface,
        borderRadius: AppBorderRadius.circular(22),
        border: Border.all(color: colors.borderSoft),
      ),
      child: ClipRRect(
        borderRadius: AppBorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: DecoratedBox(
                decoration: AppBoxDecoration(color: colors.surfaceHigh),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const AppEdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _GuideSkeletonLine(widthFactor: 0.72, height: 18),
                    SizedBox(height: 10),
                    _GuideSkeletonLine(widthFactor: 0.92, height: 12),
                    SizedBox(height: 9),
                    _GuideSkeletonLine(widthFactor: 0.54, height: 12),
                    Spacer(),
                    _GuideSkeletonLine(widthFactor: 1, height: 34),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideSkeletonLine extends StatelessWidget {
  const _GuideSkeletonLine({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: colors.textMuted.withValues(alpha: 0.16),
          borderRadius: AppBorderRadius.circular(999),
        ),
        child: SizedBox(height: height),
      ),
    );
  }
}

class _GuidesInlineError extends StatelessWidget {
  const _GuidesInlineError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.46),
        borderRadius: AppBorderRadius.circular(14),
        border: Border.all(color: colors.primary.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const AppEdgeInsetsDirectional.fromSTEB(14, 11, 10, 11),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: colors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}

const double _guideCardBodyMinHeight = 178;
const double _guideCardBodyHorizontalPadding = 15;
const double _guideCardBodyVerticalPadding = 12;
const double _guideCardNameFontSize = 18;
const double _guideCardNameLineHeight = 1.08;
const double _guideCardRoleFontSize = 13;
const double _guideCardRoleLineHeight = 1.18;
const double _guideCardLanguageFontSize = 14;
const double _guideCardLanguageLineHeight = 1.18;
const double _guideCardLanguageGap = 6;
const double _guideCardMetaFontSize = 12;
const double _guideCardMetaLineHeight = 1.15;
const double _guideCardButtonTopGap = 8;
const double _guideCardButtonMinHeight = 36;
const double _guideCardButtonHorizontalPadding = 12;
const double _guideCardButtonVerticalPadding = 8;
const double _guideCardButtonFontSize = 12;
const double _guideCardMinFlexibleGap = 4;

double _guideCardBodyHeight(BuildContext context) {
  final textScaler = MediaQuery.textScalerOf(context);
  final nameHeight =
      textScaler.scale(_guideCardNameFontSize) * _guideCardNameLineHeight;
  final languageHeight =
      textScaler.scale(_guideCardLanguageFontSize) *
      _guideCardLanguageLineHeight;
  final roleHeight =
      textScaler.scale(_guideCardRoleFontSize) * _guideCardRoleLineHeight;
  final metaHeight =
      textScaler.scale(_guideCardMetaFontSize) * _guideCardMetaLineHeight;
  final buttonHeight = math.max(
    _guideCardButtonMinHeight,
    textScaler.scale(_guideCardButtonFontSize) +
        _guideCardButtonVerticalPadding * 2,
  );

  final contentHeight =
      _guideCardBodyVerticalPadding * 2 +
      nameHeight +
      5 +
      roleHeight +
      _guideCardLanguageGap +
      languageHeight +
      7 +
      metaHeight +
      7 +
      metaHeight +
      _guideCardButtonTopGap +
      buttonHeight +
      _guideCardMinFlexibleGap;

  return math.max(_guideCardBodyMinHeight, contentHeight);
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.guide,
    required this.imageHeight,
    required this.onTap,
  });

  final PublicGuideVm guide;
  final double imageHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final languageLabel = guideExcursionLanguageLabel(l10n, guide);
    final roleLabel = guideRoleLabel(l10n, guide);
    final serviceLabel = guideServiceLabels(l10n, guide).take(2).join(' • ');
    final reviewLabel = guide.reviewsCount == 0
        ? l10n.guidesRatingNew
        : l10n.guidesReviewsCount(guide.reviewsCount);
    final experienceYears = guide.experienceYears;
    final metaLabel = [
      reviewLabel,
      if (experienceYears != null && experienceYears > 0)
        l10n.guidesExperienceYears(experienceYears),
    ].join(' • ');
    final avatarUrl = guide.avatarFileId == null
        ? null
        : resolvePublicFileContentUrl(guide.avatarFileId!);
    final semanticsLabel = [
      guide.preferredName,
      if (roleLabel.isNotEmpty) roleLabel,
      if (languageLabel.isNotEmpty) languageLabel,
      metaLabel,
      if (serviceLabel.isNotEmpty) serviceLabel,
      l10n.guidesViewProfile,
    ].join(', ');

    return Semantics(
      button: true,
      label: semanticsLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: colors.transparent,
          child: InkWell(
            onTap: onTap,
            excludeFromSemantics: true,
            borderRadius: AppBorderRadius.circular(22),
            child: Ink(
              decoration: AppBoxDecoration(
                color: colors.surface,
                borderRadius: AppBorderRadius.circular(22),
                border: Border.all(color: colors.borderSoft),
              ),
              child: ClipRRect(
                borderRadius: AppBorderRadius.circular(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: imageHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (avatarUrl != null)
                            Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              cacheWidth: _imageCacheWidth(context),
                              filterQuality: FilterQuality.medium,
                              loadingBuilder: (context, child, progress) =>
                                  progress == null
                                  ? child
                                  : _GuideFallbackArt(initials: guide.initials),
                              errorBuilder: (_, _, _) =>
                                  _GuideFallbackArt(initials: guide.initials),
                            )
                          else
                            _GuideFallbackArt(initials: guide.initials),
                          DecoratedBox(
                            decoration: AppBoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  colors.transparent,
                                  colors.black.withValues(alpha: 0.52),
                                ],
                                stops: [0.55, 1.0],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 13,
                            right: 12,
                            child: _RatingBadge(rating: guide.ratingAvg),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const AppEdgeInsets.symmetric(
                          horizontal: _guideCardBodyHorizontalPadding,
                          vertical: _guideCardBodyVerticalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              guide.preferredName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle(
                                color: colors.textPrimary,
                                fontSize: _guideCardNameFontSize,
                                fontWeight: FontWeight.w900,
                                height: _guideCardNameLineHeight,
                                letterSpacing: 0,
                              ),
                            ),
                            if (roleLabel.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                roleLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle(
                                  color: colors.textSecondary,
                                  fontSize: _guideCardRoleFontSize,
                                  fontWeight: FontWeight.w700,
                                  height: _guideCardRoleLineHeight,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                            if (languageLabel.isNotEmpty) ...[
                              const SizedBox(height: _guideCardLanguageGap),
                              Text(
                                languageLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle(
                                  color: colors.textSecondary,
                                  fontSize: _guideCardLanguageFontSize,
                                  fontWeight: FontWeight.w500,
                                  height: _guideCardLanguageLineHeight,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                            const SizedBox(height: 7),
                            Text(
                              metaLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle(
                                color: colors.textMuted,
                                fontSize: _guideCardMetaFontSize,
                                fontWeight: FontWeight.w800,
                                height: _guideCardMetaLineHeight,
                                letterSpacing: 0,
                              ),
                            ),
                            if (serviceLabel.isNotEmpty) ...[
                              const SizedBox(height: 7),
                              Text(
                                serviceLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle(
                                  color: colors.textMuted,
                                  fontSize: _guideCardMetaFontSize,
                                  fontWeight: FontWeight.w700,
                                  height: _guideCardMetaLineHeight,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                            const Spacer(),
                            const SizedBox(height: _guideCardButtonTopGap),
                            _ViewProfileButton(label: l10n.guidesViewProfile),
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
  }

  int _imageCacheWidth(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
    return (190 * dpr).round();
  }
}

class _GuideFallbackArt extends StatelessWidget {
  const _GuideFallbackArt({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surfaceTeal, colors.surfaceWarm, colors.surfaceHigh],
        ),
      ),
      child: Center(
        child: Container(
          width: 78,
          height: 78,
          decoration: AppBoxDecoration(
            color: colors.black.withValues(alpha: 0.22),
            shape: BoxShape.circle,
            border: Border.all(color: colors.borderSecondary),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: AppTextStyle(
              color: colors.textPrimary,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Container(
      height: 30,
      padding: const AppEdgeInsets.symmetric(horizontal: 10),
      decoration: AppBoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: AppBorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: colors.primary, size: 18),
          const SizedBox(width: 4),
          Text(
            (rating <= 0 ? 5.0 : rating).toStringAsFixed(1),
            style: AppTextStyle(
              color: colors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewProfileButton extends StatelessWidget {
  const _ViewProfileButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Container(
      constraints: const BoxConstraints(minHeight: _guideCardButtonMinHeight),
      alignment: Alignment.center,
      decoration: AppBoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.38),
        borderRadius: AppBorderRadius.circular(9),
      ),
      padding: const AppEdgeInsets.symmetric(
        horizontal: _guideCardButtonHorizontalPadding,
        vertical: _guideCardButtonVerticalPadding,
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTextStyle(
          color: colors.primary,
          fontSize: _guideCardButtonFontSize,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: 1.7,
        ),
      ),
    );
  }
}

class _GuidesEmptyState extends StatelessWidget {
  const _GuidesEmptyState({
    required this.title,
    required this.subtitle,
    required this.clearSearchLabel,
    required this.clearFiltersLabel,
    required this.showClearFiltersAction,
    this.onClearSearch,
    this.onClearFilters,
  });

  final String title;
  final String subtitle;
  final String clearSearchLabel;
  final String clearFiltersLabel;
  final bool showClearFiltersAction;
  final VoidCallback? onClearSearch;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final actions = [
      if (onClearSearch != null)
        _GuidesEmptyAction(label: clearSearchLabel, onPressed: onClearSearch!),
      if (showClearFiltersAction && onClearFilters != null)
        _GuidesEmptyAction(
          label: clearFiltersLabel,
          onPressed: onClearFilters!,
        ),
    ];

    return Padding(
      padding: const AppEdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_outlined, color: colors.primary, size: 56),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyle(
              color: colors.textSecondary,
              fontSize: 15,
              height: 1.35,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

class _GuidesEmptyAction extends StatelessWidget {
  const _GuidesEmptyAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.primary.withValues(alpha: 0.42)),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.circular(12),
        ),
      ),
      child: Text(label),
    );
  }
}

class _GuideFilters {
  const _GuideFilters({
    this.country,
    this.city,
    this.specializations = const <String>{},
    this.languageCodes = const <String>{},
    this.minRating,
    this.minExperienceYears,
  });

  final AppCountryFilterValue? country;
  final AppCityFilterValue? city;
  final Set<String> specializations;
  final Set<String> languageCodes;
  final double? minRating;
  final int? minExperienceYears;

  List<String> get countryCodes {
    final code = country?.countryCode ?? city?.countryCode;
    final normalizedCode = code?.trim().toUpperCase();
    if (normalizedCode == null || normalizedCode.isEmpty) {
      return const <String>[];
    }
    return <String>[normalizedCode];
  }

  _GuideFilters copyWith({
    Object? country = _unset,
    Object? city = _unset,
    Set<String>? specializations,
    Set<String>? languageCodes,
    double? minRating,
    bool clearMinRating = false,
    int? minExperienceYears,
    bool clearMinExperienceYears = false,
  }) {
    return _GuideFilters(
      country: identical(country, _unset)
          ? this.country
          : country as AppCountryFilterValue?,
      city: identical(city, _unset) ? this.city : city as AppCityFilterValue?,
      specializations: specializations ?? this.specializations,
      languageCodes: languageCodes ?? this.languageCodes,
      minRating: clearMinRating ? null : minRating ?? this.minRating,
      minExperienceYears: clearMinExperienceYears
          ? null
          : minExperienceYears ?? this.minExperienceYears,
    );
  }

  static const Object _unset = Object();

  int get activeCount =>
      (country == null ? 0 : 1) +
      (city == null ? 0 : 1) +
      specializations.length +
      languageCodes.length +
      (minRating == null ? 0 : 1) +
      (minExperienceYears == null ? 0 : 1);
}

class _GuidesFiltersSheet extends StatefulWidget {
  const _GuidesFiltersSheet({
    required this.initialFilters,
    required this.filterOptions,
    required this.fallbackResultCount,
    required this.resultCountLoader,
  });

  final _GuideFilters initialFilters;
  final GuideFilterOptions filterOptions;
  final int fallbackResultCount;
  final Future<int> Function(_GuideFilters filters) resultCountLoader;

  @override
  State<_GuidesFiltersSheet> createState() => _GuidesFiltersSheetState();
}

class _GuidesFiltersSheetState extends State<_GuidesFiltersSheet> {
  static const _ratings = [4.0, 4.5, 5.0];
  static const _experienceYears = [1, 3, 5];

  late _GuideFilters _filters;
  late final TextEditingController _languageSearchController;
  Timer? _resultCountDebounce;
  int? _resultCount;
  bool _isLoadingResultCount = false;
  int _resultCountRequestId = 0;
  String _languageSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _languageSearchController = TextEditingController()
      ..addListener(_handleLanguageSearchChanged);
    _resultCount = widget.fallbackResultCount;
    _loadResultCount();
  }

  @override
  void dispose() {
    _resultCountDebounce?.cancel();
    _languageSearchController
      ..removeListener(_handleLanguageSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleLanguageSearchChanged() {
    final nextQuery = _languageSearchController.text.trim();
    if (nextQuery == _languageSearchQuery) return;

    setState(() => _languageSearchQuery = nextQuery);
  }

  void _clear() {
    _languageSearchController.clear();
    _setFilters(const _GuideFilters());
  }

  void _toggleSpecialization(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('-', '_');
    final next = Set<String>.of(_filters.specializations);
    if (!next.remove(normalized)) next.add(normalized);
    _setFilters(_filters.copyWith(specializations: next));
  }

  void _selectLanguage(String code) {
    final normalized = code.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final selectedCode = _filters.languageCodes.contains(normalized)
        ? null
        : normalized;
    _languageSearchController.clear();
    _setFilters(
      _filters.copyWith(
        languageCodes: selectedCode == null ? const <String>{} : {selectedCode},
      ),
    );
  }

  void _setRating(double rating) {
    _setFilters(
      _filters.copyWith(
        minRating: rating,
        clearMinRating: _filters.minRating == rating,
      ),
    );
  }

  void _setExperience(int years) {
    _setFilters(
      _filters.copyWith(
        minExperienceYears: years,
        clearMinExperienceYears: _filters.minExperienceYears == years,
      ),
    );
  }

  void _setCity(AppCityFilterValue? city) {
    _setFilters(_filters.copyWith(city: city));
  }

  void _setCountry(AppCountryFilterValue? country) {
    _setFilters(_filters.copyWith(country: country, city: null));
  }

  void _setFilters(_GuideFilters filters) {
    setState(() => _filters = filters);
    _scheduleResultCountLoad();
  }

  void _scheduleResultCountLoad() {
    _resultCountDebounce?.cancel();
    _resultCountDebounce = Timer(
      const Duration(milliseconds: 180),
      _loadResultCount,
    );
  }

  Future<void> _loadResultCount() async {
    final requestId = ++_resultCountRequestId;
    setState(() => _isLoadingResultCount = true);
    try {
      final count = await widget.resultCountLoader(_filters);
      if (!mounted || requestId != _resultCountRequestId) return;
      setState(() {
        _resultCount = count;
        _isLoadingResultCount = false;
      });
    } catch (_) {
      if (!mounted || requestId != _resultCountRequestId) return;
      setState(() => _isLoadingResultCount = false);
    }
  }

  String? _selectedLanguage(AppLocalizations l10n) {
    if (_filters.languageCodes.isEmpty) return null;
    return localizedGuideLanguageLabel(l10n, _filters.languageCodes.first);
  }

  List<String> _visibleLanguages(AppLocalizations l10n) {
    final query = _languageSearchQuery.trim();
    if (query.isEmpty) return const [];

    return widget.filterOptions.languageCodes
        .where(
          (code) =>
              guideSearchMatches(query, _languageSearchHaystack(l10n, code)),
        )
        .toList(growable: false);
  }

  List<String> _languageSearchHaystack(AppLocalizations l10n, String code) {
    final aliases = widget.filterOptions.languageAliases(code);
    return [code, localizedGuideLanguageLabel(l10n, code), ...aliases];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final resultCount = _resultCount ?? widget.fallbackResultCount;
    final selectedLanguage = _selectedLanguage(l10n);
    final visibleLanguages = _visibleLanguages(l10n);

    return AppModalSheetFrame(
      onTapOutside: () => Navigator.of(context).maybePop(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
          maxWidth: 520,
        ),
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            color: colors.surface,
            borderRadius: const AppBorderRadius.vertical(
              top: AppRadiusValue.circular(24),
            ),
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppFilterSheetHeader(
                title: l10n.guidesFiltersTitle,
                clearLabel: l10n.guidesFiltersClear,
                onClear: _clear,
                height: 74,
                horizontalPadding: 22,
                titleFontSize: 18,
              ),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const AppEdgeInsets.fromLTRB(22, 28, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCountryFilterSection(
                        title: l10n.guidesFilterCountry,
                        allCountriesLabel: l10n.guidesFilterCountryAll,
                        searchHint: l10n.guidesFilterCountrySearchHint,
                        noResultsText: l10n.guidesFilterCountryNoResults,
                        selectedCountry: _filters.country,
                        onChanged: _setCountry,
                      ),
                      if (_filters.country != null) ...[
                        const SizedBox(height: 30),
                        AppCityFilterSection(
                          title: l10n.locationFilterCitySection,
                          allCitiesLabel: l10n.locationFilterAllCities,
                          searchHint: l10n.locationFilterCitySearchHint,
                          noResultsText: l10n.locationFilterCityNoResults,
                          selectedCity: _filters.city,
                          onChanged: _setCity,
                          countryCode: _filters.country?.countryCode,
                        ),
                      ],
                      const SizedBox(height: 30),
                      _GuideFilterSection(
                        title: l10n.guidesFilterExpertise,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final code
                                in widget.filterOptions.specializationCodes)
                              _GuideFilterChip(
                                label: localizedGuideSpecializationLabel(
                                  l10n,
                                  code,
                                ),
                                selected: _filters.specializations.contains(
                                  code,
                                ),
                                onTap: () => _toggleSpecialization(code),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      _GuideFilterSection(
                        title: l10n.guidesFilterLanguage,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DecoratedBox(
                              decoration: AppBoxDecoration(
                                color: colors.surfaceHigh,
                                borderRadius: AppBorderRadius.circular(16),
                                border: Border.all(color: colors.borderSoft),
                              ),
                              child: Padding(
                                padding: const AppEdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.translate_rounded,
                                      color: colors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        selectedLanguage ??
                                            l10n.guidesFilterLanguageAll,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyle(
                                          color: colors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (_filters.languageCodes.isNotEmpty)
                                      IconButton(
                                        tooltip: l10n.guidesFiltersClear,
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _setFilters(
                                          _filters.copyWith(
                                            languageCodes: const <String>{},
                                          ),
                                        ),
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: colors.textMuted,
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _languageSearchController,
                              cursorColor: colors.primary,
                              style: AppTextStyle(
                                color: colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: AppInputDecoration(
                                hintText: l10n.guidesFilterLanguageSearchHint,
                                hintStyle: AppTextStyle(
                                  color: colors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: colors.primary,
                                ),
                                filled: true,
                                fillColor: colors.surfaceRaised,
                                contentPadding: const AppEdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: AppBorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppBorderRadius.circular(16),
                                  borderSide: BorderSide(color: colors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppBorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: colors.primary,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            if (_languageSearchQuery.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              if (visibleLanguages.isEmpty)
                                Text(
                                  l10n.guidesFilterLanguageNoResults,
                                  style: AppTextStyle(
                                    color: colors.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    for (final code in visibleLanguages) ...[
                                      _GuideLanguageOptionRow(
                                        label: localizedGuideLanguageLabel(
                                          l10n,
                                          code,
                                        ),
                                        code: code.toUpperCase(),
                                        selected: _filters.languageCodes
                                            .contains(code),
                                        onTap: () => _selectLanguage(code),
                                      ),
                                      if (code != visibleLanguages.last)
                                        const SizedBox(height: 8),
                                    ],
                                  ],
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      _GuideFilterSection(
                        title: l10n.guidesFilterRating,
                        child: _GuideSegmentGrid<double>(
                          items: [
                            for (final rating in _ratings)
                              _GuideSegmentItem(
                                value: rating,
                                label: l10n.guidesFilterRatingAtLeast(
                                  rating.toStringAsFixed(1),
                                ),
                              ),
                          ],
                          selectedValue: _filters.minRating,
                          onSelected: _setRating,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _GuideFilterSection(
                        title: l10n.guidesFilterExperience,
                        child: _GuideSegmentGrid<int>(
                          items: [
                            for (final years in _experienceYears)
                              _GuideSegmentItem(
                                value: years,
                                label: l10n.guidesExperienceYears(years),
                              ),
                          ],
                          selectedValue: _filters.minExperienceYears,
                          onSelected: _setExperience,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: AppEdgeInsets.fromLTRB(22, 0, 22, bottomInset + 18),
                child: AppFilterApplyButton(
                  label: l10n.guidesFiltersShowResults(resultCount),
                  onTap: () => Navigator.of(context).pop(_filters),
                  borderRadius: 14,
                  fontSize: 15,
                  isLoading: _isLoadingResultCount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideFilterSection extends StatelessWidget {
  const _GuideFilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTextStyle(
            color: colors.textPrimary,
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

class _GuideFilterChip extends StatelessWidget {
  const _GuideFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 42),
          padding: const AppEdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: AppBoxDecoration(
            color: selected ? colors.primary : colors.surfaceHigh,
            borderRadius: AppBorderRadius.circular(999),
            border: Border.all(
              color: selected ? colors.primary : colors.borderSoft,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle(
              color: selected ? colors.textPrimary : colors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideLanguageOptionRow extends StatelessWidget {
  const _GuideLanguageOptionRow({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.circular(14),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.18)
              : colors.surfaceHigh,
          borderRadius: AppBorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.primary : colors.borderSoft,
          ),
        ),
        child: Padding(
          padding: const AppEdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                code,
                style: AppTextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
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

class _GuideSegmentItem<T> {
  const _GuideSegmentItem({required this.value, required this.label});

  final T value;
  final String label;
}

class _GuideSegmentGrid<T> extends StatelessWidget {
  const _GuideSegmentGrid({
    required this.items,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<_GuideSegmentItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn = constraints.maxWidth < 330;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final contentExtent = 14 * textScale * 1.15 * 2 + 16;
        final itemExtent = contentExtent < 48 ? 48.0 : contentExtent;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: useSingleColumn ? 1 : 2,
            mainAxisExtent: itemExtent,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _GuideSegmentButton(
              label: item.label,
              selected: item.value == selectedValue,
              onTap: () => onSelected(item.value),
            );
          },
        );
      },
    );
  }
}

class _GuideSegmentButton extends StatelessWidget {
  const _GuideSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          padding: const AppEdgeInsets.symmetric(horizontal: 10),
          decoration: AppBoxDecoration(
            color: selected ? colors.primary : colors.surfaceHigh,
            borderRadius: AppBorderRadius.circular(10),
            border: Border.all(
              color: selected ? colors.primary : colors.borderSoft,
            ),
          ),
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle(
              color: selected ? colors.textPrimary : colors.textSecondary,
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
