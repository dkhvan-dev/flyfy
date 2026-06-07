import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/time/app_time.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_view.dart';
import '../../features/excursions/models/create_excursion_booking_request.dart';
import '../../features/excursions/models/excursion_booking_vm.dart';
import '../../features/excursions/models/excursion_schedule_vm.dart';
import '../../features/excursions/models/excursion_vm.dart';
import '../../features/excursions/excursion_cover_url.dart';
import '../../features/excursions/excursion_localization.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/excursion_provider.dart';

class ExcursionBookingRouteArgs {
  const ExcursionBookingRouteArgs({this.excursion, this.selectedOfferId});

  final ExcursionVm? excursion;
  final String? selectedOfferId;
}

class ExcursionBookingScreen extends StatefulWidget {
  const ExcursionBookingScreen({
    super.key,
    required this.excursionId,
    this.initialExcursion,
    this.selectedOfferId,
  });

  final String excursionId;
  final ExcursionVm? initialExcursion;
  final String? selectedOfferId;

  @override
  State<ExcursionBookingScreen> createState() => _ExcursionBookingScreenState();
}

class _ExcursionBookingScreenState extends State<ExcursionBookingScreen> {
  ExcursionVm? _excursion;
  List<ExcursionScheduleSlotVm> _slots = const [];
  ExcursionScheduleSlotVm? _selectedSlot;
  String? _loadError;
  String? _scheduleError;
  String? _selectedSlotUnavailableMessage;
  bool _isLoading = true;
  bool _isScheduleLoading = false;
  bool _isSubmitting = false;
  int _scheduleRequestSerial = 0;
  int _adults = 1;
  int _children = 0;

  @override
  void initState() {
    super.initState();
    _excursion = _applySelectedOffer(widget.initialExcursion);
    _isLoading = widget.initialExcursion == null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExcursionProvider>().loadMyExcursionBookings();
      _ensureExcursionLoaded(silent: widget.initialExcursion != null);
    });
  }

  Future<void> _ensureExcursionLoaded({bool silent = false}) async {
    final trimmedExcursionId = widget.excursionId.trim();
    if (trimmedExcursionId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _excursion = null;
        _loadError = AppLocalizations.of(context)!.excursionBookingLoadFailed;
        _isLoading = false;
      });
      return;
    }

    final provider = context.read<ExcursionProvider>();
    final cachedExcursion =
        provider.excursionDetailsFor(trimmedExcursionId) ??
        provider.selectedExcursion;
    if (_excursion == null &&
        cachedExcursion != null &&
        cachedExcursion.id == trimmedExcursionId) {
      setState(() {
        _excursion = cachedExcursion;
        _isLoading = false;
        _loadError = null;
      });
    }

    if (!silent && mounted) {
      setState(() {
        _isLoading = _excursion == null;
        _loadError = null;
      });
    }

    await provider.loadExcursionDetails(
      trimmedExcursionId,
      initialExcursion: _excursion,
    );

    if (!mounted) return;
    final loadedExcursion =
        provider.excursionDetailsFor(trimmedExcursionId) ??
        provider.selectedExcursion;
    final loadedMatchingExcursion =
        loadedExcursion != null && loadedExcursion.id == trimmedExcursionId
        ? loadedExcursion
        : null;
    final nextExcursion = _applySelectedOffer(
      loadedMatchingExcursion ?? _excursion,
    );

    setState(() {
      _excursion = nextExcursion;
      _isLoading = false;
      _loadError = nextExcursion == null
          ? provider.detailErrorMessageFor(trimmedExcursionId) ??
                provider.detailErrorMessage
          : null;
      _clampTravelersToLimit(_travelerLimitFor(nextExcursion, _selectedSlot));
    });
    await _loadScheduleSlots();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/excursions/${Uri.encodeComponent(widget.excursionId)}');
  }

  Future<void> _loadScheduleSlots() async {
    final productId = widget.excursionId.trim();
    final offerId = _selectedOfferId;
    if (productId.isEmpty || offerId.isEmpty || _excursion == null) {
      return;
    }

    final requestSerial = ++_scheduleRequestSerial;
    final previousSlotId = _selectedSlot?.id;
    setState(() {
      _isScheduleLoading = true;
      _scheduleError = null;
      _selectedSlotUnavailableMessage = null;
    });

    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 90));

    try {
      final loadedSlots = await context
          .read<ExcursionProvider>()
          .loadBookableExcursionSchedule(
            productId: productId,
            offerId: offerId,
            from: from,
            to: to,
            seats: _totalTravelers,
          );
      if (!mounted || requestSerial != _scheduleRequestSerial) return;

      final slots = _sortSlots(
        loadedSlots
            .where((slot) => slot.isBookableForBooking(_totalTravelers))
            .toList(growable: false),
      );
      final preservedSlot = _slotById(slots, previousSlotId);
      final selectedSlot =
          preservedSlot ??
          (previousSlotId == null ? _firstSlotOrNull(slots) : null);
      final unavailableMessage = previousSlotId != null && preservedSlot == null
          ? AppLocalizations.of(
              context,
            )!.excursionBookingSelectedSlotUnavailable(_totalTravelers)
          : null;
      setState(() {
        _slots = slots;
        _selectedSlot = selectedSlot;
        _isScheduleLoading = false;
        _scheduleError = null;
        _selectedSlotUnavailableMessage = unavailableMessage;
      });
    } catch (_) {
      if (!mounted || requestSerial != _scheduleRequestSerial) return;
      setState(() {
        _slots = const [];
        _selectedSlot = null;
        _selectedSlotUnavailableMessage = null;
        _isScheduleLoading = false;
        _scheduleError = AppLocalizations.of(
          context,
        )!.excursionBookingScheduleLoadFailed;
      });
    }
  }

  List<ExcursionScheduleSlotVm> _sortSlots(
    List<ExcursionScheduleSlotVm> slots,
  ) {
    return List<ExcursionScheduleSlotVm>.of(slots)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  ExcursionScheduleSlotVm? _slotById(
    List<ExcursionScheduleSlotVm> slots,
    String? id,
  ) {
    if (id == null || id.trim().isEmpty) return null;
    for (final slot in slots) {
      if (slot.id == id) return slot;
    }
    return null;
  }

  ExcursionScheduleSlotVm? _firstSlotOrNull(
    List<ExcursionScheduleSlotVm> slots,
  ) {
    return slots.isEmpty ? null : slots.first;
  }

  void _incrementAdults() {
    if (_adults + _children >= _travelerLimit) return;
    setState(() => _adults++);
    _loadScheduleSlots();
  }

  void _decrementAdults() {
    if (_adults <= 1) return;
    setState(() => _adults--);
    _loadScheduleSlots();
  }

  void _incrementChildren() {
    if (_adults + _children >= _travelerLimit) return;
    setState(() => _children++);
    _loadScheduleSlots();
  }

  void _decrementChildren() {
    if (_children <= 0) return;
    setState(() => _children--);
    _loadScheduleSlots();
  }

  Future<void> _confirmBooking() async {
    if (_isSubmitting) return;
    final productId = widget.excursionId.trim();
    final offerId = _selectedOfferId;
    final selectedSlot = _selectedSlot;
    if (productId.isEmpty || offerId.isEmpty || selectedSlot == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              selectedSlot == null
                  ? AppLocalizations.of(context)!.excursionBookingSelectSlot
                  : AppLocalizations.of(context)!.excursionBookingLoadFailed,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF3A2B1D),
          ),
        );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    final scheduledFor = selectedSlot.startAt;
    final provider = context.read<ExcursionProvider>();
    final success = await provider.createExcursionBooking(
      CreateExcursionBookingRequest(
        productId: productId,
        offerId: offerId,
        scheduledFor: scheduledFor,
        adults: _adults,
        children: _children,
        scheduleSlotId: _selectedSlot?.id,
        idempotencyKey:
            '$productId:$offerId:${selectedSlot.id}:$_adults:$_children',
      ),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (!success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              provider.actionErrorMessage ??
                  AppLocalizations.of(context)!.excursionBookingLoadFailed,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF3A2B1D),
          ),
        );
      return;
    }
    await provider.loadMyExcursionBookings(force: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    context.go('/me/excursions');
  }

  int get _totalTravelers => _adults + _children;

  int get _travelerLimit => _travelerLimitFor(_excursion, _selectedSlot);

  String get _selectedOfferId {
    final explicit = widget.selectedOfferId?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    return (_excursion?.primaryOffer?.id ?? '').trim();
  }

  ExcursionVm? _applySelectedOffer(ExcursionVm? excursion) {
    final selectedOfferId = widget.selectedOfferId?.trim();
    if (excursion == null ||
        selectedOfferId == null ||
        selectedOfferId.isEmpty) {
      return excursion;
    }
    for (final offer in excursion.offers) {
      if (offer.id == selectedOfferId) {
        return excursion.withPrimaryOffer(offer);
      }
    }
    return excursion;
  }

  int _maxTravelersFor(ExcursionVm? excursion) {
    final groupSize = excursion?.maxGroupSize ?? 0;
    return groupSize > 0 ? groupSize : 12;
  }

  int _travelerLimitFor(
    ExcursionVm? excursion,
    ExcursionScheduleSlotVm? selectedSlot,
  ) {
    final excursionLimit = _maxTravelersFor(excursion);
    final slotLimit = selectedSlot?.availableSeats;
    if (slotLimit == null || slotLimit <= 0) {
      return excursionLimit;
    }
    return math.min(excursionLimit, slotLimit);
  }

  void _clampTravelersToLimit(int maxTravelers) {
    final safeMaxTravelers = math.max(1, maxTravelers);
    if (_adults > safeMaxTravelers) {
      _adults = safeMaxTravelers;
      _children = 0;
      return;
    }
    if (_adults + _children > safeMaxTravelers) {
      _children = math.max(0, safeMaxTravelers - _adults);
    }
  }

  ExcursionBookingVm? _existingBookingForSelectedSlot(
    List<ExcursionBookingVm> bookings,
  ) {
    final selectedSlot = _selectedSlot;
    final offerId = _selectedOfferId;
    final productId = widget.excursionId.trim();
    if (selectedSlot == null || offerId.isEmpty || productId.isEmpty) {
      return null;
    }
    final now = DateTime.now().toUtc();
    for (final booking in bookings) {
      if (!booking.isBooked(now) ||
          booking.productId != productId ||
          booking.offerId != offerId) {
        continue;
      }
      final bookedSlotId = booking.scheduleSlotId?.trim();
      if (bookedSlotId != null && bookedSlotId == selectedSlot.id) {
        return booking;
      }
      if ((bookedSlotId == null || bookedSlotId.isEmpty) &&
          booking.scheduledFor.isAtSameMomentAs(selectedSlot.startAt.toUtc())) {
        return booking;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const _BookingLoadingScaffold();
    }

    final excursion = _excursion;
    if (excursion == null) {
      return Scaffold(
        backgroundColor: _BookingColors.base,
        body: DecoratedBox(
          decoration: _BookingColors.backgroundDecoration,
          child: SafeArea(
            child: ErrorView(
              message: _loadError ?? l10n.excursionBookingLoadFailed,
              onRetry: () => _ensureExcursionLoaded(),
            ),
          ),
        ),
      );
    }

    final existingBooking = _existingBookingForSelectedSlot(
      context.watch<ExcursionProvider>().myExcursionBookings,
    );

    return Scaffold(
      backgroundColor: _BookingColors.base,
      body: ExcursionBookingContent(
        excursion: excursion,
        slots: _slots,
        selectedSlot: _selectedSlot,
        isScheduleLoading: _isScheduleLoading,
        scheduleError: _scheduleError,
        selectedSlotUnavailableMessage: _selectedSlotUnavailableMessage,
        adults: _adults,
        children: _children,
        maxTravelers: _travelerLimit,
        isSubmitting: _isSubmitting,
        existingBooking: existingBooking,
        loadError: _loadError,
        onBackTap: _goBack,
        onSelectSlot: (slot) => setState(() {
          _selectedSlot = slot;
          _selectedSlotUnavailableMessage = null;
          _clampTravelersToLimit(_travelerLimitFor(_excursion, slot));
        }),
        onReloadSchedule: _loadScheduleSlots,
        onIncrementAdults: _incrementAdults,
        onDecrementAdults: _decrementAdults,
        onIncrementChildren: _incrementChildren,
        onDecrementChildren: _decrementChildren,
        onConfirm: _confirmBooking,
        onOpenMyExcursions: () => context.go('/me/excursions'),
        onRetry: () => _ensureExcursionLoaded(),
      ),
    );
  }
}

class ExcursionBookingContent extends StatelessWidget {
  const ExcursionBookingContent({
    super.key,
    required this.excursion,
    required this.slots,
    required this.selectedSlot,
    required this.isScheduleLoading,
    required this.adults,
    required this.children,
    required this.maxTravelers,
    required this.isSubmitting,
    required this.existingBooking,
    required this.onBackTap,
    required this.onSelectSlot,
    required this.onReloadSchedule,
    required this.onIncrementAdults,
    required this.onDecrementAdults,
    required this.onIncrementChildren,
    required this.onDecrementChildren,
    required this.onConfirm,
    required this.onOpenMyExcursions,
    this.onRetry,
    this.loadError,
    this.scheduleError,
    this.selectedSlotUnavailableMessage,
  });

  final ExcursionVm excursion;
  final List<ExcursionScheduleSlotVm> slots;
  final ExcursionScheduleSlotVm? selectedSlot;
  final bool isScheduleLoading;
  final int adults;
  final int children;
  final int maxTravelers;
  final bool isSubmitting;
  final ExcursionBookingVm? existingBooking;
  final VoidCallback onBackTap;
  final ValueChanged<ExcursionScheduleSlotVm> onSelectSlot;
  final VoidCallback onReloadSchedule;
  final VoidCallback onIncrementAdults;
  final VoidCallback onDecrementAdults;
  final VoidCallback onIncrementChildren;
  final VoidCallback onDecrementChildren;
  final VoidCallback onConfirm;
  final VoidCallback onOpenMyExcursions;
  final VoidCallback? onRetry;
  final String? loadError;
  final String? scheduleError;
  final String? selectedSlotUnavailableMessage;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final horizontalPadding = compact ? 20.0 : 24.0;
    final effectiveMaxTravelers = _effectiveTravelerLimit(
      maxTravelers,
      selectedSlot,
    );
    final selectedSlotCanFitTravelers =
        selectedSlot?.isBookableForBooking(adults + children) ?? false;

    return DecoratedBox(
      decoration: _BookingColors.backgroundDecoration,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = math.min(430.0, constraints.maxWidth);
            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    _BookingTopBar(onBackTap: onBackTap),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          24,
                          horizontalPadding,
                          32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (loadError != null) ...[
                              _SoftErrorBanner(
                                message: loadError!,
                                onRetry: onRetry,
                              ),
                              const SizedBox(height: 16),
                            ],
                            _BookingExcursionCard(excursion: excursion),
                            SizedBox(
                              height: _bookingSectionGap(
                                context,
                                compact: 30,
                                regular: 42,
                              ),
                            ),
                            _BookingScheduleSection(
                              slots: slots,
                              selectedSlot: selectedSlot,
                              isLoading: isScheduleLoading,
                              errorMessage: scheduleError,
                              selectedSlotUnavailableMessage:
                                  selectedSlotUnavailableMessage,
                              travelers: adults + children,
                              onSelectSlot: onSelectSlot,
                              onReload: onReloadSchedule,
                            ),
                            SizedBox(
                              height: _bookingSectionGap(
                                context,
                                compact: 28,
                                regular: 38,
                              ),
                            ),
                            _TravelersSection(
                              adults: adults,
                              children: children,
                              maxTravelers: effectiveMaxTravelers,
                              onIncrementAdults: onIncrementAdults,
                              onDecrementAdults: onDecrementAdults,
                              onIncrementChildren: onIncrementChildren,
                              onDecrementChildren: onDecrementChildren,
                            ),
                            SizedBox(
                              height: _bookingSectionGap(
                                context,
                                compact: 34,
                                regular: 52,
                              ),
                            ),
                            _BookingSummarySection(
                              excursion: excursion,
                              adults: adults,
                              children: children,
                            ),
                            if (existingBooking != null) ...[
                              const SizedBox(height: 16),
                              _AlreadyBookedNotice(
                                booking: existingBooking!,
                                onOpenMyExcursions: onOpenMyExcursions,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _BookingFooter(
                      excursion: excursion,
                      adults: adults,
                      children: children,
                      isSubmitting: isSubmitting,
                      canConfirm:
                          selectedSlotCanFitTravelers &&
                          existingBooking == null,
                      existingBooking: existingBooking,
                      onConfirm: onConfirm,
                      onOpenMyExcursions: onOpenMyExcursions,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BookingTopBar extends StatelessWidget {
  const _BookingTopBar({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: _bookingTopBarMinHeight(context)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            _CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onTap: onBackTap,
            ),
            Expanded(
              child: Text(
                l10n.excursionBookingTitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _BookingColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

class _BookingExcursionCard extends StatelessWidget {
  const _BookingExcursionCard({required this.excursion});

  final ExcursionVm excursion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final imageUrl = resolveExcursionCoverUrl(excursion)?.trim() ?? '';
    final price = _formatBookingMoney(
      context,
      excursion.priceAmount,
      excursion.currency,
    );
    final cityName = excursion.cityName?.trim() ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = _bookingCoverImageSize(context, constraints.maxWidth);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: imageSize,
                height: imageSize,
                child: imageUrl.isEmpty
                    ? const _BookingImageFallback()
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _BookingImageFallback(),
                      ),
              ),
            ),
            SizedBox(width: _bookingInlineGap(context, regular: 20)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizedExcursionCategoryLabel(
                      l10n,
                      excursion.categorySlug,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    excursion.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _BookingColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 0.98,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (cityName.isNotEmpty)
                        _BookingInfoPill(
                          icon: Icons.place_rounded,
                          label: cityName,
                        ),
                      if (excursion.maxGroupSize > 0)
                        _BookingInfoPill(
                          icon: Icons.people_rounded,
                          label: l10n.excursionDetailsGroupSizeUpTo(
                            excursion.maxGroupSize,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BookingInfoPill extends StatelessWidget {
  const _BookingInfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _BookingColors.muted, size: 13),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _BookingColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingScheduleSection extends StatelessWidget {
  const _BookingScheduleSection({
    required this.slots,
    required this.selectedSlot,
    required this.isLoading,
    required this.travelers,
    required this.onSelectSlot,
    required this.onReload,
    this.errorMessage,
    this.selectedSlotUnavailableMessage,
  });

  final List<ExcursionScheduleSlotVm> slots;
  final ExcursionScheduleSlotVm? selectedSlot;
  final bool isLoading;
  final int travelers;
  final ValueChanged<ExcursionScheduleSlotVm> onSelectSlot;
  final VoidCallback onReload;
  final String? errorMessage;
  final String? selectedSlotUnavailableMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final selectedStart = selectedSlot == null
        ? null
        : eventDateTime(selectedSlot!.startAt, selectedSlot!.timezone);
    final dateLabel = selectedStart == null
        ? l10n.excursionBookingSelectSlot
        : DateFormat.yMMMd(locale).format(selectedStart);
    final timeLabel = selectedStart == null
        ? '--:--'
        : DateFormat.Hm(locale).format(selectedStart);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHead(
          title: l10n.excursionBookingSchedule,
          actionLabel: l10n.excursionBookingChange,
          onActionTap: () => _handleChangeTap(context),
        ),
        const SizedBox(height: 22),
        Column(
          children: [
            _BookingScheduleCard(
              icon: Icons.calendar_month_rounded,
              label: l10n.excursionBookingDate,
              value: dateLabel,
              active: true,
              highlightValue: true,
              onTap: () => _handleChangeTap(context),
            ),
            const SizedBox(height: 12),
            _BookingScheduleCard(
              icon: Icons.schedule_rounded,
              label: l10n.excursionBookingTimeSlot,
              value: timeLabel,
              active: true,
              highlightValue: true,
              onTap: () => _handleChangeTap(context),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _BookingSlotSelector(
          slots: slots,
          selectedSlot: selectedSlot,
          isLoading: isLoading,
          travelers: travelers,
          errorMessage: errorMessage,
          selectedSlotUnavailableMessage: selectedSlotUnavailableMessage,
          onSelectSlot: onSelectSlot,
          onRetry: onReload,
        ),
      ],
    );
  }

  void _handleChangeTap(BuildContext context) {
    if (isLoading) return;
    if (slots.isEmpty || errorMessage != null) {
      onReload();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.38,
          maxChildSize: 0.88,
          builder: (context, scrollController) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: _BookingColors.base,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.excursionBookingSelectSlot,
                        style: _sectionTitleStyle,
                      ),
                      const SizedBox(height: 18),
                      _BookingSlotSelector(
                        slots: slots,
                        selectedSlot: selectedSlot,
                        isLoading: false,
                        travelers: travelers,
                        selectedSlotUnavailableMessage:
                            selectedSlotUnavailableMessage,
                        onSelectSlot: (slot) {
                          onSelectSlot(slot);
                          Navigator.of(sheetContext).pop();
                        },
                        onRetry: onReload,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BookingSlotSelector extends StatelessWidget {
  const _BookingSlotSelector({
    required this.slots,
    required this.selectedSlot,
    required this.isLoading,
    required this.travelers,
    required this.onSelectSlot,
    required this.onRetry,
    this.errorMessage,
    this.selectedSlotUnavailableMessage,
  });

  final List<ExcursionScheduleSlotVm> slots;
  final ExcursionScheduleSlotVm? selectedSlot;
  final bool isLoading;
  final int travelers;
  final ValueChanged<ExcursionScheduleSlotVm> onSelectSlot;
  final VoidCallback onRetry;
  final String? errorMessage;
  final String? selectedSlotUnavailableMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isLoading && slots.isEmpty) {
      return const _BookingScheduleStatePanel(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }
    if (errorMessage != null) {
      return _SoftErrorBanner(message: errorMessage!, onRetry: onRetry);
    }
    if (slots.isEmpty) {
      return _BookingScheduleStatePanel(
        child: Text(
          l10n.excursionBookingNoSlots,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _BookingColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      );
    }

    final grouped = _groupSlotsByDay(slots);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedSlotUnavailableMessage != null) ...[
          _SoftErrorBanner(message: selectedSlotUnavailableMessage!),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < grouped.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          Text(
            DateFormat.yMMMd(locale).format(grouped[i].day),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _BookingColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final slot in grouped[i].slots)
                _BookingSlotChip(
                  key: ValueKey('booking-slot-chip-${slot.id}'),
                  slot: slot,
                  selected: selectedSlot?.id == slot.id,
                  enabled: slot.isBookableForBooking(travelers),
                  onTap: () => onSelectSlot(slot),
                ),
            ],
          ),
        ],
      ],
    );
  }

  List<_SlotsByDay> _groupSlotsByDay(List<ExcursionScheduleSlotVm> slots) {
    final result = <_SlotsByDay>[];
    for (final slot in slots) {
      final day = eventDateOnly(slot.startAt, slot.timezone);
      if (result.isEmpty || result.last.day != day) {
        result.add(_SlotsByDay(day: day, slots: [slot]));
      } else {
        result.last.slots.add(slot);
      }
    }
    return result;
  }
}

class _BookingSlotChip extends StatelessWidget {
  const _BookingSlotChip({
    super.key,
    required this.slot,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ExcursionScheduleSlotVm slot;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeLabel = DateFormat.Hm(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(eventDateTime(slot.startAt, slot.timezone));
    final background = selected
        ? AppColors.accent
        : enabled
        ? _BookingColors.panel
        : _BookingColors.panel.withValues(alpha: 0.52);
    final foreground = selected
        ? AppColors.textPrimary
        : enabled
        ? _BookingColors.text
        : _BookingColors.muted.withValues(alpha: 0.58);

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label:
          '$timeLabel, ${l10n.excursionBookingSeatsLeft(slot.availableSeats)}',
      onTap: enabled ? onTap : null,
      child: ExcludeSemantics(
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeLabel,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.excursionBookingSeatsLeft(slot.availableSeats),
                    style: TextStyle(
                      color: foreground.withValues(
                        alpha: selected ? 0.86 : 0.68,
                      ),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1,
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

class _BookingScheduleStatePanel extends StatelessWidget {
  const _BookingScheduleStatePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: _bookingScheduleStatePanelMinHeight(context),
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _BookingColors.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _SlotsByDay {
  _SlotsByDay({required this.day, required this.slots});

  final DateTime day;
  final List<ExcursionScheduleSlotVm> slots;
}

int _effectiveTravelerLimit(
  int maxTravelers,
  ExcursionScheduleSlotVm? selectedSlot,
) {
  final slotLimit = selectedSlot?.availableSeats;
  if (slotLimit == null || slotLimit <= 0) {
    return maxTravelers;
  }
  return math.min(maxTravelers, slotLimit);
}

class _TravelersSection extends StatelessWidget {
  const _TravelersSection({
    required this.adults,
    required this.children,
    required this.maxTravelers,
    required this.onIncrementAdults,
    required this.onDecrementAdults,
    required this.onIncrementChildren,
    required this.onDecrementChildren,
  });

  final int adults;
  final int children;
  final int maxTravelers;
  final VoidCallback onIncrementAdults;
  final VoidCallback onDecrementAdults;
  final VoidCallback onIncrementChildren;
  final VoidCallback onDecrementChildren;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final travelerCount = adults + children;
    final canAddTraveler = travelerCount < maxTravelers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.excursionBookingTravelers, style: _sectionTitleStyle),
        const SizedBox(height: 22),
        _TravelerCounterRow(
          title: l10n.excursionBookingAdults,
          value: adults,
          canDecrement: adults > 1,
          canIncrement: canAddTraveler,
          onIncrement: onIncrementAdults,
          onDecrement: onDecrementAdults,
        ),
        const SizedBox(height: 12),
        _TravelerCounterRow(
          title: l10n.excursionBookingChildren,
          value: children,
          canDecrement: children > 0,
          canIncrement: canAddTraveler,
          onIncrement: onIncrementChildren,
          onDecrement: onDecrementChildren,
        ),
      ],
    );
  }
}

class _BookingSummarySection extends StatelessWidget {
  const _BookingSummarySection({
    required this.excursion,
    required this.adults,
    required this.children,
  });

  final ExcursionVm excursion;
  final int adults;
  final int children;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final price = excursion.priceAmount;
    final adultTotal = price * adults;
    final childrenTotal = price * children;
    final subtotal = adultTotal + childrenTotal;
    final fee = subtotal * _BookingMath.serviceFeeRate;
    final total = subtotal + fee;
    final priceLabel = _formatBookingMoney(context, price, excursion.currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.excursionBookingSummary, style: _sectionTitleStyle),
        const SizedBox(height: 24),
        _SummaryRow(
          label: l10n.excursionBookingAdultSummary(adults, priceLabel),
          value: _formatBookingMoney(context, adultTotal, excursion.currency),
        ),
        if (children > 0) ...[
          const SizedBox(height: 22),
          _SummaryRow(
            label: l10n.excursionBookingChildrenSummary(children, priceLabel),
            value: _formatBookingMoney(
              context,
              childrenTotal,
              excursion.currency,
            ),
          ),
        ],
        const SizedBox(height: 22),
        _SummaryRow(
          label: l10n.excursionBookingServiceFeeSummary,
          value: _formatBookingMoney(context, fee, excursion.currency),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 26),
          child: Divider(height: 1, color: Color(0x33F98C06)),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.excursionBookingTotalPrice,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _BookingColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                _formatBookingMoney(context, total, excursion.currency),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BookingFooter extends StatelessWidget {
  const _BookingFooter({
    required this.excursion,
    required this.adults,
    required this.children,
    required this.isSubmitting,
    required this.canConfirm,
    required this.existingBooking,
    required this.onConfirm,
    required this.onOpenMyExcursions,
  });

  final ExcursionVm excursion;
  final int adults;
  final int children;
  final bool isSubmitting;
  final bool canConfirm;
  final ExcursionBookingVm? existingBooking;
  final VoidCallback onConfirm;
  final VoidCallback onOpenMyExcursions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final total = _BookingMath.total(
      pricePerTraveler: excursion.priceAmount,
      adults: adults,
      children: children,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF130C06).withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, math.max(18, safeBottom)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: _bookingFooterButtonMinHeight(context),
                  minWidth: double.infinity,
                ),
                child: FilledButton.icon(
                  onPressed: existingBooking != null
                      ? onOpenMyExcursions
                      : isSubmitting || !canConfirm
                      ? null
                      : onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.accent.withValues(
                      alpha: 0.45,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  icon: existingBooking == null
                      ? const SizedBox.shrink()
                      : const Icon(Icons.confirmation_number_rounded, size: 19),
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isSubmitting
                        ? const SizedBox(
                            key: ValueKey('booking-progress'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            (existingBooking != null
                                    ? l10n.excursionBookingOpenMyExcursions
                                    : l10n.excursionBookingConfirmReservation)
                                .toUpperCase(),
                            key: const ValueKey('booking-confirm'),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                existingBooking != null
                    ? l10n.excursionBookingAlreadyBookedMessage
                    : l10n.excursionBookingPaymentPendingNote(
                        _formatBookingMoney(context, total, excursion.currency),
                      ),
                textAlign: TextAlign.center,
                maxLines: 3,
                style: const TextStyle(
                  color: Color(0x99D6C1B3),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _sectionTitleStyle,
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _BookingScheduleCard extends StatelessWidget {
  const _BookingScheduleCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.active = false,
    this.highlightValue = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool active;
  final bool highlightValue;

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = _bookingScheduleIconBoxSize(context);

    return Material(
      color: _BookingColors.panel,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.accent.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: active ? AppColors.accent : const Color(0xFFD6C1B3),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _BookingColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: highlightValue
                            ? AppColors.accent
                            : _BookingColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TravelerCounterRow extends StatelessWidget {
  const _TravelerCounterRow({
    required this.title,
    required this.value,
    required this.canIncrement,
    required this.canDecrement,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String title;
  final int value;
  final bool canIncrement;
  final bool canDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final valueWidth = _bookingCounterValueWidth(context);
    return Container(
      constraints: BoxConstraints(
        minHeight: _bookingCounterRowMinHeight(context),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: _BookingColors.panel,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _BookingColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _CounterButton(
            icon: Icons.remove_rounded,
            enabled: canDecrement,
            onTap: onDecrement,
          ),
          SizedBox(
            width: valueWidth,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _BookingColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          _CounterButton(
            icon: Icons.add_rounded,
            enabled: canIncrement,
            emphasized: true,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final bool enabled;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final filled = emphasized && enabled;
    final buttonSize = _bookingCounterButtonSize(context);
    return InkResponse(
      onTap: enabled ? onTap : null,
      radius: 26,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: emphasized
                ? AppColors.accent.withValues(alpha: enabled ? 1 : 0.32)
                : const Color(0xFFD6C1B3).withValues(alpha: 0.23),
            width: 1.4,
          ),
        ),
        child: Icon(
          icon,
          color: filled
              ? Colors.white
              : emphasized
              ? AppColors.accent.withValues(alpha: enabled ? 1 : 0.34)
              : const Color(0xFFD6C1B3).withValues(alpha: enabled ? 1 : 0.35),
          size: 20,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _BookingColors.muted,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _BookingColors.muted,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _SoftErrorBanner extends StatelessWidget {
  const _SoftErrorBanner({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF4A2B13).withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _BookingColors.text,
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlreadyBookedNotice extends StatelessWidget {
  const _AlreadyBookedNotice({
    required this.booking,
    required this.onOpenMyExcursions,
  });

  final ExcursionBookingVm booking;
  final VoidCallback onOpenMyExcursions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = formatEventDateTime(
      booking.scheduledFor,
      timezoneId: booking.timezone,
      localeName: localeName,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.26)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.confirmation_number_rounded,
              color: AppColors.accent,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.excursionBookingAlreadyBookedTitle,
                    style: const TextStyle(
                      color: _BookingColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$dateLabel · ${l10n.myExcursionsGuests(booking.totalSeats)}',
                    style: const TextStyle(
                      color: _BookingColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onOpenMyExcursions,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(l10n.excursionBookingOpenMyExcursions),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingImageFallback extends StatelessWidget {
  const _BookingImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5A3517), Color(0xFF1B1008)],
        ),
      ),
      child: Center(
        child: Icon(Icons.terrain_rounded, color: AppColors.accent, size: 34),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: _BookingColors.text, size: 18),
        ),
      ),
    );
  }
}

class _BookingLoadingScaffold extends StatelessWidget {
  const _BookingLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _BookingColors.base,
      body: DecoratedBox(
        decoration: _BookingColors.backgroundDecoration,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      ),
    );
  }
}

abstract final class _BookingMath {
  static const serviceFeeRate = 0.05;

  static double total({
    required double pricePerTraveler,
    required int adults,
    required int children,
  }) {
    final subtotal = pricePerTraveler * (adults + children);
    return subtotal + subtotal * serviceFeeRate;
  }
}

abstract final class _BookingColors {
  static const base = Color(0xFF160D05);
  static const panel = Color(0xFF27170B);
  static const text = Color(0xFFF4E7D8);
  static const muted = Color(0xFFD6C1B3);

  static const backgroundDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF24150A), Color(0xFF160D05), Color(0xFF130C06)],
    ),
  );
}

const _sectionTitleStyle = TextStyle(
  color: _BookingColors.text,
  fontSize: 24,
  fontWeight: FontWeight.w900,
  height: 1,
);

double _bookingHeightDensity(BuildContext context) {
  final height = MediaQuery.sizeOf(context).height;
  return (height / 844).clamp(0.72, 1.0).toDouble();
}

double _bookingSectionGap(
  BuildContext context, {
  required double compact,
  required double regular,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final base = width < 360 ? compact : regular;
  return base * _bookingHeightDensity(context);
}

double _bookingInlineGap(BuildContext context, {required double regular}) {
  final width = MediaQuery.sizeOf(context).width;
  final density = (width / 390).clamp(0.74, 1.0).toDouble();
  return regular * density;
}

double _bookingTopBarMinHeight(BuildContext context) {
  final scaledTitleHeight = MediaQuery.textScalerOf(context).scale(18);
  return (scaledTitleHeight + 44).clamp(56.0, 72.0).toDouble();
}

double _bookingCoverImageSize(BuildContext context, double availableWidth) {
  final width = MediaQuery.sizeOf(context).width;
  final compactLimit = width < 360 ? 84.0 : 96.0;
  return (availableWidth * 0.27).clamp(74.0, compactLimit).toDouble();
}

double _bookingScheduleIconBoxSize(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.12).clamp(44.0, 50.0).toDouble();
}

double _bookingFooterButtonMinHeight(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final textScale = MediaQuery.textScalerOf(context).scale(1);
  return (width * 0.145 + 8 * textScale).clamp(54.0, 66.0).toDouble();
}

double _bookingScheduleStatePanelMinHeight(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.22).clamp(78.0, 94.0).toDouble();
}

double _bookingCounterRowMinHeight(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.18).clamp(64.0, 78.0).toDouble();
}

double _bookingCounterValueWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.12).clamp(42.0, 54.0).toDouble();
}

double _bookingCounterButtonSize(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.095).clamp(34.0, 42.0).toDouble();
}

String _formatBookingMoney(
  BuildContext context,
  double amount,
  String currency,
) {
  final l10n = AppLocalizations.of(context)!;
  if (amount <= 0) return l10n.excursionsFreePrice;

  final decimalDigits = amount == amount.truncateToDouble() ? 0 : 2;
  try {
    return NumberFormat.simpleCurrency(
      name: currency,
      decimalDigits: decimalDigits,
    ).format(amount);
  } catch (_) {
    return '${amount.toStringAsFixed(decimalDigits)} $currency';
  }
}
