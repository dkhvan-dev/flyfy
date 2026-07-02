import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/app_list_search_field.dart';
import '../../features/places/place_ui.dart';
import '../../features/places/data/place_api.dart';
import '../../features/places/models/place_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/reference/app_location_label_resolver.dart';
import '../../shared/map/app_map_links.dart';
import '../../shared/widgets/app_city_filter_section.dart';
import '../places/places_filter_sheet.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

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
    this.photoFileIds = const [],
    this.photoImageUrls = const [],
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
  final List<String> photoFileIds;
  final List<String> photoImageUrls;
  final Map<String, ExcursionLocationLocalizedCopy> translations;
  final String categorySlug;

  ExcursionLocationSelection copyWith({String? cityName}) {
    return ExcursionLocationSelection(
      id: id,
      name: name,
      countryCode: countryCode,
      cityId: cityId,
      cityName: cityName ?? this.cityName,
      latitude: latitude,
      longitude: longitude,
      mapUrl: mapUrl,
      coverFileId: coverFileId,
      coverImageUrl: coverImageUrl,
      photoFileIds: photoFileIds,
      photoImageUrls: photoImageUrls,
      translations: translations,
      categorySlug: categorySlug,
    );
  }

  factory ExcursionLocationSelection.fromPlace(
    PlaceVm place, {
    String? fallbackCityName,
  }) {
    final coverMedia = place.coverMedia;
    final coverImageUrl = coverMedia == null
        ? null
        : resolvePlaceMediaUrl(coverMedia);
    final sortedPhotoMedia = List<PlaceMediaVm>.from(
      place.media.where(
        (media) => media.mediaType.trim().toUpperCase() != 'VIDEO',
      ),
    )..sort((a, b) => a.position.compareTo(b.position));
    final photoFileIds = _uniqueNonBlankStrings(
      sortedPhotoMedia.map((media) => media.fileId),
    );
    final photoImageUrls = _uniqueNonBlankStrings(
      sortedPhotoMedia.map(resolvePlaceMediaUrl),
    );
    final cityId = place.cityId.trim();
    final cityName = _selectionCityName(
      cityId: cityId,
      fallbackCityName: fallbackCityName,
    );
    final translations = <String, ExcursionLocationLocalizedCopy>{};
    for (final entry in place.translations.entries) {
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
    final locale = place.locale.trim().toLowerCase().replaceAll('_', '-');
    if (locale.isNotEmpty &&
        (place.title.trim().isNotEmpty ||
            place.description.trim().isNotEmpty)) {
      translations.putIfAbsent(
        locale,
        () => ExcursionLocationLocalizedCopy(
          title: place.title.trim(),
          description: place.description.trim(),
        ),
      );
    }
    return ExcursionLocationSelection(
      id: place.id,
      name: place.title,
      countryCode: place.countryCode,
      cityId: cityId.isEmpty ? null : cityId,
      cityName: cityName,
      latitude: place.latitude,
      longitude: place.longitude,
      mapUrl: place.hasLocation
          ? AppMapLinks.buildUrl(
              latitude: place.latitude!,
              longitude: place.longitude!,
              title: place.title,
              subtitle: cityName ?? place.countryCode,
            )
          : null,
      coverFileId: place.coverFileId,
      coverImageUrl: coverImageUrl,
      photoFileIds: photoFileIds,
      photoImageUrls: photoImageUrls,
      translations: translations,
      categorySlug: place.category.trim(),
    );
  }
}

List<String> _uniqueNonBlankStrings(Iterable<String?> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty || !seen.add(normalized)) {
      continue;
    }
    result.add(normalized);
  }
  return List.unmodifiable(result);
}

String? _selectionCityName({required String cityId, String? fallbackCityName}) {
  final cityName = fallbackCityName?.trim();
  if (cityName != null && cityName.isNotEmpty) {
    return cityName;
  }
  return cityId.trim().isEmpty ? null : cityId.trim();
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
    this.locationLabelResolver,
  });

  final String countryCode;
  final ExcursionLocationSelection? initialSelection;
  final PlaceApi? api;
  final AppLocationLabelResolver? locationLabelResolver;

  @override
  State<ExcursionSelectLocationScreen> createState() =>
      _ExcursionSelectLocationScreenState();
}

class _ExcursionSelectLocationScreenState
    extends State<ExcursionSelectLocationScreen> {
  static const _pageSize = 8;
  static const double _swipeCloseMinDistance = 56;
  static const double _swipeCloseMinVelocity = 700;

  late final PlaceApi _api;
  late final AppLocationLabelResolver _locationLabelResolver;
  final _placeSearchCtrl = TextEditingController();
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
  PlaceFilterResult _filters = PlaceFilterResult.empty;
  List<PlaceVm> _items = const [];
  ExcursionLocationSelection? _selectedLocation;

  int get _totalPages {
    final pages = (_totalItems / _pageSize).ceil();
    return pages < 1 ? 1 : pages;
  }

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? PlaceApi();
    _locationLabelResolver =
        widget.locationLabelResolver ?? AppLocationLabelResolver();
    _selectedCountryCode = widget.countryCode.trim().toUpperCase();
    if (_selectedCountryCode.isEmpty) {
      _selectedCountryCode = 'KZ';
    }
    final initial = widget.initialSelection;
    if (_hasUsableInitialSelection(initial)) {
      _selectedLocation = initial;
    }
    _filters = _initialLocationFilter(initial);
    _placeSearchCtrl.addListener(_onPlaceSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaces());
  }

  bool _hasUsableInitialSelection(ExcursionLocationSelection? initial) {
    return initial != null &&
        initial.id.trim().isNotEmpty &&
        initial.countryCode.trim().toUpperCase() == _selectedCountryCode;
  }

  PlaceFilterResult _initialLocationFilter(
    ExcursionLocationSelection? initial,
  ) {
    final country = AppCountryFilterValue.fromParts(
      countryCode: _selectedCountryCode,
    );
    if (initial == null || initial.countryCode != _selectedCountryCode) {
      return PlaceFilterResult(country: country);
    }

    final city = AppCityFilterValue.fromParts(
      cityId: initial.cityId,
      cityName: initial.cityName,
      countryCode: initial.countryCode,
    );
    return PlaceFilterResult(country: country, city: city);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _placeSearchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onPlaceSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 380),
      () => _loadPlaces(page: 1),
    );
  }

  Future<void> _loadPlaces({int page = 1, bool refresh = false}) async {
    if (!mounted) return;
    final normalizedPage = page < 1 ? 1 : page;
    setState(() {
      _isLoading = _items.isEmpty && !refresh;
      _isRefreshing = refresh;
      _error = null;
    });

    try {
      final locale = Localizations.localeOf(context).languageCode;
      final search = _placeSearchCtrl.text.trim();
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

  Future<void> _refresh() => _loadPlaces(page: _currentPage, refresh: true);

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();

    final result = await showAppModalBottomSheet<PlaceFilterResult>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppDesignSystem.colorsFor(context).transparent,
      builder: (_) => PlacesFilterSheet(
        initial: _filters,
        api: _api,
        searchQuery: _placeSearchCtrl.text,
        fallbackCountryCode: _selectedCountryCode,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _filters = result);
    await _loadPlaces(page: 1);
  }

  Future<void> _changePage(int page) async {
    if (page == _currentPage || _isLoading || page < 1 || page > _totalPages) {
      return;
    }
    FocusScope.of(context).unfocus();
    await _loadPlaces(page: page);
    if (!mounted || !_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectPlace(PlaceVm place) {
    unawaited(_selectPlaceWithLocalizedCity(place));
  }

  Future<void> _selectPlaceWithLocalizedCity(PlaceVm place) async {
    final selection = ExcursionLocationSelection.fromPlace(
      place,
      fallbackCityName: _filters.cityName,
    );
    if (!mounted) return;
    setState(() => _selectedLocation = selection);

    final cityName = await _resolveSelectionCityName(selection);
    if (!mounted || cityName == null) return;
    final current = _selectedLocation;
    if (current == null ||
        current.id != selection.id ||
        current.cityId != selection.cityId) {
      return;
    }
    if ((current.cityName ?? '').trim() == cityName) return;
    setState(() => _selectedLocation = current.copyWith(cityName: cityName));
  }

  Future<String?> _resolveSelectionCityName(
    ExcursionLocationSelection selection,
  ) async {
    final cityId = selection.cityId?.trim();
    final fallbackCityName = selection.cityName?.trim();
    if ((cityId == null || cityId.isEmpty) &&
        (fallbackCityName == null || fallbackCityName.isEmpty)) {
      return null;
    }

    try {
      final resolved = await _locationLabelResolver.resolveCity(
        countryCode: selection.countryCode,
        cityId: cityId,
        cityName: fallbackCityName,
        localeName: Localizations.localeOf(context).toString(),
      );
      final cityName = resolved.trim();
      return cityName.isEmpty ? null : cityName;
    } catch (_) {
      return null;
    }
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
    final colors = AppDesignSystem.colorsFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PlaceTextScale(
      child: Theme(
        data: AppDesignSystem.themeFor(context),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: colors.background,
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
                            color: colors.primary,
                            backgroundColor: colors.surfaceRaised,
                            onRefresh: _refresh,
                            child: ListView(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const AppEdgeInsets.fromLTRB(
                                24,
                                24,
                                24,
                                28,
                              ),
                              children: [
                                _LocationSectionTitle(
                                  title:
                                      l10n.excursionSelectLocationPlaceSection,
                                ),
                                const SizedBox(height: 20),
                                AppListSearchField(
                                  controller: _placeSearchCtrl,
                                  hintText: l10n
                                      .excursionSelectLocationPlaceSearchHint,
                                  filterTooltip: l10n.placesFiltersTitle,
                                  activeFilterCount: _filters.activeCount,
                                  onFilterTap: _openFilters,
                                ),
                                const SizedBox(height: 24),
                                _buildPlaces(l10n),
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
                                  style: AppTextStyle(
                                    color: colors.textMuted,
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
      ),
    );
  }

  Widget _buildPlaces(AppLocalizations l10n) {
    if (_isLoading) {
      return const _PlaceGridPlaceholder();
    }
    if (_error != null) {
      return _LocationStateBlock(
        icon: Icons.cloud_off_rounded,
        title: l10n.placesLoadFailed,
        actionLabel: l10n.createCategoryRetry,
        onAction: () => _loadPlaces(page: _currentPage),
      );
    }
    if (_items.isEmpty) {
      return _LocationStateBlock(
        icon: Icons.location_off_rounded,
        title: l10n.placesNoResults,
        actionLabel: l10n.createCategoryRetry,
        onAction: () => _loadPlaces(page: 1),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 330 ? 1 : 2;
        final aspectRatio = _locationGridAspectRatio(
          context,
          crossAxisCount: crossAxisCount,
        );
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
            return _PlaceSelectionCard(
              place: item,
              selected: _selectedLocation?.id == item.id,
              onTap: () => _selectPlace(item),
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
    final colors = AppDesignSystem.colorsFor(context);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: _locationTopBarMinHeight(context)),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: colors.surface.withValues(alpha: 0.96),
          border: Border(bottom: BorderSide(color: colors.borderPrimary)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: colors.textPrimary,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  color: colors.textPrimary,
                  fontSize: _locationTopBarTitleFontSize(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(width: _locationTopBarSideReserve(context)),
          ],
        ),
      ),
    );
  }
}

class _LocationSectionTitle extends StatelessWidget {
  const _LocationSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyle(
        color: colors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        height: 1.05,
      ),
    );
  }
}

class _PlaceSelectionCard extends StatelessWidget {
  const _PlaceSelectionCard({
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final PlaceVm place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final coverUrl = _resolvePlaceCoverUrl(place);
    final imageTargetWidth = placeImageTargetWidth(
      context,
      MediaQuery.sizeOf(context).width / 2,
      minWidth: _locationCardMinWidth(context).round(),
      maxWidth: 760,
    );
    final categoryLabel = _placeSubtitle(context, place);

    return Material(
      color: colors.surface,
      borderRadius: AppBorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl != null)
                    Image.network(
                      coverUrl,
                      headers: placeImageRequestHeaders(coverUrl),
                      fit: BoxFit.cover,
                      cacheWidth: imageTargetWidth,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => const _PlaceFallback(),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const _PlaceFallback();
                      },
                    )
                  else
                    const _PlaceFallback(),
                  DecoratedBox(
                    decoration: AppBoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.transparent,
                          colors.black.withValues(alpha: 0.42),
                        ],
                        stops: const [0.52, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _PlaceCategoryTag(label: categoryLabel),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const AppEdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 44,
                      child: Text(
                        place.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
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

class _PlaceCategoryTag extends StatelessWidget {
  const _PlaceCategoryTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: DecoratedBox(
              decoration: AppBoxDecoration(
                color: colors.surface.withValues(alpha: 0.86),
                borderRadius: AppBorderRadius.circular(999),
              ),
              child: Padding(
                padding: const AppEdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: colors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectButton extends StatelessWidget {
  const _SelectButton({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 44),
      alignment: Alignment.center,
      decoration: AppBoxDecoration(
        color: selected ? colors.primary : colors.transparent,
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? colors.primary
              : colors.primary.withValues(alpha: 0.38),
          width: 1.5,
        ),
        boxShadow: selected && isDark
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.28),
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
        style: AppTextStyle(
          color: selected ? colors.textPrimary : colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _PlaceFallback extends StatelessWidget {
  const _PlaceFallback();

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surfaceHigh, colors.surfaceTeal, colors.surfaceWarm],
        ),
      ),
      child: Center(
        child: Icon(Icons.landscape_rounded, color: colors.textMuted, size: 44),
      ),
    );
  }
}

class _PlaceGridPlaceholder extends StatelessWidget {
  const _PlaceGridPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 330 ? 1 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 24,
            crossAxisSpacing: 16,
            childAspectRatio: _locationGridAspectRatio(
              context,
              crossAxisCount: crossAxisCount,
            ),
          ),
          itemBuilder: (context, index) {
            return DecoratedBox(
              decoration: AppBoxDecoration(
                color: colors.surface,
                borderRadius: AppBorderRadius.circular(26),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: colors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

double _locationTopBarMinHeight(BuildContext context) {
  final scaledTitleHeight = MediaQuery.textScalerOf(context).scale(23);
  return (scaledTitleHeight + 48).clamp(64.0, 84.0).toDouble();
}

double _locationTopBarTitleFontSize(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.058).clamp(20.0, 24.0).toDouble();
}

double _locationTopBarSideReserve(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.12).clamp(42.0, 52.0).toDouble();
}

double _locationGridAspectRatio(
  BuildContext context, {
  required int crossAxisCount,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (crossAxisCount == 1) {
    return (width / 390).clamp(0.82, 0.92).toDouble();
  }
  return ((width - 320) / 520).clamp(0.0, 1.0).toDouble() * 0.08 + 0.58;
}

double _locationCardMinWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.76).clamp(280.0, 340.0).toDouble();
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
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.surface,
        borderRadius: AppBorderRadius.circular(24),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, color: colors.primary, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary.withValues(alpha: 0.48)),
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
    final colors = AppDesignSystem.colorsFor(context);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppBorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: AppBoxDecoration(
          shape: BoxShape.circle,
          color: selected ? colors.primary : colors.surface,
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: icon == null
            ? Text(
                label ?? '',
                style: AppTextStyle(
                  color: enabled ? colors.textPrimary : colors.textDisabled,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              )
            : Icon(
                icon,
                color: enabled ? colors.textPrimary : colors.textDisabled,
              ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots();

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return SizedBox(
      width: 28,
      height: 48,
      child: Center(
        child: Text(
          '...',
          style: AppTextStyle(
            color: colors.textMuted,
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
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.transparent,
            colors.background.withValues(alpha: 0.92),
            colors.background,
          ],
        ),
      ),
      child: Padding(
        padding: AppEdgeInsets.fromLTRB(24, 18, 24, 24 + bottomInset),
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
              backgroundColor: colors.primary,
              foregroundColor: colors.textPrimary,
              disabledBackgroundColor: colors.primary.withValues(alpha: 0.36),
              disabledForegroundColor: colors.textSecondary.withValues(
                alpha: 0.58,
              ),
              padding: const AppEdgeInsets.symmetric(
                vertical: 19,
                horizontal: 22,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.circular(18),
              ),
              textStyle: const AppTextStyle(
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

String? _resolvePlaceCoverUrl(PlaceVm place) {
  final media = place.coverMedia;
  if (media == null) return null;

  final fileUrl = resolvePlaceMediaUrl(media)?.trim() ?? '';
  if (fileUrl.isNotEmpty) return fileUrl;

  final externalUrl = media.externalUrl.trim();
  if (externalUrl.isNotEmpty) return externalUrl;

  final sourceUrl = media.sourceUrl.trim();
  if (sourceUrl.isNotEmpty) return sourceUrl;

  return null;
}

String _placeSubtitle(BuildContext context, PlaceVm place) {
  final category = place.category.trim();
  if (category.isNotEmpty) {
    final l10n = AppLocalizations.of(context)!;
    return localizedPlaceCategoryLabel(l10n, category);
  }
  final country = place.countryCode.trim();
  return country.isEmpty ? 'PLACE' : country.toUpperCase();
}
