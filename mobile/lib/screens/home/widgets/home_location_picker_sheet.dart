import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/reference_api.dart';
import '../../../core/ui/app_colors.dart';
import '../../../core/ui/filter_sheet_chrome.dart';
import '../../../features/profile/models/user_profile_vm.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/home_location_provider.dart';
import '../../../shared/widgets/app_localized_location_text.dart';

class HomeLocationPickerSheet extends StatefulWidget {
  const HomeLocationPickerSheet({
    super.key,
    required this.profile,
  });

  final UserProfileVm? profile;

  @override
  State<HomeLocationPickerSheet> createState() =>
      _HomeLocationPickerSheetState();
}

class _HomeLocationPickerSheetState extends State<HomeLocationPickerSheet> {
  final ReferenceApi _referenceApi = ReferenceApi();
  final TextEditingController _queryController = TextEditingController();
  Timer? _searchDebounce;
  List<ReferenceCity> _results = const [];
  bool _isSearching = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_handleQueryChanged);
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

  Future<void> _selectCity(ReferenceCity city) async {
    await context.read<HomeLocationProvider>().selectCity(city);
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
          profile: widget.profile,
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<HomeLocationProvider>();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2B1808), Color(0xFF201208)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
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
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                              ),
                            ),
                          )
                        else if (_errorText != null)
                          _LocationMessage(
                            icon: Icons.cloud_off_rounded,
                            message: _errorText!,
                          )
                        else if (_queryController.text.trim().length >= 2 &&
                            _results.isEmpty)
                          _LocationMessage(
                            icon: Icons.location_off_rounded,
                            message: l10n.homeLocationNoResults,
                            color: AppColors.accent,
                          )
                        else
                          for (final city in _results)
                            _CityResultTile(
                              city: city,
                              onTap: () => _selectCity(city),
                            ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
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
  const _CurrentLocationPreview({
    required this.location,
    required this.label,
  });

  final HomeLocationPreference location;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.accent,
            ),
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
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.86),
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
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            : const Icon(Icons.my_location_rounded),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.28)),
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
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
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textCaption),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accent),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _CityResultTile extends StatelessWidget {
  const _CityResultTile({
    required this.city,
    required this.onTap,
  });

  final ReferenceCity city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_city_rounded,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        city.countryCode.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textCaption,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textCaption,
                ),
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
    final effectiveColor = color ?? AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Icon(icon, color: effectiveColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
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
