import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../core/time/app_time.dart';
import '../../../features/excursions/models/excursion_schedule_vm.dart';
import '../../../l10n/generated/app_localizations.dart';

Color guideScheduleStatusColor(
  BuildContext context,
  ExcursionScheduleSlotVm slot,
) {
  final colors = AppDesignSystem.colorsFor(context);
  switch (slot.status) {
    case ExcursionScheduleSlotStatus.available:
      return colors.secondary;
    case ExcursionScheduleSlotStatus.booked:
    case ExcursionScheduleSlotStatus.full:
      return colors.primary;
    case ExcursionScheduleSlotStatus.closed:
      return colors.textMuted;
    case ExcursionScheduleSlotStatus.cancelled:
      return colors.textDisabled;
    case ExcursionScheduleSlotStatus.completed:
      return colors.success;
  }
}

class GuideScheduleSlotCard extends StatelessWidget {
  const GuideScheduleSlotCard({super.key, required this.slot, this.onTap});

  final ExcursionScheduleSlotVm slot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final timeLabel = formatEventTimeRange(
      start: slot.startAt,
      end: slot.endAt,
      timezoneId: slot.timezone,
      localeName: locale,
    );
    final colors = AppDesignSystem.colorsFor(context);
    final color = guideScheduleStatusColor(context, slot);
    final title = slot.title.trim().isEmpty
        ? l10n.serviceExcursions
        : slot.title.trim();
    final cancelReason = _cancelReasonLabel(l10n, slot);
    final semanticLabel = [
      timeLabel,
      _statusLabel(l10n, slot.status),
      title,
      '${slot.bookedSeats}/${slot.capacity}',
      if (cancelReason != null) l10n.guideCalendarCancelReason(cancelReason),
    ].join(', ');

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: colors.surface,
          borderRadius: AppBorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: AppBorderRadius.circular(8),
            child: Padding(
              padding: const AppEdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 64,
                    decoration: AppBoxDecoration(
                      color: color,
                      borderRadius: AppBorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              timeLabel,
                              style: AppTextStyle(
                                color: colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            _StatusPill(
                              label: _statusLabel(l10n, slot.status),
                              color: color,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            color: colors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${slot.bookedSeats}/${slot.capacity}',
                          style: AppTextStyle(
                            color: colors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (cancelReason != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.guideCalendarCancelReason(cancelReason),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _cancelReasonLabel(
  AppLocalizations l10n,
  ExcursionScheduleSlotVm slot,
) {
  if (slot.status != ExcursionScheduleSlotStatus.cancelled) {
    return null;
  }
  final reason = slot.cancelReason?.trim();
  if (reason == null || reason.isEmpty) {
    return null;
  }
  if (reason == 'NO_BOOKINGS_BEFORE_START_2H') {
    return l10n.guideCalendarAutoCancelNoBookings;
  }
  return reason;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const AppEdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: AppBoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _statusLabel(AppLocalizations l10n, ExcursionScheduleSlotStatus status) {
  switch (status) {
    case ExcursionScheduleSlotStatus.available:
      return l10n.guideCalendarAvailable;
    case ExcursionScheduleSlotStatus.booked:
    case ExcursionScheduleSlotStatus.full:
      return l10n.guideCalendarBooked;
    case ExcursionScheduleSlotStatus.closed:
      return l10n.guideCalendarClosed;
    case ExcursionScheduleSlotStatus.cancelled:
      return l10n.guideCalendarCancelled;
    case ExcursionScheduleSlotStatus.completed:
      return l10n.guideCalendarCompleted;
  }
}
