import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_colors.dart';
import '../../features/excursions/models/excursion_schedule_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/excursion_provider.dart';
import '../../providers/excursion_schedule_provider.dart';
import 'widgets/guide_calendar_day_strip.dart';
import 'widgets/guide_calendar_timeline.dart';
import 'widgets/guide_schedule_slot_sheet.dart';

class GuideCalendarScreen extends StatefulWidget {
  const GuideCalendarScreen({
    super.key,
    this.guideUserId,
    this.readOnly = false,
  });

  final String? guideUserId;
  final bool readOnly;

  @override
  State<GuideCalendarScreen> createState() => _GuideCalendarScreenState();
}

class _GuideCalendarScreenState extends State<GuideCalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.readOnly) {
        context.read<ExcursionProvider>().loadGuideDashboardData();
      }
      context.read<ExcursionScheduleProvider>().loadWeek(
            DateTime.now(),
            guideUserId: widget.guideUserId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<ExcursionScheduleProvider>(
          builder: (context, provider, _) {
            final selectedDate = provider.selectedDate ?? DateTime.now();
            final selectedSlots = provider.slotsForDay(selectedDate);
            return RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: const Color(0xFF2A2118),
              onRefresh: () => provider.loadWeek(
                selectedDate,
                guideUserId: widget.guideUserId,
              ),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.guideCalendarTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (!widget.readOnly)
                            FilledButton.icon(
                              onPressed: () => _openSlotSheet(selectedDate),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(l10n.guideCalendarAddSlot),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.textPrimary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: GuideCalendarDayStrip(
                      selectedDate: selectedDate,
                      slots: provider.slots,
                      onDateSelected: (day) {
                        if (provider.isDateInLoadedWeek(
                          day,
                          guideUserId: widget.guideUserId,
                        )) {
                          provider.selectDate(day);
                        } else {
                          provider.loadWeek(
                            day,
                            guideUserId: widget.guideUserId,
                          );
                        }
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  GuideCalendarTimeline(
                    slots: selectedSlots,
                    isLoading: provider.state == ExcursionScheduleState.loading,
                    onSlotTap: widget.readOnly
                        ? null
                        : (slot) => _openSlotSheet(selectedDate, slot),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openSlotSheet(
    DateTime selectedDate, [
    ExcursionScheduleSlotVm? slot,
  ]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GuideScheduleSlotSheet(
        slot: slot,
        initialDate: selectedDate,
      ),
    );
  }
}
