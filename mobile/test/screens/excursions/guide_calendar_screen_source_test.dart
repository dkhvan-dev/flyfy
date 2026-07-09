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
    expect(router, contains("path: '/guides/:guideUserId/calendar'"));
    expect(router, contains('GuideCalendarScreen('));
    expect(router, contains('guideUserId: guideUserId'));
    expect(router, contains('readOnly: true'));
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
    expect(source, contains('backgroundColor: colors.primary'));
    expect(source, contains('foregroundColor: colors.textPrimary'));
    expect(source, contains('const GuideCalendarScreen({'));
    expect(source, contains('this.guideUserId'));
    expect(source, contains('this.readOnly = false'));
    expect(source, contains('final String? guideUserId;'));
    expect(source, contains('final bool readOnly;'));
    expect(source, contains('guideUserId: widget.guideUserId'));
    expect(source, contains('if (!widget.readOnly)'));
    expect(source, contains('onSlotTap: widget.readOnly'));
    expect(source, contains('_openSlotSheet(selectedDate, slot)'));
    expect(source, isNot(contains('height: 700')));
  });

  test(
    'guide calendar header adapts compact widths without overflow',
    () async {
      final source = await File(
        'lib/screens/excursions/guide_calendar_screen.dart',
      ).readAsString();

      final headerStart = source.indexOf('class _GuideCalendarHeader');
      expect(headerStart, isNonNegative);

      final headerSource = source.substring(headerStart);
      expect(source, contains('_GuideCalendarHeader('));
      expect(headerSource, contains('LayoutBuilder('));
      expect(
        headerSource,
        contains('MediaQuery.textScalerOf(context).scale(1)'),
      );
      expect(headerSource, contains('Wrap('));
      expect(headerSource, contains('FittedBox('));
      expect(headerSource, contains('foregroundColor: colors.textPrimary'));
    },
  );

  test('guide calendar screen uses V2 colors only', () async {
    final source = await File(
      'lib/screens/excursions/guide_calendar_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.screenGradientColors'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'guide calendar empty availability metadata uses secondary accents',
    () async {
      final source = await File(
        'lib/screens/excursions/widgets/guide_calendar_timeline.dart',
      ).readAsString();
      final emptyStart = source.indexOf('if (slots.isEmpty)');
      final listStart = source.indexOf(
        'return SliverList.separated',
        emptyStart,
      );

      expect(emptyStart, isNonNegative);
      expect(listStart, greaterThan(emptyStart));

      final emptySource = source.substring(emptyStart, listStart);
      expect(emptySource, contains('colors.secondaryContainer'));
      expect(emptySource, contains('colors.borderSecondary'));
      expect(emptySource, contains('color: colors.secondary'));
    },
  );

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
      expect(source, contains('_GuideCancelSlotReasonSheet'));
      expect(source, contains('guideDashboardCancelReasonRequired'));
      expect(source, isNot(contains("'cancelled by guide'")));
      expect(source, contains('Wrap('));
      expect(source, contains('ExcursionProvider'));
      expect(source, contains('DropdownButtonFormField'));
      expect(source, contains('_dateController'));
      expect(source, contains('_timeController'));
      expect(source, contains('_DateInputFormatter'));
      expect(source, contains('_TimeInputFormatter'));
      expect(source, contains('_chipTheme'));
      expect(source, contains('AppDesignSystem.colorsFor(context)'));
      expect(source, contains('iconEnabledColor: colors.primary'));
      expect(source, contains('Icon(icon, color: colors.primary'));
      expect(
        source,
        contains('_repeatWeekly && _weekdays.contains(day.value)'),
      );
      expect(source, contains('colors.surfaceRaised'));
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

    expect(
      RegExp(
        r'selected\s*\?\s*colors\.textPrimary\s*:\s*colors\.textMuted',
      ).hasMatch(source),
      isTrue,
    );
    expect(source, isNot(contains('selected ? AppPalette.warmInk64')));
  });

  test('guide calendar day tabs use rounded segmented radius', () async {
    final source = await File(
      'lib/screens/excursions/widgets/guide_calendar_day_strip.dart',
    ).readAsString();

    expect(source, contains('const double _guideCalendarDayCellRadius = 18;'));
    expect(
      RegExp(
        r'BorderRadius\.circular\(\s*_guideCalendarDayCellRadius\s*,?\s*\)',
      ).allMatches(source).length,
      greaterThanOrEqualTo(2),
    );
    expect(source, isNot(contains('AppBorderRadius.circular(8)')));
  });
}
