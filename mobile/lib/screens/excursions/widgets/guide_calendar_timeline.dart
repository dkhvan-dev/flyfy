import 'package:flutter/material.dart';

import '../../../core/ui/app_colors.dart';
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
    if (isLoading && slots.isEmpty) {
      return SliverList.separated(
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _TimelineSkeleton(),
        ),
      );
    }

    if (slots.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2118),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.guideCalendarEmptyDay,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
    return Container(
      height: 94,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2118).withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
