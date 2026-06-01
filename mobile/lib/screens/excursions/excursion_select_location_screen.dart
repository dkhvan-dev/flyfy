import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/app_list_search_field.dart';
import '../../features/attractions/attraction_ui.dart';
import '../../features/attractions/data/attraction_api.dart';
import '../../features/attractions/models/attraction_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/map/app_map_links.dart';
import '../../shared/widgets/app_city_filter_section.dart';
import '../attractions/attractions_filter_sheet.dart';

class ExcursionLocationSelection {
  const ExcursionLocationSelection({
    required this.id,
    required this.name,
    required this.countryCode,
    this.cityId,
    this.cityName,
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.coverFileId,
    this.coverImageUrl,
    this.translations = const {},
    this.categorySlug = '',
  });

  final String id;
  final String name;
  final String countryCode;
  final String? cityId;
  final String? cityName;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;
  final String? coverFileId;
  final String? coverImageUrl;
  final Map<String, ExcursionLocationLocalizedCopy> translations;
  final String categorySlug;

  factory ExcursionLocationSelection.fromAttraction(
    AttractionVm attraction, {
    String? fallbackCityName,
  }) {
    final coverMedia = attraction.coverMedia;
    final coverImageUrl = coverMedia == null
        ? null
        : resolveAttractionMediaUrl(coverMedia);
    final cityId = attraction.cityId.trim();
    final cityName = _selectionCityName(
      cityId: cityId,
      fallbackCityName: fallbackCityName,
    );
    final translations = <String, ExcursionLocationLocalizedCopy>{};
    for (final entry in attraction.translations.entries) {
      final locale = entry.key.trim().toLowerCase().replaceAll('_', '-');
      if (locale.isEmpty) continue;
      final title = entry.value.title.trim();
      final description = entry.value.description.trim();
      if (title.isEmpty && description.isEmpty) continue;
      translations[locale] = ExcursionLocationLocalizedCopy(
        title: title,
        description: description,
      );
    }
    final locale = attraction.locale.trim().toLowerCase().replaceAll('_', '-');
    if (locale.isNotEmpty &&
        (attraction.title.trim().isNotEmpty ||
            attraction.description.trim().isNotEmpty)) {
      translations.putIfAbsent(
        locale,
        () => ExcursionLocationLocalizedCopy(
          title: attraction.title.trim(),
          description: attraction.description.trim(),
        ),
      );
    }
    return ExcursionLocationSelection(
      id: attraction.id,
      name: attraction.title,
      countryCode: attraction.countryCode,
      cityId: cityId.isEmpty ? null : cityId,
      cityName: cityName,
      latitude: attraction.latitude,
      longitude: attraction.longitude,
      mapUrl: attraction.hasLocation
          ? AppMapLinks.buildUrl(
              latitude: attraction.latitude!,
              longitude: attraction.longitude!,
              title: attraction.title,
              subtitle: cityName ?? attraction.countryCode,
            )
          : null,
      coverFileId: attraction.coverFileId,
      coverImageUrl: coverImageUrl,
      translations: translations,
      categorySlug: attraction.category.trim(),
    );
  }
}

String? _selectionCityName({required String cityId, String? fallbackCityName}) {
  final cityName = fallbackCityName?.trim();
  if (cityName != null && cityName.isNotEmpty) {
    return cityName;
  }
  final normalizedCityId = cityId.trim();
  return normalizedCityId.isEmpty ? null : normalizedCityId;
}

class ExcursionLocationLocalizedCopy {
  const ExcursionLocationLocalizedCopy({
    this.title = '',
    this.summary = '',
    this.description = '',
  });

  final String title;
  final String summary;
  final String description;
}

class ExcursionLocationPickerArgs {
  const ExcursionLocationPickerArgs({
    required this.countryCode,
    this.initialSelection,
  });

  final String countryCode;
  final ExcursionLocationSelection? initialSelection;
}

class ExcursionSelectLocationScreen extends StatefulWidget {
  const ExcursionSelectLocationScreen({
    super.key,
    required this.countryCode,
    this.initialSelection,
    this.api,
  });

  final String countryCode;
  final ExcursionLocationSelection? initialSelection;
  final AttractionApi? api;

  @override
  State<ExcursionSelectLocationScreen> createState() =>
      _ExcursionSelectLocationScreenState();
}

class _ExcursionSelectLocationScreenState
    extends State<ExcursionSelectLocationScreen> {
  static const _pageSize = 8;
  static const double _swipeCloseMinDistance = 56;
  static const double _swipeCloseMinVelocity = 700;

  late final AttractionApi _api;
  final _attractionSearchCtrl = TextEditingController();
  final _scrollController = ScrollController();

  Timer? _searchDebounce;
  var _isTrackingSwipeClose = false;
  var _swipeCloseDistance = 0.0;
  var _selectedCountryCode = 'KZ';
  var _currentPage = 1;
  var _totalItems = 0;
  var _isLoading = true;
  var _isRefreshing = false;
  String? _error;
  AttractionFilterResult _filters = AttractionFilterResult.empty;
  List<AttractionVm> _items = const [];
  ExcursionLocationSelection? _selectedLocation;

  int get _totalPages {
    final pages = (_totalItems / _pageSize).ceil();
    return pages < 1 ? 1 : pages;
  }

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? AttractionApi();
    _selectedCountryCode = widget.countryCode.trim().toUpperCase();
    if (_selectedCountryCode.isEmpty) {
      _selectedCountryCode = 'KZ';
    }
    final initial = widget.initialSelection;
    if (_hasUsableInitialSelection(initial)) {
      _selectedLocation = initial;
    }
    _filters = _initialLocationFilter(initial);
    _attractionSearchCtrl.addListener(_onAttractionSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAttractions());
  }

  bool _hasUsableInitialSelection(ExcursionLocationSelection? initial) {
    return initial != null &&
        initial.id.trim().isNotEmpty &&
        initial.countryCode.trim().toUpperCase() == _selectedCountryCode;
  }

  AttractionFilterResult _initialLocationFilter(
    ExcursionLocationSelection? initial,
  ) {
    final country = AppCountryFilterValue.fromParts(
      countryCode: _selectedCountryCode,
    );
    if (initial == null || initial.countryCode != _selectedCountryCode) {
      return AttractionFilterResult(country: country);
    }

    final city = AppCityFilterValue.fromParts(
      cityId: initial.cityId,
      cityName: initial.cityName,
      countryCode: initial.countryCode,
    );
    return AttractionFilterResult(country: country, city: city);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _attractionSearchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onAttractionSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 380),
      () => _loadAttractions(page: 1),
    );
  }

  Future<void> _loadAttractions({int page = 1, bool refresh = false}) async {
    if (!mounted) return;
    final normalizedPage = page < 1 ? 1 : page;
    setState(() {
      _isLoading = _items.isEmpty && !refresh;
      _isRefreshing = refresh;
      _error = null;
    });

    try {
      final locale = Localizations.localeOf(context).languageCode;
      final search = _attractionSearchCtrl.text.trim();
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
        sort: 'rating_desc',
        locale: locale,
        limit: _pageSize,
        offset: (normalizedPage - 1) * _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _totalItems = result.total;
        _currentPage = result.total == 0 ? 1 : normalizedPage;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _error = 'load_failed';
      });
    }
  }

  Future<void> _refresh() =>
      _loadAttractions(page: _currentPage, refresh: true);

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
        searchQuery: _attractionSearchCtrl.text,
        fallbackCountryCode: _selectedCountryCode,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _filters = result);
    await _loadAttractions(page: 1);
  }

  Future<void> _changePage(int page) async {
    if (page == _currentPage || _isLoading || page < 1 || page > _totalPages) {
      return;
    }
    FocusScope.of(context).unfocus();
    await _loadAttractions(page: page);
    if (!mounted || !_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectAttraction(AttractionVm attraction) {
    setState(() {
      _selectedLocation = ExcursionLocationSelection.fromAttraction(
        attraction,
        fallbackCityName: _filters.cityName,
      );
    });
  }

  void _confirm() {
    final selected = _selectedLocation;
    if (selected == null) return;
    context.pop<ExcursionLocationSelection>(selected);
  }

  void _resetSwipeClose() {
    _isTrackingSwipeClose = false;
    _swipeCloseDistance = 0;
  }

  double _swipeCloseEdgeWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width <= 393 ? 68.0 : 76.0;
  }

  void _handleSwipeCloseStart(DragStartDetails details) {
    if (!Navigator.of(context).canPop()) {
      _resetSwipeClose();
      return;
    }
    _isTrackingSwipeClose =
        details.localPosition.dx <= _swipeCloseEdgeWidth(context);
    _swipeCloseDistance = 0;
  }

  void _handleSwipeCloseUpdate(DragUpdateDetails details) {
    if (!_isTrackingSwipeClose) return;
    final delta = details.primaryDelta ?? 0;
    if (delta < 0 && _swipeCloseDistance <= 0) {
      _resetSwipeClose();
      return;
    }
    _swipeCloseDistance += delta;
  }

  Future<void> _handleSwipeCloseEnd(DragEndDetails details) async {
    final primaryVelocity = details.primaryVelocity ?? 0;
    final shouldClose =
        _isTrackingSwipeClose &&
        (_swipeCloseDistance >= _swipeCloseMinDistance ||
            primaryVelocity >= _swipeCloseMinVelocity);

    _resetSwipeClose();
    if (!shouldClose) return;

    FocusScope.of(context).unfocus();
    await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AttractionTextScale(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFF150E08),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF21160C), Color(0xFF150E08)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Column(
                    children: [
                      _LocationTopBar(
                        title: l10n.excursionSelectLocationTitle,
                        onBack: () => context.pop(),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.accent,
                          backgroundColor: const Color(0xFF2D1C0B),
                          onRefresh: _refresh,
                          child: ListView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                            children: [
                              _LocationSectionTitle(
                                title: l10n
                                    .excursionSelectLocationAttractionSection,
                              ),
                              const SizedBox(height: 20),
                              AppListSearchField(
                                controller: _attractionSearchCtrl,
                                hintText: l10n
                                    .excursionSelectLocationAttractionSearchHint,
                                filterTooltip: l10n.attractionsFiltersTitle,
                                activeFilterCount: _filters.activeCount,
                                onFilterTap: _openFilters,
                              ),
                              const SizedBox(height: 24),
                              _buildAttractions(l10n),
                              const SizedBox(height: 24),
                              _LocationPagination(
                                currentPage: _currentPage,
                                totalPages: _totalPages,
                                onPageSelected: _changePage,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.excursionSelectLocationPageCaption(
                                  _currentPage,
                                  _totalPages,
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF6F5848),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _LocationConfirmBar(
                        label: l10n.confirm,
                        enabled: _selectedLocation != null && !_isRefreshing,
                        onConfirm: _confirm,
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: _swipeCloseEdgeWidth(context),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: _handleSwipeCloseStart,
                      onHorizontalDragUpdate: _handleSwipeCloseUpdate,
                      onHorizontalDragEnd: _handleSwipeCloseEnd,
                      onHorizontalDragCancel: _resetSwipeClose,
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

  Widget _buildAttractions(AppLocalizations l10n) {
    if (_isLoading) {
      return const _AttractionGridPlaceholder();
    }
    if (_error != null) {
      return _LocationStateBlock(
        icon: Icons.cloud_off_rounded,
        title: l10n.attractionsLoadFailed,
        actionLabel: l10n.createCategoryRetry,
        onAction: () => _loadAttractions(page: _currentPage),
      );
    }
    if (_items.isEmpty) {
      return _LocationStateBlock(
        icon: Icons.location_off_rounded,
        title: l10n.attractionsNoResults,
        actionLabel: l10n.createCategoryRetry,
        onAction: () => _loadAttractions(page: 1),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 330 ? 1 : 2;
        final aspectRatio = crossAxisCount == 1 ? 0.86 : 0.58;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 24,
            crossAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = _items[index];
            return _AttractionSelectionCard(
              attraction: item,
              selected: _selectedLocation?.id == item.id,
              onTap: () => _selectAttraction(item),
            );
          },
        );
      },
    );
  }
}

class _LocationTopBar extends StatelessWidget {
  const _LocationTopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFF21160C).withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(color: AppColors.accent.withValues(alpha: 0.14)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFFFFF8EF),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFF8EF),
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _LocationSectionTitle extends StatelessWidget {
  const _LocationSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFFFFF8EF),
        fontSize: 28,
        fontWeight: FontWeight.w900,
        height: 1.05,
      ),
    );
  }
}

class _AttractionSelectionCard extends StatelessWidget {
  const _AttractionSelectionCard({
    required this.attraction,
    required this.selected,
    required this.onTap,
  });

  final AttractionVm attraction;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coverUrl = _resolveAttractionCoverUrl(attraction);
    final imageTargetWidth = attractionImageTargetWidth(
      context,
      MediaQuery.sizeOf(context).width / 2,
      minWidth: 320,
      maxWidth: 760,
    );

    return Material(
      color: const Color(0xFF2C2014),
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
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
                      errorBuilder: (_, _, _) => const _AttractionFallback(),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const _AttractionFallback();
                      },
                    )
                  else
                    const _AttractionFallback(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attraction.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFF8EF),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _attractionSubtitle(attraction),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD2BBAD),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    _SelectButton(selected: selected),
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

class _SelectButton extends StatelessWidget {
  const _SelectButton({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? AppColors.accent
              : AppColors.accent.withValues(alpha: 0.38),
          width: 1.5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Text(
        selected ? l10n.excursionSelectLocationSelected : l10n.select,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _AttractionFallback extends StatelessWidget {
  const _AttractionFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF56C4EE), Color(0xFF0E4C5B), Color(0xFF173E2A)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          color: Colors.white.withValues(alpha: 0.78),
          size: 44,
        ),
      ),
    );
  }
}

class _AttractionGridPlaceholder extends StatelessWidget {
  const _AttractionGridPlaceholder();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 24,
        crossAxisSpacing: 16,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (context, index) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF2C2014),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
}

class _LocationStateBlock extends StatelessWidget {
  const _LocationStateBlock({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2014),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFF8EF),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.48),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPagination extends StatelessWidget {
  const _LocationPagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    final pages = <int>{
      1,
      currentPage,
      if (currentPage > 1) currentPage - 1,
      if (currentPage < totalPages) currentPage + 1,
      totalPages,
    }.where((page) => page >= 1 && page <= totalPages).toList()..sort();

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        _PageCircle(
          icon: Icons.chevron_left_rounded,
          enabled: currentPage > 1,
          onTap: () => onPageSelected(currentPage - 1),
        ),
        for (var i = 0; i < pages.length; i++) ...[
          if (i > 0 && pages[i] - pages[i - 1] > 1) const _PageDots(),
          _PageCircle(
            label: '${pages[i]}',
            selected: pages[i] == currentPage,
            onTap: () => onPageSelected(pages[i]),
          ),
        ],
        _PageCircle(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < totalPages,
          onTap: () => onPageSelected(currentPage + 1),
        ),
      ],
    );
  }
}

class _PageCircle extends StatelessWidget {
  const _PageCircle({
    this.label,
    this.icon,
    this.selected = false,
    this.enabled = true,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? AppColors.accent
              : Colors.white.withValues(alpha: 0.025),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: icon == null
            ? Text(
                label ?? '',
                style: TextStyle(
                  color: enabled
                      ? const Color(0xFFD7C7BB)
                      : const Color(0xFF6F5848),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              )
            : Icon(
                icon,
                color: enabled
                    ? const Color(0xFFD7C7BB)
                    : const Color(0xFF6F5848),
              ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 28,
      height: 42,
      child: Center(
        child: Text(
          '...',
          style: TextStyle(
            color: Color(0xFF6F5848),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LocationConfirmBar extends StatelessWidget {
  const _LocationConfirmBar({
    required this.label,
    required this.enabled,
    required this.onConfirm,
  });

  final String label;
  final bool enabled;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF120C07).withValues(alpha: 0.92),
            const Color(0xFF120C07),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 18, 24, 24 + bottomInset),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: enabled ? onConfirm : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.36),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.58),
              padding: const EdgeInsets.symmetric(vertical: 19, horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _resolveAttractionCoverUrl(AttractionVm attraction) {
  final media = attraction.coverMedia;
  if (media == null) return null;

  final fileUrl = resolveAttractionMediaUrl(media)?.trim() ?? '';
  if (fileUrl.isNotEmpty) return fileUrl;

  final externalUrl = media.externalUrl.trim();
  if (externalUrl.isNotEmpty) return externalUrl;

  final sourceUrl = media.sourceUrl.trim();
  if (sourceUrl.isNotEmpty) return sourceUrl;

  return null;
}

String _attractionSubtitle(AttractionVm attraction) {
  final category = attraction.category.trim();
  if (category.isNotEmpty) {
    return category.replaceAll('_', ' ').toUpperCase();
  }
  final country = attraction.countryCode.trim();
  return country.isEmpty ? 'ATTRACTION' : country.toUpperCase();
}
