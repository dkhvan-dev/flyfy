import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/device/device_context_service.dart';
import '../../../core/time/app_time.dart';
import '../../../features/excursions/models/excursion_schedule_vm.dart';
import '../../../features/excursions/models/excursion_vm.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/excursion_provider.dart';
import '../../../providers/excursion_schedule_provider.dart';

const _slotSheetFieldIconColor = AppPalette.orangeSoft11;

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
    _timezone = widget.slot?.timezone ?? 'Asia/Almaty';
    final start = widget.slot == null
        ? widget.initialDate ?? DateTime.now()
        : eventDateTime(widget.slot!.startAt, _timezone);
    _date = DateTime(start.year, start.month, start.day);
    _time = TimeOfDay.fromDateTime(start);
    _selectedOfferId = widget.slot?.offerId;
    _dateController = TextEditingController(text: _formatDate(_date));
    _timeController = TextEditingController(text: _formatTime(_time));
    _capacityController = TextEditingController(
      text: widget.slot == null ? '' : widget.slot!.capacity.toString(),
    );
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
    final guideExcursions = context
        .watch<ExcursionProvider>()
        .myGuideExcursions;
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
    final isReadonly = widget.slot?.isReadonly == true;

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return DecoratedBox(
            decoration: const AppBoxDecoration(
              color: AppPalette.warmSurface01,
              borderRadius: AppBorderRadius.vertical(
                top: AppRadiusValue.circular(8),
              ),
            ),
            child: ListView(
              controller: controller,
              padding: AppEdgeInsets.fromLTRB(
                20,
                18,
                20,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Text(
                  isReadonly
                      ? l10n.guideCalendarViewSlot
                      : isEditing
                      ? l10n.guideCalendarEditSlot
                      : l10n.guideCalendarAddSlot,
                  style: const AppTextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedOfferId,
                  menuMaxHeight: 320,
                  itemHeight: 74,
                  borderRadius: AppBorderRadius.circular(8),
                  items: dropdownOptions
                      .map((option) {
                        return DropdownMenuItem<String>(
                          value: option.id,
                          child: _OfferOptionTile(option: option),
                        );
                      })
                      .toList(growable: false),
                  selectedItemBuilder: (context) => dropdownOptions
                      .map((option) {
                        return Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            option.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const AppTextStyle(
                              color: AppPalette.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                  onChanged: isReadonly || !hasOfferOptions
                      ? null
                      : (value) => setState(() {
                          _selectedOfferId = value;
                          _offerError = null;
                          _showConflictBanner = false;
                        }),
                  isExpanded: true,
                  dropdownColor: AppPalette.warmSurface01,
                  iconEnabledColor: _slotSheetFieldIconColor,
                  iconDisabledColor: _slotSheetFieldIconColor,
                  style: const AppTextStyle(color: AppPalette.textPrimary),
                  decoration: _inputDecoration(l10n.guideCalendarOfferLabel)
                      .copyWith(
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
                      enabled: !isReadonly,
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
                      enabled: !isReadonly,
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
                  enabled: !isReadonly,
                  cursorColor: AppPalette.primary,
                  style: const AppTextStyle(color: AppPalette.textPrimary),
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
                if (isReadonly) ...[
                  const SizedBox(height: 16),
                  _GuideCalendarReadonlyBanner(
                    title: l10n.guideCalendarReadonlyCompletedSlot,
                  ),
                ],
                if (showActionError) ...[
                  const SizedBox(height: 14),
                  Text(
                    provider.actionErrorMessage!,
                    style: const AppTextStyle(
                      color: AppPalette.redLight03,
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
                    if (isEditing && !isReadonly) ...[
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.primary,
                          foregroundColor: AppPalette.textPrimary,
                        ),
                        onPressed:
                            provider.actionState ==
                                    ExcursionScheduleActionState.loading ||
                                !hasOfferOptions
                            ? null
                            : () => _save(provider),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(l10n.guideCalendarSaveSlot),
                      ),
                      OutlinedButton.icon(
                        style: _closeSlotButtonStyle(),
                        onPressed:
                            provider.actionState ==
                                ExcursionScheduleActionState.loading
                            ? null
                            : () => _closeSlot(provider),
                        icon: const Icon(Icons.lock_clock_rounded),
                        label: Text(l10n.guideCalendarCloseSlot),
                      ),
                      OutlinedButton.icon(
                        style: _cancelSlotButtonStyle(),
                        onPressed:
                            provider.actionState ==
                                ExcursionScheduleActionState.loading
                            ? null
                            : () => _cancelSlot(provider),
                        icon: const Icon(Icons.event_busy_rounded),
                        label: Text(l10n.guideCalendarCancelSlot),
                      ),
                      OutlinedButton.icon(
                        style: _deleteSlotButtonStyle(),
                        onPressed:
                            provider.actionState ==
                                ExcursionScheduleActionState.loading
                            ? null
                            : () => _deleteSlot(provider),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(l10n.guideCalendarDeleteSlot),
                      ),
                    ] else
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.primary,
                          foregroundColor: AppPalette.textPrimary,
                        ),
                        onPressed:
                            provider.actionState ==
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
    return AppInputDecoration(
      labelText: label,
      labelStyle: const AppTextStyle(
        color: AppPalette.orangeSoft11,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const AppTextStyle(
        color: AppPalette.orangeSoft11,
        fontSize: 16,
        height: 1.2,
      ),
      errorMaxLines: 2,
      helperStyle: const AppTextStyle(
        color: AppPalette.orangeSoft11,
        fontWeight: FontWeight.w600,
      ),
      isDense: true,
      contentPadding: const AppEdgeInsets.fromLTRB(18, 17, 18, 17),
      filled: true,
      fillColor: AppPalette.warmSurface47,
      border: OutlineInputBorder(
        borderRadius: AppBorderRadius.circular(999),
        borderSide: BorderSide(color: AppPalette.white.withValues(alpha: 0.03)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.circular(999),
        borderSide: BorderSide(color: AppPalette.white.withValues(alpha: 0.03)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.circular(999),
        borderSide: BorderSide(
          color: AppPalette.primary.withValues(alpha: 0.55),
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.circular(999),
        borderSide: BorderSide(color: AppPalette.white.withValues(alpha: 0.03)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.circular(999),
        borderSide: const BorderSide(color: AppPalette.redLight03),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.circular(999),
        borderSide: const BorderSide(color: AppPalette.redLight03),
      ),
    );
  }

  ChipThemeData _chipTheme(BuildContext context) {
    return Theme.of(context).chipTheme.copyWith(
      backgroundColor: AppPalette.warmSurface47,
      selectedColor: AppPalette.primary,
      disabledColor: AppPalette.warmSurface47.withValues(alpha: 0.52),
      checkmarkColor: AppPalette.textPrimary,
      labelStyle: const AppTextStyle(
        color: AppPalette.orangeLight30,
        fontWeight: FontWeight.w800,
      ),
      secondaryLabelStyle: const AppTextStyle(
        color: AppPalette.textPrimary,
        fontWeight: FontWeight.w900,
      ),
      side: BorderSide(color: AppPalette.primary.withValues(alpha: 0.26)),
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.circular(999),
      ),
      padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  ButtonStyle _closeSlotButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppPalette.textPrimary,
      backgroundColor: AppPalette.primary.withValues(alpha: 0.16),
      side: BorderSide(color: AppPalette.primary.withValues(alpha: 0.58)),
    );
  }

  ButtonStyle _cancelSlotButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppPalette.amberLight15,
      backgroundColor: AppPalette.warmSurfaceHigh25.withValues(alpha: 0.34),
      side: BorderSide(color: AppPalette.primary.withValues(alpha: 0.34)),
    );
  }

  ButtonStyle _deleteSlotButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppPalette.redWash01,
      backgroundColor: AppPalette.redSurfaceHigh02.withValues(alpha: 0.42),
      side: BorderSide(color: AppPalette.redSoft12.withValues(alpha: 0.36)),
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
    if (eventWallClockToUtc(
      startAt,
      _timezone,
    ).isBefore(DateTime.now().toUtc().add(_slotSetupLeadTime))) {
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
    final reason = await showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: AppPalette.transparent,
      builder: (_) => const _GuideCancelSlotReasonSheet(),
    );
    if (!mounted || reason == null) return;

    final ok = await provider.cancelSlot(widget.slot!.id, reason);
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
      padding: const AppEdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: AppBoxDecoration(
              color: AppPalette.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.route_rounded,
              color: AppPalette.primary,
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
                  style: const AppTextStyle(
                    color: AppPalette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (option.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const AppTextStyle(
                      color: AppPalette.textCoolSecondary,
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
        cursorColor: AppPalette.primary,
        style: AppTextStyle(
          color: enabled
              ? AppPalette.textPrimary
              : AppPalette.textPrimary.withValues(alpha: 0.72),
          fontSize: 16,
          height: 1.2,
        ),
        decoration: AppInputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          errorMaxLines: 2,
          labelStyle: const AppTextStyle(
            color: AppPalette.orangeSoft11,
            fontWeight: FontWeight.w700,
          ),
          hintStyle: const AppTextStyle(
            color: AppPalette.orangeSoft11,
            fontSize: 16,
            height: 1.2,
          ),
          suffixIcon: Icon(icon, color: _slotSheetFieldIconColor, size: 20),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 64,
          ),
          isDense: true,
          contentPadding: const AppEdgeInsets.fromLTRB(18, 17, 8, 17),
          filled: true,
          fillColor: AppPalette.warmSurface47,
          border: OutlineInputBorder(
            borderRadius: AppBorderRadius.circular(999),
            borderSide: BorderSide(
              color: AppPalette.white.withValues(alpha: 0.03),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppBorderRadius.circular(999),
            borderSide: BorderSide(
              color: AppPalette.white.withValues(alpha: 0.03),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppBorderRadius.circular(999),
            borderSide: BorderSide(
              color: AppPalette.primary.withValues(alpha: 0.55),
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: AppBorderRadius.circular(999),
            borderSide: BorderSide(
              color: AppPalette.white.withValues(alpha: 0.03),
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppBorderRadius.circular(999),
            borderSide: const BorderSide(color: AppPalette.redLight03),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppBorderRadius.circular(999),
            borderSide: const BorderSide(color: AppPalette.redLight03),
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
      padding: const AppEdgeInsets.all(14),
      decoration: AppBoxDecoration(
        color: AppPalette.primary.withValues(alpha: 0.12),
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.38)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppPalette.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const AppTextStyle(
                    color: AppPalette.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestionLabel,
                  style: const AppTextStyle(
                    color: AppPalette.orangeLight30,
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

class _GuideCalendarReadonlyBanner extends StatelessWidget {
  const _GuideCalendarReadonlyBanner({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const AppEdgeInsets.all(14),
      decoration: AppBoxDecoration(
        color: AppPalette.warmSurface47.withValues(alpha: 0.68),
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_rounded, color: AppPalette.orangeLight01),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const AppTextStyle(
                color: AppPalette.orangeLight30,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCancelSlotReasonSheet extends StatefulWidget {
  const _GuideCancelSlotReasonSheet();

  @override
  State<_GuideCancelSlotReasonSheet> createState() =>
      _GuideCancelSlotReasonSheetState();
}

class _GuideCancelSlotReasonSheetState
    extends State<_GuideCancelSlotReasonSheet> {
  final TextEditingController _reasonController = TextEditingController();
  final FocusNode _reasonFocusNode = FocusNode();
  String? _errorText;

  @override
  void dispose() {
    _reasonController.dispose();
    _reasonFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() {
        _errorText = AppLocalizations.of(
          context,
        )!.guideDashboardCancelReasonRequired;
      });
      _reasonFocusNode.requestFocus();
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final compact = mediaQuery.size.width < 390;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: AppEdgeInsets.fromLTRB(
          12,
          0,
          12,
          mediaQuery.viewInsets.bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 540,
              maxHeight: mediaQuery.size.height * 0.86,
            ),
            child: DecoratedBox(
              decoration: AppBoxDecoration(
                color: AppPalette.warmSurface01,
                borderRadius: const AppBorderRadius.vertical(
                  top: AppRadiusValue.circular(24),
                ),
                border: Border.all(
                  color: AppPalette.white.withValues(alpha: 0.08),
                ),
              ),
              child: SingleChildScrollView(
                padding: AppEdgeInsets.fromLTRB(
                  compact ? 16 : 20,
                  14,
                  compact ? 16 : 20,
                  22 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 52,
                        height: 5,
                        decoration: AppBoxDecoration(
                          color: AppPalette.white.withValues(alpha: 0.18),
                          borderRadius: AppBorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.guideDashboardCancelTitle,
                      style: AppTextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: compact ? 21 : 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.guideDashboardCancelDescription,
                      style: const AppTextStyle(
                        color: AppPalette.orangeLight01,
                        fontSize: 14,
                        height: 1.42,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.guideDashboardCancelReasonLabel,
                      style: const AppTextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DecoratedBox(
                      decoration: AppBoxDecoration(
                        color: AppPalette.white.withValues(alpha: 0.05),
                        borderRadius: AppBorderRadius.circular(18),
                        border: Border.all(
                          color: _errorText == null
                              ? AppPalette.white.withValues(alpha: 0.08)
                              : AppPalette.redOverlaySoft02,
                        ),
                      ),
                      child: TextField(
                        controller: _reasonController,
                        focusNode: _reasonFocusNode,
                        maxLines: 4,
                        minLines: 3,
                        maxLength: 160,
                        textCapitalization: TextCapitalization.sentences,
                        style: const AppTextStyle(
                          color: AppPalette.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        decoration: AppInputDecoration(
                          hintText: l10n.guideDashboardCancelReasonPlaceholder,
                          hintStyle: AppTextStyle(
                            color: AppPalette.orangeLight01.withValues(
                              alpha: 0.72,
                            ),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          counterStyle: const AppTextStyle(
                            color: AppPalette.orangeLight01,
                            fontSize: 12,
                          ),
                          contentPadding: const AppEdgeInsets.fromLTRB(
                            14,
                            12,
                            14,
                            8,
                          ),
                        ),
                        onChanged: (_) {
                          if (_errorText != null &&
                              _reasonController.text.trim().isNotEmpty) {
                            setState(() => _errorText = null);
                          }
                        },
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorText!,
                        style: const AppTextStyle(
                          color: AppPalette.redSoft11,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stack = constraints.maxWidth < 360;
                        final keep = OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppPalette.textPrimary,
                            side: BorderSide(
                              color: AppPalette.white.withValues(alpha: 0.12),
                            ),
                            minimumSize: const Size(0, 50),
                          ),
                          child: Text(l10n.cancelButton),
                        );
                        final confirm = FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.event_busy_rounded),
                          label: Text(l10n.guideDashboardCancelConfirm),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppPalette.primary,
                            foregroundColor: AppPalette.white,
                            minimumSize: const Size(0, 50),
                          ),
                        );

                        if (stack) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              keep,
                              const SizedBox(height: 10),
                              confirm,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: keep),
                            const SizedBox(width: 10),
                            Expanded(child: confirm),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayOption {
  const _WeekdayOption(this.value, this.label);

  final int value;
  final String label;
}
