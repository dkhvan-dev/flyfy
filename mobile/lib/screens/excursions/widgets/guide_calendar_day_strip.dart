import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/time/app_time.dart';
import '../../../core/ui/app_colors.dart';
import '../../../features/excursions/models/excursion_schedule_vm.dart';
import 'guide_schedule_slot_card.dart';

const double _guideCalendarDayCellRadius = 18;

class GuideCalendarDayStrip extends StatelessWidget {
  const GuideCalendarDayStrip({
    super.key,
    required this.selectedDate,
    required this.slots,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final List<ExcursionScheduleSlotVm> slots;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final weekStart = _mondayStart(selectedDate);
    final days = List<DateTime>.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    final locale = Localizations.localeOf(context).toLanguageTag();

    return SizedBox(
      height: _guideCalendarDayStripHeight(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final day = days[index];
          final selected = _isSameDay(day, selectedDate);
          final daySlots = _slotsForDay(day);
          final indicatorColor = daySlots.any((slot) => slot.isBooked)
              ? AppColors.accent
              : daySlots.isEmpty
              ? Colors.transparent
              : guideScheduleStatusColor(daySlots.first);
          return Semantics(
            button: true,
            selected: selected,
            label: DateFormat.yMMMMEEEEd(locale).format(day),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: _guideCalendarDayCellMinWidth(context),
              ),
              child: Material(
                color: selected ? AppColors.accent : const Color(0xFF2A2118),
                borderRadius: BorderRadius.circular(
                  _guideCalendarDayCellRadius,
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    _guideCalendarDayCellRadius,
                  ),
                  onTap: () => onDateSelected(day),
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat.E(locale).format(day),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: _guideCalendarWeekdayFontSize(context),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat.d(locale).format(day),
                            style: TextStyle(
                              color: selected
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimary,
                              fontSize: _guideCalendarDayFontSize(context),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            width: _guideCalendarIndicatorSize(context),
                            height: _guideCalendarIndicatorSize(context),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.textPrimary
                                  : indicatorColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: days.length,
      ),
    );
  }

  List<ExcursionScheduleSlotVm> _slotsForDay(DateTime day) {
    return slots
        .where((slot) {
          return isSameEventDate(slot.startAt, day, slot.timezone);
        })
        .toList(growable: false);
  }

  DateTime _mondayStart(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

double _guideCalendarDayStripHeight(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  return (MediaQuery.sizeOf(context).height * 0.095 + 12 * scale)
      .clamp(82.0, 104.0)
      .toDouble();
}

double _guideCalendarDayCellMinWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.16).clamp(56.0, 72.0).toDouble();
}

double _guideCalendarWeekdayFontSize(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.031).clamp(11.0, 13.0).toDouble();
}

double _guideCalendarDayFontSize(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.057).clamp(20.0, 24.0).toDouble();
}

double _guideCalendarIndicatorSize(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.021).clamp(7.0, 9.0).toDouble();
}
