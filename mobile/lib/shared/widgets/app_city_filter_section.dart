import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/reference_api.dart';
import '../../core/ui/app_colors.dart';
import 'app_localized_location_text.dart';

class AppCityFilterValue {
  const AppCityFilterValue({
    this.cityId,
    this.cityName,
    this.countryCode,
  });

  final String? cityId;
  final String? cityName;
  final String? countryCode;

  bool get hasValue =>
      _normalize(cityId) != null || _normalize(cityName) != null;

  String get fallbackLabel {
    final city = _normalize(cityName);
    if (city != null) return city;
    final country = _normalizeCountry(countryCode);
    if (country != null) return country;
    return '';
  }

  bool matches({
    String? cityId,
    String? cityName,
    String? countryCode,
  }) {
    final selectedId = _normalize(this.cityId);
    final candidateId = _normalize(cityId);
    if (selectedId != null && candidateId != null) {
      return selectedId.toLowerCase() == candidateId.toLowerCase();
    }

    final selectedCity = _normalizeCity(this.cityName);
    final candidateCity = _normalizeCity(cityName);
    final selectedCountry = _normalizeCountry(this.countryCode);
    final candidateCountry = _normalizeCountry(countryCode);
    final countryMatches = selectedCountry == null ||
        candidateCountry == null ||
        selectedCountry == candidateCountry;

    final selectedCitySlug = _normalizeCitySlug(selectedCity);
    final candidateCitySlug = _normalizeCitySlug(candidateCity);
    if (countryMatches && selectedId != null && candidateCitySlug != null) {
      return selectedId.toLowerCase() == candidateCitySlug;
    }
    if (countryMatches && candidateId != null && selectedCitySlug != null) {
      return candidateId.toLowerCase() == selectedCitySlug;
    }

    if (selectedCity != null && candidateCity != null) {
      return countryMatches && selectedCity == candidateCity;
    }

    return false;
  }

  static AppCityFilterValue? fromParts({
    String? cityId,
    String? cityName,
    String? countryCode,
  }) {
    final value = AppCityFilterValue(
      cityId: _normalize(cityId),
      cityName: _normalize(cityName),
      countryCode: _normalizeCountry(countryCode),
    );
    return value.hasValue ? value : null;
  }

  factory AppCityFilterValue.fromCity(ReferenceCity city) {
    return AppCityFilterValue(
      cityId: _normalize(city.id),
      cityName: _normalize(city.name),
      countryCode: _normalizeCountry(city.countryCode),
    );
  }
}

class AppCityFilterSection extends StatefulWidget {
  const AppCityFilterSection({
    super.key,
    required this.title,
    required this.allCitiesLabel,
    required this.searchHint,
    required this.noResultsText,
    required this.selectedCity,
    required this.onChanged,
    this.api,
    this.maxResultsHeight = 224,
  });

  final String title;
  final String allCitiesLabel;
  final String searchHint;
  final String noResultsText;
  final AppCityFilterValue? selectedCity;
  final ValueChanged<AppCityFilterValue?> onChanged;
  final ReferenceApi? api;
  final double maxResultsHeight;

  @override
  State<AppCityFilterSection> createState() => _AppCityFilterSectionState();
}

class _AppCityFilterSectionState extends State<AppCityFilterSection> {
  late final ReferenceApi _api;
  final TextEditingController _citySearchController = TextEditingController();
  Timer? _searchDebounce;
  List<ReferenceCity> _visibleCities = const [];
  String _citySearchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ReferenceApi();
    _citySearchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _citySearchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final query = _citySearchController.text.trim();
    if (query == _citySearchQuery) return;
    _citySearchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 260), _runSearch);
  }

  Future<void> _runSearch() async {
    final query = _citySearchQuery;
    if (query.length < 2) {
      if (!mounted) return;
      setState(() {
        _visibleCities = const [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final cities = await _api.searchCities(
        query,
        lang: Localizations.localeOf(context).languageCode,
        limit: 24,
      );
      if (!mounted || _citySearchQuery != query) return;
      setState(() {
        _visibleCities = cities;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted || _citySearchQuery != query) return;
      setState(() {
        _visibleCities = const [];
        _isSearching = false;
      });
    }
  }

  void _selectCity(ReferenceCity city) {
    final value = AppCityFilterValue.fromCity(city);
    final current = widget.selectedCity;
    final next = current != null &&
            value.matches(
              cityId: current.cityId,
              cityName: current.cityName,
              countryCode: current.countryCode,
            )
        ? null
        : value;
    _citySearchController.clear();
    setState(() {
      _citySearchQuery = '';
      _visibleCities = const [];
    });
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCity = widget.selectedCity;
    final queryHasEnoughText = _citySearchQuery.trim().length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF2C2118),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.location_city_rounded,
                  color: AppColors.accent,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: selectedCity == null
                      ? Text(
                          widget.allCitiesLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : AppLocalizedLocationText(
                          countryCode: selectedCity.countryCode,
                          cityId: selectedCity.cityId,
                          cityName: selectedCity.cityName,
                          fallbackText: selectedCity.fallbackLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                if (selectedCity != null)
                  IconButton(
                    tooltip: widget.allCitiesLabel,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onChanged(null),
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
          controller: _citySearchController,
          cursorColor: AppColors.accent,
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: widget.searchHint,
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
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.06)),
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
        if (_isSearching) ...[
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.accent,
              ),
            ),
          ),
        ] else if (queryHasEnoughText) ...[
          const SizedBox(height: 12),
          if (_visibleCities.isEmpty)
            Row(
              children: [
                const Icon(
                  Icons.location_off_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.noResultsText,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.maxResultsHeight),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: _visibleCities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final city = _visibleCities[index];
                  final selected = widget.selectedCity?.matches(
                        cityId: city.id,
                        cityName: city.name,
                        countryCode: city.countryCode,
                      ) ??
                      false;
                  return _CityOptionRow(
                    city: city,
                    selected: selected,
                    onTap: () => _selectCity(city),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

class _CityOptionRow extends StatelessWidget {
  const _CityOptionRow({
    required this.city,
    required this.selected,
    required this.onTap,
  });

  final ReferenceCity city;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final code = city.countryCode.trim().toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                    city.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (code.isNotEmpty) ...[
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
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _normalize(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}

String? _normalizeCountry(String? value) {
  final normalized = _normalize(value)?.toUpperCase();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String? _normalizeCity(String? value) {
  return _normalize(value)
      ?.toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String? _normalizeCitySlug(String? value) {
  final normalized = _normalizeCity(value);
  if (normalized == null) return null;
  final buffer = StringBuffer();
  var lastWasSeparator = false;
  for (final rune in normalized.runes) {
    final isLowerLatin = rune >= 0x61 && rune <= 0x7A;
    final isDigit = rune >= 0x30 && rune <= 0x39;
    if (isLowerLatin || isDigit) {
      buffer.writeCharCode(rune);
      lastWasSeparator = false;
      continue;
    }
    if (!lastWasSeparator && buffer.isNotEmpty) {
      buffer.write('-');
      lastWasSeparator = true;
    }
  }
  final slug = buffer.toString().replaceAll(RegExp(r'-+$'), '');
  return slug.isEmpty ? null : slug;
}
