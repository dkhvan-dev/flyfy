import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:provider/provider.dart';

import '../../../core/network/reference_api.dart';
import '../../../core/ui/filter_sheet_chrome.dart';
import '../../../features/profile/models/user_profile_vm.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/home_location_provider.dart';
import '../../../shared/widgets/app_localized_location_text.dart';

class HomeLocationPickerSheet extends StatefulWidget {
  const HomeLocationPickerSheet({super.key, required this.profile});

  final UserProfileVm? profile;

  @override
  State<HomeLocationPickerSheet> createState() =>
      _HomeLocationPickerSheetState();
}

class _HomeLocationPickerSheetState extends State<HomeLocationPickerSheet> {
  static const _initialCountryCityLimit = 8;

  final ReferenceApi _referenceApi = ReferenceApi();
  final TextEditingController _queryController = TextEditingController();
  Timer? _searchDebounce;
  List<ReferenceCity> _initialCountryCities = const [];
  List<ReferenceCity> _results = const [];
  bool _isLoadingInitialCities = false;
  bool _isSearching = false;
  String? _initialCountryRequestKey;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_handleQueryChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInitialCountryCities();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 260), _runSearch);
  }

  Future<void> _runSearch() async {
    final query = _queryController.text.trim();
    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _results = const [];
          _isSearching = false;
          _errorText = null;
        });
      }
      return;
    }

    setState(() {
      _isSearching = true;
      _errorText = null;
    });

    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      final results = await _referenceApi.searchCities(
        query,
        lang: languageCode,
        limit: 20,
      );
      if (!mounted || _queryController.text.trim() != query) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _errorText = AppLocalizations.of(context)!.homeLocationSearchFailed;
      });
    }
  }

  Future<void> _loadInitialCountryCities() async {
    final countryCode = _suggestedCountryCode();
    if (countryCode == null) return;

    final languageCode = Localizations.localeOf(context).languageCode;
    final requestKey = '$countryCode:$languageCode';
    if (_initialCountryRequestKey == requestKey) return;

    _initialCountryRequestKey = requestKey;
    setState(() {
      _initialCountryCities = const [];
      _isLoadingInitialCities = true;
      _errorText = null;
    });

    try {
      final cities = await _referenceApi.citiesByCountry(
        countryCode,
        lang: languageCode,
      );
      if (!mounted || _initialCountryRequestKey != requestKey) return;
      setState(() {
        _initialCountryCities = cities
            .take(_initialCountryCityLimit)
            .toList(growable: false);
        _isLoadingInitialCities = false;
      });
    } catch (_) {
      if (!mounted || _initialCountryRequestKey != requestKey) return;
      setState(() {
        _isLoadingInitialCities = false;
        _errorText = AppLocalizations.of(context)!.homeLocationSearchFailed;
      });
    }
  }

  String? _suggestedCountryCode() {
    final providerCountryCode = context
        .read<HomeLocationProvider>()
        .effectiveLocation
        .countryCode
        ?.trim();
    if (providerCountryCode != null && providerCountryCode.isNotEmpty) {
      return providerCountryCode.toUpperCase();
    }

    return null;
  }

  Future<void> _selectCity(ReferenceCity city) async {
    await context.read<HomeLocationProvider>().selectCity(
      city,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _detectCurrentLocation() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await context.read<HomeLocationProvider>().detectCurrentLocation(
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = l10n.homeLocationDetectionFailed);
    }
  }

  Future<void> _clearSelection() async {
    await context.read<HomeLocationProvider>().clearSelection(
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<HomeLocationProvider>();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final query = _queryController.text.trim();
    final isSearchActive = query.length >= 2;
    final visibleCities = isSearchActive ? _results : _initialCountryCities;
    final colors = AppDesignSystem.colorsFor(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: AppEdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors.screenGradientColors,
            ),
            borderRadius: const AppBorderRadius.vertical(
              top: AppRadiusValue.circular(28),
            ),
            border: Border.all(color: colors.borderSoft),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppFilterSheetHeader(
                  title: l10n.homeLocationSheetTitle,
                  clearLabel: l10n.myActivitiesFilterClear,
                  onClear: _clearSelection,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const AppEdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CurrentLocationPreview(
                          location: provider.effectiveLocation,
                          label: l10n.homeLocationSelected,
                        ),
                        const SizedBox(height: 14),
                        _DetectLocationButton(
                          isLoading: provider.isDetecting,
                          label: provider.isDetecting
                              ? l10n.homeLocationDetecting
                              : l10n.homeLocationUseCurrent,
                          onTap: provider.isDetecting
                              ? null
                              : _detectCurrentLocation,
                        ),
                        const SizedBox(height: 18),
                        _LocationSearchField(
                          controller: _queryController,
                          hintText: l10n.homeLocationSearchHint,
                        ),
                        const SizedBox(height: 14),
                        if (_isSearching ||
                            (!isSearchActive && _isLoadingInitialCities))
                          Padding(
                            padding: const AppEdgeInsets.symmetric(
                              vertical: 18,
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: colors.primary,
                              ),
                            ),
                          )
                        else if (_errorText != null)
                          _LocationMessage(
                            icon: Icons.cloud_off_rounded,
                            message: _errorText!,
                          )
                        else if (isSearchActive && _results.isEmpty)
                          _LocationMessage(
                            icon: Icons.location_off_rounded,
                            message: l10n.homeLocationNoResults,
                            color: colors.primary,
                          )
                        else
                          for (final city in visibleCities)
                            _CityResultTile(
                              city: city,
                              onTap: () => _selectCity(city),
                            ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: AppEdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
                  child: AppFilterApplyButton(
                    label: l10n.homeLocationApply,
                    icon: Icons.check_rounded,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentLocationPreview extends StatelessWidget {
  const _CurrentLocationPreview({required this.location, required this.label});

  final HomeLocationPreference location;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Container(
      width: double.infinity,
      padding: const AppEdgeInsets.all(16),
      decoration: AppBoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppBorderRadius.circular(18),
        border: Border.all(color: colors.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: AppBoxDecoration(
              shape: BoxShape.circle,
              color: colors.primaryContainer,
            ),
            child: Icon(Icons.location_on_rounded, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                AppLocalizedLocationText(
                  countryCode: location.countryCode,
                  cityId: location.cityId,
                  cityName: location.cityName,
                  fallbackText: location.fallbackLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectLocationButton extends StatelessWidget {
  const _DetectLocationButton({
    required this.label,
    required this.onTap,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              )
            : const Icon(Icons.my_location_rounded),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.borderPrimary),
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _LocationSearchField extends StatelessWidget {
  const _LocationSearchField({
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      style: AppTextStyle(
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: AppInputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyle(color: colors.textMuted),
        prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
        filled: true,
        fillColor: colors.surfaceRaised,
        contentPadding: const AppEdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.circular(16),
          borderSide: BorderSide(color: colors.borderPrimary),
        ),
      ),
    );
  }
}

class _CityResultTile extends StatelessWidget {
  const _CityResultTile({required this.city, required this.onTap});

  final ReferenceCity city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Padding(
      padding: const AppEdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.circular(16),
          child: Ink(
            padding: const AppEdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            decoration: AppBoxDecoration(
              color: colors.surface,
              borderRadius: AppBorderRadius.circular(16),
              border: Border.all(color: colors.borderSoft),
            ),
            child: Row(
              children: [
                Icon(Icons.location_city_rounded, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AppLocalizedLocationText(
                        countryCode: city.countryCode,
                        cityId: null,
                        cityName: null,
                        fallbackText: city.countryCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: colors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationMessage extends StatelessWidget {
  const _LocationMessage({
    required this.icon,
    required this.message,
    this.color,
  });

  final IconData icon;
  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final effectiveColor = color ?? colors.textSecondary;

    return Padding(
      padding: const AppEdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Icon(icon, color: effectiveColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyle(
                color: effectiveColor,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
