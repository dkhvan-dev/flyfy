import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/error_view.dart';
import '../../features/excursions/models/create_excursion_booking_request.dart';
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
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  ExcursionVm? _excursion;
  String? _loadError;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _adults = 1;
  int _children = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 2));
    _selectedTime = const TimeOfDay(hour: 10, minute: 0);
    _excursion = _applySelectedOffer(widget.initialExcursion);
    _isLoading = widget.initialExcursion == null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final cachedExcursion = provider.selectedExcursion;
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

    await provider.loadExcursionDetails(trimmedExcursionId,
        initialExcursion: _excursion);

    if (!mounted) return;
    final loadedExcursion = provider.selectedExcursion;
    final loadedMatchingExcursion =
        loadedExcursion != null && loadedExcursion.id == trimmedExcursionId
            ? loadedExcursion
            : null;
    final nextExcursion =
        _applySelectedOffer(loadedMatchingExcursion ?? _excursion);

    setState(() {
      _excursion = nextExcursion;
      _isLoading = false;
      _loadError = nextExcursion == null ? provider.detailErrorMessage : null;
      final maxTravelers = _maxTravelersFor(nextExcursion);
      if (_adults + _children > maxTravelers) {
        _children = math.max(0, maxTravelers - _adults);
      }
    });
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/excursions/${Uri.encodeComponent(widget.excursionId)}');
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final initialDate = _selectedDate.isBefore(now) ? now : _selectedDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: _BookingColors.panel,
              onSurface: _BookingColors.text,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: _BookingColors.panel,
              onSurface: _BookingColors.text,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!mounted) return;
    setState(() {
      _selectedDate = pickedDate;
      if (pickedTime != null) {
        _selectedTime = pickedTime;
      }
    });
  }

  void _incrementAdults() {
    if (_adults + _children >= _maxTravelers) return;
    setState(() => _adults++);
  }

  void _decrementAdults() {
    if (_adults <= 1) return;
    setState(() => _adults--);
  }

  void _incrementChildren() {
    if (_adults + _children >= _maxTravelers) return;
    setState(() => _children++);
  }

  void _decrementChildren() {
    if (_children <= 0) return;
    setState(() => _children--);
  }

  Future<void> _confirmBooking() async {
    if (_isSubmitting) return;
    final productId = widget.excursionId.trim();
    final offerId = _selectedOfferId;
    if (productId.isEmpty || offerId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.excursionBookingLoadFailed),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF3A2B1D),
          ),
        );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    final scheduledFor = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final success =
        await context.read<ExcursionProvider>().createExcursionBooking(
              CreateExcursionBookingRequest(
                productId: productId,
                offerId: offerId,
                scheduledFor: scheduledFor,
                adults: _adults,
                children: _children,
                idempotencyKey:
                    '$productId:$offerId:${scheduledFor.toUtc().toIso8601String()}:$_adults:$_children',
              ),
            );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (!success) {
      final provider = context.read<ExcursionProvider>();
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.excursionBookingSubmitted),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF3A2B1D),
        ),
      );
  }

  int get _maxTravelers => _maxTravelersFor(_excursion);

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

    return Scaffold(
      backgroundColor: _BookingColors.base,
      body: ExcursionBookingContent(
        excursion: excursion,
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        adults: _adults,
        children: _children,
        maxTravelers: _maxTravelers,
        isSubmitting: _isSubmitting,
        loadError: _loadError,
        onBackTap: _goBack,
        onChangeSchedule: _pickSchedule,
        onIncrementAdults: _incrementAdults,
        onDecrementAdults: _decrementAdults,
        onIncrementChildren: _incrementChildren,
        onDecrementChildren: _decrementChildren,
        onConfirm: _confirmBooking,
        onRetry: () => _ensureExcursionLoaded(),
      ),
    );
  }
}

class ExcursionBookingContent extends StatelessWidget {
  const ExcursionBookingContent({
    super.key,
    required this.excursion,
    required this.selectedDate,
    required this.selectedTime,
    required this.adults,
    required this.children,
    required this.maxTravelers,
    required this.isSubmitting,
    required this.onBackTap,
    required this.onChangeSchedule,
    required this.onIncrementAdults,
    required this.onDecrementAdults,
    required this.onIncrementChildren,
    required this.onDecrementChildren,
    required this.onConfirm,
    this.onRetry,
    this.loadError,
  });

  final ExcursionVm excursion;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final int adults;
  final int children;
  final int maxTravelers;
  final bool isSubmitting;
  final VoidCallback onBackTap;
  final VoidCallback onChangeSchedule;
  final VoidCallback onIncrementAdults;
  final VoidCallback onDecrementAdults;
  final VoidCallback onIncrementChildren;
  final VoidCallback onDecrementChildren;
  final VoidCallback onConfirm;
  final VoidCallback? onRetry;
  final String? loadError;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final horizontalPadding = compact ? 20.0 : 24.0;

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
                            const SizedBox(height: 42),
                            _BookingScheduleSection(
                              selectedDate: selectedDate,
                              selectedTime: selectedTime,
                              onChangeSchedule: onChangeSchedule,
                            ),
                            const SizedBox(height: 38),
                            _TravelersSection(
                              adults: adults,
                              children: children,
                              maxTravelers: maxTravelers,
                              onIncrementAdults: onIncrementAdults,
                              onDecrementAdults: onDecrementAdults,
                              onIncrementChildren: onIncrementChildren,
                              onDecrementChildren: onDecrementChildren,
                            ),
                            const SizedBox(height: 52),
                            _BookingSummarySection(
                              excursion: excursion,
                              adults: adults,
                              children: children,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _BookingFooter(
                      excursion: excursion,
                      adults: adults,
                      children: children,
                      isSubmitting: isSubmitting,
                      onConfirm: onConfirm,
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
    return SizedBox(
      height: 62,
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
    final price =
        _formatBookingMoney(context, excursion.priceAmount, excursion.currency);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            width: 96,
            height: 96,
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
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizedExcursionCategoryLabel(l10n, excursion.categorySlug),
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
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: price,
                      style: const TextStyle(
                        color: _BookingColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(text: ' ${l10n.excursionBookingPerPerson}'),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _BookingColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingScheduleSection extends StatelessWidget {
  const _BookingScheduleSection({
    required this.selectedDate,
    required this.selectedTime,
    required this.onChangeSchedule,
  });

  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final VoidCallback onChangeSchedule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat.yMMMd(locale).format(selectedDate);
    final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(
      selectedTime,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHead(
          title: l10n.excursionBookingSchedule,
          actionLabel: l10n.excursionBookingChange,
          onActionTap: onChangeSchedule,
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 342;
            final cards = [
              _BookingScheduleCard(
                icon: Icons.calendar_month_rounded,
                label: l10n.excursionBookingDate,
                value: dateLabel,
                onTap: onChangeSchedule,
              ),
              _BookingScheduleCard(
                icon: Icons.schedule_rounded,
                label: l10n.excursionBookingTimeSlot,
                value: timeLabel,
                active: true,
                onTap: onChangeSchedule,
              ),
            ];

            if (isNarrow) {
              return Column(
                children: [cards.first, const SizedBox(height: 12), cards.last],
              );
            }

            return Row(
              children: [
                Expanded(child: cards.first),
                const SizedBox(width: 14),
                Expanded(child: cards.last),
              ],
            );
          },
        ),
      ],
    );
  }
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
            value:
                _formatBookingMoney(context, childrenTotal, excursion.currency),
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
    required this.onConfirm,
  });

  final ExcursionVm excursion;
  final int adults;
  final int children;
  final bool isSubmitting;
  final VoidCallback onConfirm;

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
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: isSubmitting ? null : onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.accent.withValues(
                      alpha: 0.45,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: AnimatedSwitcher(
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
                            l10n.excursionBookingConfirmPay.toUpperCase(),
                            key: const ValueKey('booking-confirm'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                '${l10n.excursionBookingSecurePayment} · '
                '${_formatBookingMoney(context, total, excursion.currency)}',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
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
                width: 42,
                height: 42,
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
                        color: active ? AppColors.accent : _BookingColors.text,
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
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
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
            width: 48,
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
    return InkResponse(
      onTap: enabled ? onTap : null,
      radius: 26,
      child: Container(
        width: 36,
        height: 36,
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
                  : const Color(0xFFD6C1B3)
                      .withValues(alpha: enabled ? 1 : 0.35),
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
