import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/device/device_context_service.dart';
import '../../../core/ui/app_colors.dart';
import '../../../features/excursions/models/excursion_schedule_vm.dart';
import '../../../features/excursions/models/excursion_vm.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/excursion_provider.dart';
import '../../../providers/excursion_schedule_provider.dart';

const _slotSheetFieldIconColor = Color(0xFFB8AB9D);

class GuideScheduleSlotSheet extends StatefulWidget {
  const GuideScheduleSlotSheet({super.key, this.slot, this.initialDate});

  final ExcursionScheduleSlotVm? slot;
  final DateTime? initialDate;

  @override
  State<GuideScheduleSlotSheet> createState() => _GuideScheduleSlotSheetState();
}

class _GuideScheduleSlotSheetState extends State<GuideScheduleSlotSheet> {
  static const Duration _slotSetupLeadTime = Duration(hours: 3);

  late DateTime _date;
  late TimeOfDay _time;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _capacityController;
  String? _selectedOfferId;
  String _timezone = 'Asia/Almaty';
  bool _repeatWeekly = false;
  Set<int> _weekdays = <int>{};
  bool _showConflictBanner = false;
  String? _offerError;
  String? _dateError;
  String? _timeError;
  String? _capacityError;

  @override
  void initState() {
    super.initState();
    final start =
        widget.slot?.startAt.toLocal() ?? widget.initialDate ?? DateTime.now();
    _date = DateTime(start.year, start.month, start.day);
    _time = TimeOfDay.fromDateTime(start);
    _selectedOfferId = widget.slot?.offerId;
    _dateController = TextEditingController(text: _formatDate(_date));
    _timeController = TextEditingController(text: _formatTime(_time));
    _capacityController = TextEditingController(
      text: widget.slot == null ? '' : widget.slot!.capacity.toString(),
    );
    _timezone = widget.slot?.timezone ?? 'Asia/Almaty';
    _weekdays = {_isoWeekday(_date)};
    _loadTimezone();
  }

  Future<void> _loadTimezone() async {
    if (widget.slot != null) return;
    final timezone = await const DeviceContextService().getLocalTimezone();
    if (!mounted || timezone == null || timezone.trim().isEmpty) return;
    setState(() => _timezone = timezone.trim());
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ExcursionScheduleProvider>();
    final guideExcursions =
        context.watch<ExcursionProvider>().myGuideExcursions;
    final offerOptions = _offerOptions(guideExcursions, l10n);
    final dropdownOptions = _dropdownOfferOptions(
      offerOptions,
      guideExcursions,
      l10n,
    );
    final hasOfferOptions = dropdownOptions.isNotEmpty;
    final isEditing = widget.slot != null;
    final selectedOffer = _selectedOfferOption(dropdownOptions);
    final showActionError =
        provider.actionState == ExcursionScheduleActionState.error &&
            provider.actionErrorMessage != null &&
            !provider.isActionConflict;

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF241A11),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: ListView(
              controller: controller,
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Text(
                  isEditing
                      ? l10n.guideCalendarEditSlot
                      : l10n.guideCalendarAddSlot,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedOfferId,
                  menuMaxHeight: 320,
                  itemHeight: 74,
                  borderRadius: BorderRadius.circular(8),
                  items: dropdownOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option.id,
                      child: _OfferOptionTile(option: option),
                    );
                  }).toList(growable: false),
                  selectedItemBuilder: (context) =>
                      dropdownOptions.map((option) {
                    return Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        option.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }).toList(growable: false),
                  onChanged: !hasOfferOptions
                      ? null
                      : (value) => setState(() {
                            _selectedOfferId = value;
                            _offerError = null;
                            _showConflictBanner = false;
                          }),
                  isExpanded: true,
                  dropdownColor: const Color(0xFF241A11),
                  iconEnabledColor: _slotSheetFieldIconColor,
                  iconDisabledColor: _slotSheetFieldIconColor,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration:
                      _inputDecoration(l10n.guideCalendarOfferLabel).copyWith(
                    errorText: _offerError,
                    helperText: !isEditing && !hasOfferOptions
                        ? l10n.guideCalendarNoPublishedOffers
                        : null,
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _SlotTextField(
                      label: l10n.guideCalendarDateLabel,
                      hint: l10n.guideCalendarDateHint,
                      controller: _dateController,
                      icon: Icons.calendar_today_rounded,
                      enabled: true,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: const [_DateInputFormatter()],
                      errorText: _dateError,
                      onChanged: _handleDateTextChanged,
                    ),
                    _SlotTextField(
                      label: l10n.guideCalendarTimeLabel,
                      hint: l10n.guideCalendarTimeHint,
                      controller: _timeController,
                      icon: Icons.schedule_rounded,
                      enabled: true,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: const [_TimeInputFormatter()],
                      errorText: _timeError,
                      onChanged: _handleTimeTextChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  enabled: true,
                  cursorColor: AppColors.accent,
                  style: const TextStyle(color: AppColors.textPrimary),
                  onChanged: (_) => _clearActionHints(clearCapacity: true),
                  decoration: _inputDecoration(l10n.guideCalendarCapacityLabel)
                      .copyWith(
                    errorText: _capacityError,
                    helperText: selectedOffer?.maxCapacity == null
                        ? null
                        : l10n.guideCalendarCapacityMax(
                            selectedOffer!.maxCapacity!,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                ChipTheme(
                  data: _chipTheme(context),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text(l10n.guideCalendarRepeatWeekly),
                        selected: _repeatWeekly,
                        onSelected: isEditing
                            ? null
                            : (value) => setState(() => _repeatWeekly = value),
                      ),
                      for (final day in _weekdayOptions(context))
                        FilterChip(
                          label: Text(day.label),
                          selected:
                              _repeatWeekly && _weekdays.contains(day.value),
                          onSelected: !_repeatWeekly || isEditing
                              ? null
                              : (selected) {
                                  setState(() {
                                    if (selected) {
                                      _weekdays.add(day.value);
                                    } else if (_weekdays.length > 1) {
                                      _weekdays.remove(day.value);
                                    }
                                  });
                                },
                        ),
                    ],
                  ),
                ),
                if (_showConflictBanner) ...[
                  const SizedBox(height: 16),
                  _GuideCalendarConflictBanner(
                    title: l10n.guideCalendarConflictTitle,
                    suggestionLabel: l10n.guideCalendarSuggestNextTime,
                  ),
                ],
                if (showActionError) ...[
                  const SizedBox(height: 14),
                  Text(
                    provider.actionErrorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFFFB4A8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    if (isEditing) ...[
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textPrimary,
                        ),
                        onPressed: provider.actionState ==
                                    ExcursionScheduleActionState.loading ||
                                !hasOfferOptions
                            ? null
                            : () => _save(provider),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(l10n.guideCalendarSaveSlot),
                      ),
                      OutlinedButton.icon(
                        style: _closeSlotButtonStyle(),
                        onPressed: provider.actionState ==
                                ExcursionScheduleActionState.loading
                            ? null
                            : () => _closeSlot(provider),
                        icon: const Icon(Icons.lock_clock_rounded),
                        label: Text(l10n.guideCalendarCloseSlot),
                      ),
                      OutlinedButton.icon(
                        style: _cancelSlotButtonStyle(),
                        onPressed: provider.actionState ==
                                ExcursionScheduleActionState.loading
                            ? null
                            : () => _cancelSlot(provider),
                        icon: const Icon(Icons.event_busy_rounded),
                        label: Text(l10n.guideCalendarCancelSlot),
                      ),
                      OutlinedButton.icon(
                        style: _deleteSlotButtonStyle(),
                        onPressed: provider.actionState ==
                                ExcursionScheduleActionState.loading
                            ? null
                            : () => _deleteSlot(provider),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(l10n.guideCalendarDeleteSlot),
                      ),
                    ] else
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textPrimary,
                        ),
                        onPressed: provider.actionState ==
                                    ExcursionScheduleActionState.loading ||
                                !hasOfferOptions
                            ? null
                            : () => _save(provider),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(l10n.guideCalendarSaveSlot),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFFB8AB9D),
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFFB8AB9D),
        fontSize: 16,
        height: 1.2,
      ),
      errorMaxLines: 2,
      helperStyle: const TextStyle(
        color: Color(0xFFB8AB9D),
        fontWeight: FontWeight.w600,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      filled: true,
      fillColor: const Color(0xFF3A2107),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.55)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: Color(0xFFFFB4A8)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: Color(0xFFFFB4A8)),
      ),
    );
  }

  ChipThemeData _chipTheme(BuildContext context) {
    return Theme.of(context).chipTheme.copyWith(
          backgroundColor: const Color(0xFF3A2107),
          selectedColor: AppColors.accent,
          disabledColor: const Color(0xFF3A2107).withValues(alpha: 0.52),
          checkmarkColor: AppColors.textPrimary,
          labelStyle: const TextStyle(
            color: Color(0xFFEFDCC8),
            fontWeight: FontWeight.w800,
          ),
          secondaryLabelStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.26)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        );
  }

  ButtonStyle _closeSlotButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      backgroundColor: AppColors.accent.withValues(alpha: 0.16),
      side: BorderSide(color: AppColors.accent.withValues(alpha: 0.58)),
    );
  }

  ButtonStyle _cancelSlotButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFFFE5BF),
      backgroundColor: const Color(0xFF7A4A08).withValues(alpha: 0.34),
      side: BorderSide(color: AppColors.accent.withValues(alpha: 0.34)),
    );
  }

  ButtonStyle _deleteSlotButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFFFD6CC),
      backgroundColor: const Color(0xFF6D2418).withValues(alpha: 0.42),
      side: BorderSide(color: const Color(0xFFFF8A76).withValues(alpha: 0.36)),
    );
  }

  void _clearActionHints({
    bool clearOffer = false,
    bool clearDate = false,
    bool clearTime = false,
    bool clearCapacity = false,
  }) {
    if (_showConflictBanner ||
        (clearOffer && _offerError != null) ||
        (clearDate && _dateError != null) ||
        (clearTime && _timeError != null) ||
        (clearCapacity && _capacityError != null)) {
      setState(() {
        _showConflictBanner = false;
        if (clearOffer) _offerError = null;
        if (clearDate) _dateError = null;
        if (clearTime) _timeError = null;
        if (clearCapacity) _capacityError = null;
      });
    }
  }

  void _handleDateTextChanged(String value) {
    _clearActionHints(clearDate: true);
    final parsed = _parseDate(value);
    if (parsed == null) return;
    setState(() {
      _date = parsed;
      _weekdays = {_isoWeekday(_date)};
    });
  }

  void _handleTimeTextChanged(String value) {
    _clearActionHints(clearTime: true);
    final parsed = _parseTime(value);
    if (parsed == null) return;
    setState(() => _time = parsed);
  }

  DateTime? _parseDate(String value) {
    final parts = value.trim().split('.');
    if (parts.length != 3 || parts.any((part) => part.length < 2)) {
      return null;
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null || year < 2000) {
      return null;
    }
    final parsed = DateTime(year, month, day);
    if (parsed.day != day || parsed.month != month || parsed.year != year) {
      return null;
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2 || parts.any((part) => part.length != 2)) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime? _manualStartAt(AppLocalizations l10n) {
    final parsedDate = _parseDate(_dateController.text);
    final parsedTime = _parseTime(_timeController.text);
    setState(() {
      _dateError = parsedDate == null ? l10n.guideCalendarInvalidDate : null;
      _timeError = parsedTime == null ? l10n.guideCalendarInvalidTime : null;
      if (parsedDate != null) {
        _date = parsedDate;
        _weekdays = {_isoWeekday(_date)};
      }
      if (parsedTime != null) {
        _time = parsedTime;
      }
    });
    if (parsedDate == null || parsedTime == null) return null;
    final startAt = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );
    if (startAt
        .toUtc()
        .isBefore(DateTime.now().toUtc().add(_slotSetupLeadTime))) {
      setState(() {
        _timeError = l10n.guideCalendarSlotLeadTimeTooSoon;
      });
      return null;
    }
    return startAt;
  }

  String _formatTime(TimeOfDay value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save(ExcursionScheduleProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _showConflictBanner = false;
      _offerError = null;
      _capacityError = null;
    });
    final startAt = _manualStartAt(l10n);
    if (startAt == null) {
      return;
    }
    final offerId = _selectedOfferId?.trim() ?? '';
    if (offerId.isEmpty) {
      setState(() => _offerError = l10n.guideCalendarOfferRequired);
      return;
    }
    final capacity = int.tryParse(_capacityController.text.trim());
    final selectedOffer = _selectedOfferOption(
      _dropdownOfferOptions(
        _offerOptions(
          context.read<ExcursionProvider>().myGuideExcursions,
          l10n,
        ),
        context.read<ExcursionProvider>().myGuideExcursions,
        l10n,
      ),
    );
    final maxCapacity = selectedOffer?.maxCapacity;
    if (capacity != null && maxCapacity != null && capacity > maxCapacity) {
      setState(() {
        _capacityError = l10n.guideCalendarCapacityTooHigh(maxCapacity);
      });
      return;
    }
    final ok = widget.slot != null
        ? await provider.updateSlot(
            widget.slot!.id,
            UpdateExcursionScheduleSlotRequest(
              offerId: offerId,
              startAt: startAt,
              timezone: _timezone,
              capacity: capacity,
            ),
          )
        : _repeatWeekly
            ? await provider.createSeries(
                CreateExcursionScheduleSeriesRequest(
                  offerId: offerId,
                  startsOn: _date,
                  startTime: _formatTime(_time),
                  timezone: _timezone,
                  weekdays: _weekdays.toList()..sort(),
                  occurrenceLimit: 12,
                  capacity: capacity,
                ),
              )
            : await provider.createSlot(
                CreateExcursionScheduleSlotRequest(
                  offerId: offerId,
                  startAt: startAt,
                  timezone: _timezone,
                  capacity: capacity,
                ),
              );
    if (!mounted) return;
    final showConflict = !ok && provider.isActionConflict;
    setState(() => _showConflictBanner = showConflict);
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _closeSlot(ExcursionScheduleProvider provider) async {
    final ok = await provider.closeSlot(widget.slot!.id);
    if (ok && mounted) Navigator.of(context).pop();
  }

  Future<void> _cancelSlot(ExcursionScheduleProvider provider) async {
    final ok = await provider.cancelSlot(widget.slot!.id, 'cancelled by guide');
    if (ok && mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteSlot(ExcursionScheduleProvider provider) async {
    final ok = await provider.deleteSlot(widget.slot!.id);
    if (ok && mounted) Navigator.of(context).pop();
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  }

  int _isoWeekday(DateTime value) => value.weekday == 0 ? 7 : value.weekday;

  List<_ScheduleOfferOption> _offerOptions(
    List<ExcursionVm> excursions,
    AppLocalizations l10n,
  ) {
    final options = <_ScheduleOfferOption>[];
    final seenOfferIds = <String>{};
    void addOption(_ScheduleOfferOption option) {
      if (seenOfferIds.add(option.id)) {
        options.add(option);
      }
    }

    for (final excursion in excursions) {
      for (final offer in excursion.offers) {
        final offerId = offer.id.trim();
        if (offerId.isEmpty || !_isPublishedPublic(offer)) continue;

        final title = offer.title.trim().isNotEmpty
            ? offer.title.trim()
            : excursion.title.trim();
        final details = <String>[
          if (offer.durationMinutes > 0)
            l10n.guideCalendarOfferDuration(offer.durationMinutes),
          if (offer.maxGroupSize > 0)
            l10n.guideCalendarOfferCapacity(offer.maxGroupSize),
          if (offer.meetingPoint.trim().isNotEmpty) offer.meetingPoint.trim(),
        ];

        addOption(
          _ScheduleOfferOption(
            id: offerId,
            title: title.isNotEmpty ? title : offerId,
            subtitle: details.join(' / '),
            maxCapacity: offer.maxGroupSize > 0 ? offer.maxGroupSize : null,
            productId: offer.productId.trim(),
            legacyExcursionId: offer.legacyExcursionId?.trim(),
            sourceExcursionId: excursion.id.trim(),
          ),
        );
      }
      final fallbackOption = _fallbackOptionFromExcursion(excursion, l10n);
      if (fallbackOption != null) {
        addOption(fallbackOption);
      }
    }
    options.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return options;
  }

  List<_ScheduleOfferOption> _dropdownOfferOptions(
    List<_ScheduleOfferOption> offerOptions,
    List<ExcursionVm> excursions,
    AppLocalizations l10n,
  ) {
    final selectedOfferId = _selectedOfferId?.trim();
    if (selectedOfferId == null ||
        selectedOfferId.isEmpty ||
        offerOptions.any((option) => option.id == selectedOfferId)) {
      return offerOptions;
    }

    final matchingIndex = _currentSlotOfferOptionIndex(
      offerOptions,
      excursions,
    );
    if (matchingIndex >= 0) {
      return [
        for (var i = 0; i < offerOptions.length; i++)
          if (i == matchingIndex)
            _currentSlotOfferOption(
              selectedOfferId: selectedOfferId,
              matchedOption: offerOptions[i],
              slotTitle: _slotOfferTitle(excursions),
            )
          else
            offerOptions[i],
      ];
    }

    final slotTitle = _slotOfferTitle(excursions)?.trim();
    return [
      _ScheduleOfferOption(
        id: selectedOfferId,
        title: slotTitle?.isNotEmpty == true
            ? slotTitle!
            : l10n.guideCalendarCurrentOfferFallback,
        subtitle: '',
        maxCapacity: widget.slot?.capacity,
      ),
      ...offerOptions,
    ];
  }

  int _currentSlotOfferOptionIndex(
    List<_ScheduleOfferOption> offerOptions,
    List<ExcursionVm> excursions,
  ) {
    final slotIdentityIds = _slotOfferIdentityIds();
    if (slotIdentityIds.isEmpty) return -1;

    final exactMatchIndex = offerOptions.indexWhere(
      (option) => slotIdentityIds.contains(option.id.trim()),
    );
    if (exactMatchIndex >= 0) return exactMatchIndex;

    final relatedMatches = <int>[];
    for (var i = 0; i < offerOptions.length; i++) {
      if (_isSameSlotOfferOption(offerOptions[i])) {
        relatedMatches.add(i);
      }
    }
    if (relatedMatches.length == 1) return relatedMatches.single;

    final slotTitle = _normalizeOfferTitle(_slotOfferTitle(excursions));
    if (slotTitle.isEmpty) return -1;

    final titleMatches = <int>[];
    final titleCandidates = relatedMatches.isEmpty
        ? Iterable<int>.generate(offerOptions.length)
        : relatedMatches;
    for (final i in titleCandidates) {
      if (_normalizeOfferTitle(offerOptions[i].title) == slotTitle) {
        titleMatches.add(i);
      }
    }
    return titleMatches.length == 1 ? titleMatches.single : -1;
  }

  bool _isSameSlotOfferOption(_ScheduleOfferOption option) {
    final slotIdentityIds = _slotOfferIdentityIds();
    if (slotIdentityIds.isEmpty) return false;
    return option.identityIds.any(slotIdentityIds.contains);
  }

  _ScheduleOfferOption _currentSlotOfferOption({
    required String selectedOfferId,
    required _ScheduleOfferOption matchedOption,
    String? slotTitle,
  }) {
    final normalizedSlotTitle = slotTitle?.trim();
    return _ScheduleOfferOption(
      id: selectedOfferId,
      title: normalizedSlotTitle?.isNotEmpty == true
          ? normalizedSlotTitle!
          : matchedOption.title,
      subtitle: matchedOption.subtitle,
      maxCapacity: matchedOption.maxCapacity,
      productId: matchedOption.productId,
      legacyExcursionId: matchedOption.legacyExcursionId,
      sourceExcursionId: matchedOption.sourceExcursionId,
    );
  }

  Set<String> _slotOfferIdentityIds() {
    final slot = widget.slot;
    if (slot == null) return const <String>{};
    return <String>{
      _selectedOfferId ?? '',
      slot.offerId,
      slot.productId,
      slot.legacyExcursionId ?? '',
    }.map((value) => value.trim()).where((value) => value.isNotEmpty).toSet();
  }

  String _normalizeOfferTitle(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  String? _slotOfferTitle(List<ExcursionVm> excursions) {
    final slot = widget.slot;
    if (slot == null) return null;
    final slotTitle = slot.title.trim();
    if (slotTitle.isNotEmpty) return slotTitle;

    final selectedOfferId = _selectedOfferId?.trim();
    final legacyExcursionId = slot.legacyExcursionId?.trim();
    final productId = slot.productId.trim();

    for (final excursion in excursions) {
      for (final offer in excursion.offers) {
        if (selectedOfferId != null &&
            selectedOfferId.isNotEmpty &&
            offer.id.trim() == selectedOfferId) {
          final offerTitle = offer.title.trim();
          if (offerTitle.isNotEmpty) return offerTitle;
          final excursionTitle = excursion.title.trim();
          return excursionTitle.isNotEmpty ? excursionTitle : null;
        }
      }
      if (legacyExcursionId != null &&
          legacyExcursionId.isNotEmpty &&
          excursion.id.trim() == legacyExcursionId) {
        final title = excursion.title.trim();
        if (title.isNotEmpty) return title;
      }
      if (productId.isNotEmpty && excursion.id.trim() == productId) {
        final title = excursion.title.trim();
        if (title.isNotEmpty) return title;
      }
    }
    return null;
  }

  _ScheduleOfferOption? _selectedOfferOption(
    List<_ScheduleOfferOption> options,
  ) {
    final selectedOfferId = _selectedOfferId?.trim();
    if (selectedOfferId == null || selectedOfferId.isEmpty) return null;
    for (final option in options) {
      if (option.id == selectedOfferId) return option;
    }
    return null;
  }

  bool _isPublishedPublic(ExcursionOfferVm offer) {
    return offer.status.trim().toUpperCase() == 'PUBLISHED' &&
        offer.visibility.trim().toUpperCase() == 'PUBLIC';
  }

  _ScheduleOfferOption? _fallbackOptionFromExcursion(
    ExcursionVm excursion,
    AppLocalizations l10n,
  ) {
    if (excursion.status.trim().toUpperCase() != 'PUBLISHED' ||
        excursion.visibility.trim().toUpperCase() != 'PUBLIC') {
      return null;
    }
    final id = excursion.primaryOffer?.id.trim().isNotEmpty == true
        ? excursion.primaryOffer!.id.trim()
        : excursion.id.trim();
    if (id.isEmpty) return null;

    final details = <String>[
      if (excursion.durationMinutes > 0)
        l10n.guideCalendarOfferDuration(excursion.durationMinutes),
      if (excursion.maxGroupSize > 0)
        l10n.guideCalendarOfferCapacity(excursion.maxGroupSize),
      if (excursion.meetingPoint.trim().isNotEmpty)
        excursion.meetingPoint.trim(),
    ];
    final title = excursion.title.trim();
    return _ScheduleOfferOption(
      id: id,
      title: title.isNotEmpty ? title : id,
      subtitle: details.join(' / '),
      maxCapacity: excursion.maxGroupSize > 0 ? excursion.maxGroupSize : null,
      productId: excursion.id.trim(),
      legacyExcursionId: excursion.primaryOffer?.legacyExcursionId?.trim(),
      sourceExcursionId: excursion.id.trim(),
    );
  }

  List<_WeekdayOption> _weekdayOptions(BuildContext context) {
    final labels = MaterialLocalizations.of(context).narrowWeekdays;
    return [
      _WeekdayOption(1, labels[1]),
      _WeekdayOption(2, labels[2]),
      _WeekdayOption(3, labels[3]),
      _WeekdayOption(4, labels[4]),
      _WeekdayOption(5, labels[5]),
      _WeekdayOption(6, labels[6]),
      _WeekdayOption(7, labels[0]),
    ];
  }
}

class _OfferOptionTile extends StatelessWidget {
  const _OfferOptionTile({required this.option});

  final _ScheduleOfferOption option;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.route_rounded,
              color: AppColors.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (option.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleOfferOption {
  const _ScheduleOfferOption({
    required this.id,
    required this.title,
    required this.subtitle,
    this.maxCapacity,
    this.productId,
    this.legacyExcursionId,
    this.sourceExcursionId,
  });

  final String id;
  final String title;
  final String subtitle;
  final int? maxCapacity;
  final String? productId;
  final String? legacyExcursionId;
  final String? sourceExcursionId;

  Set<String> get identityIds {
    return <String>{
      id,
      productId ?? '',
      legacyExcursionId ?? '',
      sourceExcursionId ?? '',
    }.map((value) => value.trim()).where((value) => value.isNotEmpty).toSet();
  }
}

class _SlotTextField extends StatelessWidget {
  const _SlotTextField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.enabled,
    required this.keyboardType,
    required this.inputFormatters,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 230),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        cursorColor: AppColors.accent,
        style: TextStyle(
          color: enabled
              ? AppColors.textPrimary
              : AppColors.textPrimary.withValues(alpha: 0.72),
          fontSize: 16,
          height: 1.2,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          errorMaxLines: 2,
          labelStyle: const TextStyle(
            color: Color(0xFFB8AB9D),
            fontWeight: FontWeight.w700,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFFB8AB9D),
            fontSize: 16,
            height: 1.2,
          ),
          suffixIcon: Icon(icon, color: _slotSheetFieldIconColor, size: 20),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 64,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(18, 17, 8, 17),
          filled: true,
          fillColor: const Color(0xFF3A2107),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: AppColors.accent.withValues(alpha: 0.55),
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Color(0xFFFFB4A8)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Color(0xFFFFB4A8)),
          ),
        ),
      ),
    );
  }
}

class _DateInputFormatter extends TextInputFormatter {
  const _DateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitSelection = _digitSelectionOffset(newValue);
    final digits = _limitedDigits(newValue.text, 8);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('.');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: _formatSelectionOffset(text, digitSelection, digits.length),
      ),
    );
  }
}

class _TimeInputFormatter extends TextInputFormatter {
  const _TimeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitSelection = _digitSelectionOffset(newValue);
    final digits = _limitedDigits(newValue.text, 4);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write(':');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: _formatSelectionOffset(text, digitSelection, digits.length),
      ),
    );
  }
}

int _digitSelectionOffset(TextEditingValue value) {
  final end = value.selection.extentOffset;
  if (end <= 0) return 0;
  final safeEnd = end > value.text.length ? value.text.length : end;
  return RegExp(r'\d').allMatches(value.text.substring(0, safeEnd)).length;
}

int _formatSelectionOffset(
  String formatted,
  int digitSelection,
  int maxDigits,
) {
  final targetDigits = digitSelection > maxDigits ? maxDigits : digitSelection;
  if (targetDigits <= 0) return 0;
  var seenDigits = 0;
  for (var i = 0; i < formatted.length; i++) {
    if (RegExp(r'\d').hasMatch(formatted[i])) {
      seenDigits++;
      if (seenDigits == targetDigits) return i + 1;
    }
  }
  return formatted.length;
}

String _limitedDigits(String value, int maxLength) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= maxLength) return digits;
  return digits.substring(0, maxLength);
}

class _GuideCalendarConflictBanner extends StatelessWidget {
  const _GuideCalendarConflictBanner({
    required this.title,
    required this.suggestionLabel,
  });

  final String title;
  final String suggestionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.38)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestionLabel,
                  style: const TextStyle(
                    color: Color(0xFFEFDCC8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayOption {
  const _WeekdayOption(this.value, this.label);

  final int value;
  final String label;
}
