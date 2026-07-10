import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/ui/app_inline_field_error.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/excursions/excursion_cover_url.dart';
import '../../features/excursions/guide_offer_status.dart';
import '../../features/excursions/models/create_excursion_request.dart';
import '../../features/excursions/models/excursion_vm.dart';
import '../../features/excursions/excursion_localization.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/excursion_provider.dart';
import '../../providers/home_location_provider.dart';
import '../../shared/map/app_map_link_resolver.dart';
import '../../shared/map/app_map_links.dart';
import '../../shared/widgets/app_currency_picker_field.dart';
import '../../shared/widgets/app_map_card.dart';
import '../map/map_screen.dart';
import 'excursion_select_location_screen.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

final class _CreateExcursionColors {
  const _CreateExcursionColors._(this.colors);

  final AppColors colors;

  static _CreateExcursionColors of(BuildContext context) {
    return _CreateExcursionColors._(AppDesignSystem.colorsFor(context));
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
  Color get backgroundWarm => colors.backgroundWarm;
  List<Color> get screenGradientColors => colors.screenGradientColors;
  Color get surface => colors.surface;
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
  Color get orangeLight13 => colors.primary;
  Color get orangeLight29 => colors.primary;
  Color get orangeLight37 => colors.primary;
  Color get orangeWash23 => colors.primary;
  Color get textOnInverse => colors.backgroundDeep;
  Color get warmSurface81 => colors.surfaceWarm;
  Color get transparent => colors.transparent;
  Color get black => colors.black;
  Color get white => colors.white;
  Color get scrim => colors.scrim;
}

extension _CreateExcursionColorContext on BuildContext {
  _CreateExcursionColors get createExcursionColors =>
      _CreateExcursionColors.of(this);
}

class CreateExcursionScreen extends StatefulWidget {
  const CreateExcursionScreen({
    super.key,
    this.excursionId,
    this.initialExcursion,
  });

  final String? excursionId;
  final ExcursionVm? initialExcursion;

  @override
  State<CreateExcursionScreen> createState() => _CreateExcursionScreenState();
}

double _createExcursionLanguageGridMaxHeight(BuildContext context) {
  final height = MediaQuery.sizeOf(context).height;
  return (height * 0.26).clamp(176.0, 248.0).toDouble();
}

double _createExcursionIncludedItemIconBoxSize(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.095).clamp(34.0, 42.0).toDouble();
}

double _modalMaxHeightAboveKeyboard(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final keyboardInset = mediaQuery.viewInsets.bottom;
  final availableHeight =
      mediaQuery.size.height - keyboardInset - mediaQuery.viewPadding.top - 24;
  final preferredHeight = keyboardInset > 0
      ? availableHeight
      : mediaQuery.size.height * 0.88;
  final upperBound = mediaQuery.size.height * 0.92;
  final lowerBound = upperBound < 260 ? upperBound : 260.0;

  return preferredHeight.clamp(lowerBound, upperBound).toDouble();
}

class _CreateExcursionScreenState extends State<CreateExcursionScreen> {
  static const _totalSteps = 3;
  static const _meetingPointStep = _totalSteps - 1;
  static const LatLng _fallbackMapTarget = LatLng(43.238949, 76.889709);
  static const double _stepBackSwipeMinDistance = 56;
  static const double _stepBackSwipeMinVelocity = 700;
  static const int _maxCoverUploadBytes = 20 * 1024 * 1024;
  static const int _maxExcursionPhotos = 10;
  static const int _maxExcursionLanguages = 5;
  static const int _minItinerarySlots = 2;
  static const int _maxItineraryPlaceStops = 5;
  static const String _autosaveKey = 'create_excursion_autosave_v1';
  static const int _autosaveVersion = 1;
  static const Duration _autosaveDebounceDuration = Duration(milliseconds: 650);

  final _pageController = PageController();
  final _imagePicker = ImagePicker();
  final _fileApi = FileApi();
  final _mapLinkResolver = const AppMapLinkResolver();
  var _currentStep = 0;
  int? _pendingProgrammaticStep;
  final Set<int> _nativeMapActivatedSteps = <int>{};
  var _isSubmitting = false;
  var _isLoadingInitialExcursion = false;
  var _didApplyInitialExcursion = false;
  var _didApplyHomeLocation = false;
  String? _editingExcursionStatus;
  String? _serverDraftId;

  final _landmarkNameCtrl = TextEditingController();
  final _cityNameCtrl = TextEditingController();
  final _durationValueCtrl = TextEditingController(text: '4');
  final _maxGroupSizeCtrl = TextEditingController(text: '8');
  final _meetingPointCtrl = TextEditingController();
  final _mapUrlCtrl = TextEditingController();
  final _priceAmountCtrl = TextEditingController();

  var _selectedCategorySlug = 'adventure';
  var _visibility = 'PUBLIC';
  var _selectedDurationUnit = _ExcursionDurationUnit.hours;
  var _selectedCurrencyCode = 'KZT';
  var _creationMode = _ExcursionCreationMode.singlePlace;
  String? _selectedCountryCode;
  String? _departureCityId;
  String? _selectedLandmarkId;
  double? _selectedLatitude;
  double? _selectedLongitude;
  Timer? _mapUrlParseDebounce;
  int _mapUrlResolveSerial = 0;
  String? _mapUrlResolvingRawValue;
  String? _mapUrlResolveFailedRawValue;
  String? _selectedPlaceCoverFileId;
  String? _selectedPlaceCoverImageUrl;
  List<String> _selectedPlacePhotoFileIds = const [];
  List<String> _selectedPlacePhotoImageUrls = const [];
  Map<String, CreateExcursionLocalizedCopyRequest> _productTranslations =
      const {};
  final List<_ExcursionPhotoDraft> _photoDrafts = [];
  Uint8List? _coverPreviewBytes;
  String? _coverFileId;
  String? _existingCoverImageUrl;
  bool _coverChanged = false;
  bool _isCoverUploading = false;
  String? _coverUploadErrorMessage;
  int _coverUploadGeneration = 0;
  int _nextPhotoDraftLocalId = 1;
  bool _isApplyingMapUrlProgrammatically = false;
  bool _isApplyingAutosaveDraft = false;
  bool _didRestoreAutosaveDraft = false;
  bool _autosaveRestored = false;
  bool _isTrackingStepBackSwipe = false;
  double _stepBackSwipeDistance = 0;
  Timer? _autosaveDebounce;
  int _mapSelectionRequestSerial = 0;
  String? _stepErrorText;
  String? _landmarkErrorText;
  String? _itineraryErrorText;
  String? _durationErrorText;
  String? _groupSizeErrorText;
  String? _languagesErrorText;
  String? _meetingPointErrorText;
  String? _mapUrlErrorText;
  String? _priceErrorText;
  String? _currencyErrorText;
  final Set<String> _selectedLanguageCodes = {'en', 'ru'};
  final List<_ExcursionIncludedItemDraft> _includedItems = [];

  final List<_ExcursionItineraryDraft> _itinerary = [];

  @override
  void initState() {
    super.initState();
    _mapUrlCtrl.addListener(_handleMapUrlTextChanged);
    _attachAutosaveListeners();
    if ((widget.excursionId ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExcursionForEdit();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_restoreAutosaveDraft());
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplyInitialExcursion) return;

    _didApplyInitialExcursion = true;
    final initialExcursion = widget.initialExcursion;
    if (initialExcursion != null) {
      _populateFromExcursion(initialExcursion);
    } else if (!_isEditMode && !_didApplyHomeLocation) {
      _didApplyHomeLocation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_applyHomeLocation());
      });
    }
  }

  Future<void> _applyHomeLocation() async {
    final provider = context.read<HomeLocationProvider>();
    if (!provider.isLoaded && !provider.isLoading) {
      try {
        await provider.load(
          languageCode: Localizations.localeOf(context).languageCode,
        );
      } catch (_) {
        // Keep the form usable if device location cannot be resolved.
      }
    }
    if (!mounted) return;

    final location = provider.effectiveLocation;
    if (location.source == HomeLocationSource.fallback) return;

    setState(() {
      _selectedCountryCode ??= (location.countryCode ?? '').trim().isEmpty
          ? null
          : location.countryCode!.trim().toUpperCase();
      _departureCityId = (location.cityId ?? '').trim().isEmpty
          ? null
          : location.cityId!.trim();
      if (_cityNameCtrl.text.trim().isEmpty &&
          (location.cityName ?? '').trim().isNotEmpty) {
        _cityNameCtrl.text = location.cityName!.trim();
      }
    });
    _scheduleAutosave();
  }

  @override
  void dispose() {
    _mapUrlCtrl.removeListener(_handleMapUrlTextChanged);
    _removeAutosaveListeners();
    _autosaveDebounce?.cancel();
    _mapUrlParseDebounce?.cancel();
    _mapUrlResolveSerial += 1;
    _pageController.dispose();
    _landmarkNameCtrl.dispose();
    _cityNameCtrl.dispose();
    _durationValueCtrl.dispose();
    _maxGroupSizeCtrl.dispose();
    _meetingPointCtrl.dispose();
    _mapUrlCtrl.dispose();
    _priceAmountCtrl.dispose();
    super.dispose();
  }

  void _attachAutosaveListeners() {
    for (final controller in _autosaveTextControllers) {
      controller.addListener(_handleAutosaveTextChanged);
    }
  }

  void _removeAutosaveListeners() {
    for (final controller in _autosaveTextControllers) {
      controller.removeListener(_handleAutosaveTextChanged);
    }
  }

  List<TextEditingController> get _autosaveTextControllers => [
    _landmarkNameCtrl,
    _cityNameCtrl,
    _durationValueCtrl,
    _maxGroupSizeCtrl,
    _meetingPointCtrl,
    _mapUrlCtrl,
    _priceAmountCtrl,
  ];

  void _handleAutosaveTextChanged() {
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    if (_isEditMode || _isApplyingAutosaveDraft) return;
    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(_autosaveDebounceDuration, () {
      unawaited(_persistAutosaveDraft());
    });
  }

  Future<void> _persistAutosaveDraft() async {
    if (_isEditMode || _isApplyingAutosaveDraft || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_autosaveKey, jsonEncode(_autosaveDraftPayload()));
  }

  Future<void> _restoreAutosaveDraft() async {
    if (_isEditMode || _didRestoreAutosaveDraft || !mounted) return;
    _didRestoreAutosaveDraft = true;
    final prefs = await SharedPreferences.getInstance();
    final rawDraft = prefs.getString(_autosaveKey);
    if (rawDraft == null || rawDraft.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(rawDraft);
      if (decoded is! Map<String, dynamic>) return;
      if (_intFromDraft(decoded['version']) != _autosaveVersion) return;
      _applyAutosaveDraftPayload(decoded);
      if (!mounted) return;
      setState(() => _autosaveRestored = true);
    } catch (_) {
      await prefs.remove(_autosaveKey);
    }
  }

  Future<void> _clearAutosaveDraft() async {
    _autosaveDebounce?.cancel();
    if (_isEditMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_autosaveKey);
  }

  bool get _hasUnsavedChanges {
    if (_isSubmitting || _isEditMode) {
      return false;
    }

    return _hasNewDraftInput;
  }

  bool get _hasNewDraftInput {
    return _currentStep > 0 ||
        _creationMode != _ExcursionCreationMode.singlePlace ||
        _selectedCategorySlug != 'adventure' ||
        _visibility != 'PUBLIC' ||
        _selectedDurationUnit != _ExcursionDurationUnit.hours ||
        _selectedCurrencyCode != 'KZT' ||
        _landmarkNameCtrl.text.trim().isNotEmpty ||
        (_selectedLandmarkId ?? '').trim().isNotEmpty ||
        (_selectedPlaceCoverFileId ?? '').trim().isNotEmpty ||
        (_selectedPlaceCoverImageUrl ?? '').trim().isNotEmpty ||
        _selectedPlacePhotoFileIds.isNotEmpty ||
        _selectedPlacePhotoImageUrls.isNotEmpty ||
        _durationValueCtrl.text.trim() != '4' ||
        _maxGroupSizeCtrl.text.trim() != '8' ||
        !_hasDefaultLanguageSelection ||
        _meetingPointCtrl.text.trim().isNotEmpty ||
        _mapUrlCtrl.text.trim().isNotEmpty ||
        _priceAmountCtrl.text.trim().isNotEmpty ||
        (_coverFileId ?? '').trim().isNotEmpty ||
        _photoDrafts.isNotEmpty ||
        _coverPreviewBytes != null ||
        _coverChanged ||
        _selectedLatitude != null ||
        _selectedLongitude != null ||
        _productTranslations.isNotEmpty ||
        _includedItems.isNotEmpty ||
        _itinerary.isNotEmpty;
  }

  bool get _hasDefaultLanguageSelection {
    return _selectedLanguageCodes.length == 2 &&
        _selectedLanguageCodes.contains('en') &&
        _selectedLanguageCodes.contains('ru');
  }

  Map<String, dynamic> _autosaveDraftPayload() {
    return {
      'version': _autosaveVersion,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'serverDraftId': _serverDraftId,
      'currentStep': _currentStep,
      'creationMode': _creationMode.name,
      'selectedCategorySlug': _selectedCategorySlug,
      'visibility': _visibility,
      'selectedDurationUnit': _selectedDurationUnit.name,
      'selectedCurrencyCode': _selectedCurrencyCode,
      'selectedCountryCode': _selectedCountryCode,
      'departureCityId': _departureCityId,
      'selectedLandmarkId': _selectedLandmarkId,
      'selectedLatitude': _selectedLatitude,
      'selectedLongitude': _selectedLongitude,
      'selectedPlaceCoverFileId': _selectedPlaceCoverFileId,
      'selectedPlaceCoverImageUrl': _selectedPlaceCoverImageUrl,
      'selectedPlacePhotoFileIds': _selectedPlacePhotoFileIds,
      'selectedPlacePhotoImageUrls': _selectedPlacePhotoImageUrls,
      'coverFileId': _coverFileId,
      'photoFileIds': _offerPhotoFileIds,
      'coverChanged': _coverChanged,
      'productTranslations': _productTranslations.map(
        (locale, copy) => MapEntry(locale, copy.toJson()),
      ),
      'selectedLanguageCodes': _selectedLanguageCodes.toList(growable: false),
      'includedItems': _includedItems
          .map((item) => item.toPayload())
          .toList(growable: false),
      'itinerary': _itinerary
          .map(_itineraryDraftToJson)
          .toList(growable: false),
      'text': {
        'landmarkName': _landmarkNameCtrl.text,
        'cityName': _cityNameCtrl.text,
        'durationValue': _durationValueCtrl.text,
        'maxGroupSize': _maxGroupSizeCtrl.text,
        'meetingPoint': _meetingPointCtrl.text,
        'mapUrl': _mapUrlCtrl.text,
        'priceAmount': _priceAmountCtrl.text,
      },
    };
  }

  void _applyAutosaveDraftPayload(Map<String, dynamic> draft) {
    final text = draft['text'];
    final restoredStep = (_intFromDraft(draft['currentStep']) ?? 0).clamp(
      0,
      _totalSteps - 1,
    );
    if (restoredStep == _meetingPointStep) {
      _pendingProgrammaticStep = restoredStep;
    }
    _isApplyingAutosaveDraft = true;
    setState(() {
      _currentStep = restoredStep;
      _serverDraftId = _stringFromDraft(draft['serverDraftId']);
      _creationMode = _enumFromDraft(
        _ExcursionCreationMode.values,
        _stringFromDraft(draft['creationMode']),
        _creationMode,
      );
      _selectedCategorySlug =
          _stringFromDraft(draft['selectedCategorySlug']) ??
          _selectedCategorySlug;
      _visibility = _stringFromDraft(draft['visibility']) ?? _visibility;
      _selectedDurationUnit = _enumFromDraft(
        _ExcursionDurationUnit.values,
        _stringFromDraft(draft['selectedDurationUnit']),
        _selectedDurationUnit,
      );
      _selectedCurrencyCode =
          _stringFromDraft(draft['selectedCurrencyCode']) ??
          _selectedCurrencyCode;
      _selectedCountryCode = _stringFromDraft(draft['selectedCountryCode']);
      _departureCityId = _stringFromDraft(draft['departureCityId']);
      _selectedLandmarkId = _stringFromDraft(draft['selectedLandmarkId']);
      _selectedLatitude = _doubleFromDraft(draft['selectedLatitude']);
      _selectedLongitude = _doubleFromDraft(draft['selectedLongitude']);
      _selectedPlaceCoverFileId = _stringFromDraft(
        draft['selectedPlaceCoverFileId'],
      );
      _selectedPlaceCoverImageUrl = _stringFromDraft(
        draft['selectedPlaceCoverImageUrl'],
      );
      _selectedPlacePhotoFileIds = _stringListFromDraft(
        draft['selectedPlacePhotoFileIds'],
      );
      _selectedPlacePhotoImageUrls = _stringListFromDraft(
        draft['selectedPlacePhotoImageUrls'],
      );
      _coverFileId = _stringFromDraft(draft['coverFileId']);
      _photoDrafts
        ..clear()
        ..addAll(
          _stringListFromDraft(draft['photoFileIds']).map(
            (fileId) => _ExcursionPhotoDraft(
              localId: _nextPhotoDraftLocalId++,
              fileId: fileId,
              imageUrl: resolvePublicFileContentUrl(fileId),
            ),
          ),
        );
      _coverChanged = draft['coverChanged'] == true && _coverFileId != null;
      _syncCoverFromPhotoDrafts();
      _productTranslations = _localizedCopyDraftMapFromJson(
        draft['productTranslations'],
      );
      _selectedLanguageCodes
        ..clear()
        ..addAll(_stringListFromDraft(draft['selectedLanguageCodes']));
      if (_selectedLanguageCodes.isEmpty) {
        _selectedLanguageCodes.addAll(const ['en', 'ru']);
      }
      _includedItems
        ..clear()
        ..addAll(
          _stringListFromDraft(
            draft['includedItems'],
          ).map(_ExcursionIncludedItemDraft.fromPayload),
        );
      _itinerary
        ..clear()
        ..addAll(_itineraryDraftsFromJson(draft['itinerary']));
      if (text is Map<String, dynamic>) {
        _landmarkNameCtrl.text = _stringFromDraft(text['landmarkName']) ?? '';
        _cityNameCtrl.text = _stringFromDraft(text['cityName']) ?? '';
        _durationValueCtrl.text =
            _stringFromDraft(text['durationValue']) ?? '4';
        _maxGroupSizeCtrl.text = _stringFromDraft(text['maxGroupSize']) ?? '8';
        _meetingPointCtrl.text = _stringFromDraft(text['meetingPoint']) ?? '';
        _setMapUrlText(_stringFromDraft(text['mapUrl']) ?? '');
        _priceAmountCtrl.text = _stringFromDraft(text['priceAmount']) ?? '';
      }
      _clearFieldValidationErrors();
      _stepErrorText = null;
    });
    _pageController.jumpToPage(_currentStep);
    _schedulePendingPageSettleFallback();
    _isApplyingAutosaveDraft = false;
  }

  Map<String, dynamic> _itineraryDraftToJson(_ExcursionItineraryDraft item) {
    return {
      'startOffsetMinutes': item.startOffsetMinutes,
      'countryCode': item.countryCode,
      'durationMinutes': item.durationMinutes,
      'placeId': item.placeId,
      'placeName': item.placeName,
      'latitude': item.latitude,
      'longitude': item.longitude,
      'travelFromPreviousMinutes': item.travelFromPreviousMinutes,
      'title': item.title,
      'description': item.description,
    };
  }

  List<_ExcursionItineraryDraft> _itineraryDraftsFromJson(Object? rawItems) {
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map((item) {
          return _ExcursionItineraryDraft(
            startOffsetMinutes: _intFromDraft(item['startOffsetMinutes']) ?? 0,
            countryCode: _stringFromDraft(item['countryCode']),
            durationMinutes: _intFromDraft(item['durationMinutes']),
            placeId: _stringFromDraft(item['placeId']),
            placeName: _stringFromDraft(item['placeName']),
            latitude: _doubleFromDraft(item['latitude']),
            longitude: _doubleFromDraft(item['longitude']),
            travelFromPreviousMinutes: _intFromDraft(
              item['travelFromPreviousMinutes'],
            ),
            title: _stringFromDraft(item['title']) ?? '',
            description: _stringFromDraft(item['description']) ?? '',
          );
        })
        .toList(growable: false);
  }

  Map<String, CreateExcursionLocalizedCopyRequest>
  _localizedCopyDraftMapFromJson(Object? rawMap) {
    if (rawMap is! Map<String, dynamic>) return const {};
    final result = <String, CreateExcursionLocalizedCopyRequest>{};
    rawMap.forEach((locale, rawCopy) {
      if (rawCopy is! Map<String, dynamic>) return;
      final normalizedLocale = locale.trim().toLowerCase();
      if (normalizedLocale.isEmpty) return;
      result[normalizedLocale] = CreateExcursionLocalizedCopyRequest(
        title: _stringFromDraft(rawCopy['title']),
        summary: _stringFromDraft(rawCopy['summary']),
        description: _stringFromDraft(rawCopy['description']),
      );
    });
    return result;
  }

  List<String> _stringListFromDraft(Object? rawItems) {
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  String? _stringFromDraft(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _intFromDraft(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  double? _doubleFromDraft(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  T _enumFromDraft<T extends Enum>(
    Iterable<T> values,
    String? name,
    T fallback,
  ) {
    if (name == null) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  bool get _isEditMode => (widget.excursionId ?? '').trim().isNotEmpty;

  bool get _canSubmitEditedExcursionForReview {
    if (!_isEditMode) return false;
    final status = (_editingExcursionStatus ?? '').trim().toUpperCase();
    return status == 'DRAFT' || status == 'REJECTED';
  }

  bool get _hasFieldValidationErrors =>
      _landmarkErrorText != null ||
      _itineraryErrorText != null ||
      _durationErrorText != null ||
      _groupSizeErrorText != null ||
      _languagesErrorText != null ||
      _meetingPointErrorText != null ||
      _priceErrorText != null ||
      _mapUrlErrorText != null ||
      _currencyErrorText != null;

  void _clearFieldValidationErrors() {
    _landmarkErrorText = null;
    _itineraryErrorText = null;
    _durationErrorText = null;
    _groupSizeErrorText = null;
    _languagesErrorText = null;
    _meetingPointErrorText = null;
    _mapUrlErrorText = null;
    _priceErrorText = null;
    _currencyErrorText = null;
  }

  void _clearOfferMediaErrors() {
    _landmarkErrorText = null;
    _itineraryErrorText = null;
  }

  void _clearLogisticsErrors() {
    _durationErrorText = null;
    _groupSizeErrorText = null;
    _languagesErrorText = null;
  }

  void _clearStoryAndPriceErrors() {
    _meetingPointErrorText = null;
    _mapUrlErrorText = null;
    _priceErrorText = null;
    _currencyErrorText = null;
  }

  List<Widget> _visibleStepPages(AppLocalizations l10n, double bottomInset) {
    if (_isEditMode) {
      return [
        _buildStepOfferMediaAndItinerary(l10n, bottomInset),
        _buildStepLogistics(l10n, bottomInset),
        _buildStepStoryAndPrice(l10n, bottomInset),
      ];
    }

    return [
      _buildStepLandmark(l10n, bottomInset),
      _buildStepLogistics(l10n, bottomInset),
      _buildStepStoryAndPrice(l10n, bottomInset),
    ];
  }

  Future<void> _loadExcursionForEdit() async {
    final excursionId = (widget.excursionId ?? '').trim();
    if (excursionId.isEmpty || _isLoadingInitialExcursion) return;
    setState(() => _isLoadingInitialExcursion = true);
    final excursion = await context
        .read<ExcursionProvider>()
        .loadMyExcursionForEdit(excursionId);
    if (!mounted) return;
    if (excursion != null) {
      _populateFromExcursion(excursion);
    }
    setState(() => _isLoadingInitialExcursion = false);
  }

  void _populateFromExcursion(ExcursionVm excursion) {
    _editingExcursionStatus = excursion.status.trim().toUpperCase();
    _creationMode = excursion.routeKind.trim().toUpperCase() == 'COMBINED_ROUTE'
        ? _ExcursionCreationMode.combinedRoute
        : _ExcursionCreationMode.singlePlace;
    _selectedLandmarkId = (excursion.landmarkId ?? '').trim().isEmpty
        ? null
        : excursion.landmarkId!.trim();
    _selectedCountryCode = (excursion.countryCode ?? '').trim().isEmpty
        ? null
        : excursion.countryCode!.trim().toUpperCase();
    _departureCityId = (excursion.departureCityId ?? '').trim().isEmpty
        ? null
        : excursion.departureCityId!.trim();
    _selectedLatitude = excursion.latitude;
    _selectedLongitude = excursion.longitude;
    _selectedCategorySlug = (excursion.categorySlug ?? '').trim().isEmpty
        ? _selectedCategorySlug
        : excursion.categorySlug!.trim();
    _visibility = excursion.visibility.trim().isEmpty
        ? _visibility
        : excursion.visibility;
    _selectedCurrencyCode = excursion.currency.trim().isEmpty
        ? _selectedCurrencyCode
        : excursion.currency;
    _landmarkNameCtrl.text = (excursion.landmarkName ?? '').trim();
    _cityNameCtrl.text = (excursion.cityName ?? '').trim();
    if (excursion.durationMinutes > 0) {
      _setDurationFromMinutes(excursion.durationMinutes);
    }
    _maxGroupSizeCtrl.text = excursion.maxGroupSize > 0
        ? excursion.maxGroupSize.toString()
        : _maxGroupSizeCtrl.text;
    _meetingPointCtrl.text = excursion.meetingPoint.trim();
    _setMapUrlText((excursion.mapUrl ?? '').trim());
    _priceAmountCtrl.text = excursion.priceAmount > 0
        ? _formatNumberInput(excursion.priceAmount)
        : '';
    _coverFileId = (excursion.coverFileId ?? '').trim().isEmpty
        ? null
        : excursion.coverFileId!.trim();
    _photoDrafts
      ..clear()
      ..addAll(
        excursion.photoFileIds.map(
          (fileId) => _ExcursionPhotoDraft(
            localId: _nextPhotoDraftLocalId++,
            fileId: fileId,
            imageUrl: resolvePublicFileContentUrl(fileId),
          ),
        ),
      );
    if (_photoDrafts.isEmpty && _coverFileId != null) {
      _photoDrafts.add(
        _ExcursionPhotoDraft(
          localId: _nextPhotoDraftLocalId++,
          fileId: _coverFileId,
          imageUrl: resolvePublicFileContentUrl(_coverFileId!),
        ),
      );
    }
    final existingCoverImageUrl = (resolveExcursionCoverUrl(excursion) ?? '')
        .trim();
    _existingCoverImageUrl = existingCoverImageUrl.isEmpty
        ? null
        : existingCoverImageUrl;
    _coverChanged = _coverFileId != null;
    _syncCoverFromPhotoDrafts();
    _selectedLanguageCodes
      ..clear()
      ..addAll(
        excursion.languageCodes
            .map((code) => code.trim().toLowerCase())
            .where((code) => code.isNotEmpty),
      );
    _includedItems
      ..clear()
      ..addAll(_uniqueIncludedItemDrafts(excursion.includedItems));
    if (excursion.itinerary.isNotEmpty) {
      _itinerary
        ..clear()
        ..addAll(
          excursion.itinerary.map(
            (item) => _ExcursionItineraryDraft(
              startOffsetMinutes: item.startOffsetMinutes,
              durationMinutes: item.durationMinutes,
              title: item.localizedTitle(
                Localizations.localeOf(context).languageCode,
              ),
              description: item.localizedDescription(
                Localizations.localeOf(context).languageCode,
              ),
              countryCode: excursion.countryCode,
              placeId: item.placeId,
              placeName: item.placeName,
              latitude: item.latitude,
              longitude: item.longitude,
              travelFromPreviousMinutes: item.travelFromPreviousMinutes,
            ),
          ),
        );
    }
  }

  String _formatNumberInput(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  void _goToStep(int step) {
    if (_pendingProgrammaticStep != null) return;
    if (step < 0 || step >= _totalSteps || step == _currentStep) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _pendingProgrammaticStep = step;
    setState(() {
      _currentStep = step;
      _stepErrorText = null;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    _scheduleAutosave();
  }

  void _nextStep() {
    if (_pendingProgrammaticStep != null) return;
    if (!_validateCurrentStep()) {
      return;
    }
    if (_currentStep == _totalSteps - 1) {
      _submit(submitForReview: !_isEditMode);
      return;
    }
    _goToStep(_currentStep + 1);
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
    if (_currentStep == step && pendingStep == null) {
      return;
    }
    setState(() {
      _currentStep = step;
      if (_pendingProgrammaticStep == step) {
        _pendingProgrammaticStep = null;
      }
      if (step == _meetingPointStep) {
        _nativeMapActivatedSteps.add(_meetingPointStep);
      }
    });
  }

  void _schedulePendingPageSettleFallback() {
    final pendingStep = _pendingProgrammaticStep;
    if (pendingStep == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingProgrammaticStep != pendingStep) return;
      _handlePageChanged(pendingStep);
    });
  }

  bool _validateCurrentStep() {
    final l10n = AppLocalizations.of(context)!;
    if (_isEditMode && _currentStep == 0) {
      _clearOfferMediaErrors();
    } else if (!_isEditMode && _currentStep == 0) {
      _clearOfferMediaErrors();
    } else if (_currentStep == 1) {
      _clearLogisticsErrors();
    } else {
      _clearStoryAndPriceErrors();
    }
    final error = _isEditMode
        ? _validateEditStep(l10n)
        : switch (_currentStep) {
            0 => _validateLandmarkStep(l10n),
            1 => _validateLogisticsStep(l10n),
            _ => _validateStoryAndPriceStep(l10n),
          };
    setState(() => _stepErrorText = error);
    return error == null;
  }

  String? _validateEditStep(AppLocalizations l10n) {
    return switch (_currentStep) {
      0 => _validateOfferMediaAndItineraryStep(l10n),
      1 => _validateLogisticsStep(l10n),
      _ => _validateStoryAndPriceStep(l10n),
    };
  }

  String? _validateOfferMediaAndItineraryStep(AppLocalizations l10n) {
    if (_isCoverUploading || _hasUploadingPhotos) {
      return l10n.createCoverUploadInProgress;
    }
    if (_hasFailedPhotoUploads ||
        (_coverChanged && (_coverFileId ?? '').trim().isEmpty)) {
      return l10n.createCoverUploadRetryRequired;
    }
    return _validateItinerary(l10n);
  }

  String? _validateItinerary(AppLocalizations l10n) {
    if (_itinerary.any((item) => item.description.trim().length < 5)) {
      _itineraryErrorText = l10n
          .createExcursionItineraryDescriptionMinLengthValidation(5);
      return _itineraryErrorText;
    }
    if (_itinerary.any((item) => item.title.trim().length < 2)) {
      _itineraryErrorText = l10n.createExcursionItineraryValidation;
      return _itineraryErrorText;
    }
    if (_itinerary.length < _minItinerarySlots) {
      _itineraryErrorText = l10n.createExcursionItineraryMinSlotsValidation(
        _minItinerarySlots,
      );
      return _itineraryErrorText;
    }
    if (_creationMode == _ExcursionCreationMode.combinedRoute) {
      final placeStopCount = _itineraryPlaceStopCount;
      if (_itinerary.length > _maxItineraryPlaceStops ||
          placeStopCount > _maxItineraryPlaceStops) {
        _itineraryErrorText = l10n
            .createExcursionCombinedRouteMaxStopsValidation(
              _maxItineraryPlaceStops,
            );
        return _itineraryErrorText;
      }
      if (_itinerary.length < _minItinerarySlots ||
          placeStopCount < _minItinerarySlots ||
          placeStopCount != _itinerary.length) {
        _itineraryErrorText = l10n
            .createExcursionCombinedRouteMinStopsValidation(_minItinerarySlots);
        return _itineraryErrorText;
      }
    }
    return null;
  }

  String? _validateLandmarkStep(AppLocalizations l10n) {
    if (_creationMode == _ExcursionCreationMode.singlePlace &&
        !_hasSelectedPlace) {
      _landmarkErrorText = l10n.createExcursionLandmarkValidation;
      return _landmarkErrorText;
    }
    final offerMediaError = _validateOfferMediaAndItineraryStep(l10n);
    if (offerMediaError != null) {
      return offerMediaError;
    }
    return null;
  }

  String? _validateLogisticsStep(AppLocalizations l10n) {
    final durationMinutes = _durationMinutesFromInput();
    final groupSize = int.tryParse(_maxGroupSizeCtrl.text.trim());

    if (durationMinutes == null || durationMinutes < 15) {
      _durationErrorText = l10n.createExcursionDurationValidation;
      return _durationErrorText;
    }
    if (groupSize == null || groupSize < 1 || groupSize > 100) {
      _groupSizeErrorText = l10n.createExcursionGroupSizeValidation;
      return _groupSizeErrorText;
    }
    if (_selectedLanguageCodes.isEmpty) {
      _languagesErrorText = l10n.createExcursionLanguagesValidation;
      return _languagesErrorText;
    }
    return null;
  }

  String? _validateStoryAndPriceStep(AppLocalizations l10n) {
    if (_isCoverUploading || _hasUploadingPhotos) {
      return l10n.createCoverUploadInProgress;
    }
    if (_hasFailedPhotoUploads ||
        (_coverChanged && (_coverFileId ?? '').trim().isEmpty)) {
      return l10n.createCoverUploadRetryRequired;
    }
    final mapUrlError = _validateMapUrlField(l10n, required: true);
    if (mapUrlError != null) {
      _mapUrlErrorText = mapUrlError;
      return _mapUrlErrorText;
    }
    if (_meetingPointCtrl.text.trim().isEmpty) {
      _meetingPointErrorText = l10n.createLocationValidation;
      return _meetingPointErrorText;
    }
    final price = double.tryParse(_priceAmountCtrl.text.trim());
    if (price == null || price < 0) {
      _priceErrorText = l10n.createPriceValidation;
      return _priceErrorText;
    }
    if (_selectedCurrencyCode.trim().isEmpty) {
      _currencyErrorText = l10n.createExcursionCurrencyValidation;
      return _currencyErrorText;
    }
    return null;
  }

  String? _validateAllStepsBeforeSubmit(AppLocalizations l10n) {
    if (_isEditMode) {
      final offerMediaError = _validateOfferMediaAndItineraryStep(l10n);
      if (offerMediaError != null) {
        return offerMediaError;
      }
    } else {
      final landmarkError = _validateLandmarkStep(l10n);
      if (landmarkError != null) {
        return landmarkError;
      }
    }

    final logisticsError = _validateLogisticsStep(l10n);
    if (logisticsError != null) {
      return logisticsError;
    }
    return _validateStoryAndPriceStep(l10n);
  }

  Future<void> _submit({bool submitForReview = true}) async {
    final l10n = AppLocalizations.of(context)!;
    _clearFieldValidationErrors();
    final validationError = _validateAllStepsBeforeSubmit(l10n);
    if (validationError != null || _isSubmitting) {
      setState(() => _stepErrorText = validationError);
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<ExcursionProvider>();
    final request = _buildRequest();
    ExcursionVm? saved;
    String? submissionErrorMessage;
    var submissionHandled = false;
    if (_isEditMode) {
      final excursionId = widget.excursionId!.trim();
      saved = await provider.updateExcursionOffer(excursionId, request);
      if (saved != null && submitForReview) {
        saved = await provider.submitExcursionForPublishing(excursionId);
      }
    } else {
      final result = await _saveNewExcursion(
        provider: provider,
        request: request,
        submitForReview: submitForReview,
        l10n: l10n,
      );
      saved = result.excursion;
      submissionErrorMessage = result.errorMessage;
      submissionHandled = result.handled;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (submissionHandled) return;

    if (saved != null) {
      _editingExcursionStatus = saved.status.trim().toUpperCase();
      await _clearAutosaveDraft();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            submitForReview
                ? l10n.createExcursionSuccess
                : _isEditMode
                ? l10n.createExcursionUpdateSuccess
                : l10n.createExcursionDraftSaved,
          ),
        ),
      );
      if (context.canPop()) {
        context.pop(saved);
      } else {
        context.go('/profile/guide-dashboard');
      }
      return;
    }

    await showErrorDialog(
      context,
      title: l10n.error,
      message:
          submissionErrorMessage ??
          provider.actionErrorMessage ??
          (_isEditMode
              ? l10n.createExcursionUpdateFailed
              : l10n.createExcursionFailed),
    );
  }

  Future<({ExcursionVm? excursion, String? errorMessage, bool handled})>
  _saveNewExcursion({
    required ExcursionProvider provider,
    required CreateExcursionRequest request,
    required bool submitForReview,
    required AppLocalizations l10n,
  }) async {
    var draftId = (_serverDraftId ?? '').trim();
    ExcursionVm? draft;

    if (draftId.isNotEmpty) {
      final current = await provider.loadMyExcursionForEdit(draftId);
      if (!mounted) {
        return (excursion: null, errorMessage: null, handled: true);
      }
      if (current == null) {
        return (excursion: null, errorMessage: null, handled: false);
      }
      if (_isExcursionSubmissionComplete(current)) {
        return (excursion: current, errorMessage: null, handled: false);
      }
      if (!_isEditableServerDraft(current)) {
        await showErrorDialog(
          context,
          title: l10n.createExcursionExistingDraftTitle,
          message: l10n.createExcursionExistingActiveDescription,
        );
        return (excursion: null, errorMessage: null, handled: true);
      }
      draft = await provider.updateExcursionOffer(draftId, request);
    } else {
      draft = await provider.createDraftExcursion(request);
      if (draft == null && provider.hasActiveExcursionForPlaceConflict) {
        final existing = await provider.findActiveExcursionForCreateRequest(
          request,
        );
        if (!mounted) {
          return (excursion: null, errorMessage: null, handled: true);
        }
        if (existing != null) {
          if (!_isEditableServerDraft(existing)) {
            await showErrorDialog(
              context,
              title: l10n.createExcursionExistingDraftTitle,
              message: l10n.createExcursionExistingActiveDescription,
            );
            return (excursion: null, errorMessage: null, handled: true);
          }

          final shouldRecover = await _showExcursionAmberConfirmDialog(
            title: l10n.createExcursionExistingDraftTitle,
            description: submitForReview
                ? l10n.createExcursionExistingDraftDescription
                : l10n.createExcursionExistingDraftSaveDescription,
            cancelLabel: l10n.cancelButton,
            confirmLabel: submitForReview
                ? l10n.createExcursionExistingDraftConfirm
                : l10n.createExcursionExistingDraftSaveConfirm,
          );
          if (!mounted || !shouldRecover) {
            return (excursion: null, errorMessage: null, handled: true);
          }

          draftId = editableGuideExcursionId(existing);
          await _rememberServerDraft(draftId);
          draft = await provider.updateExcursionOffer(draftId, request);
        }
      } else if (draft != null) {
        draftId = editableGuideExcursionId(draft);
        await _rememberServerDraft(draftId);
      }
    }

    if (draft == null) {
      return (excursion: null, errorMessage: null, handled: false);
    }
    if (!submitForReview) {
      return (excursion: draft, errorMessage: null, handled: false);
    }
    if (draftId.isEmpty) {
      return (
        excursion: null,
        errorMessage: l10n.createExcursionFailed,
        handled: false,
      );
    }

    final submitted = await provider.submitExcursionForPublishing(draftId);
    if (submitted != null) {
      return (excursion: submitted, errorMessage: null, handled: false);
    }
    final cause = provider.actionErrorMessage ?? l10n.createExcursionFailed;
    return (
      excursion: null,
      errorMessage: l10n.createExcursionDraftSubmitFailed(cause),
      handled: false,
    );
  }

  Future<void> _rememberServerDraft(String excursionId) async {
    final normalized = excursionId.trim();
    if (normalized.isEmpty) return;
    _serverDraftId = normalized;
    try {
      await _persistAutosaveDraft();
    } catch (_) {
      // The in-memory id still makes retries safe for the current form session.
    }
  }

  bool _isEditableServerDraft(ExcursionVm excursion) {
    return isDraftGuideOffer(excursion) || isRejectedGuideOffer(excursion);
  }

  bool _isExcursionSubmissionComplete(ExcursionVm excursion) {
    final status = excursion.status.trim().toUpperCase();
    return status == 'PUBLISHED' || isReviewGuideOffer(excursion);
  }

  CreateExcursionRequest _buildRequest() {
    final price = double.tryParse(_priceAmountCtrl.text.trim()) ?? 0;
    final isCombinedRoute =
        _creationMode == _ExcursionCreationMode.combinedRoute;
    return CreateExcursionRequest(
      sourceLanguage: Localizations.localeOf(context).languageCode,
      landmarkName: isCombinedRoute ? null : _landmarkNameCtrl.text.trim(),
      landmarkId: isCombinedRoute ? null : _selectedLandmarkId,
      categorySlug: _selectedCategorySlug,
      productTranslations: _productTranslationsForRequest(),
      durationMinutes: _durationMinutesFromInput() ?? 60,
      maxGroupSize: int.tryParse(_maxGroupSizeCtrl.text.trim()) ?? 1,
      languageCodes: _selectedLanguageCodes.toList(growable: false),
      visibility: _visibility,
      meetingPoint: _meetingPointCtrl.text.trim(),
      countryCode: _selectedCountryCode,
      cityName: _cityNameCtrl.text.trim(),
      departureCityId: _departureCityId,
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
      mapUrl: _mapUrlCtrl.text.trim(),
      priceAmount: price,
      currency: _selectedCurrencyCode,
      coverFileId: _offerCoverFileId,
      productCoverFileId: _productCoverFileId,
      productCoverImageUrl: _productCoverImageUrl,
      photoFileIds: _offerPhotoFileIds,
      productPhotoFileIds: _productPhotoFileIds,
      productPhotoImageUrls: _productPhotoImageUrls,
      includedItems: _includedItems
          .map((item) => item.toPayload())
          .toList(growable: false),
      includedItemTranslations: _includedItemTranslationsForRequest(),
      itinerary: _itinerary
          .map(
            (item) => CreateExcursionItineraryItemRequest(
              startOffsetMinutes: item.startOffsetMinutes,
              durationMinutes: item.durationMinutes,
              title: item.title,
              description: item.description,
              placeId: isCombinedRoute ? item.placeId : null,
              placeName: isCombinedRoute ? item.placeName : null,
              latitude: isCombinedRoute ? item.latitude : null,
              longitude: isCombinedRoute ? item.longitude : null,
              travelFromPreviousMinutes: isCombinedRoute
                  ? item.travelFromPreviousMinutes
                  : null,
              translations: _itineraryTranslationsForRequest(item),
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, CreateExcursionLocalizedCopyRequest>
  _productTranslationsForRequest() {
    if (_selectedLandmarkId == null) {
      return const {};
    }
    return _productTranslations;
  }

  Map<String, CreateExcursionLocalizedCopyRequest> _copyLocationTranslations(
    Map<String, ExcursionLocationLocalizedCopy> translations,
  ) {
    if (translations.isEmpty) return const {};
    final result = <String, CreateExcursionLocalizedCopyRequest>{};
    translations.forEach((locale, copy) {
      final normalizedLocale = locale.trim().toLowerCase().replaceAll('_', '-');
      if (normalizedLocale.isEmpty) return;
      result[normalizedLocale] = CreateExcursionLocalizedCopyRequest(
        title: copy.title,
        summary: copy.summary,
        description: copy.description,
      );
    });
    return result;
  }

  Map<String, ExcursionLocationLocalizedCopy> _locationTranslationsForPicker() {
    if (_productTranslations.isEmpty) return const {};
    final result = <String, ExcursionLocationLocalizedCopy>{};
    _productTranslations.forEach((locale, copy) {
      final normalizedLocale = locale.trim().toLowerCase().replaceAll('_', '-');
      if (normalizedLocale.isEmpty) return;
      result[normalizedLocale] = ExcursionLocationLocalizedCopy(
        title: copy.title ?? '',
        summary: copy.summary ?? '',
        description: copy.description ?? '',
      );
    });
    return result;
  }

  Map<String, List<String>> _includedItemTranslationsForRequest() {
    if (_includedItems.isEmpty) return const {};

    return {
      for (final locale in const ['en', 'ru', 'kk'])
        locale: _includedItems
            .map((item) => item.localizedPayload(locale))
            .toList(growable: false),
    };
  }

  Map<String, CreateExcursionItineraryLocalizedCopyRequest>
  _itineraryTranslationsForRequest(_ExcursionItineraryDraft item) {
    final locale = Localizations.localeOf(
      context,
    ).languageCode.trim().toLowerCase();
    if (locale.isEmpty) return const {};
    return {
      locale: CreateExcursionItineraryLocalizedCopyRequest(
        title: item.title,
        description: item.description,
      ),
    };
  }

  int? _durationMinutesFromInput() {
    final value = int.tryParse(_durationValueCtrl.text.trim());
    if (value == null || value <= 0) {
      return null;
    }
    return value * _selectedDurationUnit.minutesMultiplier;
  }

  void _setDurationFromMinutes(int minutes) {
    if (minutes % _ExcursionDurationUnit.days.minutesMultiplier == 0) {
      _selectedDurationUnit = _ExcursionDurationUnit.days;
      _durationValueCtrl.text =
          (minutes ~/ _ExcursionDurationUnit.days.minutesMultiplier).toString();
      return;
    }
    if (minutes % _ExcursionDurationUnit.hours.minutesMultiplier == 0) {
      _selectedDurationUnit = _ExcursionDurationUnit.hours;
      _durationValueCtrl.text =
          (minutes ~/ _ExcursionDurationUnit.hours.minutesMultiplier)
              .toString();
      return;
    }
    _selectedDurationUnit = _ExcursionDurationUnit.minutes;
    _durationValueCtrl.text = minutes.toString();
  }

  void _toggleLanguageCode(String code) {
    final normalized = code.trim().toLowerCase();
    if (normalized.isEmpty) return;

    setState(() {
      if (_selectedLanguageCodes.contains(normalized)) {
        _selectedLanguageCodes.remove(normalized);
        _languagesErrorText = null;
        _stepErrorText = null;
        return;
      }

      if (_selectedLanguageCodes.length >= _maxExcursionLanguages) {
        _stepErrorText = AppLocalizations.of(
          context,
        )!.createExcursionLanguagesLimitValidation(_maxExcursionLanguages);
        return;
      }

      _selectedLanguageCodes.add(normalized);
      _languagesErrorText = null;
      _stepErrorText = null;
    });
    _scheduleAutosave();
  }

  Future<void> _openIncludedItemsEditor() async {
    final result =
        await showAppModalBottomSheet<List<_ExcursionIncludedItemDraft>>(
          context: context,
          isDismissible: true,
          isScrollControlled: true,
          backgroundColor: context.createExcursionColors.transparent,
          builder: (context) =>
              _ExcursionIncludedItemsEditorSheet(initialItems: _includedItems),
        );

    if (result == null || !mounted) return;
    setState(() {
      _includedItems
        ..clear()
        ..addAll(result);
      _stepErrorText = null;
    });
    _scheduleAutosave();
  }

  List<_ExcursionIncludedItemDraft> _uniqueIncludedItemDrafts(
    List<String> values,
  ) {
    final seen = <_ExcursionIncludedItemType>{};
    final items = <_ExcursionIncludedItemDraft>[];
    for (final value in values) {
      final item = _ExcursionIncludedItemDraft.fromPayload(value);
      if (!seen.add(item.type)) continue;
      items.add(item);
    }
    return items;
  }

  bool get _hasSelectedMapPoint =>
      _selectedLatitude != null && _selectedLongitude != null;

  void _clearMeetingPointSelection() {
    _mapUrlParseDebounce?.cancel();
    _mapUrlResolveSerial += 1;
    _mapSelectionRequestSerial += 1;
    _selectedLatitude = null;
    _selectedLongitude = null;
    _meetingPointCtrl.clear();
    _setMapUrlText('');
    _mapUrlResolvingRawValue = null;
    _mapUrlResolveFailedRawValue = null;
    _meetingPointErrorText = null;
    _mapUrlErrorText = null;
    _scheduleAutosave();
  }

  bool get _hasSelectedPlace => (_selectedLandmarkId ?? '').trim().isNotEmpty;

  int get _itineraryPlaceStopCount {
    return _itinerary
        .where((item) => (item.placeId ?? '').trim().isNotEmpty)
        .length;
  }

  void _selectCreationMode(_ExcursionCreationMode mode) {
    if (mode == _creationMode) return;
    unawaited(_selectCreationModeWithConfirmation(mode));
  }

  Future<void> _selectCreationModeWithConfirmation(
    _ExcursionCreationMode mode,
  ) async {
    if (mode == _creationMode) return;

    final previousMode = _creationMode;
    final hasModeSpecificDraft = _hasCreationModeSpecificDraft(previousMode);
    if (hasModeSpecificDraft) {
      final canSwitch = await _confirmCreationModeChangeIfNeeded();
      if (!mounted || !canSwitch) return;
    }

    setState(() {
      if (hasModeSpecificDraft) {
        _clearModeSpecificDraft(previousMode);
      }
      _creationMode = mode;
      _landmarkErrorText = null;
      _itineraryErrorText = null;
      _stepErrorText = null;
    });
    _scheduleAutosave();
  }

  Future<bool> _confirmCreationModeChangeIfNeeded() {
    final l10n = AppLocalizations.of(context)!;
    return _showExcursionAmberConfirmDialog(
      title: l10n.createExcursionModeSwitchTitle,
      description: l10n.createExcursionModeSwitchDescription,
      cancelLabel: l10n.createExcursionModeSwitchCancel,
      confirmLabel: l10n.createExcursionModeSwitchConfirm,
    );
  }

  bool _hasCreationModeSpecificDraft(_ExcursionCreationMode mode) {
    return switch (mode) {
      _ExcursionCreationMode.singlePlace =>
        _hasSelectedPlace ||
            _landmarkNameCtrl.text.trim().isNotEmpty ||
            (_selectedPlaceCoverFileId ?? '').trim().isNotEmpty ||
            (_selectedPlaceCoverImageUrl ?? '').trim().isNotEmpty ||
            _productTranslations.isNotEmpty ||
            _selectedCategorySlug != 'adventure',
      _ExcursionCreationMode.combinedRoute => _itinerary.isNotEmpty,
    };
  }

  void _clearModeSpecificDraft(_ExcursionCreationMode mode) {
    switch (mode) {
      case _ExcursionCreationMode.singlePlace:
        _clearSinglePlaceModeDraft();
      case _ExcursionCreationMode.combinedRoute:
        _clearCombinedRouteModeDraft();
    }
  }

  void _clearSinglePlaceModeDraft() {
    _selectedLandmarkId = null;
    _landmarkNameCtrl.clear();
    _departureCityId = null;
    _cityNameCtrl.clear();
    _selectedPlaceCoverFileId = null;
    _selectedPlaceCoverImageUrl = null;
    _selectedPlacePhotoFileIds = const [];
    _selectedPlacePhotoImageUrls = const [];
    _productTranslations = const {};
    _selectedCategorySlug = 'adventure';
    _landmarkErrorText = null;
  }

  void _clearCombinedRouteModeDraft() {
    _itinerary.clear();
    _itineraryErrorText = null;
  }

  void _replaceCustomCoverWithPlaceCover() {
    _coverUploadGeneration += 1;
    _photoDrafts.clear();
    _coverPreviewBytes = null;
    _coverFileId = null;
    _coverChanged = false;
    _coverUploadErrorMessage = null;
    _isCoverUploading = false;
  }

  String? get _effectiveCoverFileId {
    final customCover = (_primaryPhotoFileId ?? _coverFileId ?? '').trim();
    if (customCover.isNotEmpty) {
      return customCover;
    }
    final placeCover = (_selectedPlaceCoverFileId ?? '').trim();
    return placeCover.isEmpty ? null : placeCover;
  }

  String? get _offerCoverFileId {
    final customCover = (_primaryPhotoFileId ?? _coverFileId ?? '').trim();
    if (customCover.isNotEmpty) {
      return customCover;
    }
    if (!_hasSelectedPlace) {
      return _effectiveCoverFileId;
    }
    return null;
  }

  String? get _productCoverFileId {
    final placeCover = (_selectedPlaceCoverFileId ?? '').trim();
    if (placeCover.isNotEmpty) {
      return placeCover;
    }
    if (!_hasSelectedPlace) {
      final customCover = (_primaryPhotoFileId ?? _coverFileId ?? '').trim();
      return customCover.isEmpty ? null : customCover;
    }
    return null;
  }

  String? get _productCoverImageUrl {
    if (!_hasSelectedPlace) return null;
    final placeImage = (_selectedPlaceCoverImageUrl ?? '').trim();
    return placeImage.isEmpty ? null : placeImage;
  }

  String? get _effectiveCoverImageUrl {
    if (_primaryPhotoPreviewBytes?.isNotEmpty ?? false) {
      return null;
    }
    final primaryPhotoImage = (_primaryPhotoImageUrl ?? '').trim();
    if (primaryPhotoImage.isNotEmpty) {
      return primaryPhotoImage;
    }
    final placeImage = (_selectedPlaceCoverImageUrl ?? '').trim();
    if (placeImage.isNotEmpty) {
      return placeImage;
    }
    final existingImage = (_existingCoverImageUrl ?? '').trim();
    return existingImage.isEmpty ? null : existingImage;
  }

  bool get _hasAnyCoverPreview {
    return (_primaryPhotoPreviewBytes?.isNotEmpty ?? false) ||
        (_effectiveCoverImageUrl?.isNotEmpty ?? false);
  }

  _ExcursionPhotoDraft? get _primaryPhotoDraft =>
      _photoDrafts.isEmpty ? null : _photoDrafts.first;

  Uint8List? get _primaryPhotoPreviewBytes => _primaryPhotoDraft?.previewBytes;

  String? get _primaryPhotoFileId {
    final fileId = (_primaryPhotoDraft?.fileId ?? '').trim();
    return fileId.isEmpty ? null : fileId;
  }

  String? get _primaryPhotoImageUrl {
    final imageUrl = (_primaryPhotoDraft?.imageUrl ?? '').trim();
    return imageUrl.isEmpty ? null : imageUrl;
  }

  List<String> get _offerPhotoFileIds {
    return _uniqueTrimmedStrings(_photoDrafts.map((draft) => draft.fileId));
  }

  List<String> get _productPhotoFileIds {
    if (_hasSelectedPlace) {
      return _selectedPlacePhotoFileIds;
    }
    return _offerPhotoFileIds;
  }

  List<String> get _productPhotoImageUrls {
    if (!_hasSelectedPlace) return const [];
    return _selectedPlacePhotoImageUrls;
  }

  bool get _hasUploadingPhotos =>
      _photoDrafts.any((draft) => draft.isUploading);

  bool get _hasFailedPhotoUploads =>
      _photoDrafts.any((draft) => draft.errorMessage != null);

  List<String> _uniqueTrimmedStrings(Iterable<String?> values) {
    final result = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final normalized = value?.trim() ?? '';
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      result.add(normalized);
    }
    return result;
  }

  LatLng get _selectedMapTarget => _hasSelectedMapPoint
      ? LatLng(_selectedLatitude!, _selectedLongitude!)
      : _fallbackMapTarget;

  String _buildMapUrl(double latitude, double longitude) {
    return AppMapLinks.buildUrl(
      latitude: latitude,
      longitude: longitude,
      title: _landmarkNameCtrl.text,
      subtitle: _meetingPointCtrl.text,
    );
  }

  void _setMapUrlText(String value) {
    _isApplyingMapUrlProgrammatically = true;
    _mapUrlCtrl.text = value;
    _isApplyingMapUrlProgrammatically = false;
  }

  void _handleMapUrlTextChanged() {
    if (_isApplyingMapUrlProgrammatically) {
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
    final coordinateLabel = _buildCoordinateMeetingPointLabel(
      resolvedPoint.latitude,
      resolvedPoint.longitude,
    );
    if (normalizeField && _mapUrlCtrl.text.trim() != normalizedUrl) {
      _setMapUrlText(normalizedUrl);
    }
    setState(() {
      _selectedLatitude = resolvedPoint.latitude;
      _selectedLongitude = resolvedPoint.longitude;
      _meetingPointCtrl.text = coordinateLabel;
      _mapUrlResolvingRawValue = null;
      _mapUrlResolveFailedRawValue = null;
      _mapUrlErrorText = null;
      _meetingPointErrorText = null;
      _stepErrorText = null;
    });
    _scheduleAutosave();
    await _applyParsedMeetingPointAddress(
      position: resolvedPoint,
      mapUrlRequestSerial: requestSerial,
      mapSelectionRequestSerial: mapSelectionRequestSerial,
      syncMapUrlAfterAddress: normalizeField,
    );
    return true;
  }

  String? _validateMapUrlField(AppLocalizations l10n, {bool required = false}) {
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
    _mapUrlResolvingRawValue = null;
    _mapUrlResolveFailedRawValue = null;
    if (rawValue != normalizedUrl) {
      _setMapUrlText(normalizedUrl);
    }
    return null;
  }

  String _buildCoordinateMeetingPointLabel(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  String _composeMeetingPointLabel(Placemark placemark) {
    final parts = <String>[];

    void addPart(String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty && !parts.contains(trimmed)) {
        parts.add(trimmed);
      }
    }

    addPart(placemark.name);
    addPart(placemark.street);
    addPart(placemark.thoroughfare);
    addPart(placemark.subLocality);
    addPart(placemark.locality);

    return parts.join(', ');
  }

  Future<void> _applyParsedMeetingPointAddress({
    required LatLng position,
    required int mapUrlRequestSerial,
    required int mapSelectionRequestSerial,
    required bool syncMapUrlAfterAddress,
  }) {
    return _resolveMeetingPointAddress(
      position: position,
      isCurrentRequest: () =>
          mapUrlRequestSerial == _mapUrlResolveSerial &&
          mapSelectionRequestSerial == _mapSelectionRequestSerial,
      syncMapUrlAfterAddress: syncMapUrlAfterAddress,
    );
  }

  Future<void> _resolveMeetingPointAddress({
    required LatLng position,
    required bool Function() isCurrentRequest,
    required bool syncMapUrlAfterAddress,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted || !isCurrentRequest()) return;

      if (placemarks.isNotEmpty) {
        final address = _composeMeetingPointLabel(placemarks.first);
        if (address.isNotEmpty) {
          setState(() {
            _meetingPointCtrl.text = address;
            if (syncMapUrlAfterAddress) {
              _setMapUrlText(
                _buildMapUrl(position.latitude, position.longitude),
              );
            }
            _meetingPointErrorText = null;
            _stepErrorText = null;
          });
          _scheduleAutosave();
        }
      }
    } catch (_) {
      // Keep coordinates and map link when reverse geocoding is unavailable.
    }
  }

  Future<void> _handleMapTapped(
    LatLng position, {
    String? meetingPointLabel,
  }) async {
    final requestSerial = ++_mapSelectionRequestSerial;
    final coordinateLabel = _buildCoordinateMeetingPointLabel(
      position.latitude,
      position.longitude,
    );
    final selectedMeetingPointLabel = meetingPointLabel?.trim();
    final displayMeetingPointLabel =
        selectedMeetingPointLabel?.isNotEmpty == true
        ? selectedMeetingPointLabel!
        : coordinateLabel;
    final mapUrl = AppMapLinks.buildUrl(
      latitude: position.latitude,
      longitude: position.longitude,
      title: _landmarkNameCtrl.text,
      subtitle: displayMeetingPointLabel,
    );

    setState(() {
      _selectedLatitude = position.latitude;
      _selectedLongitude = position.longitude;
      _setMapUrlText(mapUrl);
      _meetingPointCtrl.text = displayMeetingPointLabel;
      _meetingPointErrorText = null;
      _mapUrlResolvingRawValue = null;
      _mapUrlResolveFailedRawValue = null;
      _mapUrlErrorText = null;
      _stepErrorText = null;
    });
    _scheduleAutosave();

    await _resolveMeetingPointAddress(
      position: position,
      isCurrentRequest: () => requestSerial == _mapSelectionRequestSerial,
      syncMapUrlAfterAddress: true,
    );
  }

  Future<void> _openExpandedMeetingPointMap() async {
    FocusScope.of(context).unfocus();

    final l10n = AppLocalizations.of(context)!;
    final title = _landmarkNameCtrl.text.trim().isNotEmpty
        ? _landmarkNameCtrl.text.trim()
        : l10n.createMeetingPointLocationLabel;
    final subtitle = _meetingPointCtrl.text.trim().isNotEmpty
        ? _meetingPointCtrl.text.trim()
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

    await _handleMapTapped(result.point, meetingPointLabel: result.subtitle);
  }

  Future<void> _pickCoverImage() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isCoverUploading || _hasUploadingPhotos) return;

    FocusScope.of(context).unfocus();
    final availableSlots = _maxExcursionPhotos - _photoDrafts.length;
    if (availableSlots <= 0) {
      return;
    }

    final pickedImages = await _imagePicker.pickMultiImage(
      maxWidth: 2400,
      imageQuality: 92,
    );
    if (pickedImages.isEmpty) {
      return;
    }

    for (final picked in pickedImages.take(availableSlots)) {
      await _uploadPickedExcursionPhoto(picked, l10n);
    }
  }

  Future<void> _uploadPickedExcursionPhoto(
    XFile picked,
    AppLocalizations l10n,
  ) async {
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    if (bytes.isEmpty) {
      setState(() => _coverUploadErrorMessage = l10n.createCoverUploadFailed);
      return;
    }
    if (bytes.lengthInBytes > _maxCoverUploadBytes) {
      setState(() => _coverUploadErrorMessage = l10n.createCoverUploadTooLarge);
      return;
    }

    final contentType = _detectCoverMimeType(bytes);
    if (contentType == null) {
      setState(
        () =>
            _coverUploadErrorMessage = l10n.createCoverUploadUnsupportedFormat,
      );
      return;
    }

    final normalizedName = _normalizeCoverFileName(picked.name, contentType);
    final uploadGeneration = _coverUploadGeneration + 1;
    final draft = _ExcursionPhotoDraft(
      localId: _nextPhotoDraftLocalId++,
      previewBytes: bytes,
      isUploading: true,
    );

    setState(() {
      _coverUploadGeneration = uploadGeneration;
      _coverChanged = true;
      _photoDrafts.add(draft);
      _coverUploadErrorMessage = null;
      _isCoverUploading = true;
      _stepErrorText = null;
      _syncCoverFromPhotoDrafts();
    });

    try {
      final upload = await _fileApi.createExcursionCoverUpload(
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

      if (!mounted || uploadGeneration != _coverUploadGeneration) return;
      setState(() {
        draft.fileId = upload.fileId;
        draft.isUploading = false;
        draft.errorMessage = null;
        _coverUploadErrorMessage = null;
        _syncCoverFromPhotoDrafts();
      });
      _scheduleAutosave();
    } on DioException catch (e) {
      if (!mounted || uploadGeneration != _coverUploadGeneration) return;
      setState(() {
        draft.errorMessage = DioErrorMapper.toMessage(e);
        draft.isUploading = false;
        _coverUploadErrorMessage = draft.errorMessage;
        _syncCoverFromPhotoDrafts();
      });
    } catch (_) {
      if (!mounted || uploadGeneration != _coverUploadGeneration) return;
      setState(() {
        draft.errorMessage = l10n.createCoverUploadFailed;
        draft.isUploading = false;
        _coverUploadErrorMessage = draft.errorMessage;
        _syncCoverFromPhotoDrafts();
      });
    }
  }

  void _syncCoverFromPhotoDrafts() {
    final primary = _primaryPhotoDraft;
    _coverPreviewBytes = primary?.previewBytes;
    _coverFileId = primary?.fileId;
    _coverChanged = _photoDrafts.isNotEmpty;
    _isCoverUploading = _photoDrafts.any((draft) => draft.isUploading);
    _coverUploadErrorMessage = null;
    for (final draft in _photoDrafts) {
      final error = draft.errorMessage;
      if (error == null) continue;
      _coverUploadErrorMessage = error;
      break;
    }
  }

  void _removeExcursionPhoto(_ExcursionPhotoDraft draft) {
    setState(() {
      _photoDrafts.remove(draft);
      _syncCoverFromPhotoDrafts();
      _stepErrorText = null;
    });
    _scheduleAutosave();
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
    final safeBase = baseName.isEmpty ? 'excursion-cover' : baseName;

    final extension = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };

    return '$safeBase.$extension';
  }

  Future<void> _openLocationSelector() async {
    if (_isEditMode) return;

    FocusScope.of(context).unfocus();
    final result = await context.push<ExcursionLocationSelection>(
      '/excursions/create/location',
      extra: ExcursionLocationPickerArgs(
        countryCode: _selectedCountryCode ?? '',
        initialSelection: ExcursionLocationSelection(
          id: _selectedLandmarkId ?? '',
          name: _landmarkNameCtrl.text.trim(),
          countryCode: _selectedCountryCode ?? '',
          cityId: _departureCityId,
          cityName: _cityNameCtrl.text.trim(),
          coverFileId: _selectedPlaceCoverFileId,
          coverImageUrl: _selectedPlaceCoverImageUrl,
          photoFileIds: _selectedPlacePhotoFileIds,
          photoImageUrls: _selectedPlacePhotoImageUrls,
          translations: _locationTranslationsForPicker(),
          categorySlug: _selectedCategorySlug,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _selectedLandmarkId = result.id.trim().isEmpty ? null : result.id.trim();
      _landmarkNameCtrl.text = result.name;
      _selectedCountryCode = result.countryCode.trim().toUpperCase();
      _departureCityId = result.cityId?.trim().isEmpty == false
          ? result.cityId!.trim()
          : null;
      final selectedCityName = (result.cityName ?? '').trim();
      if (selectedCityName.isNotEmpty) {
        _cityNameCtrl.text = selectedCityName;
      } else {
        _cityNameCtrl.clear();
      }
      _selectedPlaceCoverFileId = (result.coverFileId ?? '').trim().isEmpty
          ? null
          : result.coverFileId!.trim();
      _selectedPlaceCoverImageUrl = (result.coverImageUrl ?? '').trim().isEmpty
          ? null
          : result.coverImageUrl!.trim();
      _selectedPlacePhotoFileIds = _uniqueTrimmedStrings(
        result.photoFileIds,
      ).take(_maxExcursionPhotos).toList(growable: false);
      _selectedPlacePhotoImageUrls = _uniqueTrimmedStrings(
        result.photoImageUrls,
      ).take(_maxExcursionPhotos).toList(growable: false);
      _replaceCustomCoverWithPlaceCover();
      _productTranslations = _copyLocationTranslations(result.translations);
      if (result.categorySlug.trim().isNotEmpty) {
        _selectedCategorySlug = result.categorySlug.trim();
      }
      _clearMeetingPointSelection();
      _landmarkErrorText = null;
      _stepErrorText = null;
    });
    _scheduleAutosave();
  }

  Future<void> _openItineraryEditor({_ExcursionItineraryDraft? item}) async {
    final l10n = AppLocalizations.of(context)!;
    final isCombinedRoute =
        _creationMode == _ExcursionCreationMode.combinedRoute;
    final itemIndex = item == null ? -1 : _itinerary.indexOf(item);
    final result = await showAppModalBottomSheet<_ExcursionItineraryDraft>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: context.createExcursionColors.transparent,
      extendToBottom: true,
      builder: (context) => _AddItinerarySlotSheet(
        l10n: l10n,
        initialItem: item,
        enablePlaceSelection: isCombinedRoute,
        countryCode: _selectedCountryCode,
        reservedPlaceIds: _reservedItineraryPlaceIds(item),
      ),
    );
    if (result == null) return;

    setState(() {
      if ((result.countryCode ?? '').trim().isNotEmpty) {
        _selectedCountryCode = result.countryCode!.trim().toUpperCase();
      }
      if (itemIndex >= 0 && itemIndex < _itinerary.length) {
        _itinerary[itemIndex] = result;
      } else {
        _itinerary.add(result);
      }
      _itinerary.sort(
        (left, right) =>
            left.startOffsetMinutes.compareTo(right.startOffsetMinutes),
      );
      _itineraryErrorText = null;
      _stepErrorText = null;
    });
    _scheduleAutosave();
  }

  Set<String> _reservedItineraryPlaceIds(_ExcursionItineraryDraft? item) {
    return _itinerary
        .where((draft) => !identical(draft, item))
        .map((draft) => (draft.placeId ?? '').trim())
        .where((id) => id.isNotEmpty)
        .toSet();
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

    _isTrackingStepBackSwipe =
        details.localPosition.dx <= _stepBackSwipeEdgeWidth(context);
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
      _goToStep(_currentStep - 1);
      return;
    }

    final canDiscard = await _confirmDiscardIfNeeded();
    if (!mounted || !canDiscard) return;

    await _clearAutosaveDraft();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile/guide-dashboard');
    }
  }

  void _handleRoutePopInvoked(bool didPop) {
    if (didPop) return;
    unawaited(_handleRouteBack());
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final l10n = AppLocalizations.of(context)!;
    return _showExcursionAmberConfirmDialog(
      title: l10n.createExcursionDiscardTitle,
      description: l10n.createExcursionDiscardDescription,
      cancelLabel: l10n.cancelButton,
      confirmLabel: l10n.createExcursionDiscardConfirm,
    );
  }

  Future<bool> _showExcursionAmberConfirmDialog({
    required String title,
    required String description,
    required String cancelLabel,
    required String confirmLabel,
  }) async {
    final result = await showAppModalDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _ExcursionAmberConfirmDialog(
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final stepBackSwipeEdgeWidth = _stepBackSwipeEdgeWidth(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handleRoutePopInvoked(didPop),
      child: Scaffold(
        backgroundColor: context.createExcursionColors.background,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: AppBoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: context.createExcursionColors.screenGradientColors,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _ExcursionTopBar(
                        title: _isEditMode
                            ? l10n.createExcursionEditTitle
                            : l10n.createExcursionTitle,
                        onBack: () => unawaited(_handleRouteBack()),
                      ),
                      _ExcursionStepIndicator(
                        currentStep: _currentStep,
                        totalSteps: _totalSteps,
                        onStepTap: (step) {
                          if (step < _currentStep) {
                            _goToStep(step);
                          }
                        },
                      ),
                      if (_stepErrorText != null && !_hasFieldValidationErrors)
                        _InlineError(message: _stepErrorText!),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: _handlePageChanged,
                          physics: const NeverScrollableScrollPhysics(),
                          children: _visibleStepPages(l10n, bottomInset),
                        ),
                      ),
                      _ExcursionBottomActionBar(
                        label: _currentStep == _totalSteps - 1
                            ? (_isEditMode
                                  ? l10n.createExcursionSaveChanges
                                  : l10n.createExcursionSubmit)
                            : l10n.createStepNext,
                        secondaryLabel: _currentStep == _totalSteps - 1
                            ? _isEditMode
                                  ? _canSubmitEditedExcursionForReview
                                        ? l10n.createExcursionSubmit
                                        : null
                                  : l10n.createExcursionSaveDraft
                            : null,
                        secondaryIcon: _isEditMode
                            ? Icons.send_rounded
                            : Icons.save_outlined,
                        isSubmitting: _isSubmitting || _isCoverUploading,
                        onPressed: _nextStep,
                        onSecondaryPressed: _currentStep == _totalSteps - 1
                            ? _isEditMode
                                  ? _canSubmitEditedExcursionForReview
                                        ? () => _submit(submitForReview: true)
                                        : null
                                  : () => _submit(submitForReview: false)
                            : null,
                      ),
                    ],
                  ),
                ),
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
    );
  }

  Widget _buildStepOfferMediaAndItinerary(
    AppLocalizations l10n,
    double bottomInset,
  ) {
    return ListView(
      padding: AppEdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
      children: [
        ..._buildOfferCoverSection(l10n),
        const SizedBox(height: 24),
        ..._buildOfferItinerarySection(l10n),
        const SizedBox(height: 16),
        Text(
          l10n.createExcursionAutosaveHint,
          textAlign: TextAlign.center,
          style: AppTextStyle(
            color: context.createExcursionColors.textMuted,
            fontSize: 12,
          ),
        ),
        if (_autosaveRestored) ...[
          const SizedBox(height: 6),
          Text(
            l10n.createExcursionAutosaveRestored,
            textAlign: TextAlign.center,
            style: AppTextStyle(
              color: context.createExcursionColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildOfferCoverSection(AppLocalizations l10n) {
    return [
      _SectionHeader(title: l10n.createExcursionCoverSection),
      const SizedBox(height: 12),
      _ExcursionCoverUploadCard(
        title: _hasAnyCoverPreview
            ? l10n.createExcursionCoverChangeAction
            : l10n.createExcursionCoverUploadTitle,
        hint: _coverUploadErrorMessage ?? l10n.createExcursionCoverUploadHint,
        imageUrl: _effectiveCoverImageUrl,
        previewBytes: _primaryPhotoPreviewBytes,
        isUploading: _isCoverUploading || _hasUploadingPhotos,
        hasError: _coverUploadErrorMessage != null,
        onTap: _pickCoverImage,
      ),
      if (_photoDrafts.isNotEmpty) ...[
        const SizedBox(height: 12),
        _ExcursionPhotoCarouselDraftStrip(
          photos: List<_ExcursionPhotoDraft>.unmodifiable(_photoDrafts),
          maxPhotos: _maxExcursionPhotos,
          onAddTap: _pickCoverImage,
          onRemoveTap: _removeExcursionPhoto,
        ),
      ],
    ];
  }

  List<Widget> _buildOfferItinerarySection(AppLocalizations l10n) {
    return [
      _SectionHeader(title: l10n.createExcursionDetailedItinerary),
      const SizedBox(height: 12),
      if (_itinerary.isEmpty) ...[
        _ItineraryEmptyState(
          message: l10n.createExcursionItineraryEmpty,
          errorText: _itineraryErrorText,
        ),
        const SizedBox(height: 12),
      ],
      ..._itinerary.map(
        (item) => Padding(
          padding: const AppEdgeInsets.only(bottom: 10),
          child: _ItinerarySlotCard(
            item: item,
            hasError: !_isCompleteItineraryDraft(item),
            onTap: () => _openItineraryEditor(item: item),
            onDelete: () {
              setState(() => _itinerary.remove(item));
              _scheduleAutosave();
            },
          ),
        ),
      ),
      if (_itinerary.isNotEmpty && _itineraryErrorText != null) ...[
        AppInlineFieldError(message: _itineraryErrorText!),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 6),
      _OutlineActionButton(
        icon: Icons.add_rounded,
        label: l10n.createExcursionAddTimeSlot,
        onTap: _openItineraryEditor,
      ),
    ];
  }

  Widget _buildStepLandmark(AppLocalizations l10n, double bottomInset) {
    return ListView(
      padding: AppEdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
      children: [
        _SectionHeader(title: l10n.createExcursionSelectedLandmark),
        const SizedBox(height: 12),
        _CreationModeSelector(
          selectedMode: _creationMode,
          onChanged: _selectCreationMode,
        ),
        if (_creationMode == _ExcursionCreationMode.singlePlace) ...[
          const SizedBox(height: 12),
          _LandmarkSelectionCard(
            landmarkName: _landmarkNameCtrl.text,
            cityName: _cityNameCtrl.text,
            hasSelection: _hasSelectedPlace,
            errorText: _landmarkErrorText,
            onSelectLocation: _openLocationSelector,
          ),
        ],
        const SizedBox(height: 24),
        ..._buildOfferCoverSection(l10n),
        const SizedBox(height: 24),
        ..._buildOfferItinerarySection(l10n),
        const SizedBox(height: 16),
        Text(
          l10n.createExcursionAutosaveHint,
          textAlign: TextAlign.center,
          style: AppTextStyle(
            color: context.createExcursionColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLogistics(AppLocalizations l10n, double bottomInset) {
    return ListView(
      padding: AppEdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
      children: [
        _ExcursionDurationPickerRow(
          controller: _durationValueCtrl,
          selectedUnit: _selectedDurationUnit,
          errorText: _durationErrorText,
          onChanged: (_) => setState(() {
            _durationErrorText = null;
            _stepErrorText = null;
          }),
          onUnitChanged: (unit) {
            setState(() {
              _selectedDurationUnit = unit;
              _durationErrorText = null;
              _stepErrorText = null;
            });
            _scheduleAutosave();
          },
        ),
        const SizedBox(height: 16),
        _ExcursionTextField(
          controller: _maxGroupSizeCtrl,
          label: l10n.createExcursionMaxGroupSizeLabel,
          hint: l10n.createExcursionMaxGroupSizeHint,
          icon: Icons.group_outlined,
          iconColor: context.createExcursionColors.primary,
          keyboardType: TextInputType.number,
          errorText: _groupSizeErrorText,
          onChanged: (_) => setState(() {
            _groupSizeErrorText = null;
            _stepErrorText = null;
          }),
        ),
        const SizedBox(height: 16),
        _ExcursionLanguagePickerField(
          selectedCodes: _selectedLanguageCodes,
          maxSelected: _maxExcursionLanguages,
          onToggle: _toggleLanguageCode,
          label: l10n.createExcursionLanguagesLabel,
          errorText: _languagesErrorText,
        ),
        const SizedBox(height: 26),
        _SectionHeader(title: l10n.createExcursionVisibilityTitle),
        const SizedBox(height: 12),
        _VisibilityCard(
          title: l10n.createVisibilityPublic,
          description: l10n.createExcursionVisibilityPublicDescription,
          icon: Icons.public_rounded,
          selected: _visibility == 'PUBLIC',
          onTap: () {
            setState(() => _visibility = 'PUBLIC');
            _scheduleAutosave();
          },
        ),
        const SizedBox(height: 12),
        _VisibilityCard(
          title: l10n.createVisibilityByLink,
          description: l10n.createExcursionVisibilityUnlistedDescription,
          icon: Icons.link_rounded,
          selected: _visibility == 'UNLISTED',
          onTap: () {
            setState(() => _visibility = 'UNLISTED');
            _scheduleAutosave();
          },
        ),
      ],
    );
  }

  Widget _buildStepStoryAndPrice(AppLocalizations l10n, double bottomInset) {
    return ListView(
      padding: AppEdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
      children: [
        _SectionHeader(title: l10n.createMeetingPointTitle),
        const SizedBox(height: 12),
        _ExcursionTextField(
          controller: _meetingPointCtrl,
          label: l10n.createMeetingPointLocationLabel,
          hint: l10n.createExcursionMeetingPointHint,
          icon: Icons.location_on_outlined,
          iconColor: context.createExcursionColors.primary,
          horizontalScroll: true,
          readOnly: true,
          errorText: _meetingPointErrorText,
          onChanged: (_) => setState(() {
            _meetingPointErrorText = null;
            _stepErrorText = null;
          }),
        ),
        const SizedBox(height: 12),
        _ExcursionTextField(
          controller: _mapUrlCtrl,
          label: l10n.createMapLinkLabel,
          hint: l10n.createMapLinkHint,
          icon: Icons.link_rounded,
          iconColor: context.createExcursionColors.primary,
          keyboardType: TextInputType.url,
          horizontalScroll: true,
          errorText: _mapUrlErrorText,
        ),
        const SizedBox(height: 14),
        Text(
          l10n.createMapEarlyStageNotice,
          style: AppTextStyle(
            color: context.createExcursionColors.textSecondary,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        AppMapCard(
          target: _selectedMapTarget,
          hasMarker: _hasSelectedMapPoint,
          nativeMapEnabled: _isStepNativeMapEnabled(_meetingPointStep),
          onTap: _handleMapTapped,
          overlay: _MapExpandButton(onTap: _openExpandedMeetingPointMap),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.createMapTapHint,
          style: AppTextStyle(
            color: context.createExcursionColors.textMuted,
            fontSize: 12,
          ),
        ),
        _SectionHeader(title: l10n.createExcursionInvestmentTitle),
        const SizedBox(height: 12),
        _ExcursionTextField(
          controller: _priceAmountCtrl,
          label: l10n.createPriceAmountLabel,
          hint: '0.00',
          icon: Icons.payments_outlined,
          iconColor: context.createExcursionColors.primary,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: _priceErrorText,
          onChanged: (_) => setState(() {
            _priceErrorText = null;
            _stepErrorText = null;
          }),
        ),
        const SizedBox(height: 12),
        AppCurrencyPickerField(
          label: l10n.createCurrencyLabel,
          selectedCode: _selectedCurrencyCode,
          errorText: _currencyErrorText,
          onChanged: (value) {
            setState(() {
              _selectedCurrencyCode = value;
              _currencyErrorText = null;
              _stepErrorText = null;
            });
            _scheduleAutosave();
          },
        ),
        const SizedBox(height: 12),
        _SectionHeader(
          title: l10n.createExcursionIncludedItemsLabel,
          actionLabel: l10n.change,
          onActionTap: _openIncludedItemsEditor,
        ),
        const SizedBox(height: 12),
        _ExcursionIncludedItemsPreview(
          items: _includedItems,
          onTap: _openIncludedItemsEditor,
        ),
      ],
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
            color: context.createExcursionColors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppBorderRadius.circular(999),
              child: Ink(
                width: 46,
                height: 46,
                decoration: AppBoxDecoration(
                  shape: BoxShape.circle,
                  color: context.createExcursionColors.background.withValues(
                    alpha: 0.88,
                  ),
                  border: Border.all(
                    color: context.createExcursionColors.primary.withValues(
                      alpha: 0.34,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.createExcursionColors.black.withValues(
                        alpha: 0.18,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.open_in_full_rounded,
                  color: context.createExcursionColors.primary,
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

enum _ExcursionCreationMode { singlePlace, combinedRoute }

enum _ExcursionDurationUnit { minutes, hours, days }

extension _ExcursionDurationUnitUi on _ExcursionDurationUnit {
  int get minutesMultiplier {
    return switch (this) {
      _ExcursionDurationUnit.minutes => 1,
      _ExcursionDurationUnit.hours => 60,
      _ExcursionDurationUnit.days => 24 * 60,
    };
  }

  String label(AppLocalizations l10n) {
    return switch (this) {
      _ExcursionDurationUnit.minutes => l10n.createExcursionDurationUnitMinutes,
      _ExcursionDurationUnit.hours => l10n.createExcursionDurationUnitHours,
      _ExcursionDurationUnit.days => l10n.createExcursionDurationUnitDays,
    };
  }
}

class _ExcursionDurationPickerRow extends StatelessWidget {
  const _ExcursionDurationPickerRow({
    required this.controller,
    required this.selectedUnit,
    required this.onUnitChanged,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final _ExcursionDurationUnit selectedUnit;
  final ValueChanged<_ExcursionDurationUnit> onUnitChanged;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;
        final amountField = _ExcursionTextField(
          controller: controller,
          label: l10n.createExcursionDurationLabel,
          hint: '4',
          icon: Icons.schedule_rounded,
          iconColor: context.createExcursionColors.primary,
          keyboardType: TextInputType.number,
          errorText: errorText,
          onChanged: onChanged,
        );
        final unitField = _DurationUnitPickerField(
          label: l10n.createExcursionDurationUnitLabel,
          selectedUnit: selectedUnit,
          onChanged: onUnitChanged,
        );

        if (isCompact) {
          return Column(
            children: [amountField, const SizedBox(height: 12), unitField],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: amountField),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: unitField),
          ],
        );
      },
    );
  }
}

class _DurationUnitPickerField extends StatelessWidget {
  const _DurationUnitPickerField({
    required this.label,
    required this.selectedUnit,
    required this.onChanged,
  });

  final String label;
  final _ExcursionDurationUnit selectedUnit;
  final ValueChanged<_ExcursionDurationUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _ExcursionFieldShell(
      label: label,
      child: PopupMenuButton<_ExcursionDurationUnit>(
        initialValue: selectedUnit,
        onSelected: onChanged,
        color: context.createExcursionColors.surfaceWarm,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.circular(18),
        ),
        itemBuilder: (context) => [
          for (final unit in _ExcursionDurationUnit.values)
            PopupMenuItem<_ExcursionDurationUnit>(
              value: unit,
              child: Row(
                children: [
                  Icon(
                    unit == selectedUnit
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: unit == selectedUnit
                        ? context.createExcursionColors.primary
                        : context.createExcursionColors.textMuted,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      unit.label(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: context.createExcursionColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const AppEdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: AppBoxDecoration(
            color: context.createExcursionColors.surfaceWarm,
            borderRadius: AppBorderRadius.circular(24),
            border: Border.all(
              color: context.createExcursionColors.primary.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timelapse_rounded,
                color: context.createExcursionColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedUnit.label(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: context.createExcursionColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: context.createExcursionColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcursionItineraryDraft {
  const _ExcursionItineraryDraft({
    required this.startOffsetMinutes,
    required this.title,
    required this.description,
    this.countryCode,
    this.durationMinutes,
    this.placeId,
    this.placeName,
    this.latitude,
    this.longitude,
    this.travelFromPreviousMinutes,
  });

  final int startOffsetMinutes;
  final String? countryCode;
  final int? durationMinutes;
  final String? placeId;
  final String? placeName;
  final double? latitude;
  final double? longitude;
  final int? travelFromPreviousMinutes;
  final String title;
  final String description;
}

bool _isCompleteItineraryDraft(_ExcursionItineraryDraft item) {
  return item.title.trim().length >= 2 && item.description.trim().length >= 5;
}

enum _ExcursionIncludedItemType {
  transport,
  food,
  tickets,
  equipment,
  guide,
  photo,
  other,
}

const _selectableIncludedItemTypes = [
  _ExcursionIncludedItemType.transport,
  _ExcursionIncludedItemType.food,
  _ExcursionIncludedItemType.tickets,
  _ExcursionIncludedItemType.equipment,
  _ExcursionIncludedItemType.guide,
  _ExcursionIncludedItemType.photo,
];

extension _ExcursionIncludedItemTypeUi on _ExcursionIncludedItemType {
  IconData get icon {
    return switch (this) {
      _ExcursionIncludedItemType.transport =>
        Icons.directions_car_filled_rounded,
      _ExcursionIncludedItemType.food => Icons.restaurant_rounded,
      _ExcursionIncludedItemType.tickets => Icons.confirmation_number_rounded,
      _ExcursionIncludedItemType.equipment => Icons.backpack_rounded,
      _ExcursionIncludedItemType.guide => Icons.person_pin_circle_rounded,
      _ExcursionIncludedItemType.photo => Icons.photo_camera_rounded,
      _ExcursionIncludedItemType.other => Icons.check_circle_rounded,
    };
  }

  String label(AppLocalizations l10n) {
    return switch (this) {
      _ExcursionIncludedItemType.transport =>
        l10n.createExcursionIncludedTypeTransport,
      _ExcursionIncludedItemType.food => l10n.createExcursionIncludedTypeFood,
      _ExcursionIncludedItemType.tickets =>
        l10n.createExcursionIncludedTypeTickets,
      _ExcursionIncludedItemType.equipment =>
        l10n.createExcursionIncludedTypeEquipment,
      _ExcursionIncludedItemType.guide => l10n.createExcursionIncludedTypeGuide,
      _ExcursionIncludedItemType.photo => l10n.createExcursionIncludedTypePhoto,
      _ExcursionIncludedItemType.other => l10n.createExcursionIncludedTypeOther,
    };
  }

  String localizedLabel(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    final labels = switch (this) {
      _ExcursionIncludedItemType.transport => const {
        'en': 'Transport',
        'ru': 'Транспорт',
        'kk': 'Көлік',
      },
      _ExcursionIncludedItemType.food => const {
        'en': 'Food',
        'ru': 'Питание',
        'kk': 'Тамақ',
      },
      _ExcursionIncludedItemType.tickets => const {
        'en': 'Tickets',
        'ru': 'Билеты',
        'kk': 'Билеттер',
      },
      _ExcursionIncludedItemType.equipment => const {
        'en': 'Equipment',
        'ru': 'Снаряжение',
        'kk': 'Жабдық',
      },
      _ExcursionIncludedItemType.guide => const {
        'en': 'Guide',
        'ru': 'Гид',
        'kk': 'Гид',
      },
      _ExcursionIncludedItemType.photo => const {
        'en': 'Photo',
        'ru': 'Фото',
        'kk': 'Фото',
      },
      _ExcursionIncludedItemType.other => const {
        'en': 'Other',
        'ru': 'Другое',
        'kk': 'Басқа',
      },
    };
    return labels[normalized] ?? labels[normalized.split('-').first] ?? name;
  }
}

class _ExcursionIncludedItemDraft {
  const _ExcursionIncludedItemDraft({required this.type});

  factory _ExcursionIncludedItemDraft.fromPayload(String rawValue) {
    final value = rawValue.trim();
    final separatorIndex = value.indexOf(':');
    if (separatorIndex > 0) {
      final type = _excursionIncludedItemTypeFromName(
        value.substring(0, separatorIndex).trim(),
      );
      return _ExcursionIncludedItemDraft(type: type);
    }
    return _ExcursionIncludedItemDraft(
      type: _excursionIncludedItemTypeFromName(value),
    );
  }

  final _ExcursionIncludedItemType type;

  String toPayload() => type.name;

  String localizedPayload(String languageCode) =>
      type.localizedLabel(languageCode);
}

_ExcursionIncludedItemType _excursionIncludedItemTypeFromName(String rawValue) {
  final normalized = rawValue.trim().toLowerCase();
  final normalizedWords = normalized
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  for (final type in _ExcursionIncludedItemType.values) {
    if (type.name == normalized || type.name == normalizedWords) {
      return type;
    }
  }
  return switch (normalizedWords) {
    'transport' ||
    'транспорт' ||
    'көлік' => _ExcursionIncludedItemType.transport,
    'food' ||
    'meal' ||
    'meals' ||
    'питание' ||
    'еда' ||
    'тамақ' => _ExcursionIncludedItemType.food,
    'tickets' ||
    'ticket' ||
    'билеты' ||
    'билет' ||
    'билеттер' => _ExcursionIncludedItemType.tickets,
    'equipment' ||
    'gear' ||
    'снаряжение' ||
    'жабдық' => _ExcursionIncludedItemType.equipment,
    'guide' || 'гид' => _ExcursionIncludedItemType.guide,
    'photo' || 'photos' || 'фото' => _ExcursionIncludedItemType.photo,
    _ => _ExcursionIncludedItemType.other,
  };
}

const _excursionLanguagePickerCodes = [
  'en',
  'ru',
  'kk',
  'fr',
  'ja',
  'de',
  'es',
  'tr',
];

String _normalizeLanguageSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[@_.,;:\/\\|()\[\]{}<>+\-=]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _languageSearchHaystack(AppLocalizations l10n, String code) {
  final aliases = switch (code.trim().toLowerCase()) {
    'en' => 'eng english английский анг ағылшын',
    'ru' => 'rus russian русский рус орыс',
    'kk' => 'kz kaz kazakh казахский қазақ қазақша',
    'fr' => 'fre french французский француз',
    'ja' => 'jp japanese японский япон жапон',
    'de' => 'ger german немецкий неміс',
    'es' => 'spa spanish испанский испан',
    'tr' => 'tur turkish турецкий түрік',
    _ => '',
  };

  return _normalizeLanguageSearchText(
    '$code ${localizedExcursionLanguageLabel(l10n, code)} $aliases',
  );
}

class _ExcursionLanguagePickerField extends StatefulWidget {
  const _ExcursionLanguagePickerField({
    required this.selectedCodes,
    required this.maxSelected,
    required this.onToggle,
    required this.label,
    this.errorText,
  });

  final Set<String> selectedCodes;
  final int maxSelected;
  final ValueChanged<String> onToggle;
  final String label;
  final String? errorText;

  @override
  State<_ExcursionLanguagePickerField> createState() =>
      _ExcursionLanguagePickerFieldState();
}

class _ExcursionLanguagePickerFieldState
    extends State<_ExcursionLanguagePickerField> {
  late final TextEditingController _languageSearchController;
  String _languageSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _languageSearchController = TextEditingController()
      ..addListener(_handleLanguageSearchChanged);
  }

  @override
  void dispose() {
    _languageSearchController
      ..removeListener(_handleLanguageSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleLanguageSearchChanged() {
    final nextQuery = _languageSearchController.text.trim();
    if (nextQuery == _languageSearchQuery) return;

    setState(() => _languageSearchQuery = nextQuery);
  }

  List<String> _visibleLanguages(AppLocalizations l10n) {
    final query = _normalizeLanguageSearchText(_languageSearchQuery);
    if (query.isEmpty) return const [];

    final tokens = query
        .split(' ')
        .where((token) => token.trim().isNotEmpty)
        .toList(growable: false);

    return _excursionLanguagePickerCodes
        .where((code) {
          final haystack = _languageSearchHaystack(l10n, code);
          return tokens.every(haystack.contains);
        })
        .toList(growable: false);
  }

  List<String> _selectedLanguages() {
    final ordered = [
      for (final code in _excursionLanguagePickerCodes)
        if (widget.selectedCodes.contains(code)) code,
    ];
    final known = ordered.toSet();
    ordered.addAll(
      widget.selectedCodes
          .where((code) => !known.contains(code))
          .map((code) => code.trim().toLowerCase())
          .where((code) => code.isNotEmpty),
    );
    return ordered;
  }

  void _selectLanguage(String code) {
    final normalized = code.trim().toLowerCase();
    if (normalized.isEmpty) return;

    final isSelected = widget.selectedCodes.contains(normalized);
    final canChange =
        isSelected || widget.selectedCodes.length < widget.maxSelected;

    widget.onToggle(normalized);

    if (!canChange) return;
    _languageSearchController.clear();
    setState(() => _languageSearchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visibleLanguages = _visibleLanguages(l10n);
    final selectedLanguages = _selectedLanguages();
    final maxSelected = widget.maxSelected;

    return _ExcursionFieldShell(
      label: widget.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: AppBoxDecoration(
              color: context.createExcursionColors.surfaceWarm,
              borderRadius: AppBorderRadius.circular(24),
              border: Border.all(
                color: widget.errorText == null
                    ? context.createExcursionColors.primary.withValues(
                        alpha: 0.10,
                      )
                    : context.createExcursionColors.danger,
              ),
            ),
            child: Padding(
              padding: const AppEdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _languageSearchController,
                    cursorColor: context.createExcursionColors.primary,
                    style: AppTextStyle(
                      color: context.createExcursionColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: AppInputDecoration(
                      hintText: l10n.createExcursionLanguagesSearchHint,
                      hintStyle: AppTextStyle(
                        color: context.createExcursionColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: context.createExcursionColors.primary,
                      ),
                      filled: true,
                      fillColor: context.createExcursionColors.background,
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
                        borderSide: BorderSide(
                          color: context.createExcursionColors.white.withValues(
                            alpha: 0.06,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppBorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: context.createExcursionColors.primary,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  if (_languageSearchQuery.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    if (visibleLanguages.isEmpty)
                      Text(
                        l10n.createExcursionLanguagesNoResults,
                        style: AppTextStyle(
                          color: context.createExcursionColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: _createExcursionLanguageGridMaxHeight(
                            context,
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: visibleLanguages.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final code = visibleLanguages[index];
                            final selected = widget.selectedCodes.contains(
                              code,
                            );
                            return _ExcursionLanguageOptionRow(
                              label: localizedExcursionLanguageLabel(
                                l10n,
                                code,
                              ),
                              code: code.toUpperCase(),
                              selected: selected,
                              onTap: () => _selectLanguage(code),
                            );
                          },
                        ),
                      ),
                  ],
                  if (selectedLanguages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final code in selectedLanguages)
                          _ExcursionLanguageChip(
                            label: localizedExcursionLanguageLabel(l10n, code),
                            selected: true,
                            disabled: false,
                            onTap: () => _selectLanguage(code),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    l10n.createExcursionLanguagesPickerHint(maxSelected),
                    style: AppTextStyle(
                      color: context.createExcursionColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.errorText != null)
            AppInlineFieldError(message: widget.errorText!),
        ],
      ),
    );
  }
}

class _ExcursionLanguageOptionRow extends StatelessWidget {
  const _ExcursionLanguageOptionRow({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.createExcursionColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(14),
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            color: selected
                ? context.createExcursionColors.primary.withValues(alpha: 0.18)
                : context.createExcursionColors.surfaceWarm,
            borderRadius: AppBorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? context.createExcursionColors.primary
                  : context.createExcursionColors.white.withValues(alpha: 0.07),
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
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      color: context.createExcursionColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  code,
                  style: AppTextStyle(
                    color: context.createExcursionColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_rounded,
                    color: context.createExcursionColors.primary,
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

class _ExcursionLanguageChip extends StatelessWidget {
  const _ExcursionLanguageChip({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = disabled
        ? context.createExcursionColors.textMuted
        : selected
        ? context.createExcursionColors.white
        : context.createExcursionColors.primary;

    return Material(
      color: selected
          ? context.createExcursionColors.primary
          : context.createExcursionColors.surfaceWarm,
      borderRadius: AppBorderRadius.circular(999),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: AppBorderRadius.circular(999),
        child: Padding(
          padding: const AppEdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(
                  Icons.check_rounded,
                  color: context.createExcursionColors.white,
                  size: 15,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: AppTextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcursionIncludedItemsPreview extends StatelessWidget {
  const _ExcursionIncludedItemsPreview({
    required this.items,
    required this.onTap,
  });

  final List<_ExcursionIncludedItemDraft> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: context.createExcursionColors.surfaceWarm,
      borderRadius: AppBorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 70),
          padding: const AppEdgeInsets.all(14),
          decoration: AppBoxDecoration(
            borderRadius: AppBorderRadius.circular(24),
            border: Border.all(
              color: context.createExcursionColors.primary.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          child: items.isEmpty
              ? Row(
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      color: context.createExcursionColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.createExcursionIncludedItemsEmpty,
                        style: AppTextStyle(
                          color: context.createExcursionColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in items)
                      _ExcursionIncludedItemChip(item: item, l10n: l10n),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ExcursionIncludedItemChip extends StatelessWidget {
  const _ExcursionIncludedItemChip({required this.item, required this.l10n});

  final _ExcursionIncludedItemDraft item;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AppBoxDecoration(
        color: context.createExcursionColors.surfaceWarm,
        borderRadius: AppBorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.type.icon,
            color: context.createExcursionColors.primary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              item.type.label(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(
                color: context.createExcursionColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExcursionIncludedItemsEditorSheet extends StatefulWidget {
  const _ExcursionIncludedItemsEditorSheet({required this.initialItems});

  final List<_ExcursionIncludedItemDraft> initialItems;

  @override
  State<_ExcursionIncludedItemsEditorSheet> createState() =>
      _ExcursionIncludedItemsEditorSheetState();
}

class _ExcursionIncludedItemsEditorSheetState
    extends State<_ExcursionIncludedItemsEditorSheet> {
  late final Set<_ExcursionIncludedItemType> selectedTypes;

  @override
  void initState() {
    super.initState();
    selectedTypes = widget.initialItems
        .map((item) => item.type)
        .where((type) => type != _ExcursionIncludedItemType.other)
        .toSet();
  }

  void _toggleType(_ExcursionIncludedItemType type) {
    setState(() {
      if (selectedTypes.contains(type)) {
        selectedTypes.remove(type);
      } else {
        selectedTypes.add(type);
      }
    });
  }

  void _submit() {
    final items =
        selectedTypes
            .map((type) => _ExcursionIncludedItemDraft(type: type))
            .toList(growable: false)
          ..sort(
            (a, b) => _selectableIncludedItemTypes
                .indexOf(a.type)
                .compareTo(_selectableIncludedItemTypes.indexOf(b.type)),
          );
    Navigator.of(context).pop(items);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.84;

    return AppModalSheetFrame(
      useSafeArea: false,
      onTapOutside: () => Navigator.of(context).maybePop(),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: AppEdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: DecoratedBox(
                  decoration: AppBoxDecoration(
                    color: context.createExcursionColors.surface,
                    borderRadius: AppRadius.sheetTop,
                    border: Border.all(
                      color: context.createExcursionColors.borderSoft,
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 48,
                        height: 5,
                        decoration: AppBoxDecoration(
                          color: context.createExcursionColors.borderSoft,
                          borderRadius: AppBorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const AppEdgeInsets.fromLTRB(18, 18, 10, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.createExcursionIncludedItemsEditorTitle,
                                style: AppTextStyle(
                                  color:
                                      context.createExcursionColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(Icons.close_rounded),
                              color: context.createExcursionColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const AppEdgeInsets.fromLTRB(16, 6, 16, 12),
                          children: [
                            for (final type
                                in _selectableIncludedItemTypes) ...[
                              _ExcursionIncludedTypeOption(
                                type: type,
                                selected: selectedTypes.contains(type),
                                onTap: () => _toggleType(type),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const AppEdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                context.createExcursionColors.primary,
                            foregroundColor:
                                context.createExcursionColors.textPrimary,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppBorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            l10n.saveProfileButton,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExcursionIncludedTypeOption extends StatelessWidget {
  const _ExcursionIncludedTypeOption({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final _ExcursionIncludedItemType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final iconBoxSize = _createExcursionIncludedItemIconBoxSize(context);

    return Material(
      color: selected
          ? context.createExcursionColors.secondaryContainer
          : context.createExcursionColors.surfaceHigh,
      borderRadius: AppBorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(18),
        child: Container(
          padding: const AppEdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: AppBoxDecoration(
            borderRadius: AppBorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? context.createExcursionColors.borderSecondary
                  : context.createExcursionColors.borderSoft,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: AppBoxDecoration(
                  color: selected
                      ? context.createExcursionColors.surface
                      : context.createExcursionColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  type.icon,
                  color: context.createExcursionColors.secondary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  type.label(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: selected
                        ? context.createExcursionColors.secondary
                        : context.createExcursionColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? context.createExcursionColors.secondary
                    : context.createExcursionColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcursionAmberConfirmDialog extends StatelessWidget {
  const _ExcursionAmberConfirmDialog({
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
      insetPadding: const AppEdgeInsets.symmetric(horizontal: 12, vertical: 24),
      backgroundColor: context.createExcursionColors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompactDialog = constraints.maxWidth < 360;
          final icon = Container(
            width: 54,
            height: 54,
            decoration: AppBoxDecoration(
              color: context.createExcursionColors.primary.withValues(
                alpha: 0.18,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.createExcursionColors.primary.withValues(
                  alpha: 0.72,
                ),
              ),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: context.createExcursionColors.primary,
              size: 30,
            ),
          );
          final textContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyle(
                  color: context.createExcursionColors.orangeWash23,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                description,
                style: AppTextStyle(
                  color: context.createExcursionColors.orangeLight13,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.38,
                ),
              ),
            ],
          );
          final header = isCompactDialog
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [icon, const SizedBox(height: 14), textContent],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(width: 14),
                    Expanded(child: textContent),
                  ],
                );

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: AppBoxDecoration(
                  borderRadius: AppBorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.createExcursionColors.warmSurface81,
                      context.createExcursionColors.textOnInverse,
                    ],
                  ),
                  border: Border.all(
                    color: context.createExcursionColors.primary.withValues(
                      alpha: 0.58,
                    ),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.createExcursionColors.black.withValues(
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
                      header,
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onConfirm,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                context.createExcursionColors.primary,
                            foregroundColor:
                                context.createExcursionColors.textPrimary,
                            padding: const AppEdgeInsets.symmetric(
                              vertical: 15,
                            ),
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
                                context.createExcursionColors.orangeLight29,
                            padding: const AppEdgeInsets.symmetric(
                              vertical: 13,
                            ),
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
        },
      ),
    );
  }
}

class _ExcursionTopBar extends StatelessWidget {
  const _ExcursionTopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

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
              child: IconButton(
                onPressed: onBack,
                splashRadius: 20,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: context.createExcursionColors.textPrimary,
                  size: 18,
                ),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
                    color: context.createExcursionColors.textPrimary,
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

class _ExcursionStepIndicator extends StatelessWidget {
  const _ExcursionStepIndicator({
    required this.currentStep,
    required this.totalSteps,
    this.onStepTap,
  });

  final int currentStep;
  final int totalSteps;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const AppEdgeInsets.fromLTRB(28, 8, 28, 14),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            final isDone = index ~/ 2 < currentStep;
            return Expanded(
              child: Container(
                height: 3,
                margin: const AppEdgeInsets.symmetric(horizontal: 10),
                decoration: AppBoxDecoration(
                  color: isDone
                      ? context.createExcursionColors.success
                      : context.createExcursionColors.primary.withValues(
                          alpha: 0.32,
                        ),
                  borderRadius: AppBorderRadius.circular(999),
                ),
              ),
            );
          }
          final step = index ~/ 2;
          final isDone = step < currentStep;
          final isActive = step == currentStep;
          final isStepTappable = onStepTap != null && isDone;
          final stepSize = isActive ? 48.0 : (isDone ? 40.0 : 34.0);
          final stepBorderColor = isDone
              ? context.createExcursionColors.success.withValues(alpha: 0.72)
              : isActive
              ? context.createExcursionColors.primary
              : context.createExcursionColors.border;
          return Material(
            color: context.createExcursionColors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: isStepTappable ? () => onStepTap!(step) : null,
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: stepSize,
                height: stepSize,
                decoration: AppBoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? context.createExcursionColors.success
                      : isActive
                      ? context.createExcursionColors.primary
                      : context.createExcursionColors.surfaceHigh,
                  boxShadow: isDone
                      ? [
                          BoxShadow(
                            color: context.createExcursionColors.success
                                .withValues(alpha: 0.22),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ]
                      : isActive
                      ? [
                          BoxShadow(
                            color: context.createExcursionColors.primary
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
                child: Center(
                  child: isDone
                      ? Icon(
                          Icons.check_rounded,
                          color: context.createExcursionColors.white,
                        )
                      : Text(
                          '${step + 1}',
                          style: AppTextStyle(
                            color: isActive
                                ? context.createExcursionColors.white
                                : context.createExcursionColors.orangeLight37,
                            fontSize: isActive ? 20 : 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const AppEdgeInsets.fromLTRB(20, 0, 20, 10),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: context.createExcursionColors.danger.withValues(alpha: 0.14),
          borderRadius: AppBorderRadius.circular(14),
          border: Border.all(
            color: context.createExcursionColors.danger.withValues(alpha: 0.35),
          ),
        ),
        child: Padding(
          padding: const AppEdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: context.createExcursionColors.danger,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyle(
                    color: context.createExcursionColors.textPrimary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle(
              color: context.createExcursionColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(
              actionLabel!,
              style: AppTextStyle(color: context.createExcursionColors.primary),
            ),
          ),
      ],
    );
  }
}

class _CreationModeSelector extends StatelessWidget {
  const _CreationModeSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  final _ExcursionCreationMode selectedMode;
  final ValueChanged<_ExcursionCreationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _CreationModeChip(
          label: l10n.createExcursionSinglePlaceMode,
          icon: Icons.place_rounded,
          selected: selectedMode == _ExcursionCreationMode.singlePlace,
          onTap: () => onChanged(_ExcursionCreationMode.singlePlace),
        ),
        _CreationModeChip(
          label: l10n.createExcursionCombinedRouteMode,
          icon: Icons.route_rounded,
          selected: selectedMode == _ExcursionCreationMode.combinedRoute,
          onTap: () => onChanged(_ExcursionCreationMode.combinedRoute),
        ),
      ],
    );
  }
}

class _CreationModeChip extends StatelessWidget {
  const _CreationModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.createExcursionColors.primary
          : context.createExcursionColors.surfaceWarm,
      borderRadius: AppBorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, maxWidth: 260),
          padding: const AppEdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : icon,
                color: selected
                    ? context.createExcursionColors.white
                    : context.createExcursionColors.primary,
                size: 18,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: selected
                        ? context.createExcursionColors.white
                        : context.createExcursionColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandmarkSelectionCard extends StatelessWidget {
  const _LandmarkSelectionCard({
    required this.landmarkName,
    required this.cityName,
    required this.hasSelection,
    required this.onSelectLocation,
    this.errorText,
  });

  final String landmarkName;
  final String cityName;
  final bool hasSelection;
  final VoidCallback? onSelectLocation;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final displayName = landmarkName.trim();
    final displayCity = cityName.trim();
    final title = hasSelection && displayName.isNotEmpty
        ? displayName
        : l10n.createExcursionLandmarkValidation;
    final subtitle = hasSelection
        ? (displayCity.isNotEmpty
              ? displayCity
              : l10n.createExcursionPlaceCatalogSource)
        : onSelectLocation == null
        ? l10n.createExcursionSelectCountryFirst
        : l10n.createExcursionPlaceCatalogHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: AppBoxDecoration(
            borderRadius: AppBorderRadius.circular(24),
            color: isLightTheme
                ? context.createExcursionColors.surfaceRaised
                : null,
            gradient: isLightTheme
                ? null
                : LinearGradient(
                    colors: [
                      context.createExcursionColors.textMuted,
                      context.createExcursionColors.surfaceWarm,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: errorText == null
                ? null
                : Border.all(
                    color: context.createExcursionColors.danger,
                    width: 1.4,
                  ),
            boxShadow: [
              BoxShadow(
                color: context.createExcursionColors.black.withValues(
                  alpha: isLightTheme ? 0.08 : 0.24,
                ),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const AppEdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: AppBoxDecoration(
                        shape: BoxShape.circle,
                        color: isLightTheme
                            ? context.createExcursionColors.secondaryContainer
                            : context.createExcursionColors.white.withValues(
                                alpha: 0.12,
                              ),
                      ),
                      child: Icon(
                        Icons.place_rounded,
                        color: context.createExcursionColors.secondary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle(
                              color: context.createExcursionColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle(
                              color:
                                  context.createExcursionColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onSelectLocation,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.createExcursionColors.primary,
                      foregroundColor:
                          context.createExcursionColors.textPrimary,
                      disabledBackgroundColor: context
                          .createExcursionColors
                          .white
                          .withValues(alpha: 0.10),
                      disabledForegroundColor: context
                          .createExcursionColors
                          .white
                          .withValues(alpha: 0.42),
                      padding: const AppEdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.circular(18),
                      ),
                      textStyle: AppTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.travel_explore_rounded),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            hasSelection
                                ? l10n.change
                                : l10n.excursionSelectLocationPlaceSection,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) AppInlineFieldError(message: errorText!),
      ],
    );
  }
}

class _ExcursionPhotoDraft {
  _ExcursionPhotoDraft({
    required this.localId,
    this.previewBytes,
    this.fileId,
    this.imageUrl,
    this.isUploading = false,
  });

  final int localId;
  Uint8List? previewBytes;
  String? fileId;
  String? imageUrl;
  bool isUploading;
  String? errorMessage;

  bool get hasPreview =>
      (previewBytes?.isNotEmpty ?? false) ||
      (imageUrl?.trim().isNotEmpty ?? false);

  bool get hasUploadedFile => (fileId ?? '').trim().isNotEmpty;
}

class _ExcursionPhotoCarouselDraftStrip extends StatelessWidget {
  const _ExcursionPhotoCarouselDraftStrip({
    required this.photos,
    required this.maxPhotos,
    required this.onAddTap,
    required this.onRemoveTap,
  });

  final List<_ExcursionPhotoDraft> photos;
  final int maxPhotos;
  final VoidCallback onAddTap;
  final ValueChanged<_ExcursionPhotoDraft> onRemoveTap;

  @override
  Widget build(BuildContext context) {
    final canAdd = photos.length < maxPhotos;
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length + (canAdd ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index >= photos.length) {
            return _AddPhotoTile(onTap: onAddTap);
          }
          final draft = photos[index];
          return _ExcursionPhotoDraftTile(
            draft: draft,
            isCover: index == 0,
            onRemoveTap: () => onRemoveTap(draft),
          );
        },
      ),
    );
  }
}

class _ExcursionPhotoDraftTile extends StatelessWidget {
  const _ExcursionPhotoDraftTile({
    required this.draft,
    required this.isCover,
    required this.onRemoveTap,
  });

  final _ExcursionPhotoDraft draft;
  final bool isCover;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppBorderRadius.circular(18),
      child: SizedBox(
        width: 86,
        height: 86,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(context),
            DecoratedBox(
              decoration: AppBoxDecoration(
                border: Border.all(
                  color: isCover
                      ? context.createExcursionColors.primary
                      : context.createExcursionColors.white.withValues(
                          alpha: 0.16,
                        ),
                  width: isCover ? 2 : 1,
                ),
                borderRadius: AppBorderRadius.circular(18),
              ),
            ),
            if (isCover)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: AppBoxDecoration(
                    color: context.createExcursionColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bookmark_rounded,
                    size: 15,
                    color: context.createExcursionColors.white,
                  ),
                ),
              ),
            Positioned(
              right: 5,
              top: 5,
              child: Material(
                color: context.createExcursionColors.black.withValues(
                  alpha: 0.54,
                ),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: draft.isUploading ? null : onRemoveTap,
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: context.createExcursionColors.white,
                    ),
                  ),
                ),
              ),
            ),
            if (draft.isUploading)
              DecoratedBox(
                decoration: AppBoxDecoration(
                  color: context.createExcursionColors.black.withValues(
                    alpha: 0.42,
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
              ),
            if (draft.errorMessage != null)
              DecoratedBox(
                decoration: AppBoxDecoration(
                  color: context.createExcursionColors.danger.withValues(
                    alpha: 0.38,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: context.createExcursionColors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final bytes = draft.previewBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    final imageUrl = (draft.imageUrl ?? '').trim();
    if (imageUrl.isNotEmpty) {
      return Image.network(imageUrl, fit: BoxFit.cover);
    }
    return ColoredBox(color: context.createExcursionColors.surfaceWarm);
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.createExcursionColors.white.withValues(alpha: 0.06),
      borderRadius: AppBorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(18),
        child: SizedBox(
          width: 86,
          height: 86,
          child: Center(
            child: Icon(
              Icons.add_photo_alternate_rounded,
              color: context.createExcursionColors.white.withValues(
                alpha: 0.82,
              ),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExcursionCoverUploadCard extends StatelessWidget {
  const _ExcursionCoverUploadCard({
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
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final isCompact = width <= 360;
    final radius = isCompact ? 26.0 : 30.0;
    final height = isCompact ? 184.0 : 206.0;
    final hasPreview = (previewBytes?.isNotEmpty ?? false) || _hasImageUrl;

    return Material(
      color: context.createExcursionColors.transparent,
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
                _buildBackground(context, hasPreview: hasPreview),
                if (hasPreview || !isLightTheme)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: AppBoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.createExcursionColors.black.withValues(
                              alpha: hasPreview ? 0.08 : 0.12,
                            ),
                            context.createExcursionColors.black.withValues(
                              alpha: hasPreview ? 0.42 : 0.18,
                            ),
                            context.createExcursionColors.black.withValues(
                              alpha: 0.68,
                            ),
                          ],
                          stops: const [0, 0.52, 1],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: isCompact ? 18 : 22,
                  right: isCompact ? 18 : 22,
                  bottom: isCompact ? 18 : 22,
                  child: _ExcursionCoverCardCopy(
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
                        color: context.createExcursionColors.black.withValues(
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
                              context.createExcursionColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DashedExcursionCoverBorderPainter(
                      color: hasError
                          ? context.createExcursionColors.danger.withValues(
                              alpha: 0.74,
                            )
                          : context.createExcursionColors.secondary,
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

  Widget _buildBackground(BuildContext context, {required bool hasPreview}) {
    if (previewBytes != null && previewBytes!.isNotEmpty) {
      return Image.memory(previewBytes!, fit: BoxFit.cover);
    }
    if (_hasImageUrl) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            _buildPlaceholder(context, hasPreview: false),
      );
    }
    return _buildPlaceholder(context, hasPreview: hasPreview);
  }

  Widget _buildPlaceholder(BuildContext context, {required bool hasPreview}) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.createExcursionColors.surfaceWarm,
            context.createExcursionColors.background,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -36,
            right: -30,
            child: Container(
              width: 138,
              height: 138,
              decoration: AppBoxDecoration(
                shape: BoxShape.circle,
                color: context.createExcursionColors.secondaryContainer,
              ),
            ),
          ),
          Positioned(
            left: -26,
            bottom: -44,
            child: Container(
              width: 150,
              height: 150,
              decoration: AppBoxDecoration(
                shape: BoxShape.circle,
                color: context.createExcursionColors.white.withValues(
                  alpha: 0.05,
                ),
              ),
            ),
          ),
          if (!hasPreview)
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: AppBoxDecoration(
                  shape: BoxShape.circle,
                  color: context.createExcursionColors.secondaryContainer,
                  border: Border.all(
                    color: context.createExcursionColors.borderSecondary,
                  ),
                ),
                child: Icon(
                  Icons.add_photo_alternate_rounded,
                  color: context.createExcursionColors.secondary,
                  size: 32,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExcursionCoverCardCopy extends StatelessWidget {
  const _ExcursionCoverCardCopy({
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
    final maxBadgeWidth =
        MediaQuery.sizeOf(context).width - (compact ? 72 : 88);
    final isLightPlaceholder =
        Theme.of(context).brightness == Brightness.light && !hasPreview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBadgeWidth),
          child: Container(
            padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: AppBoxDecoration(
              color: context.createExcursionColors.secondaryContainer,
              borderRadius: AppBorderRadius.circular(999),
              border: Border.all(
                color: context.createExcursionColors.borderSecondary,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasPreview
                      ? Icons.refresh_rounded
                      : Icons.file_upload_outlined,
                  color: context.createExcursionColors.secondary,
                  size: compact ? 14 : 15,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      color: context.createExcursionColors.secondary,
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hint,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle(
            color: hasError
                ? context.createExcursionColors.danger
                : isLightPlaceholder
                ? context.createExcursionColors.textSecondary
                : context.createExcursionColors.white.withValues(alpha: 0.88),
            fontSize: compact ? 13 : 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DashedExcursionCoverBorderPainter extends CustomPainter {
  const _DashedExcursionCoverBorderPainter({
    required this.color,
    required this.radius,
  });

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
  bool shouldRepaint(covariant _DashedExcursionCoverBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _ItineraryEmptyState extends StatelessWidget {
  const _ItineraryEmptyState({required this.message, this.errorText});

  final String message;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: AppBoxDecoration(
            color: context.createExcursionColors.surfaceWarm,
            borderRadius: AppBorderRadius.circular(20),
            border: Border.all(
              color: errorText == null
                  ? context.createExcursionColors.borderSecondary
                  : context.createExcursionColors.danger,
            ),
          ),
          child: Padding(
            padding: const AppEdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: AppBoxDecoration(
                    color: context.createExcursionColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.route_rounded,
                    color: context.createExcursionColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyle(
                      color: context.createExcursionColors.secondary,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) AppInlineFieldError(message: errorText!),
      ],
    );
  }
}

class _ItinerarySlotCard extends StatelessWidget {
  const _ItinerarySlotCard({
    required this.item,
    required this.onTap,
    this.hasError = false,
    this.onDelete,
  });

  final _ExcursionItineraryDraft item;
  final VoidCallback onTap;
  final bool hasError;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.createExcursionColors.surfaceHigh,
      borderRadius: AppBorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(20),
        child: Container(
          decoration: AppBoxDecoration(
            borderRadius: AppBorderRadius.circular(20),
            border: Border.all(
              color: hasError
                  ? context.createExcursionColors.danger
                  : context.createExcursionColors.borderSoft,
              width: hasError ? 1.2 : 1,
            ),
          ),
          padding: const AppEdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: AppBoxDecoration(
                  color: context.createExcursionColors.secondaryContainer,
                  borderRadius: AppBorderRadius.circular(16),
                  border: Border.all(
                    color: context.createExcursionColors.borderSecondary,
                  ),
                ),
                child: Text(
                  _formatOffset(context, item.startOffsetMinutes),
                  textAlign: TextAlign.center,
                  style: AppTextStyle(
                    color: context.createExcursionColors.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: context.createExcursionColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: context.createExcursionColors.textSecondary,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.close_rounded),
                color: onDelete == null
                    ? context.createExcursionColors.textMuted
                    : context.createExcursionColors.textMuted,
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatOffset(BuildContext context, int minutes) {
    final l10n = AppLocalizations.of(context)!;
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) {
      return l10n.createExcursionOffsetMinutesShort(rest);
    }
    if (rest == 0) {
      return l10n.createExcursionOffsetHoursShort(hours);
    }
    return l10n.createExcursionOffsetHoursMinutesShort(hours, rest);
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: context.createExcursionColors.primary,
        side: BorderSide(
          color: context.createExcursionColors.white.withValues(alpha: 0.18),
        ),
        padding: const AppEdgeInsets.symmetric(vertical: 16, horizontal: 18),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _ExcursionTextField extends StatelessWidget {
  const _ExcursionTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.iconColor,
    this.errorText,
    this.onChanged,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.horizontalScroll = false,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color? iconColor;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final bool horizontalScroll;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final effectiveMinLines = horizontalScroll ? 1 : minLines;
    final effectiveMaxLines = horizontalScroll ? 1 : maxLines;
    final effectiveIconColor =
        iconColor ?? context.createExcursionColors.textMuted;

    return _ExcursionFieldShell(
      label: label,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        readOnly: readOnly,
        minLines: effectiveMinLines,
        maxLines: effectiveMaxLines,
        scrollPhysics: horizontalScroll ? const BouncingScrollPhysics() : null,
        textCapitalization: TextCapitalization.sentences,
        style: AppTextStyle(
          color: context.createExcursionColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        decoration: AppInputDecoration(
          hintText: hint,
          errorText: errorText,
          errorMaxLines: 3,
          prefixIcon: Icon(icon, color: effectiveIconColor),
          hintStyle: AppTextStyle(
            color: context.createExcursionColors.textMuted,
          ),
          errorStyle: AppTextStyle(
            color: context.createExcursionColors.danger,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          filled: true,
          fillColor: context.createExcursionColors.surfaceWarm,
          contentPadding: const AppEdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: AppBorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppBorderRadius.circular(24),
            borderSide: BorderSide(
              color: context.createExcursionColors.borderSoft,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppBorderRadius.circular(24),
            borderSide: BorderSide(
              color: context.createExcursionColors.primary,
              width: 1.4,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppBorderRadius.circular(24),
            borderSide: BorderSide(
              color: context.createExcursionColors.danger,
              width: 1.2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppBorderRadius.circular(24),
            borderSide: BorderSide(
              color: context.createExcursionColors.danger,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExcursionFieldShell extends StatelessWidget {
  const _ExcursionFieldShell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle(
            color: context.createExcursionColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.createExcursionColors.primary
          : context.createExcursionColors.surfaceWarm,
      borderRadius: AppBorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(20),
        child: Padding(
          padding: const AppEdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: AppBoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? context.createExcursionColors.white.withValues(
                          alpha: 0.16,
                        )
                      : context.createExcursionColors.white.withValues(
                          alpha: 0.08,
                        ),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? context.createExcursionColors.white
                      : context.createExcursionColors.primary,
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
                        color: selected
                            ? context.createExcursionColors.white
                            : context.createExcursionColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: AppTextStyle(
                        color: selected
                            ? context.createExcursionColors.white.withValues(
                                alpha: 0.82,
                              )
                            : context.createExcursionColors.primary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: context.createExcursionColors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcursionBottomActionBar extends StatelessWidget {
  const _ExcursionBottomActionBar({
    required this.label,
    required this.isSubmitting,
    required this.onPressed,
    this.secondaryLabel,
    this.secondaryIcon = Icons.save_outlined,
    this.onSecondaryPressed,
  });

  final String label;
  final String? secondaryLabel;
  final IconData secondaryIcon;
  final bool isSubmitting;
  final VoidCallback onPressed;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final secondaryLabel = this.secondaryLabel;
    return Padding(
      padding: AppEdgeInsets.fromLTRB(20, 10, 20, 14 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSubmitting ? null : onPressed,
              icon: isSubmitting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.createExcursionColors.textPrimary,
                      ),
                    )
                  : Icon(Icons.arrow_forward_rounded),
              label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              style: FilledButton.styleFrom(
                backgroundColor: context.createExcursionColors.primary,
                foregroundColor: context.createExcursionColors.textPrimary,
                disabledBackgroundColor: context.createExcursionColors.primary
                    .withValues(alpha: 0.55),
                padding: const AppEdgeInsets.symmetric(
                  vertical: 17,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.circular(22),
                ),
                textStyle: AppTextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (secondaryLabel != null && onSecondaryPressed != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: isSubmitting ? null : onSecondaryPressed,
                icon: Icon(
                  secondaryIcon,
                  color: context.createExcursionColors.textSecondary,
                  size: 18,
                ),
                label: Text(
                  style: AppTextStyle(
                    color: context.createExcursionColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  secondaryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddItinerarySlotSheet extends StatefulWidget {
  const _AddItinerarySlotSheet({
    required this.l10n,
    this.initialItem,
    this.enablePlaceSelection = false,
    this.countryCode,
    this.reservedPlaceIds = const {},
  });

  final AppLocalizations l10n;
  final _ExcursionItineraryDraft? initialItem;
  final bool enablePlaceSelection;
  final String? countryCode;
  final Set<String> reservedPlaceIds;

  @override
  State<_AddItinerarySlotSheet> createState() => _AddItinerarySlotSheetState();
}

class _AddItinerarySlotSheetState extends State<_AddItinerarySlotSheet> {
  final _offsetCtrl = TextEditingController(text: '180');
  final _durationCtrl = TextEditingController(text: '60');
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String? _selectedPlaceId;
  String? _selectedPlaceName;
  String? _selectedCountryCode;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _errorText;
  String? _placeErrorText;
  String? _offsetErrorText;
  String? _titleErrorText;
  String? _descriptionErrorText;

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = (widget.countryCode ?? '').trim().toUpperCase();
    final initialItem = widget.initialItem;
    if (initialItem == null) {
      return;
    }
    _offsetCtrl.text = initialItem.startOffsetMinutes.toString();
    _durationCtrl.text = initialItem.durationMinutes?.toString() ?? '';
    _titleCtrl.text =
        widget.enablePlaceSelection &&
            (initialItem.placeName ?? '').trim().isNotEmpty
        ? initialItem.placeName!.trim()
        : initialItem.title;
    _descriptionCtrl.text = initialItem.description;
    _selectedPlaceId = initialItem.placeId;
    _selectedPlaceName = initialItem.placeName;
    _selectedCountryCode =
        (initialItem.countryCode ?? _selectedCountryCode ?? '')
            .trim()
            .toUpperCase();
    _selectedLatitude = initialItem.latitude;
    _selectedLongitude = initialItem.longitude;
  }

  @override
  void dispose() {
    _offsetCtrl.dispose();
    _durationCtrl.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _openStopPlaceSelector() async {
    final countryCode = (_selectedCountryCode ?? '').trim().toUpperCase();

    FocusScope.of(context).unfocus();
    final selectedId = (_selectedPlaceId ?? '').trim();
    final result = await context.push<ExcursionLocationSelection>(
      '/excursions/create/location',
      extra: ExcursionLocationPickerArgs(
        countryCode: countryCode,
        initialSelection: selectedId.isEmpty
            ? null
            : ExcursionLocationSelection(
                id: selectedId,
                name: (_selectedPlaceName ?? '').trim(),
                countryCode: countryCode,
                latitude: _selectedLatitude,
                longitude: _selectedLongitude,
              ),
      ),
    );
    if (!mounted || result == null) return;

    final placeId = result.id.trim();
    if (_isReservedPlace(placeId)) {
      setState(() {
        _placeErrorText =
            widget.l10n.createExcursionDuplicateRouteStopValidation;
      });
      return;
    }

    setState(() {
      _selectedPlaceId = placeId.isEmpty ? null : placeId;
      _selectedPlaceName = result.name.trim();
      _selectedCountryCode = result.countryCode.trim().toUpperCase();
      _selectedLatitude = result.latitude;
      _selectedLongitude = result.longitude;
      _titleCtrl.text = result.name.trim();
      _placeErrorText = null;
      _errorText = null;
    });
  }

  bool _isReservedPlace(String placeId) {
    final normalized = placeId.trim();
    return normalized.isNotEmpty &&
        widget.reservedPlaceIds.contains(normalized);
  }

  void _submit() {
    final offset = int.tryParse(_offsetCtrl.text.trim());
    final duration = int.tryParse(_durationCtrl.text.trim());
    final draft = _ExcursionItineraryDraft(
      startOffsetMinutes: offset ?? 0,
      countryCode: _selectedCountryCode,
      durationMinutes: duration,
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      placeId: _selectedPlaceId,
      placeName: _selectedPlaceName,
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
      travelFromPreviousMinutes: widget.initialItem?.travelFromPreviousMinutes,
    );
    String? formErrorText;
    String? placeErrorText;
    String? offsetErrorText;
    String? titleErrorText;
    String? descriptionErrorText;
    final isCompleteDraft = _isCompleteItineraryDraft(draft);
    if (widget.enablePlaceSelection && (draft.placeId ?? '').trim().isEmpty) {
      placeErrorText = widget.l10n.createExcursionLandmarkValidation;
    }
    if (widget.enablePlaceSelection && _isReservedPlace(draft.placeId ?? '')) {
      placeErrorText = widget.l10n.createExcursionDuplicateRouteStopValidation;
    }
    if (offset == null || offset < 0) {
      offsetErrorText = widget.l10n.createExcursionStartOffsetValidation;
    }
    if (draft.title.trim().length < 2) {
      titleErrorText = widget.l10n.createExcursionItineraryTitleValidation;
    }
    if (!isCompleteDraft && draft.description.trim().length < 5) {
      descriptionErrorText = widget.l10n
          .createExcursionItineraryDescriptionMinLengthValidation(5);
    }
    if (placeErrorText != null ||
        offsetErrorText != null ||
        titleErrorText != null ||
        descriptionErrorText != null) {
      formErrorText = null;
      setState(() {
        _errorText = formErrorText;
        _placeErrorText = placeErrorText;
        _offsetErrorText = offsetErrorText;
        _titleErrorText = titleErrorText;
        _descriptionErrorText = descriptionErrorText;
      });
      return;
    }
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final systemBottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        var maxHeight = _modalMaxHeightAboveKeyboard(context);
        if (constraints.maxHeight.isFinite) {
          maxHeight = maxHeight.clamp(0.0, constraints.maxHeight).toDouble();
        }

        return SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: DecoratedBox(
              key: const ValueKey('excursion-itinerary-slot-sheet-surface'),
              decoration: AppBoxDecoration(
                color: context.createExcursionColors.surfaceWarm,
                borderRadius: const AppBorderRadius.vertical(
                  top: AppRadiusValue.circular(28),
                ),
              ),
              child: Padding(
                padding: AppEdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  34 + systemBottomPadding,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: widget.initialItem == null
                            ? widget.l10n.createExcursionAddTimeSlot
                            : widget.l10n.createExcursionEditTimeSlot,
                      ),
                      const SizedBox(height: 14),
                      if (widget.enablePlaceSelection) ...[
                        _LandmarkSelectionCard(
                          landmarkName: _selectedPlaceName ?? '',
                          cityName: '',
                          hasSelection: (_selectedPlaceId ?? '')
                              .trim()
                              .isNotEmpty,
                          errorText: _placeErrorText,
                          onSelectLocation: _openStopPlaceSelector,
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _ExcursionTextField(
                              controller: _offsetCtrl,
                              label:
                                  widget.l10n.createExcursionStartOffsetLabel,
                              hint: '120',
                              icon: Icons.schedule_rounded,
                              keyboardType: TextInputType.number,
                              errorText: _offsetErrorText,
                              onChanged: (_) {
                                if (_offsetErrorText != null) {
                                  setState(() => _offsetErrorText = null);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ExcursionTextField(
                              controller: _durationCtrl,
                              label:
                                  widget.l10n.createExcursionSlotDurationLabel,
                              hint: '60',
                              icon: Icons.timelapse_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ExcursionTextField(
                        controller: _titleCtrl,
                        label: widget.l10n.createExcursionItineraryTitleLabel,
                        hint: widget.l10n.createExcursionItineraryTitleHint,
                        icon: Icons.route_outlined,
                        readOnly:
                            widget.enablePlaceSelection &&
                            (_selectedPlaceId ?? '').trim().isNotEmpty,
                        errorText: _titleErrorText,
                        onChanged: (_) {
                          if (_titleErrorText != null) {
                            setState(() => _titleErrorText = null);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _ExcursionTextField(
                        controller: _descriptionCtrl,
                        label: widget
                            .l10n
                            .createExcursionItineraryDescriptionLabel,
                        hint:
                            widget.l10n.createExcursionItineraryDescriptionHint,
                        icon: Icons.notes_rounded,
                        errorText: _descriptionErrorText,
                        onChanged: (_) {
                          if (_descriptionErrorText != null) {
                            setState(() => _descriptionErrorText = null);
                          }
                        },
                        minLines: 3,
                        maxLines: 5,
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorText!,
                          style: AppTextStyle(
                            color: context.createExcursionColors.danger,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey(
                            'excursion-itinerary-slot-confirm',
                          ),
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                context.createExcursionColors.primary,
                            foregroundColor:
                                context.createExcursionColors.textPrimary,
                            padding: const AppEdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                          child: Text(
                            widget.l10n.confirm,
                            style: AppTextStyle(
                              color: context.createExcursionColors.textPrimary,
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
        );
      },
    );
  }
}
