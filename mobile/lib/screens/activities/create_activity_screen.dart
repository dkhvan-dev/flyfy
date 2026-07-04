import 'dart:async';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/device/device_context_service.dart';
import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/network/reference_api.dart';
import '../../core/time/app_time.dart';
import '../../core/ui/app_inline_field_error.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/activities/activity_cover_url.dart';
import '../../features/activities/activity_edit_policy.dart';
import '../../features/activities/activity_location_mismatch.dart';
import '../../features/activities/activity_taxonomy_resolver.dart';
import '../../features/activities/models/activity_category_vm.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/activities/models/create_activity_request.dart';
import '../../features/activities/models/update_activity_request.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/home_location_provider.dart';
import '../../providers/session_provider.dart';
import '../../shared/formatters/app_money_formatter.dart';
import '../../shared/map/app_map_link_resolver.dart';
import '../../shared/map/app_map_links.dart';
import '../../shared/reference/app_location_label_resolver.dart';
import '../../shared/widgets/app_currency_picker_field.dart';
import '../../shared/widgets/app_map_card.dart';
import '../map/map_screen.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

Color _inlineValidationColor(BuildContext context) =>
    context.createActivityColors.danger;

final class _CreateActivityColors {
  const _CreateActivityColors._(this.colors);

  final AppColors colors;

  static _CreateActivityColors of(BuildContext context) {
    return _CreateActivityColors._(AppDesignSystem.colorsFor(context));
  }

  Color get primary => colors.primary;
  Color get primaryPressed => colors.primaryPressed;
  Color get primarySoft => colors.primarySoft;
  Color get primaryContainer => colors.primaryContainer;
  Color get onPrimary => colors.onPrimary;
  Color get secondary => colors.secondary;
  Color get secondaryPressed => colors.secondaryPressed;
  Color get secondarySoft => colors.secondarySoft;
  Color get secondaryContainer => colors.secondaryContainer;
  Color get onSecondary => colors.onSecondary;
  Color get background => colors.background;
  Color get backgroundDeep => colors.backgroundDeep;
  Color get backgroundWarm => colors.background;
  List<Color> get screenGradientColors => colors.screenGradientColors;
  Color get surface => colors.surface;
  Color get inputSurface => colors.surfaceRaised;
  Color get surfaceRaised => colors.surfaceRaised;
  Color get surfaceHigh => colors.surfaceHigh;
  Color get surfaceWarm => colors.surfaceWarm;
  Color get surfaceTeal => colors.surfaceTeal;
  Color get textPrimary => colors.textPrimary;
  Color get textSecondary => colors.textSecondary;
  Color get textMuted => colors.textMuted;
  Color get textDisabled => colors.textDisabled;
  Color get border => colors.border;
  Color get borderSoft => colors.borderSoft;
  Color get borderPrimary => colors.borderPrimary;
  Color get borderSecondary => colors.borderSecondary;
  Color get success => colors.success;
  Color get warning => colors.warning;
  Color get danger => colors.danger;
  Color get transparent => colors.transparent;
  Color get black => colors.black;
  Color get white => colors.white;
  Color get scrim => colors.scrim;

  Color get amberMuted03 => colors.primarySoft;
  Color get amberSoft24 => colors.warning;
  Color get blueMuted24 => colors.secondary;
  Color get neutralOverlayInk01 => colors.black.withValues(alpha: 0.08);
  Color get orangeLight02 => colors.textSecondary;
  Color get orangeLight13 => colors.primary;
  Color get orangeLight29 => colors.primary;
  Color get orangeLight37 => colors.primary;
  Color get orangeSoft11 => colors.textMuted;
  Color get orangeWash01 => colors.textPrimary;
  Color get orangeWash05 => colors.textPrimary;
  Color get orangeWash23 => colors.primary;
  Color get outlineOverlayLight => colors.border;
  Color get redLight06 => colors.danger;
  Color get redSoft10 => colors.danger;
  Color get redSoft11 => colors.danger;
  Color get surfaceCoolLight => colors.surfaceHigh;
  Color get textCaption => colors.textMuted;
  Color get textCoolSecondary => colors.textSecondary;
  Color get textOnInverse => colors.backgroundDeep;
  Color get warmInk104 => colors.surfaceRaised;
  Color get warmInk30 => colors.backgroundDeep;
  Color get warmInk48 => colors.backgroundDeep;
  Color get warmInk54 => colors.backgroundDeep;
  Color get warmMuted19 => colors.textMuted;
  Color get warmOverlayInk04 => colors.surface;
  Color get warmSurface18 => colors.surface;
  Color get warmSurface19 => colors.surfaceWarm;
  Color get warmSurface37 => colors.surface;
  Color get warmSurface47 => colors.surfaceRaised;
  Color get warmSurface48 => colors.surfaceRaised;
  Color get warmSurface55 => colors.surfaceWarm;
  Color get warmSurface69 => colors.surfaceWarm;
  Color get warmSurface81 => colors.surfaceWarm;
  Color get warmSurface96 => colors.surfaceHigh;
  Color get warmSurfaceHigh15 => colors.surfaceHigh;
}

Color _createActivityInputBorderColor(
  BuildContext context, {
  required bool hasFocus,
  required bool hasError,
}) {
  final colors = _CreateActivityColors.of(context);
  if (hasError) {
    return colors.danger;
  }
  if (hasFocus) {
    return colors.primary;
  }
  return colors.border;
}

double _createActivityInputBorderWidth({
  required bool hasFocus,
  required bool hasError,
}) {
  if (hasError) {
    return 1.6;
  }
  if (hasFocus) {
    return 1.3;
  }
  return 1;
}

BoxDecoration _createActivityInputDecoration(
  BuildContext context, {
  required BorderRadiusGeometry borderRadius,
  required bool hasFocus,
  required bool hasError,
}) {
  return AppBoxDecoration(
    color: context.createActivityColors.inputSurface,
    borderRadius: borderRadius,
    border: Border.all(
      color: _createActivityInputBorderColor(
        context,
        hasFocus: hasFocus,
        hasError: hasError,
      ),
      width: _createActivityInputBorderWidth(
        hasFocus: hasFocus,
        hasError: hasError,
      ),
    ),
  );
}

extension _CreateActivityColorContext on BuildContext {
  _CreateActivityColors get createActivityColors =>
      _CreateActivityColors.of(this);
}

final _activityPasswordInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[\x20-\x7E]'),
);
final _activityPasswordFormatters = <TextInputFormatter>[
  _activityPasswordInputFormatter,
];
final _activityPasswordAsciiPattern = RegExp(r'^[\x20-\x7E]+$');

bool _isActivityPasswordAscii(String value) {
  return _activityPasswordAsciiPattern.hasMatch(value);
}

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({
    super.key,
    this.activity,
    this.repeatFromActivity = false,
  });

  final ActivityListItemVm? activity;
  final bool repeatFromActivity;

  bool get hasInitialActivity => activity != null;

  bool get isRepeatMode => repeatFromActivity && activity != null;

  bool get isEditMode => activity != null && !repeatFromActivity;

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _pageController = PageController();
  final _imagePicker = ImagePicker();
  final _fileApi = FileApi();
  final _referenceApi = ReferenceApi();
  late final AppLocationLabelResolver _locationLabelResolver =
      AppLocationLabelResolver(api: _referenceApi);
  final _mapLinkResolver = const AppMapLinkResolver();
  final _deviceContextService = const DeviceContextService();
  int _currentStep = 0;
  int? _pendingProgrammaticStep;
  final Set<int> _nativeMapActivatedSteps = <int>{};
  static const _totalSteps = 3;
  static const double _stepBackSwipeMinDistance = 56;
  static const double _stepBackSwipeMinVelocity = 700;
  static const int _maxCoverUploadBytes = 20 * 1024 * 1024;
  static const int _lateMonthCarryoverDays = 3;
  static const int _minActivityParticipants = 2;
  static const int _maxLimitedParticipants = 100;

  // — Step 1: Basic —
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  String? _selectedCategorySlug;
  String? _selectedSubcategorySlug;
  String? _initialCategorySlug;
  String? _initialSubcategorySlug;
  Uint8List? _coverPreviewBytes;
  String? _coverFileId;
  bool _coverChanged = false;
  bool _isCoverUploading = false;
  String? _coverUploadErrorMessage;

  // — Step 2: Format & Schedule —
  String _format = 'OFFLINE';
  DateTime _startAt = DateTime.now();
  DateTime _endAt = DateTime.now();
  final _startAtCtrl = TextEditingController();
  final _endAtCtrl = TextEditingController();
  String _languageCode = 'ru';
  bool _didSetInitialLanguage = false;
  String _timezone = 'Asia/Almaty';

  // — Step 3: Participation —
  String _capacityType = 'UNLIMITED';
  int _minParticipants = _minActivityParticipants;
  int _maxParticipants = 15;
  bool _allowsParticipantInvites = false;
  String _visibility = 'PUBLIC';
  bool _visibilityPasswordChanged = false;
  String _priceType = 'FREE';
  String _selectedCurrencyCode = 'KZT';
  bool _didOverrideCurrency = false;
  final _visibilityPasswordCtrl = TextEditingController();
  final _priceAmountCtrl = TextEditingController();
  final _minParticipantsCtrl = TextEditingController(
    text: '$_minActivityParticipants',
  );
  final _maxParticipantsCtrl = TextEditingController(text: '15');

  // — Meeting point / location —
  final _countryCodeCtrl = TextEditingController(text: 'KZ');
  final _cityNameCtrl = TextEditingController();
  String? _selectedCityId;
  final _addressTextCtrl = TextEditingController();
  final _mapUrlCtrl = TextEditingController();
  final _meetingUrlCtrl = TextEditingController();
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedMapUrl;
  Timer? _mapUrlParseDebounce;
  int _mapUrlResolveSerial = 0;
  int _mapSelectionRequestSerial = 0;
  String? _mapUrlResolvingRawValue;
  String? _mapUrlResolveFailedRawValue;
  String? _authorLocationCountryCode;
  String? _authorLocationCityId;
  String? _authorLocationCityName;
  bool _isResolvingMapSelection = false;
  bool _isApplyingMapUrlProgrammatically = false;
  bool _didApplyAuthorLocationSnapshot = false;

  static const LatLng _fallbackMapTarget = LatLng(43.238949, 76.889709);
  static const _dateTimeInputFormatter = _DateTimeInputFormatter();

  bool _isSubmitting = false;
  bool _isTrackingStepBackSwipe = false;
  double _stepBackSwipeDistance = 0;

  String? _titleErrorText;
  String? _descriptionErrorText;
  String? _categoryErrorText;
  String? _addressErrorText;
  String? _mapUrlErrorText;
  String? _meetingUrlErrorText;
  String? _startAtErrorText;
  String? _endAtErrorText;
  String? _visibilityPasswordErrorText;
  String? _priceAmountErrorText;
  String? _minParticipantsErrorText;
  String? _maxParticipantsErrorText;

  // Track whether the user changed date/time fields in edit mode.
  bool _startAtChanged = false;
  bool _endAtChanged = false;

  bool get _isPublished {
    final status = widget.activity?.status.toUpperCase() ?? '';
    return status == 'ENROLLMENT_OPEN' ||
        status == 'FULL' ||
        status == 'PUBLISHED' ||
        status == 'STARTED';
  }

  bool get _isCancelledActivity =>
      widget.activity?.status.toUpperCase() == 'CANCELLED';

  bool get _shouldRepublishCancelledActivity =>
      widget.isEditMode && _isCancelledActivity;

  DateTime get _meetingAddressEditStartAt => widget.activity == null
      ? _startAt
      : eventDateTime(widget.activity!.startAt, widget.activity!.timezone);

  bool get _canEditMeetingAddress {
    if (!widget.isEditMode) {
      return true;
    }
    return ActivityEditPolicy.canEditMeetingAddress(
      startAt: _meetingAddressEditStartAt,
      now: DateTime.now(),
    );
  }

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _initialCategorySlug = _normalizeCategorySlug(a?.categorySlug);
    _selectedCategorySlug = _initialCategorySlug;
    _initialSubcategorySlug = _normalizeCategorySlug(a?.subcategorySlug);
    _selectedSubcategorySlug = _initialSubcategorySlug;
    if (a == null) {
      _startAt = _defaultStartAt();
      _endAt = _defaultEndAt(_startAt);
    } else {
      _applyInitialActivity(a);
    }
    _minParticipantsCtrl.text = '$_minParticipants';
    _maxParticipantsCtrl.text = '$_maxParticipants';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<ActivityProvider>();
      if (provider.categoryState == ActivitiesState.initial ||
          (provider.categoryState == ActivitiesState.error &&
              provider.categoryItems.isEmpty)) {
        provider.loadActivityCategories();
      }
      await _prefillAuthorLocationFromHomeLocation();
      if (!mounted) return;
      await _prefillPricingContext();
    });

    _cityNameCtrl.addListener(_handleLocationPreviewChanged);
    _addressTextCtrl.addListener(_handleLocationPreviewChanged);
    _mapUrlCtrl.addListener(_handleMapUrlTextChanged);
  }

  void _applyInitialActivity(ActivityListItemVm a) {
    _titleCtrl.text = a.title;
    _descriptionCtrl.text = a.description;
    _tagsCtrl.text = a.tags.join(', ');
    _coverFileId = a.coverFileId;
    _format = a.format.toUpperCase();
    _timezone = a.timezone;
    if (widget.isRepeatMode) {
      _startAt = _defaultStartAt();
      _endAt = _defaultEndAt(_startAt);
    } else {
      _applyExistingSchedule(a);
    }
    _languageCode = a.languageCode;
    _capacityType = a.capacityType.toUpperCase();
    _allowsParticipantInvites = a.allowsParticipantInvites;
    if (a.minParticipants != null) {
      _minParticipants = a.minParticipants! < _minActivityParticipants
          ? _minActivityParticipants
          : a.minParticipants!;
    }
    if (a.maxParticipants != null) {
      _maxParticipants = a.maxParticipants!;
    }
    _visibility = a.visibility.toUpperCase();
    _priceType = _normalizePriceType(a.priceType);
    if (a.priceAmount != null) {
      _priceAmountCtrl.text = a.priceAmount! % 1 == 0
          ? a.priceAmount!.toStringAsFixed(0)
          : a.priceAmount!.toStringAsFixed(2);
    }
    if (a.currency != null && a.currency!.trim().isNotEmpty) {
      _selectedCurrencyCode = normalizeAppCurrencyCodeOrDefault(
        a.currency,
        fallback: 'KZT',
      );
      _didOverrideCurrency = true;
    }
    if (a.countryCode != null && a.countryCode!.trim().isNotEmpty) {
      _countryCodeCtrl.text = a.countryCode!;
    }
    if (a.cityName != null && a.cityName!.trim().isNotEmpty) {
      _cityNameCtrl.text = a.cityName!;
    }
    if (a.cityId != null && a.cityId!.trim().isNotEmpty) {
      _selectedCityId = a.cityId!.trim();
    }
    if (a.addressText != null && a.addressText!.trim().isNotEmpty) {
      _addressTextCtrl.text = a.addressText!;
    }
    if (a.meetingUrl != null && a.meetingUrl!.trim().isNotEmpty) {
      _meetingUrlCtrl.text = a.meetingUrl!;
    }
    _selectedLatitude = a.latitude;
    _selectedLongitude = a.longitude;
    if (a.mapUrl != null && a.mapUrl!.trim().isNotEmpty) {
      _selectedMapUrl = a.mapUrl!;
      _setMapUrlText(a.mapUrl!);
    }
    _syncScheduleControllers();
  }

  void _applyExistingSchedule(ActivityListItemVm activity) {
    _startAt = eventDateTime(activity.startAt, activity.timezone);
    _endAt = eventDateTime(activity.endAt, activity.timezone);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSetInitialLanguage || widget.hasInitialActivity) {
      return;
    }
    final localeCode = Localizations.localeOf(context).languageCode;
    if (localeCode == 'ru' || localeCode == 'en' || localeCode == 'kk') {
      _languageCode = localeCode;
    }
    _didSetInitialLanguage = true;
  }

  @override
  void dispose() {
    _cityNameCtrl.removeListener(_handleLocationPreviewChanged);
    _addressTextCtrl.removeListener(_handleLocationPreviewChanged);
    _mapUrlCtrl.removeListener(_handleMapUrlTextChanged);
    _mapUrlParseDebounce?.cancel();
    _mapUrlResolveSerial += 1;
    _mapSelectionRequestSerial += 1;
    _pageController.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _tagsCtrl.dispose();
    _startAtCtrl.dispose();
    _endAtCtrl.dispose();
    _visibilityPasswordCtrl.dispose();
    _priceAmountCtrl.dispose();
    _minParticipantsCtrl.dispose();
    _maxParticipantsCtrl.dispose();
    _countryCodeCtrl.dispose();
    _cityNameCtrl.dispose();
    _addressTextCtrl.dispose();
    _mapUrlCtrl.dispose();
    _meetingUrlCtrl.dispose();
    super.dispose();
  }

  void _handleLocationPreviewChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _setMapUrlText(String value) {
    _isApplyingMapUrlProgrammatically = true;
    _mapUrlCtrl.text = value;
    _isApplyingMapUrlProgrammatically = false;
  }

  void _handleMapUrlTextChanged() {
    if (_isApplyingMapUrlProgrammatically ||
        _format == 'ONLINE' ||
        !_canEditMeetingAddress) {
      return;
    }
    _mapUrlParseDebounce?.cancel();
    final rawInput = _mapUrlCtrl.text.trim();
    final rawValue = AppMapLinks.normalizePastedMapLink(rawInput);
    if (rawValue.isEmpty) {
      _mapUrlResolveSerial += 1;
      if (_mapUrlErrorText != null) {
        setState(() {
          _mapUrlResolvingRawValue = null;
          _mapUrlResolveFailedRawValue = null;
          _mapUrlErrorText = null;
        });
      } else {
        _mapUrlResolvingRawValue = null;
        _mapUrlResolveFailedRawValue = null;
      }
      return;
    }
    if (rawInput != rawValue) {
      _setMapUrlText(rawValue);
    }
    _mapUrlParseDebounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_applyParsedMapUrl(rawValue, normalizeField: true)),
    );
  }

  Future<bool> _applyParsedMapUrl(
    String rawValue, {
    required bool normalizeField,
  }) async {
    if (!mounted) {
      return false;
    }
    final normalizedRawValue = AppMapLinks.normalizePastedMapLink(rawValue);
    if (normalizeField && _mapUrlCtrl.text.trim() != normalizedRawValue) {
      _setMapUrlText(normalizedRawValue);
    }
    final requestSerial = ++_mapUrlResolveSerial;
    final l10n = AppLocalizations.of(context)!;
    var point = AppMapLinks.tryParseCoordinates(normalizedRawValue);
    final shouldResolveRemote =
        point == null &&
        AppMapLinkResolver.canResolveRemoteMapLink(normalizedRawValue);
    if (shouldResolveRemote) {
      setState(() {
        _mapUrlResolvingRawValue = normalizedRawValue;
        _mapUrlResolveFailedRawValue = null;
        _mapUrlErrorText = l10n.createMapLinkResolvingError;
      });
    }
    point ??= await _mapLinkResolver.resolveCoordinates(normalizedRawValue);
    if (!mounted || requestSerial != _mapUrlResolveSerial) {
      return false;
    }
    if (normalizeField && _mapUrlCtrl.text.trim() != normalizedRawValue) {
      return false;
    }
    if (point == null) {
      setState(() {
        _mapUrlResolvingRawValue = null;
        _mapUrlResolveFailedRawValue = normalizedRawValue;
        _mapUrlErrorText = l10n.createMapLinkInvalidError;
      });
      return false;
    }
    final resolvedPoint = point;

    final normalizedUrl = _buildMapUrl(
      resolvedPoint.latitude,
      resolvedPoint.longitude,
    );
    final mapSelectionRequestSerial = ++_mapSelectionRequestSerial;
    if (normalizeField && _mapUrlCtrl.text.trim() != normalizedUrl) {
      _setMapUrlText(normalizedUrl);
    }
    setState(() {
      _selectedLatitude = resolvedPoint.latitude;
      _selectedLongitude = resolvedPoint.longitude;
      _selectedMapUrl = normalizedUrl;
      _mapUrlResolvingRawValue = null;
      _mapUrlResolveFailedRawValue = null;
      _mapUrlErrorText = null;
      _addressErrorText = null;
      _isResolvingMapSelection = true;
    });
    await _applyParsedMapPointAddress(
      position: resolvedPoint,
      mapUrlRequestSerial: requestSerial,
      mapSelectionRequestSerial: mapSelectionRequestSerial,
      syncMapUrlAfterAddress: normalizeField,
    );
    return true;
  }

  String? _validateMapUrlField(AppLocalizations l10n, {bool required = false}) {
    if (_format == 'ONLINE' || !_canEditMeetingAddress) {
      return null;
    }
    final rawValue = _mapUrlCtrl.text.trim();
    if (rawValue.isEmpty) {
      return required ? l10n.createMapLinkRequiredError : null;
    }
    final point = AppMapLinks.tryParseCoordinates(rawValue);
    if (point == null) {
      if (AppMapLinkResolver.canResolveRemoteMapLink(rawValue)) {
        if (_mapUrlResolveFailedRawValue == rawValue) {
          return l10n.createMapLinkInvalidError;
        }
        if (_mapUrlResolvingRawValue != rawValue) {
          unawaited(_applyParsedMapUrl(rawValue, normalizeField: true));
        }
        return l10n.createMapLinkResolvingError;
      }
      return l10n.createMapLinkInvalidError;
    }

    final normalizedUrl = _buildMapUrl(point.latitude, point.longitude);
    _selectedLatitude = point.latitude;
    _selectedLongitude = point.longitude;
    _selectedMapUrl = normalizedUrl;
    _mapUrlResolvingRawValue = null;
    _mapUrlResolveFailedRawValue = null;
    if (rawValue != normalizedUrl) {
      _setMapUrlText(normalizedUrl);
    }
    return null;
  }

  Future<void> _prefillAuthorLocationFromHomeLocation() async {
    if (widget.isEditMode) {
      return;
    }

    final provider = context.read<HomeLocationProvider>();
    if (!provider.isLoaded && !provider.isLoading) {
      try {
        await provider.load(
          languageCode: Localizations.localeOf(context).languageCode,
        );
      } catch (_) {
        // Keep the form usable if cached location loading fails.
      }
    }
    if (!mounted) return;

    final location = provider.effectiveLocation;
    if (location.source == HomeLocationSource.fallback) {
      return;
    }

    final countryCode = normalizeAppCountryCode(location.countryCode);
    final cityId = _normalizeOptionalLocationId(location.cityId);
    final cityName = location.cityName?.trim() ?? '';
    if (countryCode == null && cityId == null && cityName.isEmpty) {
      return;
    }

    setState(() {
      _authorLocationCountryCode = countryCode;
      _authorLocationCityId = cityId;
      _authorLocationCityName = cityName.isEmpty ? null : cityName;
      _didApplyAuthorLocationSnapshot = true;

      final currentCountryText = _countryCodeCtrl.text.trim().toUpperCase();
      final canPrefillMeetingLocation =
          !widget.hasInitialActivity &&
          (currentCountryText.isEmpty || currentCountryText == 'KZ');
      final hasUserSelectedMeetingLocation =
          _cityNameCtrl.text.trim().isNotEmpty ||
          (_selectedCityId ?? '').trim().isNotEmpty ||
          _addressTextCtrl.text.trim().isNotEmpty ||
          _hasSelectedMapPoint ||
          _mapUrlCtrl.text.trim().isNotEmpty;

      if (canPrefillMeetingLocation && !hasUserSelectedMeetingLocation) {
        final ccy = _selectedCurrencyCode;
        _applyCountryAndCurrency(location.countryCode, fallbackCurrency: ccy);
        _selectedCityId = location.cityId;
        if (_selectedCityId?.trim().isEmpty == true) {
          _selectedCityId = null;
        }
        if (cityName.isNotEmpty) {
          _cityNameCtrl.text = location.cityName ?? '';
        }
      }
    });
  }

  Future<void> _prefillPricingContext() async {
    final profile = context.read<SessionProvider>().profile;
    final profileCurrencyCode = normalizeAppCurrencyCode(profile?.currency);
    final currentCountryCode = normalizeAppCountryCode(_countryCodeCtrl.text);
    final currentCurrencyCode = normalizeAppCurrencyCode(_selectedCurrencyCode);
    final initialCountryCode = currentCountryCode;
    final initialCurrencyCode = widget.hasInitialActivity
        ? (currentCurrencyCode ??
              _currencyForCountryCode(initialCountryCode) ??
              profileCurrencyCode)
        : (profileCurrencyCode ??
              _currencyForCountryCode(initialCountryCode) ??
              currentCurrencyCode);

    if (mounted) {
      setState(() {
        _applyCountryAndCurrency(
          initialCountryCode,
          fallbackCurrency: initialCurrencyCode,
        );
      });
    }

    if (widget.hasInitialActivity || _didApplyAuthorLocationSnapshot) {
      return;
    }

    try {
      final suggestion = await _deviceContextService.detectLocationSuggestion();
      if (!mounted || suggestion == null) return;

      final detectedCountryCode = normalizeAppCountryCode(
        suggestion.countryCode,
      );
      if (detectedCountryCode == null) return;

      setState(() {
        _applyCountryAndCurrency(
          detectedCountryCode,
          fallbackCurrency:
              profileCurrencyCode ??
              normalizeAppCurrencyCode(_selectedCurrencyCode),
        );
      });
    } catch (_) {
      // Keep the current/default pricing context when device location is unavailable.
    }
  }

  void _applyCountryAndCurrency(
    String? countryCode, {
    String? fallbackCurrency,
  }) {
    final normalizedCountryCode = normalizeAppCountryCode(countryCode);
    if (normalizedCountryCode != null) {
      _countryCodeCtrl.text = normalizedCountryCode;
    }

    final resolvedCurrencyCode =
        normalizeAppCurrencyCode(fallbackCurrency) ??
        _currencyForCountryCode(normalizedCountryCode);
    if (resolvedCurrencyCode != null && !_didOverrideCurrency) {
      _selectedCurrencyCode = resolvedCurrencyCode;
    }
  }

  void _setSelectedCurrencyCode(String value) {
    final normalized = normalizeAppCurrencyCodeOrDefault(value);
    setState(() {
      _selectedCurrencyCode = normalized;
      _didOverrideCurrency = true;
      _priceAmountErrorText = null;
    });
  }

  String? _currencyForCountryCode(String? countryCode) {
    return appCurrencyForCountryCode(countryCode);
  }

  bool get _hasExistingCoverImage {
    final existingUrl = widget.activity == null
        ? ''
        : (resolveActivityCoverUrl(widget.activity!) ?? '').trim();
    return !_coverChanged && existingUrl.isNotEmpty;
  }

  bool get _hasAnyCoverPreview {
    return (_coverPreviewBytes?.isNotEmpty ?? false) || _hasExistingCoverImage;
  }

  Future<void> _pickCoverImage() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isCoverUploading) return;

    FocusScope.of(context).unfocus();

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 92,
    );
    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    if (bytes.isEmpty) {
      _showValidationError(l10n.createCoverUploadFailed);
      return;
    }
    if (bytes.lengthInBytes > _maxCoverUploadBytes) {
      _showValidationError(l10n.createCoverUploadTooLarge);
      return;
    }

    final contentType = _detectCoverMimeType(bytes);
    if (contentType == null) {
      _showValidationError(l10n.createCoverUploadUnsupportedFormat);
      return;
    }

    final normalizedName = _normalizeCoverFileName(picked.name, contentType);

    setState(() {
      _coverChanged = true;
      _coverPreviewBytes = bytes;
      _coverFileId = null;
      _coverUploadErrorMessage = null;
      _isCoverUploading = true;
    });

    try {
      final upload = await _fileApi.createActivityMediaUpload(
        originalName: normalizedName,
        contentType: contentType,
        sizeBytes: bytes.lengthInBytes,
      );

      await _fileApi.uploadBinary(
        upload: upload,
        bytes: bytes,
        contentType: contentType,
      );
      await _fileApi.completeUpload(upload.fileId);

      if (!mounted) return;
      setState(() {
        _coverFileId = upload.fileId;
        _coverUploadErrorMessage = null;
        _isCoverUploading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _coverUploadErrorMessage = DioErrorMapper.toMessage(e);
        _isCoverUploading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _coverUploadErrorMessage = l10n.createCoverUploadFailed;
        _isCoverUploading = false;
      });
    }
  }

  String? _detectCoverMimeType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }

    return null;
  }

  String _normalizeCoverFileName(String rawName, String contentType) {
    final trimmed = rawName.trim();
    final dotIndex = trimmed.lastIndexOf('.');
    final baseName = dotIndex > 0 ? trimmed.substring(0, dotIndex) : trimmed;
    final safeBase = baseName.isEmpty ? 'activity-cover' : baseName;

    final extension = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };

    return '$safeBase.$extension';
  }

  void _setUnlimitedParticipants(bool value) {
    setState(() {
      _capacityType = value ? 'UNLIMITED' : 'LIMITED';
      _minParticipantsErrorText = null;
      _maxParticipantsErrorText = null;
      if (!value) {
        if (_minParticipants < _minActivityParticipants) {
          _minParticipants = _minActivityParticipants;
          _minParticipantsCtrl.text = '$_minActivityParticipants';
        }
        if (_maxParticipants < _minActivityParticipants) {
          _maxParticipants = 15;
          _maxParticipantsCtrl.text = '15';
        }
      }
    });
  }

  void _setAllowsParticipantInvites(bool value) {
    setState(() => _allowsParticipantInvites = value);
  }

  void _handleMinParticipantsChanged(String value) {
    final parsed = int.tryParse(value.trim());
    setState(() {
      _minParticipants = parsed ?? 0;
      _minParticipantsErrorText = null;
      _maxParticipantsErrorText = null;
    });
  }

  void _handleMaxParticipantsChanged(String value) {
    final parsed = int.tryParse(value.trim());
    setState(() {
      _maxParticipants = parsed ?? 0;
      _maxParticipantsErrorText = null;
      _minParticipantsErrorText = null;
    });
  }

  void _setVisibility(String value) {
    setState(() {
      _visibility = value;
      _visibilityPasswordErrorText = null;
      if (value != 'PRIVATE') {
        _visibilityPasswordCtrl.clear();
        _visibilityPasswordChanged = true;
      }
    });
  }

  void _handleVisibilityPasswordChanged(String _) {
    setState(() {
      _visibilityPasswordChanged = true;
      _visibilityPasswordErrorText = null;
    });
  }

  void _setPriceType(String value) {
    setState(() {
      _priceType = _normalizePriceType(value);
      _priceAmountErrorText = null;
    });
  }

  String _normalizePriceType(String value) {
    switch (value.trim().toUpperCase()) {
      case 'PAID':
      case 'DEPOSIT':
        return 'PAID';
      case 'FREE':
      default:
        return 'FREE';
    }
  }

  DateTime _defaultStartAt() {
    final now = DateTime.now();
    final normalized = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    return normalized.add(const Duration(hours: 2));
  }

  DateTime _defaultEndAt(DateTime startAt) =>
      startAt.add(const Duration(minutes: 30));

  DateTime _endOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day, 23, 59, 59, 999, 999);

  DateTime _endOfMonth(DateTime value) =>
      _endOfDay(DateTime(value.year, value.month + 1, 0));

  DateTime _addCalendarMonthClamped(DateTime value) {
    final nextMonth = DateTime(
      value.year,
      value.month + 1,
      1,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
    final lastDayOfNextMonth = DateTime(
      nextMonth.year,
      nextMonth.month + 1,
      0,
    ).day;
    final clampedDay = value.day > lastDayOfNextMonth
        ? lastDayOfNextMonth
        : value.day;
    return DateTime(
      nextMonth.year,
      nextMonth.month,
      clampedDay,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }

  bool _isNearMonthEnd(DateTime value) {
    final lastDay = DateTime(value.year, value.month + 1, 0).day;
    return value.day >= lastDay - (_lateMonthCarryoverDays - 1);
  }

  DateTime _maxAllowedStartAt(DateTime now) {
    final monthWindowLimit = _isNearMonthEnd(now)
        ? _endOfMonth(DateTime(now.year, now.month + 2, 0))
        : _endOfMonth(now);
    final monthAheadLimit = _endOfDay(_addCalendarMonthClamped(now));
    return monthWindowLimit.isBefore(monthAheadLimit)
        ? monthWindowLimit
        : monthAheadLimit;
  }

  DateTime _maxAllowedEndAt(DateTime startAt) =>
      _addCalendarMonthClamped(startAt);

  bool get _hasCustomEndScheduleInput => _endAtCtrl.text.trim().isNotEmpty;

  void _syncScheduleControllers() {
    _startAtCtrl.text = _formatDateTimeInput(_startAt);
    _endAtCtrl.text = _formatDateTimeInput(_endAt);
  }

  String _formatDateTimeInput(DateTime value) =>
      DateFormat('dd.MM.yyyy HH:mm').format(value);

  DateTime? _parseDateTimeInput(String value) {
    if (value.trim().length != 16) {
      return null;
    }
    try {
      return DateFormat('dd.MM.yyyy HH:mm').parseStrict(value.trim());
    } catch (_) {
      return null;
    }
  }

  bool _validateScheduleStep(AppLocalizations l10n) {
    final parsedStartAt = _parseDateTimeInput(_startAtCtrl.text.trim());
    final parsedEndAt = _parseDateTimeInput(_endAtCtrl.text.trim());

    String? startError;
    String? endError;

    if (parsedStartAt == null) {
      startError = l10n.createScheduleInputValidation;
    }
    if (parsedEndAt == null) {
      endError = l10n.createScheduleInputValidation;
    }

    if (parsedStartAt != null && parsedEndAt != null) {
      final nowUtc = DateTime.now().toUtc();
      final nowInEventTimezone = eventDateTime(nowUtc, _timezone);
      final parsedStartAtUtc = eventWallClockToUtc(parsedStartAt, _timezone);
      final shouldValidateStartWindow = !widget.isEditMode || _startAtChanged;
      if (shouldValidateStartWindow &&
          !parsedStartAtUtc.isAfter(nowUtc.add(const Duration(hours: 1)))) {
        startError = l10n.createStartAtTooSoonValidation;
      }

      if (startError == null && shouldValidateStartWindow) {
        final maxStartAt = _maxAllowedStartAt(nowInEventTimezone);
        if (parsedStartAt.isAfter(maxStartAt)) {
          startError = l10n.createStartAtMonthLimitValidation(
            _formatDateTimeInput(maxStartAt),
          );
        }
      }

      if (startError == null && !parsedEndAt.isAfter(parsedStartAt)) {
        endError = l10n.createEndDateValidation;
      }

      final shouldValidateEndWindow =
          !widget.isEditMode || _startAtChanged || _endAtChanged;
      if (startError == null && endError == null && shouldValidateEndWindow) {
        final maxEndAt = _maxAllowedEndAt(parsedStartAt);
        if (parsedEndAt.isAfter(maxEndAt)) {
          endError = l10n.createEndAtMonthLimitValidation(
            _formatDateTimeInput(maxEndAt),
          );
        }
      }

      if (startError == null && endError == null) {
        final startChanged = parsedStartAt != _startAt;
        final endChanged = parsedEndAt != _endAt;
        _startAt = parsedStartAt;
        _endAt = parsedEndAt;
        _startAtChanged = _startAtChanged || startChanged;
        _endAtChanged = _endAtChanged || endChanged;
      }
    }

    setState(() {
      _startAtErrorText = startError;
      _endAtErrorText = endError;
    });

    return startError == null && endError == null;
  }

  void _handleStartAtChanged(String value) {
    final parsed = _parseDateTimeInput(value);
    setState(() {
      _startAtErrorText = null;
      _endAtErrorText = null;
      if (parsed != null) {
        _startAt = parsed;
        _startAtChanged = true;
        if (!_hasCustomEndScheduleInput) {
          _endAt = _defaultEndAt(_startAt);
        }
      }
    });
  }

  void _handleEndAtChanged(String value) {
    final parsed = _parseDateTimeInput(value);
    setState(() {
      _endAtErrorText = null;
      if (parsed != null) {
        _endAt = parsed;
        _endAtChanged = true;
      }
    });
  }

  void _goToStep(int step, {bool animate = true}) {
    if (step < 0 || step >= _totalSteps) return;
    if (_currentStep == step && _pendingProgrammaticStep == null) return;

    FocusManager.instance.primaryFocus?.unfocus();
    _pendingProgrammaticStep = step;
    setState(() => _currentStep = step);

    if (animate) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _pageController.jumpToPage(step);
    _pendingProgrammaticStep = null;
  }

  bool _isStepNativeMapEnabled(int step) {
    return _nativeMapActivatedSteps.contains(step) ||
        (_currentStep == step && _pendingProgrammaticStep == null);
  }

  void _handlePageChanged(int step) {
    final pendingStep = _pendingProgrammaticStep;
    if (pendingStep != null && step != pendingStep) {
      return;
    }

    if (_currentStep == step && _pendingProgrammaticStep == null) {
      return;
    }

    setState(() {
      _currentStep = step;
      if (_pendingProgrammaticStep == step) {
        _pendingProgrammaticStep = null;
      }
      if (step == 1) {
        _nativeMapActivatedSteps.add(step);
      }
    });
  }

  void _resetStepBackSwipe() {
    _isTrackingStepBackSwipe = false;
    _stepBackSwipeDistance = 0;
  }

  double _stepBackSwipeEdgeWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width <= 393 ? 68.0 : 76.0;
  }

  void _handleStepBackSwipeStart(DragStartDetails details) {
    if (_currentStep <= 0) {
      _resetStepBackSwipe();
      return;
    }

    final edgeWidth = _stepBackSwipeEdgeWidth(context);
    _isTrackingStepBackSwipe = details.localPosition.dx <= edgeWidth;
    _stepBackSwipeDistance = 0;
  }

  void _handleStepBackSwipeUpdate(DragUpdateDetails details) {
    if (!_isTrackingStepBackSwipe) return;

    final delta = details.primaryDelta ?? 0;
    if (delta < 0 && _stepBackSwipeDistance <= 0) {
      _resetStepBackSwipe();
      return;
    }

    _stepBackSwipeDistance += delta;
  }

  void _handleStepBackSwipeEnd(DragEndDetails details) {
    final primaryVelocity = details.primaryVelocity ?? 0;
    final shouldGoBack =
        _isTrackingStepBackSwipe &&
        _currentStep > 0 &&
        (_stepBackSwipeDistance >= _stepBackSwipeMinDistance ||
            primaryVelocity >= _stepBackSwipeMinVelocity);

    _resetStepBackSwipe();
    if (!shouldGoBack) return;

    FocusScope.of(context).unfocus();
    _goToStep(_currentStep - 1);
  }

  Future<void> _handleRouteBack() async {
    if (_currentStep > 0) {
      FocusScope.of(context).unfocus();
      _goToStep(_currentStep - 1, animate: false);
      return;
    }

    final canDiscard = await _confirmDiscardIfNeeded();
    if (!mounted || !canDiscard) {
      return;
    }

    context.pop();
  }

  void _handleRoutePopInvoked(bool didPop) {
    if (didPop) {
      return;
    }

    unawaited(_handleRouteBack());
  }

  bool get _hasUnsavedChanges {
    if (_isSubmitting) {
      return false;
    }

    final initialActivity = widget.activity;
    if (initialActivity != null && !widget.isRepeatMode) {
      return _hasChangedFromInitialActivity(initialActivity);
    }

    return _hasNewDraftInput;
  }

  bool _hasChangedFromInitialActivity(ActivityListItemVm activity) {
    return _normalizedText(_titleCtrl.text) !=
            _normalizedText(activity.title) ||
        _normalizedText(_descriptionCtrl.text) !=
            _normalizedText(activity.description) ||
        _normalizedText(_tagsCtrl.text) !=
            _normalizedText(activity.tags.join(', ')) ||
        _coverChanged ||
        _coverFileId != activity.coverFileId ||
        _format != activity.format.toUpperCase() ||
        _startAtChanged ||
        _endAtChanged ||
        _languageCode != activity.languageCode ||
        _timezone != activity.timezone ||
        _capacityType != activity.capacityType.toUpperCase() ||
        _minParticipants !=
            (activity.minParticipants ?? _minActivityParticipants) ||
        _maxParticipants != (activity.maxParticipants ?? 15) ||
        _allowsParticipantInvites != activity.allowsParticipantInvites ||
        _visibility != activity.visibility.toUpperCase() ||
        _visibilityPasswordChanged ||
        _priceType != _normalizePriceType(activity.priceType) ||
        _normalizedText(_priceAmountCtrl.text) !=
            _normalizedPriceAmount(activity.priceAmount) ||
        (_priceType != 'FREE' &&
            _selectedCurrencyCode !=
                normalizeAppCurrencyCodeOrDefault(
                  activity.currency,
                  fallback: 'KZT',
                )) ||
        _normalizedText(_countryCodeCtrl.text) !=
            _normalizedText(activity.countryCode ?? 'KZ') ||
        _normalizedText(_cityNameCtrl.text) !=
            _normalizedText(activity.cityName ?? '') ||
        (_selectedCityId ?? '') != (activity.cityId ?? '') ||
        _normalizedText(_addressTextCtrl.text) !=
            _normalizedText(activity.addressText ?? '') ||
        _normalizedText(_mapUrlCtrl.text) !=
            _normalizedText(activity.mapUrl ?? '') ||
        _normalizedText(_meetingUrlCtrl.text) !=
            _normalizedText(activity.meetingUrl ?? '');
  }

  bool get _hasNewDraftInput {
    return _currentStep > 0 ||
        _titleCtrl.text.trim().isNotEmpty ||
        _descriptionCtrl.text.trim().isNotEmpty ||
        _tagsCtrl.text.trim().isNotEmpty ||
        _selectedCategorySlug != null ||
        _selectedSubcategorySlug != null ||
        _coverChanged ||
        _coverFileId != null ||
        _format != 'OFFLINE' ||
        _capacityType != 'UNLIMITED' ||
        _minParticipants != _minActivityParticipants ||
        _maxParticipants != 15 ||
        _allowsParticipantInvites ||
        _visibility != 'PUBLIC' ||
        _visibilityPasswordCtrl.text.trim().isNotEmpty ||
        _priceType != 'FREE' ||
        _priceAmountCtrl.text.trim().isNotEmpty ||
        _addressTextCtrl.text.trim().isNotEmpty ||
        _mapUrlCtrl.text.trim().isNotEmpty ||
        _meetingUrlCtrl.text.trim().isNotEmpty ||
        _selectedLatitude != null ||
        _selectedLongitude != null;
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final l10n = AppLocalizations.of(context)!;
    return _showActivityAmberConfirmDialog(
      title: l10n.createActivityDiscardTitle,
      description: l10n.createActivityDiscardDescription,
      cancelLabel: l10n.cancelButton,
      confirmLabel: l10n.createActivityDiscardConfirm,
    );
  }

  Future<bool> _showActivityAmberConfirmDialog({
    required String title,
    required String description,
    required String cancelLabel,
    required String confirmLabel,
  }) async {
    final result = await showAppModalDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _ActivityAmberConfirmDialog(
          title: title,
          description: description,
          cancelLabel: cancelLabel,
          confirmLabel: confirmLabel,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );
    return result ?? false;
  }

  String _normalizedText(String value) => value.trim();

  String _normalizedPriceAmount(double? amount) {
    if (amount == null) {
      return '';
    }
    return amount % 1 == 0
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  bool _validateCurrentStep() {
    final l10n = AppLocalizations.of(context)!;

    switch (_currentStep) {
      case 0:
        final titleError = _titleCtrl.text.trim().length < 3
            ? l10n.createTitleValidation
            : null;
        final descriptionError = _descriptionCtrl.text.trim().length < 10
            ? l10n.createDescriptionValidation
            : null;
        final categoryError = (_selectedCategorySlug ?? '').trim().isEmpty
            ? l10n.createCategoryValidation
            : null;
        setState(() {
          _titleErrorText = titleError;
          _descriptionErrorText = descriptionError;
          _categoryErrorText = categoryError;
        });

        if (titleError != null ||
            descriptionError != null ||
            categoryError != null) {
          return false;
        }
        if (_isCoverUploading) {
          _showValidationError(l10n.createCoverUploadInProgress);
          return false;
        }
        if (_coverChanged && _coverFileId == null) {
          _showValidationError(l10n.createCoverUploadRetryRequired);
          return false;
        }
        return true;
      case 1:
        if (!_validateScheduleStep(l10n)) {
          return false;
        }
        final requiresMapLink =
            (_format == 'OFFLINE' || _format == 'HYBRID') &&
            _canEditMeetingAddress;
        final meetingUrlError =
            (_format == 'ONLINE' || _format == 'HYBRID') &&
                _meetingUrlCtrl.text.trim().isEmpty
            ? l10n.createMeetingUrlValidation
            : null;
        final mapUrlError = _validateMapUrlField(
          l10n,
          required: requiresMapLink,
        );
        setState(() {
          _meetingUrlErrorText = meetingUrlError;
          _addressErrorText = null;
          _mapUrlErrorText = mapUrlError;
        });

        if (meetingUrlError != null || mapUrlError != null) {
          return false;
        }
        return true;
      case 2:
        String? visibilityPasswordError;
        String? maxParticipantsError;
        String? minParticipantsError;
        String? priceAmountError;

        if (_shouldRequireVisibilityPassword) {
          final password = _visibilityPasswordValue ?? '';
          if (password.length < 4 || password.length > 64) {
            visibilityPasswordError = l10n.createVisibilityPasswordValidation;
          } else if (!_isActivityPasswordAscii(password)) {
            visibilityPasswordError =
                l10n.createVisibilityPasswordAsciiValidation;
          }
        }
        if (_capacityType == 'LIMITED') {
          if (_minParticipants < _minActivityParticipants) {
            minParticipantsError = l10n.createMinParticipantsValidation;
          }
          if (_maxParticipants < _minActivityParticipants ||
              _maxParticipants > _maxLimitedParticipants) {
            maxParticipantsError = l10n.createMaxParticipantsValidation;
          } else if (minParticipantsError == null &&
              _minParticipants > _maxParticipants) {
            minParticipantsError = l10n.createMinExceedsMaxValidation;
            maxParticipantsError = l10n.createMinExceedsMaxValidation;
          }
        }
        if (_priceType != 'FREE') {
          final amount = double.tryParse(_priceAmountCtrl.text.trim());
          if (amount == null || amount <= 0) {
            priceAmountError = l10n.createPriceValidation;
          }
        }
        setState(() {
          _visibilityPasswordErrorText = visibilityPasswordError;
          _minParticipantsErrorText = minParticipantsError;
          _maxParticipantsErrorText = maxParticipantsError;
          _priceAmountErrorText = priceAmountError;
        });

        return visibilityPasswordError == null &&
            minParticipantsError == null &&
            maxParticipantsError == null &&
            priceAmountError == null;
      default:
        return true;
    }
  }

  void _showValidationError(String message) {
    final l10n = AppLocalizations.of(context)!;
    showErrorDialog(context, title: l10n.error, message: message);
  }

  void _nextStep() {
    if (_pendingProgrammaticStep != null) return;
    if (!_validateCurrentStep()) return;

    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    } else {
      _submit();
    }
  }

  Future<void> _submitAndPublish() async {
    if (_isSubmitting) return;
    if (!_validateCurrentStep()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<ActivityProvider>();
    final request = _buildCreateRequest();
    final created = await provider.createActivity(request);

    if (!mounted) return;

    if (created != null) {
      setState(() => _isSubmitting = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.activityPublishSuccess)));
      context.read<ActivityProvider>().loadActivities();
      context.pushReplacement('/activities/${created.id}', extra: created);
    } else {
      setState(() => _isSubmitting = false);
      final l10n = AppLocalizations.of(context)!;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: provider.actionErrorMessage ?? l10n.createActivityFailed,
      );
    }
  }

  // ── Shared field extraction helpers ────────────────────────────

  String? _normalizeCategorySlug(String? value) {
    final normalized = normalizeActivityTaxonomySlug(value);
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  bool get _didCategoryChange =>
      _normalizeCategorySlug(_selectedCategorySlug) != _initialCategorySlug;

  bool get _didSubcategoryChange =>
      _normalizeCategorySlug(_selectedSubcategorySlug) !=
      _initialSubcategorySlug;

  bool get _startedPrivate =>
      widget.activity?.visibility.toUpperCase() == 'PRIVATE';

  List<String> get _parsedTags => _tagsCtrl.text
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  String? get _visibilityPasswordValue {
    final value = _visibilityPasswordCtrl.text.trim();
    return value.isEmpty ? null : value;
  }

  bool get _shouldShowVisibilityPasswordField => _visibility == 'PRIVATE';

  bool get _shouldRequireVisibilityPassword {
    if (_visibility != 'PRIVATE') {
      return false;
    }
    if (!widget.isEditMode) {
      return true;
    }
    if (!_startedPrivate) {
      return true;
    }
    return _visibilityPasswordChanged;
  }

  bool get _shouldSendVisibilityPasswordChange {
    if (_visibility != 'PRIVATE') {
      return _startedPrivate;
    }
    if (!widget.isEditMode) {
      return true;
    }
    if (!_startedPrivate) {
      return true;
    }
    return _visibilityPasswordChanged;
  }

  int? get _minParticipantsValue =>
      _capacityType == 'LIMITED' ? _minParticipants : null;

  int? get _maxParticipantsValue =>
      _capacityType == 'LIMITED' ? _maxParticipants : null;

  double? get _priceAmountValue => _priceType != 'FREE'
      ? double.tryParse(_priceAmountCtrl.text.trim())
      : null;

  String? get _currencyValue =>
      _priceType != 'FREE' ? _selectedCurrencyCode.trim().toUpperCase() : null;

  String? get _countryCodeValue =>
      _format != 'ONLINE' ? _countryCodeCtrl.text.trim().toUpperCase() : null;

  String? get _cityNameValue =>
      _format != 'ONLINE' ? _cityNameCtrl.text.trim() : null;

  String? get _cityIdValue => _format != 'ONLINE' ? _selectedCityId : null;

  String? get _addressTextValue =>
      _format != 'ONLINE' ? _addressTextCtrl.text.trim() : null;

  String? get _meetingUrlValue =>
      _format != 'OFFLINE' ? _meetingUrlCtrl.text.trim() : null;

  double? get _latitudeValue => _format != 'ONLINE' ? _selectedLatitude : null;

  double? get _longitudeValue =>
      _format != 'ONLINE' ? _selectedLongitude : null;

  String? get _mapUrlValue {
    if (_format == 'ONLINE') {
      return null;
    }
    final manualValue = _mapUrlCtrl.text.trim();
    if (manualValue.isNotEmpty) {
      return manualValue;
    }
    final trimmed = _selectedMapUrl?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    if (_selectedLatitude != null && _selectedLongitude != null) {
      return _buildMapUrl(_selectedLatitude!, _selectedLongitude!);
    }
    return null;
  }

  bool get _hasSelectedMapPoint =>
      _selectedLatitude != null && _selectedLongitude != null;

  bool get _meetingLocationDiffersFromAuthorLocation {
    return activityMeetingLocationDiffersFromAuthorLocation(
      format: _format,
      didApplyAuthorLocationSnapshot: _didApplyAuthorLocationSnapshot,
      authorCountryCode: _authorLocationCountryCode,
      authorCityId: _authorLocationCityId,
      authorCityName: _authorLocationCityName,
      meetingCountryCode: _countryCodeCtrl.text,
      meetingCityId: _selectedCityId,
      meetingCityName: _cityNameCtrl.text,
    );
  }

  String? _normalizeOptionalLocationId(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  LatLng get _selectedMapTarget => _hasSelectedMapPoint
      ? LatLng(_selectedLatitude!, _selectedLongitude!)
      : _fallbackMapTarget;

  // ── Submit ─────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_validateCurrentStep()) return;

    if (widget.isRepeatMode) {
      await _submitAndPublish();
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<ActivityProvider>();

    if (_shouldRepublishCancelledActivity) {
      await _submitUpdateAndPublish(provider);
    } else if (widget.isEditMode) {
      await _submitUpdate(provider);
    } else {
      await _submitCreate(provider);
    }
  }

  CreateActivityRequest _buildCreateRequest() {
    return CreateActivityRequest(
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      format: _format,
      visibility: _visibility,
      categorySlug: _selectedCategorySlug!,
      subcategorySlug: _selectedSubcategorySlug,
      tags: _parsedTags,
      languageCode: _languageCode,
      timezone: _timezone,
      startAt: _startAt,
      endAt: _endAt,
      capacityType: _capacityType,
      allowsParticipantInvites: _allowsParticipantInvites,
      minParticipants: _minParticipantsValue,
      maxParticipants: _maxParticipantsValue,
      priceType: _priceType,
      priceAmount: _priceAmountValue,
      currency: _currencyValue,
      countryCode: _countryCodeValue,
      cityId: _cityIdValue,
      cityName: _cityNameValue,
      addressText: _addressTextValue,
      latitude: _latitudeValue,
      longitude: _longitudeValue,
      mapUrl: _mapUrlValue,
      meetingUrl: _meetingUrlValue,
      authorCountryCode: _authorLocationCountryCode,
      authorCityId: _authorLocationCityId,
      authorCityName: _authorLocationCityName,
      visibilityPassword: _visibility == 'PRIVATE'
          ? _visibilityPasswordValue
          : null,
      coverFileId: _coverFileId,
    );
  }

  Future<void> _submitCreate(ActivityProvider provider) async {
    final request = _buildCreateRequest();

    final created = await provider.createActivity(request);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (created != null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.createActivitySuccess)));
      context.read<ActivityProvider>().loadActivities();
      context.pushReplacement('/activities/${created.id}', extra: created);
    } else {
      final l10n = AppLocalizations.of(context)!;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: provider.actionErrorMessage ?? l10n.createActivityFailed,
      );
    }
  }

  Future<void> _submitUpdate(ActivityProvider provider) async {
    final activityId = widget.activity!.id;

    final request = _buildUpdateRequest();

    final updated = await provider.updateActivity(activityId, request);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (updated != null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.editActivitySuccess)));
      context.read<ActivityProvider>().loadActivities();
      context.pop();
    } else {
      final l10n = AppLocalizations.of(context)!;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: provider.actionErrorMessage ?? l10n.editActivityFailed,
      );
    }
  }

  UpdateActivityRequest _buildUpdateRequest() {
    final canEditMeetingAddress = _canEditMeetingAddress;

    return UpdateActivityRequest(
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      visibility: _visibility,
      categorySlug: _didCategoryChange ? _selectedCategorySlug : null,
      subcategorySlug: _selectedSubcategorySlug,
      hasSubcategorySlug: _didCategoryChange || _didSubcategoryChange,
      tags: _parsedTags,
      languageCode: _languageCode,
      timezone: _timezone,
      startAt: _startAtChanged ? _startAt : null,
      endAt: _endAtChanged ? _endAt : null,
      capacityType: _capacityType,
      allowsParticipantInvites: _allowsParticipantInvites,
      minParticipants: _minParticipantsValue,
      hasMinParticipants: true,
      maxParticipants: _maxParticipantsValue,
      hasMaxParticipants: true,
      priceType: _priceType,
      priceAmount: _priceAmountValue,
      hasPriceAmount: true,
      currency: _currencyValue,
      hasCurrency: true,
      countryCode: canEditMeetingAddress ? _countryCodeValue : null,
      hasCountryCode: canEditMeetingAddress,
      cityId: canEditMeetingAddress ? _cityIdValue : null,
      hasCityId: canEditMeetingAddress,
      cityName: canEditMeetingAddress ? _cityNameValue : null,
      hasCityName: canEditMeetingAddress,
      addressText: canEditMeetingAddress ? _addressTextValue : null,
      hasAddressText: canEditMeetingAddress,
      latitude: canEditMeetingAddress ? _latitudeValue : null,
      hasLatitude: canEditMeetingAddress,
      longitude: canEditMeetingAddress ? _longitudeValue : null,
      hasLongitude: canEditMeetingAddress,
      mapUrl: canEditMeetingAddress ? _mapUrlValue : null,
      hasMapUrl: canEditMeetingAddress,
      meetingUrl: _meetingUrlValue,
      hasMeetingUrl: true,
      visibilityPassword: _shouldSendVisibilityPasswordChange
          ? (_visibility == 'PRIVATE' ? _visibilityPasswordValue : null)
          : null,
      hasVisibilityPassword: _shouldSendVisibilityPasswordChange,
      coverFileId: _coverChanged ? _coverFileId : null,
      hasCoverFileId: _coverChanged,
    );
  }

  Future<void> _submitUpdateAndPublish(ActivityProvider provider) async {
    final activityId = widget.activity!.id;
    final request = _buildUpdateRequest();
    final updated = await provider.updateActivity(activityId, request);

    if (!mounted) return;

    if (updated == null) {
      setState(() => _isSubmitting = false);
      final l10n = AppLocalizations.of(context)!;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: provider.actionErrorMessage ?? l10n.editActivityFailed,
      );
      return;
    }

    final published = await provider.publishActivity(activityId);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (published) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.activityPublishSuccess)));
      context.read<ActivityProvider>().loadActivities();
      context.read<ActivityProvider>().loadMyActivities();
      context.pushReplacement('/activities/$activityId');
    } else {
      final l10n = AppLocalizations.of(context)!;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: provider.actionErrorMessage ?? l10n.activityPublishFailed,
      );
    }
  }

  Future<void> _openCategoryPicker(
    AppLocalizations l10n,
    Map<String, String> items,
  ) async {
    final selected = await showAppModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      backgroundColor: context.createActivityColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CategoryPickerSheet(
          title: l10n.createCategoryPickerTitle,
          actionLabel: l10n.createCategoryApply,
          items: items,
          initialValue: _selectedCategorySlug,
          iconForSlug: _categoryIconForSlug,
        );
      },
    );

    if (!mounted || selected == null) return;
    setState(() {
      final nextCategorySlug = _normalizeCategorySlug(selected);
      if (nextCategorySlug != _selectedCategorySlug) {
        _selectedSubcategorySlug = null;
      }
      _selectedCategorySlug = nextCategorySlug;
      _categoryErrorText = null;
    });
  }

  Future<void> _openSubcategoryPicker(
    AppLocalizations l10n,
    Map<String, String> items,
  ) async {
    final selected = await showAppModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      backgroundColor: context.createActivityColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CategoryPickerSheet(
          title: l10n.createSubcategoryPickerTitle,
          actionLabel: l10n.createSubcategoryApply,
          items: items,
          initialValue: _selectedSubcategorySlug,
          iconForSlug: (_) => Icons.label_rounded,
        );
      },
    );

    if (!mounted || selected == null) return;
    setState(() {
      _selectedSubcategorySlug = _normalizeCategorySlug(selected);
    });
  }

  Future<void> _openVisibilityPicker(AppLocalizations l10n) async {
    final selected = await showAppModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      backgroundColor: context.createActivityColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CategoryPickerSheet(
          title: l10n.createVisibilityPickerTitle,
          actionLabel: l10n.createVisibilityApply,
          items: {
            'PUBLIC': l10n.createVisibilityPublic,
            'PRIVATE': l10n.createVisibilityPrivateWithPassword,
            'UNLISTED': l10n.createVisibilityByLink,
          },
          initialValue: _visibility,
          iconForSlug: _visibilityIconForValue,
        );
      },
    );

    if (!mounted || selected == null) return;
    _setVisibility(selected);
  }

  IconData _categoryIconForSlug(String slug) {
    switch (slug) {
      case 'food-drinks':
        return Icons.restaurant_rounded;
      case 'social-nightlife':
        return Icons.nightlife_rounded;
      case 'culture-art':
        return Icons.palette_rounded;
      case 'city-walks':
        return Icons.directions_walk_rounded;
      case 'nature-outdoor':
      case 'adventure-sports':
        return Icons.forest_rounded;
      case 'sports-wellness':
      case 'health-wellness':
        return Icons.self_improvement_rounded;
      case 'workshops-learning':
        return Icons.auto_stories_rounded;
      case 'games-entertainment':
        return Icons.sports_esports_rounded;
      case 'family-kids':
        return Icons.family_restroom_rounded;
      default:
        return Icons.local_activity_rounded;
    }
  }

  IconData _visibilityIconForValue(String value) {
    switch (value) {
      case 'PRIVATE':
        return Icons.lock_outline_rounded;
      case 'UNLISTED':
        return Icons.link_rounded;
      case 'PUBLIC':
      default:
        return Icons.public_rounded;
    }
  }

  String _buildMapUrl(double latitude, double longitude) {
    return AppMapLinks.buildUrl(
      latitude: latitude,
      longitude: longitude,
      title: _titleCtrl.text,
      subtitle: _addressTextCtrl.text,
    );
  }

  String _composeCityLabel(Placemark placemark) {
    final candidates = [
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
    ];

    for (final value in candidates) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return '';
  }

  String _composeAddressLabel(Placemark placemark) {
    final parts = <String>[];

    void addPart(String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty && !parts.contains(trimmed)) {
        parts.add(trimmed);
      }
    }

    addPart(placemark.street);
    addPart(placemark.thoroughfare);
    addPart(placemark.subLocality);
    if (parts.isEmpty) {
      addPart(placemark.name);
    }

    return parts.join(', ');
  }

  String _reverseGeocodingLocaleIdentifier() {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode.trim().isNotEmpty
        ? locale.languageCode.trim().toLowerCase()
        : 'en';
    final countryCode =
        normalizeAppCountryCode(_countryCodeCtrl.text) ??
        normalizeAppCountryCode(locale.countryCode) ??
        'US';

    return '${languageCode}_$countryCode';
  }

  Future<ReferenceCity?> _resolveReferenceCity({
    required String cityName,
    required String countryCode,
  }) async {
    final city = cityName.trim();
    final country = normalizeAppCountryCode(countryCode);
    if (city.isEmpty || country == null) {
      return null;
    }

    try {
      final locale = mounted
          ? Localizations.localeOf(context).languageCode
          : 'en';
      final matches = await _referenceApi.searchCities(
        city,
        countryCode: country,
        lang: locale,
        limit: 5,
      );
      if (matches.isEmpty) {
        return null;
      }
      final normalizedCity = city.toLowerCase();
      for (final item in matches) {
        if (item.countryCode.trim().toUpperCase() == country &&
            item.name.trim().toLowerCase() == normalizedCity) {
          return item;
        }
      }
      return matches.first;
    } catch (_) {
      return null;
    }
  }

  Future<void> _applyParsedMapPointAddress({
    required LatLng position,
    required int mapUrlRequestSerial,
    required int mapSelectionRequestSerial,
    required bool syncMapUrlAfterAddress,
  }) {
    return _resolveSelectedMapPointAddress(
      position: position,
      isCurrentRequest: () =>
          mapUrlRequestSerial == _mapUrlResolveSerial &&
          mapSelectionRequestSerial == _mapSelectionRequestSerial,
      syncMapUrlAfterAddress: syncMapUrlAfterAddress,
    );
  }

  Future<void> _resolveSelectedMapPointAddress({
    required LatLng position,
    required bool Function() isCurrentRequest,
    required bool syncMapUrlAfterAddress,
  }) async {
    try {
      await setLocaleIdentifier(_reverseGeocodingLocaleIdentifier());
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted || !isCurrentRequest()) return;

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final city = _composeCityLabel(placemark);
        final address = _composeAddressLabel(placemark);
        final isoCountryCode =
            normalizeAppCountryCode(placemark.isoCountryCode) ?? '';
        final referenceCity = await _resolveReferenceCity(
          cityName: city,
          countryCode: isoCountryCode,
        );
        if (!mounted || !isCurrentRequest()) return;

        final localizedCityName = referenceCity?.name.trim().isNotEmpty == true
            ? referenceCity!.name.trim()
            : city;
        final reverseGeocodedAddress = formatLocationAddressLabel(
          city: city,
          country: isoCountryCode,
          address: address,
        );
        final resolvedAddress = await _locationLabelResolver.resolveAddress(
          countryCode: isoCountryCode,
          cityId: referenceCity?.id,
          cityName: city,
          addressText: reverseGeocodedAddress,
          localeName: Localizations.localeOf(context).toString(),
        );
        if (!mounted || !isCurrentRequest()) return;

        setState(() {
          if (isoCountryCode.isNotEmpty) {
            _applyCountryAndCurrency(
              isoCountryCode,
              fallbackCurrency: _selectedCurrencyCode,
            );
          }
          if (localizedCityName.isNotEmpty) {
            _cityNameCtrl.text = localizedCityName;
            _selectedCityId = referenceCity?.id;
          }
          if (resolvedAddress.isNotEmpty) {
            _addressTextCtrl.text = resolvedAddress;
            if (syncMapUrlAfterAddress) {
              _selectedMapUrl = _buildMapUrl(
                position.latitude,
                position.longitude,
              );
              _setMapUrlText(_selectedMapUrl!);
            }
          }
          _addressErrorText = null;
          _isResolvingMapSelection = false;
        });
        return;
      }
    } catch (_) {
      // Keep the selected pin even if reverse geocoding fails.
    }

    if (!mounted || !isCurrentRequest()) return;
    setState(() => _isResolvingMapSelection = false);
  }

  Future<void> _handleMapTapped(LatLng position, {String? addressLabel}) async {
    if (!_canEditMeetingAddress) {
      return;
    }
    final requestSerial = ++_mapSelectionRequestSerial;
    final selectedAddressLabel = addressLabel?.trim();
    final displayAddressLabel = selectedAddressLabel?.isNotEmpty == true
        ? selectedAddressLabel!
        : null;
    final mapUrl = AppMapLinks.buildUrl(
      latitude: position.latitude,
      longitude: position.longitude,
      title: _titleCtrl.text,
      subtitle: displayAddressLabel ?? _addressTextCtrl.text,
    );

    setState(() {
      _selectedLatitude = position.latitude;
      _selectedLongitude = position.longitude;
      _selectedMapUrl = mapUrl;
      _setMapUrlText(mapUrl);
      if (displayAddressLabel != null) {
        _addressTextCtrl.text = displayAddressLabel;
      }
      _mapUrlResolvingRawValue = null;
      _mapUrlResolveFailedRawValue = null;
      _mapUrlErrorText = null;
      _addressErrorText = null;
      _isResolvingMapSelection = true;
    });

    await _resolveSelectedMapPointAddress(
      position: position,
      isCurrentRequest: () => requestSerial == _mapSelectionRequestSerial,
      syncMapUrlAfterAddress: true,
    );
  }

  Future<void> _openExpandedMeetingPointMap() async {
    if (!_canEditMeetingAddress) {
      return;
    }

    FocusScope.of(context).unfocus();

    final l10n = AppLocalizations.of(context)!;
    final title = _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : l10n.createMeetingPointLocationLabel;
    final subtitle = _addressTextCtrl.text.trim().isNotEmpty
        ? _addressTextCtrl.text.trim()
        : _cityNameCtrl.text.trim();
    final mapUrl = _mapUrlCtrl.text.trim();
    final initialTarget = _hasSelectedMapPoint
        ? MapTarget(
            title: title,
            subtitle: subtitle.isEmpty ? null : subtitle,
            latitude: _selectedLatitude!,
            longitude: _selectedLongitude!,
            sourceUrl: mapUrl.isEmpty ? null : mapUrl,
          )
        : null;

    final result = await context.push<MapTarget>(
      '/map?mode=meeting-point-picker',
      extra: initialTarget,
    );
    if (!mounted || result == null) {
      return;
    }

    await _handleMapTapped(result.point, addressLabel: result.subtitle);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stepBackSwipeEdgeWidth = _stepBackSwipeEdgeWidth(context);

    final stepTitles = [
      l10n.createStepDetailsLogistics,
      l10n.createStepParticipation,
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handleRoutePopInvoked(didPop),
      child: Scaffold(
        backgroundColor: context.createActivityColors.background,
        body: DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              colors: context.createActivityColors.screenGradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _CreateTopBar(
                  title: widget.isEditMode
                      ? l10n.editActivityTitle
                      : l10n.createActivityTitle,
                  onBack: _currentStep == 0
                      ? () => unawaited(_handleRouteBack())
                      : null,
                ),
                _StepIndicator(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  titles: stepTitles,
                  counterLabel: l10n.createStepCounter(
                    _currentStep + 1,
                    _totalSteps,
                  ),
                  compact: true,
                  onStepTap: (step) {
                    if (step < _currentStep) {
                      _goToStep(step, animate: false);
                    }
                  },
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: _handlePageChanged,
                          children: [
                            _buildStep1Basic(l10n),
                            _buildStep2Schedule(l10n),
                            _buildStep3Participation(l10n),
                          ],
                        ),
                      ),
                      if (_currentStep > 0)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: stepBackSwipeEdgeWidth,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onHorizontalDragStart: _handleStepBackSwipeStart,
                            onHorizontalDragUpdate: _handleStepBackSwipeUpdate,
                            onHorizontalDragEnd: _handleStepBackSwipeEnd,
                            onHorizontalDragCancel: _resetStepBackSwipe,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_currentStep == _totalSteps - 1)
                  _Step3ActionBar(
                    isSubmitting: _isSubmitting,
                    onPrimaryAction: widget.isRepeatMode
                        ? _submitAndPublish
                        : _shouldRepublishCancelledActivity
                        ? _submit
                        : widget.isEditMode
                        ? _submit
                        : _submitAndPublish,
                    primaryLabel: widget.isRepeatMode
                        ? l10n.activityPublishButton
                        : _shouldRepublishCancelledActivity
                        ? l10n.activityPublishButton
                        : widget.isEditMode
                        ? l10n.editActivitySubmit
                        : l10n.createPublishActivityCta,
                    showPrimaryIcon:
                        !widget.isEditMode ||
                        widget.isRepeatMode ||
                        _shouldRepublishCancelledActivity,
                  )
                else if (_currentStep == 1)
                  _Step2NavBar(
                    isSubmitting: _isSubmitting,
                    onNext: _nextStep,
                    nextLabel: l10n.createStepNext,
                  )
                else
                  _BottomNavBar(
                    isSubmitting: _isSubmitting,
                    onNext: _nextStep,
                    nextLabel: _currentStep == _totalSteps - 1
                        ? l10n.editActivitySubmit
                        : l10n.createStepNext,
                    heroStyle: _currentStep == 0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 1: Basic ──────────────────────────────────────────────

  Widget _buildStep1Basic(AppLocalizations l10n) {
    final media = MediaQuery.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final width = media.size.width;
    final isCompact = width <= 360;
    final isWide = width >= 394;
    final horizontalPadding = isCompact ? 16.0 : (isWide ? 24.0 : 20.0);
    final blockSpacing = isCompact ? 18.0 : 20.0;
    final descriptionHeight = isCompact ? 140.0 : 150.0;

    return ListView(
      padding: AppEdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        24 + media.viewInsets.bottom,
      ),
      children: [
        _Step1FieldSection(
          label: l10n.createCoverSection,
          child: _CoverUploadCard(
            title: _hasAnyCoverPreview
                ? l10n.createCoverChangeAction
                : l10n.createCoverUploadTitle,
            hint: _coverUploadErrorMessage ?? l10n.createCoverUploadHint,
            imageUrl: _hasExistingCoverImage
                ? resolveActivityCoverUrl(widget.activity!)
                : null,
            previewBytes: _coverPreviewBytes,
            isUploading: _isCoverUploading,
            hasError: _coverUploadErrorMessage != null,
            onTap: _pickCoverImage,
          ),
        ),
        SizedBox(height: blockSpacing),
        _Step1FieldSection(
          label: l10n.createTitleLabel,
          child: _Step1TextField(
            controller: _titleCtrl,
            hint: l10n.createTitleHint,
            maxLength: 200,
            errorText: _titleErrorText,
            onChanged: (_) {
              if (_titleErrorText == null) return;
              setState(() => _titleErrorText = null);
            },
          ),
        ),
        SizedBox(height: blockSpacing),
        _Step1FieldSection(
          label: l10n.createDescriptionLabel,
          child: _Step1TextField(
            controller: _descriptionCtrl,
            hint: l10n.createDescriptionHint,
            maxLines: 5,
            minHeight: descriptionHeight,
            isMultiline: true,
            errorText: _descriptionErrorText,
            onChanged: (_) {
              if (_descriptionErrorText == null) return;
              setState(() => _descriptionErrorText = null);
            },
          ),
        ),
        SizedBox(height: blockSpacing),
        _Step1FieldSection(
          label: l10n.createCategoryLabel,
          child: Consumer<ActivityProvider>(
            builder: (context, provider, _) {
              final items = _buildCategoryOptions(
                provider.categoryItems,
                languageCode,
              );

              if ((provider.categoryState == ActivitiesState.initial ||
                      provider.categoryState == ActivitiesState.loading) &&
                  items.isEmpty) {
                return _CategoryCatalogState(
                  message: l10n.createCategoryLoading,
                  trailing: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: context.createActivityColors.primary,
                    ),
                  ),
                );
              }

              if (provider.categoryState == ActivitiesState.error &&
                  items.isEmpty) {
                return _CategoryCatalogState(
                  message:
                      provider.categoryErrorMessage ??
                      l10n.createCategoryLoadFailed,
                  trailing: TextButton(
                    onPressed: () => context
                        .read<ActivityProvider>()
                        .loadActivityCategories(force: true),
                    child: Text(l10n.createCategoryRetry),
                  ),
                );
              }

              if (items.isEmpty) {
                return _CategoryCatalogState(message: l10n.createCategoryEmpty);
              }

              final selectedCategory = findActivityCategoryBySlug(
                categories: provider.categoryItems,
                slug: _selectedCategorySlug,
              );
              final selectedCategoryLabel = localizedActivityCategoryLabel(
                categories: provider.categoryItems,
                slug: _selectedCategorySlug,
                languageCode: languageCode,
              );
              final subcategoryItems = selectedCategory == null
                  ? const <String, String>{}
                  : _buildSubcategoryOptions(selectedCategory, languageCode);
              final selectedSubcategoryLabel =
                  subcategoryItems[_selectedSubcategorySlug];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategorySelectorField(
                    value: selectedCategoryLabel.isNotEmpty
                        ? selectedCategoryLabel
                        : l10n.createCategoryHint,
                    isPlaceholder: _selectedCategorySlug == null,
                    onTap: () => _openCategoryPicker(l10n, items),
                    errorText: _categoryErrorText,
                  ),
                  if (subcategoryItems.isNotEmpty) ...[
                    SizedBox(height: blockSpacing),
                    _Step1FieldSection(
                      label: l10n.createSubcategoryLabel,
                      child: _CategorySelectorField(
                        value:
                            selectedSubcategoryLabel ??
                            l10n.createSubcategoryHint,
                        isPlaceholder: _selectedSubcategorySlug == null,
                        onTap: () =>
                            _openSubcategoryPicker(l10n, subcategoryItems),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Map<String, String> _buildCategoryOptions(
    List<ActivityCategoryVm> categories,
    String languageCode,
  ) {
    final options = <String, String>{};
    final selectedSlug = _normalizeCategorySlug(_selectedCategorySlug);

    if (selectedSlug != null &&
        selectedSlug.isNotEmpty &&
        categories.every((item) => item.slug != selectedSlug)) {
      options[selectedSlug] = ActivityCategoryVm.humanizeSlug(selectedSlug);
    }

    for (final item in categories) {
      options[item.slug] = item.localizedName(languageCode);
    }

    return options;
  }

  Map<String, String> _buildSubcategoryOptions(
    ActivityCategoryVm category,
    String languageCode,
  ) {
    final options = <String, String>{};
    final selectedSlug = _normalizeCategorySlug(_selectedSubcategorySlug);

    if (selectedSlug != null &&
        selectedSlug.isNotEmpty &&
        category.subcategories.every((item) => item.slug != selectedSlug)) {
      options[selectedSlug] = ActivityCategoryVm.humanizeSlug(selectedSlug);
    }

    for (final item in category.subcategories) {
      options[item.slug] = item.localizedName(languageCode);
    }

    return options;
  }

  // ── Step 2: Schedule ───────────────────────────────────────────

  Widget _buildStep2Schedule(AppLocalizations l10n) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final horizontalPadding = width <= 393 ? 16.0 : 20.0;
    final formatLocked = widget.isEditMode;
    final showOffline = _format == 'OFFLINE' || _format == 'HYBRID';
    final showOnline = _format == 'ONLINE' || _format == 'HYBRID';
    final locationLocked = showOffline && !_canEditMeetingAddress;

    return ListView(
      padding: AppEdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        24 + media.viewInsets.bottom,
      ),
      children: [
        _Step2FieldSection(
          label: l10n.createEventFormatLabel,
          child: IgnorePointer(
            ignoring: formatLocked,
            child: Opacity(
              opacity: formatLocked ? 0.5 : 1,
              child: _Step2FormatSegmented(
                value: _format,
                items: {
                  'OFFLINE': l10n.activityFormatOffline,
                  'ONLINE': l10n.activityFormatOnline,
                  'HYBRID': l10n.activityFormatHybrid,
                },
                icons: const {
                  'OFFLINE': Icons.place_outlined,
                  'ONLINE': Icons.videocam_outlined,
                  'HYBRID': Icons.layers_outlined,
                },
                onChanged: (v) => setState(() {
                  _format = v;
                  _addressErrorText = null;
                  _mapUrlErrorText = null;
                  _meetingUrlErrorText = null;
                }),
              ),
            ),
          ),
        ),
        if (formatLocked) ...[
          const SizedBox(height: 6),
          Text(
            l10n.editFormatLocked,
            style: AppTextStyle(
              color: context.createActivityColors.textCaption,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 18),
        if (showOffline) ...[
          _Step2FieldSection(
            label: l10n.createMeetingPointLocationLabel,
            child: IgnorePointer(
              ignoring: locationLocked,
              child: Opacity(
                opacity: locationLocked ? 0.5 : 1,
                child: _Step2PillTextField(
                  controller: _addressTextCtrl,
                  hint: l10n.createVenueOrAddressHint,
                  icon: Icons.location_on_outlined,
                  readOnly: true,
                  errorText: _addressErrorText,
                  onChanged: (_) {
                    if (_addressErrorText == null) return;
                    setState(() => _addressErrorText = null);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _Step2FieldSection(
            label: l10n.createMapLinkLabel,
            child: IgnorePointer(
              ignoring: locationLocked,
              child: Opacity(
                opacity: locationLocked ? 0.5 : 1,
                child: _Step2PillTextField(
                  controller: _mapUrlCtrl,
                  hint: l10n.createMapLinkHint,
                  icon: Icons.link_rounded,
                  keyboardType: TextInputType.url,
                  errorText: _mapUrlErrorText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.createMapEarlyStageNotice,
            style: AppTextStyle(
              color: context.createActivityColors.orangeLight02,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          IgnorePointer(
            ignoring: locationLocked,
            child: Opacity(
              opacity: locationLocked ? 0.5 : 1,
              child: AppMapCard(
                target: _selectedMapTarget,
                hasMarker: _hasSelectedMapPoint,
                nativeMapEnabled: _isStepNativeMapEnabled(1),
                onTap: _handleMapTapped,
                overlay: _MapExpandButton(onTap: _openExpandedMeetingPointMap),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            locationLocked
                ? l10n.editLocationLocked
                : (_isResolvingMapSelection
                      ? l10n.createMapResolvingHint
                      : l10n.createMapTapHint),
            style: AppTextStyle(
              color: context.createActivityColors.orangeLight02,
              fontSize: 12,
            ),
          ),

          if (_meetingLocationDiffersFromAuthorLocation) ...[
            const SizedBox(height: 10),
            _Step2LocationMismatchNotice(
              message: l10n.createAuthorLocationMismatchHint,
            ),
          ],
          const SizedBox(height: 18),
        ],
        if (showOnline) ...[
          _Step2FieldSection(
            label: l10n.createMeetingUrlLabel,
            child: _Step2PillTextField(
              controller: _meetingUrlCtrl,
              hint: l10n.createMeetingUrlHint,
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              errorText: _meetingUrlErrorText,
              onChanged: (_) {
                if (_meetingUrlErrorText == null) return;
                setState(() => _meetingUrlErrorText = null);
              },
            ),
          ),
          const SizedBox(height: 18),
        ],
        _Step2PickerField(
          label: l10n.createStartAtLabel,
          controller: _startAtCtrl,
          hint: _formatDateTimeInput(_startAt),
          icon: Icons.event_outlined,
          keyboardType: TextInputType.datetime,
          inputFormatters: const [_dateTimeInputFormatter],
          onChanged: _handleStartAtChanged,
          errorText: _startAtErrorText,
        ),
        const SizedBox(height: 16),
        _Step2PickerField(
          label: l10n.createEndAtLabel,
          controller: _endAtCtrl,
          hint: _formatDateTimeInput(_endAt),
          icon: Icons.event_available_outlined,
          keyboardType: TextInputType.datetime,
          inputFormatters: const [_dateTimeInputFormatter],
          onChanged: _handleEndAtChanged,
          errorText: _endAtErrorText,
        ),
      ],
    );
  }

  // ── Step 3: Participation ──────────────────────────────────────

  Widget _buildStep3Participation(AppLocalizations l10n) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final textScale = media.textScaler.scale(1);
    final isCompact = width <= 360;
    final isNarrow = width <= 430 || textScale > 1.05;
    final horizontalPadding = isCompact ? 16.0 : 18.0;
    final sectionGap = isCompact ? 28.0 : 34.0;
    final priceChipGap = width <= 393 ? 6.0 : 8.0;
    final isUnlimited = _capacityType == 'UNLIMITED';
    return ListView(
      padding: AppEdgeInsets.fromLTRB(
        horizontalPadding,
        6,
        horizontalPadding,
        24 + media.viewInsets.bottom,
      ),
      children: [
        _Step3Section(
          icon: Icons.remove_red_eye_outlined,
          title: l10n.createActivityPrivacyTitle,
          child: _CategorySelectorField(
            value: switch (_visibility) {
              'PRIVATE' => l10n.createVisibilityPrivateWithPassword,
              'UNLISTED' => l10n.createVisibilityByLink,
              _ => l10n.createVisibilityPublic,
            },
            isPlaceholder: false,
            onTap: () => _openVisibilityPicker(l10n),
          ),
        ),
        if (_visibility == 'PUBLIC' ||
            _visibility == 'PRIVATE' ||
            _visibility == 'UNLISTED') ...[
          const SizedBox(height: 10),
          Text(
            switch (_visibility) {
              'PRIVATE' => l10n.createVisibilityPrivateDescription,
              'UNLISTED' => l10n.createVisibilityUnlistedDescription,
              _ => l10n.createVisibilityPublicDescription,
            },
            style: AppTextStyle(
              color: context.createActivityColors.textCaption,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
        if (_shouldShowVisibilityPasswordField) ...[
          const SizedBox(height: 16),
          _Step3TextField(
            label: l10n.createVisibilityPasswordLabel,
            controller: _visibilityPasswordCtrl,
            placeholder: l10n.createVisibilityPasswordPlaceholder,
            obscureText: true,
            inputFormatters: _activityPasswordFormatters,
            onChanged: _handleVisibilityPasswordChanged,
            errorText: _visibilityPasswordErrorText,
          ),
          if (widget.isEditMode && _startedPrivate) ...[
            const SizedBox(height: 8),
            Text(
              l10n.createVisibilityPasswordEditHint,
              style: AppTextStyle(
                color: context.createActivityColors.textCaption,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
        SizedBox(height: sectionGap),
        _Step3Section(
          icon: Icons.payments_outlined,
          title: l10n.createPricingModelTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Step3ChoiceChip(
                      label: l10n.createPriceFree,
                      isSelected: _priceType == 'FREE',
                      onTap: () => _setPriceType('FREE'),
                    ),
                  ),
                  SizedBox(width: priceChipGap),
                  Expanded(
                    child: _Step3ChoiceChip(
                      label: l10n.createPricePaid,
                      isSelected: _priceType == 'PAID',
                      onTap: () => _setPriceType('PAID'),
                    ),
                  ),
                ],
              ),
              if (_priceType != 'FREE') ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Step3PriceField(
                      label: l10n.createPriceAmountLabel,
                      controller: _priceAmountCtrl,
                      placeholder: '0.00',
                      enabled: true,
                      suffixText: l10n.createPricePerPersonHint,
                      errorText: _priceAmountErrorText,
                      onChanged: (_) {
                        if (_priceAmountErrorText == null) return;
                        setState(() => _priceAmountErrorText = null);
                      },
                    ),
                    const SizedBox(height: 12),
                    AppCurrencyPickerField(
                      label: l10n.createCurrencyLabel,
                      selectedCode: _selectedCurrencyCode,
                      surfaceColor: context.createActivityColors.warmSurface48,
                      onChanged: _setSelectedCurrencyCode,
                    ),
                  ],
                ),
              ],
              if (_isPublished) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.editPriceRestrictionHint,
                  style: AppTextStyle(
                    color: context.createActivityColors.textCaption,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: sectionGap),
        _Step3Section(
          icon: Icons.groups_outlined,
          title: l10n.createParticipantLimitsTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Step3ToggleRow(
                label: l10n.createUnlimitedParticipantsLabel,
                value: isUnlimited,
                onChanged: _setUnlimitedParticipants,
              ),
              const SizedBox(height: 16),
              _Step3ToggleRow(
                label: l10n.createAllowParticipantInvitesLabel,
                value: _allowsParticipantInvites,
                onChanged: _setAllowsParticipantInvites,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.createAllowParticipantInvitesHint,
                style: AppTextStyle(
                  color: context.createActivityColors.textCaption,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              isNarrow
                  ? Column(
                      children: [
                        _Step3LimitField(
                          label: l10n.createParticipantsMinShort,
                          icon: Icons.person_add_alt_1_outlined,
                          controller: isUnlimited ? null : _minParticipantsCtrl,
                          placeholder: '$_minActivityParticipants',
                          readOnly: isUnlimited,
                          readOnlyValue: '$_minActivityParticipants',
                          onChanged: _handleMinParticipantsChanged,
                          errorText: _minParticipantsErrorText,
                        ),
                        const SizedBox(height: 12),
                        _Step3LimitField(
                          label: l10n.createParticipantsMaxShort,
                          icon: Icons.groups_2_outlined,
                          controller: isUnlimited ? null : _maxParticipantsCtrl,
                          placeholder: l10n.createNoLimitPlaceholder,
                          readOnly: isUnlimited,
                          readOnlyValue: l10n.createNoLimitPlaceholder,
                          onChanged: _handleMaxParticipantsChanged,
                          errorText: _maxParticipantsErrorText,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Step3LimitField(
                            label: l10n.createParticipantsMinShort,
                            icon: Icons.person_add_alt_1_outlined,
                            controller: isUnlimited
                                ? null
                                : _minParticipantsCtrl,
                            placeholder: '$_minActivityParticipants',
                            readOnly: isUnlimited,
                            readOnlyValue: '$_minActivityParticipants',
                            onChanged: _handleMinParticipantsChanged,
                            errorText: _minParticipantsErrorText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Step3LimitField(
                            label: l10n.createParticipantsMaxShort,
                            icon: Icons.groups_2_outlined,
                            controller: isUnlimited
                                ? null
                                : _maxParticipantsCtrl,
                            placeholder: l10n.createNoLimitPlaceholder,
                            readOnly: isUnlimited,
                            readOnlyValue: l10n.createNoLimitPlaceholder,
                            onChanged: _handleMaxParticipantsChanged,
                            errorText: _maxParticipantsErrorText,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Reusable widgets (private to this screen)
// ════════════════════════════════════════════════════════════════

class _ActivityAmberConfirmDialog extends StatelessWidget {
  const _ActivityAmberConfirmDialog({
    required this.title,
    required this.description,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final String description;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      insetPadding: const AppEdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: context.createActivityColors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            borderRadius: AppBorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.createActivityColors.warmSurface81,
                context.createActivityColors.textOnInverse,
              ],
            ),
            border: Border.all(
              color: context.createActivityColors.primary.withValues(
                alpha: 0.58,
              ),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: context.createActivityColors.black.withValues(
                  alpha: 0.42,
                ),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: const AppEdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: AppBoxDecoration(
                        color: context.createActivityColors.primary.withValues(
                          alpha: 0.18,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.createActivityColors.primary
                              .withValues(alpha: 0.72),
                        ),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: context.createActivityColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyle(
                              color: context.createActivityColors.orangeWash23,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            description,
                            style: AppTextStyle(
                              color: context.createActivityColors.orangeLight13,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.createActivityColors.primary,
                      foregroundColor: context.createActivityColors.textPrimary,
                      padding: const AppEdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.circular(18),
                      ),
                      textStyle: AppTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          context.createActivityColors.orangeLight29,
                      padding: const AppEdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      cancelLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(fontWeight: FontWeight.w800),
                    ),
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

class _MapExpandButton extends StatelessWidget {
  const _MapExpandButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Positioned(
      top: 12,
      right: 12,
      child: Semantics(
        button: true,
        label: l10n.createMapTapHint,
        child: Tooltip(
          message: l10n.createMapTapHint,
          child: Material(
            color: context.createActivityColors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppBorderRadius.circular(999),
              child: Ink(
                width: 46,
                height: 46,
                decoration: AppBoxDecoration(
                  shape: BoxShape.circle,
                  color: context.createActivityColors.warmInk104.withValues(
                    alpha: 0.88,
                  ),
                  border: Border.all(
                    color: context.createActivityColors.primary.withValues(
                      alpha: 0.34,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.createActivityColors.black.withValues(
                        alpha: 0.18,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.open_in_full_rounded,
                  color: context.createActivityColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateTopBar extends StatelessWidget {
  const _CreateTopBar({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final textScale = media.textScaler.scale(1);
    final compact = width <= 360 || textScale > 1.05;
    final titleSize = compact ? 18.0 : (width >= 394 ? 22.0 : 20.0);

    return Padding(
      padding: AppEdgeInsets.fromLTRB(10, compact ? 6 : 8, 10, compact ? 2 : 4),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: onBack == null
                  ? null
                  : IconButton(
                      onPressed: onBack,
                      splashRadius: 20,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: context.createActivityColors.textPrimary,
                        size: 18,
                      ),
                    ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: context.createActivityColors.textPrimary,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.titles,
    required this.counterLabel,
    this.compact = false,
    this.onStepTap,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> titles;
  final String counterLabel;
  final bool compact;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      final media = MediaQuery.of(context);
      final width = media.size.width;
      final height = media.size.height;
      final textScale = media.textScaler.scale(1);
      final isCompact = width <= 360 || textScale > 1.05;
      final topPadding = height <= 780 || textScale > 1.05 ? 18.0 : 28.0;
      final bottomPadding = height <= 780 || textScale > 1.05 ? 22.0 : 34.0;

      return Padding(
        padding: AppEdgeInsets.fromLTRB(
          isCompact ? 22 : 28,
          topPadding,
          isCompact ? 22 : 28,
          bottomPadding,
        ),
        child: Row(
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isOdd) {
              final lineIndex = index ~/ 2;
              final isDone = lineIndex < currentStep;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const AppEdgeInsets.symmetric(horizontal: 10),
                  decoration: AppBoxDecoration(
                    color: isDone
                        ? context.createActivityColors.success
                        : context.createActivityColors.primary.withValues(
                            alpha: 0.32,
                          ),
                    borderRadius: AppBorderRadius.circular(999),
                  ),
                ),
              );
            }

            final stepIndex = index ~/ 2;
            final isActive = stepIndex == currentStep;
            final isDone = stepIndex < currentStep;
            final isStepTappable = onStepTap != null && stepIndex < currentStep;
            final stepSize = isActive ? 48.0 : (isDone ? 40.0 : 34.0);
            final stepBorderColor = isDone
                ? context.createActivityColors.success.withValues(alpha: 0.72)
                : isActive
                ? context.createActivityColors.primary
                : context.createActivityColors.border;
            final stepChild = isDone
                ? Icon(
                    Icons.check_rounded,
                    color: context.createActivityColors.white,
                  )
                : Text(
                    '${stepIndex + 1}',
                    style: AppTextStyle(
                      color: isActive
                          ? context.createActivityColors.white
                          : context.createActivityColors.orangeLight37,
                      fontSize: isActive ? 20 : 15,
                      fontWeight: FontWeight.w900,
                    ),
                  );

            return Material(
              color: context.createActivityColors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: isStepTappable ? () => onStepTap!(stepIndex) : null,
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: stepSize,
                  height: stepSize,
                  decoration: AppBoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? context.createActivityColors.success
                        : isActive
                        ? context.createActivityColors.primary
                        : context.createActivityColors.warmSurface96,
                    boxShadow: isDone
                        ? [
                            BoxShadow(
                              color: context.createActivityColors.success
                                  .withValues(alpha: 0.22),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ]
                        : isActive
                        ? [
                            BoxShadow(
                              color: context.createActivityColors.primary
                                  .withValues(alpha: 0.24),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : null,
                    border: Border.all(
                      color: stepBorderColor,
                      width: isActive ? 1.3 : 1,
                    ),
                  ),
                  child: Center(child: stepChild),
                ),
              ),
            );
          }),
        ),
      );
    }

    return Container(
      padding: const AppEdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titles[currentStep],
                  style: AppTextStyle(
                    color: context.createActivityColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Text(
                counterLabel,
                style: AppTextStyle(
                  color: context.createActivityColors.textCaption,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: AppBorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / totalSteps,
              minHeight: 5,
              backgroundColor: context.createActivityColors.white.withValues(
                alpha: 0.08,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                context.createActivityColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            titles[currentStep],
            style: AppTextStyle(
              color: context.createActivityColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.isSubmitting,
    required this.onNext,
    required this.nextLabel,
    this.heroStyle = false,
  });

  final bool isSubmitting;
  final VoidCallback onNext;
  final String nextLabel;
  final bool heroStyle;

  @override
  Widget build(BuildContext context) {
    if (heroStyle) {
      final media = MediaQuery.of(context);
      final width = media.size.width;
      final textScale = media.textScaler.scale(1);
      final isCompact = width <= 360 || textScale > 1.05;
      final isWide = width >= 394;
      final horizontalPadding = isCompact ? 16.0 : (isWide ? 24.0 : 20.0);
      final buttonHeight = isCompact ? 60.0 : (isWide ? 68.0 : 64.0);
      final fontSize = isCompact ? 18.0 : (isWide ? 22.0 : 20.0);

      return SafeArea(
        top: false,
        child: Container(
          padding: AppEdgeInsets.fromLTRB(
            horizontalPadding,
            14,
            horizontalPadding,
            16,
          ),
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.createActivityColors.warmInk54.withValues(alpha: 0),
                context.createActivityColors.warmInk54.withValues(alpha: 0.9),
                context.createActivityColors.warmInk54,
              ],
            ),
            border: Border(
              top: BorderSide(
                color: context.createActivityColors.primary.withValues(
                  alpha: 0.18,
                ),
              ),
            ),
          ),
          child: ElevatedButton(
            onPressed: isSubmitting ? null : onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.createActivityColors.primary,
              foregroundColor: context.createActivityColors.textPrimary,
              minimumSize: Size.fromHeight(buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            child: isSubmitting
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: context.createActivityColors.textPrimary,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          nextLabel,
                          style: AppTextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, size: 22),
                      ],
                    ),
                  ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const AppEdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: AppBoxDecoration(
          color: context.createActivityColors.warmOverlayInk04,
          border: Border(
            top: BorderSide(
              color: context.createActivityColors.outlineOverlayLight,
            ),
          ),
        ),
        child: ElevatedButton(
          onPressed: isSubmitting ? null : onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.createActivityColors.primary,
            foregroundColor: context.createActivityColors.textPrimary,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: AppBorderRadius.circular(18),
            ),
          ),
          child: isSubmitting
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: context.createActivityColors.textPrimary,
                  ),
                )
              : Text(
                  nextLabel,
                  style: AppTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _Step2NavBar extends StatelessWidget {
  const _Step2NavBar({
    required this.isSubmitting,
    required this.onNext,
    required this.nextLabel,
  });

  final bool isSubmitting;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final horizontalPadding = width <= 393 ? 16.0 : 20.0;

    final nextButton = ElevatedButton(
      onPressed: isSubmitting ? null : onNext,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        foregroundColor: context.createActivityColors.textPrimary,
        backgroundColor: context.createActivityColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.circular(999),
        ),
      ),
      child: isSubmitting
          ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: context.createActivityColors.textPrimary,
              ),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nextLabel,
                    style: AppTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
            ),
    );

    return SafeArea(
      top: false,
      child: Container(
        padding: AppEdgeInsets.fromLTRB(
          horizontalPadding,
          14,
          horizontalPadding,
          14,
        ),
        decoration: AppBoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.createActivityColors.warmInk54.withValues(alpha: 0),
              context.createActivityColors.warmInk54.withValues(alpha: 0.88),
              context.createActivityColors.warmInk54,
            ],
          ),
          border: Border(
            top: BorderSide(
              color: context.createActivityColors.blueMuted24.withValues(
                alpha: 0.16,
              ),
            ),
          ),
        ),
        child: SizedBox(width: double.infinity, child: nextButton),
      ),
    );
  }
}

class _Step1FieldSection extends StatelessWidget {
  const _Step1FieldSection({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final labelSize = width <= 360 ? 16.0 : (width >= 394 ? 20.0 : 18.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle(
            color: context.createActivityColors.textPrimary,
            fontSize: labelSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _Step2FieldSection extends StatelessWidget {
  const _Step2FieldSection({required this.label, required this.child});

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
            color: context.createActivityColors.orangeWash01,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _Step2LocationMismatchNotice extends StatelessWidget {
  const _Step2LocationMismatchNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const AppEdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppBoxDecoration(
        color: context.createActivityColors.secondaryContainer,
        borderRadius: AppBorderRadius.circular(18),
        border: Border.all(color: context.createActivityColors.borderSecondary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: context.createActivityColors.secondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyle(
                color: context.createActivityColors.textPrimary,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step2FormatSegmented extends StatelessWidget {
  const _Step2FormatSegmented({
    required this.value,
    required this.items,
    required this.icons,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> items;
  final Map<String, IconData> icons;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = items.entries.toList();
    final width = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.of(context).textScaler.scale(1);
    final segmentHeight = width <= 360 || textScale > 1.05 ? 52.0 : 56.0;
    final iconSize = width <= 360 ? 16.0 : 18.0;
    final fontSize = width <= 360 || textScale > 1.05 ? 13.0 : 15.0;
    final spacing = width <= 360 ? 6.0 : 8.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const AppEdgeInsets.all(6),
      decoration: AppBoxDecoration(
        color: context.createActivityColors.surface,
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: context.createActivityColors.border),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: context.createActivityColors.neutralOverlayInk01,
                  blurRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: entries.map((entry) {
          final isActive = entry.key == value;
          final labelColor = isActive
              ? context.createActivityColors.textPrimary
              : context.createActivityColors.primary;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: Container(
                constraints: BoxConstraints(minHeight: segmentHeight),
                decoration: AppBoxDecoration(
                  color: isActive
                      ? context.createActivityColors.primary
                      : context.createActivityColors.surfaceRaised,
                  borderRadius: AppBorderRadius.circular(999),
                  border: Border.all(
                    color: isActive
                        ? context.createActivityColors.primary
                        : context.createActivityColors.border,
                  ),
                  boxShadow: isActive && isDark
                      ? [
                          BoxShadow(
                            color: context.createActivityColors.primary
                                .withValues(alpha: 0.22),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : null,
                ),
                child: Padding(
                  padding: const AppEdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[entry.key], size: iconSize, color: labelColor),
                      SizedBox(width: spacing),
                      Flexible(
                        child: Text(
                          entry.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            color: labelColor,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Step2PillTextField extends StatelessWidget {
  const _Step2PillTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.onChanged,
    this.errorText,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    const fieldHeight = 68.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: fieldHeight),
          decoration: AppBoxDecoration(
            color: context.createActivityColors.warmSurface47,
            borderRadius: AppBorderRadius.circular(999),
            border: Border.all(
              color: errorText == null
                  ? context.createActivityColors.border
                  : _inlineValidationColor(context),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onChanged: onChanged,
            maxLines: 1,
            scrollPhysics: const BouncingScrollPhysics(),
            textAlignVertical: TextAlignVertical.center,
            style: AppTextStyle(
              color: context.createActivityColors.textPrimary,
              fontSize: 16,
              height: 1.2,
              letterSpacing: -0.2,
            ),
            decoration: AppInputDecoration(
              hintText: hint,
              hintStyle: AppTextStyle(
                color: context.createActivityColors.orangeSoft11,
                fontSize: 16,
                height: 1.2,
                letterSpacing: -0.2,
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: const AppEdgeInsets.fromLTRB(0, 18, 20, 18),
              prefixIcon: SizedBox(
                width: 56,
                height: fieldHeight,
                child: Center(
                  child: Padding(
                    padding: const AppEdgeInsets.only(left: 18, right: 12),
                    child: Icon(
                      icon,
                      color: context.createActivityColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 56,
                minHeight: fieldHeight,
              ),
            ),
          ),
        ),
        if (errorText != null)
          AppInlineFieldError(
            message: errorText!,
            padding: const AppEdgeInsets.only(top: 8, left: 6, right: 6),
          ),
      ],
    );
  }
}

class _Step2PickerField extends StatelessWidget {
  const _Step2PickerField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle(
            color: context.createActivityColors.orangeWash01,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: AppBoxDecoration(
            color: context.createActivityColors.warmSurface47,
            borderRadius: AppBorderRadius.circular(999),
            border: Border.all(
              color: errorText == null
                  ? context.createActivityColors.border
                  : _inlineValidationColor(context),
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textAlignVertical: TextAlignVertical.center,
            style: AppTextStyle(
              color: context.createActivityColors.textPrimary,
              fontSize: 16,
              height: 1.2,
              letterSpacing: -0.2,
            ),
            decoration: AppInputDecoration(
              hintText: hint,
              hintStyle: AppTextStyle(
                color: context.createActivityColors.orangeSoft11,
                fontSize: 16,
                height: 1.2,
                letterSpacing: -0.2,
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: const AppEdgeInsets.fromLTRB(18, 17, 8, 17),
              suffixIcon: Icon(
                icon,
                color: context.createActivityColors.orangeSoft11,
                size: 20,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 64,
              ),
            ),
          ),
        ),
        if (errorText != null)
          AppInlineFieldError(
            message: errorText!,
            padding: const AppEdgeInsets.only(top: 8, left: 6, right: 6),
          ),
      ],
    );
  }
}

class _DateTimeInputFormatter extends TextInputFormatter {
  const _DateTimeInputFormatter();

  static const _maxDigits = 12;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawSelectionOffset = newValue.selection.isValid
        ? newValue.selection.extentOffset
        : newValue.text.length;
    final selectionOffset = rawSelectionOffset < 0
        ? 0
        : rawSelectionOffset > newValue.text.length
        ? newValue.text.length
        : rawSelectionOffset;
    final selectionDigitCount = _countDigitsBeforeOffset(
      newValue.text,
      selectionOffset,
    );
    final selectionFollowsSeparator =
        selectionOffset > 0 &&
        !_isDigit(newValue.text.codeUnitAt(selectionOffset - 1));

    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = digits.length > _maxDigits
        ? digits.substring(0, _maxDigits)
        : digits;
    final clampedSelectionDigitCount = selectionDigitCount > trimmed.length
        ? trimmed.length
        : selectionDigitCount;
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i == 2 || i == 4) {
        buffer.write('.');
      } else if (i == 8) {
        buffer.write(' ');
      } else if (i == 10) {
        buffer.write(':');
      }
      buffer.write(trimmed[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: _selectionOffsetForDigitCount(
          text,
          clampedSelectionDigitCount,
          preferAfterSeparator: selectionFollowsSeparator,
        ),
      ),
      composing: TextRange.empty,
    );
  }

  static int _countDigitsBeforeOffset(String value, int offset) {
    var count = 0;
    for (var i = 0; i < offset; i++) {
      if (_isDigit(value.codeUnitAt(i))) {
        count++;
      }
    }
    return count;
  }

  static int _selectionOffsetForDigitCount(
    String value,
    int digitCount, {
    required bool preferAfterSeparator,
  }) {
    if (digitCount <= 0) {
      return 0;
    }

    var count = 0;
    for (var i = 0; i < value.length; i++) {
      if (!_isDigit(value.codeUnitAt(i))) {
        continue;
      }
      count++;
      if (count == digitCount) {
        var offset = i + 1;
        if (preferAfterSeparator) {
          while (offset < value.length && !_isDigit(value.codeUnitAt(offset))) {
            offset++;
          }
        }
        return offset;
      }
    }

    return value.length;
  }

  static bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;
}

class _Step3Section extends StatelessWidget {
  const _Step3Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: context.createActivityColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTextStyle(
                  color: context.createActivityColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _Step3ChoiceChip extends StatelessWidget {
  const _Step3ChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.of(context).textScaler.scale(1);
    final horizontalPadding = width <= 360 ? 8.0 : 12.0;
    final fontSize = width <= 360 || textScale > 1.05 ? 12.0 : 15.0;
    final labelColor = isSelected
        ? context.createActivityColors.textPrimary
        : context.createActivityColors.textPrimary;

    return Material(
      color: context.createActivityColors.transparent,
      child: InkWell(
        borderRadius: AppBorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 50),
          padding: AppEdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 10,
          ),
          decoration: AppBoxDecoration(
            color: isSelected
                ? context.createActivityColors.primary
                : context.createActivityColors.surfaceRaised,
            borderRadius: AppBorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? context.createActivityColors.primary
                  : context.createActivityColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppTextStyle(
                color: labelColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step3PriceField extends StatelessWidget {
  const _Step3PriceField({
    required this.label,
    required this.controller,
    required this.placeholder,
    required this.enabled,
    required this.suffixText,
    this.onChanged,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final bool enabled;
  final String suffixText;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle(
            color: context.createActivityColors.orangeWash05,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(minHeight: 68),
          decoration: _createActivityInputDecoration(
            context,
            borderRadius: AppBorderRadius.circular(999),
            hasFocus: false,
            hasError: errorText != null,
          ),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              return TextField(
                controller: controller,
                enabled: enabled,
                onChanged: onChanged,
                textAlignVertical: TextAlignVertical.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: AppTextStyle(
                  color: enabled
                      ? context.createActivityColors.textPrimary
                      : context.createActivityColors.textPrimary.withValues(
                          alpha: 0.72,
                        ),
                  fontSize: 20,
                  height: 1.2,
                  letterSpacing: -0.6,
                ),
                decoration: AppInputDecoration(
                  suffixText: suffixText,
                  suffixStyle: AppTextStyle(
                    color: enabled
                        ? context.createActivityColors.textPrimary
                        : context.createActivityColors.textPrimary.withValues(
                            alpha: 0.7,
                          ),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  hintText: placeholder,
                  hintStyle: AppTextStyle(
                    color: context.createActivityColors.textMuted,
                    fontSize: 20,
                    height: 1.2,
                    letterSpacing: -0.6,
                  ),
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const AppEdgeInsets.fromLTRB(20, 18, 20, 18),
                ),
              );
            },
          ),
        ),
        if (errorText != null)
          AppInlineFieldError(
            message: errorText!,
            padding: const AppEdgeInsets.only(top: 8, left: 6, right: 6),
          ),
      ],
    );
  }
}

class _Step3TextField extends StatelessWidget {
  const _Step3TextField({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.onChanged,
    this.obscureText = false,
    this.inputFormatters,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle(
            color: context.createActivityColors.orangeWash05,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(minHeight: 68),
          decoration: AppBoxDecoration(
            color: context.createActivityColors.warmSurface48,
            borderRadius: AppBorderRadius.circular(999),
            border: Border.all(
              color: errorText == null
                  ? context.createActivityColors.border
                  : _inlineValidationColor(context),
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: obscureText,
            inputFormatters: inputFormatters,
            textAlignVertical: TextAlignVertical.center,
            style: AppTextStyle(
              color: context.createActivityColors.textPrimary,
              fontSize: 18,
              height: 1.2,
              letterSpacing: -0.4,
            ),
            decoration: AppInputDecoration(
              hintText: placeholder,
              hintStyle: AppTextStyle(
                color: context.createActivityColors.warmMuted19,
                fontSize: 18,
                height: 1.2,
                letterSpacing: -0.4,
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: const AppEdgeInsets.fromLTRB(20, 18, 20, 18),
            ),
          ),
        ),
        if (errorText != null)
          AppInlineFieldError(
            message: errorText!,
            padding: const AppEdgeInsets.only(top: 8, left: 6, right: 6),
          ),
      ],
    );
  }
}

class _Step3ToggleRow extends StatelessWidget {
  const _Step3ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppBorderRadius.circular(999),
      onTap: () => onChanged(!value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const AppEdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: AppBoxDecoration(
          color: context.createActivityColors.surfaceRaised,
          borderRadius: AppBorderRadius.circular(999),
          border: Border.all(color: context.createActivityColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  color: context.createActivityColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 60,
              height: 34,
              padding: const AppEdgeInsets.all(4),
              decoration: AppBoxDecoration(
                color: value
                    ? context.createActivityColors.primary
                    : context.createActivityColors.surfaceHigh,
                borderRadius: AppBorderRadius.circular(999),
                border: Border.all(
                  color: value
                      ? context.createActivityColors.primary
                      : context.createActivityColors.border,
                ),
              ),
              child: Align(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: AppBoxDecoration(
                    color: context.createActivityColors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step3LimitField extends StatelessWidget {
  const _Step3LimitField({
    required this.label,
    required this.icon,
    required this.placeholder,
    required this.readOnly,
    required this.readOnlyValue,
    this.controller,
    this.onChanged,
    this.errorText,
  });

  final String label;
  final IconData icon;
  final String placeholder;
  final bool readOnly;
  final String readOnlyValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.createActivityColors;
    final hasError = errorText != null;
    final valueStyle = AppTextStyle(
      color: readOnly && readOnlyValue == placeholder
          ? colors.textMuted
          : colors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );
    final hintStyle = AppTextStyle(
      color: colors.textMuted,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const AppEdgeInsets.fromLTRB(14, 12, 16, 12),
          decoration: AppBoxDecoration(
            color: context.createActivityColors.surfaceRaised,
            borderRadius: AppBorderRadius.circular(26),
            border: Border.all(
              color: hasError ? _inlineValidationColor(context) : colors.border,
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: AppBoxDecoration(
                  color: context.createActivityColors.surfaceWarm,
                  borderRadius: AppBorderRadius.circular(18),
                  border: Border.all(color: colors.borderPrimary),
                ),
                child: Icon(icon, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: readOnly
                    ? Text(
                        readOnlyValue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: valueStyle,
                      )
                    : TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlignVertical: TextAlignVertical.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: onChanged,
                        style: valueStyle,
                        decoration: AppInputDecoration(
                          hintText: placeholder,
                          hintStyle: hintStyle,
                          isDense: true,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (errorText != null)
          AppInlineFieldError(
            message: errorText!,
            padding: const AppEdgeInsets.only(top: 8, left: 6, right: 6),
          ),
      ],
    );
  }
}

class _Step3ActionBar extends StatelessWidget {
  const _Step3ActionBar({
    required this.isSubmitting,
    required this.onPrimaryAction,
    required this.primaryLabel,
    this.showPrimaryIcon = true,
  });

  final bool isSubmitting;
  final VoidCallback onPrimaryAction;
  final String primaryLabel;
  final bool showPrimaryIcon;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final horizontalPadding = width <= 360 ? 16.0 : 18.0;

    final primaryButton = ElevatedButton(
      onPressed: isSubmitting ? null : onPrimaryAction,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(62),
        foregroundColor: context.createActivityColors.textPrimary,
        backgroundColor: context.createActivityColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.circular(999),
        ),
      ),
      child: isSubmitting
          ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: context.createActivityColors.textPrimary,
              ),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    primaryLabel,
                    style: AppTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (showPrimaryIcon) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_outward_rounded, size: 22),
                  ],
                ],
              ),
            ),
    );

    return SafeArea(
      top: false,
      child: Container(
        padding: AppEdgeInsets.fromLTRB(
          horizontalPadding,
          16,
          horizontalPadding,
          18,
        ),
        decoration: AppBoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.createActivityColors.warmInk48.withValues(alpha: 0),
              context.createActivityColors.warmInk48.withValues(alpha: 0.9),
              context.createActivityColors.warmInk48,
            ],
          ),
          border: Border(
            top: BorderSide(
              color: context.createActivityColors.blueMuted24.withValues(
                alpha: 0.2,
              ),
            ),
          ),
        ),
        child: SizedBox(width: double.infinity, child: primaryButton),
      ),
    );
  }
}

class _Step1TextField extends StatefulWidget {
  const _Step1TextField({
    required this.controller,
    this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.minHeight,
    this.isMultiline = false,
    this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String? hint;
  final int? maxLength;
  final int maxLines;
  final double? minHeight;
  final bool isMultiline;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  State<_Step1TextField> createState() => _Step1TextFieldState();
}

class _Step1TextFieldState extends State<_Step1TextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width <= 360;
    final isWide = width >= 394;
    final radius = AppBorderRadius.circular(32);
    final fieldHeight =
        widget.minHeight ?? (isCompact ? 66.0 : (isWide ? 78.0 : 72.0));
    final horizontalPadding = isCompact ? 18.0 : 22.0;
    final fieldFontSize = isCompact ? 16.0 : (isWide ? 20.0 : 18.0);
    final multilineTop = isCompact ? 18.0 : 20.0;
    final singleLineVerticalPadding = isCompact ? 16.0 : (isWide ? 20.0 : 18.0);
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: BoxConstraints(minHeight: fieldHeight),
          decoration: _createActivityInputDecoration(
            context,
            borderRadius: radius,
            hasFocus: _focusNode.hasFocus,
            hasError: hasError,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            maxLength: widget.maxLength,
            buildCounter:
                (
                  context, {
                  required int currentLength,
                  required bool isFocused,
                  int? maxLength,
                }) => null,
            maxLines: widget.maxLines,
            minLines: widget.isMultiline ? widget.maxLines : 1,
            scrollPhysics: widget.isMultiline
                ? null
                : const BouncingScrollPhysics(),
            keyboardType: widget.isMultiline
                ? TextInputType.multiline
                : TextInputType.text,
            textAlignVertical: widget.isMultiline
                ? TextAlignVertical.top
                : TextAlignVertical.center,
            style: AppTextStyle(
              color: context.createActivityColors.textPrimary,
              fontSize: fieldFontSize,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.8,
              height: 1.2,
            ),
            decoration: AppInputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyle(
                color: context.createActivityColors.textMuted,
                fontSize: fieldFontSize,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.8,
              ),
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: AppEdgeInsets.fromLTRB(
                horizontalPadding,
                widget.isMultiline ? multilineTop : singleLineVerticalPadding,
                horizontalPadding,
                widget.isMultiline ? 20 : singleLineVerticalPadding,
              ),
            ),
          ),
        ),
        if (widget.errorText != null)
          AppInlineFieldError(
            message: widget.errorText!,
            padding: const AppEdgeInsets.only(top: 8, left: 6, right: 6),
          ),
      ],
    );
  }
}

class _CategorySelectorField extends StatelessWidget {
  const _CategorySelectorField({
    required this.value,
    required this.isPlaceholder,
    required this.onTap,
    this.errorText,
  });

  final String value;
  final bool isPlaceholder;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width <= 360;
    final isWide = width >= 394;
    final height = isCompact ? 66.0 : (isWide ? 78.0 : 72.0);
    final fontSize = isCompact ? 16.0 : (isWide ? 20.0 : 18.0);
    final horizontalPadding = isCompact ? 18.0 : 22.0;
    final hasError = errorText != null;
    final radius = AppBorderRadius.circular(32);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          container: true,
          button: true,
          label: value,
          onTap: onTap,
          child: ExcludeSemantics(
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                constraints: BoxConstraints(minHeight: height),
                padding: AppEdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 10,
                ),
                decoration: _createActivityInputDecoration(
                  context,
                  borderRadius: radius,
                  hasFocus: false,
                  hasError: hasError,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: isPlaceholder
                              ? context.createActivityColors.textMuted
                              : context.createActivityColors.textPrimary,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      color: context.createActivityColors.primary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (errorText != null)
          AppInlineFieldError(
            message: errorText!,
            padding: const AppEdgeInsets.only(top: 8, left: 6, right: 6),
          ),
      ],
    );
  }
}

LinearGradient? _coverUploadOverlayGradient(
  BuildContext context, {
  required bool hasPreview,
}) {
  if (Theme.of(context).brightness == Brightness.light) {
    return null;
  }

  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      context.createActivityColors.black.withValues(
        alpha: hasPreview ? 0.08 : 0.12,
      ),
      context.createActivityColors.black.withValues(
        alpha: hasPreview ? 0.44 : 0.18,
      ),
      context.createActivityColors.black.withValues(alpha: 0.68),
    ],
    stops: const [0, 0.52, 1],
  );
}

class _CoverUploadCard extends StatelessWidget {
  const _CoverUploadCard({
    required this.title,
    required this.hint,
    required this.onTap,
    this.imageUrl,
    this.previewBytes,
    this.isUploading = false,
    this.hasError = false,
  });

  final String title;
  final String hint;
  final String? imageUrl;
  final Uint8List? previewBytes;
  final bool isUploading;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width <= 360;
    final isWide = width >= 394;
    final radius = isCompact ? 28.0 : 34.0;
    final height = isCompact ? 190.0 : (isWide ? 230.0 : 210.0);

    final hasPreview = (previewBytes?.isNotEmpty ?? false) || _hasImageUrl;
    final overlayGradient = _coverUploadOverlayGradient(
      context,
      hasPreview: hasPreview,
    );

    return Material(
      color: context.createActivityColors.transparent,
      child: InkWell(
        onTap: isUploading ? null : onTap,
        borderRadius: AppBorderRadius.circular(radius),
        child: ClipRRect(
          borderRadius: AppBorderRadius.circular(radius),
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBackground(hasPreview),
                if (overlayGradient != null)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: AppBoxDecoration(gradient: overlayGradient),
                    ),
                  ),
                Positioned(
                  left: isCompact ? 18 : 22,
                  right: isCompact ? 18 : 22,
                  bottom: isCompact ? 18 : 22,
                  child: _CoverCardCopy(
                    title: title,
                    hint: hint,
                    hasPreview: hasPreview,
                    hasError: hasError,
                    compact: isCompact,
                  ),
                ),
                if (isUploading)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: AppBoxDecoration(
                        color: context.createActivityColors.black.withValues(
                          alpha: 0.42,
                        ),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.createActivityColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DashedCoverBorderPainter(
                      color: hasError
                          ? context.createActivityColors.redSoft10
                          : context.createActivityColors.secondary,
                      radius: radius,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasImageUrl => (imageUrl?.trim().isNotEmpty ?? false);

  Widget _buildBackground(bool hasPreview) {
    if (previewBytes != null && previewBytes!.isNotEmpty) {
      return Image.memory(previewBytes!, fit: BoxFit.cover);
    }
    if (_hasImageUrl) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(hasPreview: false),
      );
    }
    return _buildPlaceholder(hasPreview: hasPreview);
  }

  Widget _buildPlaceholder({required bool hasPreview}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final baseSize = constraints.biggest.shortestSide;
        final accentCircleSize = baseSize * 0.54;
        final glowCircleSize = baseSize * 0.58;
        final actionCircleSize = baseSize * 0.27;

        return DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.createActivityColors.warmSurface55,
                context.createActivityColors.warmInk30,
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -accentCircleSize * 0.26,
                right: -accentCircleSize * 0.22,
                child: Container(
                  width: accentCircleSize,
                  height: accentCircleSize,
                  decoration: AppBoxDecoration(
                    shape: BoxShape.circle,
                    color: context.createActivityColors.secondaryContainer,
                  ),
                ),
              ),
              Positioned(
                left: -glowCircleSize * 0.17,
                bottom: -glowCircleSize * 0.29,
                child: Container(
                  width: glowCircleSize,
                  height: glowCircleSize,
                  decoration: AppBoxDecoration(
                    shape: BoxShape.circle,
                    color: context.createActivityColors.white.withValues(
                      alpha: 0.05,
                    ),
                  ),
                ),
              ),
              if (!hasPreview)
                Center(
                  child: Container(
                    width: actionCircleSize,
                    height: actionCircleSize,
                    decoration: AppBoxDecoration(
                      shape: BoxShape.circle,
                      color: context.createActivityColors.secondaryContainer,
                      border: Border.all(
                        color: context.createActivityColors.borderSecondary,
                      ),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_rounded,
                      color: context.createActivityColors.secondary,
                      size: actionCircleSize * 0.47,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CoverCardCopy extends StatelessWidget {
  const _CoverCardCopy({
    required this.title,
    required this.hint,
    required this.hasPreview,
    required this.hasError,
    required this.compact,
  });

  final String title;
  final String hint;
  final bool hasPreview;
  final bool hasError;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final hintColor = hasError
        ? context.createActivityColors.redLight06
        : isLight
        ? context.createActivityColors.textSecondary
        : context.createActivityColors.textPrimary;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Container(
                padding: const AppEdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: AppBoxDecoration(
                  color: context.createActivityColors.secondaryContainer,
                  borderRadius: AppBorderRadius.circular(999),
                  border: Border.all(
                    color: context.createActivityColors.borderSecondary,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasPreview
                          ? Icons.refresh_rounded
                          : Icons.file_upload_outlined,
                      color: context.createActivityColors.secondary,
                      size: compact ? 14 : 15,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: context.createActivityColors.secondary,
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          hint,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle(
            color: hintColor,
            fontSize: compact ? 13 : 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    if (!isLight) {
      return content;
    }

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: context.createActivityColors.surface,
        borderRadius: AppBorderRadius.circular(22),
        border: Border.all(color: context.createActivityColors.border),
      ),
      child: Padding(padding: const AppEdgeInsets.all(12), child: content),
    );
  }
}

class _DashedCoverBorderPainter extends CustomPainter {
  const _DashedCoverBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1.5),
      AppRadiusValue.circular(radius),
    );
    final path = ui.Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      const dashLength = 10.0;
      const gapLength = 8.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCoverBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _CategoryCatalogState extends StatelessWidget {
  const _CategoryCatalogState({required this.message, this.trailing});

  final String message;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width <= 360;
    final isWide = width >= 394;
    final height = isCompact ? 66.0 : (isWide ? 78.0 : 72.0);
    final fontSize = isCompact ? 16.0 : (isWide ? 20.0 : 18.0);
    final horizontalPadding = isCompact ? 18.0 : 22.0;

    return Container(
      constraints: BoxConstraints(minHeight: height),
      padding: AppEdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 10,
      ),
      decoration: _createActivityInputDecoration(
        context,
        borderRadius: AppBorderRadius.circular(32),
        hasFocus: false,
        hasError: false,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(
                color: context.createActivityColors.textMuted,
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.6,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({
    required this.title,
    required this.actionLabel,
    required this.items,
    required this.initialValue,
    required this.iconForSlug,
  });

  final String title;
  final String actionLabel;
  final Map<String, String> items;
  final String? initialValue;
  final IconData Function(String slug) iconForSlug;

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  late String? _selected = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.42;

    return Padding(
      padding: AppEdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 48,
      ),
      child: Container(
        decoration: AppBoxDecoration(
          color: context.createActivityColors.warmSurface18,
          borderRadius: AppBorderRadius.circular(28),
          border: Border.all(
            color: context.createActivityColors.outlineOverlayLight,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const AppEdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTextStyle(
                          color: context.createActivityColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: context.createActivityColors.textCoolSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxListHeight),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = widget.items.entries.elementAt(index);
                      final selected = entry.key == _selected;
                      void selectItem() {
                        setState(() => _selected = entry.key);
                      }

                      return Semantics(
                        container: true,
                        button: true,
                        selected: selected,
                        label: entry.value,
                        onTap: selectItem,
                        child: ExcludeSemantics(
                          child: InkWell(
                            borderRadius: AppBorderRadius.circular(18),
                            onTap: selectItem,
                            child: Container(
                              padding: const AppEdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: AppBoxDecoration(
                                color: selected
                                    ? context.createActivityColors.primary
                                          .withValues(alpha: 0.18)
                                    : context.createActivityColors.surfaceHigh,
                                borderRadius: AppBorderRadius.circular(18),
                                border: Border.all(
                                  color: selected
                                      ? context.createActivityColors.primary
                                      : context
                                            .createActivityColors
                                            .outlineOverlayLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    widget.iconForSlug(entry.key),
                                    color: context.createActivityColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: AppTextStyle(
                                        color: context
                                            .createActivityColors
                                            .textPrimary,
                                        fontSize: 15,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    selected
                                        ? Icons.check_circle_rounded
                                        : Icons.chevron_right_rounded,
                                    color: selected
                                        ? context.createActivityColors.primary
                                        : context
                                              .createActivityColors
                                              .textCaption,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.of(context).pop(_selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.createActivityColors.primary,
                      disabledBackgroundColor:
                          context.createActivityColors.surfaceCoolLight,
                      foregroundColor: context.createActivityColors.textPrimary,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      widget.actionLabel,
                      style: AppTextStyle(fontWeight: FontWeight.w700),
                    ),
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
