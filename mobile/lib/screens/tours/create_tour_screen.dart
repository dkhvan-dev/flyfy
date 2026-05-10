import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/tours/models/create_tour_request.dart';
import '../../features/tours/tour_localization.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/tour_provider.dart';
import 'tour_select_location_screen.dart';

class CreateTourScreen extends StatefulWidget {
  const CreateTourScreen({super.key});

  @override
  State<CreateTourScreen> createState() => _CreateTourScreenState();
}

class _CreateTourScreenState extends State<CreateTourScreen> {
  static const _totalSteps = 3;
  static const LatLng _fallbackMapTarget = LatLng(43.238949, 76.889709);
  static const double _stepBackSwipeMinDistance = 56;
  static const double _stepBackSwipeMinVelocity = 700;
  static const int _maxCoverUploadBytes = 20 * 1024 * 1024;
  static const int _maxTourLanguages = 5;

  final _pageController = PageController();
  final _imagePicker = ImagePicker();
  final _fileApi = FileApi();
  final MapController _mapController = MapController();
  var _currentStep = 0;
  var _isSubmitting = false;

  final _landmarkNameCtrl = TextEditingController();
  final _cityNameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '4 hours');
  final _maxGroupSizeCtrl = TextEditingController(text: '8');
  final _meetingPointCtrl = TextEditingController();
  final _mapUrlCtrl = TextEditingController();
  final _priceAmountCtrl = TextEditingController();

  var _selectedCategorySlug = 'adventure';
  var _visibility = 'PUBLIC';
  var _selectedCurrencyCode = 'KZT';
  String? _selectedCountryCode;
  String? _selectedLandmarkId;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAttractionCoverFileId;
  String? _selectedAttractionCoverImageUrl;
  var _isApplyingLocationSelection = false;
  Uint8List? _coverPreviewBytes;
  String? _coverFileId;
  bool _coverChanged = false;
  bool _isCoverUploading = false;
  String? _coverUploadErrorMessage;
  bool _isTrackingStepBackSwipe = false;
  double _stepBackSwipeDistance = 0;
  String? _stepErrorText;
  final Set<String> _selectedLanguageCodes = {'en', 'ru'};
  final List<_TourIncludedItemDraft> _includedItems = [];

  final List<_TourItineraryDraft> _itinerary = [
    _TourItineraryDraft(
      startOffsetMinutes: 0,
      durationMinutes: 45,
      title: 'Meet at base camp',
      description: 'Meet your guide, check gear, and align on the route.',
    ),
    _TourItineraryDraft(
      startOffsetMinutes: 120,
      durationMinutes: 90,
      title: 'Mountain ascent and photography',
      description: 'Walk to the scenic ridge and stop for photo moments.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _landmarkNameCtrl.addListener(_handleLocationTextEdited);
    _cityNameCtrl.addListener(_handleLocationTextEdited);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _landmarkNameCtrl.removeListener(_handleLocationTextEdited);
    _cityNameCtrl.removeListener(_handleLocationTextEdited);
    _landmarkNameCtrl.dispose();
    _cityNameCtrl.dispose();
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _descriptionCtrl.dispose();
    _tagsCtrl.dispose();
    _durationCtrl.dispose();
    _maxGroupSizeCtrl.dispose();
    _meetingPointCtrl.dispose();
    _mapUrlCtrl.dispose();
    _priceAmountCtrl.dispose();
    super.dispose();
  }

  void _handleLocationTextEdited() {
    if (_isApplyingLocationSelection ||
        (_selectedLandmarkId == null &&
            _selectedLatitude == null &&
            _selectedLongitude == null)) {
      return;
    }
    setState(() {
      _selectedLandmarkId = null;
      _selectedLatitude = null;
      _selectedLongitude = null;
      _selectedAttractionCoverFileId = null;
      _selectedAttractionCoverImageUrl = null;
    });
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
    final error = switch (_currentStep) {
      0 => _validateLandmarkStep(l10n),
      1 => _validateLogisticsStep(l10n),
      _ => _validateStoryAndPriceStep(l10n),
    };
    setState(() => _stepErrorText = error);
    return error == null;
  }

  String? _validateLandmarkStep(AppLocalizations l10n) {
    if (!_hasSelectedCountry) {
      return l10n.createTourCountryValidation;
    }
    if (_landmarkNameCtrl.text.trim().isEmpty) {
      return l10n.createTourLandmarkValidation;
    }
    if (_selectedCategorySlug.trim().isEmpty) {
      return l10n.createCategoryValidation;
    }
    if (_itinerary.isEmpty ||
        _itinerary.any(
          (item) =>
              item.title.trim().isEmpty || item.description.trim().isEmpty,
        )) {
      return l10n.createTourItineraryValidation;
    }
    return null;
  }

  String? _validateLogisticsStep(AppLocalizations l10n) {
    final durationMinutes = _parseDurationMinutes(_durationCtrl.text);
    final groupSize = int.tryParse(_maxGroupSizeCtrl.text.trim());

    if (durationMinutes == null || durationMinutes < 15) {
      return l10n.createTourDurationValidation;
    }
    if (groupSize == null || groupSize < 1 || groupSize > 100) {
      return l10n.createTourGroupSizeValidation;
    }
    if (_selectedLanguageCodes.isEmpty) {
      return l10n.createTourLanguagesValidation;
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
    if (_titleCtrl.text.trim().length < 3) {
      return l10n.createTitleValidation;
    }
    if (_summaryCtrl.text.trim().length < 3) {
      return l10n.createTourSummaryValidation;
    }
    if (_descriptionCtrl.text.trim().length < 20) {
      return l10n.createTourDescriptionValidation;
    }
    if (_meetingPointCtrl.text.trim().isEmpty) {
      return l10n.createLocationValidation;
    }
    final price = double.tryParse(_priceAmountCtrl.text.trim());
    if (price == null || price < 0) {
      return l10n.createPriceValidation;
    }
    if (_selectedCurrencyCode.trim().isEmpty) {
      return l10n.createTourCurrencyValidation;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_validateCurrentStep() || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<TourProvider>();
    final created = await provider.createAndPublishTour(_buildRequest());

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final l10n = AppLocalizations.of(context)!;
    if (created != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.createTourSuccess)));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
      return;
    }

    await showErrorDialog(
      context,
      title: l10n.error,
      message: provider.actionErrorMessage ?? l10n.createTourFailed,
    );
  }

  CreateTourRequest _buildRequest() {
    final price = double.tryParse(_priceAmountCtrl.text.trim()) ?? 0;
    return CreateTourRequest(
      landmarkName: _landmarkNameCtrl.text.trim(),
      landmarkId: _selectedLandmarkId,
      title: _titleCtrl.text.trim(),
      summary: _summaryCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      categorySlug: _selectedCategorySlug,
      tags: _parseCommaList(_tagsCtrl.text),
      durationMinutes: _parseDurationMinutes(_durationCtrl.text) ?? 60,
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
      coverFileId: _effectiveCoverFileId,
      includedItems: _includedItems
          .map((item) => item.toPayload())
          .toList(growable: false),
      itinerary: _itinerary
          .map(
            (item) => CreateTourItineraryItemRequest(
              startOffsetMinutes: item.startOffsetMinutes,
              durationMinutes: item.durationMinutes,
              title: item.title,
              description: item.description,
            ),
          )
          .toList(growable: false),
    );
  }

  int? _parseDurationMinutes(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    final direct = int.tryParse(normalized);
    if (direct != null) {
      return direct;
    }
    final numberMatch = RegExp(r'\d+([.,]\d+)?').firstMatch(normalized);
    if (numberMatch == null) {
      return null;
    }
    final amount = double.tryParse(
      numberMatch.group(0)!.replaceAll(',', '.'),
    );
    if (amount == null) {
      return null;
    }
    final isHour = normalized.contains('hour') ||
        normalized.contains('hr') ||
        normalized.contains('час') ||
        normalized.contains('сағ');
    return (amount * (isHour ? 60 : 1)).round();
  }

  List<String> _parseCommaList(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  void _toggleLanguageCode(String code) {
    final normalized = code.trim().toLowerCase();
    if (normalized.isEmpty) return;

    setState(() {
      if (_selectedLanguageCodes.contains(normalized)) {
        _selectedLanguageCodes.remove(normalized);
        _stepErrorText = null;
        return;
      }

      if (_selectedLanguageCodes.length >= _maxTourLanguages) {
        _stepErrorText = AppLocalizations.of(context)!
            .createTourLanguagesLimitValidation(_maxTourLanguages);
        return;
      }

      _selectedLanguageCodes.add(normalized);
      _stepErrorText = null;
    });
  }

  Future<void> _openIncludedItemsEditor() async {
    final result = await showModalBottomSheet<List<_TourIncludedItemDraft>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TourIncludedItemsEditorSheet(
        initialItems: _includedItems,
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _includedItems
        ..clear()
        ..addAll(result);
      _stepErrorText = null;
    });
  }

  Future<void> _openCountryPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TourCountryPickerSheet(
        selectedCode: _selectedCountryCode,
      ),
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

  bool get _isLocationEditingEnabled =>
      _hasSelectedCountry && !_hasSelectedAttraction;

  String? get _effectiveCoverFileId {
    final customCover = (_coverFileId ?? '').trim();
    if (customCover.isNotEmpty) {
      return customCover;
    }
    final attractionCover = (_selectedAttractionCoverFileId ?? '').trim();
    return attractionCover.isEmpty ? null : attractionCover;
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

  void _handleMapTapped(LatLng position) {
    setState(() {
      _selectedLatitude = position.latitude;
      _selectedLongitude = position.longitude;
      _mapUrlCtrl.text = _buildMapUrl(position.latitude, position.longitude);
      if (_meetingPointCtrl.text.trim().isEmpty) {
        _meetingPointCtrl.text = _landmarkNameCtrl.text.trim();
      }
      _stepErrorText = null;
    });
    _mapController.move(position, 15);
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
      final upload = await _fileApi.createTourCoverUpload(
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
    final safeBase = baseName.isEmpty ? 'tour-cover' : baseName;

    final extension = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };

    return '$safeBase.$extension';
  }

  Future<void> _openLocationSelector() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_hasSelectedCountry) {
      setState(() => _stepErrorText = l10n.createTourCountryValidation);
      return;
    }

    FocusScope.of(context).unfocus();
    final result = await context.push<TourLocationSelection>(
      '/tours/create/location',
      extra: TourLocationPickerArgs(
        countryCode: _selectedCountryCode!,
        initialSelection: TourLocationSelection(
          id: _selectedLandmarkId ?? '',
          name: _landmarkNameCtrl.text.trim(),
          countryCode: _selectedCountryCode!,
          cityName: _cityNameCtrl.text.trim(),
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          mapUrl: _mapUrlCtrl.text.trim(),
          coverFileId: _selectedAttractionCoverFileId,
          coverImageUrl: _selectedAttractionCoverImageUrl,
        ),
      ),
    );
    if (!mounted || result == null) return;
    _isApplyingLocationSelection = true;
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
    _isApplyingLocationSelection = false;
    _moveMapToSelection();
  }

  Future<void> _openItineraryEditor() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<_TourItineraryDraft>(
      context: context,
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
                      _TourTopBar(
                        title: l10n.createTourTitle,
                        onBack: _currentStep == 0
                            ? () => context.pop()
                            : () => _goToStep(_currentStep - 1),
                      ),
                      _TourStepIndicator(
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
                          children: [
                            _buildStepLandmark(l10n, bottomInset),
                            _buildStepLogistics(l10n, bottomInset),
                            _buildStepStoryAndPrice(l10n, bottomInset),
                          ],
                        ),
                      ),
                      _TourBottomActionBar(
                        label: _currentStep == _totalSteps - 1
                            ? l10n.createTourSubmit
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

  Widget _buildStepLandmark(AppLocalizations l10n, double bottomInset) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
      children: [
        _SectionHeader(
          title: l10n.createTourSelectedLandmark,
          actionLabel: _hasSelectedCountry ? l10n.change : null,
          onActionTap: _hasSelectedCountry ? _openLocationSelector : null,
        ),
        const SizedBox(height: 12),
        _TourCountryPickerField(
          selectedCode: _selectedCountryCode,
          onTap: _openCountryPicker,
        ),
        const SizedBox(height: 12),
        _LandmarkCard(
          landmarkNameController: _landmarkNameCtrl,
          cityNameController: _cityNameCtrl,
          isEditable: _isLocationEditingEnabled,
          isLockedByAttraction: _hasSelectedAttraction,
          onSelectLocation: _hasSelectedCountry ? _openLocationSelector : null,
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: l10n.createTourCoverSection),
        const SizedBox(height: 12),
        _TourCoverUploadCard(
          title: _hasAnyCoverPreview
              ? l10n.createTourCoverChangeAction
              : l10n.createTourCoverUploadTitle,
          hint: _coverUploadErrorMessage ?? l10n.createTourCoverUploadHint,
          imageUrl: _effectiveCoverImageUrl,
          previewBytes: _coverPreviewBytes,
          isUploading: _isCoverUploading,
          hasError: _coverUploadErrorMessage != null,
          onTap: _pickCoverImage,
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: l10n.createTourCategorization),
        const SizedBox(height: 12),
        _CategoryGrid(
          selectedSlug: _selectedCategorySlug,
          onSelected: (value) => setState(() {
            _selectedCategorySlug = value;
            _stepErrorText = null;
          }),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: l10n.createTourDetailedItinerary),
        const SizedBox(height: 12),
        ..._itinerary.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ItinerarySlotCard(
              item: item,
              onDelete: _itinerary.length == 1
                  ? null
                  : () => setState(() => _itinerary.remove(item)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _OutlineActionButton(
          icon: Icons.add_rounded,
          label: l10n.createTourAddTimeSlot,
          onTap: _openItineraryEditor,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.createTourAutosaveHint,
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
        _TourTextField(
          controller: _durationCtrl,
          label: l10n.createTourDurationLabel,
          hint: l10n.createTourDurationHint,
          icon: Icons.schedule_rounded,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        _TourTextField(
          controller: _maxGroupSizeCtrl,
          label: l10n.createTourMaxGroupSizeLabel,
          hint: l10n.createTourMaxGroupSizeHint,
          icon: Icons.group_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _TourLanguagePickerField(
          selectedCodes: _selectedLanguageCodes,
          maxSelected: _maxTourLanguages,
          onToggle: _toggleLanguageCode,
          label: l10n.createTourLanguagesLabel,
        ),
        const SizedBox(height: 26),
        _SectionHeader(title: l10n.createTourVisibilityTitle),
        const SizedBox(height: 12),
        _VisibilityCard(
          title: l10n.createVisibilityPublic,
          description: l10n.createTourVisibilityPublicDescription,
          icon: Icons.public_rounded,
          selected: _visibility == 'PUBLIC',
          onTap: () => setState(() => _visibility = 'PUBLIC'),
        ),
        const SizedBox(height: 12),
        _VisibilityCard(
          title: l10n.createVisibilityByLink,
          description: l10n.createTourVisibilityUnlistedDescription,
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
        _TourTextField(
          controller: _meetingPointCtrl,
          label: l10n.createMeetingPointLocationLabel,
          hint: l10n.createTourMeetingPointHint,
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 12),
        _TourTextField(
          controller: _mapUrlCtrl,
          label: l10n.createMapLinkLabel,
          hint: l10n.createMapLinkHint,
          icon: Icons.link_rounded,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 14),
        _TourMapPickerCard(
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
        const SizedBox(height: 24),
        _SectionHeader(title: l10n.createTourSoulTitle),
        const SizedBox(height: 12),
        _TourTextField(
          controller: _titleCtrl,
          label: l10n.createTourNameLabel,
          hint: l10n.createTourNameHint,
          icon: Icons.flag_outlined,
        ),
        const SizedBox(height: 12),
        _TourTextField(
          controller: _summaryCtrl,
          label: l10n.createTourSummaryLabel,
          hint: l10n.createTourSummaryHint,
          icon: Icons.short_text_rounded,
        ),
        const SizedBox(height: 12),
        _TourTextField(
          controller: _descriptionCtrl,
          label: l10n.createDescriptionLabel,
          hint: l10n.createTourSoulHint,
          icon: Icons.auto_stories_outlined,
          minLines: 5,
          maxLines: 8,
        ),
        const SizedBox(height: 20),
        _SectionHeader(title: l10n.createTourInvestmentTitle),
        const SizedBox(height: 12),
        _TourTextField(
          controller: _priceAmountCtrl,
          label: l10n.createPriceAmountLabel,
          hint: '0.00',
          icon: Icons.payments_outlined,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
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
          title: l10n.createTourIncludedItemsLabel,
          actionLabel: l10n.change,
          onActionTap: _openIncludedItemsEditor,
        ),
        const SizedBox(height: 12),
        _TourIncludedItemsPreview(
          items: _includedItems,
          onTap: _openIncludedItemsEditor,
        ),
        const SizedBox(height: 12),
        _TourTextField(
          controller: _tagsCtrl,
          label: l10n.createTagsLabel,
          hint: l10n.createTagsHint,
          icon: Icons.local_offer_outlined,
        ),
      ],
    );
  }
}

class _TourItineraryDraft {
  const _TourItineraryDraft({
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

enum _TourIncludedItemType {
  transport,
  food,
  tickets,
  equipment,
  guide,
  photo,
  other,
}

extension _TourIncludedItemTypeUi on _TourIncludedItemType {
  IconData get icon {
    return switch (this) {
      _TourIncludedItemType.transport => Icons.directions_car_filled_rounded,
      _TourIncludedItemType.food => Icons.restaurant_rounded,
      _TourIncludedItemType.tickets => Icons.confirmation_number_rounded,
      _TourIncludedItemType.equipment => Icons.backpack_rounded,
      _TourIncludedItemType.guide => Icons.person_pin_circle_rounded,
      _TourIncludedItemType.photo => Icons.photo_camera_rounded,
      _TourIncludedItemType.other => Icons.check_circle_rounded,
    };
  }

  String label(AppLocalizations l10n) {
    return switch (this) {
      _TourIncludedItemType.transport => l10n.createTourIncludedTypeTransport,
      _TourIncludedItemType.food => l10n.createTourIncludedTypeFood,
      _TourIncludedItemType.tickets => l10n.createTourIncludedTypeTickets,
      _TourIncludedItemType.equipment => l10n.createTourIncludedTypeEquipment,
      _TourIncludedItemType.guide => l10n.createTourIncludedTypeGuide,
      _TourIncludedItemType.photo => l10n.createTourIncludedTypePhoto,
      _TourIncludedItemType.other => l10n.createTourIncludedTypeOther,
    };
  }
}

class _TourIncludedItemDraft {
  const _TourIncludedItemDraft({
    required this.type,
    required this.title,
  });

  final _TourIncludedItemType type;
  final String title;

  String toPayload() => '${type.name}: ${title.trim()}';
}

class TourCountryOption {
  const TourCountryOption({
    required this.code,
    required this.searchAliases,
  });

  final String code;
  final List<String> searchAliases;

  String label(AppLocalizations l10n) {
    return switch (code) {
      'KZ' => l10n.tourCountryKazakhstan,
      'FR' => l10n.tourCountryFrance,
      'JP' => l10n.tourCountryJapan,
      'IT' => l10n.tourCountryItaly,
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

const tourCountryOptions = [
  TourCountryOption(
    code: 'KZ',
    searchAliases: ['Kazakhstan', 'Казахстан', 'Қазақстан'],
  ),
  TourCountryOption(
    code: 'FR',
    searchAliases: ['France', 'Франция'],
  ),
  TourCountryOption(
    code: 'JP',
    searchAliases: ['Japan', 'Япония', 'Жапония'],
  ),
  TourCountryOption(
    code: 'IT',
    searchAliases: ['Italy', 'Италия'],
  ),
];

TourCountryOption? findTourCountryOption(String? code) {
  final normalized = (code ?? '').trim().toUpperCase();
  if (normalized.isEmpty) return null;
  for (final option in tourCountryOptions) {
    if (option.code == normalized) return option;
  }
  return null;
}

class _TourLanguagePickerField extends StatelessWidget {
  const _TourLanguagePickerField({
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

    return _TourFieldShell(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2115),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.10),
          ),
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
                    _TourLanguageChip(
                      label: localizedTourLanguageLabel(l10n, code),
                      selected: selectedCodes.contains(code),
                      disabled: !selectedCodes.contains(code) &&
                          selectedCodes.length >= maxSelected,
                      onTap: () => onToggle(code),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.createTourLanguagesPickerHint(maxSelected),
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

class _TourLanguageChip extends StatelessWidget {
  const _TourLanguageChip({
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

class _TourIncludedItemsPreview extends StatelessWidget {
  const _TourIncludedItemsPreview({
    required this.items,
    required this.onTap,
  });

  final List<_TourIncludedItemDraft> items;
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
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.10),
            ),
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
                        l10n.createTourIncludedItemsEmpty,
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
                      _TourIncludedItemChip(item: item, l10n: l10n),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TourIncludedItemChip extends StatelessWidget {
  const _TourIncludedItemChip({
    required this.item,
    required this.l10n,
  });

  final _TourIncludedItemDraft item;
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
              '${item.type.label(l10n)}: ${item.title}',
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

class _TourIncludedItemsEditorSheet extends StatefulWidget {
  const _TourIncludedItemsEditorSheet({
    required this.initialItems,
  });

  final List<_TourIncludedItemDraft> initialItems;

  @override
  State<_TourIncludedItemsEditorSheet> createState() =>
      _TourIncludedItemsEditorSheetState();
}

class _TourIncludedItemsEditorSheetState
    extends State<_TourIncludedItemsEditorSheet> {
  late final List<_EditableTourIncludedItem> _drafts;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _drafts = widget.initialItems.isEmpty
        ? [_EditableTourIncludedItem.empty()]
        : widget.initialItems
            .map(_EditableTourIncludedItem.fromDraft)
            .toList(growable: true);
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _drafts.add(_EditableTourIncludedItem.empty());
      _errorText = null;
    });
  }

  void _removeItem(int index) {
    final removed = _drafts.removeAt(index);
    removed.dispose();
    setState(() => _errorText = null);
  }

  void _submit(AppLocalizations l10n) {
    final items = <_TourIncludedItemDraft>[];
    for (final draft in _drafts) {
      final title = draft.controller.text.trim();
      if (title.isEmpty) {
        setState(() => _errorText = l10n.createTourIncludedItemsValidation);
        return;
      }
      items.add(_TourIncludedItemDraft(type: draft.type, title: title));
    }
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
                          l10n.createTourIncludedItemsEditorTitle,
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
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    itemCount: _drafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _TourIncludedItemEditorRow(
                        draft: _drafts[index],
                        canDelete: _drafts.length > 1,
                        onTypeChanged: (type) => setState(() {
                          _drafts[index].type = type;
                          _errorText = null;
                        }),
                        onDelete: () => _removeItem(index),
                      );
                    },
                  ),
                ),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Color(0xFFFFB4A6),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(l10n.createTourIncludedItemsAdd),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFDEB6),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _submit(l10n),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableTourIncludedItem {
  _EditableTourIncludedItem({
    required this.type,
    required String title,
  }) : controller = TextEditingController(text: title);

  factory _EditableTourIncludedItem.empty() {
    return _EditableTourIncludedItem(
      type: _TourIncludedItemType.transport,
      title: '',
    );
  }

  factory _EditableTourIncludedItem.fromDraft(_TourIncludedItemDraft draft) {
    return _EditableTourIncludedItem(
      type: draft.type,
      title: draft.title,
    );
  }

  _TourIncludedItemType type;
  final TextEditingController controller;

  void dispose() => controller.dispose();
}

class _TourIncludedItemEditorRow extends StatelessWidget {
  const _TourIncludedItemEditorRow({
    required this.draft,
    required this.canDelete,
    required this.onTypeChanged,
    required this.onDelete,
  });

  final _EditableTourIncludedItem draft;
  final bool canDelete;
  final ValueChanged<_TourIncludedItemType> onTypeChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF3A2A1D),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<_TourIncludedItemType>(
                    initialValue: draft.type,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D2115),
                    decoration: InputDecoration(
                      labelText: l10n.createTourIncludedItemsTypeLabel,
                      labelStyle: const TextStyle(color: Color(0xFFA99683)),
                      filled: true,
                      fillColor: const Color(0xFF2D2115),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(
                      color: Color(0xFFFFF8F0),
                      fontWeight: FontWeight.w800,
                    ),
                    items: [
                      for (final type in _TourIncludedItemType.values)
                        DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(
                                type.icon,
                                color: AppColors.accent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  type.label(l10n),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) onTypeChanged(value);
                    },
                  ),
                ),
                if (canDelete) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: const Color(0xFFFFB4A6),
                    tooltip: l10n.createTourIncludedItemsRemove,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: draft.controller,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                color: Color(0xFFFFF8F0),
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                labelText: l10n.createTourIncludedItemsValueLabel,
                hintText: l10n.createTourIncludedItemsValueHint,
                labelStyle: const TextStyle(color: Color(0xFFA99683)),
                hintStyle: const TextStyle(color: Color(0xFFA99683)),
                filled: true,
                fillColor: const Color(0xFF2D2115),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourTopBar extends StatelessWidget {
  const _TourTopBar({required this.title, required this.onBack});

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

class _TourStepIndicator extends StatelessWidget {
  const _TourStepIndicator({
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

class _TourCountryPickerField extends StatelessWidget {
  const _TourCountryPickerField({
    required this.selectedCode,
    required this.onTap,
  });

  final String? selectedCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final option = findTourCountryOption(selectedCode);
    final selectedLabel = option?.label(l10n);

    return _TourFieldShell(
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
                    selectedLabel ?? l10n.createTourSelectCountryFirst,
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

class _TourCountryPickerSheet extends StatefulWidget {
  const _TourCountryPickerSheet({required this.selectedCode});

  final String? selectedCode;

  @override
  State<_TourCountryPickerSheet> createState() =>
      _TourCountryPickerSheetState();
}

class _TourCountryPickerSheetState extends State<_TourCountryPickerSheet> {
  final _searchCtrl = TextEditingController();

  List<TourCountryOption> get _visibleCountries {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return tourCountryOptions;
    return tourCountryOptions
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
                          l10n.tourSelectLocationCountrySection,
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
                    hintText: l10n.tourSelectLocationCountrySearchHint,
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

class _LandmarkCard extends StatelessWidget {
  const _LandmarkCard({
    required this.landmarkNameController,
    required this.cityNameController,
    required this.isEditable,
    required this.isLockedByAttraction,
    required this.onSelectLocation,
  });

  final TextEditingController landmarkNameController;
  final TextEditingController cityNameController;
  final bool isEditable;
  final bool isLockedByAttraction;
  final VoidCallback? onSelectLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    children: [
                      _TransparentTextField(
                        controller: landmarkNameController,
                        label: l10n.createTourLandmarkNameLabel,
                        hint: l10n.createTourLandmarkNameHint,
                        enabled: isEditable,
                      ),
                      const SizedBox(height: 10),
                      _TransparentTextField(
                        controller: cityNameController,
                        label: l10n.createCityLabel,
                        hint: l10n.createCityHint,
                        enabled: isEditable,
                      ),
                      const SizedBox(height: 12),
                      _LocationEditHint(
                        isEditable: isEditable,
                        isLockedByAttraction: isLockedByAttraction,
                        onSelectLocation: onSelectLocation,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationEditHint extends StatelessWidget {
  const _LocationEditHint({
    required this.isEditable,
    required this.isLockedByAttraction,
    required this.onSelectLocation,
  });

  final bool isEditable;
  final bool isLockedByAttraction;
  final VoidCallback? onSelectLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = isLockedByAttraction
        ? l10n.createTourLocationLockedByAttraction
        : isEditable
            ? l10n.createTourManualLocationHint
            : l10n.createTourSelectCountryFirst;

    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onSelectLocation,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                isLockedByAttraction
                    ? Icons.lock_rounded
                    : Icons.travel_explore_rounded,
                color: const Color(0xFFFFE5C2),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFFFE5C2),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
              if (onSelectLocation != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFFFE5C2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TourCoverUploadCard extends StatelessWidget {
  const _TourCoverUploadCard({
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
                  child: _TourCoverCardCopy(
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
                    painter: _DashedTourCoverBorderPainter(
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

class _TourCoverCardCopy extends StatelessWidget {
  const _TourCoverCardCopy({
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

class _DashedTourCoverBorderPainter extends CustomPainter {
  const _DashedTourCoverBorderPainter({
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
  bool shouldRepaint(covariant _DashedTourCoverBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _TransparentTextField extends StatelessWidget {
  const _TransparentTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(
        color: enabled ? const Color(0xFFFFF5E8) : const Color(0xFFC9B49D),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFFE8C79D), fontSize: 12),
        hintStyle: TextStyle(
          color: const Color(0xFFFFF5E8).withValues(alpha: 0.48),
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withValues(alpha: enabled ? 0.08 : 0.045),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.selectedSlug,
    required this.onSelected,
  });

  final String selectedSlug;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      _TourCategoryOption(
        slug: 'adventure',
        label: l10n.createTourCategoryAdventure,
        icon: Icons.explore_outlined,
      ),
      _TourCategoryOption(
        slug: 'cultural',
        label: l10n.createTourCategoryCultural,
        icon: Icons.account_balance_outlined,
      ),
      _TourCategoryOption(
        slug: 'culinary',
        label: l10n.createTourCategoryCulinary,
        icon: Icons.restaurant_outlined,
      ),
      _TourCategoryOption(
        slug: 'wellness',
        label: l10n.createTourCategoryWellness,
        icon: Icons.spa_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 370 ? 1 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 4.6 : 2.7,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final selected = selectedSlug == item.slug;
            return _CategoryButton(
              option: item,
              selected: selected,
              onTap: () => onSelected(item.slug),
            );
          },
        );
      },
    );
  }
}

class _TourCategoryOption {
  const _TourCategoryOption({
    required this.slug,
    required this.label,
    required this.icon,
  });

  final String slug;
  final String label;
  final IconData icon;
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _TourCategoryOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : const Color(0xFF4A321D),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(option.icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

class _ItinerarySlotCard extends StatelessWidget {
  const _ItinerarySlotCard({required this.item, this.onDelete});

  final _TourItineraryDraft item;
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

class _TourTextField extends StatelessWidget {
  const _TourTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return _TourFieldShell(
      label: label,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          color: Color(0xFFFFF8F0),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFA99683)),
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

class _TourFieldShell extends StatelessWidget {
  const _TourFieldShell({
    required this.label,
    required this.child,
  });

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
  const _CurrencyOption({
    required this.code,
    required this.symbol,
  });

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

    return _TourFieldShell(
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

class _TourMapPickerCard extends StatelessWidget {
  const _TourMapPickerCard({
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

class _TourBottomActionBar extends StatelessWidget {
  const _TourBottomActionBar({
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
      setState(() => _errorText = widget.l10n.createTourItineraryValidation);
      return;
    }
    Navigator.of(context).pop(
      _TourItineraryDraft(
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
                  _SectionHeader(title: widget.l10n.createTourAddTimeSlot),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _TourTextField(
                          controller: _offsetCtrl,
                          label: widget.l10n.createTourStartOffsetLabel,
                          hint: '120',
                          icon: Icons.schedule_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TourTextField(
                          controller: _durationCtrl,
                          label: widget.l10n.createTourSlotDurationLabel,
                          hint: '60',
                          icon: Icons.timelapse_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TourTextField(
                    controller: _titleCtrl,
                    label: widget.l10n.createTourItineraryTitleLabel,
                    hint: widget.l10n.createTourItineraryTitleHint,
                    icon: Icons.route_outlined,
                  ),
                  const SizedBox(height: 12),
                  _TourTextField(
                    controller: _descriptionCtrl,
                    label: widget.l10n.createTourItineraryDescriptionLabel,
                    hint: widget.l10n.createTourItineraryDescriptionHint,
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
                      child: Text(widget.l10n.confirm,
                          style: const TextStyle(color: AppColors.textPrimary)),
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
