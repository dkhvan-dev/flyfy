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
import '../../features/excursions/models/create_excursion_request.dart';
import '../../features/excursions/models/excursion_vm.dart';
import '../../features/excursions/excursion_localization.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/excursion_provider.dart';
import 'excursion_select_location_screen.dart';

class CreateExcursionScreen extends StatefulWidget {
  const CreateExcursionScreen(
      {super.key, this.excursionId, this.initialExcursion});

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

  final _pageController = PageController();
  final _imagePicker = ImagePicker();
  final _fileApi = FileApi();
  final MapController _mapController = MapController();
  var _currentStep = 0;
  var _isSubmitting = false;
  var _isLoadingInitialExcursion = false;
  var _didApplyInitialExcursion = false;

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
  String? _selectedCountryCode;
  String? _selectedLandmarkId;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAttractionCoverFileId;
  String? _selectedAttractionCoverImageUrl;
  Map<String, CreateExcursionLocalizedCopyRequest> _productTranslations =
      const {};
  Uint8List? _coverPreviewBytes;
  String? _coverFileId;
  bool _coverChanged = false;
  bool _isCoverUploading = false;
  String? _coverUploadErrorMessage;
  bool _isTrackingStepBackSwipe = false;
  double _stepBackSwipeDistance = 0;
  int _mapSelectionRequestSerial = 0;
  String? _stepErrorText;
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
    _selectedLandmarkId = (excursion.landmarkId ?? '').trim().isEmpty
        ? null
        : excursion.landmarkId!.trim();
    _selectedCountryCode = (excursion.countryCode ?? '').trim().isEmpty
        ? null
        : excursion.countryCode!.trim().toUpperCase();
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
    FocusScope.of(context).unfocus();
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
      _submit();
      return;
    }
    _goToStep(_currentStep + 1);
  }

  bool _validateCurrentStep() {
    final l10n = AppLocalizations.of(context)!;
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
    if (_itinerary.isEmpty ||
        _itinerary.any(
          (item) =>
              item.title.trim().isEmpty || item.description.trim().isEmpty,
        )) {
      return l10n.createExcursionItineraryValidation;
    }
    return null;
  }

  String? _validateLandmarkStep(AppLocalizations l10n) {
    if (!_hasSelectedCountry) {
      return l10n.createExcursionCountryValidation;
    }
    if (!_hasSelectedAttraction) {
      return l10n.createExcursionLandmarkValidation;
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
      return l10n.createExcursionDurationValidation;
    }
    if (groupSize == null || groupSize < 1 || groupSize > 100) {
      return l10n.createExcursionGroupSizeValidation;
    }
    if (_selectedLanguageCodes.isEmpty) {
      return l10n.createExcursionLanguagesValidation;
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
      return l10n.createLocationValidation;
    }
    final price = double.tryParse(_priceAmountCtrl.text.trim());
    if (price == null || price < 0) {
      return l10n.createPriceValidation;
    }
    if (_selectedCurrencyCode.trim().isEmpty) {
      return l10n.createExcursionCurrencyValidation;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_validateCurrentStep() || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<ExcursionProvider>();
    final request = _buildRequest();
    final saved = _isEditMode
        ? await provider.updateExcursionOffer(
            widget.excursionId!.trim(), request)
        : await provider.createAndPublishExcursion(request);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final l10n = AppLocalizations.of(context)!;
    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? l10n.createExcursionUpdateSuccess
                : l10n.createExcursionSuccess,
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
      message: provider.actionErrorMessage ??
          (_isEditMode
              ? l10n.createExcursionUpdateFailed
              : l10n.createExcursionFailed),
    );
  }

  CreateExcursionRequest _buildRequest() {
    final price = double.tryParse(_priceAmountCtrl.text.trim()) ?? 0;
    return CreateExcursionRequest(
      landmarkName: _landmarkNameCtrl.text.trim(),
      landmarkId: _selectedLandmarkId,
      categorySlug: _selectedCategorySlug,
      productTranslations: _productTranslationsForRequest(),
      durationMinutes: _durationMinutesFromInput() ?? 60,
      maxGroupSize: int.tryParse(_maxGroupSizeCtrl.text.trim()) ?? 1,
      languageCodes: _selectedLanguageCodes.toList(growable: false),
      visibility: _visibility,
      meetingPoint: _meetingPointCtrl.text.trim(),
      countryCode: _selectedCountryCode,
      cityName: _cityNameCtrl.text.trim(),
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
      mapUrl: _mapUrlCtrl.text.trim(),
      priceAmount: price,
      currency: _selectedCurrencyCode,
      coverFileId: _offerCoverFileId,
      productCoverFileId: _productCoverFileId,
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
        _stepErrorText = null;
        return;
      }

      if (_selectedLanguageCodes.length >= _maxExcursionLanguages) {
        _stepErrorText = AppLocalizations.of(
          context,
        )!
            .createExcursionLanguagesLimitValidation(_maxExcursionLanguages);
        return;
      }

      _selectedLanguageCodes.add(normalized);
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
      List<String> values) {
    final seen = <_ExcursionIncludedItemType>{};
    final items = <_ExcursionIncludedItemDraft>[];
    for (final value in values) {
      final item = _ExcursionIncludedItemDraft.fromPayload(value);
      if (!seen.add(item.type)) continue;
      items.add(item);
    }
    return items;
  }

  Future<void> _openCountryPicker() async {
    if (_isEditMode) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ExcursionCountryPickerSheet(selectedCode: _selectedCountryCode),
    );

    if (result == null || !mounted) return;
    final normalized = result.trim().toUpperCase();
    if (normalized == (_selectedCountryCode ?? '').trim().toUpperCase()) {
      return;
    }

    setState(() {
      _selectedCountryCode = normalized;
      _selectedLandmarkId = null;
      _selectedLatitude = null;
      _selectedLongitude = null;
      _selectedAttractionCoverFileId = null;
      _selectedAttractionCoverImageUrl = null;
      _productTranslations = const {};
      _landmarkNameCtrl.clear();
      _cityNameCtrl.clear();
      _mapUrlCtrl.clear();
      _stepErrorText = null;
    });
  }

  bool get _hasSelectedMapPoint =>
      _selectedLatitude != null && _selectedLongitude != null;

  bool get _hasSelectedCountry =>
      (_selectedCountryCode ?? '').trim().isNotEmpty;

  bool get _hasSelectedAttraction =>
      (_selectedLandmarkId ?? '').trim().isNotEmpty;

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

  String? get _effectiveCoverImageUrl {
    if (_coverPreviewBytes?.isNotEmpty ?? false) {
      return null;
    }
    final attractionImage = (_selectedAttractionCoverImageUrl ?? '').trim();
    return attractionImage.isEmpty ? null : attractionImage;
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

    setState(() {
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

    final l10n = AppLocalizations.of(context)!;
    if (!_hasSelectedCountry) {
      setState(() => _stepErrorText = l10n.createExcursionCountryValidation);
      return;
    }

    FocusScope.of(context).unfocus();
    final result = await context.push<ExcursionLocationSelection>(
      '/excursions/create/location',
      extra: ExcursionLocationPickerArgs(
        countryCode: _selectedCountryCode!,
        initialSelection: ExcursionLocationSelection(
          id: _selectedLandmarkId ?? '',
          name: _landmarkNameCtrl.text.trim(),
          countryCode: _selectedCountryCode!,
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
      if ((result.cityName ?? '').trim().isNotEmpty) {
        _cityNameCtrl.text = result.cityName!.trim();
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
      _stepErrorText = null;
    });
    _moveMapToSelection();
  }

  Future<void> _openItineraryEditor() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<_ExcursionItineraryDraft>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddItinerarySlotSheet(l10n: l10n),
    );
    if (result == null) return;

    setState(() {
      _itinerary.add(result);
      _itinerary.sort(
        (left, right) =>
            left.startOffsetMinutes.compareTo(right.startOffsetMinutes),
      );
      _stepErrorText = null;
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
    final shouldGoBack = _isTrackingStepBackSwipe &&
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
                      if (_stepErrorText != null)
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
                        isSubmitting: _isSubmitting || _isCoverUploading,
                        onPressed: _nextStep,
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
        _ItineraryEmptyState(message: l10n.createExcursionItineraryEmpty),
        const SizedBox(height: 12),
      ],
      ..._itinerary.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ItinerarySlotCard(
            item: item,
            onDelete: () => setState(() => _itinerary.remove(item)),
          ),
        ),
      ),
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
        _ExcursionCountryPickerField(
          selectedCode: _selectedCountryCode,
          onTap: _openCountryPicker,
        ),
        const SizedBox(height: 12),
        _LandmarkSelectionCard(
          landmarkName: _landmarkNameCtrl.text,
          cityName: _cityNameCtrl.text,
          hasSelection: _hasSelectedAttraction,
          onSelectLocation: _hasSelectedCountry ? _openLocationSelector : null,
        ),
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
          onUnitChanged: (unit) => setState(() {
            _selectedDurationUnit = unit;
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
        ),
        const SizedBox(height: 16),
        _ExcursionLanguagePickerField(
          selectedCodes: _selectedLanguageCodes,
          maxSelected: _maxExcursionLanguages,
          onToggle: _toggleLanguageCode,
          label: l10n.createExcursionLanguagesLabel,
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
        ),
        const SizedBox(height: 12),
        _CurrencyPickerField(
          label: l10n.createCurrencyLabel,
          selectedCode: _selectedCurrencyCode,
          onChanged: (value) => setState(() {
            _selectedCurrencyCode = value;
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
  });

  final TextEditingController controller;
  final _ExcursionDurationUnit selectedUnit;
  final ValueChanged<_ExcursionDurationUnit> onUnitChanged;

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
              const Icon(
                Icons.timelapse_rounded,
                color: AppColors.accent,
              ),
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
    this.durationMinutes,
  });

  final int startOffsetMinutes;
  final int? durationMinutes;
  final String title;
  final String description;
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
        type: _excursionIncludedItemTypeFromName(value));
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
    'көлік' =>
      _ExcursionIncludedItemType.transport,
    'food' ||
    'meal' ||
    'meals' ||
    'питание' ||
    'еда' ||
    'тамақ' =>
      _ExcursionIncludedItemType.food,
    'tickets' ||
    'ticket' ||
    'билеты' ||
    'билет' ||
    'билеттер' =>
      _ExcursionIncludedItemType.tickets,
    'equipment' ||
    'gear' ||
    'снаряжение' ||
    'жабдық' =>
      _ExcursionIncludedItemType.equipment,
    'guide' || 'гид' => _ExcursionIncludedItemType.guide,
    'photo' || 'photos' || 'фото' => _ExcursionIncludedItemType.photo,
    _ => _ExcursionIncludedItemType.other,
  };
}

class ExcursionCountryOption {
  const ExcursionCountryOption(
      {required this.code, required this.searchAliases});

  final String code;
  final List<String> searchAliases;

  String label(AppLocalizations l10n) {
    return switch (code) {
      'KZ' => l10n.excursionCountryKazakhstan,
      'FR' => l10n.excursionCountryFrance,
      'JP' => l10n.excursionCountryJapan,
      'IT' => l10n.excursionCountryItaly,
      _ => code,
    };
  }

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    if (code.toLowerCase().contains(normalized)) return true;
    return searchAliases.any(
      (value) => value.toLowerCase().contains(normalized),
    );
  }
}

const excursionCountryOptions = [
  ExcursionCountryOption(
    code: 'KZ',
    searchAliases: ['Kazakhstan', 'Казахстан', 'Қазақстан'],
  ),
  ExcursionCountryOption(code: 'FR', searchAliases: ['France', 'Франция']),
  ExcursionCountryOption(
      code: 'JP', searchAliases: ['Japan', 'Япония', 'Жапония']),
  ExcursionCountryOption(code: 'IT', searchAliases: ['Italy', 'Италия']),
];

ExcursionCountryOption? findExcursionCountryOption(String? code) {
  final normalized = (code ?? '').trim().toUpperCase();
  if (normalized.isEmpty) return null;
  for (final option in excursionCountryOptions) {
    if (option.code == normalized) return option;
  }
  return null;
}

class _ExcursionLanguagePickerField extends StatelessWidget {
  const _ExcursionLanguagePickerField({
    required this.selectedCodes,
    required this.maxSelected,
    required this.onToggle,
    required this.label,
  });

  static const _availableCodes = ['en', 'ru', 'kk', 'fr', 'ja'];

  final Set<String> selectedCodes;
  final int maxSelected;
  final ValueChanged<String> onToggle;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _ExcursionFieldShell(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2115),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.10)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final code in _availableCodes)
                    _ExcursionLanguageChip(
                      label: localizedExcursionLanguageLabel(l10n, code),
                      selected: selectedCodes.contains(code),
                      disabled: !selectedCodes.contains(code) &&
                          selectedCodes.length >= maxSelected,
                      onTap: () => onToggle(code),
                    ),
                ],
              ),
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
  const _ExcursionIncludedItemsPreview(
      {required this.items, required this.onTap});

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
    final items = selectedTypes
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

class _ExcursionCountryPickerField extends StatelessWidget {
  const _ExcursionCountryPickerField({
    required this.selectedCode,
    required this.onTap,
  });

  final String? selectedCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final option = findExcursionCountryOption(selectedCode);
    final selectedLabel = option?.label(l10n);

    return _ExcursionFieldShell(
      label: l10n.createCountryLabel,
      child: Material(
        color: const Color(0xFF2D2115),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.public_rounded, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedLabel ?? l10n.createExcursionSelectCountryFirst,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selectedLabel == null
                          ? const Color(0xFFA99683)
                          : const Color(0xFFFFF8F0),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFFA99683),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExcursionCountryPickerSheet extends StatefulWidget {
  const _ExcursionCountryPickerSheet({required this.selectedCode});

  final String? selectedCode;

  @override
  State<_ExcursionCountryPickerSheet> createState() =>
      _ExcursionCountryPickerSheetState();
}

class _ExcursionCountryPickerSheetState
    extends State<_ExcursionCountryPickerSheet> {
  final _searchCtrl = TextEditingController();

  List<ExcursionCountryOption> get _visibleCountries {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return excursionCountryOptions;
    return excursionCountryOptions
        .where((item) => item.matchesQuery(query))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
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
                          l10n.excursionSelectLocationCountrySection,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                  child: _LocationSearchLikeField(
                    controller: _searchCtrl,
                    hintText: l10n.excursionSelectLocationCountrySearchHint,
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                    itemCount: _visibleCountries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final country = _visibleCountries[index];
                      final selected = country.code ==
                          (widget.selectedCode ?? '').trim().toUpperCase();
                      return ListTile(
                        onTap: () => Navigator.of(context).pop(country.code),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        tileColor: selected
                            ? AppColors.accent.withValues(alpha: 0.14)
                            : const Color(0xFF3A2A1D),
                        leading: CircleAvatar(
                          backgroundColor: selected
                              ? AppColors.accent
                              : const Color(0xFF4A321D),
                          foregroundColor: Colors.white,
                          child: Text(country.code),
                        ),
                        title: Text(
                          country.label(l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFFF8F0),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.accent,
                              )
                            : null,
                      );
                    },
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

class _LocationSearchLikeField extends StatelessWidget {
  const _LocationSearchLikeField({
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.fromLTRB(16, 4, 14, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF21170D),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.accent, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: Color(0xFFFFF8F0),
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Color(0xFFA99683)),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
        ],
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
  });

  final String landmarkName;
  final String cityName;
  final bool hasSelection;
  final VoidCallback? onSelectLocation;

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

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF9A673A), Color(0xFF533018)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.10),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.42),
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
        errorBuilder: (_, __, ___) => _buildPlaceholder(hasPreview: false),
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
  const _ItineraryEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF4A321D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
    );
  }
}

class _ItinerarySlotCard extends StatelessWidget {
  const _ItinerarySlotCard({required this.item, this.onDelete});

  final _ExcursionItineraryDraft item;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF4A321D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
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
                _formatOffset(item.startOffsetMinutes),
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
    );
  }

  static String _formatOffset(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) {
      return '+${rest}m';
    }
    if (rest == 0) {
      return '+${hours}h';
    }
    return '+${hours}h ${rest}m';
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
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.horizontalScroll = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color? iconColor;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final bool horizontalScroll;

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
          prefixIcon: Icon(icon, color: effectiveIconColor),
          hintStyle: const TextStyle(color: Color(0xFFA99683)),
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

class _CurrencyOption {
  const _CurrencyOption({required this.code, required this.symbol});

  final String code;
  final String symbol;

  String label(AppLocalizations l10n) {
    return switch (code) {
      'KZT' => l10n.createCurrencyKzt,
      'USD' => l10n.createCurrencyUsd,
      'EUR' => l10n.createCurrencyEur,
      'RUB' => l10n.createCurrencyRub,
      'GBP' => l10n.createCurrencyGbp,
      _ => code,
    };
  }
}

const _currencyOptions = [
  _CurrencyOption(code: 'KZT', symbol: '₸'),
  _CurrencyOption(code: 'USD', symbol: r'$'),
  _CurrencyOption(code: 'EUR', symbol: '€'),
  _CurrencyOption(code: 'RUB', symbol: '₽'),
  _CurrencyOption(code: 'GBP', symbol: '£'),
];

class _CurrencyPickerField extends StatelessWidget {
  const _CurrencyPickerField({
    required this.label,
    required this.selectedCode,
    required this.onChanged,
  });

  final String label;
  final String selectedCode;
  final ValueChanged<String> onChanged;

  _CurrencyOption get _selectedOption {
    return _currencyOptions.firstWhere(
      (option) => option.code == selectedCode,
      orElse: () => _currencyOptions.first,
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF2D2115),
                borderRadius: BorderRadius.circular(28),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(12),
                itemCount: _currencyOptions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.accent.withValues(alpha: 0.10),
                ),
                itemBuilder: (context, index) {
                  final option = _currencyOptions[index];
                  final selected = option.code == selectedCode;
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(option.code),
                    leading: CircleAvatar(
                      backgroundColor:
                          selected ? AppColors.accent : const Color(0xFF3A2A1D),
                      foregroundColor: Colors.white,
                      child: Text(option.symbol),
                    ),
                    title: Text(
                      option.label(l10n),
                      style: const TextStyle(
                        color: Color(0xFFFFF8F0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.accent,
                          )
                        : Text(
                            option.code,
                            style: const TextStyle(
                              color: Color(0xFFA99683),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (result != null && result != selectedCode) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedOption = _selectedOption;

    return _ExcursionFieldShell(
      label: label,
      child: Material(
        color: const Color(0xFF2D2115),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              children: [
                Text(
                  selectedOption.symbol,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    selectedOption.label(l10n),
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
                  color: Color(0xFFA99683),
                ),
              ],
            ),
          ),
        ),
      ),
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
                        color:
                            selected ? Colors.white : const Color(0xFFFFE3B8),
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
                  userAgentPackageName: 'dev.dkhvan.flyfy.superapp',
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
  });

  final String label;
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + bottomInset),
      child: SizedBox(
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
            disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.55),
            padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 20),
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
    );
  }
}

class _AddItinerarySlotSheet extends StatefulWidget {
  const _AddItinerarySlotSheet({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_AddItinerarySlotSheet> createState() => _AddItinerarySlotSheetState();
}

class _AddItinerarySlotSheetState extends State<_AddItinerarySlotSheet> {
  final _offsetCtrl = TextEditingController(text: '180');
  final _durationCtrl = TextEditingController(text: '60');
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _offsetCtrl.dispose();
    _durationCtrl.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final offset = int.tryParse(_offsetCtrl.text.trim());
    final duration = int.tryParse(_durationCtrl.text.trim());
    if (offset == null || offset < 0 || _titleCtrl.text.trim().isEmpty) {
      setState(
          () => _errorText = widget.l10n.createExcursionItineraryValidation);
      return;
    }
    Navigator.of(context).pop(
      _ExcursionItineraryDraft(
        startOffsetMinutes: offset,
        durationMinutes: duration,
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
      ),
    );
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
                  _SectionHeader(title: widget.l10n.createExcursionAddTimeSlot),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ExcursionTextField(
                          controller: _offsetCtrl,
                          label: widget.l10n.createExcursionStartOffsetLabel,
                          hint: '120',
                          icon: Icons.schedule_rounded,
                          keyboardType: TextInputType.number,
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
                  ),
                  const SizedBox(height: 12),
                  _ExcursionTextField(
                    controller: _descriptionCtrl,
                    label: widget.l10n.createExcursionItineraryDescriptionLabel,
                    hint: widget.l10n.createExcursionItineraryDescriptionHint,
                    icon: Icons.notes_rounded,
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
