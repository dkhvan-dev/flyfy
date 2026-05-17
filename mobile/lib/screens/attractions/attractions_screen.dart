import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/reference_api.dart';
import '../../core/reference/country_filter_utils.dart';
import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_inline_sort_row.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/pagination_bar.dart';
import '../../features/attractions/attraction_ui.dart';
import '../../features/attractions/data/attraction_api.dart';
import '../../features/attractions/models/attraction_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
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
  static const int _pageSize = 8;

  final AttractionApi _api = AttractionApi();
  final ReferenceApi _referenceApi = ReferenceApi();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<AttractionVm> _attractions = [];
  List<ReferenceCountry> _countries = const [];
  Map<String, Set<String>> _countrySearchAliases = const {};
  bool _loading = true;
  bool _isCountriesLoading = false;
  bool _hasAppliedDefaultCountryFilter = false;
  String? _error;
  AttractionFilterResult _filters = AttractionFilterResult.empty;
  Timer? _searchDebounce;
  Future<void>? _countriesLoadFuture;
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
      _applyDefaultCountryFilter();
      unawaited(_loadCountries());
      _loadAttractions();
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

  String? _defaultCountryCode() {
    return normalizeReferenceCountryCode(
      context.read<SessionProvider>().profile?.countryCode,
    );
  }

  void _applyDefaultCountryFilter() {
    if (!mounted || _hasAppliedDefaultCountryFilter) return;
    _hasAppliedDefaultCountryFilter = true;

    final defaultCountryCode = _defaultCountryCode();
    if (defaultCountryCode == null || _filters.countryCode != null) return;

    setState(() {
      _filters = AttractionFilterResult(
        countryCode: defaultCountryCode,
        category: _filters.category,
        minRating: _filters.minRating,
        durationMin: _filters.durationMin,
        durationMax: _filters.durationMax,
        durationUnit: _filters.durationUnit,
        priceMin: _filters.priceMin,
        priceMax: _filters.priceMax,
      );
    });
  }

  Future<void> _loadCountries() {
    if (_countries.isNotEmpty) return Future.value();
    final inFlight = _countriesLoadFuture;
    if (inFlight != null) return inFlight;

    final future = _loadCountriesInner();
    _countriesLoadFuture = future;
    return future.whenComplete(() => _countriesLoadFuture = null);
  }

  Future<void> _loadCountriesInner() async {
    if (!mounted) return;

    setState(() => _isCountriesLoading = true);
    final lang = Localizations.localeOf(context).languageCode;
    final defaultCountryCode = _defaultCountryCode();

    try {
      final countries = withDefaultReferenceCountry(
        await _referenceApi.listCountries(lang: lang),
        defaultCountryCode,
      );
      final countrySearchAliases = await _loadCountrySearchAliases(
        countries,
        lang,
      );
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _countrySearchAliases = countrySearchAliases;
        _isCountriesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final countries = withDefaultReferenceCountry(
        const [],
        defaultCountryCode,
      );
      setState(() {
        _countries = countries;
        _countrySearchAliases = countrySearchAliasMap(countries);
        _isCountriesLoading = false;
      });
    }
  }

  Future<Map<String, Set<String>>> _loadCountrySearchAliases(
    List<ReferenceCountry> countries,
    String currentLang,
  ) async {
    final languages = {'en', 'ru', 'kk'}..remove(currentLang);
    final localizedLists = await Future.wait(
      languages.map((lang) async {
        try {
          return await _referenceApi.listCountries(lang: lang);
        } catch (_) {
          return const <ReferenceCountry>[];
        }
      }),
    );

    return countrySearchAliasMap([
      ...countries,
      for (final localizedCountries in localizedLists) ...localizedCountries,
    ]);
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
    await _loadCountries();
    if (!mounted) return;

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
        countries: _countries,
        countrySearchAliases: _countrySearchAliases,
        isCountriesLoading: _isCountriesLoading,
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
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.scale(58, minFactor: 0.9, maxFactor: 1.0),
        ),
        padding: EdgeInsetsDirectional.fromSTEB(
          a.scale(16, minFactor: 0.86, maxFactor: 1.0),
          0,
          a.scale(8, minFactor: 0.86, maxFactor: 1.0),
          0,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2D1C0B),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: AppColors.accent,
              size: a.scale(27, minFactor: 0.86, maxFactor: 1.0),
            ),
            SizedBox(width: a.scale(12, minFactor: 0.82, maxFactor: 1.0)),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: a.scale(16, minFactor: 0.9, maxFactor: 1.0),
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l10n.attractionsSearchHint,
                  hintStyle: TextStyle(
                    color: const Color(0xFF9F8B7D),
                    fontSize: a.scale(16, minFactor: 0.9, maxFactor: 1.0),
                    height: 1.2,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _loadAttractions(page: 1),
              ),
            ),
            Tooltip(
              message: l10n.attractionsFiltersTitle,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: _openFilters,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                      foregroundColor: AppColors.accent,
                      minimumSize: Size(
                        a.scale(43, minFactor: 0.9, maxFactor: 1.0),
                        a.scale(43, minFactor: 0.9, maxFactor: 1.0),
                      ),
                      shape: const CircleBorder(),
                    ),
                    icon: Icon(
                      Icons.tune_rounded,
                      size: a.scale(24, minFactor: 0.9, maxFactor: 1.0),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  if (activeFilterCount > 0)
                    PositionedDirectional(
                      top: 2,
                      end: 2,
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: a.scale(16, minFactor: 0.9, maxFactor: 1.0),
                          minHeight:
                              a.scale(16, minFactor: 0.9, maxFactor: 1.0),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              a.scale(4, minFactor: 0.8, maxFactor: 1.0),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          activeFilterCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize:
                                a.scale(10, minFactor: 0.9, maxFactor: 1.0),
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
                  child: Text(
                    l10n.attractionsNoResults,
                    style: const TextStyle(color: AppColors.textSecondary),
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
                child: FlyfyPaginationBar(
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
          final coverUrl =
              coverMedia == null ? null : resolveAttractionMediaUrl(coverMedia);
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
                          errorBuilder: (_, __, ___) => _placeholder(),
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
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
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
