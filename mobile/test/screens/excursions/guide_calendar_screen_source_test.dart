import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guide calendar route and dashboard entry exist', () async {
    final router = await File('lib/core/router/app_router.dart').readAsString();
    final dashboard = await File(
      'lib/screens/excursions/guide_dashboard_screen.dart',
    ).readAsString();

    expect(router, contains("path: '/profile/guide-dashboard/calendar'"));
    expect(router, contains('GuideCalendarScreen'));
    expect(
      dashboard,
      contains("context.push('/profile/guide-dashboard/calendar')"),
    );
    expect(dashboard, contains('guideCalendarTitle'));
  });

  test('guide calendar screen uses adaptive week timeline structure', () async {
    final source = await File(
      'lib/screens/excursions/guide_calendar_screen.dart',
    ).readAsString();

    expect(source, contains('class GuideCalendarScreen'));
    expect(source, contains('GuideCalendarDayStrip'));
    expect(source, contains('GuideCalendarTimeline'));
    expect(source, contains('SafeArea'));
    expect(source, contains('RefreshIndicator'));
    expect(source, contains('CustomScrollView'));
    expect(source, contains('backgroundColor: AppColors.accent'));
    expect(source, contains('foregroundColor: AppColors.textPrimary'));
    expect(source, isNot(contains('height: 700')));
  });

  test(
    'guide schedule slot sheet supports recurrence and conflict actions',
    () async {
      final source = await File(
        'lib/screens/excursions/widgets/guide_schedule_slot_sheet.dart',
      ).readAsString();

      expect(source, contains('class GuideScheduleSlotSheet'));
      expect(source, contains('guideCalendarRepeatWeekly'));
      expect(source, contains('guideCalendarConflictTitle'));
      expect(source, contains('guideCalendarSuggestNextTime'));
      expect(source, contains('guideCalendarDeleteSlot'));
      expect(source, contains('guideCalendarCancelSlot'));
      expect(source, contains('Wrap('));
      expect(source, contains('ExcursionProvider'));
      expect(source, contains('DropdownButtonFormField'));
      expect(source, contains('_dateController'));
      expect(source, contains('_timeController'));
      expect(source, contains('_DateInputFormatter'));
      expect(source, contains('_TimeInputFormatter'));
      expect(source, contains('_chipTheme'));
      expect(source, contains('_slotSheetFieldIconColor'));
      expect(source, contains('iconEnabledColor: _slotSheetFieldIconColor'));
      expect(source, contains('Icon(icon, color: _slotSheetFieldIconColor'));
      expect(
          source, contains('_repeatWeekly && _weekdays.contains(day.value)'));
      expect(source, contains('const Color(0xFF3A2107)'));
      expect(source, contains('_fallbackOptionFromExcursion'));
      expect(source, contains('menuMaxHeight:'));
      expect(source, contains('guideCalendarOfferRequired'));
      expect(source, contains('guideCalendarCapacityTooHigh'));
      expect(source, contains('guideCalendarSlotLeadTimeTooSoon'));
      expect(source, contains('_slotSetupLeadTime'));
      expect(source, contains('provider.isActionConflict'));
      expect(source, contains('_selectedOfferOption'));
      expect(source, contains('_currentSlotOfferOptionIndex'));
      expect(source, contains('_isSameSlotOfferOption'));
      expect(source, contains('_formatSelectionOffset'));
      expect(source, contains('_slotOfferTitle'));
      expect(source, contains('slot.title.trim()'));
      expect(source, contains('_manualStartAt'));
      expect(source, contains('provider.updateSlot'));
      expect(source, contains('_closeSlotButtonStyle'));
      expect(source, contains('_cancelSlotButtonStyle'));
      expect(source, contains('_deleteSlotButtonStyle'));
      expect(source, isNot(contains('_showConflictBanner = !ok')));
      expect(source, isNot(contains('_offerController')));
      expect(source, isNot(contains('showDatePicker')));
      expect(source, isNot(contains('showTimePicker')));
      expect(
        source,
        isNot(contains('onChanged: isEditing || !hasOfferOptions')),
      );
      expect(source, isNot(contains('enabled: !isEditing')));
    },
  );

  test('guide calendar selected day keeps primary text color', () async {
    final source = await File(
      'lib/screens/excursions/widgets/guide_calendar_day_strip.dart',
    ).readAsString();

    expect(source, contains('selected ? AppColors.textPrimary'));
    expect(source, isNot(contains('selected ? const Color(0xFF201407)')));
  });
}
