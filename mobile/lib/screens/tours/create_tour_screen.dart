import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/tours/models/create_tour_request.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/tour_provider.dart';

class CreateTourScreen extends StatefulWidget {
  const CreateTourScreen({super.key});

  @override
  State<CreateTourScreen> createState() => _CreateTourScreenState();
}

class _CreateTourScreenState extends State<CreateTourScreen> {
  static const _totalSteps = 3;

  final _pageController = PageController();
  var _currentStep = 0;
  var _isSubmitting = false;

  final _landmarkNameCtrl = TextEditingController(text: 'Medeu');
  final _cityNameCtrl = TextEditingController(text: 'Almaty');
  final _countryCodeCtrl = TextEditingController(text: 'KZ');
  final _titleCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '4 hours');
  final _maxGroupSizeCtrl = TextEditingController(text: '8');
  final _languagesCtrl = TextEditingController(text: 'English, Russian');
  final _meetingPointCtrl = TextEditingController();
  final _mapUrlCtrl = TextEditingController();
  final _priceAmountCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController(text: 'KZT');
  final _includedItemsCtrl = TextEditingController();

  var _selectedCategorySlug = 'adventure';
  var _visibility = 'PUBLIC';
  String? _stepErrorText;

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
  void dispose() {
    _pageController.dispose();
    _landmarkNameCtrl.dispose();
    _cityNameCtrl.dispose();
    _countryCodeCtrl.dispose();
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _descriptionCtrl.dispose();
    _tagsCtrl.dispose();
    _durationCtrl.dispose();
    _maxGroupSizeCtrl.dispose();
    _languagesCtrl.dispose();
    _meetingPointCtrl.dispose();
    _mapUrlCtrl.dispose();
    _priceAmountCtrl.dispose();
    _currencyCtrl.dispose();
    _includedItemsCtrl.dispose();
    super.dispose();
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
    final languages = _parseLanguageCodes(_languagesCtrl.text);

    if (durationMinutes == null || durationMinutes < 15) {
      return l10n.createTourDurationValidation;
    }
    if (groupSize == null || groupSize < 1 || groupSize > 100) {
      return l10n.createTourGroupSizeValidation;
    }
    if (languages.isEmpty) {
      return l10n.createTourLanguagesValidation;
    }
    return null;
  }

  String? _validateStoryAndPriceStep(AppLocalizations l10n) {
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
    if (_currencyCtrl.text.trim().isEmpty) {
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
      title: _titleCtrl.text.trim(),
      summary: _summaryCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      categorySlug: _selectedCategorySlug,
      tags: _parseCommaList(_tagsCtrl.text),
      durationMinutes: _parseDurationMinutes(_durationCtrl.text) ?? 60,
      maxGroupSize: int.tryParse(_maxGroupSizeCtrl.text.trim()) ?? 1,
      languageCodes: _parseLanguageCodes(_languagesCtrl.text),
      visibility: _visibility,
      meetingPoint: _meetingPointCtrl.text.trim(),
      countryCode: _countryCodeCtrl.text.trim(),
      cityName: _cityNameCtrl.text.trim(),
      mapUrl: _mapUrlCtrl.text.trim(),
      priceAmount: price,
      currency: _currencyCtrl.text.trim(),
      includedItems: _parseCommaList(_includedItemsCtrl.text),
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

  List<String> _parseLanguageCodes(String value) {
    return _parseCommaList(value)
        .map((item) {
          final normalized = item.trim().toLowerCase();
          return switch (normalized) {
            'english' || 'английский' || 'ағылшын' => 'en',
            'russian' || 'русский' || 'орыс' => 'ru',
            'kazakh' || 'казахский' || 'қазақ' => 'kk',
            'french' || 'французский' => 'fr',
            'japanese' || 'японский' => 'ja',
            _ => normalized,
          };
        })
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  List<String> _parseCommaList(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentStep > 0) {
          _goToStep(_currentStep - 1);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: DecoratedBox(
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
                  isSubmitting: _isSubmitting,
                  onPressed: _nextStep,
                ),
              ],
            ),
          ),
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
          actionLabel: l10n.change,
          onActionTap: () => _landmarkNameCtrl.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _landmarkNameCtrl.text.length,
          ),
        ),
        const SizedBox(height: 12),
        _LandmarkCard(
          landmarkNameController: _landmarkNameCtrl,
          cityNameController: _cityNameCtrl,
          countryCodeController: _countryCodeCtrl,
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
        _TourTextField(
          controller: _languagesCtrl,
          label: l10n.createTourLanguagesLabel,
          hint: l10n.createTourLanguagesHint,
          icon: Icons.translate_rounded,
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
        const _MapPreviewCard(),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _TourTextField(
                controller: _priceAmountCtrl,
                label: l10n.createPriceAmountLabel,
                hint: '0.00',
                icon: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TourTextField(
                controller: _currencyCtrl,
                label: l10n.createCurrencyLabel,
                hint: 'KZT',
                icon: Icons.sell_outlined,
                textCapitalization: TextCapitalization.characters,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TourTextField(
          controller: _includedItemsCtrl,
          label: l10n.createTourIncludedItemsLabel,
          hint: l10n.createTourIncludedItemsHint,
          icon: Icons.checklist_rounded,
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
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 16),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            final isDone = index ~/ 2 < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: isDone ? AppColors.accent : const Color(0xFF6B4A2B),
              ),
            );
          }
          final step = index ~/ 2;
          final isDone = step < currentStep;
          final isActive = step == currentStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive || isDone
                  ? AppColors.accent
                  : const Color(0xFF4B321B),
              border: Border.all(
                color: const Color(0xFFFFD7A6).withValues(alpha: 0.18),
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white)
                  : Text(
                      '${step + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
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

class _LandmarkCard extends StatelessWidget {
  const _LandmarkCard({
    required this.landmarkNameController,
    required this.cityNameController,
    required this.countryCodeController,
  });

  final TextEditingController landmarkNameController;
  final TextEditingController cityNameController;
  final TextEditingController countryCodeController;

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
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _TransparentTextField(
                              controller: cityNameController,
                              label: l10n.createCityLabel,
                              hint: l10n.createCityHint,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TransparentTextField(
                              controller: countryCodeController,
                              label: l10n.createCountryLabel,
                              hint: 'KZ',
                              textCapitalization: TextCapitalization.characters,
                            ),
                          ),
                        ],
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

class _TransparentTextField extends StatelessWidget {
  const _TransparentTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: Color(0xFFFFF5E8),
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
        fillColor: Colors.white.withValues(alpha: 0.08),
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
        color: const Color(0xFFF1E4D3),
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
                color: const Color(0xFF8D5F34).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _formatOffset(item.startOffsetMinutes),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4A2B15),
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
                      color: Color(0xFF2A1B0F),
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
                      color: Color(0xFF775943),
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
                  ? const Color(0xFFB9A897)
                  : const Color(0xFF6A4428),
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
    this.textCapitalization = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: Color(0xFF2A1B0F),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF8A5A2F)),
        labelStyle: const TextStyle(color: Color(0xFF7B5A3A)),
        hintStyle: const TextStyle(color: Color(0xFFAA9380)),
        filled: true,
        fillColor: const Color(0xFFF7EBDD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
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
      color: selected ? const Color(0xFFF6E4CF) : const Color(0xFF4A321D),
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
                      ? AppColors.accent.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.08),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.accent : const Color(0xFFFFDEB6),
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
                            ? const Color(0xFF2A1B0F)
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
                            ? const Color(0xFF7D624A)
                            : const Color(0xFFC4A27D),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF5D3C22),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _MapGridPainter()),
            ),
            const Center(
              child: Icon(
                Icons.location_on_rounded,
                color: AppColors.accent,
                size: 48,
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFFFFE3B8),
                    size: 20,
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

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const gap = 32.0;
    for (var x = 0.0; x < size.width; x += gap) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - size.width), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
                      child: Text(widget.l10n.confirm),
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
