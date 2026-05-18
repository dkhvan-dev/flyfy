import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/ui/app_colors.dart';
import '../../../features/excursions/models/excursion_schedule_vm.dart';
import 'guide_schedule_slot_card.dart';

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
      height: 92,
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
          return ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 62),
            child: Material(
              color: selected ? AppColors.accent : const Color(0xFF2A2118),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onDateSelected(day),
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
                          fontSize: 12,
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
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              selected ? AppColors.textPrimary : indicatorColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: days.length,
      ),
    );
  }

  List<ExcursionScheduleSlotVm> _slotsForDay(DateTime day) {
    return slots.where((slot) {
      final local = slot.startAt.toLocal();
      return _isSameDay(local, day);
    }).toList(growable: false);
  }

  DateTime _mondayStart(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
