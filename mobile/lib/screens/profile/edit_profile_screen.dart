import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/network/file_api.dart';
import '../../core/network/reference_api.dart';
import '../../core/reference/country_filter_utils.dart';
import '../../core/reference/currency_filter_utils.dart';
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
  final _nicknameFieldKey = GlobalKey();
  final _phoneFieldKey = GlobalKey();
  final _countryFieldKey = GlobalKey();
  final _profileApi = ProfileApi();
  final _fileApi = FileApi();
  final _referenceApi = ReferenceApi();
  final _imagePicker = ImagePicker();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _phoneCodeController;
  late final TextEditingController _bioController;
  late final TextEditingController _countryCodeController;
  late final TextEditingController _countrySearchController;
  late final TextEditingController _currencyController;
  late final TextEditingController _currencySearchController;

  late String _localeCode;
  late final String _initialNickname;
  List<ReferenceCountry> _countries = const [];
  Map<String, Set<String>> _countrySearchAliases = const {};
  List<ReferenceCurrency> _currencies = const [];
  Map<String, Set<String>> _currencySearchAliases = const {};
  Future<void>? _countriesLoadFuture;
  Future<void>? _currenciesLoadFuture;
  String _countrySearchQuery = '';
  String _currencySearchQuery = '';
  String? _avatarFileId;

  Future<String?>? _avatarFuture;
  Uint8List? _avatarPreviewBytes;
  bool _isCountriesLoading = false;
  bool _isCurrenciesLoading = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isCheckingNickname = false;
  bool _isNicknameTaken = false;
  bool _isNicknameAvailable = false;
  String? _nicknameAvailabilityError;
  String? _lastCheckedNickname;
  Timer? _nicknameAvailabilityDebounce;
  Timer? _phoneResendCountdownTimer;
  int _nicknameAvailabilityRequestId = 0;
  String? _phoneVerificationChallengeId;
  String? _phoneVerificationMaskedPhone;
  String? _phoneVerificationError;
  int _phoneResendSecondsRemaining = 0;
  bool _isStartingPhoneVerification = false;
  bool _isVerifyingPhoneVerification = false;
  bool _isResendingPhoneVerification = false;
  bool _isPhoneVerificationConfirmed = false;
  bool _isChangingVerifiedPhone = false;
  bool _isApplyingPhonePrefix = false;
  String? _verifiedPhoneBeforeChange;

  @override
  void initState() {
    super.initState();

    final profile = context.read<SessionProvider>().profile;
    final appLocaleCode = context.read<LocaleProvider>().locale.languageCode;
    _initialNickname = (profile?.nickname ?? '').trim();

    _firstNameController = TextEditingController(text: profile?.firstName ?? '')
      ..addListener(_handlePreviewChanged);
    _lastNameController = TextEditingController(text: profile?.lastName ?? '')
      ..addListener(_handlePreviewChanged);
    _nicknameController = TextEditingController(text: _initialNickname)
      ..addListener(_handleNicknameChanged);
    _phoneController = TextEditingController(
      text: _initialPhoneInputText(profile),
    )..addListener(_handlePhoneChanged);
    _phoneCodeController = TextEditingController();
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _countryCodeController = TextEditingController(
      text: profile?.countryCode ?? '',
    );
    _countrySearchController = TextEditingController()
      ..addListener(_handleCountrySearchChanged);
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
    _phoneVerificationMaskedPhone = profile?.primaryPhoneVerified == true
        ? profile?.primaryPhoneDisplay
        : null;
    _isPhoneVerificationConfirmed = profile?.primaryPhoneVerified == true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadCountries());
      unawaited(_loadCurrencies());
    });
  }

  @override
  void dispose() {
    _nicknameAvailabilityDebounce?.cancel();
    _phoneResendCountdownTimer?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _phoneCodeController.dispose();
    _bioController.dispose();
    _countryCodeController.dispose();
    _countrySearchController
      ..removeListener(_handleCountrySearchChanged)
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

  void _handleNicknameChanged() {
    _handlePreviewChanged();
    _scheduleNicknameAvailabilityCheck();
  }

  String _initialPhoneInputText(UserProfileVm? profile) {
    if (profile?.primaryPhoneVerified == true) {
      return profile?.primaryPhoneDisplay ?? '';
    }
    return '+';
  }

  void _handlePhoneChanged() {
    if (_isApplyingPhonePrefix ||
        (_isPhoneVerificationConfirmed && !_isChangingVerifiedPhone)) {
      return;
    }
    _ensurePhonePlusPrefix();
  }

  void _ensurePhonePlusPrefix() {
    final value = _phoneController.value;
    final text = value.text;

    if (text.startsWith('+')) return;

    final nextText = text.isEmpty ? '+' : '+$text';
    final baseOffset = value.selection.baseOffset;
    final nextOffset = text.isEmpty
        ? 1
        : (baseOffset < 0 ? nextText.length : baseOffset + 1);

    _isApplyingPhonePrefix = true;
    _phoneController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(
        offset: nextOffset.clamp(0, nextText.length),
      ),
    );
    _isApplyingPhonePrefix = false;
  }

  void _scheduleNicknameAvailabilityCheck() {
    if (_isNicknameLocked) return;

    final nickname = _nicknameController.text.trim();
    _nicknameAvailabilityDebounce?.cancel();
    _nicknameAvailabilityRequestId++;

    if (nickname.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isCheckingNickname = false;
        _isNicknameTaken = false;
        _isNicknameAvailable = false;
        _nicknameAvailabilityError = null;
        _lastCheckedNickname = null;
      });
      return;
    }

    setState(() {
      _isCheckingNickname = false;
      _isNicknameTaken = false;
      _isNicknameAvailable = false;
      _nicknameAvailabilityError = null;
      _lastCheckedNickname = null;
    });

    _nicknameAvailabilityDebounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_checkNicknameAvailability(nickname)),
    );
  }

  Future<void> _checkNicknameAvailability(String nickname) async {
    final requestId = ++_nicknameAvailabilityRequestId;
    if (!mounted || _isNicknameLocked) return;

    setState(() {
      _isCheckingNickname = true;
      _isNicknameTaken = false;
      _isNicknameAvailable = false;
      _nicknameAvailabilityError = null;
      _lastCheckedNickname = nickname;
    });

    try {
      final available = await _profileApi.isNicknameAvailable(nickname);
      if (!mounted ||
          requestId != _nicknameAvailabilityRequestId ||
          _nicknameController.text.trim() != nickname) {
        return;
      }

      setState(() {
        _isCheckingNickname = false;
        _isNicknameTaken = !available;
        _isNicknameAvailable = available;
        _nicknameAvailabilityError = null;
        _lastCheckedNickname = nickname;
      });
    } catch (_) {
      if (!mounted ||
          requestId != _nicknameAvailabilityRequestId ||
          _nicknameController.text.trim() != nickname) {
        return;
      }

      setState(() {
        _isCheckingNickname = false;
        _isNicknameTaken = false;
        _isNicknameAvailable = false;
        _nicknameAvailabilityError = AppLocalizations.of(
          context,
        )!.profileNicknameCheckFailed;
        _lastCheckedNickname = nickname;
      });
    }
  }

  void _handleCountrySearchChanged() {
    final nextQuery = _countrySearchController.text.trim();
    if (nextQuery == _countrySearchQuery) return;

    setState(() => _countrySearchQuery = nextQuery);
  }

  void _handleCurrencySearchChanged() {
    final nextQuery = _currencySearchController.text.trim();
    if (nextQuery == _currencySearchQuery) return;

    setState(() => _currencySearchQuery = nextQuery);
  }

  bool get _isNicknameLocked => _initialNickname.isNotEmpty;

  String _nicknameSupportingText(AppLocalizations l10n) {
    final lines = <String>[l10n.profileNicknameOneTimeHint];
    final currentNickname = _nicknameController.text.trim();

    if (!_isNicknameLocked && currentNickname.isNotEmpty) {
      if (_isCheckingNickname) {
        lines.add(l10n.profileNicknameChecking);
      } else if (_isNicknameAvailable &&
          _lastCheckedNickname == currentNickname) {
        lines.add(l10n.profileNicknameAvailable);
      } else if (_nicknameAvailabilityError != null &&
          _lastCheckedNickname == currentNickname) {
        lines.add(_nicknameAvailabilityError!);
      }
    }

    return lines.join('\n');
  }

  String? _nicknameErrorText(AppLocalizations l10n) {
    final currentNickname = _nicknameController.text.trim();
    if (!_isNicknameLocked &&
        _isNicknameTaken &&
        _lastCheckedNickname == currentNickname) {
      return l10n.profileNicknameTaken;
    }
    return null;
  }

  bool get _hasPendingPhoneVerification =>
      (_phoneVerificationChallengeId ?? '').trim().isNotEmpty;

  bool get _isPhoneVerificationBusy =>
      _isStartingPhoneVerification ||
      _isVerifyingPhoneVerification ||
      _isResendingPhoneVerification;

  ButtonStyle get _phoneChangeActionStyle {
    return TextButton.styleFrom(
      foregroundColor: AppPalette.primary,
      padding: AppEdgeInsets.zero,
      alignment: Alignment.centerLeft,
    );
  }

  String _currentVerifiedPhoneDisplay(UserProfileVm? profile) {
    final pendingChangePhone = (_verifiedPhoneBeforeChange ?? '').trim();
    if (_isChangingVerifiedPhone && pendingChangePhone.isNotEmpty) {
      return pendingChangePhone;
    }

    final profilePhone = (profile?.primaryPhoneDisplay ?? '').trim();
    if (profile?.primaryPhoneVerified == true && profilePhone.isNotEmpty) {
      return profilePhone;
    }

    if (_isPhoneVerificationConfirmed) {
      return (_phoneVerificationMaskedPhone ?? '').trim();
    }

    return '';
  }

  void _setPhoneControllerText(String text) {
    final nextText = text.trim().isEmpty ? '+' : text.trim();
    _isApplyingPhonePrefix = true;
    _phoneController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
    _isApplyingPhonePrefix = false;
  }

  void _startVerifiedPhoneChange() {
    if (_isPhoneVerificationBusy || _hasPendingPhoneVerification) return;

    final currentPhone = _currentVerifiedPhoneDisplay(
      context.read<SessionProvider>().profile,
    );
    _phoneResendCountdownTimer?.cancel();
    _phoneCodeController.clear();
    setState(() {
      _isChangingVerifiedPhone = true;
      _verifiedPhoneBeforeChange = currentPhone.isEmpty ? null : currentPhone;
      _phoneVerificationChallengeId = null;
      _phoneVerificationMaskedPhone = null;
      _phoneVerificationError = null;
      _phoneResendSecondsRemaining = 0;
      _isPhoneVerificationConfirmed = false;
    });
    _setPhoneControllerText('+');
  }

  String _normalizePhoneInput(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];
      if (char == '+' && i == 0) {
        buffer.write(char);
      } else if (RegExp(r'\d').hasMatch(char)) {
        buffer.write(char);
      }
    }

    final normalized = buffer.toString();
    if (normalized.startsWith('00')) {
      return '+${normalized.substring(2)}';
    }
    return normalized;
  }

  bool _isValidPhoneInput(String phone) {
    return RegExp(r'^\+\d{8,15}$').hasMatch(phone);
  }

  String _phoneVerificationErrorMessage(
    DioException error,
    AppLocalizations l10n,
  ) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final backendError = data is Map<String, dynamic>
        ? data['error']?.toString().trim()
        : null;

    if (backendError == 'phone is already verified for this account') {
      return l10n.profilePhoneAlreadyVerified;
    }
    if (statusCode == 409 || backendError == 'phone is unavailable') {
      return l10n.profilePhoneUnavailable;
    }
    if (statusCode == 410 ||
        backendError == 'phone verification code expired') {
      return l10n.profilePhoneCodeExpired;
    }
    if (statusCode == 401 ||
        backendError == 'invalid phone verification code') {
      return l10n.profilePhoneCodeInvalid;
    }
    if (statusCode == 423 || backendError == 'phone verification locked') {
      return l10n.profilePhoneVerificationLocked;
    }
    if (statusCode == 429) {
      return l10n.profilePhoneRateLimited;
    }
    if (statusCode == 503) {
      return l10n.profilePhoneVerificationUnavailable;
    }
    if (backendError == 'phone is required' ||
        backendError == 'invalid phone') {
      return l10n.profilePhoneInvalid;
    }
    return l10n.profilePhoneVerificationFailed;
  }

  void _startPhoneResendCountdown(int seconds) {
    _phoneResendCountdownTimer?.cancel();
    final initial = seconds < 0 ? 0 : seconds;
    setState(() => _phoneResendSecondsRemaining = initial);

    if (initial == 0) return;

    _phoneResendCountdownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final next = _phoneResendSecondsRemaining - 1;
      if (next <= 0) {
        timer.cancel();
        setState(() => _phoneResendSecondsRemaining = 0);
        return;
      }

      setState(() => _phoneResendSecondsRemaining = next);
    });
  }

  Future<void> _startPhoneVerification() async {
    if (_isPhoneVerificationBusy) return;

    final l10n = AppLocalizations.of(context)!;
    final phone = _normalizePhoneInput(_phoneController.text);
    if (!_isValidPhoneInput(phone)) {
      setState(() => _phoneVerificationError = l10n.profilePhoneInvalid);
      await _scrollToField(_phoneFieldKey);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isStartingPhoneVerification = true;
      _phoneVerificationError = null;
    });

    try {
      final challenge = await _profileApi.startPhoneVerification(phone);
      if (!mounted) return;

      _phoneCodeController.clear();
      _setPhoneControllerText(phone);
      setState(() {
        _phoneVerificationChallengeId = challenge.challengeId;
        _phoneVerificationMaskedPhone = challenge.maskedPhone;
        _phoneVerificationError = null;
        _isPhoneVerificationConfirmed = false;
      });
      _startPhoneResendCountdown(challenge.resendAfterSeconds);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _phoneVerificationError = _phoneVerificationErrorMessage(e, l10n);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phoneVerificationError = l10n.profilePhoneVerificationFailed;
      });
    } finally {
      if (mounted) {
        setState(() => _isStartingPhoneVerification = false);
      }
    }
  }

  Future<void> _verifyPhoneVerification() async {
    if (_isPhoneVerificationBusy) return;

    final l10n = AppLocalizations.of(context)!;
    final challengeId = (_phoneVerificationChallengeId ?? '').trim();
    final code = _phoneCodeController.text.trim();

    if (challengeId.isEmpty) {
      setState(() => _phoneVerificationError = l10n.profilePhoneStartRequired);
      return;
    }
    if (!RegExp(r'^\d{4,10}$').hasMatch(code)) {
      setState(() => _phoneVerificationError = l10n.profilePhoneCodeRequired);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifyingPhoneVerification = true;
      _phoneVerificationError = null;
    });

    try {
      final result = await _profileApi.verifyPhoneVerification(
        challengeId: challengeId,
        code: code,
      );
      if (!mounted) return;

      _phoneResendCountdownTimer?.cancel();
      _phoneCodeController.clear();
      setState(() {
        _phoneVerificationChallengeId = null;
        _phoneVerificationMaskedPhone = result.maskedPhone;
        _phoneVerificationError = null;
        _phoneResendSecondsRemaining = 0;
        _isPhoneVerificationConfirmed = result.verified;
        _isChangingVerifiedPhone = false;
        _verifiedPhoneBeforeChange = null;
        if ((result.maskedPhone ?? '').trim().isNotEmpty) {
          _setPhoneControllerText(result.maskedPhone!.trim());
        }
      });

      await context.read<SessionProvider>().reloadProfile();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _phoneVerificationError = _phoneVerificationErrorMessage(e, l10n);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phoneVerificationError = l10n.profilePhoneVerificationFailed;
      });
    } finally {
      if (mounted) {
        setState(() => _isVerifyingPhoneVerification = false);
      }
    }
  }

  Future<void> _resendPhoneVerification() async {
    if (_isPhoneVerificationBusy || _phoneResendSecondsRemaining > 0) return;

    final l10n = AppLocalizations.of(context)!;
    final challengeId = (_phoneVerificationChallengeId ?? '').trim();
    if (challengeId.isEmpty) {
      setState(() => _phoneVerificationError = l10n.profilePhoneStartRequired);
      return;
    }

    setState(() {
      _isResendingPhoneVerification = true;
      _phoneVerificationError = null;
    });

    try {
      final challenge = await _profileApi.resendPhoneVerification(challengeId);
      if (!mounted) return;

      setState(() {
        _phoneVerificationChallengeId = challenge.challengeId;
        _phoneVerificationMaskedPhone = challenge.maskedPhone;
        _phoneVerificationError = null;
      });
      _startPhoneResendCountdown(challenge.resendAfterSeconds);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _phoneVerificationError = _phoneVerificationErrorMessage(e, l10n);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phoneVerificationError = l10n.profilePhoneVerificationFailed;
      });
    } finally {
      if (mounted) {
        setState(() => _isResendingPhoneVerification = false);
      }
    }
  }

  Future<void> _cancelPendingPhoneVerification() async {
    await _cancelPhoneVerification(restoreVerifiedPhone: false);
  }

  Future<void> _cancelVerifiedPhoneChange() async {
    await _cancelPhoneVerification(restoreVerifiedPhone: true);
  }

  Future<void> _cancelPhoneVerification({
    required bool restoreVerifiedPhone,
  }) async {
    if (_isPhoneVerificationBusy) return;

    final profile = context.read<SessionProvider>().profile;
    final currentVerifiedPhone = restoreVerifiedPhone
        ? _currentVerifiedPhoneDisplay(profile)
        : '';

    setState(() {
      _phoneVerificationChallengeId = null;
      _phoneVerificationMaskedPhone = currentVerifiedPhone.isEmpty
          ? null
          : currentVerifiedPhone;
      _phoneVerificationError = null;
      _phoneResendSecondsRemaining = 0;
      _isPhoneVerificationConfirmed =
          restoreVerifiedPhone &&
          (profile?.primaryPhoneVerified == true ||
              currentVerifiedPhone.isNotEmpty);
      _isChangingVerifiedPhone = false;
      _verifiedPhoneBeforeChange = null;
    });
    _phoneCodeController.clear();
    _phoneResendCountdownTimer?.cancel();
    _setPhoneControllerText(
      restoreVerifiedPhone ? currentVerifiedPhone : _phoneController.text,
    );

    try {
      await _profileApi.cancelPendingPhoneVerification();
    } catch (_) {
      // Local cancellation keeps the user unblocked; backend pending challenge
      // will expire if the network request fails.
    }
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
          nickname: _isNicknameLocked ? null : _nicknameController.text,
          bio: _bioController.text,
          avatarFileId: _avatarFileId,
          countryCode: _countryCodeController.text,
          locale: _localeCode,
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
          final normalizedBackendError = backendError.trim();
          if (normalizedBackendError == 'nickname is already taken') {
            message = l10n.profileNicknameTaken;
          } else if (normalizedBackendError == 'nickname is required') {
            message = l10n.nicknameRequired;
          } else if (normalizedBackendError == 'nickname cannot be changed') {
            message = l10n.profileNicknameLockedDescription;
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

    if (!_isNicknameLocked && _nicknameController.text.trim().isEmpty) {
      await _scrollToField(_nicknameFieldKey);
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
    final display = _nicknameController.text.trim();
    if (display.isNotEmpty) {
      return display;
    }

    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final fullName = [first, last].where((part) => part.isNotEmpty).join(' ');
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return profile?.preferredName ?? 'Inflap';
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

  Widget _buildPhoneVerificationSection(
    UserProfileVm? profile,
    AppLocalizations l10n,
  ) {
    final currentVerifiedPhone = _currentVerifiedPhoneDisplay(profile);
    final hasVerifiedPhone =
        profile?.primaryPhoneVerified == true ||
        (_isPhoneVerificationConfirmed && !_isChangingVerifiedPhone) ||
        (_isChangingVerifiedPhone && currentVerifiedPhone.isNotEmpty);
    final isChangingVerifiedPhone =
        hasVerifiedPhone && _isChangingVerifiedPhone;
    final isVerified = hasVerifiedPhone && !isChangingVerifiedPhone;
    final displayPhone = isVerified && currentVerifiedPhone.isNotEmpty
        ? currentVerifiedPhone
        : (_phoneVerificationMaskedPhone ?? '').trim().isNotEmpty
        ? _phoneVerificationMaskedPhone!.trim()
        : profile?.primaryPhoneDisplay ?? '';
    final isSendDisabled =
        _isPhoneVerificationBusy || isVerified || _hasPendingPhoneVerification;
    final isVerifyDisabled =
        _isPhoneVerificationBusy || !_hasPendingPhoneVerification;
    final isResendDisabled =
        _isPhoneVerificationBusy ||
        !_hasPendingPhoneVerification ||
        _phoneResendSecondsRemaining > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionHeading(title: l10n.profilePhoneVerificationSection),
        SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
        _ProfileSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: profileScaled(context, 42, min: 38, max: 44),
                    height: profileScaled(context, 42, min: 38, max: 44),
                    decoration: AppBoxDecoration(
                      color: AppPalette.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVerified
                          ? Icons.verified_user_rounded
                          : Icons.sms_outlined,
                      color: AppPalette.primary,
                      size: profileScaled(context, 21, min: 19, max: 22),
                    ),
                  ),
                  SizedBox(width: profileScaled(context, 12, min: 10, max: 14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVerified
                              ? l10n.profilePhoneVerifiedTitle
                              : l10n.profilePhoneVerificationTitle,
                          style: AppTextStyle(
                            color: AppPalette.textPrimary,
                            fontSize: profileScaled(
                              context,
                              16,
                              min: 15,
                              max: 17,
                            ),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 6, min: 5, max: 7),
                        ),
                        Text(
                          isVerified
                              ? l10n.profilePhoneVerifiedDescription
                              : l10n.profilePhoneVerificationDescription,
                          style: AppTextStyle(
                            color: profileTextMuted,
                            fontSize: profileScaled(
                              context,
                              13,
                              min: 12,
                              max: 13,
                            ),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: profileScaled(context, 16, min: 14, max: 18)),
              _LabeledInput(
                key: _phoneFieldKey,
                label: l10n.profilePhone,
                child: _StyledTextField(
                  controller: _phoneController,
                  hintText: '+77011234567',
                  readOnly: isVerified || _hasPendingPhoneVerification,
                  keyboardType: TextInputType.phone,
                  textCapitalization: TextCapitalization.none,
                ),
              ),
              if (isVerified && displayPhone.isNotEmpty) ...[
                SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
                _PhoneStatusLine(
                  icon: Icons.check_circle_rounded,
                  text: l10n.profilePhoneVerifiedAs(displayPhone),
                  color: AppPalette.greenSoft01,
                ),
                SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _isPhoneVerificationBusy
                        ? null
                        : _startVerifiedPhoneChange,
                    style: _phoneChangeActionStyle,
                    icon: const Icon(Icons.edit_rounded),
                    label: Text(l10n.profilePhoneChangeNumber),
                  ),
                ),
              ],
              if (isChangingVerifiedPhone &&
                  currentVerifiedPhone.isNotEmpty) ...[
                SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
                _PhoneStatusLine(
                  icon: Icons.verified_rounded,
                  text: l10n.profilePhoneCurrentVerifiedAs(
                    currentVerifiedPhone,
                  ),
                  color: AppPalette.greenSoft01,
                ),
              ],
              if (!isVerified && !_hasPendingPhoneVerification) ...[
                SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
                FilledButton(
                  onPressed: isSendDisabled ? null : _startPhoneVerification,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.primary,
                    foregroundColor: AppPalette.white,
                    minimumSize: Size(
                      double.infinity,
                      profileScaled(context, 50, min: 46, max: 52),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorderRadius.circular(
                        profileScaled(context, 16, min: 14, max: 18),
                      ),
                    ),
                  ),
                  child: _isStartingPhoneVerification
                      ? SizedBox(
                          width: profileScaled(context, 18, min: 16, max: 18),
                          height: profileScaled(context, 18, min: 16, max: 18),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppPalette.white,
                          ),
                        )
                      : Text(
                          l10n.profilePhoneSendCode,
                          textAlign: TextAlign.center,
                          style: const AppTextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                if (isChangingVerifiedPhone) ...[
                  SizedBox(height: profileScaled(context, 8, min: 6, max: 10)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _isPhoneVerificationBusy
                          ? null
                          : _cancelVerifiedPhoneChange,
                      style: _phoneChangeActionStyle,
                      icon: const Icon(Icons.close_rounded),
                      label: Text(l10n.profilePhoneCancelChange),
                    ),
                  ),
                ],
              ],
              if (!isVerified && _hasPendingPhoneVerification) ...[
                SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
                _PhoneStatusLine(
                  icon: Icons.mark_email_read_outlined,
                  text: l10n.profilePhoneCodeSentTo(
                    (_phoneVerificationMaskedPhone ?? '').trim().isEmpty
                        ? _phoneController.text.trim()
                        : _phoneVerificationMaskedPhone!.trim(),
                  ),
                  color: profileTextSoft,
                ),
                SizedBox(height: profileScaled(context, 12, min: 10, max: 14)),
                _StyledTextField(
                  controller: _phoneCodeController,
                  hintText: l10n.profilePhoneCodeHint,
                  keyboardType: TextInputType.number,
                  textCapitalization: TextCapitalization.none,
                ),
                SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
                FilledButton(
                  onPressed: isVerifyDisabled ? null : _verifyPhoneVerification,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.primary,
                    foregroundColor: AppPalette.white,
                    minimumSize: Size(
                      double.infinity,
                      profileScaled(context, 50, min: 46, max: 52),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorderRadius.circular(
                        profileScaled(context, 16, min: 14, max: 18),
                      ),
                    ),
                  ),
                  child: _isVerifyingPhoneVerification
                      ? SizedBox(
                          width: profileScaled(context, 18, min: 16, max: 18),
                          height: profileScaled(context, 18, min: 16, max: 18),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppPalette.white,
                          ),
                        )
                      : Text(
                          l10n.profilePhoneVerifyCode,
                          textAlign: TextAlign.center,
                          style: const AppTextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
                Wrap(
                  spacing: profileScaled(context, 10, min: 8, max: 10),
                  runSpacing: profileScaled(context, 8, min: 6, max: 8),
                  children: [
                    TextButton.icon(
                      onPressed: isResendDisabled
                          ? null
                          : _resendPhoneVerification,
                      icon: _isResendingPhoneVerification
                          ? SizedBox(
                              width: profileScaled(
                                context,
                                16,
                                min: 14,
                                max: 16,
                              ),
                              height: profileScaled(
                                context,
                                16,
                                min: 14,
                                max: 16,
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(
                        _phoneResendSecondsRemaining > 0
                            ? l10n.profilePhoneResendIn(
                                _phoneResendSecondsRemaining,
                              )
                            : l10n.profilePhoneResendCode,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isPhoneVerificationBusy
                          ? null
                          : isChangingVerifiedPhone
                          ? _cancelVerifiedPhoneChange
                          : _cancelPendingPhoneVerification,
                      style: _phoneChangeActionStyle,
                      icon: Icon(
                        isChangingVerifiedPhone
                            ? Icons.close_rounded
                            : Icons.edit_rounded,
                      ),
                      label: Text(
                        isChangingVerifiedPhone
                            ? l10n.profilePhoneCancelChange
                            : l10n.profilePhoneChangeNumber,
                      ),
                    ),
                  ],
                ),
              ],
              if ((_phoneVerificationError ?? '').trim().isNotEmpty) ...[
                SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
                _PhoneStatusLine(
                  icon: Icons.error_outline_rounded,
                  text: _phoneVerificationError!.trim(),
                  color: AppPalette.redSoft05,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStickySaveButton(AppLocalizations l10n) {
    return FilledButton(
      onPressed: (_isSaving || _isUploadingAvatar) ? null : _save,
      style: FilledButton.styleFrom(
        backgroundColor: AppPalette.primary,
        foregroundColor: AppPalette.white,
        minimumSize: Size(
          double.infinity,
          profileScaled(context, 56, min: 50, max: 58),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.circular(
            profileScaled(context, 18, min: 16, max: 20),
          ),
        ),
      ),
      child: _isSaving
          ? SizedBox(
              width: profileScaled(context, 18, min: 16, max: 18),
              height: profileScaled(context, 18, min: 16, max: 18),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppPalette.white,
              ),
            )
          : Text(
              l10n.profileSaveChangesButton,
              style: AppTextStyle(
                fontSize: profileScaled(context, 15, min: 14, max: 16),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = context.watch<SessionProvider>().profile;
    final padding = profileScaled(context, 20, min: 14, max: 20);
    final previewName = _previewName(profile);
    final previewInitials = _previewInitials(profile);

    return Scaffold(
      backgroundColor: AppPalette.transparent,
      bottomNavigationBar: SafeArea(
        minimum: AppEdgeInsets.fromLTRB(
          padding,
          profileScaled(context, 8, min: 6, max: 10),
          padding,
          profileScaled(context, 12, min: 10, max: 14),
        ),
        child: _buildStickySaveButton(l10n),
      ),
      body: ProfileResponsiveScope(
        child: ProfileGlassBackground(
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: AppEdgeInsets.fromLTRB(
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
                        phone: profile?.primaryPhoneDisplay,
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
                          key: _nicknameFieldKey,
                          label: l10n.nicknameLabel,
                          child: _StyledTextField(
                            controller: _nicknameController,
                            hintText: l10n.nicknameLabel,
                            readOnly: _isNicknameLocked,
                            helperText: _nicknameSupportingText(l10n),
                            errorText: _nicknameErrorText(l10n),
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (!_isNicknameLocked &&
                                  (value ?? '').trim().isEmpty) {
                                return l10n.nicknameRequired;
                              }
                              if (_nicknameErrorText(l10n) != null) {
                                return l10n.profileNicknameTaken;
                              }
                              return null;
                            },
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
                      ],
                    ),
                  ),
                  SizedBox(
                    height: profileScaled(context, 28, min: 24, max: 32),
                  ),
                  _buildPhoneVerificationSection(profile, l10n),
                  SizedBox(
                    height: profileScaled(context, 28, min: 24, max: 32),
                  ),
                  Center(
                    child: Text(
                      l10n.profileDeactivateAccountLabel,
                      style: AppTextStyle(
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
            padding: AppEdgeInsets.symmetric(
              horizontal: profileScaled(context, 12, min: 8, max: 12),
            ),
            child: Text(
              title,
              textAlign: TextAlign.left,
              style: AppTextStyle(
                color: AppPalette.textPrimary,
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
                  padding: AppEdgeInsets.all(
                    profileScaled(context, 4, min: 3, max: 5),
                  ),
                  decoration: const AppBoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppPalette.amberSoft06,
                        AppPalette.warmSurfaceHigh30,
                      ],
                    ),
                  ),
                  child: ClipOval(
                    child: DecoratedBox(
                      decoration: const AppBoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppPalette.blueWash04,
                            AppPalette.blueLight07,
                          ],
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
                              errorBuilder: (_, _, _) => Center(
                                child: Text(
                                  initials,
                                  style: AppTextStyle(
                                    color: AppPalette.blueMuted20,
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
                                style: AppTextStyle(
                                  color: AppPalette.blueMuted20,
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
                              color: AppPalette.black.withValues(alpha: 0.28),
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
                                    color: AppPalette.white,
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
                    decoration: AppBoxDecoration(
                      shape: BoxShape.circle,
                      color: AppPalette.primary,
                      border: Border.all(color: profileBgTop, width: 2),
                    ),
                    child: Icon(
                      isUploadingAvatar
                          ? Icons.hourglass_top_rounded
                          : Icons.edit_rounded,
                      color: AppPalette.white,
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
          style: AppTextStyle(
            color: AppPalette.textPrimary,
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
          style: AppTextStyle(
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
      padding: AppEdgeInsets.symmetric(
        horizontal: profileScaled(context, 12, min: 10, max: 14),
        vertical: profileScaled(context, 7, min: 6, max: 8),
      ),
      decoration: AppBoxDecoration(
        color: AppPalette.white.withValues(alpha: 0.04),
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        text,
        style: AppTextStyle(
          color: profileTextSoft,
          fontSize: profileScaled(context, 12, min: 11, max: 12),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PhoneStatusLine extends StatelessWidget {
  const _PhoneStatusLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: profileScaled(context, 18, min: 16, max: 18),
        ),
        SizedBox(width: profileScaled(context, 8, min: 7, max: 9)),
        Expanded(
          child: Text(
            text,
            style: AppTextStyle(
              color: color,
              fontSize: profileScaled(context, 12, min: 11, max: 13),
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ],
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
        const errorColor = AppPalette.redSoft05;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasSelection) ...[
              DecoratedBox(
                decoration: AppBoxDecoration(
                  color: AppPalette.white.withValues(alpha: 0.04),
                  borderRadius: AppBorderRadius.circular(
                    profileScaled(context, 18, min: 16, max: 20),
                  ),
                  border: Border.all(
                    color: AppPalette.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Padding(
                  padding: AppEdgeInsets.symmetric(
                    horizontal: profileScaled(context, 14, min: 12, max: 16),
                    vertical: profileScaled(context, 11, min: 10, max: 12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.public_rounded,
                        color: AppPalette.primary,
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
                          style: AppTextStyle(
                            color: AppPalette.textPrimary,
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
              cursorColor: AppPalette.primary,
              style: AppTextStyle(
                color: AppPalette.textPrimary,
                fontSize: profileScaled(context, 14, min: 13, max: 15),
                fontWeight: FontWeight.w700,
              ),
              decoration: AppInputDecoration(
                hintText: searchHint,
                hintStyle: AppTextStyle(
                  color: profileTextMuted,
                  fontSize: profileScaled(context, 14, min: 13, max: 15),
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: hasError && !hasSelection
                      ? errorColor
                      : AppPalette.primary,
                ),
                errorText: hasSelection ? null : errorText,
                errorStyle: AppTextStyle(
                  color: errorColor,
                  fontSize: profileScaled(context, 12, min: 11, max: 12),
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: AppPalette.white.withValues(alpha: 0.04),
                contentPadding: AppEdgeInsets.symmetric(
                  horizontal: profileScaled(context, 14, min: 12, max: 16),
                  vertical: profileScaled(context, 13, min: 11, max: 14),
                ),
                border: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(
                    profileScaled(context, 16, min: 14, max: 18),
                  ),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(
                    profileScaled(context, 16, min: 14, max: 18),
                  ),
                  borderSide: BorderSide(
                    color: AppPalette.white.withValues(alpha: 0.05),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(
                    profileScaled(context, 16, min: 14, max: 18),
                  ),
                  borderSide: const BorderSide(
                    color: AppPalette.primary,
                    width: 1.2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(
                    profileScaled(context, 16, min: 14, max: 18),
                  ),
                  borderSide: const BorderSide(color: errorColor),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(
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
                    color: AppPalette.primary,
                  ),
                ),
              ),
            ] else if (searchQuery.trim().isNotEmpty) ...[
              SizedBox(height: profileScaled(context, 12, min: 10, max: 12)),
              if (visibleCountries.isEmpty)
                Text(
                  emptyLabel,
                  style: AppTextStyle(
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
                        borderRadius: AppBorderRadius.circular(
                          profileScaled(context, 14, min: 12, max: 16),
                        ),
                        child: DecoratedBox(
                          decoration: AppBoxDecoration(
                            color: selected
                                ? AppPalette.primary.withValues(alpha: 0.16)
                                : AppPalette.white.withValues(alpha: 0.04),
                            borderRadius: AppBorderRadius.circular(
                              profileScaled(context, 14, min: 12, max: 16),
                            ),
                            border: Border.all(
                              color: selected
                                  ? AppPalette.primary
                                  : AppPalette.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Padding(
                            padding: AppEdgeInsets.symmetric(
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
                                    style: AppTextStyle(
                                      color: AppPalette.textPrimary,
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
                                  style: AppTextStyle(
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
            decoration: AppBoxDecoration(
              color: AppPalette.white.withValues(alpha: 0.04),
              borderRadius: AppBorderRadius.circular(
                profileScaled(context, 18, min: 16, max: 20),
              ),
              border: Border.all(
                color: AppPalette.white.withValues(alpha: 0.05),
              ),
            ),
            child: Padding(
              padding: AppEdgeInsets.symmetric(
                horizontal: profileScaled(context, 14, min: 12, max: 16),
                vertical: profileScaled(context, 11, min: 10, max: 12),
              ),
              child: Row(
                children: [
                  Text(
                    selectedSymbol == null || selectedSymbol.isEmpty
                        ? selectedCurrencyCode ?? ''
                        : selectedSymbol,
                    style: AppTextStyle(
                      color: AppPalette.primary,
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
                      style: AppTextStyle(
                        color: AppPalette.textPrimary,
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
          cursorColor: AppPalette.primary,
          textCapitalization: TextCapitalization.words,
          style: AppTextStyle(
            color: AppPalette.textPrimary,
            fontSize: profileScaled(context, 14, min: 13, max: 15),
            fontWeight: FontWeight.w700,
          ),
          decoration: AppInputDecoration(
            hintText: searchHint,
            hintStyle: AppTextStyle(
              color: profileTextMuted,
              fontSize: profileScaled(context, 14, min: 13, max: 15),
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppPalette.primary,
            ),
            filled: true,
            fillColor: AppPalette.white.withValues(alpha: 0.04),
            contentPadding: AppEdgeInsets.symmetric(
              horizontal: profileScaled(context, 14, min: 12, max: 16),
              vertical: profileScaled(context, 13, min: 11, max: 14),
            ),
            border: OutlineInputBorder(
              borderRadius: AppBorderRadius.circular(
                profileScaled(context, 16, min: 14, max: 18),
              ),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.circular(
                profileScaled(context, 16, min: 14, max: 18),
              ),
              borderSide: BorderSide(
                color: AppPalette.white.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.circular(
                profileScaled(context, 16, min: 14, max: 18),
              ),
              borderSide: const BorderSide(
                color: AppPalette.primary,
                width: 1.2,
              ),
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
                color: AppPalette.primary,
              ),
            ),
          ),
        ] else if (searchQuery.trim().isNotEmpty) ...[
          SizedBox(height: profileScaled(context, 12, min: 10, max: 12)),
          if (visibleCurrencies.isEmpty)
            Text(
              emptyLabel,
              style: AppTextStyle(
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
                    borderRadius: AppBorderRadius.circular(
                      profileScaled(context, 14, min: 12, max: 16),
                    ),
                    child: DecoratedBox(
                      decoration: AppBoxDecoration(
                        color: selected
                            ? AppPalette.primary.withValues(alpha: 0.16)
                            : AppPalette.white.withValues(alpha: 0.04),
                        borderRadius: AppBorderRadius.circular(
                          profileScaled(context, 14, min: 12, max: 16),
                        ),
                        border: Border.all(
                          color: selected
                              ? AppPalette.primary
                              : AppPalette.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Padding(
                        padding: AppEdgeInsets.symmetric(
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
                              style: AppTextStyle(
                                color: AppPalette.primary,
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
                                style: AppTextStyle(
                                  color: AppPalette.textPrimary,
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
                              style: AppTextStyle(
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
      padding: AppEdgeInsets.all(profileScaled(context, 18, min: 14, max: 20)),
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
          style: AppTextStyle(
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
    this.readOnly = false,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final bool readOnly;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final radius = AppBorderRadius.circular(
      profileScaled(context, 18, min: 16, max: 20),
    );

    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: readOnly,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: AppTextStyle(
        color: AppPalette.textPrimary,
        fontSize: profileScaled(context, 15, min: 14, max: 16),
      ),
      decoration: AppInputDecoration(
        hintText: hintText,
        helperText: helperText,
        helperMaxLines: 3,
        errorText: errorText,
        errorMaxLines: 3,
        hintStyle: AppTextStyle(
          color: profileTextMuted,
          fontSize: profileScaled(context, 15, min: 14, max: 16),
        ),
        filled: true,
        fillColor: AppPalette.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: AppPalette.white.withValues(alpha: 0.04),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: AppPalette.white.withValues(alpha: 0.04),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: AppPalette.primary.withValues(alpha: 0.3),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppPalette.redSoft05),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppPalette.redSoft05),
        ),
        contentPadding: AppEdgeInsets.symmetric(
          horizontal: profileScaled(context, 16, min: 14, max: 18),
          vertical: profileScaled(context, 14, min: 12, max: 16),
        ),
      ),
    );
  }
}
