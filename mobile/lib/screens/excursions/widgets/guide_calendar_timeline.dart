import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../features/excursions/models/excursion_schedule_vm.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'guide_schedule_slot_card.dart';

class GuideCalendarTimeline extends StatelessWidget {
  const GuideCalendarTimeline({
    super.key,
    required this.slots,
    required this.isLoading,
    this.onSlotTap,
  });

  final List<ExcursionScheduleSlotVm> slots;
  final bool isLoading;
  final ValueChanged<ExcursionScheduleSlotVm>? onSlotTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    if (isLoading && slots.isEmpty) {
      return SliverList.separated(
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => const Padding(
          padding: AppEdgeInsets.symmetric(horizontal: 20),
          child: _TimelineSkeleton(),
        ),
      );
    }

    if (slots.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const AppEdgeInsets.fromLTRB(20, 28, 20, 0),
          child: Container(
            padding: const AppEdgeInsets.all(18),
            decoration: AppBoxDecoration(
              color: colors.surface,
              borderRadius: AppBorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.event_available_rounded, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.guideCalendarEmptyDay,
                    style: AppTextStyle(
                      color: colors.textPrimary,
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

    return SliverList.separated(
      itemCount: slots.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final slot = slots[index];
        return Padding(
          padding: const AppEdgeInsets.symmetric(horizontal: 20),
          child: GuideScheduleSlotCard(
            slot: slot,
            onTap: onSlotTap == null ? null : () => onSlotTap!(slot),
          ),
        );
      },
    );
  }
}

class _TimelineSkeleton extends StatelessWidget {
  const _TimelineSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: _guideTimelineSkeletonMinHeight(context),
      ),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: colors.surface.withValues(alpha: 0.68),
          borderRadius: AppBorderRadius.circular(8),
        ),
      ),
    );
  }
}

double _guideTimelineSkeletonMinHeight(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.24).clamp(86.0, 112.0).toDouble();
}
