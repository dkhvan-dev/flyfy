import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ui/error_dialog.dart';
import '../../features/activities/models/create_activity_request.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

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
  final _categoryCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  // — Step 2: Format & Schedule —
  String _format = 'OFFLINE';
  DateTime _startAt = DateTime.now().add(const Duration(hours: 2));
  DateTime _endAt = DateTime.now().add(const Duration(hours: 4));
  DateTime _registrationDeadline = DateTime.now().add(const Duration(hours: 1));
  String _languageCode = 'ru';
  String _timezone = 'Asia/Almaty';

  // — Step 3: Participation —
  String _capacityType = 'UNLIMITED';
  final _minParticipantsCtrl = TextEditingController();
  final _maxParticipantsCtrl = TextEditingController();
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

  @override
  void dispose() {
    _pageController.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _categoryCtrl.dispose();
    _tagsCtrl.dispose();
    _minParticipantsCtrl.dispose();
    _maxParticipantsCtrl.dispose();
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
        if (_categoryCtrl.text.trim().isEmpty) {
          _showValidationError(l10n.createCategoryValidation);
          return false;
        }
        return true;
      case 1:
        if (!_endAt.isAfter(_startAt)) {
          _showValidationError(l10n.createEndDateValidation);
          return false;
        }
        return true;
      case 2:
        if (_capacityType == 'LIMITED') {
          final max = int.tryParse(_maxParticipantsCtrl.text.trim());
          if (max == null || max <= 0) {
            _showValidationError(l10n.createMaxParticipantsValidation);
            return false;
          }
        }
        if (_priceType != 'FREE') {
          final amount = double.tryParse(_priceAmountCtrl.text.trim());
          if (amount == null || amount < 0) {
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
        backgroundColor: Colors.redAccent.withOpacity(0.9),
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

  Future<void> _submit() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isSubmitting = true);

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final request = CreateActivityRequest(
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      format: _format,
      visibility: _visibility,
      joinMode: _joinMode,
      categorySlug: _categoryCtrl.text.trim().toLowerCase().replaceAll(' ', '-'),
      tags: tags,
      languageCode: _languageCode,
      timezone: _timezone,
      startAt: _startAt,
      endAt: _endAt,
      registrationDeadline: _registrationDeadline,
      capacityType: _capacityType,
      minParticipants: _capacityType == 'LIMITED'
          ? int.tryParse(_minParticipantsCtrl.text.trim())
          : null,
      maxParticipants: _capacityType == 'LIMITED'
          ? int.tryParse(_maxParticipantsCtrl.text.trim())
          : null,
      priceType: _priceType,
      priceAmount: _priceType != 'FREE'
          ? double.tryParse(_priceAmountCtrl.text.trim())
          : null,
      currency:
          _priceType != 'FREE' ? _currencyCtrl.text.trim().toUpperCase() : null,
      countryCode: (_format != 'ONLINE')
          ? _countryCodeCtrl.text.trim().toUpperCase()
          : null,
      cityName:
          (_format != 'ONLINE') ? _cityNameCtrl.text.trim() : null,
      addressText:
          (_format != 'ONLINE') ? _addressTextCtrl.text.trim() : null,
      meetingUrl:
          (_format != 'OFFLINE') ? _meetingUrlCtrl.text.trim() : null,
    );

    final provider = context.read<ActivityProvider>();
    final created = await provider.createActivity(request);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (created != null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.createActivitySuccess)),
      );
      context.go('/activities/${created.id}');
    } else {
      final l10n = AppLocalizations.of(context)!;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: provider.actionErrorMessage ?? l10n.createActivityFailed,
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
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00BCD4),
          onPrimary: Colors.white,
          surface: Color(0xFF16161F),
          onSurface: Colors.white,
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
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          l10n.createActivityTitle,
          style: const TextStyle(color: Colors.white),
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
          _BottomNavBar(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            isSubmitting: _isSubmitting,
            onBack: () => _goToStep(_currentStep - 1),
            onNext: _nextStep,
            nextLabel: _currentStep == _totalSteps - 1
                ? l10n.createActivitySubmit
                : l10n.createStepNext,
            backLabel: l10n.createStepBack,
          ),
        ],
      ),
    );
  }

  // ── Step 1: Basic ──────────────────────────────────────────────

  Widget _buildStep1Basic(AppLocalizations l10n) {
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
        _InputField(
          controller: _categoryCtrl,
          label: l10n.createCategoryLabel,
          hint: l10n.createCategoryHint,
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

  // ── Step 2: Schedule ───────────────────────────────────────────

  Widget _buildStep2Schedule(AppLocalizations l10n) {
    final df = DateFormat('dd.MM.yyyy HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(title: l10n.createFormatSection),
        const SizedBox(height: 12),
        _SegmentedSelect<String>(
          value: _format,
          items: {
            'OFFLINE': l10n.activityFormatOffline,
            'ONLINE': l10n.activityFormatOnline,
            'HYBRID': l10n.activityFormatHybrid,
          },
          onChanged: (v) => setState(() => _format = v),
        ),
        const SizedBox(height: 24),
        _SectionTitle(title: l10n.createScheduleSection),
        const SizedBox(height: 12),
        _DatePickerTile(
          label: l10n.createStartAtLabel,
          value: df.format(_startAt),
          onTap: () => _pickDateTime(
            initial: _startAt,
            onPicked: (v) => setState(() => _startAt = v),
          ),
        ),
        const SizedBox(height: 12),
        _DatePickerTile(
          label: l10n.createEndAtLabel,
          value: df.format(_endAt),
          onTap: () => _pickDateTime(
            initial: _endAt,
            onPicked: (v) => setState(() => _endAt = v),
          ),
        ),
        const SizedBox(height: 12),
        _DatePickerTile(
          label: l10n.createRegistrationDeadlineLabel,
          value: df.format(_registrationDeadline),
          onTap: () => _pickDateTime(
            initial: _registrationDeadline,
            onPicked: (v) => setState(() => _registrationDeadline = v),
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
          onChanged: (v) => setState(() => _capacityType = v),
        ),
        if (_capacityType == 'LIMITED') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InputField(
                  controller: _minParticipantsCtrl,
                  label: l10n.createMinParticipantsLabel,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InputField(
                  controller: _maxParticipantsCtrl,
                  label: l10n.createMaxParticipantsLabel,
                  keyboardType: TextInputType.number,
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
      ],
    );
  }

  // ── Step 4: Location ───────────────────────────────────────────

  Widget _buildStep4Location(AppLocalizations l10n) {
    final showOffline = _format == 'OFFLINE' || _format == 'HYBRID';
    final showOnline = _format == 'ONLINE' || _format == 'HYBRID';

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
          const SizedBox(height: 12),
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
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Reusable widgets
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
                        ? const Color(0xFF00BCD4)
                        : Colors.white.withOpacity(0.1),
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
                      ? const Color(0xFF00BCD4)
                      : Colors.white.withOpacity(0.08),
                  border: isActive
                      ? Border.all(
                          color: const Color(0xFF00BCD4).withOpacity(0.5),
                          width: 2,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${step + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white54,
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
              color: Colors.white,
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
          color: const Color(0xFF0A0A0F),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
        child: Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.14)),
                    foregroundColor: Colors.white,
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
                      ? const Color(0xFF00C853)
                      : const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
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
                          color: Colors.white,
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
        color: Color(0xFF00BCD4),
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
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white24),
        counterStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00BCD4)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _SegmentedSelect<T> extends StatelessWidget {
  const _SegmentedSelect({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.entries.map((entry) {
        final isSelected = entry.key == value;
        return GestureDetector(
          onTap: () => onChanged(entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00BCD4).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00BCD4)
                    : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Text(
              entry.value,
              style: TextStyle(
                color: isSelected ? const Color(0xFF7EE6F2) : Colors.white70,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
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
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
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
              color: Color(0xFF00BCD4),
            ),
          ],
        ),
      ),
    );
  }
}