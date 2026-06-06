import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_inline_sort_row.dart';
import '../../core/ui/app_list_search_field.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/pagination_bar.dart';
import '../../features/attractions/attraction_ui.dart';
import '../../features/attractions/data/attraction_api.dart';
import '../../features/attractions/models/attraction_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/home_location_provider.dart';
import '../../shared/widgets/app_city_filter_section.dart';
import '../../shared/widgets/app_localized_location_text.dart';
import 'attractions_filter_sheet.dart';

enum _AttractionSortField { rating, duration, price }

enum _AttractionSortDirection { asc, desc }

extension _AttractionSortFieldX on _AttractionSortField {
  String label(AppLocalizations l10n) {
    switch (this) {
      case _AttractionSortField.rating:
        return l10n.attractionsSortRating;
      case _AttractionSortField.duration:
        return l10n.attractionsSortDuration;
      case _AttractionSortField.price:
        return l10n.attractionsSortPrice;
    }
  }

  _AttractionSortDirection get defaultDirection {
    switch (this) {
      case _AttractionSortField.rating:
        return _AttractionSortDirection.desc;
      case _AttractionSortField.duration:
      case _AttractionSortField.price:
        return _AttractionSortDirection.asc;
    }
  }

  String queryParam(_AttractionSortDirection direction) {
    final suffix = direction == _AttractionSortDirection.asc ? 'asc' : 'desc';
    switch (this) {
      case _AttractionSortField.rating:
        return 'rating_$suffix';
      case _AttractionSortField.duration:
        return 'duration_$suffix';
      case _AttractionSortField.price:
        return 'price_$suffix';
    }
  }
}

class AttractionsScreen extends StatefulWidget {
  const AttractionsScreen({super.key});

  @override
  State<AttractionsScreen> createState() => _AttractionsScreenState();
}

class _AttractionsScreenState extends State<AttractionsScreen> {
  static const int _pageSize = 24;

  final AttractionApi _api = AttractionApi();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<AttractionVm> _attractions = [];
  bool _loading = true;
  bool _hasAppliedDefaultLocationFilter = false;
  String? _error;
  AttractionFilterResult _filters = AttractionFilterResult.empty;
  Timer? _searchDebounce;
  int _currentPage = 1;
  int _totalAttractions = 0;
  _AttractionSortField _sortField = _AttractionSortField.rating;
  _AttractionSortDirection _sortDirection = _AttractionSortDirection.desc;

  int get _totalPages {
    final pages = (_totalAttractions / _pageSize).ceil();
    return pages < 1 ? 1 : pages;
  }

  String get _sortQueryParam => _sortField.queryParam(_sortDirection);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapAttractions());
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _loadAttractions(page: 1),
    );
  }

  Future<void> _bootstrapAttractions() async {
    await _initializeDefaultLocationFilter();
    if (!mounted) return;
    await _loadAttractions();
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
    if (_hasAppliedDefaultLocationFilter ||
        _filters.country != null ||
        _filters.city != null) {
      return;
    }

    final location = provider.effectiveLocation;
    if (location.source == HomeLocationSource.fallback) return;

    _hasAppliedDefaultLocationFilter = true;

    final defaultCountry = AppCountryFilterValue.fromParts(
      countryCode: location.countryCode,
    );
    final defaultCity = defaultCountry == null
        ? null
        : AppCityFilterValue.fromParts(
            cityId: location.cityId,
            cityName: location.cityName,
            countryCode: location.countryCode,
          );
    if (defaultCountry == null && defaultCity == null) return;

    setState(() {
      _filters = _filters.copyWith(country: defaultCountry, city: defaultCity);
      _currentPage = 1;
    });
  }

  Future<void> _loadAttractions({int page = 1}) async {
    if (!mounted) return;
    final normalizedPage = page < 1 ? 1 : page;
    setState(() {
      _loading = _attractions.isEmpty;
      _error = null;
    });

    try {
      final locale = Localizations.localeOf(context).languageCode;
      final search = _searchController.text.trim();
      final result = await _api.getAttractions(
        search: search.isEmpty ? null : search,
        countryCode: _filters.countryCode,
        cityId: _filters.cityId,
        category: _filters.category,
        minRating: _filters.minRating,
        priceMin: _filters.priceMin,
        priceMax: _filters.priceMax,
        durationMin: _filters.durationMin,
        durationMax: _filters.durationMax,
        durationUnit: _filters.durationUnit,
        sort: _sortQueryParam,
        locale: locale,
        limit: _pageSize,
        offset: (normalizedPage - 1) * _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _attractions = result.items;
        _totalAttractions = result.total;
        _currentPage = result.total == 0 ? 1 : normalizedPage;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'load_failed';
        _loading = false;
      });
    }
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();

    final result = await showModalBottomSheet<AttractionFilterResult>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttractionsFilterSheet(
        initial: _filters,
        api: _api,
        searchQuery: _searchController.text,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _filters = result);
    _loadAttractions(page: 1);
  }

  void _handleSortSelected(_AttractionSortField field) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (_sortField == field) {
        _sortDirection = _sortDirection == _AttractionSortDirection.asc
            ? _AttractionSortDirection.desc
            : _AttractionSortDirection.asc;
      } else {
        _sortField = field;
        _sortDirection = field.defaultDirection;
      }
    });
    _loadAttractions(page: 1);
  }

  Future<void> _refreshAttractions() {
    return _loadAttractions(page: _currentPage);
  }

  Future<void> _handlePageChanged(int page) async {
    if (page == _currentPage || _loading) return;
    FocusScope.of(context).unfocus();
    await _loadAttractions(page: page);
    if (!mounted || !_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _openDetails(AttractionVm attraction) {
    context.push('/attractions/${attraction.id}', extra: attraction);
  }

  AppCityFilterValue? _currentCityValue(HomeLocationProvider provider) {
    if (_filters.city != null) return _filters.city;

    final location = provider.effectiveLocation;
    return AppCityFilterValue.fromParts(
      cityId: location.cityId,
      cityName: location.cityName,
      countryCode: location.countryCode,
    );
  }

  List<AttractionVm> _mustVisitAttractions(AppCityFilterValue? city) {
    if (city == null || _attractions.isEmpty) return const [];

    final currentCityItems =
        _attractions
            .where(
              (item) => city.matches(
                cityId: item.cityId,
                countryCode: item.countryCode,
              ),
            )
            .toList()
          ..sort((a, b) {
            final ratingCompare = b.rating.compareTo(a.rating);
            if (ratingCompare != 0) return ratingCompare;
            return b.reviewCount.compareTo(a.reviewCount);
          });

    return currentCityItems.take(5).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return AttractionTextScale(
      child: Builder(
        builder: (context) {
          final adaptive = AttractionAdaptive.of(context);
          final l10n = AppLocalizations.of(context)!;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: const Color(0xFF201407),
              bottomNavigationBar: CommonBottomNavigationBar(
                onHomeTap: () => context.go('/'),
                onQrTap: () => context.push('/qr'),
                onMapTap: () => context.push('/map'),
                onServicesTap: () => context.push('/services'),
                onChatsTap: () => context.push('/chats'),
              ),
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildHeader(l10n),
                    _buildSearchBar(adaptive, l10n),
                    Expanded(child: _buildBody(adaptive, l10n)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return AppListScreenHeader(
      title: l10n.attractionsTitle,
      notificationsTooltip: l10n.profileNotificationsRowTitle,
      onBackTap: _onBack,
      onNotificationsTap: () => context.push('/notifications'),
    );
  }

  Widget _buildSearchBar(AttractionAdaptive a, AppLocalizations l10n) {
    final activeFilterCount = _filters.activeCount;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        a.scale(24, minFactor: 0.78),
        a.scale(22),
        a.scale(24, minFactor: 0.78),
        0,
      ),
      child: AppListSearchField(
        controller: _searchController,
        hintText: l10n.attractionsSearchHint,
        filterTooltip: l10n.attractionsFiltersTitle,
        activeFilterCount: activeFilterCount,
        onFilterTap: _openFilters,
        onSubmitted: (_) => _loadAttractions(page: 1),
      ),
    );
  }

  Widget _buildBody(AttractionAdaptive a, AppLocalizations l10n) {
    if (_loading && _attractions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null && _attractions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.attractionsLoadFailed,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: a.scale(12)),
            TextButton(
              onPressed: () => _loadAttractions(page: _currentPage),
              child: Text(
                l10n.retryButton,
                style: const TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      );
    }

    final padX = a.scale(24, minFactor: 0.78);
    final locationProvider = context.watch<HomeLocationProvider>();
    final currentCity = _currentCityValue(locationProvider);
    final mustVisitAttractions = _mustVisitAttractions(currentCity);
    final search = _searchController.text.trim();
    final shouldShowMustVisit =
        _filters.isEmpty &&
        search.isEmpty &&
        currentCity != null &&
        mustVisitAttractions.isNotEmpty;

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: const Color(0xFF271609),
      onRefresh: _refreshAttractions,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                padX,
                a.scale(28, minFactor: 0.72),
                padX,
                a.scale(24, minFactor: 0.72),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shouldShowMustVisit)
                    _MustVisitSection(
                      l10n: l10n,
                      adaptive: a,
                      city: currentCity,
                      attractions: mustVisitAttractions,
                      onTap: _openDetails,
                    ),
                  if (shouldShowMustVisit)
                    SizedBox(height: a.scale(24, minFactor: 0.72)),
                  _AttractionSortBar(
                    l10n: l10n,
                    adaptive: a,
                    selectedField: _sortField,
                    direction: _sortDirection,
                    onFieldSelected: _handleSortSelected,
                  ),
                ],
              ),
            ),
          ),
          if (_attractions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: a.scale(40)),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: a.scale(24)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.attractionsNoResults,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: a.scale(8)),
                        Text(
                          l10n.attractionsNoResultsSubtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textCaption,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padX, 0, padX, a.scale(24)),
              sliver: _buildGrid(a, l10n),
            ),
          if (_attractions.isNotEmpty && _totalPages > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  padX,
                  a.scale(10, minFactor: 0.72),
                  padX,
                  a.scale(34, minFactor: 0.78),
                ),
                child: InflapPaginationBar(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onPageChanged: _handlePageChanged,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(AttractionAdaptive a, AppLocalizations l10n) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.crossAxisExtent < 330;
        final columns = isCompact ? 1 : 2;
        final spacing = a.scale(16, minFactor: 0.7);
        final cardWidth =
            (constraints.crossAxisExtent - spacing * (columns - 1)) / columns;
        final imageHeight = _discoverImageHeight(cardWidth);
        final cardHeight = imageHeight + a.scale(96, minFactor: 0.84);

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: a.scale(36, minFactor: 0.78),
            crossAxisSpacing: spacing,
            mainAxisExtent: cardHeight,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, i) => _DiscoverCard(
              attraction: _attractions[i],
              l10n: l10n,
              adaptive: a,
              onTap: _openDetails,
            ),
            childCount: _attractions.length,
          ),
        );
      },
    );
  }

  double _discoverImageHeight(double cardWidth) {
    return (cardWidth * 1.33).clamp(200.0, 230.0);
  }
}

class _MustVisitSection extends StatelessWidget {
  const _MustVisitSection({
    required this.l10n,
    required this.adaptive,
    required this.city,
    required this.attractions,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final AttractionAdaptive adaptive;
  final AppCityFilterValue city;
  final List<AttractionVm> attractions;
  final void Function(AttractionVm) onTap;

  @override
  Widget build(BuildContext context) {
    if (attractions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: adaptive.scale(32, minFactor: 0.86),
              height: adaptive.scale(32, minFactor: 0.86),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.accent,
                size: adaptive.scale(17, minFactor: 0.86),
              ),
            ),
            SizedBox(width: adaptive.scale(10, minFactor: 0.74)),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      l10n.attractionMustVisitBadge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: adaptive.scale(18, minFactor: 0.84),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        height: 1.08,
                      ),
                    ),
                  ),
                  SizedBox(width: adaptive.scale(8, minFactor: 0.72)),
                  Container(
                    width: adaptive.scale(4, minFactor: 0.72),
                    height: adaptive.scale(4, minFactor: 0.72),
                    decoration: const BoxDecoration(
                      color: AppColors.textCaption,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: adaptive.scale(8, minFactor: 0.72)),
                  Flexible(
                    child: AppLocalizedLocationText(
                      cityId: city.cityId,
                      cityName: city.cityName,
                      countryCode: city.countryCode,
                      fallbackText: city.fallbackLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: adaptive.scale(18, minFactor: 0.84),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        height: 1.08,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: adaptive.scale(14, minFactor: 0.72)),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth =
                (constraints.maxWidth * (adaptive.isVeryNarrow ? 0.78 : 0.68))
                    .clamp(174.0, 238.0)
                    .toDouble();

            return SingleChildScrollView(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (var i = 0; i < attractions.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: i == attractions.length - 1
                            ? 0
                            : adaptive.scale(12, minFactor: 0.72),
                      ),
                      child: _MustVisitCard(
                        attraction: attractions[i],
                        l10n: l10n,
                        adaptive: adaptive,
                        width: cardWidth,
                        onTap: onTap,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MustVisitCard extends StatelessWidget {
  const _MustVisitCard({
    required this.attraction,
    required this.l10n,
    required this.adaptive,
    required this.width,
    required this.onTap,
  });

  final AttractionVm attraction;
  final AppLocalizations l10n;
  final AttractionAdaptive adaptive;
  final double width;
  final void Function(AttractionVm) onTap;

  @override
  Widget build(BuildContext context) {
    final coverMedia = attraction.coverMedia;
    final imageTargetWidth = attractionImageTargetWidth(
      context,
      width,
      minWidth: 360,
      maxWidth: 620,
    );
    final coverUrl = coverMedia == null
        ? null
        : resolveAttractionMediaUrl(coverMedia, targetWidth: imageTargetWidth);

    return GestureDetector(
      onTap: () => onTap(attraction),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(adaptive.radius(16)),
              child: AspectRatio(
                aspectRatio: 1.42,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverUrl != null)
                      Image.network(
                        coverUrl,
                        headers: attractionImageRequestHeaders(coverUrl),
                        fit: BoxFit.cover,
                        cacheWidth: imageTargetWidth,
                        filterQuality: FilterQuality.medium,
                        gaplessPlayback: true,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return _placeholder();
                        },
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    else
                      _placeholder(),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.02),
                              Colors.black.withValues(alpha: 0.48),
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: adaptive.scale(8, minFactor: 0.78),
                      right: adaptive.scale(8, minFactor: 0.78),
                      child: _ratingBadge(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: adaptive.scale(10, minFactor: 0.72)),
            Text(
              attraction.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: adaptive.scale(15, minFactor: 0.86),
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                height: 1.12,
              ),
            ),
            SizedBox(height: adaptive.scale(4, minFactor: 0.72)),
            Text(
              _secondaryLabel(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textCaption,
                fontSize: adaptive.scale(12, minFactor: 0.86),
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                height: 1.18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _secondaryLabel(BuildContext context) {
    final duration = formatAttractionDurationLabel(l10n, attraction).trim();
    if (duration.isNotEmpty) return duration;
    return formatAttractionPriceLabel(context, l10n, attraction);
  }

  Widget _ratingBadge() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xD41B211F),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: adaptive.scale(8, minFactor: 0.78),
          vertical: adaptive.scale(5, minFactor: 0.78),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              color: AppColors.accent,
              size: adaptive.scale(13, minFactor: 0.82),
            ),
            SizedBox(width: adaptive.scale(2, minFactor: 0.72)),
            Text(
              attraction.rating.toStringAsFixed(1),
              style: TextStyle(
                color: AppColors.accent,
                fontSize: adaptive.scale(12, minFactor: 0.82),
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.white.withValues(alpha: 0.05),
    child: const Center(
      child: Icon(
        Icons.landscape_rounded,
        color: AppColors.textCaption,
        size: 34,
      ),
    ),
  );
}

class _AttractionSortBar extends StatelessWidget {
  const _AttractionSortBar({
    required this.l10n,
    required this.adaptive,
    required this.selectedField,
    required this.direction,
    required this.onFieldSelected,
  });

  final AppLocalizations l10n;
  final AttractionAdaptive adaptive;
  final _AttractionSortField selectedField;
  final _AttractionSortDirection direction;
  final ValueChanged<_AttractionSortField> onFieldSelected;

  @override
  Widget build(BuildContext context) {
    final fields = _AttractionSortField.values;
    final isAscending = direction == _AttractionSortDirection.asc;

    return AppInlineSortRow<_AttractionSortField>(
      label: l10n.attractionsSortLabel,
      options: [
        for (final field in fields)
          AppInlineSortOption(value: field, label: field.label(l10n)),
      ],
      selectedValue: selectedField,
      isAscending: isAscending,
      onSelected: onFieldSelected,
      fontSize: adaptive.scale(12, minFactor: 0.9),
      iconSize: adaptive.scale(14, minFactor: 0.86),
      labelToOptionsGap: adaptive.scale(18, minFactor: 0.72),
      optionGap: adaptive.scale(22, minFactor: 0.72),
      iconGap: adaptive.scale(5, minFactor: 0.72),
      verticalPadding: adaptive.scale(8, minFactor: 0.84),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    required this.attraction,
    required this.l10n,
    required this.adaptive,
    required this.onTap,
  });

  final AttractionVm attraction;
  final AppLocalizations l10n;
  final AttractionAdaptive adaptive;
  final void Function(AttractionVm) onTap;

  @override
  Widget build(BuildContext context) {
    final coverMedia = attraction.coverMedia;

    return GestureDetector(
      onTap: () => onTap(attraction),
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = (constraints.maxWidth * 1.33).clamp(200.0, 230.0);
          final imageTargetWidth = attractionImageTargetWidth(
            context,
            constraints.maxWidth,
            minWidth: 420,
            maxWidth: 720,
          );
          final coverUrl = coverMedia == null
              ? null
              : resolveAttractionMediaUrl(
                  coverMedia,
                  targetWidth: imageTargetWidth,
                );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(adaptive.radius(18)),
                child: SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (coverUrl != null)
                        Image.network(
                          coverUrl,
                          headers: attractionImageRequestHeaders(coverUrl),
                          fit: BoxFit.cover,
                          cacheWidth: imageTargetWidth,
                          filterQuality: FilterQuality.medium,
                          gaplessPlayback: true,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) {
                              return child;
                            }
                            return _placeholder();
                          },
                          errorBuilder: (_, _, _) => _placeholder(),
                        )
                      else
                        _placeholder(),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.42),
                              ],
                              stops: const [0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: adaptive.scale(8),
                        right: adaptive.scale(8),
                        child: _saveButton(),
                      ),
                      Positioned(
                        left: adaptive.scale(32, minFactor: 0.48),
                        bottom: adaptive.scale(28, minFactor: 0.5),
                        child: _categoryTag(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: adaptive.scale(16, minFactor: 0.72)),
              Text(
                attraction.title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: adaptive.scale(21, minFactor: 0.86),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: adaptive.scale(6)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatAttractionPriceLabel(context, l10n, attraction),
                      style: TextStyle(
                        color: const Color(0xFFC7B49F),
                        fontSize: adaptive.scale(17, minFactor: 0.82),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.star_rounded,
                    color: AppColors.accent,
                    size: adaptive.scale(18),
                  ),
                  SizedBox(width: adaptive.scale(2)),
                  Text(
                    attraction.rating.toStringAsFixed(1),
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: adaptive.scale(17, minFactor: 0.82),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _saveButton() {
    final size = adaptive.scale(42, minFactor: 0.86);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xB71B211F),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        Icons.bookmark_border_rounded,
        color: Colors.white,
        size: adaptive.scale(19, minFactor: 0.86),
      ),
    );
  }

  Widget _categoryTag() {
    return Container(
      height: adaptive.scale(23, minFactor: 0.84),
      padding: EdgeInsets.symmetric(horizontal: adaptive.scale(12)),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xB8554C24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _categoryLabel(attraction.category).toUpperCase(),
        style: TextStyle(
          color: AppColors.accent,
          fontSize: adaptive.scale(12, minFactor: 0.84),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    final normalized = category.trim().toUpperCase();
    switch (normalized) {
      case 'PARK':
      case 'PARKS':
        return l10n.attractionFilterCategoryParks;
      case 'MUSEUM':
      case 'MUSEUMS':
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
      case 'HISTORY':
        return l10n.attractionFilterCategoryHistory;
      case 'ADVENTURE':
        return l10n.attractionFilterCategoryAdventure;
    }
    if (normalized.isEmpty) return l10n.attractionFilterCategoryOther;
    return normalized
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.length == 1
              ? part
              : '${part.substring(0, 1)}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Widget _placeholder() => Container(
    color: Colors.white.withValues(alpha: 0.05),
    child: const Center(
      child: Icon(
        Icons.landscape_rounded,
        color: AppColors.textCaption,
        size: 48,
      ),
    ),
  );
}
