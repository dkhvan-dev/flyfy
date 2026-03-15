import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  static const _totalSteps = 4;

  // — Step 1: Basic —
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  String? _selectedCategorySlug;
  String? _initialCategorySlug;

  // — Step 2: Format & Schedule —
  String _format = 'OFFLINE';
  DateTime _startAt = DateTime.now().add(const Duration(hours: 2));
  DateTime _endAt = DateTime.now().add(const Duration(hours: 4));
  DateTime _registrationDeadline = DateTime.now().add(const Duration(hours: 1));
  String _languageCode = 'ru';
  String _timezone = 'Asia/Almaty';

  // — Step 3: Participation —
  String _capacityType = 'UNLIMITED';
  int _minParticipants = 2;
  int _maxParticipants = 15;
  String _joinMode = 'AUTO_APPROVE';
  String _visibility = 'PUBLIC';
  String _priceType = 'FREE';
  final _priceAmountCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController(text: 'KZT');

  // — Step 4: Location —
  final _countryCodeCtrl = TextEditingController(text: 'KZ');
  final _cityNameCtrl = TextEditingController();
  final _addressTextCtrl = TextEditingController();
  final _meetingUrlCtrl = TextEditingController();

  bool _isSubmitting = false;

  // Track whether the user changed date/time fields in edit mode.
  bool _startAtChanged = false;
  bool _endAtChanged = false;
  bool _registrationDeadlineChanged = false;

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
    if (a != null) {
      _titleCtrl.text = a.title;
      _descriptionCtrl.text = a.description;
      _tagsCtrl.text = a.tags.join(', ');
      _format = a.format.toUpperCase();
      _startAt = a.startAt.toLocal();
      _endAt = a.endAt.toLocal();
      _registrationDeadline =
          a.registrationDeadline?.toLocal() ??
          _startAt.subtract(const Duration(hours: 1));
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
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ActivityProvider>();
      if (provider.categoryState == ActivitiesState.initial ||
          (provider.categoryState == ActivitiesState.error &&
              provider.categoryItems.isEmpty)) {
        provider.loadActivityCategories();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _tagsCtrl.dispose();
    _priceAmountCtrl.dispose();
    _currencyCtrl.dispose();
    _countryCodeCtrl.dispose();
    _cityNameCtrl.dispose();
    _addressTextCtrl.dispose();
    _meetingUrlCtrl.dispose();
    super.dispose();
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
        if (!widget.isEditMode &&
            !_startAt.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
          _showValidationError(l10n.createStartAtTooSoonValidation);
          return false;
        }
        if (!_endAt.isAfter(_startAt)) {
          _showValidationError(l10n.createEndDateValidation);
          return false;
        }
        if (_registrationDeadline.isAfter(_startAt)) {
          _showValidationError(l10n.createRegistrationDeadlineValidation);
          return false;
        }
        return true;
      case 2:
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
      case 3:
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
      default:
        return true;
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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

  List<String> get _parsedTags => _tagsCtrl.text
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

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
      registrationDeadline: _registrationDeadline,
      capacityType: _capacityType,
      minParticipants: _minParticipantsValue,
      maxParticipants: _maxParticipantsValue,
      priceType: _priceType,
      priceAmount: _priceAmountValue,
      currency: _currencyValue,
      countryCode: _countryCodeValue,
      cityName: _cityNameValue,
      addressText: _addressTextValue,
      meetingUrl: _meetingUrlValue,
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
      registrationDeadline: _registrationDeadlineChanged
          ? _registrationDeadline
          : null,
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
      meetingUrl: _meetingUrlValue,
      hasMeetingUrl: true,
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

  Future<void> _pickDateTime({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: _datePickerTheme,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: _datePickerTheme,
    );
    if (time == null || !mounted) return;

    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Widget _datePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: AppColors.accent,
          onPrimary: AppColors.background,
          surface: AppColors.surfaceLight,
          onSurface: AppColors.textPrimary,
        ),
      ),
      child: child!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final stepTitles = [
      l10n.createStepBasic,
      l10n.createStepSchedule,
      l10n.createStepParticipation,
      l10n.createStepLocation,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          widget.isEditMode ? l10n.editActivityTitle : l10n.createActivityTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          _StepIndicator(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            titles: stepTitles,
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
                _buildStep4Location(l10n),
              ],
            ),
          ),
          if (_currentStep == _totalSteps - 1 && !widget.isEditMode)
            _DualCtaBar(
              isSubmitting: _isSubmitting,
              onBack: () => _goToStep(_currentStep - 1),
              onSaveDraft: _nextStep,
              onPublish: _submitAndPublish,
              saveDraftLabel: l10n.createSaveDraft,
              publishLabel: l10n.createAndPublish,
              backLabel: l10n.createStepBack,
            )
          else
            _BottomNavBar(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              isSubmitting: _isSubmitting,
              onBack: () => _goToStep(_currentStep - 1),
              onNext: _nextStep,
              nextLabel: _currentStep == _totalSteps - 1
                  ? l10n.editActivitySubmit
                  : l10n.createStepNext,
              backLabel: l10n.createStepBack,
            ),
        ],
      ),
    );
  }

  // ── Step 1: Basic ──────────────────────────────────────────────

  Widget _buildStep1Basic(AppLocalizations l10n) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(title: l10n.createBasicSection),
        const SizedBox(height: 12),
        _InputField(
          controller: _titleCtrl,
          label: l10n.createTitleLabel,
          hint: l10n.createTitleHint,
          maxLength: 200,
        ),
        const SizedBox(height: 16),
        _InputField(
          controller: _descriptionCtrl,
          label: l10n.createDescriptionLabel,
          hint: l10n.createDescriptionHint,
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.createCategoryLabel,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.createCategoryHint,
          style: const TextStyle(color: AppColors.textCaption, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Consumer<ActivityProvider>(
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
                  width: 18,
                  height: 18,
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

            return _CategoryDropdownField(
              value: _selectedCategorySlug,
              items: items,
              onChanged: (value) => setState(() {
                _selectedCategorySlug = _normalizeCategorySlug(value);
              }),
            );
          },
        ),
        const SizedBox(height: 16),
        _InputField(
          controller: _tagsCtrl,
          label: l10n.createTagsLabel,
          hint: l10n.createTagsHint,
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
    final df = DateFormat('dd.MM.yyyy HH:mm');
    final formatLocked = widget.isEditMode;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(title: l10n.createFormatSection),
        const SizedBox(height: 12),
        IgnorePointer(
          ignoring: formatLocked,
          child: Opacity(
            opacity: formatLocked ? 0.5 : 1.0,
            child: _SegmentedSelect<String>(
              value: _format,
              items: {
                'OFFLINE': l10n.activityFormatOffline,
                'ONLINE': l10n.activityFormatOnline,
                'HYBRID': l10n.activityFormatHybrid,
              },
              icons: const {
                'OFFLINE': Icons.location_on,
                'ONLINE': Icons.videocam,
                'HYBRID': Icons.devices,
              },
              onChanged: (v) => setState(() => _format = v),
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
        const SizedBox(height: 24),
        _SectionTitle(title: l10n.createScheduleSection),
        const SizedBox(height: 12),
        _DatePickerTile(
          label: l10n.createStartAtLabel,
          value: df.format(_startAt),
          onTap: () => _pickDateTime(
            initial: _startAt,
            onPicked: (v) => setState(() {
              _startAt = v;
              _startAtChanged = true;
            }),
          ),
        ),
        const SizedBox(height: 12),
        _DatePickerTile(
          label: l10n.createEndAtLabel,
          value: df.format(_endAt),
          onTap: () => _pickDateTime(
            initial: _endAt,
            onPicked: (v) => setState(() {
              _endAt = v;
              _endAtChanged = true;
            }),
          ),
        ),
        const SizedBox(height: 12),
        _DatePickerTile(
          label: l10n.createRegistrationDeadlineLabel,
          value: df.format(_registrationDeadline),
          onTap: () => _pickDateTime(
            initial: _registrationDeadline,
            onPicked: (v) => setState(() {
              _registrationDeadline = v;
              _registrationDeadlineChanged = true;
            }),
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(title: l10n.createLanguageSection),
        const SizedBox(height: 12),
        _SegmentedSelect<String>(
          value: _languageCode,
          items: const {'ru': 'Русский', 'en': 'English', 'kk': 'Қазақша'},
          onChanged: (v) => setState(() => _languageCode = v),
        ),
      ],
    );
  }

  // ── Step 3: Participation ──────────────────────────────────────

  Widget _buildStep3Participation(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(title: l10n.createVisibilitySection),
        const SizedBox(height: 12),
        _SegmentedSelect<String>(
          value: _visibility,
          items: {
            'PUBLIC': l10n.createVisibilityPublic,
            'PRIVATE': l10n.createVisibilityPrivate,
            'UNLISTED': l10n.createVisibilityUnlisted,
          },
          onChanged: (v) => setState(() => _visibility = v),
        ),
        const SizedBox(height: 24),
        _SectionTitle(title: l10n.createJoinModeSection),
        const SizedBox(height: 12),
        _SegmentedSelect<String>(
          value: _joinMode,
          items: {
            'AUTO_APPROVE': l10n.createJoinModeAuto,
            'MANUAL_APPROVE': l10n.createJoinModeManual,
          },
          onChanged: (v) => setState(() => _joinMode = v),
        ),
        const SizedBox(height: 24),
        _SectionTitle(title: l10n.createCapacitySection),
        const SizedBox(height: 12),
        _SegmentedSelect<String>(
          value: _capacityType,
          items: {
            'UNLIMITED': l10n.createCapacityUnlimited,
            'LIMITED': l10n.createCapacityLimited,
          },
          onChanged: (v) => setState(() {
            _capacityType = v;
            if (v == 'LIMITED' && _maxParticipants <= 0) {
              _minParticipants = 2;
              _maxParticipants = 15;
            }
          }),
        ),
        if (_capacityType == 'LIMITED') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SpinnerField(
                  label: l10n.createMinParticipantsLabel,
                  value: _minParticipants,
                  min: 1,
                  max: 999,
                  onChanged: (v) => setState(() => _minParticipants = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SpinnerField(
                  label: l10n.createMaxParticipantsLabel,
                  value: _maxParticipants,
                  min: 1,
                  max: 999,
                  onChanged: (v) => setState(() => _maxParticipants = v),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _SectionTitle(title: l10n.createPriceSection),
        const SizedBox(height: 12),
        _SegmentedSelect<String>(
          value: _priceType,
          items: {
            'FREE': l10n.createPriceFree,
            'PAID': l10n.createPricePaid,
            'DEPOSIT': l10n.createPriceDeposit,
          },
          onChanged: (v) => setState(() => _priceType = v),
        ),
        if (_priceType != 'FREE') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _InputField(
                  controller: _priceAmountCtrl,
                  label: l10n.createPriceAmountLabel,
                  hint: l10n.createPricePerPersonHint,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InputField(
                  controller: _currencyCtrl,
                  label: l10n.createCurrencyLabel,
                ),
              ),
            ],
          ),
        ],
        if (_isPublished) ...[
          const SizedBox(height: 8),
          Text(
            l10n.editPriceRestrictionHint,
            style: const TextStyle(color: AppColors.textCaption, fontSize: 12),
          ),
        ],
      ],
    );
  }

  // ── Step 4: Location ───────────────────────────────────────────

  Widget _buildStep4Location(AppLocalizations l10n) {
    final showOffline = _format == 'OFFLINE' || _format == 'HYBRID';
    final showOnline = _format == 'ONLINE' || _format == 'HYBRID';
    final locationLocked = _isPublished && showOffline;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (showOnline) ...[
          _SectionTitle(title: l10n.createOnlineSection),
          const SizedBox(height: 12),
          _InputField(
            controller: _meetingUrlCtrl,
            label: l10n.createMeetingUrlLabel,
            hint: l10n.createMeetingUrlHint,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 24),
        ],
        if (showOffline) ...[
          _SectionTitle(title: l10n.createOfflineSection),
          if (locationLocked) ...[
            const SizedBox(height: 8),
            Text(
              l10n.editLocationLocked,
              style: const TextStyle(
                color: AppColors.textCaption,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          IgnorePointer(
            ignoring: locationLocked,
            child: Opacity(
              opacity: locationLocked ? 0.5 : 1.0,
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: _InputField(
                          controller: _countryCodeCtrl,
                          label: l10n.createCountryLabel,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _InputField(
                          controller: _cityNameCtrl,
                          label: l10n.createCityLabel,
                          hint: l10n.createCityHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _addressTextCtrl,
                    label: l10n.createAddressLabel,
                    hint: l10n.createAddressHint,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Reusable widgets (private to this screen)
// ════════════════════════════════════════════════════════════════

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.titles,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps * 2 - 1, (i) {
              if (i.isOdd) {
                return Expanded(
                  child: Container(
                    height: 2,
                    color: (i ~/ 2) < currentStep
                        ? AppColors.accent
                        : AppColors.background.withValues(alpha: 0.1),
                  ),
                );
              }
              final step = i ~/ 2;
              final isActive = step == currentStep;
              final isDone = step < currentStep;
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive || isDone
                      ? AppColors.accent
                      : AppColors.surfaceLight,
                  border: isActive
                      ? Border.all(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          width: 2,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: isDone
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.background,
                      )
                    : Text(
                        '${step + 1}',
                        style: TextStyle(
                          color: isActive
                              ? AppColors.background
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            titles[currentStep],
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
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
    required this.currentStep,
    required this.totalSteps,
    required this.isSubmitting,
    required this.onBack,
    required this.onNext,
    required this.nextLabel,
    required this.backLabel,
  });

  final int currentStep;
  final int totalSteps;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String nextLabel;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.borderLight),
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(backLabel),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: currentStep > 0 ? 2 : 1,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentStep == totalSteps - 1
                      ? AppColors.success
                      : AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.accent,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textCaption),
        counterStyle: const TextStyle(color: AppColors.textCaption),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _CategoryDropdownField extends StatelessWidget {
  const _CategoryDropdownField({
    required this.items,
    required this.onChanged,
    this.value,
  });

  final Map<String, String> items;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue = items.containsKey(value) ? value : null;
    final l10n = AppLocalizations.of(context)!;

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      isExpanded: true,
      menuMaxHeight: 360,
      dropdownColor: AppColors.surfaceLight,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: l10n.createCategoryLabel,
        hintStyle: const TextStyle(color: AppColors.textCaption),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      iconEnabledColor: AppColors.accent,
      items: items.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SegmentedSelect<T> extends StatelessWidget {
  const _SegmentedSelect({
    required this.value,
    required this.items,
    required this.onChanged,
    this.icons,
  });

  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  final Map<T, IconData>? icons;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.entries.map((entry) {
        final isSelected = entry.key == value;
        final icon = icons?[entry.key];
        return GestureDetector(
          onTap: () => onChanged(entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.2)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.borderLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? AppColors.accentLight
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  entry.value,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.accentLight
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SpinnerField extends StatelessWidget {
  const _SpinnerField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _spinnerButton(
                icon: Icons.remove,
                onTap: value > min ? () => onChanged(value - 1) : null,
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _spinnerButton(
                icon: Icons.add,
                onTap: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _spinnerButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppColors.accent.withValues(alpha: 0.2)
              : AppColors.surface,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.accent : AppColors.textCaption,
        ),
      ),
    );
  }
}

class _DualCtaBar extends StatelessWidget {
  const _DualCtaBar({
    required this.isSubmitting,
    required this.onBack,
    required this.onSaveDraft,
    required this.onPublish,
    required this.saveDraftLabel,
    required this.publishLabel,
    required this.backLabel,
  });

  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;
  final String saveDraftLabel;
  final String publishLabel;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSubmitting ? null : onSaveDraft,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.borderLight),
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(saveDraftLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : onPublish,
                    icon: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.background,
                            ),
                          )
                        : const Icon(Icons.rocket_launch, size: 18),
                    label: Text(
                      publishLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: isSubmitting ? null : onBack,
                child: Text(
                  backLabel,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}
