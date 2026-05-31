import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/file_api.dart';
import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_inline_sort_row.dart';
import '../../core/ui/app_list_search_field.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../core/ui/pagination_bar.dart';
import '../../features/guides/data/guide_discovery_api.dart';
import '../../features/guides/guide_localization.dart';
import '../../features/guides/guide_search.dart';
import '../../features/guides/models/public_guide_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/home_location_provider.dart';
import '../../shared/widgets/app_city_filter_section.dart';

enum _GuideSortMode { rating, experience }

enum _GuideSortDirection { asc, desc }

const _guideSpecializationFilterCodes = [
  'mountain_guide',
  'city_historian',
  'culinary_expert',
  'nature_photographer',
];

const _guideLanguageFilterCodes = ['en', 'ru', 'kk'];

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
  bool _hasAppliedDefaultCityFilter = false;
  String? _error;
  String _searchQuery = '';
  Timer? _searchDebounce;
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
    if (locationProvider.selectedLocation == null &&
        !locationProvider.isLoading) {
      await locationProvider.load();
    }
    if (!mounted) return;
    _applyDefaultCityFilter(locationProvider);
    await _loadGuides();
  }

  void _applyDefaultCityFilter(HomeLocationProvider provider) {
    if (_hasAppliedDefaultCityFilter ||
        _filters.country != null ||
        _filters.city != null) {
      _hasAppliedDefaultCityFilter = true;
      return;
    }

    _hasAppliedDefaultCityFilter = true;
    final location = provider.selectedLocation;
    final country = AppCountryFilterValue.fromParts(
      countryCode: location?.countryCode,
    );
    final city = AppCityFilterValue.fromParts(
      cityId: location?.cityId,
      cityName: location?.cityName,
      countryCode: location?.countryCode,
    );
    if ((country == null && city == null) || !mounted) return;

    setState(() {
      _filters = _filters.copyWith(country: country, city: city);
      _currentPage = 1;
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
    setState(() {
      _loading = _guides.isEmpty;
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
      if (!mounted) return;
      final totalPages = math.max(1, (result.total / _pageSize).ceil());
      if (result.total > 0 && normalizedPage > totalPages) {
        await _loadGuides(page: totalPages);
        return;
      }
      setState(() {
        _guides = result.items;
        _totalGuides = result.total;
        _loading = false;
        _currentPage = normalizedPage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'load_failed';
        _loading = false;
      });
    }
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
    final selected = await showModalBottomSheet<_GuideFilters>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GuidesFiltersSheet(
        initialFilters: _filters,
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
    final totalPages = math.max(1, (_totalGuides / _pageSize).ceil());
    final activePage = _currentPage.clamp(1, totalPages).toInt();
    final pageGuides = _guides;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1007),
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null && _guides.isEmpty) {
      return ErrorView(
        message: l10n.guidesLoadFailed,
        onRetry: () => _loadGuides(page: _currentPage),
      );
    }

    final padX = _horizontalPadding(context);

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: const Color(0xFF2C2014),
      onRefresh: () => _loadGuides(page: _currentPage),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padX, 22, padX, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GuidesSearchField(
                    controller: _searchController,
                    hintText: l10n.guidesSearchHint,
                    onFilterTap: _showFilters,
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
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padX, 28, padX, 24),
              sliver: _GuidesGrid(guides: pageGuides, onGuideTap: _openProfile),
            ),
          if (totalVisible > _pageSize)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(padX, 5, padX, 34),
                child: Column(
                  children: [
                    InflapPaginationBar(
                      currentPage: activePage,
                      totalPages: totalPages,
                      onPageChanged: _handlePageChanged,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      l10n.commonPaginationLabel(activePage, totalPages),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0x6ED2BBAD),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
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

  String get _sortQuery => '${_sortMode.queryKey}_${_sortDirection.queryKey}';

  String _backendSearchQuery(AppLocalizations l10n) {
    final query = _searchQuery.trim();
    if (query.isEmpty) return query;

    for (final code in _guideSpecializationFilterCodes) {
      if (guideSearchMatches(query, [
        code,
        localizedGuideSpecializationLabel(l10n, code),
      ])) {
        return code;
      }
    }

    for (final code in _guideLanguageFilterCodes) {
      if (guideSearchMatches(query, [
        code,
        localizedGuideLanguageLabel(l10n, code),
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
    required this.activeFilterCount,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onFilterTap;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {
    return AppListSearchField(
      controller: controller,
      hintText: hintText,
      filterTooltip: AppLocalizations.of(context)!.guidesFiltersTitle,
      activeFilterCount: activeFilterCount,
      onFilterTap: onFilterTap,
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
    return AppInlineSortRow<_GuideSortMode>(
      label: l10n.guidesSortLabel,
      options: [
        for (final mode in _GuideSortMode.values)
          AppInlineSortOption(value: mode, label: mode.label(l10n)),
      ],
      selectedValue: selected,
      isAscending: direction == _GuideSortDirection.asc,
      onSelected: onChanged,
      fontSize: 14,
      iconSize: 15,
      labelToOptionsGap: 18,
      optionGap: 22,
      letterSpacing: 1.8,
      labelColor: const Color(0xFF8D7464),
      inactiveColor: const Color(0xFFD5C0B2),
    );
  }
}

class _GuidesGrid extends StatelessWidget {
  const _GuidesGrid({required this.guides, required this.onGuideTap});

  final List<PublicGuideVm> guides;
  final ValueChanged<PublicGuideVm> onGuideTap;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.crossAxisExtent < 335
            ? 1
            : constraints.crossAxisExtent >= 680
            ? 3
            : 2;
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

const double _guideCardBodyMinHeight = 122;
const double _guideCardBodyHorizontalPadding = 15;
const double _guideCardBodyVerticalPadding = 12;
const double _guideCardNameFontSize = 18;
const double _guideCardNameLineHeight = 1.08;
const double _guideCardLanguageFontSize = 14;
const double _guideCardLanguageLineHeight = 1.18;
const double _guideCardLanguageGap = 6;
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
  final buttonHeight = math.max(
    _guideCardButtonMinHeight,
    textScaler.scale(_guideCardButtonFontSize) +
        _guideCardButtonVerticalPadding * 2,
  );

  final contentHeight =
      _guideCardBodyVerticalPadding * 2 +
      nameHeight +
      _guideCardLanguageGap +
      languageHeight +
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
    final languageLabel = guideExcursionLanguageLabel(l10n, guide);
    final avatarUrl = guide.avatarFileId == null
        ? null
        : resolvePublicFileContentUrl(guide.avatarFileId!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF2C2014),
            borderRadius: BorderRadius.circular(22),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
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
                          errorBuilder: (_, _, _) =>
                              _GuideFallbackArt(initials: guide.initials),
                        )
                      else
                        _GuideFallbackArt(initials: guide.initials),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0x66120B05)],
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
                    padding: const EdgeInsets.symmetric(
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
                          style: const TextStyle(
                            color: Color(0xFFFFF3E8),
                            fontSize: _guideCardNameFontSize,
                            fontWeight: FontWeight.w900,
                            height: _guideCardNameLineHeight,
                            letterSpacing: 0,
                          ),
                        ),
                        if (languageLabel.isNotEmpty) ...[
                          const SizedBox(height: _guideCardLanguageGap),
                          Text(
                            languageLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFD9C4B5),
                              fontSize: _guideCardLanguageFontSize,
                              fontWeight: FontWeight.w500,
                              height: _guideCardLanguageLineHeight,
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF293B35), Color(0xFF704117), Color(0xFF17100A)],
        ),
      ),
      child: Center(
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: Color(0xFFFFF3E8),
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
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xEB2C2014),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
          const SizedBox(width: 4),
          Text(
            rating <= 0 ? '0.0' : rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.accent,
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
    return Container(
      constraints: const BoxConstraints(minHeight: _guideCardButtonMinHeight),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: _guideCardButtonHorizontalPadding,
        vertical: _guideCardButtonVerticalPadding,
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.accent,
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
  const _GuidesEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_outlined, color: AppColors.accent, size: 56),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFF3E8),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFC8AD9C),
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ],
      ),
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
    required this.fallbackResultCount,
    required this.resultCountLoader,
  });

  final _GuideFilters initialFilters;
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

    return _guideLanguageFilterCodes
        .where(
          (code) =>
              guideSearchMatches(query, _languageSearchHaystack(l10n, code)),
        )
        .toList(growable: false);
  }

  List<String> _languageSearchHaystack(AppLocalizations l10n, String code) {
    final aliases = switch (code.trim().toLowerCase()) {
      'en' => const ['english', 'английский', 'ағылшын'],
      'ru' => const ['russian', 'русский', 'орыс'],
      'kk' || 'kz' => const ['kazakh', 'казахский', 'қазақ'],
      _ => const <String>[],
    };
    return [code, localizedGuideLanguageLabel(l10n, code), ...aliases];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final resultCount = _resultCount ?? widget.fallbackResultCount;
    final selectedLanguage = _selectedLanguage(l10n);
    final visibleLanguages = _visibleLanguages(l10n);

    return AppDismissibleModalSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
          maxWidth: 520,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF211508),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0x293A270F))),
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
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCountryFilterSection(
                        title: l10n.attractionFilterCountrySection,
                        allCountriesLabel: l10n.attractionFilterCountryAll,
                        searchHint: l10n.attractionFilterCountrySearchHint,
                        noResultsText: l10n.attractionFilterCountryNoResults,
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
                            for (final code in _guideSpecializationFilterCodes)
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
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2118),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.translate_rounded,
                                      color: AppColors.accent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        selectedLanguage ??
                                            l10n.guidesFilterLanguageAll,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
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
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: Color(0xFFBDAA98),
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
                              cursorColor: AppColors.accent,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.guidesFilterLanguageSearchHint,
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9D8877),
                                  fontWeight: FontWeight.w600,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.accent,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF171009),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.accent,
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
                                  style: const TextStyle(
                                    color: Color(0xFFBDAA98),
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
                padding: EdgeInsets.fromLTRB(22, 0, 22, bottomInset + 18),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFFF3E8),
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
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFD8C7B7),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.18)
              : const Color(0xFF2C2118),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                code,
                style: const TextStyle(
                  color: Color(0xFFBDAA98),
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
