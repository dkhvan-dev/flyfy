import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/excursions/excursion_cover_url.dart';
import '../../features/excursions/models/create_excursion_request.dart';
import '../../features/excursions/models/excursion_vm.dart';
import '../../features/excursions/excursion_localization.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/excursion_provider.dart';
import '../../providers/home_location_provider.dart';
import '../../shared/widgets/app_currency_picker_field.dart';
import 'excursion_select_location_screen.dart';

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

class _CreateExcursionScreenState extends State<CreateExcursionScreen> {
  static const _totalSteps = 3;
  static const LatLng _fallbackMapTarget = LatLng(43.238949, 76.889709);
  static const double _stepBackSwipeMinDistance = 56;
  static const double _stepBackSwipeMinVelocity = 700;
  static const int _maxCoverUploadBytes = 20 * 1024 * 1024;
  static const int _maxExcursionLanguages = 5;
  static const int _minItinerarySlots = 2;
  static const int _maxItineraryAttractionStops = 5;

  final _pageController = PageController();
  final _imagePicker = ImagePicker();
  final _fileApi = FileApi();
  final MapController _mapController = MapController();
  var _currentStep = 0;
  var _isSubmitting = false;
  var _isLoadingInitialExcursion = false;
  var _didApplyInitialExcursion = false;
  var _didApplyHomeLocation = false;
  String? _editingExcursionStatus;

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
  var _creationMode = _ExcursionCreationMode.singleAttraction;
  String? _selectedCountryCode;
  String? _departureCityId;
  String? _selectedLandmarkId;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAttractionCoverFileId;
  String? _selectedAttractionCoverImageUrl;
  Map<String, CreateExcursionLocalizedCopyRequest> _productTranslations =
      const {};
  Uint8List? _coverPreviewBytes;
  String? _coverFileId;
  String? _existingCoverImageUrl;
  bool _coverChanged = false;
  bool _isCoverUploading = false;
  String? _coverUploadErrorMessage;
  int _coverUploadGeneration = 0;
  bool _isTrackingStepBackSwipe = false;
  double _stepBackSwipeDistance = 0;
  int _mapSelectionRequestSerial = 0;
  String? _stepErrorText;
  String? _landmarkErrorText;
  String? _itineraryErrorText;
  String? _durationErrorText;
  String? _groupSizeErrorText;
  String? _languagesErrorText;
  String? _meetingPointErrorText;
  String? _priceErrorText;
  String? _currencyErrorText;
  final Set<String> _selectedLanguageCodes = {'en', 'ru'};
  final List<_ExcursionIncludedItemDraft> _includedItems = [];

  final List<_ExcursionItineraryDraft> _itinerary = [];

  @override
  void initState() {
    super.initState();
    if ((widget.excursionId ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExcursionForEdit();
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
      final location = context.read<HomeLocationProvider>().effectiveLocation;
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
    }
  }

  @override
  void dispose() {
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
      _currencyErrorText != null;

  void _clearFieldValidationErrors() {
    _landmarkErrorText = null;
    _itineraryErrorText = null;
    _durationErrorText = null;
    _groupSizeErrorText = null;
    _languagesErrorText = null;
    _meetingPointErrorText = null;
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
        : _ExcursionCreationMode.singleAttraction;
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
    _mapUrlCtrl.text = (excursion.mapUrl ?? '').trim();
    _priceAmountCtrl.text = excursion.priceAmount > 0
        ? _formatNumberInput(excursion.priceAmount)
        : '';
    _coverFileId = (excursion.coverFileId ?? '').trim().isEmpty
        ? null
        : excursion.coverFileId!.trim();
    final existingCoverImageUrl = (resolveExcursionCoverUrl(excursion) ?? '')
        .trim();
    _existingCoverImageUrl = existingCoverImageUrl.isEmpty
        ? null
        : existingCoverImageUrl;
    _coverChanged = _coverFileId != null;
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
              attractionId: item.attractionId,
              attractionName: item.attractionName,
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
    if (step < 0 || step >= _totalSteps || step == _currentStep) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _currentStep = step;
      _stepErrorText = null;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextStep() {
    if (!_validateCurrentStep()) {
      return;
    }
    if (_currentStep == _totalSteps - 1) {
      _submit(submitForReview: !_isEditMode);
      return;
    }
    _goToStep(_currentStep + 1);
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
    if (_isCoverUploading) {
      return l10n.createCoverUploadInProgress;
    }
    if (_coverChanged && (_coverFileId ?? '').trim().isEmpty) {
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
      final attractionStopCount = _itineraryAttractionStopCount;
      if (_itinerary.length > _maxItineraryAttractionStops ||
          attractionStopCount > _maxItineraryAttractionStops) {
        _itineraryErrorText = l10n
            .createExcursionCombinedRouteMaxStopsValidation(
              _maxItineraryAttractionStops,
            );
        return _itineraryErrorText;
      }
      if (_itinerary.length < _minItinerarySlots ||
          attractionStopCount < _minItinerarySlots ||
          attractionStopCount != _itinerary.length) {
        _itineraryErrorText = l10n
            .createExcursionCombinedRouteMinStopsValidation(_minItinerarySlots);
        return _itineraryErrorText;
      }
    }
    return null;
  }

  String? _validateLandmarkStep(AppLocalizations l10n) {
    if (_creationMode == _ExcursionCreationMode.singleAttraction &&
        !_hasSelectedAttraction) {
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
    if (_isCoverUploading) {
      return l10n.createCoverUploadInProgress;
    }
    if (_coverChanged && (_coverFileId ?? '').trim().isEmpty) {
      return l10n.createCoverUploadRetryRequired;
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
    if (_isEditMode) {
      final excursionId = widget.excursionId!.trim();
      saved = await provider.updateExcursionOffer(excursionId, request);
      if (saved != null && submitForReview) {
        saved = await provider.submitExcursionForPublishing(excursionId);
      }
    } else {
      saved = submitForReview
          ? await provider.createAndSubmitExcursion(request)
          : await provider.createDraftExcursion(request);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (saved != null) {
      _editingExcursionStatus = saved.status.trim().toUpperCase();
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
        context.go('/');
      }
      return;
    }

    await showErrorDialog(
      context,
      title: l10n.error,
      message:
          provider.actionErrorMessage ??
          (_isEditMode
              ? l10n.createExcursionUpdateFailed
              : l10n.createExcursionFailed),
    );
  }

  CreateExcursionRequest _buildRequest() {
    final price = double.tryParse(_priceAmountCtrl.text.trim()) ?? 0;
    final isCombinedRoute =
        _creationMode == _ExcursionCreationMode.combinedRoute;
    return CreateExcursionRequest(
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
              attractionId: isCombinedRoute ? item.attractionId : null,
              attractionName: isCombinedRoute ? item.attractionName : null,
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
  }

  Future<void> _openIncludedItemsEditor() async {
    final result =
        await showModalBottomSheet<List<_ExcursionIncludedItemDraft>>(
          context: context,
          isDismissible: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
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

  bool get _hasSelectedAttraction =>
      (_selectedLandmarkId ?? '').trim().isNotEmpty;

  int get _itineraryAttractionStopCount {
    return _itinerary
        .where((item) => (item.attractionId ?? '').trim().isNotEmpty)
        .length;
  }

  void _selectCreationMode(_ExcursionCreationMode mode) {
    if (mode == _creationMode) return;
    setState(() {
      _creationMode = mode;
      _landmarkErrorText = null;
      _itineraryErrorText = null;
      _stepErrorText = null;
    });
  }

  void _replaceCustomCoverWithAttractionCover() {
    _coverUploadGeneration += 1;
    _coverPreviewBytes = null;
    _coverFileId = null;
    _coverChanged = false;
    _coverUploadErrorMessage = null;
    _isCoverUploading = false;
  }

  String? get _effectiveCoverFileId {
    final customCover = (_coverFileId ?? '').trim();
    if (customCover.isNotEmpty) {
      return customCover;
    }
    final attractionCover = (_selectedAttractionCoverFileId ?? '').trim();
    return attractionCover.isEmpty ? null : attractionCover;
  }

  String? get _offerCoverFileId {
    final customCover = (_coverFileId ?? '').trim();
    if (customCover.isNotEmpty) {
      return customCover;
    }
    if (!_hasSelectedAttraction) {
      return _effectiveCoverFileId;
    }
    return null;
  }

  String? get _productCoverFileId {
    final attractionCover = (_selectedAttractionCoverFileId ?? '').trim();
    if (attractionCover.isNotEmpty) {
      return attractionCover;
    }
    if (!_hasSelectedAttraction) {
      final customCover = (_coverFileId ?? '').trim();
      return customCover.isEmpty ? null : customCover;
    }
    return null;
  }

  String? get _productCoverImageUrl {
    if (!_hasSelectedAttraction) return null;
    final attractionImage = (_selectedAttractionCoverImageUrl ?? '').trim();
    return attractionImage.isEmpty ? null : attractionImage;
  }

  String? get _effectiveCoverImageUrl {
    if (_coverPreviewBytes?.isNotEmpty ?? false) {
      return null;
    }
    final attractionImage = (_selectedAttractionCoverImageUrl ?? '').trim();
    if (attractionImage.isNotEmpty) {
      return attractionImage;
    }
    final existingImage = (_existingCoverImageUrl ?? '').trim();
    return existingImage.isEmpty ? null : existingImage;
  }

  bool get _hasAnyCoverPreview {
    return (_coverPreviewBytes?.isNotEmpty ?? false) ||
        (_effectiveCoverImageUrl?.isNotEmpty ?? false);
  }

  LatLng get _selectedMapTarget => _hasSelectedMapPoint
      ? LatLng(_selectedLatitude!, _selectedLongitude!)
      : _fallbackMapTarget;

  List<Marker> get _selectedMapMarkers => !_hasSelectedMapPoint
      ? const <Marker>[]
      : [
          Marker(
            point: _selectedMapTarget,
            width: 46,
            height: 46,
            alignment: Alignment.topCenter,
            child: const Icon(
              Icons.location_on_rounded,
              size: 46,
              color: AppColors.accent,
            ),
          ),
        ];

  String _buildMapUrl(double latitude, double longitude) {
    final lat = latitude.toStringAsFixed(6);
    final lng = longitude.toStringAsFixed(6);
    return 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=16/$lat/$lng';
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

  void _moveMapToSelection({double zoom = 15}) {
    if (!_hasSelectedMapPoint) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(_selectedMapTarget, zoom);
      } catch (_) {
        // MapController is attached only after FlutterMap is mounted.
      }
    });
  }

  Future<void> _handleMapTapped(LatLng position) async {
    final requestSerial = ++_mapSelectionRequestSerial;
    final mapUrl = _buildMapUrl(position.latitude, position.longitude);
    final coordinateLabel = _buildCoordinateMeetingPointLabel(
      position.latitude,
      position.longitude,
    );

    setState(() {
      _selectedLatitude = position.latitude;
      _selectedLongitude = position.longitude;
      _mapUrlCtrl.text = mapUrl;
      _meetingPointCtrl.text = coordinateLabel;
      _meetingPointErrorText = null;
      _stepErrorText = null;
    });
    _mapController.move(position, 15);

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted || requestSerial != _mapSelectionRequestSerial) return;

      if (placemarks.isNotEmpty) {
        final address = _composeMeetingPointLabel(placemarks.first);
        if (address.isNotEmpty) {
          setState(() {
            _meetingPointCtrl.text = address;
            _meetingPointErrorText = null;
            _stepErrorText = null;
          });
        }
      }
    } catch (_) {
      // Keep coordinates and map link when reverse geocoding is unavailable.
    }
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

    setState(() {
      _coverUploadGeneration = uploadGeneration;
      _coverChanged = true;
      _coverPreviewBytes = bytes;
      _coverFileId = null;
      _coverUploadErrorMessage = null;
      _isCoverUploading = true;
      _stepErrorText = null;
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
        _coverFileId = upload.fileId;
        _coverUploadErrorMessage = null;
        _isCoverUploading = false;
      });
    } on DioException catch (e) {
      if (!mounted || uploadGeneration != _coverUploadGeneration) return;
      setState(() {
        _coverUploadErrorMessage = DioErrorMapper.toMessage(e);
        _isCoverUploading = false;
      });
    } catch (_) {
      if (!mounted || uploadGeneration != _coverUploadGeneration) return;
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
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          mapUrl: _mapUrlCtrl.text.trim(),
          coverFileId: _selectedAttractionCoverFileId,
          coverImageUrl: _selectedAttractionCoverImageUrl,
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
      final selectedCityId = (result.cityId ?? '').trim();
      if (selectedCityName.isNotEmpty) {
        _cityNameCtrl.text = selectedCityName;
      } else if (selectedCityId.isNotEmpty) {
        _cityNameCtrl.text = selectedCityId;
      } else {
        _cityNameCtrl.clear();
      }
      _selectedLatitude = result.latitude;
      _selectedLongitude = result.longitude;
      _selectedAttractionCoverFileId = (result.coverFileId ?? '').trim().isEmpty
          ? null
          : result.coverFileId!.trim();
      _selectedAttractionCoverImageUrl =
          (result.coverImageUrl ?? '').trim().isEmpty
          ? null
          : result.coverImageUrl!.trim();
      _replaceCustomCoverWithAttractionCover();
      _productTranslations = _copyLocationTranslations(result.translations);
      if (result.categorySlug.trim().isNotEmpty) {
        _selectedCategorySlug = result.categorySlug.trim();
      }
      if ((result.mapUrl ?? '').trim().isNotEmpty) {
        _mapUrlCtrl.text = result.mapUrl!.trim();
      } else if (result.latitude != null && result.longitude != null) {
        _mapUrlCtrl.text = _buildMapUrl(result.latitude!, result.longitude!);
      }
      if (_meetingPointCtrl.text.trim().isEmpty) {
        _meetingPointCtrl.text = result.name;
      }
      _landmarkErrorText = null;
      _stepErrorText = null;
    });
    _moveMapToSelection();
  }

  Future<void> _openItineraryEditor({_ExcursionItineraryDraft? item}) async {
    final l10n = AppLocalizations.of(context)!;
    final isCombinedRoute =
        _creationMode == _ExcursionCreationMode.combinedRoute;
    final itemIndex = item == null ? -1 : _itinerary.indexOf(item);
    final result = await showModalBottomSheet<_ExcursionItineraryDraft>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddItinerarySlotSheet(
        l10n: l10n,
        initialItem: item,
        enableAttractionSelection: isCombinedRoute,
        countryCode: _selectedCountryCode,
        reservedAttractionIds: _reservedItineraryAttractionIds(item),
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
  }

  Set<String> _reservedItineraryAttractionIds(_ExcursionItineraryDraft? item) {
    return _itinerary
        .where((draft) => !identical(draft, item))
        .map((draft) => (draft.attractionId ?? '').trim())
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final stepBackSwipeEdgeWidth = _stepBackSwipeEdgeWidth(context);

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentStep > 0) {
          _goToStep(_currentStep - 1);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF25180D), Color(0xFF3B2815)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _ExcursionTopBar(
                        title: _isEditMode
                            ? l10n.createExcursionEditTitle
                            : l10n.createExcursionTitle,
                        onBack: _currentStep == 0
                            ? () => context.pop()
                            : () => _goToStep(_currentStep - 1),
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
      padding: EdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
      children: [
        ..._buildOfferCoverSection(l10n),
        const SizedBox(height: 24),
        ..._buildOfferItinerarySection(l10n),
        const SizedBox(height: 16),
        Text(
          l10n.createExcursionAutosaveHint,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFB69B78), fontSize: 12),
        ),
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
        previewBytes: _coverPreviewBytes,
        isUploading: _isCoverUploading,
        hasError: _coverUploadErrorMessage != null,
        onTap: _pickCoverImage,
      ),
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
          padding: const EdgeInsets.only(bottom: 10),
          child: _ItinerarySlotCard(
            item: item,
            hasError: !_isCompleteItineraryDraft(item),
            onTap: () => _openItineraryEditor(item: item),
            onDelete: () => setState(() => _itinerary.remove(item)),
          ),
        ),
      ),
      if (_itinerary.isNotEmpty && _itineraryErrorText != null) ...[
        _InlineFieldError(message: _itineraryErrorText!),
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
      padding: EdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
      children: [
        _SectionHeader(title: l10n.createExcursionSelectedLandmark),
        const SizedBox(height: 12),
        _CreationModeSelector(
          selectedMode: _creationMode,
          onChanged: _selectCreationMode,
        ),
        if (_creationMode == _ExcursionCreationMode.singleAttraction) ...[
          const SizedBox(height: 12),
          _LandmarkSelectionCard(
            landmarkName: _landmarkNameCtrl.text,
            cityName: _cityNameCtrl.text,
            hasSelection: _hasSelectedAttraction,
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
          style: const TextStyle(color: Color(0xFFB69B78), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStepLogistics(AppLocalizations l10n, double bottomInset) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
      children: [
        _ExcursionDurationPickerRow(
          controller: _durationValueCtrl,
          selectedUnit: _selectedDurationUnit,
          errorText: _durationErrorText,
          onChanged: (_) => setState(() {
            _durationErrorText = null;
            _stepErrorText = null;
          }),
          onUnitChanged: (unit) => setState(() {
            _selectedDurationUnit = unit;
            _durationErrorText = null;
            _stepErrorText = null;
          }),
        ),
        const SizedBox(height: 16),
        _ExcursionTextField(
          controller: _maxGroupSizeCtrl,
          label: l10n.createExcursionMaxGroupSizeLabel,
          hint: l10n.createExcursionMaxGroupSizeHint,
          icon: Icons.group_outlined,
          iconColor: AppColors.accent,
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
          onTap: () => setState(() => _visibility = 'PUBLIC'),
        ),
        const SizedBox(height: 12),
        _VisibilityCard(
          title: l10n.createVisibilityByLink,
          description: l10n.createExcursionVisibilityUnlistedDescription,
          icon: Icons.link_rounded,
          selected: _visibility == 'UNLISTED',
          onTap: () => setState(() => _visibility = 'UNLISTED'),
        ),
      ],
    );
  }

  Widget _buildStepStoryAndPrice(AppLocalizations l10n, double bottomInset) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
      children: [
        _SectionHeader(title: l10n.createMeetingPointTitle),
        const SizedBox(height: 12),
        _ExcursionTextField(
          controller: _meetingPointCtrl,
          label: l10n.createMeetingPointLocationLabel,
          hint: l10n.createExcursionMeetingPointHint,
          icon: Icons.location_on_outlined,
          iconColor: AppColors.accent,
          horizontalScroll: true,
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
          iconColor: AppColors.accent,
          keyboardType: TextInputType.url,
          horizontalScroll: true,
        ),
        const SizedBox(height: 14),
        _ExcursionMapPickerCard(
          target: _selectedMapTarget,
          markers: _selectedMapMarkers,
          hasSelection: _hasSelectedMapPoint,
          mapController: _mapController,
          onTap: _handleMapTapped,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.createMapTapHint,
          style: const TextStyle(color: Color(0xFFD4BEA8), fontSize: 12),
        ),
        _SectionHeader(title: l10n.createExcursionInvestmentTitle),
        const SizedBox(height: 12),
        _ExcursionTextField(
          controller: _priceAmountCtrl,
          label: l10n.createPriceAmountLabel,
          hint: '0.00',
          icon: Icons.payments_outlined,
          iconColor: AppColors.accent,
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
          onChanged: (value) => setState(() {
            _selectedCurrencyCode = value;
            _currencyErrorText = null;
            _stepErrorText = null;
          }),
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

enum _ExcursionCreationMode { singleAttraction, combinedRoute }

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
          iconColor: AppColors.accent,
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
        color: const Color(0xFF2D2115),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                        ? AppColors.accent
                        : const Color(0xFFA99683),
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      unit.label(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFF8F0),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2115),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              const Icon(Icons.timelapse_rounded, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedUnit.label(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFF8F0),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.accent,
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
    this.attractionId,
    this.attractionName,
    this.latitude,
    this.longitude,
    this.travelFromPreviousMinutes,
  });

  final int startOffsetMinutes;
  final String? countryCode;
  final int? durationMinutes;
  final String? attractionId;
  final String? attractionName;
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
            decoration: BoxDecoration(
              color: const Color(0xFF2D2115),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.errorText == null
                    ? AppColors.accent.withValues(alpha: 0.10)
                    : const Color(0xFFFFB199),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _languageSearchController,
                    cursorColor: AppColors.accent,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.createExcursionLanguagesSearchHint,
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
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
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
                  if (_languageSearchQuery.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    if (visibleLanguages.isEmpty)
                      Text(
                        l10n.createExcursionLanguagesNoResults,
                        style: const TextStyle(
                          color: Color(0xFFBDAA98),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 224),
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
                    style: const TextStyle(
                      color: Color(0xFFA99683),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.errorText != null)
            _InlineFieldError(message: widget.errorText!),
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
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  code,
                  style: const TextStyle(
                    color: Color(0xFFBDAA98),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
        ? const Color(0xFF806F5E)
        : selected
        ? Colors.white
        : const Color(0xFFFFF8F0);

    return Material(
      color: selected ? AppColors.accent : const Color(0xFF3A2A1D),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
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
      color: const Color(0xFF2D2115),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.10)),
          ),
          child: items.isEmpty
              ? Row(
                  children: [
                    const Icon(
                      Icons.checklist_rounded,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.createExcursionIncludedItemsEmpty,
                        style: const TextStyle(
                          color: Color(0xFFA99683),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4A321D),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.type.icon, color: AppColors.accent, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              item.type.label(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFF8F0),
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF2D2115),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 10, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.createExcursionIncludedItemsEditorTitle,
                          style: const TextStyle(
                            color: Color(0xFFFFF8F0),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFFFFF8F0),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    children: [
                      for (final type in _selectableIncludedItemTypes) ...[
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

    return Material(
      color: selected ? AppColors.accent : const Color(0xFF3A2A1D),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  type.icon,
                  color: selected ? Colors.white : AppColors.accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  type.label(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFFFFF8F0),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? Colors.white : const Color(0xFFA99683),
                size: 22,
              ),
            ],
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFFF5E9DA),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF9F0E4),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
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
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 14),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            final isDone = index ~/ 2 < currentStep;
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.success
                      : AppColors.accent.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }
          final step = index ~/ 2;
          final isDone = step < currentStep;
          final isActive = step == currentStep;
          final isStepTappable = onStepTap != null && isDone;
          final stepSize = isActive ? 48.0 : (isDone ? 40.0 : 34.0);
          return Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: isStepTappable ? () => onStepTap!(step) : null,
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: stepSize,
                height: stepSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppColors.success
                      : isActive
                      ? AppColors.accent
                      : const Color(0xFF5A370D),
                  boxShadow: isDone
                      ? [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.22),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ]
                      : isActive
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.24),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : null,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, color: Colors.white)
                      : Text(
                          '${step + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : const Color(0xFFF6DEC2),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFF8A65).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFF8A65).withValues(alpha: 0.35),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFFB199),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFFFD4C5),
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

class _InlineFieldError extends StatelessWidget {
  const _InlineFieldError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFFFB199),
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFFB199),
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
            style: const TextStyle(
              color: Color(0xFFFFE3B8),
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
              style: const TextStyle(color: AppColors.accent),
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
          label: l10n.createExcursionSingleAttractionMode,
          icon: Icons.place_rounded,
          selected: selectedMode == _ExcursionCreationMode.singleAttraction,
          onTap: () => onChanged(_ExcursionCreationMode.singleAttraction),
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
      color: selected ? AppColors.accent : const Color(0xFF3A2A1D),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : icon,
                color: selected ? Colors.white : AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFFFFF8F0),
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
    final displayName = landmarkName.trim();
    final displayCity = cityName.trim();
    final title = hasSelection && displayName.isNotEmpty
        ? displayName
        : l10n.createExcursionLandmarkValidation;
    final subtitle = hasSelection
        ? (displayCity.isNotEmpty
              ? displayCity
              : l10n.createExcursionAttractionCatalogSource)
        : onSelectLocation == null
        ? l10n.createExcursionSelectCountryFirst
        : l10n.createExcursionAttractionCatalogHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF9A673A), Color(0xFF533018)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: errorText == null
                ? null
                : Border.all(color: const Color(0xFFFFB199), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.place_rounded,
                        color: Color(0xFFFFE5C2),
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
                            style: const TextStyle(
                              color: Color(0xFFFFF5E8),
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
                            style: const TextStyle(
                              color: Color(0xFFFFE5C2),
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
                      backgroundColor: AppColors.accent,
                      disabledBackgroundColor: Colors.white.withValues(
                        alpha: 0.10,
                      ),
                      disabledForegroundColor: Colors.white.withValues(
                        alpha: 0.42,
                      ),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.travel_explore_rounded),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            hasSelection
                                ? l10n.change
                                : l10n.excursionSelectLocationAttractionSection,
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
        if (errorText != null) _InlineFieldError(message: errorText!),
      ],
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
    final isCompact = width <= 360;
    final radius = isCompact ? 26.0 : 30.0;
    final height = isCompact ? 184.0 : 206.0;
    final hasPreview = (previewBytes?.isNotEmpty ?? false) || _hasImageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUploading ? null : onTap,
        borderRadius: BorderRadius.circular(radius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBackground(hasPreview: hasPreview),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(
                            alpha: hasPreview ? 0.08 : 0.12,
                          ),
                          Colors.black.withValues(
                            alpha: hasPreview ? 0.42 : 0.18,
                          ),
                          Colors.black.withValues(alpha: 0.68),
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
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.accent,
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
                          ? const Color(0xFFFF7B6E).withValues(alpha: 0.74)
                          : const Color(0xFFBE965D).withValues(alpha: 0.45),
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

  Widget _buildBackground({required bool hasPreview}) {
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A240D), Color(0xFF181109)],
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.17),
              ),
            ),
          ),
          Positioned(
            left: -26,
            bottom: -44,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          if (!hasPreview)
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Icon(
                  Icons.add_photo_alternate_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.26)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasPreview ? Icons.refresh_rounded : Icons.file_upload_outlined,
                color: AppColors.accent,
                size: compact ? 14 : 15,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hint,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: hasError
                ? const Color(0xFFFFC0B8)
                : Colors.white.withValues(alpha: 0.88),
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
      Radius.circular(radius),
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
          decoration: BoxDecoration(
            color: const Color(0xFF4A321D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: errorText == null
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFFFB199),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFFFFE3B8),
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
        if (errorText != null) _InlineFieldError(message: errorText!),
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
      color: const Color(0xFF4A321D),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: hasError
                ? Border.all(color: const Color(0xFFFFB199), width: 1.2)
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _formatOffset(context, item.startOffsetMinutes),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFDEB6),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFC4A27D),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close_rounded),
                color: onDelete == null
                    ? const Color(0xFF8F765B)
                    : const Color(0xFFFFDEB6),
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
        foregroundColor: const Color(0xFFFFDEB6),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
    final effectiveIconColor = iconColor ?? const Color(0xFFA99683);

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
        style: const TextStyle(
          color: Color(0xFFFFF8F0),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hint,
          errorText: errorText,
          errorMaxLines: 3,
          prefixIcon: Icon(icon, color: effectiveIconColor),
          hintStyle: const TextStyle(color: Color(0xFFA99683)),
          errorStyle: const TextStyle(
            color: Color(0xFFFFB199),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          filled: true,
          fillColor: const Color(0xFF2D2115),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: AppColors.accent.withValues(alpha: 0.10),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFFFFB199), width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFFFFB199), width: 1.4),
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
          style: const TextStyle(
            color: Color(0xFFD4BEA8),
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
      color: selected ? AppColors.accent : const Color(0xFF3A2108),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.08),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : const Color(0xFFFFDEB6),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFFFFE3B8),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.82)
                            : const Color(0xFFC4A27D),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcursionMapPickerCard extends StatelessWidget {
  const _ExcursionMapPickerCard({
    required this.target,
    required this.markers,
    required this.hasSelection,
    required this.mapController,
    required this.onTap,
  });

  final LatLng target;
  final List<Marker> markers;
  final bool hasSelection;
  final MapController mapController;
  final ValueChanged<LatLng> onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = width <= 393 ? 168.0 : 178.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: target,
                initialZoom: hasSelection ? 15 : 12,
                backgroundColor: const Color(0xFFB3A28D),
                onTap: (_, point) => onTap(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'kz.inflap',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0x22695841),
                        const Color(0x22695841),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: IgnorePointer(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.22),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    hasSelection
                        ? Icons.location_on_rounded
                        : Icons.my_location_rounded,
                    size: 24,
                    color: Colors.white,
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
      padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSubmitting ? null : onPressed,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.accent.withValues(
                  alpha: 0.55,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 17,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                textStyle: const TextStyle(
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
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                label: Text(
                  style: TextStyle(
                    color: AppColors.textSecondary,
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
    this.enableAttractionSelection = false,
    this.countryCode,
    this.reservedAttractionIds = const {},
  });

  final AppLocalizations l10n;
  final _ExcursionItineraryDraft? initialItem;
  final bool enableAttractionSelection;
  final String? countryCode;
  final Set<String> reservedAttractionIds;

  @override
  State<_AddItinerarySlotSheet> createState() => _AddItinerarySlotSheetState();
}

class _AddItinerarySlotSheetState extends State<_AddItinerarySlotSheet> {
  final _offsetCtrl = TextEditingController(text: '180');
  final _durationCtrl = TextEditingController(text: '60');
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String? _selectedAttractionId;
  String? _selectedAttractionName;
  String? _selectedCountryCode;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _errorText;
  String? _attractionErrorText;
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
        widget.enableAttractionSelection &&
            (initialItem.attractionName ?? '').trim().isNotEmpty
        ? initialItem.attractionName!.trim()
        : initialItem.title;
    _descriptionCtrl.text = initialItem.description;
    _selectedAttractionId = initialItem.attractionId;
    _selectedAttractionName = initialItem.attractionName;
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

  Future<void> _openStopAttractionSelector() async {
    final countryCode = (_selectedCountryCode ?? '').trim().toUpperCase();

    FocusScope.of(context).unfocus();
    final selectedId = (_selectedAttractionId ?? '').trim();
    final result = await context.push<ExcursionLocationSelection>(
      '/excursions/create/location',
      extra: ExcursionLocationPickerArgs(
        countryCode: countryCode,
        initialSelection: selectedId.isEmpty
            ? null
            : ExcursionLocationSelection(
                id: selectedId,
                name: (_selectedAttractionName ?? '').trim(),
                countryCode: countryCode,
                latitude: _selectedLatitude,
                longitude: _selectedLongitude,
              ),
      ),
    );
    if (!mounted || result == null) return;

    final attractionId = result.id.trim();
    if (_isReservedAttraction(attractionId)) {
      setState(() {
        _attractionErrorText =
            widget.l10n.createExcursionDuplicateRouteStopValidation;
      });
      return;
    }

    setState(() {
      _selectedAttractionId = attractionId.isEmpty ? null : attractionId;
      _selectedAttractionName = result.name.trim();
      _selectedCountryCode = result.countryCode.trim().toUpperCase();
      _selectedLatitude = result.latitude;
      _selectedLongitude = result.longitude;
      _titleCtrl.text = result.name.trim();
      _attractionErrorText = null;
      _errorText = null;
    });
  }

  bool _isReservedAttraction(String attractionId) {
    final normalized = attractionId.trim();
    return normalized.isNotEmpty &&
        widget.reservedAttractionIds.contains(normalized);
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
      attractionId: _selectedAttractionId,
      attractionName: _selectedAttractionName,
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
      travelFromPreviousMinutes: widget.initialItem?.travelFromPreviousMinutes,
    );
    String? formErrorText;
    String? attractionErrorText;
    String? offsetErrorText;
    String? titleErrorText;
    String? descriptionErrorText;
    final isCompleteDraft = _isCompleteItineraryDraft(draft);
    if (widget.enableAttractionSelection &&
        (draft.attractionId ?? '').trim().isEmpty) {
      attractionErrorText = widget.l10n.createExcursionLandmarkValidation;
    }
    if (widget.enableAttractionSelection &&
        _isReservedAttraction(draft.attractionId ?? '')) {
      attractionErrorText =
          widget.l10n.createExcursionDuplicateRouteStopValidation;
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
    if (attractionErrorText != null ||
        offsetErrorText != null ||
        titleErrorText != null ||
        descriptionErrorText != null) {
      formErrorText = null;
      setState(() {
        _errorText = formErrorText;
        _attractionErrorText = attractionErrorText;
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF2D1E11),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                  if (widget.enableAttractionSelection) ...[
                    _LandmarkSelectionCard(
                      landmarkName: _selectedAttractionName ?? '',
                      cityName: '',
                      hasSelection: (_selectedAttractionId ?? '')
                          .trim()
                          .isNotEmpty,
                      errorText: _attractionErrorText,
                      onSelectLocation: _openStopAttractionSelector,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _ExcursionTextField(
                          controller: _offsetCtrl,
                          label: widget.l10n.createExcursionStartOffsetLabel,
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
                          label: widget.l10n.createExcursionSlotDurationLabel,
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
                        widget.enableAttractionSelection &&
                        (_selectedAttractionId ?? '').trim().isNotEmpty,
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
                    label: widget.l10n.createExcursionItineraryDescriptionLabel,
                    hint: widget.l10n.createExcursionItineraryDescriptionHint,
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
                      style: const TextStyle(color: Color(0xFFFFB199)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        widget.l10n.confirm,
                        style: const TextStyle(color: AppColors.textPrimary),
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
