import 'dart:ui' as ui;

import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/activities/models/activity_category_vm.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/activities/models/create_activity_request.dart';
import '../../features/activities/models/update_activity_request.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key, this.activity});

  final ActivityListItemVm? activity;

  bool get isEditMode => activity != null;

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 3;

  // — Step 1: Basic —
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  String? _selectedCategorySlug;
  String? _initialCategorySlug;

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
  int _minParticipants = 1;
  int _maxParticipants = 15;
  String _joinMode = 'AUTO_APPROVE';
  String _visibility = 'PUBLIC';
  bool _visibilityPasswordChanged = false;
  String _priceType = 'FREE';
  final _visibilityPasswordCtrl = TextEditingController();
  final _priceAmountCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController(text: 'KZT');
  final _minParticipantsCtrl = TextEditingController(text: '1');
  final _maxParticipantsCtrl = TextEditingController(text: '15');

  // — Meeting point / location —
  final _countryCodeCtrl = TextEditingController(text: 'KZ');
  final _cityNameCtrl = TextEditingController();
  final _addressTextCtrl = TextEditingController();
  final _mapUrlCtrl = TextEditingController();
  final _meetingUrlCtrl = TextEditingController();
  final MapController _mapController = MapController();
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedMapUrl;
  bool _isResolvingMapSelection = false;

  static const LatLng _fallbackMapTarget = LatLng(43.238949, 76.889709);
  static const _dateTimeInputFormatter = _DateTimeInputFormatter();

  bool _isSubmitting = false;

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

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _initialCategorySlug = _normalizeCategorySlug(a?.categorySlug);
    _selectedCategorySlug = _initialCategorySlug;
    if (a == null) {
      _startAt = _defaultStartAt();
      _endAt = _defaultEndAt(_startAt);
    }
    if (a != null) {
      _titleCtrl.text = a.title;
      _descriptionCtrl.text = a.description;
      _tagsCtrl.text = a.tags.join(', ');
      _format = a.format.toUpperCase();
      _startAt = a.startAt.toLocal();
      _endAt = a.endAt.toLocal();
      _languageCode = a.languageCode;
      _timezone = a.timezone;
      _capacityType = a.capacityType.toUpperCase();
      if (a.minParticipants != null) {
        _minParticipants = a.minParticipants!;
      }
      if (a.maxParticipants != null) {
        _maxParticipants = a.maxParticipants!;
      }
      _joinMode = a.joinMode.toUpperCase();
      _visibility = a.visibility.toUpperCase();
      _priceType = a.priceType.toUpperCase();
      if (a.priceAmount != null) {
        _priceAmountCtrl.text = a.priceAmount! % 1 == 0
            ? a.priceAmount!.toStringAsFixed(0)
            : a.priceAmount!.toStringAsFixed(2);
      }
      if (a.currency != null && a.currency!.trim().isNotEmpty) {
        _currencyCtrl.text = a.currency!;
      }
      if (a.countryCode != null && a.countryCode!.trim().isNotEmpty) {
        _countryCodeCtrl.text = a.countryCode!;
      }
      if (a.cityName != null && a.cityName!.trim().isNotEmpty) {
        _cityNameCtrl.text = a.cityName!;
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
        _mapUrlCtrl.text = a.mapUrl!;
      }
      _syncScheduleControllers();
    }
    _minParticipantsCtrl.text = '$_minParticipants';
    _maxParticipantsCtrl.text = '$_maxParticipants';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ActivityProvider>();
      if (provider.categoryState == ActivitiesState.initial ||
          (provider.categoryState == ActivitiesState.error &&
              provider.categoryItems.isEmpty)) {
        provider.loadActivityCategories();
      }
    });

    _cityNameCtrl.addListener(_handleLocationPreviewChanged);
    _addressTextCtrl.addListener(_handleLocationPreviewChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSetInitialLanguage || widget.isEditMode) {
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
    _pageController.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _tagsCtrl.dispose();
    _startAtCtrl.dispose();
    _endAtCtrl.dispose();
    _visibilityPasswordCtrl.dispose();
    _priceAmountCtrl.dispose();
    _currencyCtrl.dispose();
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

  void _setUnlimitedParticipants(bool value) {
    setState(() {
      _capacityType = value ? 'UNLIMITED' : 'LIMITED';
      if (!value) {
        if (_minParticipants <= 0) {
          _minParticipants = 1;
          _minParticipantsCtrl.text = '1';
        }
        if (_maxParticipants <= 0) {
          _maxParticipants = 15;
          _maxParticipantsCtrl.text = '15';
        }
      }
    });
  }

  void _handleMinParticipantsChanged(String value) {
    final parsed = int.tryParse(value.trim());
    setState(() => _minParticipants = parsed ?? 0);
  }

  void _handleMaxParticipantsChanged(String value) {
    final parsed = int.tryParse(value.trim());
    setState(() => _maxParticipants = parsed ?? 0);
  }

  void _setVisibility(String value) {
    setState(() {
      _visibility = value;
      if (value != 'PRIVATE') {
        _visibilityPasswordCtrl.clear();
        _visibilityPasswordChanged = true;
      }
    });
  }

  void _handleVisibilityPasswordChanged(String _) {
    if (_visibilityPasswordChanged) return;
    setState(() => _visibilityPasswordChanged = true);
  }

  void _setPriceType(String value) {
    setState(() {
      _priceType = value;
      if (value == 'FREE') {
        _priceAmountCtrl.clear();
      }
    });
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

  DateTime? _resolveScheduleInput({
    required TextEditingController controller,
    required DateTime fallback,
  }) {
    final text = controller.text.trim();
    return text.isEmpty ? fallback : _parseDateTimeInput(text);
  }

  bool _syncScheduleStateFromInputs() {
    final nextStartAt = _resolveScheduleInput(
      controller: _startAtCtrl,
      fallback: _startAt,
    );
    final nextEndAt = _resolveScheduleInput(
      controller: _endAtCtrl,
      fallback: _endAt,
    );

    if (nextStartAt == null || nextEndAt == null) {
      return false;
    }

    final startChanged = nextStartAt != _startAt;
    final endChanged = nextEndAt != _endAt;

    _startAt = nextStartAt;
    _endAt = nextEndAt;
    _startAtChanged = _startAtChanged || startChanged;
    _endAtChanged = _endAtChanged || endChanged;
    return true;
  }

  void _handleStartAtChanged(String value) {
    final parsed = _parseDateTimeInput(value);
    if (parsed == null) return;
    setState(() {
      _startAt = parsed;
      _startAtChanged = true;
      if (!_hasCustomEndScheduleInput) {
        _endAt = _defaultEndAt(_startAt);
      }
    });
  }

  void _handleEndAtChanged(String value) {
    final parsed = _parseDateTimeInput(value);
    if (parsed == null) return;
    setState(() {
      _endAt = parsed;
      _endAtChanged = true;
    });
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  bool _validateCurrentStep() {
    final l10n = AppLocalizations.of(context)!;

    switch (_currentStep) {
      case 0:
        if (_titleCtrl.text.trim().length < 3) {
          _showValidationError(l10n.createTitleValidation);
          return false;
        }
        if (_descriptionCtrl.text.trim().length < 10) {
          _showValidationError(l10n.createDescriptionValidation);
          return false;
        }
        if ((_selectedCategorySlug ?? '').trim().isEmpty) {
          _showValidationError(l10n.createCategoryValidation);
          return false;
        }
        return true;
      case 1:
        if (!_syncScheduleStateFromInputs()) {
          _showValidationError(l10n.createScheduleInputValidation);
          return false;
        }
        if (!widget.isEditMode &&
            !_startAt.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
          _showValidationError(l10n.createStartAtTooSoonValidation);
          return false;
        }
        if (!_endAt.isAfter(_startAt)) {
          _showValidationError(l10n.createEndDateValidation);
          return false;
        }
        if (_format == 'ONLINE' || _format == 'HYBRID') {
          if (_meetingUrlCtrl.text.trim().isEmpty) {
            _showValidationError(l10n.createMeetingUrlValidation);
            return false;
          }
        }
        if (_format == 'OFFLINE' || _format == 'HYBRID') {
          if (_cityNameCtrl.text.trim().isEmpty &&
              _addressTextCtrl.text.trim().isEmpty) {
            _showValidationError(l10n.createLocationValidation);
            return false;
          }
        }
        return true;
      case 2:
        if (_shouldRequireVisibilityPassword) {
          final password = _visibilityPasswordValue ?? '';
          if (password.length < 4 || password.length > 64) {
            _showValidationError(l10n.createVisibilityPasswordValidation);
            return false;
          }
        }
        if (_capacityType == 'LIMITED') {
          if (_maxParticipants <= 0) {
            _showValidationError(l10n.createMaxParticipantsValidation);
            return false;
          }
          if (_minParticipants > _maxParticipants) {
            _showValidationError(l10n.createMinExceedsMaxValidation);
            return false;
          }
        }
        if (_priceType != 'FREE') {
          final amount = double.tryParse(_priceAmountCtrl.text.trim());
          if (amount == null || amount <= 0) {
            _showValidationError(l10n.createPriceValidation);
            return false;
          }
        }
        return true;
      default:
        return true;
    }
  }

  void _showValidationError(String message) {
    final l10n = AppLocalizations.of(context)!;
    showErrorDialog(context, title: l10n.error, message: message);
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    } else {
      _submit();
    }
  }

  Future<void> _submitAndPublish() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<ActivityProvider>();
    final request = _buildCreateRequest();
    final created = await provider.createActivity(request);

    if (!mounted) return;

    if (created != null) {
      final published = await provider.publishActivity(created.id);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (published) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.activityPublishSuccess)));
        context.read<ActivityProvider>().loadActivities();
        context.pushReplacement('/activities/${created.id}');
      } else {
        final l10n = AppLocalizations.of(context)!;
        await showErrorDialog(
          context,
          title: l10n.error,
          message: provider.actionErrorMessage ?? l10n.activityPublishFailed,
        );
      }
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
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  bool get _didCategoryChange =>
      _normalizeCategorySlug(_selectedCategorySlug) != _initialCategorySlug;

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
      _priceType != 'FREE' ? _currencyCtrl.text.trim().toUpperCase() : null;

  String? get _countryCodeValue =>
      _format != 'ONLINE' ? _countryCodeCtrl.text.trim().toUpperCase() : null;

  String? get _cityNameValue =>
      _format != 'ONLINE' ? _cityNameCtrl.text.trim() : null;

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

  // ── Submit ─────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<ActivityProvider>();

    if (widget.isEditMode) {
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
      joinMode: _joinMode,
      categorySlug: _selectedCategorySlug!,
      tags: _parsedTags,
      languageCode: _languageCode,
      timezone: _timezone,
      startAt: _startAt,
      endAt: _endAt,
      capacityType: _capacityType,
      minParticipants: _minParticipantsValue,
      maxParticipants: _maxParticipantsValue,
      priceType: _priceType,
      priceAmount: _priceAmountValue,
      currency: _currencyValue,
      countryCode: _countryCodeValue,
      cityName: _cityNameValue,
      addressText: _addressTextValue,
      latitude: _latitudeValue,
      longitude: _longitudeValue,
      mapUrl: _mapUrlValue,
      meetingUrl: _meetingUrlValue,
      visibilityPassword:
          _visibility == 'PRIVATE' ? _visibilityPasswordValue : null,
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
      context.pushReplacement('/activities/${created.id}');
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

    final request = UpdateActivityRequest(
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      visibility: _visibility,
      joinMode: _joinMode,
      categorySlug: _didCategoryChange ? _selectedCategorySlug : null,
      tags: _parsedTags,
      languageCode: _languageCode,
      timezone: _timezone,
      startAt: _startAtChanged ? _startAt : null,
      endAt: _endAtChanged ? _endAt : null,
      capacityType: _capacityType,
      minParticipants: _minParticipantsValue,
      hasMinParticipants: true,
      maxParticipants: _maxParticipantsValue,
      hasMaxParticipants: true,
      priceType: _priceType,
      priceAmount: _priceAmountValue,
      hasPriceAmount: true,
      currency: _currencyValue,
      hasCurrency: true,
      countryCode: _countryCodeValue,
      hasCountryCode: true,
      cityName: _cityNameValue,
      hasCityName: true,
      addressText: _addressTextValue,
      hasAddressText: true,
      latitude: _latitudeValue,
      hasLatitude: true,
      longitude: _longitudeValue,
      hasLongitude: true,
      mapUrl: _mapUrlValue,
      hasMapUrl: true,
      meetingUrl: _meetingUrlValue,
      hasMeetingUrl: true,
      visibilityPassword: _shouldSendVisibilityPasswordChange
          ? (_visibility == 'PRIVATE' ? _visibilityPasswordValue : null)
          : null,
      hasVisibilityPassword: _shouldSendVisibilityPasswordChange,
    );

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

  Future<void> _openCategoryPicker(
    AppLocalizations l10n,
    Map<String, String> items,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
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
      _selectedCategorySlug = _normalizeCategorySlug(selected);
    });
  }

  Future<void> _openJoinModePicker(AppLocalizations l10n) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CategoryPickerSheet(
          title: l10n.createJoinModePickerTitle,
          actionLabel: l10n.createJoinModeApply,
          items: {
            'AUTO_APPROVE': l10n.createJoinModeAutomaticShort,
            'MANUAL_APPROVE': l10n.createJoinModeManualShort,
          },
          initialValue: _joinMode,
          iconForSlug: _joinModeIconForValue,
        );
      },
    );

    if (!mounted || selected == null) return;
    setState(() => _joinMode = selected);
  }

  Future<void> _openVisibilityPicker(AppLocalizations l10n) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
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
      case 'health-wellness':
        return Icons.self_improvement_rounded;
      case 'social-nightlife':
        return Icons.nightlife_rounded;
      case 'adventure-sports':
        return Icons.hiking_rounded;
      case 'workshops-learning':
        return Icons.palette_rounded;
      default:
        return Icons.local_activity_rounded;
    }
  }

  IconData _joinModeIconForValue(String value) {
    switch (value) {
      case 'MANUAL_APPROVE':
        return Icons.person_search_outlined;
      case 'AUTO_APPROVE':
      default:
        return Icons.bolt_rounded;
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
    return 'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=16/$latitude/$longitude';
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

  Future<void> _handleMapTapped(LatLng position) async {
    setState(() {
      _selectedLatitude = position.latitude;
      _selectedLongitude = position.longitude;
      _selectedMapUrl = _buildMapUrl(position.latitude, position.longitude);
      _mapUrlCtrl.text = _selectedMapUrl!;
      _isResolvingMapSelection = true;
    });
    _mapController.move(position, 15);

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final city = _composeCityLabel(placemark);
        final address = _composeAddressLabel(placemark);

        setState(() {
          final isoCountryCode = placemark.isoCountryCode?.trim() ?? '';
          if (isoCountryCode.isNotEmpty) {
            _countryCodeCtrl.text = isoCountryCode;
          }
          if (city.isNotEmpty) {
            _cityNameCtrl.text = city;
          }
          if (address.isNotEmpty) {
            _addressTextCtrl.text = address;
          }
          _isResolvingMapSelection = false;
        });
        return;
      }
    } catch (_) {
      // Keep the selected pin even if reverse geocoding fails.
    }

    if (!mounted) return;
    setState(() => _isResolvingMapSelection = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final stepTitles = [
      l10n.createStepDetailsLogistics,
      l10n.createStepParticipation,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF231A0F), Color(0xFF2A1F12), Color(0xFF231A0F)],
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
                onLeadingPressed: () {
                  if (_currentStep > 0) {
                    _goToStep(_currentStep - 1);
                    return;
                  }
                  context.pop();
                },
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
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentStep = i),
                  children: [
                    _buildStep1Basic(l10n),
                    _buildStep2Schedule(l10n),
                    _buildStep3Participation(l10n),
                  ],
                ),
              ),
              if (_currentStep == _totalSteps - 1)
                _Step3ActionBar(
                  isSubmitting: _isSubmitting,
                  onBack: () => _goToStep(_currentStep - 1),
                  onPrimaryAction:
                      widget.isEditMode ? _submit : _submitAndPublish,
                  backLabel: l10n.createStepBack,
                  primaryLabel: widget.isEditMode
                      ? l10n.editActivitySubmit
                      : l10n.createPublishActivityCta,
                  showPrimaryIcon: !widget.isEditMode,
                )
              else if (_currentStep == 1)
                _Step2NavBar(
                  isSubmitting: _isSubmitting,
                  onBack: () => _goToStep(_currentStep - 1),
                  onNext: _nextStep,
                  backLabel: l10n.createStepBack,
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
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        24 + media.viewInsets.bottom,
      ),
      children: [
        _Step1FieldSection(
          label: l10n.createCoverSection,
          child: const _CoverUploadCard(),
        ),
        SizedBox(height: blockSpacing),
        _Step1FieldSection(
          label: l10n.createTitleLabel,
          child: _Step1TextField(
            controller: _titleCtrl,
            hint: l10n.createTitleHint,
            maxLength: 200,
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
                  trailing: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.accent,
                    ),
                  ),
                );
              }

              if (provider.categoryState == ActivitiesState.error &&
                  items.isEmpty) {
                return _CategoryCatalogState(
                  message: provider.categoryErrorMessage ??
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

              return _CategorySelectorField(
                value: items[_selectedCategorySlug] ?? l10n.createCategoryHint,
                isPlaceholder: _selectedCategorySlug == null,
                onTap: () => _openCategoryPicker(l10n, items),
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

  // ── Step 2: Schedule ───────────────────────────────────────────

  Widget _buildStep2Schedule(AppLocalizations l10n) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final horizontalPadding = width <= 393 ? 16.0 : 20.0;
    final formatLocked = widget.isEditMode;
    final showOffline = _format == 'OFFLINE' || _format == 'HYBRID';
    final showOnline = _format == 'ONLINE' || _format == 'HYBRID';
    final locationLocked = _isPublished && showOffline;

    return ListView(
      padding: EdgeInsets.fromLTRB(
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
                onChanged: (v) => setState(() => _format = v),
              ),
            ),
          ),
        ),
        if (formatLocked) ...[
          const SizedBox(height: 6),
          Text(
            l10n.editFormatLocked,
            style: const TextStyle(color: AppColors.textCaption, fontSize: 12),
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
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          IgnorePointer(
            ignoring: locationLocked,
            child: Opacity(
              opacity: locationLocked ? 0.5 : 1,
              child: _MapPickerCard(
                target: _selectedMapTarget,
                markers: _selectedMapMarkers,
                hasSelection: _hasSelectedMapPoint,
                mapController: _mapController,
                onTap: _handleMapTapped,
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
            style: const TextStyle(color: AppColors.textCaption, fontSize: 12),
          ),
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
      padding: EdgeInsets.fromLTRB(
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
            style: const TextStyle(
              color: AppColors.textCaption,
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
            onChanged: _handleVisibilityPasswordChanged,
          ),
          if (widget.isEditMode && _startedPrivate) ...[
            const SizedBox(height: 8),
            Text(
              l10n.createVisibilityPasswordEditHint,
              style: const TextStyle(
                color: AppColors.textCaption,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
        SizedBox(height: sectionGap),
        _Step3Section(
          icon: Icons.shield_outlined,
          title: l10n.createJoinApprovalTitle,
          child: _CategorySelectorField(
            value: _joinMode == 'MANUAL_APPROVE'
                ? l10n.createJoinModeManualShort
                : l10n.createJoinModeAutomaticShort,
            isPlaceholder: false,
            onTap: () => _openJoinModePicker(l10n),
          ),
        ),
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
                  SizedBox(width: priceChipGap),
                  Expanded(
                    child: _Step3ChoiceChip(
                      label: l10n.createPriceDeposit,
                      isSelected: _priceType == 'DEPOSIT',
                      onTap: () => _setPriceType('DEPOSIT'),
                    ),
                  ),
                ],
              ),
              if (_priceType != 'FREE') ...[
                const SizedBox(height: 16),
                _Step3PriceField(
                  label: l10n.createPriceAmountLabel,
                  controller: _priceAmountCtrl,
                  placeholder: l10n.createPriceAmountPlaceholder,
                  enabled: true,
                ),
              ],
              if (_isPublished) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.editPriceRestrictionHint,
                  style: const TextStyle(
                    color: AppColors.textCaption,
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
            children: [
              _Step3ToggleRow(
                label: l10n.createUnlimitedParticipantsLabel,
                value: isUnlimited,
                onChanged: _setUnlimitedParticipants,
              ),
              const SizedBox(height: 16),
              isNarrow
                  ? Column(
                      children: [
                        _Step3LimitField(
                          label: l10n.createParticipantsMinShort,
                          controller: isUnlimited ? null : _minParticipantsCtrl,
                          placeholder: '1',
                          readOnly: isUnlimited,
                          readOnlyValue: '1',
                          onChanged: _handleMinParticipantsChanged,
                        ),
                        const SizedBox(height: 12),
                        _Step3LimitField(
                          label: l10n.createParticipantsMaxShort,
                          controller: isUnlimited ? null : _maxParticipantsCtrl,
                          placeholder: l10n.createNoLimitPlaceholder,
                          readOnly: isUnlimited,
                          readOnlyValue: l10n.createNoLimitPlaceholder,
                          onChanged: _handleMaxParticipantsChanged,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _Step3LimitField(
                            label: l10n.createParticipantsMinShort,
                            controller:
                                isUnlimited ? null : _minParticipantsCtrl,
                            placeholder: '1',
                            readOnly: isUnlimited,
                            readOnlyValue: '1',
                            onChanged: _handleMinParticipantsChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Step3LimitField(
                            label: l10n.createParticipantsMaxShort,
                            controller:
                                isUnlimited ? null : _maxParticipantsCtrl,
                            placeholder: l10n.createNoLimitPlaceholder,
                            readOnly: isUnlimited,
                            readOnlyValue: l10n.createNoLimitPlaceholder,
                            onChanged: _handleMaxParticipantsChanged,
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

class _CreateTopBar extends StatelessWidget {
  const _CreateTopBar({required this.title, required this.onLeadingPressed});

  final String title;
  final VoidCallback onLeadingPressed;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final textScale = media.textScaler.scale(1);
    final compact = width <= 360 || textScale > 1.05;
    final titleSize = compact ? 18.0 : (width >= 394 ? 22.0 : 20.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(10, compact ? 6 : 8, 10, compact ? 2 : 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              onPressed: onLeadingPressed,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 26,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 40, height: 40),
        ],
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
  });

  final int currentStep;
  final int totalSteps;
  final List<String> titles;
  final String counterLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      final media = MediaQuery.of(context);
      final width = media.size.width;
      final height = media.size.height;
      final textScale = media.textScaler.scale(1);
      final isCompact = width <= 360 || textScale > 1.05;
      final isWide = width >= 394;
      final stepSize = isCompact ? 40.0 : (isWide ? 48.0 : 44.0);
      final stepFontSize = isCompact ? 18.0 : (isWide ? 21.0 : 20.0);
      final lineWidth = isCompact ? 28.0 : (isWide ? 48.0 : 34.0);
      final lineGap = isCompact ? 10.0 : 12.0;
      final topPadding = height <= 780 || textScale > 1.05 ? 18.0 : 28.0;
      final bottomPadding = height <= 780 || textScale > 1.05 ? 22.0 : 34.0;

      return Padding(
        padding: EdgeInsets.fromLTRB(24, topPadding, 24, bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isOdd) {
              final lineIndex = index ~/ 2;
              final isDone = lineIndex < currentStep;
              return Container(
                width: lineWidth,
                height: 3,
                margin: EdgeInsets.symmetric(horizontal: lineGap),
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.success
                      : AppColors.accent.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }

            final stepIndex = index ~/ 2;
            final isActive = stepIndex == currentStep;
            final isDone = stepIndex < currentStep;
            return Container(
              width: stepSize,
              height: stepSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.success
                    : isActive
                        ? AppColors.accent
                        : const Color(0xFF6B4208),
              ),
              alignment: Alignment.center,
              child: isDone
                  ? Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: stepFontSize + 1,
                    )
                  : Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        color:
                            isActive ? Colors.white : const Color(0xFFF6DEC2),
                        fontSize: stepFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            );
          }),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titles[currentStep],
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Text(
                counterLabel,
                style: const TextStyle(
                  color: AppColors.textCaption,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / totalSteps,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            titles[currentStep],
            style: const TextStyle(
              color: AppColors.textPrimary,
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
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            14,
            horizontalPadding,
            16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1D1208).withValues(alpha: 0),
                const Color(0xFF1D1208).withValues(alpha: 0.9),
                const Color(0xFF1D1208),
              ],
            ),
            border: Border(
              top: BorderSide(color: AppColors.accent.withValues(alpha: 0.18)),
            ),
          ),
          child: ElevatedButton(
            onPressed: isSubmitting ? null : onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              minimumSize: Size.fromHeight(buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            child: isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
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
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded, size: 22),
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xB6231A0F),
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: ElevatedButton(
          onPressed: isSubmitting ? null : onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.background,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: isSubmitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.background,
                  ),
                )
              : Text(
                  nextLabel,
                  style: const TextStyle(
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
    required this.onBack,
    required this.onNext,
    required this.backLabel,
    required this.nextLabel,
  });

  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String backLabel;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final textScale = media.textScaler.scale(1);
    final horizontalPadding = width <= 393 ? 16.0 : 20.0;
    final stackButtons = width <= 430 || textScale > 1.05;

    final backButton = OutlinedButton(
      onPressed: isSubmitting ? null : onBack,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        foregroundColor: AppColors.accent,
        side: BorderSide(
          color: AppColors.accent.withValues(alpha: 0.26),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        backgroundColor: const Color(0x614D2A07),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          backLabel,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ),
    );

    final nextButton = ElevatedButton(
      onPressed: isSubmitting ? null : onNext,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        foregroundColor: Colors.white,
        backgroundColor: AppColors.accent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: isSubmitting
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
            ),
    );

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          14,
          horizontalPadding,
          14,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1D1208).withValues(alpha: 0),
              const Color(0xFF1D1208).withValues(alpha: 0.88),
              const Color(0xFF1D1208),
            ],
          ),
          border: Border(
            top: BorderSide(
              color: const Color(0xFF5F86B3).withValues(alpha: 0.16),
            ),
          ),
        ),
        child: stackButtons
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: double.infinity, child: backButton),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: nextButton),
                ],
              )
            : Row(
                children: [
                  Expanded(flex: 10, child: backButton),
                  const SizedBox(width: 12),
                  Expanded(flex: 14, child: nextButton),
                ],
              ),
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
          style: TextStyle(
            color: AppColors.textPrimary,
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
          style: const TextStyle(
            color: Color(0xFFEFE7DF),
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

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF2F1A06),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 1)],
      ),
      child: Row(
        children: entries.map((entry) {
          final isActive = entry.key == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: Container(
                constraints: BoxConstraints(minHeight: segmentHeight),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.22),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : null,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[entry.key],
                          size: iconSize, color: Colors.white),
                      SizedBox(width: spacing),
                      Flexible(
                        child: Text(
                          entry.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
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
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    const fieldHeight = 68.0;

    return Container(
      constraints: const BoxConstraints(minHeight: fieldHeight),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2107),
        borderRadius: BorderRadius.circular(999),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          height: 1.2,
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFB8AB9D),
            fontSize: 16,
            height: 1.2,
            letterSpacing: -0.2,
          ),
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(0, 18, 20, 18),
          prefixIcon: SizedBox(
            width: 56,
            height: fieldHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 18, right: 12),
                child: Icon(icon, color: AppColors.accent, size: 22),
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 56,
            minHeight: fieldHeight,
          ),
        ),
      ),
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
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFEFE7DF),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(
            color: const Color(0xFF3A2107),
            borderRadius: BorderRadius.circular(999),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              height: 1.2,
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFB8AB9D),
                fontSize: 16,
                height: 1.2,
                letterSpacing: -0.2,
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(18, 17, 8, 17),
              suffixIcon: Icon(icon, color: const Color(0xFFB8AB9D), size: 20),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 64,
              ),
            ),
          ),
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
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed =
        digits.length > _maxDigits ? digits.substring(0, _maxDigits) : digits;
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
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
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
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 50),
          padding:
              EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : const Color(0xFF3A2108),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
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
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF3E8DC),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(minHeight: 68),
          decoration: BoxDecoration(
            color: const Color(0xFF3A2108),
            borderRadius: BorderRadius.circular(999),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            textAlignVertical: TextAlignVertical.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: enabled
                  ? AppColors.textPrimary
                  : AppColors.textPrimary.withValues(alpha: 0.72),
              fontSize: 20,
              height: 1.2,
              letterSpacing: -0.6,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                color: Color(0xFF9F8D78),
                fontSize: 20,
                height: 1.2,
                letterSpacing: -0.6,
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            ),
          ),
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
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF3E8DC),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(minHeight: 68),
          decoration: BoxDecoration(
            color: const Color(0xFF3A2108),
            borderRadius: BorderRadius.circular(999),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: obscureText,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              height: 1.2,
              letterSpacing: -0.4,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                color: Color(0xFF9F8D78),
                fontSize: 18,
                height: 1.2,
                letterSpacing: -0.4,
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            ),
          ),
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
      borderRadius: BorderRadius.circular(999),
      onTap: () => onChanged(!value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF3A2108),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: value ? AppColors.accent : const Color(0xFF6A410B),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.white,
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
    required this.placeholder,
    required this.readOnly,
    required this.readOnlyValue,
    this.controller,
    this.onChanged,
  });

  final String label;
  final String placeholder;
  final bool readOnly;
  final String readOnlyValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: const Color(0xFF3A2108),
      borderRadius: BorderRadius.circular(999),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF3E8DC),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(minHeight: 60),
          decoration: decoration,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: readOnly
              ? Text(
                  readOnlyValue,
                  style: TextStyle(
                    color: readOnlyValue == placeholder
                        ? const Color(0xFF9F8D78)
                        : AppColors.textPrimary,
                    fontSize: 18,
                    letterSpacing: -0.4,
                  ),
                )
              : TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlignVertical: TextAlignVertical.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: onChanged,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    letterSpacing: -0.4,
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: const TextStyle(
                      color: Color(0xFF9F8D78),
                      fontSize: 18,
                      letterSpacing: -0.4,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
        ),
      ],
    );
  }
}

class _Step3ActionBar extends StatelessWidget {
  const _Step3ActionBar({
    required this.isSubmitting,
    required this.onBack,
    required this.onPrimaryAction,
    required this.backLabel,
    required this.primaryLabel,
    this.showPrimaryIcon = true,
  });

  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onPrimaryAction;
  final String backLabel;
  final String primaryLabel;
  final bool showPrimaryIcon;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final textScale = media.textScaler.scale(1);
    final stackButtons = width <= 430 || textScale > 1.05;
    final horizontalPadding = width <= 360 ? 16.0 : 18.0;

    final backButton = OutlinedButton(
      onPressed: isSubmitting ? null : onBack,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(62),
        foregroundColor: AppColors.accent,
        backgroundColor: const Color(0x8C462707),
        side: BorderSide(
          color: AppColors.accent.withValues(alpha: 0.22),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          backLabel,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );

    final primaryButton = ElevatedButton(
      onPressed: isSubmitting ? null : onPrimaryAction,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(62),
        foregroundColor: Colors.white,
        backgroundColor: AppColors.accent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: isSubmitting
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (showPrimaryIcon) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_outward_rounded, size: 22),
                  ],
                ],
              ),
            ),
    );

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          16,
          horizontalPadding,
          18,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1C1107).withValues(alpha: 0),
              const Color(0xFF1C1107).withValues(alpha: 0.9),
              const Color(0xFF1C1107),
            ],
          ),
          border: Border(
            top: BorderSide(
              color: const Color(0xFF5F86B3).withValues(alpha: 0.2),
            ),
          ),
        ),
        child: stackButtons
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: double.infinity, child: backButton),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: primaryButton),
                ],
              )
            : Row(
                children: [
                  Expanded(flex: 10, child: backButton),
                  const SizedBox(width: 12),
                  Expanded(flex: 19, child: primaryButton),
                ],
              ),
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
  });

  final TextEditingController controller;
  final String? hint;
  final int? maxLength;
  final int maxLines;
  final double? minHeight;
  final bool isMultiline;

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
    final radius = BorderRadius.circular(32);
    final fieldHeight =
        widget.minHeight ?? (isCompact ? 66.0 : (isWide ? 78.0 : 72.0));
    final horizontalPadding = isCompact ? 18.0 : 22.0;
    final fieldFontSize = isCompact ? 16.0 : (isWide ? 20.0 : 18.0);
    final multilineTop = isCompact ? 18.0 : 20.0;
    final singleLineVerticalPadding = isCompact ? 16.0 : (isWide ? 20.0 : 18.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      constraints: BoxConstraints(minHeight: fieldHeight),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2107),
        borderRadius: radius,
        border: Border.all(
          color: _focusNode.hasFocus
              ? AppColors.accent
              : Colors.white.withValues(alpha: 0.02),
          width: _focusNode.hasFocus ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        maxLength: widget.maxLength,
        buildCounter: (
          context, {
          required int currentLength,
          required bool isFocused,
          int? maxLength,
        }) =>
            null,
        maxLines: widget.maxLines,
        minLines: widget.isMultiline ? widget.maxLines : 1,
        keyboardType:
            widget.isMultiline ? TextInputType.multiline : TextInputType.text,
        textAlignVertical: widget.isMultiline
            ? TextAlignVertical.top
            : TextAlignVertical.center,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fieldFontSize,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.8,
          height: 1.2,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.58),
            fontSize: fieldFontSize,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.8,
          ),
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.fromLTRB(
            horizontalPadding,
            widget.isMultiline ? multilineTop : singleLineVerticalPadding,
            horizontalPadding,
            widget.isMultiline ? 20 : singleLineVerticalPadding,
          ),
        ),
      ),
    );
  }
}

class _CategorySelectorField extends StatelessWidget {
  const _CategorySelectorField({
    required this.value,
    required this.isPlaceholder,
    required this.onTap,
  });

  final String value;
  final bool isPlaceholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width <= 360;
    final isWide = width >= 394;
    final height = isCompact ? 66.0 : (isWide ? 78.0 : 72.0);
    final fontSize = isCompact ? 16.0 : (isWide ? 20.0 : 18.0);
    final horizontalPadding = isCompact ? 18.0 : 22.0;

    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        padding:
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF3A2107),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isPlaceholder
                ? Colors.white.withValues(alpha: 0.02)
                : AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isPlaceholder
                      ? Colors.white.withValues(alpha: 0.58)
                      : AppColors.textPrimary,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              color: Colors.white.withValues(alpha: 0.78),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverUploadCard extends StatelessWidget {
  const _CoverUploadCard();

  static const _previewUrl =
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width <= 360;
    final isWide = width >= 394;
    final radius = isCompact ? 28.0 : 34.0;
    final height = isCompact ? 190.0 : (isWide ? 230.0 : 210.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF238FE7),
                    Color(0xFF89D1FF),
                    Color(0xFF8AB8DF),
                  ],
                ),
              ),
              child: Image.network(
                _previewUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.expand(),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _DashedCoverBorderPainter(
                  color: const Color(0xFFBE965D).withValues(alpha: 0.45),
                  radius: radius,
                ),
              ),
            ),
          ],
        ),
      ),
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
  bool shouldRepaint(covariant _DashedCoverBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _MapPickerCard extends StatelessWidget {
  const _MapPickerCard({
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
                  child: const Icon(
                    Icons.my_location_rounded,
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
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2107),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
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
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 48,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A1E11),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = widget.items.entries.elementAt(index);
                      final selected = entry.key == _selected;
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => setState(() => _selected = entry.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accent.withValues(alpha: 0.18)
                                : const Color(0xFF332416),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.iconForSlug(entry.key),
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
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
                                    ? AppColors.accent
                                    : AppColors.textCaption,
                              ),
                            ],
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
                      backgroundColor: AppColors.accent,
                      disabledBackgroundColor: AppColors.surfaceLight,
                      foregroundColor: AppColors.background,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      widget.actionLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
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
