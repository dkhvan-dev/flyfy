import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
    final colors = AppDesignSystem.colorsFor(context);

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: Scaffold(
        backgroundColor: colors.background,
        body: DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors.screenGradientColors,
            ),
          ),
          child: SafeArea(
            child: Consumer<ExcursionScheduleProvider>(
              builder: (context, provider, _) {
                final selectedDate = provider.selectedDate ?? DateTime.now();
                final selectedSlots = provider.slotsForDay(selectedDate);
                return RefreshIndicator(
                  color: colors.primary,
                  backgroundColor: colors.surface,
                  onRefresh: () => provider.loadWeek(
                    selectedDate,
                    guideUserId: widget.guideUserId,
                  ),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const AppEdgeInsets.fromLTRB(20, 12, 20, 16),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).backButtonTooltip,
                                onPressed: () => context.pop(),
                                icon: const Icon(Icons.arrow_back_rounded),
                                color: colors.textPrimary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.guideCalendarTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: colors.textPrimary,
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
                                    backgroundColor: colors.primary,
                                    foregroundColor: colors.textPrimary,
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
                        isLoading:
                            provider.state == ExcursionScheduleState.loading,
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
        ),
      ),
    );
  }

  Future<void> _openSlotSheet(
    DateTime selectedDate, [
    ExcursionScheduleSlotVm? slot,
  ]) async {
    final colors = AppDesignSystem.colorsFor(context);

    await showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: colors.transparent,
      builder: (_) =>
          GuideScheduleSlotSheet(slot: slot, initialDate: selectedDate),
    );
  }
}
