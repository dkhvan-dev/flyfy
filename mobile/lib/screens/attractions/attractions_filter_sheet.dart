import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../features/attractions/attraction_ui.dart';
import '../../features/attractions/data/attraction_api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_city_filter_section.dart';

/// Result handed back to the discover screen when the user taps "Show N spots".
class AttractionFilterResult {
  const AttractionFilterResult({
    this.city,
    this.category,
    this.minRating,
    this.durationMin,
    this.durationMax,
    this.durationUnit,
    this.priceMin,
    this.priceMax,
  });

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
  String? get countryCode => city?.countryCode;

  bool get isEmpty =>
      city == null &&
      category == null &&
      minRating == null &&
      durationMin == null &&
      durationMax == null &&
      durationUnit == null &&
      priceMin == null &&
      priceMax == null;

  int get activeCount =>
      (city == null ? 0 : 1) +
      (category == null ? 0 : 1) +
      (minRating == null ? 0 : 1) +
      (durationMin == null && durationMax == null && durationUnit == null
          ? 0
          : 1) +
      (priceMin == null ? 0 : 1) +
      (priceMax == null ? 0 : 1);

  static const empty = AttractionFilterResult();

  AttractionFilterResult copyWith({
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
    return AttractionFilterResult(
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

class AttractionsFilterSheet extends StatefulWidget {
  const AttractionsFilterSheet({
    super.key,
    required this.initial,
    this.api,
    this.searchQuery,
  });

  final AttractionFilterResult initial;
  final AttractionApi? api;
  final String? searchQuery;

  @override
  State<AttractionsFilterSheet> createState() => _AttractionsFilterSheetState();
}

class _AttractionsFilterSheetState extends State<AttractionsFilterSheet> {
  static const _hourMin = 1;
  static const _hourMax = 12;
  static const _defaultRange = RangeValues(2.0, 8.0);

  late final AttractionApi _api;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;

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
    _api = widget.api ?? AttractionApi();

    final initial = widget.initial;
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
      final result = await _api.getAttractions(
        search: widget.searchQuery?.trim().isNotEmpty == true
            ? widget.searchQuery!.trim()
            : null,
        countryCode: staged.countryCode,
        cityId: staged.cityId,
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

  AttractionFilterResult _stageResult() {
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

    return AttractionFilterResult(
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
    return AttractionTextScale(
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          final adaptive = AttractionAdaptive.of(context);
          final size = MediaQuery.sizeOf(context);
          final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
          final padX = adaptive.scale(22, minFactor: 0.82, maxFactor: 1.05);
          final sideInset = adaptive.scale(
            16,
            minFactor: 0.62,
            maxFactor: 1.0,
          );
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

          return AppDismissibleModalSheet(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: viewInsets),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: sideInset),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 393),
                  child: SizedBox(
                    height: sheetHeight,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF211508),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xBF000000),
                            blurRadius: 70,
                            offset: Offset(0, 42),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          children: [
                            _buildHeader(l10n, adaptive, padX),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  padX,
                                  adaptive.scale(32),
                                  padX,
                                  adaptive.scale(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCountrySection(
                                      l10n,
                                      adaptive,
                                    ),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    AppLocalizations l10n,
    AttractionAdaptive adaptive,
    double padX,
  ) {
    return AppFilterSheetHeader(
      title: l10n.attractionsFiltersTitle,
      clearLabel: l10n.attractionFilterClear,
      onClear: _clearAll,
      height: adaptive.scale(50, minFactor: 0.9),
      horizontalPadding: padX,
      titleFontSize: adaptive.scale(17),
      clearFontSize: adaptive.scale(12),
    );
  }

  Widget _buildCountrySection(
    AppLocalizations l10n,
    AttractionAdaptive adaptive,
  ) {
    return AppCityFilterSection(
      title: l10n.locationFilterCitySection,
      allCitiesLabel: l10n.locationFilterAllCities,
      searchHint: l10n.locationFilterCitySearchHint,
      noResultsText: l10n.locationFilterCityNoResults,
      selectedCity: _city,
      onChanged: _setCity,
    );
  }

  Widget _buildCategoriesSection(
    AppLocalizations l10n,
    AttractionAdaptive adaptive,
  ) {
    final categories = <_ChipModel>[
      _ChipModel(
        label: l10n.attractionFilterCategoryAll,
        value: null,
        wide: true,
      ),
      _ChipModel(label: l10n.attractionFilterCategoryParks, value: 'PARK'),
      _ChipModel(label: l10n.attractionFilterCategoryMuseums, value: 'MUSEUM'),
      _ChipModel(label: l10n.attractionFilterCategoryNature, value: 'NATURE'),
      _ChipModel(
        label: l10n.attractionFilterCategoryArchitecture,
        value: 'ARCHITECTURE',
      ),
      _ChipModel(label: l10n.attractionFilterCategoryBeach, value: 'BEACH'),
      _ChipModel(label: l10n.attractionFilterCategoryTemple, value: 'TEMPLE'),
      _ChipModel(
        label: l10n.attractionFilterCategoryEntertainment,
        value: 'ENTERTAINMENT',
      ),
      _ChipModel(label: l10n.attractionFilterCategoryFood, value: 'FOOD'),
      _ChipModel(
        label: l10n.attractionFilterCategoryShopping,
        value: 'SHOPPING',
      ),
    ];

    return _SectionContainer(
      adaptive: adaptive,
      header: l10n.attractionFilterCategoriesSection,
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

  Widget _buildRatingSection(
    AppLocalizations l10n,
    AttractionAdaptive adaptive,
  ) {
    final options = <({String label, double? value})>[
      (label: l10n.attractionFilterRatingAny, value: null),
      (label: '3.0 ☆', value: 3.0),
      (label: '4.0 ★', value: 4.0),
      (label: '4.5 ☆', value: 4.5),
    ];

    return _SectionContainer(
      adaptive: adaptive,
      header: l10n.attractionFilterMinRatingSection,
      child: Container(
        height: adaptive.scale(50),
        padding: EdgeInsets.symmetric(horizontal: adaptive.scale(8)),
        decoration: BoxDecoration(
          color: const Color(0xFF2D1F11),
          border: Border.all(color: const Color(0xFF443121)),
          borderRadius: BorderRadius.circular(999),
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

  Widget _buildDurationSection(
    AppLocalizations l10n,
    AttractionAdaptive adaptive,
  ) {
    final presets = <({_DurationPreset preset, String label})>[
      (
        preset: _DurationPreset.short,
        label: l10n.attractionFilterDurationShort,
      ),
      (
        preset: _DurationPreset.medium,
        label: l10n.attractionFilterDurationMedium,
      ),
      (
        preset: _DurationPreset.fullDay,
        label: l10n.attractionFilterDurationFullDay,
      ),
      (
        preset: _DurationPreset.multiDay,
        label: l10n.attractionFilterDurationMultiDay,
      ),
    ];

    return _SectionContainer(
      adaptive: adaptive,
      header: l10n.attractionFilterDurationSection,
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

  Widget _buildRangeSection(
    AppLocalizations l10n,
    AttractionAdaptive adaptive,
  ) {
    final value = l10n.attractionFilterRangeValue(
      _hours.start.round(),
      _hours.end.round(),
    );

    return _SectionContainer(
      adaptive: adaptive,
      header: l10n.attractionFilterRangeSection,
      trailing: Text(
        value,
        style: TextStyle(
          color: AppColors.accent,
          fontSize: adaptive.scale(17),
          fontWeight: FontWeight.w900,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: adaptive.scale(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: adaptive.scale(4),
                activeTrackColor: AppColors.accent,
                inactiveTrackColor: const Color(0xFF5A4B3B),
                thumbColor: AppColors.accent,
                overlayColor: AppColors.accent.withValues(alpha: 0.18),
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
              padding: EdgeInsets.symmetric(horizontal: adaptive.scale(6)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.attractionFilterRangeMinTick.toUpperCase(),
                    style: TextStyle(
                      color: const Color(0xFF8F8378),
                      fontSize: adaptive.scale(11),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    l10n.attractionFilterRangeMaxTick.toUpperCase(),
                    style: TextStyle(
                      color: const Color(0xFF8F8378),
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

  Widget _buildPriceSection(
    AppLocalizations l10n,
    AttractionAdaptive adaptive,
  ) {
    return _SectionContainer(
      adaptive: adaptive,
      header: l10n.attractionFilterPriceRangeSection,
      child: Row(
        children: [
          Expanded(
            child: _UnderlineNumberField(
              controller: _minPriceController,
              hint: l10n.attractionMinPriceLabel,
              onChanged: (_) => _schedulePreview(),
              adaptive: adaptive,
            ),
          ),
          SizedBox(width: adaptive.scale(24)),
          Expanded(
            child: _UnderlineNumberField(
              controller: _maxPriceController,
              hint: l10n.attractionMaxPriceLabel,
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
    AttractionAdaptive adaptive,
    double padX,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        padX,
        adaptive.scale(22),
        padX,
        adaptive.scale(22),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF2211508), Color(0xFF2A1B0B)],
        ),
        border: const Border(top: BorderSide(color: Color(0xFF3B260D))),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 17),
          ),
        ],
      ),
      child: AppFilterApplyButton(
        label: l10n.attractionFilterShowSpots(_previewCount),
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

  final AttractionAdaptive adaptive;
  final String header;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                header.toUpperCase(),
                style: TextStyle(
                  color: const Color(0xFFD6BDAB),
                  fontSize: adaptive.scale(12),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
            ),
            if (trailing != null) trailing!,
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
  final AttractionAdaptive adaptive;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final hPad = adaptive.scale(wide ? 19 : 18);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: hPad,
            vertical: adaptive.scale(9),
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : const Color(0xFF2D1F11),
            border:
                selected ? null : Border.all(color: const Color(0xFF443121)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: adaptive.scale(20)),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFD6BDAB),
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
  final AttractionAdaptive adaptive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: adaptive.scale(40),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : const Color(0xFFD6BDAB),
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
  final AttractionAdaptive adaptive;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      onChanged: onChanged,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: adaptive.scale(13),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.6,
      ),
      decoration: InputDecoration(
        hintText: hint.toUpperCase(),
        hintStyle: TextStyle(
          color: const Color(0xFF8F8378),
          fontSize: adaptive.scale(13),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF3B260D)),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF3B260D)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: adaptive.scale(4),
          vertical: adaptive.scale(10),
        ),
      ),
    );
  }
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
