import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../core/network/reference_api.dart';
import '../reference/app_location_label_resolver.dart';
import 'app_localized_location_text.dart';

class AppCityFilterValue {
  const AppCityFilterValue({this.cityId, this.cityName, this.countryCode});

  final String? cityId;
  final String? cityName;
  final String? countryCode;

  bool get hasValue =>
      _normalize(cityId) != null || _normalize(cityName) != null;

  String? get queryCityId => _normalize(cityId) ?? _normalizeCitySlug(cityName);

  String get fallbackLabel {
    final city = _normalize(cityName);
    if (city != null) return city;
    final country = _normalizeCountry(countryCode);
    if (country != null) return country;
    return '';
  }

  bool matches({String? cityId, String? cityName, String? countryCode}) {
    final selectedId = _normalize(this.cityId);
    final candidateId = _normalize(cityId);
    if (selectedId != null && candidateId != null) {
      return selectedId.toLowerCase() == candidateId.toLowerCase();
    }

    final selectedCity = _normalizeCity(this.cityName);
    final candidateCity = _normalizeCity(cityName);
    final selectedCountry = _normalizeCountry(this.countryCode);
    final candidateCountry = _normalizeCountry(countryCode);
    final countryMatches =
        selectedCountry == null ||
        candidateCountry == null ||
        selectedCountry == candidateCountry;

    final selectedCitySlug = _normalizeCitySlug(selectedCity);
    final candidateCitySlug = _normalizeCitySlug(candidateCity);
    if (countryMatches &&
        selectedCitySlug != null &&
        candidateCitySlug != null) {
      return selectedCitySlug == candidateCitySlug;
    }
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

class AppCountryFilterValue {
  const AppCountryFilterValue({this._countryCode, this.countryName});

  final String? _countryCode;
  final String? countryName;

  String? get countryCode => _normalizeCountry(_countryCode);

  bool get hasValue => _normalizeCountry(countryCode) != null;

  String get fallbackLabel {
    final name = _normalize(countryName);
    if (name != null) return name;
    return _normalizeCountry(countryCode) ?? '';
  }

  bool matches({String? countryCode, String? countryName}) {
    final selectedCode = _normalizeCountry(this.countryCode);
    final candidateCode = _normalizeCountry(countryCode);
    if (selectedCode != null && candidateCode != null) {
      return selectedCode == candidateCode;
    }

    final selectedName = _normalizeCity(this.countryName);
    final candidateName = _normalizeCity(countryName);
    return selectedName != null &&
        candidateName != null &&
        selectedName == candidateName;
  }

  static AppCountryFilterValue? fromParts({
    String? countryCode,
    String? countryName,
  }) {
    final value = AppCountryFilterValue(
      countryCode: _normalizeCountry(countryCode),
      countryName: _normalize(countryName),
    );
    return value.hasValue ? value : null;
  }

  factory AppCountryFilterValue.fromCountry(ReferenceCountry country) {
    return AppCountryFilterValue(
      countryCode: _normalizeCountry(country.code),
      countryName: _normalize(country.name),
    );
  }
}

class AppCountryFilterSection extends StatefulWidget {
  const AppCountryFilterSection({
    super.key,
    required this.title,
    required this.allCountriesLabel,
    required this.searchHint,
    required this.noResultsText,
    required this.selectedCountry,
    required this.onChanged,
    this.api,
    this.maxResultsHeight = 224,
  });

  final String title;
  final String allCountriesLabel;
  final String searchHint;
  final String noResultsText;
  final AppCountryFilterValue? selectedCountry;
  final ValueChanged<AppCountryFilterValue?> onChanged;
  final ReferenceApi? api;
  final double maxResultsHeight;

  @override
  State<AppCountryFilterSection> createState() =>
      _AppCountryFilterSectionState();
}

class _AppCountryFilterSectionState extends State<AppCountryFilterSection> {
  late final ReferenceApi _api;
  late final AppLocationLabelResolver _labelResolver;
  final TextEditingController _countrySearchController =
      TextEditingController();
  Timer? _searchDebounce;
  List<ReferenceCountry> _visibleCountries = const [];
  String _countrySearchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ReferenceApi();
    _labelResolver = AppLocationLabelResolver(api: _api);
    _countrySearchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _countrySearchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final query = _countrySearchController.text.trim();
    if (query == _countrySearchQuery) return;
    _countrySearchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 260), _runSearch);
  }

  Future<void> _runSearch() async {
    final query = _countrySearchQuery;
    if (query.length < 2) {
      if (!mounted) return;
      setState(() {
        _visibleCountries = const [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final countries = await _api.searchCountries(
        query,
        lang: Localizations.localeOf(context).languageCode,
        limit: 24,
      );
      if (!mounted || _countrySearchQuery != query) return;
      setState(() {
        _visibleCountries = countries;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted || _countrySearchQuery != query) return;
      setState(() {
        _visibleCountries = const [];
        _isSearching = false;
      });
    }
  }

  void _selectCountry(ReferenceCountry country) {
    final value = AppCountryFilterValue.fromCountry(country);
    final current = widget.selectedCountry;
    final next =
        current != null &&
            value.matches(
              countryCode: current.countryCode,
              countryName: current.countryName,
            )
        ? null
        : value;
    _countrySearchController.clear();
    setState(() {
      _countrySearchQuery = '';
      _visibleCountries = const [];
    });
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final selectedCountry = widget.selectedCountry;
    final queryHasEnoughText = _countrySearchQuery.trim().length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: AppBoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: AppBorderRadius.circular(18),
            border: Border.all(color: colors.borderSecondary),
          ),
          child: Padding(
            padding: const AppEdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(Icons.flag_rounded, color: colors.secondary, size: 21),
                const SizedBox(width: 10),
                Expanded(
                  child: selectedCountry == null
                      ? Text(
                          widget.allCountriesLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : AppLocalizedLocationText(
                          countryCode: selectedCountry.countryCode,
                          cityId: null,
                          cityName: null,
                          fallbackText: selectedCountry.fallbackLabel,
                          resolver: _labelResolver,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                if (selectedCountry != null)
                  IconButton(
                    tooltip: widget.allCountriesLabel,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onChanged(null),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _countrySearchController,
          cursorColor: colors.primary,
          textInputAction: TextInputAction.search,
          style: AppTextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: AppInputDecoration(
            hintText: widget.searchHint,
            hintStyle: AppTextStyle(
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
            filled: true,
            fillColor: colors.surfaceHigh,
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
              borderSide: BorderSide(color: colors.borderSoft),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.circular(16),
              borderSide: BorderSide(color: colors.primary, width: 1.2),
            ),
          ),
        ),
        if (_isSearching) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: colors.primary,
              ),
            ),
          ),
        ] else if (queryHasEnoughText) ...[
          const SizedBox(height: 12),
          if (_visibleCountries.isEmpty)
            Row(
              children: [
                Icon(
                  Icons.flag_circle_rounded,
                  color: colors.secondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.noResultsText,
                    style: AppTextStyle(
                      color: colors.secondary,
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
                itemCount: _visibleCountries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final country = _visibleCountries[index];
                  final selected =
                      widget.selectedCountry?.matches(
                        countryCode: country.code,
                        countryName: country.name,
                      ) ??
                      false;
                  return _CountryOptionRow(
                    country: country,
                    selected: selected,
                    onTap: () => _selectCountry(country),
                  );
                },
              ),
            ),
        ],
      ],
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
    this.countryCode,
    this.api,
    this.maxResultsHeight = 224,
  });

  final String title;
  final String allCitiesLabel;
  final String searchHint;
  final String noResultsText;
  final AppCityFilterValue? selectedCity;
  final ValueChanged<AppCityFilterValue?> onChanged;
  final String? countryCode;
  final ReferenceApi? api;
  final double maxResultsHeight;

  @override
  State<AppCityFilterSection> createState() => _AppCityFilterSectionState();
}

class _AppCityFilterSectionState extends State<AppCityFilterSection> {
  late final ReferenceApi _api;
  late final AppLocationLabelResolver _labelResolver;
  final TextEditingController _citySearchController = TextEditingController();
  Timer? _searchDebounce;
  List<ReferenceCity> _visibleCities = const [];
  String _citySearchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ReferenceApi();
    _labelResolver = AppLocationLabelResolver(api: _api);
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
        countryCode: widget.countryCode,
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
    final next =
        current != null &&
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
    final colors = AppDesignSystem.colorsFor(context);
    final selectedCity = widget.selectedCity;
    final queryHasEnoughText = _citySearchQuery.trim().length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: AppBoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: AppBorderRadius.circular(18),
            border: Border.all(color: colors.borderSecondary),
          ),
          child: Padding(
            padding: const AppEdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_city_rounded,
                  color: colors.secondary,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: selectedCity == null
                      ? Text(
                          widget.allCitiesLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : AppLocalizedLocationText(
                          countryCode: selectedCity.countryCode,
                          cityId: selectedCity.cityId,
                          cityName: selectedCity.cityName,
                          fallbackText: selectedCity.fallbackLabel,
                          resolver: _labelResolver,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                if (selectedCity != null)
                  IconButton(
                    tooltip: widget.allCitiesLabel,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onChanged(null),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.primary,
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
          cursorColor: colors.primary,
          textInputAction: TextInputAction.search,
          style: AppTextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: AppInputDecoration(
            hintText: widget.searchHint,
            hintStyle: AppTextStyle(
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
            filled: true,
            fillColor: colors.surfaceHigh,
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
              borderSide: BorderSide(color: colors.borderSoft),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.circular(16),
              borderSide: BorderSide(color: colors.primary, width: 1.2),
            ),
          ),
        ),
        if (_isSearching) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: colors.primary,
              ),
            ),
          ),
        ] else if (queryHasEnoughText) ...[
          const SizedBox(height: 12),
          if (_visibleCities.isEmpty)
            Row(
              children: [
                Icon(
                  Icons.location_off_rounded,
                  color: colors.secondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.noResultsText,
                    style: AppTextStyle(
                      color: colors.secondary,
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
                  final selected =
                      widget.selectedCity?.matches(
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

class _CountryOptionRow extends StatelessWidget {
  const _CountryOptionRow({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final ReferenceCountry country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final code = country.code.trim().toUpperCase();

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(14),
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceRaised,
            borderRadius: AppBorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.primary : colors.borderSoft,
            ),
          ),
          child: Padding(
            padding: const AppEdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    country.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (code.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Text(
                    code,
                    style: AppTextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_rounded,
                    color: colors.primary,
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
    final colors = AppDesignSystem.colorsFor(context);
    final code = city.countryCode.trim().toUpperCase();

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(14),
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceRaised,
            borderRadius: AppBorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.primary : colors.borderSoft,
            ),
          ),
          child: Padding(
            padding: const AppEdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    city.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (code.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Text(
                    code,
                    style: AppTextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_rounded,
                    color: colors.primary,
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
  return _normalize(
    value,
  )?.toLowerCase().replaceAll('ё', 'е').replaceAll(RegExp(r'\s+'), ' ');
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
    final transliterated = _citySlugTransliteration[String.fromCharCode(rune)];
    if (transliterated != null) {
      buffer.write(transliterated);
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

const _citySlugTransliteration = <String, String>{
  'а': 'a',
  'ә': 'a',
  'б': 'b',
  'в': 'v',
  'г': 'g',
  'ғ': 'g',
  'д': 'd',
  'е': 'e',
  'ж': 'zh',
  'з': 'z',
  'и': 'i',
  'і': 'i',
  'й': 'y',
  'к': 'k',
  'қ': 'q',
  'л': 'l',
  'м': 'm',
  'н': 'n',
  'ң': 'n',
  'о': 'o',
  'ө': 'o',
  'п': 'p',
  'р': 'r',
  'с': 's',
  'т': 't',
  'у': 'u',
  'ұ': 'u',
  'ү': 'u',
  'ф': 'f',
  'х': 'kh',
  'һ': 'h',
  'ц': 'ts',
  'ч': 'ch',
  'ш': 'sh',
  'щ': 'shch',
  'ъ': '',
  'ы': 'y',
  'ь': '',
  'э': 'e',
  'ю': 'yu',
  'я': 'ya',
};
