import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

import '../../core/ui/filter_sheet_chrome.dart';
import '../../features/places/data/place_api.dart';
import '../../features/places/place_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_city_filter_section.dart';

/// Result handed back to the discover screen when the user taps "Show N spots".
class PlaceFilterResult {
  const PlaceFilterResult({
    this.country,
    this.city,
    this.category,
    this.minRating,
    this.durationMin,
    this.durationMax,
    this.durationUnit,
    this.priceMin,
    this.priceMax,
  });

  final AppCountryFilterValue? country;
  final AppCityFilterValue? city;
  final String? category;
  final double? minRating;
  final int? durationMin;
  final int? durationMax;
  final String? durationUnit;
  final double? priceMin;
  final double? priceMax;

  String? get cityId => city?.cityId;
  String? get cityName => city?.cityName;
  String? get countryCode => country?.countryCode ?? city?.countryCode;

  bool get isEmpty =>
      country == null &&
      city == null &&
      category == null &&
      minRating == null &&
      durationMin == null &&
      durationMax == null &&
      durationUnit == null &&
      priceMin == null &&
      priceMax == null;

  int get activeCount =>
      (country == null ? 0 : 1) +
      (city == null ? 0 : 1) +
      (category == null ? 0 : 1) +
      (minRating == null ? 0 : 1) +
      (durationMin == null && durationMax == null && durationUnit == null
          ? 0
          : 1) +
      (priceMin == null ? 0 : 1) +
      (priceMax == null ? 0 : 1);

  static const empty = PlaceFilterResult();

  PlaceFilterResult copyWith({
    Object? country = _unset,
    Object? city = _unset,
    String? category,
    bool clearCategory = false,
    double? minRating,
    bool clearMinRating = false,
    int? durationMin,
    int? durationMax,
    String? durationUnit,
    bool clearDuration = false,
    double? priceMin,
    bool clearPriceMin = false,
    double? priceMax,
    bool clearPriceMax = false,
  }) {
    return PlaceFilterResult(
      country: identical(country, _unset)
          ? this.country
          : country as AppCountryFilterValue?,
      city: identical(city, _unset) ? this.city : city as AppCityFilterValue?,
      category: clearCategory ? null : category ?? this.category,
      minRating: clearMinRating ? null : minRating ?? this.minRating,
      durationMin: clearDuration ? null : durationMin ?? this.durationMin,
      durationMax: clearDuration ? null : durationMax ?? this.durationMax,
      durationUnit: clearDuration ? null : durationUnit ?? this.durationUnit,
      priceMin: clearPriceMin ? null : priceMin ?? this.priceMin,
      priceMax: clearPriceMax ? null : priceMax ?? this.priceMax,
    );
  }

  static const Object _unset = Object();
}

enum _DurationPreset { none, short, medium, fullDay, multiDay }

extension _DurationPresetX on _DurationPreset {
  ({int min, int max, String unit})? toRange() {
    switch (this) {
      case _DurationPreset.short:
        return (min: 1, max: 2, unit: 'HOURS');
      case _DurationPreset.medium:
        return (min: 2, max: 5, unit: 'HOURS');
      case _DurationPreset.fullDay:
        return (min: 5, max: 12, unit: 'HOURS');
      case _DurationPreset.multiDay:
        return (min: 1, max: 7, unit: 'DAYS');
      case _DurationPreset.none:
        return null;
    }
  }
}

_DurationPreset _presetFromRange({
  required int min,
  required int max,
  required String unit,
}) {
  if (unit == 'DAYS') return _DurationPreset.multiDay;
  if (min == 1 && max == 2) return _DurationPreset.short;
  if (min == 2 && max == 5) return _DurationPreset.medium;
  if (min == 5 && max == 12) return _DurationPreset.fullDay;
  return _DurationPreset.none;
}

class PlacesFilterSheet extends StatefulWidget {
  const PlacesFilterSheet({
    super.key,
    required this.initial,
    this.api,
    this.searchQuery,
    this.fallbackCountryCode,
    this.accessCityId,
  });

  final PlaceFilterResult initial;
  final PlaceApi? api;
  final String? searchQuery;
  final String? fallbackCountryCode;
  final String? accessCityId;

  @override
  State<PlacesFilterSheet> createState() => _PlacesFilterSheetState();
}

class _PlacesFilterSheetState extends State<PlacesFilterSheet> {
  static const _hourMin = 1;
  static const _hourMax = 12;
  static const _defaultRange = RangeValues(1.0, 12.0);

  late final PlaceApi _api;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;

  AppCountryFilterValue? _country;
  AppCityFilterValue? _city;
  String? _category;
  double? _minRating;
  _DurationPreset _preset = _DurationPreset.none;
  RangeValues _hours = _defaultRange;
  Timer? _previewDebounce;
  int _previewCount = 0;
  bool _previewLoading = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? PlaceApi();

    final initial = widget.initial;
    _country =
        initial.country ??
        AppCountryFilterValue.fromParts(
          countryCode: initial.city?.countryCode ?? widget.fallbackCountryCode,
        );
    _city = initial.city;
    _category = initial.category;
    _minRating = initial.minRating;

    if (initial.durationMin != null && initial.durationMax != null) {
      final unit = initial.durationUnit ?? 'HOURS';
      _preset = _presetFromRange(
        min: initial.durationMin!,
        max: initial.durationMax!,
        unit: unit,
      );
      if (unit == 'HOURS') {
        _hours = RangeValues(
          initial.durationMin!.toDouble().clamp(
            _hourMin.toDouble(),
            _hourMax.toDouble(),
          ),
          initial.durationMax!.toDouble().clamp(
            _hourMin.toDouble(),
            _hourMax.toDouble(),
          ),
        );
      }
    }

    _minPriceController = TextEditingController(
      text: _formatInitial(initial.priceMin),
    );
    _maxPriceController = TextEditingController(
      text: _formatInitial(initial.priceMax),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPreview());
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  // ---- preview count ------------------------------------------------------

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(
      const Duration(milliseconds: 250),
      _refreshPreview,
    );
  }

  Future<void> _refreshPreview() async {
    if (!mounted) return;
    setState(() => _previewLoading = true);

    final staged = _stageResult();
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final result = await _api.getPlaces(
        search: widget.searchQuery?.trim().isNotEmpty == true
            ? widget.searchQuery!.trim()
            : null,
        countryCode: staged.countryCode ?? _normalizedFallbackCountryCode(),
        cityId: staged.cityId,
        accessCityId: _normalizedAccessCityId(),
        category: staged.category,
        minRating: staged.minRating,
        durationMin: staged.durationMin,
        durationMax: staged.durationMax,
        durationUnit: staged.durationUnit,
        priceMin: staged.priceMin,
        priceMax: staged.priceMax,
        locale: locale,
        limit: 1,
      );
      if (!mounted) return;
      setState(() {
        _previewCount = result.total;
        _previewLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _previewLoading = false);
    }
  }

  String? _normalizedFallbackCountryCode() {
    final value = widget.fallbackCountryCode?.trim().toUpperCase() ?? '';
    return value.isEmpty ? null : value;
  }

  String? _normalizedAccessCityId() {
    final value = widget.accessCityId?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  PlaceFilterResult _stageResult() {
    int? durationMin;
    int? durationMax;
    String? durationUnit;

    if (_preset == _DurationPreset.multiDay) {
      durationMin = 1;
      durationMax = 7;
      durationUnit = 'DAYS';
    } else {
      final start = _hours.start.round();
      final end = _hours.end.round();
      // Treat full-range as "no duration filter" in HOURS mode
      if (start != _hourMin || end != _hourMax) {
        durationMin = start;
        durationMax = end;
        durationUnit = 'HOURS';
      }
    }

    return PlaceFilterResult(
      country: _country,
      city: _city,
      category: _category,
      minRating: _minRating,
      durationMin: durationMin,
      durationMax: durationMax,
      durationUnit: durationUnit,
      priceMin: _parseDouble(_minPriceController.text),
      priceMax: _parseDouble(_maxPriceController.text),
    );
  }

  // ---- handlers -----------------------------------------------------------

  void _setCountry(AppCountryFilterValue? value) {
    setState(() {
      _country = value;
      _city = null;
    });
    _schedulePreview();
  }

  void _setCity(AppCityFilterValue? value) {
    setState(() => _city = value);
    _schedulePreview();
  }

  void _setCategory(String? value) {
    setState(() => _category = value);
    _schedulePreview();
  }

  void _setRating(double? value) {
    setState(() => _minRating = value);
    _schedulePreview();
  }

  void _setPreset(_DurationPreset preset) {
    setState(() {
      _preset = preset;
      final range = preset.toRange();
      if (range != null && range.unit == 'HOURS') {
        _hours = RangeValues(range.min.toDouble(), range.max.toDouble());
      }
    });
    _schedulePreview();
  }

  void _setHours(RangeValues values) {
    setState(() {
      _hours = values;
      _preset = _presetFromRange(
        min: values.start.round(),
        max: values.end.round(),
        unit: 'HOURS',
      );
    });
    _schedulePreview();
  }

  void _clearAll() {
    setState(() {
      _country = null;
      _city = null;
      _category = null;
      _minRating = null;
      _preset = _DurationPreset.none;
      _hours = _defaultRange;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
    _schedulePreview();
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: PlaceTextScale(
        child: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            final colors = AppDesignSystem.colorsFor(context);
            final adaptive = PlaceAdaptive.of(context);
            final size = MediaQuery.sizeOf(context);
            final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
            final padX = adaptive.scale(22, minFactor: 0.82, maxFactor: 1.05);
            final availableHeight = size.height - viewInsets;
            final reservedTopGap = adaptive.scale(70, minFactor: 0.7);
            final minSheetHeight = adaptive.scale(260, minFactor: 0.75);
            final desiredHeight = availableHeight - reservedTopGap;
            final sheetHeight = desiredHeight
                .clamp(
                  availableHeight < minSheetHeight
                      ? availableHeight
                      : minSheetHeight,
                  availableHeight,
                )
                .toDouble();

            return AppModalSheetFrame(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: AppEdgeInsets.only(bottom: viewInsets),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SizedBox(
                    height: sheetHeight,
                    child: Container(
                      decoration: _placesFilterSheetDecoration(context, colors),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          children: [
                            _buildHeader(l10n, adaptive, padX),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: AppEdgeInsets.fromLTRB(
                                  padX,
                                  adaptive.scale(32),
                                  padX,
                                  adaptive.scale(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCountrySection(l10n, adaptive),
                                    if (_country != null) ...[
                                      SizedBox(height: adaptive.scale(38)),
                                      _buildCitySection(l10n, adaptive),
                                    ],
                                    SizedBox(height: adaptive.scale(38)),
                                    _buildCategoriesSection(l10n, adaptive),
                                    SizedBox(height: adaptive.scale(38)),
                                    _buildRatingSection(l10n, adaptive),
                                    SizedBox(height: adaptive.scale(38)),
                                    _buildDurationSection(l10n, adaptive),
                                    SizedBox(height: adaptive.scale(38)),
                                    _buildRangeSection(l10n, adaptive),
                                    SizedBox(height: adaptive.scale(38)),
                                    _buildPriceSection(l10n, adaptive),
                                  ],
                                ),
                              ),
                            ),
                            _buildFooter(l10n, adaptive, padX),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    AppLocalizations l10n,
    PlaceAdaptive adaptive,
    double padX,
  ) {
    return AppFilterSheetHeader(
      title: l10n.placesFiltersTitle,
      clearLabel: l10n.placeFilterClear,
      onClear: _clearAll,
      height: adaptive.scale(50, minFactor: 0.9),
      horizontalPadding: padX,
      titleFontSize: adaptive.scale(17),
      clearFontSize: adaptive.scale(12),
    );
  }

  Widget _buildCountrySection(AppLocalizations l10n, PlaceAdaptive adaptive) {
    return AppCountryFilterSection(
      title: l10n.placeFilterCountrySection,
      allCountriesLabel: l10n.placeFilterCountryAll,
      searchHint: l10n.placeFilterCountrySearchHint,
      noResultsText: l10n.placeFilterCountryNoResults,
      selectedCountry: _country,
      onChanged: _setCountry,
    );
  }

  Widget _buildCitySection(AppLocalizations l10n, PlaceAdaptive adaptive) {
    return AppCityFilterSection(
      title: l10n.locationFilterCitySection,
      allCitiesLabel: l10n.locationFilterAllCities,
      searchHint: l10n.locationFilterCitySearchHint,
      noResultsText: l10n.locationFilterCityNoResults,
      selectedCity: _city,
      onChanged: _setCity,
      countryCode: _country?.countryCode,
    );
  }

  Widget _buildCategoriesSection(
    AppLocalizations l10n,
    PlaceAdaptive adaptive,
  ) {
    final categories = <_ChipModel>[
      _ChipModel(label: l10n.placeFilterCategoryAll, value: null, wide: true),
      _ChipModel(label: l10n.placeFilterCategoryParks, value: 'PARK'),
      _ChipModel(label: l10n.placeFilterCategoryMuseums, value: 'MUSEUM'),
      _ChipModel(label: l10n.placeFilterCategoryNature, value: 'NATURE'),
      _ChipModel(
        label: l10n.placeFilterCategoryArchitecture,
        value: 'ARCHITECTURE',
      ),
      _ChipModel(label: l10n.placeFilterCategoryBeach, value: 'BEACH'),
      _ChipModel(label: l10n.placeFilterCategoryTemple, value: 'TEMPLE'),
      _ChipModel(
        label: l10n.placeFilterCategoryEntertainment,
        value: 'ENTERTAINMENT',
      ),
      _ChipModel(label: l10n.placeFilterCategoryFood, value: 'FOOD'),
      _ChipModel(label: l10n.placeFilterCategoryMarket, value: 'MARKET'),
      _ChipModel(label: l10n.placeFilterCategoryShopping, value: 'SHOPPING'),
    ];

    return _SectionContainer(
      adaptive: adaptive,
      header: l10n.placeFilterCategoriesSection,
      child: Wrap(
        spacing: adaptive.scale(8),
        runSpacing: adaptive.scale(8),
        children: [
          for (final c in categories)
            _PillChip(
              label: c.label,
              selected: _category == c.value,
              wide: c.wide,
              adaptive: adaptive,
              onTap: () => _setCategory(c.value),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(AppLocalizations l10n, PlaceAdaptive adaptive) {
    final options = <({String label, double? value})>[
      (label: l10n.placeFilterRatingAny, value: null),
      (label: '3.0 ☆', value: 3.0),
      (label: '4.0 ★', value: 4.0),
      (label: '4.5 ☆', value: 4.5),
    ];

    return _SectionContainer(
      adaptive: adaptive,
      header: l10n.placeFilterMinRatingSection,
      child: Container(
        height: adaptive.scale(50),
        padding: AppEdgeInsets.symmetric(horizontal: adaptive.scale(8)),
        decoration: AppBoxDecoration(
          color: AppDesignSystem.colorsFor(context).surfaceRaised,
          border: Border.all(
            color: AppDesignSystem.colorsFor(context).borderSoft,
          ),
          borderRadius: AppBorderRadius.circular(999),
        ),
        child: Row(
          children: [
            for (final opt in options)
              Expanded(
                child: _RatingPill(
                  label: opt.label,
                  selected: _minRating == opt.value,
                  adaptive: adaptive,
                  onTap: () => _setRating(opt.value),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSection(AppLocalizations l10n, PlaceAdaptive adaptive) {
    final presets = <({_DurationPreset preset, String label})>[
      (preset: _DurationPreset.short, label: l10n.placeFilterDurationShort),
      (preset: _DurationPreset.medium, label: l10n.placeFilterDurationMedium),
      (preset: _DurationPreset.fullDay, label: l10n.placeFilterDurationFullDay),
      (
        preset: _DurationPreset.multiDay,
        label: l10n.placeFilterDurationMultiDay,
      ),
    ];

    return _SectionContainer(
      adaptive: adaptive,
      header: l10n.placeFilterDurationSection,
      child: Wrap(
        spacing: adaptive.scale(7),
        runSpacing: adaptive.scale(8),
        children: [
          for (final p in presets)
            _PillChip(
              label: p.label,
              selected: _preset == p.preset,
              adaptive: adaptive,
              onTap: () => _setPreset(p.preset),
            ),
        ],
      ),
    );
  }

  Widget _buildRangeSection(AppLocalizations l10n, PlaceAdaptive adaptive) {
    final value = l10n.placeFilterRangeValue(
      _hours.start.round(),
      _hours.end.round(),
    );

    return _SectionContainer(
      adaptive: adaptive,
      header: l10n.placeFilterRangeSection,
      trailing: Text(
        value,
        style: AppTextStyle(
          color: AppDesignSystem.colorsFor(context).primary,
          fontSize: adaptive.scale(17),
          fontWeight: FontWeight.w900,
        ),
      ),
      child: Padding(
        padding: AppEdgeInsets.only(top: adaptive.scale(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: adaptive.scale(4),
                activeTrackColor: AppDesignSystem.colorsFor(context).primary,
                inactiveTrackColor: AppDesignSystem.colorsFor(
                  context,
                ).borderSoft,
                thumbColor: AppDesignSystem.colorsFor(context).primary,
                overlayColor: AppDesignSystem.colorsFor(context).primarySoft,
                rangeThumbShape: RoundRangeSliderThumbShape(
                  enabledThumbRadius: adaptive.scale(11),
                ),
                rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
              ),
              child: RangeSlider(
                values: _hours,
                min: _hourMin.toDouble(),
                max: _hourMax.toDouble(),
                divisions: _hourMax - _hourMin,
                onChanged: _setHours,
              ),
            ),
            Padding(
              padding: AppEdgeInsets.symmetric(horizontal: adaptive.scale(6)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.placeFilterRangeMinTick.toUpperCase(),
                    style: AppTextStyle(
                      color: AppDesignSystem.colorsFor(context).textSecondary,
                      fontSize: adaptive.scale(11),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    l10n.placeFilterRangeMaxTick.toUpperCase(),
                    style: AppTextStyle(
                      color: AppDesignSystem.colorsFor(context).textSecondary,
                      fontSize: adaptive.scale(11),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
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

  Widget _buildPriceSection(AppLocalizations l10n, PlaceAdaptive adaptive) {
    return _SectionContainer(
      adaptive: adaptive,
      header: l10n.placeFilterPriceRangeSection,
      child: Row(
        children: [
          Expanded(
            child: _UnderlineNumberField(
              controller: _minPriceController,
              hint: l10n.placeMinPriceLabel,
              onChanged: (_) => _schedulePreview(),
              adaptive: adaptive,
            ),
          ),
          SizedBox(width: adaptive.scale(24)),
          Expanded(
            child: _UnderlineNumberField(
              controller: _maxPriceController,
              hint: l10n.placeMaxPriceLabel,
              onChanged: (_) => _schedulePreview(),
              adaptive: adaptive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    AppLocalizations l10n,
    PlaceAdaptive adaptive,
    double padX,
  ) {
    final colors = AppDesignSystem.colorsFor(context);

    return Container(
      padding: AppEdgeInsets.fromLTRB(
        padX,
        adaptive.scale(22),
        padX,
        adaptive.scale(22),
      ),
      decoration: AppBoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.borderSoft)),
      ),
      child: AppFilterApplyButton(
        label: l10n.placeFilterShowSpots(_previewCount),
        onTap: () => Navigator.of(context).pop(_stageResult()),
        minHeight: adaptive.scale(51),
        fontSize: adaptive.scale(14),
        borderRadius: adaptive.radius(999),
        isLoading: _previewLoading,
      ),
    );
  }
}

class _ChipModel {
  const _ChipModel({
    required this.label,
    required this.value,
    this.wide = false,
  });

  final String label;
  final String? value;
  final bool wide;
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({
    required this.adaptive,
    required this.header,
    required this.child,
    this.trailing,
  });

  final PlaceAdaptive adaptive;
  final String header;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                header.toUpperCase(),
                style: AppTextStyle(
                  color: colors.primary,
                  fontSize: adaptive.scale(12),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        SizedBox(height: adaptive.scale(18)),
        child,
      ],
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.selected,
    required this.adaptive,
    required this.onTap,
    this.wide = false,
  });

  final String label;
  final bool selected;
  final PlaceAdaptive adaptive;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final hPad = adaptive.scale(wide ? 19 : 18);
    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(999),
        child: Ink(
          padding: AppEdgeInsets.symmetric(
            horizontal: hPad,
            vertical: adaptive.scale(9),
          ),
          decoration: AppBoxDecoration(
            color: selected ? colors.primary : colors.surfaceRaised,
            border: Border.all(
              color: selected ? colors.borderPrimary : colors.borderSoft,
            ),
            borderRadius: AppBorderRadius.circular(999),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: adaptive.scale(20)),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: AppTextStyle(
                  color: selected ? colors.textPrimary : colors.textSecondary,
                  fontSize: adaptive.scale(14),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({
    required this.label,
    required this.selected,
    required this.adaptive,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final PlaceAdaptive adaptive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.circular(999),
      child: Container(
        height: adaptive.scale(40),
        decoration: AppBoxDecoration(
          color: selected ? colors.primary : colors.transparent,
          borderRadius: AppBorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyle(
            color: selected ? colors.textPrimary : colors.textSecondary,
            fontSize: adaptive.scale(14),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _UnderlineNumberField extends StatelessWidget {
  const _UnderlineNumberField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.adaptive,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final PlaceAdaptive adaptive;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      onChanged: onChanged,
      style: AppTextStyle(
        color: colors.textPrimary,
        fontSize: adaptive.scale(13),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.6,
      ),
      decoration: AppInputDecoration(
        hintText: hint.toUpperCase(),
        hintStyle: AppTextStyle(
          color: colors.textSecondary,
          fontSize: adaptive.scale(13),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.borderSoft),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.borderSoft),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.primary),
        ),
        contentPadding: AppEdgeInsets.symmetric(
          horizontal: adaptive.scale(4),
          vertical: adaptive.scale(10),
        ),
      ),
    );
  }
}

BoxDecoration _placesFilterSheetDecoration(
  BuildContext context,
  AppColors colors,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return AppBoxDecoration(
    color: colors.surface,
    borderRadius: const AppBorderRadius.vertical(
      top: AppRadiusValue.circular(16),
    ),
    border: Border.all(color: colors.border),
    boxShadow: isDark
        ? [
            BoxShadow(
              color: colors.black.withValues(alpha: 0.24),
              blurRadius: 70,
              offset: const Offset(0, 42),
            ),
          ]
        : const [],
  );
}

String _formatInitial(double? v) {
  if (v == null) return '';
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2);
}

double? _parseDouble(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final parsed = double.tryParse(trimmed);
  if (parsed == null || parsed < 0) return null;
  return parsed;
}
