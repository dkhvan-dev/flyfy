import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_inline_sort_row.dart';
import '../../core/ui/app_list_search_field.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/pagination_bar.dart';
import '../../features/help_center/data/help_center_api.dart';
import '../../features/help_center/widgets/contextual_help_section.dart';
import '../../features/places/place_ui.dart';
import '../../features/places/data/place_api.dart';
import '../../features/places/models/place_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/currency_rate_provider.dart';
import '../../providers/home_location_provider.dart';
import '../../providers/session_provider.dart';
import '../../shared/location/home_location_filter_defaults.dart';
import '../../shared/widgets/app_city_filter_section.dart';
import '../../shared/widgets/app_localized_location_text.dart';
import 'places_filter_sheet.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

enum _PlaceSortField { rating, duration, price }

enum _PlaceSortDirection { asc, desc }

extension _PlaceSortFieldX on _PlaceSortField {
  String label(AppLocalizations l10n) {
    switch (this) {
      case _PlaceSortField.rating:
        return l10n.placesSortRating;
      case _PlaceSortField.duration:
        return l10n.placesSortDuration;
      case _PlaceSortField.price:
        return l10n.placesSortPrice;
    }
  }

  _PlaceSortDirection get defaultDirection {
    switch (this) {
      case _PlaceSortField.rating:
        return _PlaceSortDirection.desc;
      case _PlaceSortField.duration:
      case _PlaceSortField.price:
        return _PlaceSortDirection.asc;
    }
  }

  String queryParam(_PlaceSortDirection direction) {
    final suffix = direction == _PlaceSortDirection.asc ? 'asc' : 'desc';
    switch (this) {
      case _PlaceSortField.rating:
        return 'rating_$suffix';
      case _PlaceSortField.duration:
        return 'duration_$suffix';
      case _PlaceSortField.price:
        return 'price_$suffix';
    }
  }
}

LinearGradient? _placesCoverOverlayGradient(
  BuildContext context, {
  required double topAlpha,
  required double bottomAlpha,
  required double firstStop,
}) {
  if (Theme.of(context).brightness == Brightness.light) {
    return null;
  }

  final colors = AppDesignSystem.colorsFor(context);
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      colors.black.withValues(alpha: topAlpha),
      colors.black.withValues(alpha: bottomAlpha),
    ],
    stops: [firstStop, 1.0],
  );
}

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  static const int _pageSize = 24;

  final PlaceApi _api = PlaceApi();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<PlaceVm> _places = [];
  bool _loading = true;
  bool _hasAppliedDefaultLocationFilter = false;
  String? _error;
  PlaceFilterResult _filters = PlaceFilterResult.empty;
  Timer? _searchDebounce;
  int _loadRequestId = 0;
  int _currentPage = 1;
  int _totalPlaces = 0;
  _PlaceSortField _sortField = _PlaceSortField.rating;
  _PlaceSortDirection _sortDirection = _PlaceSortDirection.desc;

  int get _totalPages {
    final pages = (_totalPlaces / _pageSize).ceil();
    return pages < 1 ? 1 : pages;
  }

  String get _sortQueryParam => _sortField.queryParam(_sortDirection);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapPlaces());
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
      () => _loadPlaces(page: 1),
    );
  }

  void _submitPlaceSearch(String value) {
    _searchDebounce?.cancel();
    FocusScope.of(context).unfocus();
    unawaited(_loadPlaces(page: 1));
  }

  Future<void> _bootstrapPlaces() async {
    await _initializeDefaultLocationFilter();
    if (!mounted) return;
    await _loadPlaces();
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
      final wasApplied = _hasAppliedDefaultLocationFilter;
      _applyDefaultLocationFilter(provider);
      if (!wasApplied && _hasAppliedDefaultLocationFilter) {
        unawaited(_loadPlaces(page: 1));
      }
    });
  }

  Future<void> _loadPlaces({int page = 1}) async {
    if (!mounted) return;
    final requestId = ++_loadRequestId;
    final normalizedPage = page < 1 ? 1 : page;
    setState(() {
      _loading = _places.isEmpty;
      _error = null;
    });

    try {
      final locale = Localizations.localeOf(context).languageCode;
      final search = _searchController.text.trim();
      final result = await _api.getPlaces(
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
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _places = result.items;
        _totalPlaces = result.total;
        _currentPage = result.total == 0 ? 1 : normalizedPage;
        _loading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted || requestId != _loadRequestId) return;
      if (kDebugMode) {
        debugPrint('Places load failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      setState(() {
        _error = 'load_failed';
        _loading = false;
      });
    }
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();

    final result = await showAppModalBottomSheet<PlaceFilterResult>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.appColors.transparent,
      builder: (_) => PlacesFilterSheet(
        initial: _filters,
        api: _api,
        searchQuery: _searchController.text,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _filters = result);
    _loadPlaces(page: 1);
  }

  void _handleSortSelected(_PlaceSortField field) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (_sortField == field) {
        _sortDirection = _sortDirection == _PlaceSortDirection.asc
            ? _PlaceSortDirection.desc
            : _PlaceSortDirection.asc;
      } else {
        _sortField = field;
        _sortDirection = field.defaultDirection;
      }
    });
    _loadPlaces(page: 1);
  }

  Future<void> _refreshPlaces() {
    return _loadPlaces(page: _currentPage);
  }

  Future<void> _handlePageChanged(int page) async {
    if (page == _currentPage || _loading) return;
    FocusScope.of(context).unfocus();
    await _loadPlaces(page: page);
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

  void _openDetails(PlaceVm place) {
    context.push('/places/${place.id}', extra: place);
  }

  AppCityFilterValue? _currentCityValue(HomeLocationProvider provider) {
    if (_filters.city != null) return _filters.city;

    return HomeLocationFilterDefaults.fromPreference(
      provider.effectiveLocation,
    ).city;
  }

  List<PlaceVm> _mustVisitPlaces(AppCityFilterValue? city) {
    if (city == null || _places.isEmpty) return const [];

    final currentCityItems =
        _places
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
    return PlaceTextScale(
      child: Builder(
        builder: (context) {
          final adaptive = PlaceAdaptive.of(context);
          final colors = AppDesignSystem.colorsFor(context);
          final l10n = AppLocalizations.of(context)!;

          return Theme(
            data: AppDesignSystem.themeFor(context),
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: Theme.of(context).brightness == Brightness.dark
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
                        _buildHeader(l10n),
                        _buildSearchBar(adaptive, l10n),
                        Expanded(child: _buildBody(adaptive, l10n)),
                      ],
                    ),
                  ),
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
      title: l10n.placesTitle,
      notificationsTooltip: l10n.profileNotificationsRowTitle,
      onBackTap: _onBack,
      onNotificationsTap: () => context.push('/notifications'),
    );
  }

  Widget _buildSearchBar(PlaceAdaptive a, AppLocalizations l10n) {
    final activeFilterCount = _filters.activeCount;

    return Padding(
      padding: AppEdgeInsets.fromLTRB(
        a.scale(24, minFactor: 0.78),
        a.scale(22),
        a.scale(24, minFactor: 0.78),
        0,
      ),
      child: AppListSearchField(
        controller: _searchController,
        hintText: l10n.placesSearchHint,
        filterTooltip: l10n.placesFiltersTitle,
        activeFilterCount: activeFilterCount,
        onFilterTap: _openFilters,
        onSubmitted: _submitPlaceSearch,
      ),
    );
  }

  Widget _buildBody(PlaceAdaptive a, AppLocalizations l10n) {
    final colors = context.appColors;

    if (_loading && _places.isEmpty) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (_error != null && _places.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.placesLoadFailed,
              style: AppTextStyle(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: a.scale(12)),
            TextButton(
              onPressed: () => _loadPlaces(page: _currentPage),
              child: Text(
                l10n.retryButton,
                style: AppTextStyle(color: colors.primary),
              ),
            ),
          ],
        ),
      );
    }

    final padX = a.scale(24, minFactor: 0.78);
    final locationProvider = context.watch<HomeLocationProvider>();
    _scheduleApplyDefaultLocationFilter(locationProvider);
    final currentCity = _currentCityValue(locationProvider);
    final mustVisitPlaces = _mustVisitPlaces(currentCity);
    final search = _searchController.text.trim();
    final cityId = currentCity?.cityId?.trim();
    final cityName = currentCity?.cityName?.trim();
    final countryCode = currentCity?.countryCode?.trim();
    final shouldShowMustVisit =
        _filters.isEmpty &&
        search.isEmpty &&
        currentCity != null &&
        mustVisitPlaces.isNotEmpty;

    return RefreshIndicator(
      color: colors.primary,
      backgroundColor: colors.surfaceRaised,
      onRefresh: _refreshPlaces,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: AppEdgeInsets.fromLTRB(
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
                      places: mustVisitPlaces,
                      onTap: _openDetails,
                    ),
                  if (shouldShowMustVisit)
                    SizedBox(height: a.scale(24, minFactor: 0.72)),
                  _PlaceSortBar(
                    l10n: l10n,
                    adaptive: a,
                    selectedField: _sortField,
                    direction: _sortDirection,
                    onFieldSelected: _handleSortSelected,
                  ),
                  SizedBox(height: a.scale(18, minFactor: 0.72)),
                  ContextualHelpSection(
                    surface: HelpCenterSurface.places,
                    tags: const ['places', 'tickets', 'opening_hours'],
                    supportContext: {
                      'screen': 'places',
                      'locale': Localizations.localeOf(context).languageCode,
                      'sort': _sortQueryParam,
                      if (search.isNotEmpty) 'search_query': search,
                      if (cityId != null && cityId.isNotEmpty)
                        'city_id': cityId,
                      if (cityName != null && cityName.isNotEmpty)
                        'city_name': cityName,
                      if (countryCode != null && countryCode.isNotEmpty)
                        'country_code': countryCode,
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_places.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: AppEdgeInsets.symmetric(vertical: a.scale(40)),
                child: Center(
                  child: Padding(
                    padding: AppEdgeInsets.symmetric(horizontal: a.scale(24)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.placesNoResults,
                          textAlign: TextAlign.center,
                          style: AppTextStyle(
                            color: colors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: a.scale(8)),
                        Text(
                          l10n.placesNoResultsSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyle(
                            color: colors.textMuted,
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
              padding: AppEdgeInsets.fromLTRB(padX, 0, padX, a.scale(24)),
              sliver: _buildGrid(a, l10n),
            ),
          if (_places.isNotEmpty && _totalPages > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: AppEdgeInsets.fromLTRB(
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

  Widget _buildGrid(PlaceAdaptive a, AppLocalizations l10n) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = placeDiscoverGridColumnCount(
          constraints.crossAxisExtent,
        );
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
              place: _places[i],
              l10n: l10n,
              adaptive: a,
              onTap: _openDetails,
            ),
            childCount: _places.length,
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
    required this.places,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final PlaceAdaptive adaptive;
  final AppCityFilterValue city;
  final List<PlaceVm> places;
  final void Function(PlaceVm) onTap;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: adaptive.scale(32, minFactor: 0.86),
              height: adaptive.scale(32, minFactor: 0.86),
              decoration: AppBoxDecoration(
                color: colors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: colors.primary,
                size: adaptive.scale(17, minFactor: 0.86),
              ),
            ),
            SizedBox(width: adaptive.scale(10, minFactor: 0.74)),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      l10n.placeMustVisitBadge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: colors.textPrimary,
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
                    decoration: AppBoxDecoration(
                      color: colors.textMuted,
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
                      style: AppTextStyle(
                        color: colors.textSecondary,
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
                  for (var i = 0; i < places.length; i++)
                    Padding(
                      padding: AppEdgeInsets.only(
                        right: i == places.length - 1
                            ? 0
                            : adaptive.scale(12, minFactor: 0.72),
                      ),
                      child: _MustVisitCard(
                        place: places[i],
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
    required this.place,
    required this.l10n,
    required this.adaptive,
    required this.width,
    required this.onTap,
  });

  final PlaceVm place;
  final AppLocalizations l10n;
  final PlaceAdaptive adaptive;
  final double width;
  final void Function(PlaceVm) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final coverMedia = place.coverMedia;
    final imageTargetWidth = placeImageTargetWidth(
      context,
      width,
      minWidth: 360,
      maxWidth: 620,
    );
    final coverUrls = coverMedia == null
        ? const <String>[]
        : resolvePlaceMediaUrls(coverMedia, targetWidth: imageTargetWidth);
    final coverOverlayGradient = _placesCoverOverlayGradient(
      context,
      topAlpha: 0.02,
      bottomAlpha: 0.48,
      firstStop: 0.4,
    );
    final coverRadius = AppBorderRadius.circular(adaptive.radius(16));

    return GestureDetector(
      onTap: () => onTap(place),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: AppBoxDecoration(
                borderRadius: coverRadius,
                border: Border.all(color: colors.border),
              ),
              child: ClipRRect(
                borderRadius: coverRadius,
                child: AspectRatio(
                  aspectRatio: 1.42,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _RetryingPlaceCoverImage(
                        imageUrls: coverUrls,
                        cacheWidth: imageTargetWidth,
                        placeholder: () => _placeholder(context),
                      ),
                      if (coverOverlayGradient != null)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: AppBoxDecoration(
                              gradient: coverOverlayGradient,
                            ),
                          ),
                        ),
                      Positioned(
                        top: adaptive.scale(8, minFactor: 0.78),
                        right: adaptive.scale(8, minFactor: 0.78),
                        child: _ratingBadge(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: adaptive.scale(10, minFactor: 0.72)),
            Text(
              place.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(
                color: colors.textPrimary,
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
              style: AppTextStyle(
                color: colors.textMuted,
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
    return formatPlacePriceLabel(
      context,
      l10n,
      place,
      preferredCurrency: context.watch<SessionProvider>().profile?.currency,
      currencyRates: context.watch<CurrencyRateProvider>(),
    );
  }

  Widget _ratingBadge(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.surfaceTeal,
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: colors.borderSecondary),
      ),
      child: Padding(
        padding: AppEdgeInsets.symmetric(
          horizontal: adaptive.scale(8, minFactor: 0.78),
          vertical: adaptive.scale(5, minFactor: 0.78),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              color: colors.primary,
              size: adaptive.scale(13, minFactor: 0.82),
            ),
            SizedBox(width: adaptive.scale(2, minFactor: 0.72)),
            Text(
              place.rating.toStringAsFixed(1),
              style: AppTextStyle(
                color: colors.primary,
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

  Widget _placeholder(BuildContext context) {
    final colors = context.appColors;

    return Container(
      color: colors.surfaceHigh,
      child: Center(
        child: Icon(Icons.landscape_rounded, color: colors.textMuted, size: 34),
      ),
    );
  }
}

class _RetryingPlaceCoverImage extends StatefulWidget {
  const _RetryingPlaceCoverImage({
    required this.imageUrls,
    required this.cacheWidth,
    required this.placeholder,
  });

  final List<String> imageUrls;
  final int cacheWidth;
  final Widget Function() placeholder;

  @override
  State<_RetryingPlaceCoverImage> createState() =>
      _RetryingPlaceCoverImageState();
}

class _RetryingPlaceCoverImageState extends State<_RetryingPlaceCoverImage> {
  static const int _maxRetryPerUrl = 1;

  int _urlIndex = 0;
  int _retry = 0;

  @override
  void didUpdateWidget(covariant _RetryingPlaceCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.imageUrls, widget.imageUrls) ||
        oldWidget.cacheWidth != widget.cacheWidth) {
      _urlIndex = 0;
      _retry = 0;
    }
  }

  void onRetryNext() {
    if (!mounted) return;
    if (_urlIndex < widget.imageUrls.length - 1) {
      setState(() {
        _urlIndex += 1;
        _retry = 0;
      });
      return;
    }
    if (_retry < _maxRetryPerUrl) {
      setState(() => _retry += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return widget.placeholder();
    }

    final imageUrl = widget.imageUrls[_urlIndex];
    return Image.network(
      imageUrl,
      key: ValueKey('$imageUrl#$_retry'),
      headers: placeImageRequestHeaders(imageUrl),
      fit: BoxFit.cover,
      cacheWidth: widget.cacheWidth,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return widget.placeholder();
      },
      errorBuilder: (_, _, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onRetryNext();
        });
        return widget.placeholder();
      },
    );
  }
}

class _PlaceSortBar extends StatelessWidget {
  const _PlaceSortBar({
    required this.l10n,
    required this.adaptive,
    required this.selectedField,
    required this.direction,
    required this.onFieldSelected,
  });

  final AppLocalizations l10n;
  final PlaceAdaptive adaptive;
  final _PlaceSortField selectedField;
  final _PlaceSortDirection direction;
  final ValueChanged<_PlaceSortField> onFieldSelected;

  @override
  Widget build(BuildContext context) {
    final fields = _PlaceSortField.values;
    final isAscending = direction == _PlaceSortDirection.asc;

    return AppInlineSortRow<_PlaceSortField>(
      label: l10n.placesSortLabel,
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
    required this.place,
    required this.l10n,
    required this.adaptive,
    required this.onTap,
  });

  final PlaceVm place;
  final AppLocalizations l10n;
  final PlaceAdaptive adaptive;
  final void Function(PlaceVm) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final coverMedia = place.coverMedia;

    return GestureDetector(
      onTap: () => onTap(place),
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = (constraints.maxWidth * 1.33).clamp(200.0, 230.0);
          final imageTargetWidth = placeImageTargetWidth(
            context,
            constraints.maxWidth,
            minWidth: 420,
            maxWidth: 720,
          );
          final coverUrls = coverMedia == null
              ? const <String>[]
              : resolvePlaceMediaUrls(
                  coverMedia,
                  targetWidth: imageTargetWidth,
                );
          final coverOverlayGradient = _placesCoverOverlayGradient(
            context,
            topAlpha: 0,
            bottomAlpha: 0.42,
            firstStop: 0.55,
          );
          final coverRadius = AppBorderRadius.circular(adaptive.radius(18));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: AppBoxDecoration(
                  borderRadius: coverRadius,
                  border: Border.all(color: colors.border),
                ),
                child: ClipRRect(
                  borderRadius: coverRadius,
                  child: SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _RetryingPlaceCoverImage(
                          imageUrls: coverUrls,
                          cacheWidth: imageTargetWidth,
                          placeholder: () => _placeholder(context),
                        ),
                        if (coverOverlayGradient != null)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: AppBoxDecoration(
                                gradient: coverOverlayGradient,
                              ),
                            ),
                          ),
                        Positioned(
                          top: adaptive.scale(8),
                          right: adaptive.scale(8),
                          child: _saveButton(context),
                        ),
                        Positioned(
                          left: adaptive.scale(32, minFactor: 0.48),
                          bottom: adaptive.scale(28, minFactor: 0.5),
                          child: _categoryTag(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: adaptive.scale(16, minFactor: 0.72)),
              Text(
                place.title,
                style: AppTextStyle(
                  color: colors.textPrimary,
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
                      style: AppTextStyle(
                        color: colors.secondary,
                        fontSize: adaptive.scale(17, minFactor: 0.82),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.star_rounded,
                    color: colors.primary,
                    size: adaptive.scale(18),
                  ),
                  SizedBox(width: adaptive.scale(2)),
                  Text(
                    place.rating.toStringAsFixed(1),
                    style: AppTextStyle(
                      color: colors.primary,
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

  Widget _saveButton(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = adaptive.scale(42, minFactor: 0.86);
    return Container(
      width: size,
      height: size,
      decoration: AppBoxDecoration(
        color: colors.surfaceTeal,
        shape: BoxShape.circle,
        border: Border.all(color: colors.borderSecondary),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : const [],
      ),
      child: Icon(
        Icons.bookmark_border_rounded,
        color: colors.secondary,
        size: adaptive.scale(19, minFactor: 0.86),
      ),
    );
  }

  Widget _categoryTag(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: adaptive.scale(23, minFactor: 0.84),
      padding: AppEdgeInsets.symmetric(horizontal: adaptive.scale(12)),
      alignment: Alignment.center,
      decoration: AppBoxDecoration(
        color: colors.primaryContainer,
        borderRadius: AppBorderRadius.circular(999),
      ),
      child: Text(
        _categoryLabel(place.category).toUpperCase(),
        style: AppTextStyle(
          color: colors.primary,
          fontSize: adaptive.scale(12, minFactor: 0.84),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    return localizedPlaceCategoryLabel(l10n, category);
  }

  Widget _placeholder(BuildContext context) {
    final colors = context.appColors;

    return Container(
      color: colors.surfaceHigh,
      child: Center(
        child: Icon(Icons.landscape_rounded, color: colors.textMuted, size: 48),
      ),
    );
  }
}
