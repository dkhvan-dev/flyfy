import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/device/device_context_service.dart';
import '../../core/network/file_api.dart';
import '../../core/network/reference_api.dart';
import '../../core/reference/country_filter_utils.dart';
import '../../core/reference/currency_filter_utils.dart';
import '../../core/reference/timezone_filter_utils.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/update_profile_request.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/session_provider.dart';
import 'profile_style.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameFieldKey = GlobalKey();
  final _lastNameFieldKey = GlobalKey();
  final _countryFieldKey = GlobalKey();
  final _profileApi = ProfileApi();
  final _fileApi = FileApi();
  final _referenceApi = ReferenceApi();
  final _deviceContextService = const DeviceContextService();
  final _imagePicker = ImagePicker();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _countryCodeController;
  late final TextEditingController _countrySearchController;
  late final TextEditingController _timezoneController;
  late final TextEditingController _timezoneSearchController;
  late final TextEditingController _currencyController;
  late final TextEditingController _currencySearchController;

  late String _localeCode;
  List<ReferenceCountry> _countries = const [];
  Map<String, Set<String>> _countrySearchAliases = const {};
  List<ReferenceTimezone> _timezones = const [];
  Map<String, Set<String>> _timezoneSearchAliases = const {};
  List<ReferenceCurrency> _currencies = const [];
  Map<String, Set<String>> _currencySearchAliases = const {};
  Future<void>? _countriesLoadFuture;
  Future<void>? _timezonesLoadFuture;
  Future<void>? _currenciesLoadFuture;
  String _countrySearchQuery = '';
  String _timezoneSearchQuery = '';
  String _currencySearchQuery = '';
  String? _avatarFileId;

  Future<String?>? _avatarFuture;
  Uint8List? _avatarPreviewBytes;
  bool _isCountriesLoading = false;
  bool _isTimezonesLoading = false;
  bool _isCurrenciesLoading = false;
  bool _isSaving = false;
  bool _isResolvingLocation = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();

    final profile = context.read<SessionProvider>().profile;
    final appLocaleCode = context.read<LocaleProvider>().locale.languageCode;

    _firstNameController = TextEditingController(text: profile?.firstName ?? '')
      ..addListener(_handlePreviewChanged);
    _lastNameController = TextEditingController(text: profile?.lastName ?? '')
      ..addListener(_handlePreviewChanged);
    _displayNameController = TextEditingController(
      text: profile?.displayName ?? '',
    )..addListener(_handlePreviewChanged);
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _countryCodeController = TextEditingController(
      text: profile?.countryCode ?? '',
    );
    _countrySearchController = TextEditingController()
      ..addListener(_handleCountrySearchChanged);
    _timezoneController = TextEditingController(
      text: profile?.timezone ?? 'Asia/Almaty',
    );
    _timezoneSearchController = TextEditingController()
      ..addListener(_handleTimezoneSearchChanged);
    _currencyController = TextEditingController(
      text: profile?.currency ?? 'KZT',
    );
    _currencySearchController = TextEditingController()
      ..addListener(_handleCurrencySearchChanged);

    _localeCode = _normalizeLocaleCode(
      profile?.locale,
      fallback: appLocaleCode,
    );
    _avatarFileId = (profile?.avatarFileId ?? '').trim().isEmpty
        ? null
        : profile!.avatarFileId!.trim();
    _avatarFuture = _loadAvatarUrl(profile?.avatarFileId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_prefillTimezoneFromDevice());
      unawaited(_loadCountries());
      unawaited(_loadTimezones());
      unawaited(_loadCurrencies());
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _countryCodeController.dispose();
    _countrySearchController
      ..removeListener(_handleCountrySearchChanged)
      ..dispose();
    _timezoneController.dispose();
    _timezoneSearchController
      ..removeListener(_handleTimezoneSearchChanged)
      ..dispose();
    _currencyController.dispose();
    _currencySearchController
      ..removeListener(_handleCurrencySearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handlePreviewChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleCountrySearchChanged() {
    final nextQuery = _countrySearchController.text.trim();
    if (nextQuery == _countrySearchQuery) return;

    setState(() => _countrySearchQuery = nextQuery);
  }

  void _handleTimezoneSearchChanged() {
    final nextQuery = _timezoneSearchController.text.trim();
    if (nextQuery == _timezoneSearchQuery) return;

    setState(() => _timezoneSearchQuery = nextQuery);
  }

  void _handleCurrencySearchChanged() {
    final nextQuery = _currencySearchController.text.trim();
    if (nextQuery == _currencySearchQuery) return;

    setState(() => _currencySearchQuery = nextQuery);
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
    final selectedCountryCode = normalizeReferenceCountryCode(
      _countryCodeController.text,
    );

    try {
      final countries = withDefaultReferenceCountry(
        await _referenceApi.listCountries(lang: lang),
        selectedCountryCode,
      );
      final aliases = await _loadCountrySearchAliases(countries, lang);
      if (!mounted) return;

      setState(() {
        _countries = countries;
        _countrySearchAliases = aliases;
        _isCountriesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final countries = withDefaultReferenceCountry(
        const [],
        selectedCountryCode,
      );

      setState(() {
        _countries = countries;
        _countrySearchAliases = countrySearchAliasMap(countries);
        _isCountriesLoading = false;
      });
    }
  }

  Future<void> _loadTimezones() {
    if (_timezones.isNotEmpty) return Future.value();
    final inFlight = _timezonesLoadFuture;
    if (inFlight != null) return inFlight;

    final future = _loadTimezonesInner();
    _timezonesLoadFuture = future;
    return future.whenComplete(() => _timezonesLoadFuture = null);
  }

  Future<void> _loadTimezonesInner() async {
    if (!mounted) return;

    setState(() => _isTimezonesLoading = true);
    final lang = Localizations.localeOf(context).languageCode;
    final selectedTimezoneId = normalizeReferenceTimezoneId(
      _timezoneController.text,
    );

    try {
      final timezones = withDefaultReferenceTimezone(
        await _referenceApi.listTimezones(lang: lang),
        selectedTimezoneId,
        lang: lang,
      );
      final aliases = await _loadTimezoneSearchAliases(timezones, lang);
      if (!mounted) return;

      setState(() {
        _timezones = timezones;
        _timezoneSearchAliases = aliases;
        _isTimezonesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final timezones = withDefaultReferenceTimezone(
        const [],
        selectedTimezoneId,
        lang: lang,
      );

      setState(() {
        _timezones = timezones;
        _timezoneSearchAliases = timezoneSearchAliasMap(timezones);
        _isTimezonesLoading = false;
      });
    }
  }

  Future<void> _loadCurrencies() {
    if (_currencies.isNotEmpty) return Future.value();
    final inFlight = _currenciesLoadFuture;
    if (inFlight != null) return inFlight;

    final future = _loadCurrenciesInner();
    _currenciesLoadFuture = future;
    return future.whenComplete(() => _currenciesLoadFuture = null);
  }

  Future<void> _loadCurrenciesInner() async {
    if (!mounted) return;

    setState(() => _isCurrenciesLoading = true);
    final lang = Localizations.localeOf(context).languageCode;
    final selectedCurrencyCode = normalizeReferenceCurrencyCode(
      _currencyController.text,
    );

    try {
      final currencies = withDefaultReferenceCurrency(
        await _referenceApi.listCurrencies(lang: lang),
        selectedCurrencyCode,
      );
      final aliases = await _loadCurrencySearchAliases(currencies, lang);
      if (!mounted) return;

      setState(() {
        _currencies = currencies;
        _currencySearchAliases = aliases;
        _isCurrenciesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final currencies = withDefaultReferenceCurrency(
        const [],
        selectedCurrencyCode,
      );

      setState(() {
        _currencies = currencies;
        _currencySearchAliases = currencySearchAliasMap(currencies);
        _isCurrenciesLoading = false;
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

  Future<Map<String, Set<String>>> _loadTimezoneSearchAliases(
    List<ReferenceTimezone> timezones,
    String currentLang,
  ) async {
    final languages = {'en', 'ru', 'kk'}..remove(currentLang);
    final localizedLists = await Future.wait(
      languages.map((lang) async {
        try {
          return await _referenceApi.listTimezones(lang: lang);
        } catch (_) {
          return const <ReferenceTimezone>[];
        }
      }),
    );

    return timezoneSearchAliasMap([
      ...timezones,
      for (final localizedTimezones in localizedLists) ...localizedTimezones,
    ]);
  }

  Future<Map<String, Set<String>>> _loadCurrencySearchAliases(
    List<ReferenceCurrency> currencies,
    String currentLang,
  ) async {
    final languages = {'en', 'ru', 'kk'}..remove(currentLang);
    final localizedLists = await Future.wait(
      languages.map((lang) async {
        try {
          return await _referenceApi.listCurrencies(lang: lang);
        } catch (_) {
          return const <ReferenceCurrency>[];
        }
      }),
    );

    return currencySearchAliasMap([
      ...currencies,
      for (final localizedCurrencies in localizedLists) ...localizedCurrencies,
    ]);
  }

  ReferenceCountry? _selectedCountry() {
    final countryCode = normalizeReferenceCountryCode(
      _countryCodeController.text,
    );
    if (countryCode == null) return null;

    for (final country in _countries) {
      if (normalizeReferenceCountryCode(country.code) == countryCode) {
        return country;
      }
    }
    return null;
  }

  List<ReferenceCountry> _visibleCountries() {
    final query = normalizeCountrySearchText(_countrySearchQuery);
    if (query.isEmpty) return const [];

    return _countries
        .where(
          (country) => countryFilterSearchHaystack(
            country,
            _countrySearchAliases,
          ).contains(query),
        )
        .take(24)
        .toList(growable: false);
  }

  ReferenceTimezone? _selectedTimezone() {
    final timezoneId = normalizeReferenceTimezoneId(_timezoneController.text);
    if (timezoneId == null) return null;

    for (final timezone in _timezones) {
      if (normalizeReferenceTimezoneId(timezone.id) == timezoneId) {
        return timezone;
      }
    }
    return null;
  }

  List<ReferenceTimezone> _visibleTimezones() {
    final query = normalizeCountrySearchText(_timezoneSearchQuery);
    if (query.isEmpty) return const [];

    return _timezones
        .where(
          (timezone) => timezoneFilterSearchHaystack(
            timezone,
            _timezoneSearchAliases,
          ).contains(query),
        )
        .take(24)
        .toList(growable: false);
  }

  ReferenceCurrency? _selectedCurrency() {
    final currencyCode = normalizeReferenceCurrencyCode(
      _currencyController.text,
    );
    if (currencyCode == null) return null;

    for (final currency in _currencies) {
      if (normalizeReferenceCurrencyCode(currency.code) == currencyCode) {
        return currency;
      }
    }
    return null;
  }

  List<ReferenceCurrency> _visibleCurrencies() {
    final query = normalizeCurrencySearchText(_currencySearchQuery);
    if (query.isEmpty) return const [];

    return _currencies
        .where(
          (currency) => currencyFilterSearchHaystack(
            currency,
            _currencySearchAliases,
          ).contains(query),
        )
        .take(24)
        .toList(growable: false);
  }

  void _selectCountry(ReferenceCountry country) {
    final normalized = normalizeReferenceCountryCode(country.code);
    if (normalized == null) return;

    setState(() {
      _countryCodeController.text = normalized;
      _countrySearchController.clear();
      _countrySearchQuery = '';
    });
  }

  void _clearCountry() {
    setState(() {
      _countryCodeController.clear();
      _countrySearchController.clear();
      _countrySearchQuery = '';
    });
  }

  void _selectTimezone(ReferenceTimezone timezone) {
    final normalized = normalizeReferenceTimezoneId(timezone.id);
    if (normalized == null) return;

    setState(() {
      _timezoneController.text = normalized;
      _timezoneSearchController.clear();
      _timezoneSearchQuery = '';
    });
  }

  void _selectCurrency(ReferenceCurrency currency) {
    final normalized = normalizeReferenceCurrencyCode(currency.code);
    if (normalized == null) return;

    setState(() {
      _currencyController.text = normalized;
      _currencySearchController.clear();
      _currencySearchQuery = '';
    });
  }

  Future<String?> _loadAvatarUrl(String? avatarFileId) async {
    final trimmed = (avatarFileId ?? '').trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return _fileApi.publicContentUrl(trimmed);
  }

  Future<void> _prefillTimezoneFromDevice() async {
    final currentValue = _timezoneController.text.trim();
    final shouldReplace = currentValue.isEmpty || currentValue == 'Asia/Almaty';

    if (!shouldReplace) return;

    final timezone = await _deviceContextService.getLocalTimezone();
    if (!mounted || timezone == null || timezone.trim().isEmpty) return;

    setState(() {
      _timezoneController.text = timezone;
    });
  }

  Future<void> _resolveLocationFromDevice() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isResolvingLocation = true;
    });

    try {
      final suggestion = await _deviceContextService.detectLocationSuggestion();
      if (!mounted || suggestion == null) return;

      final confirmed = await _showLocationConfirmDialog(suggestion);
      if (!mounted || confirmed != true) return;

      await _loadTimezones();
      if (!mounted) return;

      final detectedTimezone = await _deviceContextService.getLocalTimezone();
      if (!mounted) return;

      final resolvedTimezone = resolveReferenceTimezoneForLocation(
        timezones: _timezones,
        aliases: _timezoneSearchAliases,
        cityName: suggestion.cityName,
        countryCode: suggestion.countryCode,
        deviceTimezoneId: detectedTimezone,
      );
      final resolvedTimezoneId =
          normalizeReferenceTimezoneId(resolvedTimezone?.id) ??
              normalizeReferenceTimezoneId(detectedTimezone);

      setState(() {
        if ((suggestion.countryCode ?? '').isNotEmpty) {
          _countryCodeController.text =
              normalizeReferenceCountryCode(suggestion.countryCode) ??
                  suggestion.countryCode!;
        }
        if (resolvedTimezoneId != null) {
          final lang = Localizations.localeOf(context).languageCode;
          _timezones = withDefaultReferenceTimezone(
            _timezones,
            resolvedTimezoneId,
            lang: lang,
          );
          _timezoneSearchAliases = timezoneSearchAliasMap(_timezones);
          _timezoneController.text = resolvedTimezoneId;
          _timezoneSearchController.clear();
          _timezoneSearchQuery = '';
        }
      });
    } catch (e) {
      if (!mounted) return;

      final code = e.toString();
      String message = l10n.locationDetectFailed;

      if (code.contains('location_services_disabled')) {
        message = l10n.locationServicesDisabled;
      } else if (code.contains('location_permission_denied_forever')) {
        message = l10n.locationPermissionDeniedForever;
      } else if (code.contains('location_permission_denied')) {
        message = l10n.locationPermissionDenied;
      }

      await showErrorDialog(context, title: l10n.error, message: message);
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
        });
      }
    }
  }

  Future<bool?> _showLocationConfirmDialog(
    DeviceLocationSuggestion suggestion,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final locationText = [
      if ((suggestion.cityName ?? '').isNotEmpty) suggestion.cityName,
      if ((suggestion.countryName ?? '').isNotEmpty) suggestion.countryName,
      if ((suggestion.countryCode ?? '').isNotEmpty) suggestion.countryCode,
    ].whereType<String>().join(', ');

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.useDetectedLocationTitle),
          content: Text(
            locationText.isEmpty
                ? l10n.locationDetectFailed
                : l10n.useDetectedLocationDescription(locationText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.useButton),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();
    final navigator = Navigator.of(context);

    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      await _scrollToFirstInvalidRequiredField();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await _profileApi.updateMeProfile(
        UpdateProfileRequest(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          displayName: _displayNameController.text,
          bio: _bioController.text,
          avatarFileId: _avatarFileId,
          countryCode: _countryCodeController.text,
          locale: _localeCode,
          timezone: _timezoneController.text,
          currency: _currencyController.text,
        ),
      );

      if (!mounted) return;

      await localeProvider.setLocale(updated.locale);
      navigator.pop(true);
    } on DioException catch (e) {
      if (!mounted) return;

      String message = l10n.profileSaveFailed;
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final backendError = data['error']?.toString();
        if (backendError != null && backendError.trim().isNotEmpty) {
          if (backendError.trim() == 'display name is already taken') {
            message = l10n.profileDisplayNameTaken;
          } else {
            message = backendError;
          }
        }
      }

      await showErrorDialog(context, title: l10n.error, message: message);
    } catch (_) {
      if (!mounted) return;

      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.profileSaveFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _scrollToFirstInvalidRequiredField() async {
    if (_firstNameController.text.trim().isEmpty) {
      await _scrollToField(_firstNameFieldKey);
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      await _scrollToField(_lastNameFieldKey);
      return;
    }

    if (normalizeReferenceCountryCode(_countryCodeController.text) == null) {
      await _scrollToField(_countryFieldKey);
    }
  }

  Future<void> _scrollToField(GlobalKey key) async {
    final fieldContext = key.currentContext;
    if (fieldContext == null) return;

    const invalidFieldScrollAlignment = 0.42;

    await Scrollable.ensureVisible(
      fieldContext,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: invalidFieldScrollAlignment,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  Future<void> _pickAvatar() async {
    if (_isUploadingAvatar || _isSaving) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 1800,
    );

    if (picked == null || !mounted) {
      return;
    }

    final contentType = _resolveAvatarContentType(picked.name);
    if (contentType == null) {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.profileSettingsAvatarUnsupportedFormat,
      );
      return;
    }

    final bytes = await picked.readAsBytes();
    if (!mounted) {
      return;
    }

    final previousFuture = _avatarFuture;
    final previousAvatarFileId = _avatarFileId;

    setState(() {
      _isUploadingAvatar = true;
      _avatarPreviewBytes = bytes;
    });

    try {
      final upload = await _fileApi.createAvatarUpload(
        originalName: picked.name,
        contentType: contentType,
        sizeBytes: bytes.length,
      );
      await _fileApi.uploadBinary(
        upload: upload,
        bytes: bytes,
        contentType: contentType,
      );
      await _fileApi.completeUpload(upload.fileId);

      if (!mounted) {
        return;
      }

      setState(() {
        _avatarFileId = upload.fileId;
        _avatarPreviewBytes = bytes;
        _avatarFuture = Future<String?>.value(
          _fileApi.publicContentUrl(upload.fileId),
        );
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _avatarPreviewBytes = null;
        _avatarFileId = previousAvatarFileId;
        _avatarFuture = previousFuture;
      });

      var message = l10n.profileSettingsAvatarUploadFailed;
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final backendError = data['error']?.toString().trim() ?? '';
        if (backendError.isNotEmpty) {
          message = backendError;
        }
      }

      await showErrorDialog(context, title: l10n.error, message: message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _avatarPreviewBytes = null;
        _avatarFileId = previousAvatarFileId;
        _avatarFuture = previousFuture;
      });

      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.profileSettingsAvatarUploadFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  String? _resolveAvatarContentType(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    return null;
  }

  String _normalizeLocaleCode(String? raw, {String fallback = 'ru'}) {
    const allowed = {'ru', 'en', 'kk'};

    final normalized = (raw ?? '').trim().toLowerCase();
    if (allowed.contains(normalized)) {
      return normalized;
    }

    final fallbackNormalized = fallback.trim().toLowerCase();
    if (allowed.contains(fallbackNormalized)) {
      return fallbackNormalized;
    }

    return 'ru';
  }

  String _previewName(UserProfileVm? profile) {
    final display = _displayNameController.text.trim();
    if (display.isNotEmpty) {
      return display;
    }

    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final fullName = [first, last].where((part) => part.isNotEmpty).join(' ');
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return profile?.preferredName ?? 'FlyFy';
  }

  String _previewInitials(UserProfileVm? profile) {
    final source = _previewName(profile).trim();
    if (source.isEmpty) {
      return profile?.initials ?? 'F';
    }

    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.length >= 2) {
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }

    return parts.first.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = context.watch<SessionProvider>().profile;
    final padding = profileScaled(context, 20, min: 14, max: 20);
    final previewName = _previewName(profile);
    final previewInitials = _previewInitials(profile);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ProfileResponsiveScope(
        child: ProfileGlassBackground(
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  padding,
                  profileScaled(context, 14, min: 10, max: 18),
                  padding,
                  profileScaled(context, 28, min: 20, max: 34),
                ),
                children: [
                  _EditProfileTopBar(title: l10n.editProfileButton),
                  SizedBox(
                    height: profileScaled(context, 26, min: 18, max: 30),
                  ),
                  FutureBuilder<String?>(
                    future: _avatarFuture,
                    builder: (context, snapshot) {
                      return _EditProfileHero(
                        avatarUrl: snapshot.data,
                        avatarBytes: _avatarPreviewBytes,
                        initials: previewInitials,
                        name: previewName,
                        phone: profile?.primaryPhone,
                        email: profile?.primaryEmail,
                        avatarHint: _isUploadingAvatar
                            ? l10n.profileSettingsAvatarUploading
                            : l10n.profileSettingsAvatarUploadHint,
                        onAvatarTap: _pickAvatar,
                        isUploadingAvatar: _isUploadingAvatar,
                      );
                    },
                  ),
                  SizedBox(
                    height: profileScaled(context, 32, min: 24, max: 34),
                  ),
                  ProfileSectionHeading(
                    title: l10n.profileSettingsDescriptionSection,
                  ),
                  SizedBox(
                    height: profileScaled(context, 14, min: 12, max: 16),
                  ),
                  _ProfileSectionCard(
                    child: _StyledTextField(
                      controller: _bioController,
                      hintText: l10n.bioLabel,
                      minLines: 4,
                      maxLines: 7,
                    ),
                  ),
                  SizedBox(
                    height: profileScaled(context, 28, min: 24, max: 32),
                  ),
                  ProfileSectionHeading(
                    title: l10n.profileSettingsDetailsSection,
                  ),
                  SizedBox(
                    height: profileScaled(context, 14, min: 12, max: 16),
                  ),
                  _ProfileSectionCard(
                    child: Column(
                      children: [
                        _LabeledInput(
                          key: _firstNameFieldKey,
                          label: l10n.firstNameLabel,
                          child: _StyledTextField(
                            controller: _firstNameController,
                            hintText: l10n.firstNameLabel,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return l10n.firstNameRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 16, min: 14, max: 18),
                        ),
                        _LabeledInput(
                          key: _lastNameFieldKey,
                          label: l10n.lastNameLabel,
                          child: _StyledTextField(
                            controller: _lastNameController,
                            hintText: l10n.lastNameLabel,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return l10n.lastNameRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 16, min: 14, max: 18),
                        ),
                        _LabeledInput(
                          label: l10n.displayNameLabel,
                          child: _StyledTextField(
                            controller: _displayNameController,
                            hintText: l10n.displayNameLabel,
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 16, min: 14, max: 18),
                        ),
                        _LabeledInput(
                          key: _countryFieldKey,
                          label: l10n.profileCountry,
                          child: _ProfileCountrySearchField(
                            value: _countryCodeController.text,
                            selectedCountry: _selectedCountry(),
                            selectedCountryCode: normalizeReferenceCountryCode(
                              _countryCodeController.text,
                            ),
                            validator: (value) {
                              if (normalizeReferenceCountryCode(value) ==
                                  null) {
                                return l10n.profileCountryRequired;
                              }
                              return null;
                            },
                            searchController: _countrySearchController,
                            visibleCountries: _visibleCountries(),
                            isLoading: _isCountriesLoading,
                            searchQuery: _countrySearchQuery,
                            searchHint: l10n.excursionsFilterCountrySearchHint,
                            emptyLabel: l10n.excursionsFilterCountryNoResults,
                            onCountrySelected: _selectCountry,
                            onClearCountry: _clearCountry,
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 16, min: 14, max: 18),
                        ),
                        _LabeledInput(
                          label: l10n.profileTimezone,
                          child: _ProfileTimezoneSearchField(
                            selectedTimezone: _selectedTimezone(),
                            selectedTimezoneId: normalizeReferenceTimezoneId(
                              _timezoneController.text,
                            ),
                            searchController: _timezoneSearchController,
                            visibleTimezones: _visibleTimezones(),
                            isLoading: _isTimezonesLoading,
                            searchQuery: _timezoneSearchQuery,
                            searchHint: l10n.profileTimezoneSearchHint,
                            emptyLabel: l10n.profileTimezoneNoResults,
                            onTimezoneSelected: _selectTimezone,
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 16, min: 14, max: 18),
                        ),
                        _LabeledInput(
                          label: l10n.profileCurrency,
                          child: _ProfileCurrencySearchField(
                            selectedCurrency: _selectedCurrency(),
                            selectedCurrencyCode:
                                normalizeReferenceCurrencyCode(
                              _currencyController.text,
                            ),
                            searchController: _currencySearchController,
                            visibleCurrencies: _visibleCurrencies(),
                            isLoading: _isCurrenciesLoading,
                            searchQuery: _currencySearchQuery,
                            searchHint: l10n.profileCurrencySearchHint,
                            emptyLabel: l10n.profileCurrencyNoResults,
                            onCurrencySelected: _selectCurrency,
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 18, min: 16, max: 20),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _isResolvingLocation
                                ? null
                                : _resolveLocationFromDevice,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: BorderSide(
                                color: AppColors.accent.withValues(alpha: 0.2),
                              ),
                              backgroundColor: AppColors.accent.withValues(
                                alpha: 0.05,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: profileScaled(
                                  context,
                                  16,
                                  min: 14,
                                  max: 18,
                                ),
                                vertical: profileScaled(
                                  context,
                                  12,
                                  min: 10,
                                  max: 12,
                                ),
                              ),
                            ),
                            icon: _isResolvingLocation
                                ? SizedBox(
                                    width: profileScaled(
                                      context,
                                      18,
                                      min: 16,
                                      max: 18,
                                    ),
                                    height: profileScaled(
                                      context,
                                      18,
                                      min: 16,
                                      max: 18,
                                    ),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.my_location_outlined),
                            label: Text(l10n.detectLocationButton),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: profileScaled(context, 28, min: 24, max: 32),
                  ),
                  FilledButton(
                    onPressed: (_isSaving || _isUploadingAvatar) ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      minimumSize: Size(
                        double.infinity,
                        profileScaled(context, 56, min: 50, max: 58),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          profileScaled(context, 18, min: 16, max: 20),
                        ),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: profileScaled(context, 18, min: 16, max: 18),
                            height: profileScaled(
                              context,
                              18,
                              min: 16,
                              max: 18,
                            ),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.profileSaveChangesButton,
                            style: TextStyle(
                              fontSize: profileScaled(
                                context,
                                15,
                                min: 14,
                                max: 16,
                              ),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                  ),
                  SizedBox(
                    height: profileScaled(context, 18, min: 14, max: 20),
                  ),
                  Center(
                    child: Text(
                      l10n.profileDeactivateAccountLabel,
                      style: TextStyle(
                        color: Color.fromARGB(255, 143, 34, 15),
                        fontSize: profileScaled(context, 12, min: 11, max: 12),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
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
}

class _EditProfileTopBar extends StatelessWidget {
  const _EditProfileTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileTopIconButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: profileScaled(context, 12, min: 8, max: 12),
            ),
            child: Text(
              title,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: profileScaled(context, 18, min: 16, max: 20),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditProfileHero extends StatelessWidget {
  const _EditProfileHero({
    required this.avatarUrl,
    required this.avatarBytes,
    required this.initials,
    required this.name,
    required this.phone,
    required this.email,
    required this.avatarHint,
    required this.onAvatarTap,
    required this.isUploadingAvatar,
  });

  final String? avatarUrl;
  final Uint8List? avatarBytes;
  final String initials;
  final String name;
  final String? phone;
  final String? email;
  final String avatarHint;
  final VoidCallback onAvatarTap;
  final bool isUploadingAvatar;

  @override
  Widget build(BuildContext context) {
    final size = profileScaled(context, 118, min: 100, max: 126);

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: size,
                  height: size,
                  padding: EdgeInsets.all(
                    profileScaled(context, 4, min: 3, max: 5),
                  ),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFE5C48D), Color(0xFF8B5506)],
                    ),
                  ),
                  child: ClipOval(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFEEF3F6), Color(0xFFB9CAD5)],
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (avatarBytes != null)
                            Image.memory(avatarBytes!, fit: BoxFit.cover)
                          else if (avatarUrl != null)
                            Image.network(
                              avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: const Color(0xFF516572),
                                    fontSize: profileScaled(
                                      context,
                                      34,
                                      min: 28,
                                      max: 36,
                                    ),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                          else
                            Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  color: const Color(0xFF516572),
                                  fontSize: profileScaled(
                                    context,
                                    34,
                                    min: 28,
                                    max: 36,
                                  ),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          if (isUploadingAvatar)
                            Container(
                              color: Colors.black.withValues(alpha: 0.28),
                              child: Center(
                                child: SizedBox(
                                  width: profileScaled(
                                    context,
                                    24,
                                    min: 22,
                                    max: 24,
                                  ),
                                  height: profileScaled(
                                    context,
                                    24,
                                    min: 22,
                                    max: 24,
                                  ),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: profileScaled(context, -2, min: -2, max: 0),
                bottom: profileScaled(context, 10, min: 8, max: 12),
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: profileScaled(context, 34, min: 30, max: 36),
                    height: profileScaled(context, 34, min: 30, max: 36),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent,
                      border: Border.all(color: profileBgTop, width: 2),
                    ),
                    child: Icon(
                      isUploadingAvatar
                          ? Icons.hourglass_top_rounded
                          : Icons.edit_rounded,
                      color: Colors.white,
                      size: profileScaled(context, 16, min: 14, max: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: profileScaled(context, 18, min: 14, max: 20)),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: profileScaled(context, 28, min: 24, max: 30),
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        if ((phone ?? '').trim().isNotEmpty ||
            (email ?? '').trim().isNotEmpty) ...[
          SizedBox(height: profileScaled(context, 12, min: 10, max: 14)),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: profileScaled(context, 10, min: 8, max: 10),
            runSpacing: profileScaled(context, 10, min: 8, max: 10),
            children: [
              if ((phone ?? '').trim().isNotEmpty) _ContactPill(text: phone!),
              if ((email ?? '').trim().isNotEmpty) _ContactPill(text: email!),
            ],
          ),
        ],
        SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
        Text(
          avatarHint,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: profileDisabled,
            fontSize: profileScaled(context, 12, min: 11, max: 12),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ContactPill extends StatelessWidget {
  const _ContactPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: profileScaled(context, 12, min: 10, max: 14),
        vertical: profileScaled(context, 7, min: 6, max: 8),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: profileTextSoft,
          fontSize: profileScaled(context, 12, min: 11, max: 12),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileCountrySearchField extends StatelessWidget {
  const _ProfileCountrySearchField({
    required this.value,
    required this.selectedCountry,
    required this.selectedCountryCode,
    required this.validator,
    required this.searchController,
    required this.visibleCountries,
    required this.isLoading,
    required this.searchQuery,
    required this.searchHint,
    required this.emptyLabel,
    required this.onCountrySelected,
    required this.onClearCountry,
  });

  final String value;
  final ReferenceCountry? selectedCountry;
  final String? selectedCountryCode;
  final String? Function(String?) validator;
  final TextEditingController searchController;
  final List<ReferenceCountry> visibleCountries;
  final bool isLoading;
  final String searchQuery;
  final String searchHint;
  final String emptyLabel;
  final ValueChanged<ReferenceCountry> onCountrySelected;
  final VoidCallback onClearCountry;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: ValueKey(normalizeReferenceCountryCode(value) ?? ''),
      initialValue: normalizeReferenceCountryCode(value),
      validator: validator,
      builder: (field) {
        final hasSelection = selectedCountryCode != null;
        final selectedLabel = selectedCountry == null
            ? selectedCountryCode
            : _countryLabel(selectedCountry!);
        final errorText = field.errorText;
        final hasError = errorText != null;
        const errorColor = Color(0xFFE47F78);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasSelection) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(
                    profileScaled(context, 18, min: 16, max: 20),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: profileScaled(context, 14, min: 12, max: 16),
                    vertical: profileScaled(context, 11, min: 10, max: 12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.public_rounded,
                        color: AppColors.accent,
                        size: profileScaled(context, 20, min: 18, max: 21),
                      ),
                      SizedBox(
                        width: profileScaled(context, 10, min: 8, max: 10),
                      ),
                      Expanded(
                        child: Text(
                          selectedLabel ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: profileScaled(
                              context,
                              15,
                              min: 14,
                              max: 16,
                            ),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).deleteButtonTooltip,
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          field.didChange(null);
                          onClearCountry();
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: profileTextMuted,
                          size: profileScaled(context, 20, min: 18, max: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
            ],
            TextField(
              controller: searchController,
              enabled: !isLoading,
              cursorColor: AppColors.accent,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: profileScaled(context, 14, min: 13, max: 15),
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: TextStyle(
                  color: profileTextMuted,
                  fontSize: profileScaled(context, 14, min: 13, max: 15),
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color:
                      hasError && !hasSelection ? errorColor : AppColors.accent,
                ),
                errorText: hasSelection ? null : errorText,
                errorStyle: TextStyle(
                  color: errorColor,
                  fontSize: profileScaled(context, 12, min: 11, max: 12),
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: profileScaled(context, 14, min: 12, max: 16),
                  vertical: profileScaled(context, 13, min: 11, max: 14),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    profileScaled(context, 16, min: 14, max: 18),
                  ),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    profileScaled(context, 16, min: 14, max: 18),
                  ),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    profileScaled(context, 16, min: 14, max: 18),
                  ),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 1.2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    profileScaled(context, 16, min: 14, max: 18),
                  ),
                  borderSide: const BorderSide(color: errorColor),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    profileScaled(context, 16, min: 14, max: 18),
                  ),
                  borderSide: const BorderSide(color: errorColor, width: 1.2),
                ),
              ),
            ),
            if (isLoading) ...[
              SizedBox(height: profileScaled(context, 12, min: 10, max: 12)),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: profileScaled(context, 22, min: 20, max: 24),
                  height: profileScaled(context, 22, min: 20, max: 24),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ] else if (searchQuery.trim().isNotEmpty) ...[
              SizedBox(height: profileScaled(context, 12, min: 10, max: 12)),
              if (visibleCountries.isEmpty)
                Text(
                  emptyLabel,
                  style: TextStyle(
                    color: profileTextMuted,
                    fontSize: profileScaled(context, 13, min: 12, max: 13),
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: profileScaled(context, 224, min: 180, max: 240),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: visibleCountries.length,
                    separatorBuilder: (_, _) => SizedBox(
                      height: profileScaled(context, 8, min: 7, max: 8),
                    ),
                    itemBuilder: (context, index) {
                      final country = visibleCountries[index];
                      final code =
                          normalizeReferenceCountryCode(country.code) ??
                              country.code.trim().toUpperCase();
                      final selected = selectedCountryCode == code;

                      return InkWell(
                        onTap: () {
                          field.didChange(code);
                          onCountrySelected(country);
                        },
                        borderRadius: BorderRadius.circular(
                          profileScaled(context, 14, min: 12, max: 16),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accent.withValues(alpha: 0.16)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(
                              profileScaled(context, 14, min: 12, max: 16),
                            ),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accent
                                  : Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: profileScaled(
                                context,
                                13,
                                min: 11,
                                max: 14,
                              ),
                              vertical: profileScaled(
                                context,
                                11,
                                min: 10,
                                max: 12,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _countryLabel(country),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: profileScaled(
                                        context,
                                        14,
                                        min: 13,
                                        max: 15,
                                      ),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: profileScaled(
                                    context,
                                    10,
                                    min: 8,
                                    max: 10,
                                  ),
                                ),
                                Text(
                                  code,
                                  style: TextStyle(
                                    color: profileTextMuted,
                                    fontSize: profileScaled(
                                      context,
                                      12,
                                      min: 11,
                                      max: 12,
                                    ),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  String _countryLabel(ReferenceCountry country) {
    final name = country.name.trim();
    if (name.isNotEmpty) return name;
    return normalizeReferenceCountryCode(country.code) ?? country.code.trim();
  }
}

class _ProfileTimezoneSearchField extends StatelessWidget {
  const _ProfileTimezoneSearchField({
    required this.selectedTimezone,
    required this.selectedTimezoneId,
    required this.searchController,
    required this.visibleTimezones,
    required this.isLoading,
    required this.searchQuery,
    required this.searchHint,
    required this.emptyLabel,
    required this.onTimezoneSelected,
  });

  final ReferenceTimezone? selectedTimezone;
  final String? selectedTimezoneId;
  final TextEditingController searchController;
  final List<ReferenceTimezone> visibleTimezones;
  final bool isLoading;
  final String searchQuery;
  final String searchHint;
  final String emptyLabel;
  final ValueChanged<ReferenceTimezone> onTimezoneSelected;

  @override
  Widget build(BuildContext context) {
    final timezoneLabelLang = Localizations.localeOf(context).languageCode;
    final hasSelection = selectedTimezoneId != null;
    final selectedLabel = selectedTimezone == null
        ? selectedTimezoneId ?? searchHint
        : referenceTimezoneLabel(selectedTimezone!, lang: timezoneLabelLang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasSelection) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(
                profileScaled(context, 18, min: 16, max: 20),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: profileScaled(context, 14, min: 12, max: 16),
                vertical: profileScaled(context, 11, min: 10, max: 12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: AppColors.accent,
                    size: profileScaled(context, 20, min: 18, max: 21),
                  ),
                  SizedBox(width: profileScaled(context, 10, min: 8, max: 10)),
                  Expanded(
                    child: Text(
                      selectedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: profileScaled(context, 15, min: 14, max: 16),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
        ],
        TextField(
          controller: searchController,
          enabled: !isLoading,
          cursorColor: AppColors.accent,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: profileScaled(context, 14, min: 13, max: 15),
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: searchHint,
            hintStyle: TextStyle(
              color: profileTextMuted,
              fontSize: profileScaled(context, 14, min: 13, max: 15),
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.accent,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            contentPadding: EdgeInsets.symmetric(
              horizontal: profileScaled(context, 14, min: 12, max: 16),
              vertical: profileScaled(context, 13, min: 11, max: 14),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                profileScaled(context, 16, min: 14, max: 18),
              ),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                profileScaled(context, 16, min: 14, max: 18),
              ),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                profileScaled(context, 16, min: 14, max: 18),
              ),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
            ),
          ),
        ),
        if (isLoading) ...[
          SizedBox(height: profileScaled(context, 12, min: 10, max: 12)),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: profileScaled(context, 22, min: 20, max: 24),
              height: profileScaled(context, 22, min: 20, max: 24),
              child: const CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.accent,
              ),
            ),
          ),
        ] else if (searchQuery.trim().isNotEmpty) ...[
          SizedBox(height: profileScaled(context, 12, min: 10, max: 12)),
          if (visibleTimezones.isEmpty)
            Text(
              emptyLabel,
              style: TextStyle(
                color: profileTextMuted,
                fontSize: profileScaled(context, 13, min: 12, max: 13),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: profileScaled(context, 224, min: 180, max: 240),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: visibleTimezones.length,
                separatorBuilder: (_, _) =>
                    SizedBox(height: profileScaled(context, 8, min: 7, max: 8)),
                itemBuilder: (context, index) {
                  final timezone = visibleTimezones[index];
                  final timezoneId =
                      normalizeReferenceTimezoneId(timezone.id) ??
                          timezone.id.trim();
                  final selected = selectedTimezoneId == timezoneId;

                  return InkWell(
                    onTap: () => onTimezoneSelected(timezone),
                    borderRadius: BorderRadius.circular(
                      profileScaled(context, 14, min: 12, max: 16),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accent.withValues(alpha: 0.16)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(
                          profileScaled(context, 14, min: 12, max: 16),
                        ),
                        border: Border.all(
                          color: selected
                              ? AppColors.accent
                              : Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: profileScaled(
                            context,
                            13,
                            min: 11,
                            max: 14,
                          ),
                          vertical: profileScaled(
                            context,
                            11,
                            min: 10,
                            max: 12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                referenceTimezoneLabel(
                                  timezone,
                                  lang: timezoneLabelLang,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: profileScaled(
                                    context,
                                    14,
                                    min: 13,
                                    max: 15,
                                  ),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

class _ProfileCurrencySearchField extends StatelessWidget {
  const _ProfileCurrencySearchField({
    required this.selectedCurrency,
    required this.selectedCurrencyCode,
    required this.searchController,
    required this.visibleCurrencies,
    required this.isLoading,
    required this.searchQuery,
    required this.searchHint,
    required this.emptyLabel,
    required this.onCurrencySelected,
  });

  final ReferenceCurrency? selectedCurrency;
  final String? selectedCurrencyCode;
  final TextEditingController searchController;
  final List<ReferenceCurrency> visibleCurrencies;
  final bool isLoading;
  final String searchQuery;
  final String searchHint;
  final String emptyLabel;
  final ValueChanged<ReferenceCurrency> onCurrencySelected;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCurrencyCode != null;
    final selectedLabel = selectedCurrency == null
        ? selectedCurrencyCode ?? searchHint
        : referenceCurrencyLabel(selectedCurrency!);
    final selectedSymbol = selectedCurrency?.symbol.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasSelection) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(
                profileScaled(context, 18, min: 16, max: 20),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: profileScaled(context, 14, min: 12, max: 16),
                vertical: profileScaled(context, 11, min: 10, max: 12),
              ),
              child: Row(
                children: [
                  Text(
                    selectedSymbol == null || selectedSymbol.isEmpty
                        ? selectedCurrencyCode ?? ''
                        : selectedSymbol,
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: profileScaled(context, 18, min: 16, max: 20),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: profileScaled(context, 10, min: 8, max: 10)),
                  Expanded(
                    child: Text(
                      selectedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: profileScaled(context, 15, min: 14, max: 16),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
        ],
        TextField(
          controller: searchController,
          enabled: !isLoading,
          cursorColor: AppColors.accent,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: profileScaled(context, 14, min: 13, max: 15),
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: searchHint,
            hintStyle: TextStyle(
              color: profileTextMuted,
              fontSize: profileScaled(context, 14, min: 13, max: 15),
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.accent,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            contentPadding: EdgeInsets.symmetric(
              horizontal: profileScaled(context, 14, min: 12, max: 16),
              vertical: profileScaled(context, 13, min: 11, max: 14),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                profileScaled(context, 16, min: 14, max: 18),
              ),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                profileScaled(context, 16, min: 14, max: 18),
              ),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                profileScaled(context, 16, min: 14, max: 18),
              ),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
            ),
          ),
        ),
        if (isLoading) ...[
          SizedBox(height: profileScaled(context, 12, min: 10, max: 12)),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: profileScaled(context, 22, min: 20, max: 24),
              height: profileScaled(context, 22, min: 20, max: 24),
              child: const CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.accent,
              ),
            ),
          ),
        ] else if (searchQuery.trim().isNotEmpty) ...[
          SizedBox(height: profileScaled(context, 12, min: 10, max: 12)),
          if (visibleCurrencies.isEmpty)
            Text(
              emptyLabel,
              style: TextStyle(
                color: profileTextMuted,
                fontSize: profileScaled(context, 13, min: 12, max: 13),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: profileScaled(context, 224, min: 180, max: 240),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: visibleCurrencies.length,
                separatorBuilder: (_, _) =>
                    SizedBox(height: profileScaled(context, 8, min: 7, max: 8)),
                itemBuilder: (context, index) {
                  final currency = visibleCurrencies[index];
                  final currencyCode =
                      normalizeReferenceCurrencyCode(currency.code) ??
                          currency.code.trim();
                  final selected = selectedCurrencyCode == currencyCode;
                  final symbol = currency.symbol.trim();

                  return InkWell(
                    onTap: () => onCurrencySelected(currency),
                    borderRadius: BorderRadius.circular(
                      profileScaled(context, 14, min: 12, max: 16),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accent.withValues(alpha: 0.16)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(
                          profileScaled(context, 14, min: 12, max: 16),
                        ),
                        border: Border.all(
                          color: selected
                              ? AppColors.accent
                              : Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: profileScaled(
                            context,
                            13,
                            min: 11,
                            max: 14,
                          ),
                          vertical: profileScaled(
                            context,
                            11,
                            min: 10,
                            max: 12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              symbol.isEmpty ? currencyCode : symbol,
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: profileScaled(
                                  context,
                                  16,
                                  min: 14,
                                  max: 18,
                                ),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(
                              width: profileScaled(
                                context,
                                10,
                                min: 8,
                                max: 10,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                referenceCurrencyLabel(currency),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: profileScaled(
                                    context,
                                    14,
                                    min: 13,
                                    max: 15,
                                  ),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: profileScaled(
                                context,
                                10,
                                min: 8,
                                max: 10,
                              ),
                            ),
                            Text(
                              currencyCode,
                              style: TextStyle(
                                color: profileTextMuted,
                                fontSize: profileScaled(
                                  context,
                                  12,
                                  min: 11,
                                  max: 12,
                                ),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(profileScaled(context, 18, min: 14, max: 20)),
      decoration: profileCardDecoration(
        context,
        radius: profileScaled(context, 22, min: 18, max: 24),
      ),
      child: child,
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: profileTextSoft,
            fontSize: profileScaled(context, 12, min: 11, max: 12),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
        child,
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hintText,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      profileScaled(context, 18, min: 16, max: 20),
    );

    return TextFormField(
      controller: controller,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: profileScaled(context, 15, min: 14, max: 16),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: profileTextMuted,
          fontSize: profileScaled(context, 15, min: 14, max: 16),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: Color(0xFFE47F78)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: Color(0xFFE47F78)),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: profileScaled(context, 16, min: 14, max: 18),
          vertical: profileScaled(context, 14, min: 12, max: 16),
        ),
      ),
    );
  }
}
