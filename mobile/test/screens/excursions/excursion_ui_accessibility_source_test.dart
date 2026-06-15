import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('excursion tap surfaces expose explicit semantics', () async {
    final listSource = await File(
      'lib/screens/excursions/excursions_screen.dart',
    ).readAsString();
    final detailsSource = await File(
      'lib/screens/excursions/excursion_details_screen.dart',
    ).readAsString();
    final mySource = await File(
      'lib/screens/excursions/my_excursions_screen.dart',
    ).readAsString();
    final guideSource = await File(
      'lib/screens/excursions/guide_dashboard_screen.dart',
    ).readAsString();
    final bookingSource = await File(
      'lib/screens/excursions/excursion_booking_screen.dart',
    ).readAsString();
    final scheduleCardSource = await File(
      'lib/screens/excursions/widgets/guide_schedule_slot_card.dart',
    ).readAsString();

    expect(listSource, contains('Semantics('));
    expect(detailsSource, contains('Semantics('));
    expect(mySource, contains('Semantics('));
    expect(guideSource, contains('Semantics('));
    expect(bookingSource, contains('Semantics('));
    expect(scheduleCardSource, contains('Semantics('));
  });

  test('excursion actions keep production mobile tap targets', () async {
    for (final path in _excursionScreenPaths) {
      final source = await File(path).readAsString();

      expect(
        source,
        isNot(contains('tapTargetSize: MaterialTapTargetSize.shrinkWrap')),
        reason: '$path should not opt out of Material tap target padding.',
      );
      expect(
        source,
        isNot(contains('minimumSize: const Size(0, 40)')),
        reason: '$path has a sub-48dp action.',
      );
      expect(
        source,
        isNot(contains('minimumSize: const Size(0, 42)')),
        reason: '$path has a sub-48dp action.',
      );
    }
  });

  test('edit guests sheet is height constrained and scrollable', () async {
    final source = await File(
      'lib/screens/excursions/my_excursions_screen.dart',
    ).readAsString();
    final sheetStart = source.indexOf('class _EditExcursionGuestsSheet');
    final sheetEnd = source.indexOf('class _EditGuestsCounterRow');

    expect(sheetStart, isNonNegative);
    expect(sheetEnd, greaterThan(sheetStart));

    final sheetSource = source.substring(sheetStart, sheetEnd);
    expect(sheetSource, contains('ConstrainedBox('));
    expect(sheetSource, contains('SingleChildScrollView('));
  });

  test('excursion filter button exposes a semantic label', () async {
    final source = await File(
      'lib/core/ui/app_list_search_field.dart',
    ).readAsString();
    final filterButtonStart = source.indexOf('IconButton(');
    final filterButtonEnd = source.indexOf(
      'icon: const Icon(Icons.tune_rounded',
    );

    expect(filterButtonStart, isNonNegative);
    expect(filterButtonEnd, greaterThan(filterButtonStart));

    final filterButtonSource = source.substring(
      filterButtonStart,
      filterButtonEnd,
    );
    expect(filterButtonSource, contains('tooltip: filterTooltip'));
  });

  test('guide dashboard quick action tiles expose semantic buttons', () async {
    final source = await File(
      'lib/screens/excursions/guide_dashboard_screen.dart',
    ).readAsString();
    final tileStart = source.indexOf('class _GuideDashboardActionTile');
    final tileEnd = source.indexOf('class _GuideDashboardSectionTabs');

    expect(tileStart, isNonNegative);
    expect(tileEnd, greaterThan(tileStart));

    final tileSource = source.substring(tileStart, tileEnd);
    expect(tileSource, contains('Semantics('));
    expect(tileSource, contains('button: true'));
    expect(tileSource, contains('label: label'));
  });

  test('guide calendar day cells expose selectable semantic buttons', () async {
    final source = await File(
      'lib/screens/excursions/widgets/guide_calendar_day_strip.dart',
    ).readAsString();

    expect(source, contains('Semantics('));
    expect(source, contains('button: true'));
    expect(source, contains('selected: selected'));
    expect(source, contains('onTap: () => onDateSelected(day)'));
  });

  test('booking screen avoids fixed critical layout sizes', () async {
    final source = await File(
      'lib/screens/excursions/excursion_booking_screen.dart',
    ).readAsString();
    final contentStart = source.indexOf('class ExcursionBookingContent');
    final contentEnd = source.indexOf('class _BookingTopBar');
    final topBarStart = contentEnd;
    final topBarEnd = source.indexOf('class _BookingExcursionCard');
    final cardStart = topBarEnd;
    final cardEnd = source.indexOf('class _BookingInfoPill');
    final scheduleCardStart = source.indexOf('class _BookingScheduleCard');
    final scheduleCardEnd = source.indexOf('class _TravelerCounterRow');

    expect(contentStart, isNonNegative);
    expect(contentEnd, greaterThan(contentStart));
    expect(topBarEnd, greaterThan(topBarStart));
    expect(cardEnd, greaterThan(cardStart));
    expect(scheduleCardStart, isNonNegative);
    expect(scheduleCardEnd, greaterThan(scheduleCardStart));

    final contentSource = source.substring(contentStart, contentEnd);
    final topBarSource = source.substring(topBarStart, topBarEnd);
    final cardSource = source.substring(cardStart, cardEnd);
    final scheduleCardSource = source.substring(
      scheduleCardStart,
      scheduleCardEnd,
    );

    expect(contentSource, contains('_bookingSectionGap('));
    expect(contentSource, isNot(contains('const SizedBox(height: 42)')));
    expect(contentSource, isNot(contains('const SizedBox(height: 38)')));
    expect(contentSource, isNot(contains('const SizedBox(height: 52)')));
    expect(topBarSource, contains('_bookingTopBarMinHeight(context)'));
    expect(topBarSource, isNot(contains('height: 62')));
    expect(cardSource, contains('LayoutBuilder('));
    expect(cardSource, contains('final imageSize ='));
    expect(cardSource, isNot(contains('width: 96')));
    expect(cardSource, isNot(contains('height: 96')));
    expect(scheduleCardSource, contains('final iconBoxSize ='));
    expect(scheduleCardSource, isNot(contains('width: 48')));
    expect(scheduleCardSource, isNot(contains('height: 48')));
  });

  test(
    'excursion surfaces avoid fixed critical non-token dimensions',
    () async {
      final dayStripSource = await File(
        'lib/screens/excursions/widgets/guide_calendar_day_strip.dart',
      ).readAsString();
      final timelineSource = await File(
        'lib/screens/excursions/widgets/guide_calendar_timeline.dart',
      ).readAsString();
      final locationSource = await File(
        'lib/screens/excursions/excursion_select_location_screen.dart',
      ).readAsString();
      final bookingSource = await File(
        'lib/screens/excursions/excursion_booking_screen.dart',
      ).readAsString();
      final listSource = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();
      final createSource = await File(
        'lib/screens/excursions/create_excursion_screen.dart',
      ).readAsString();
      final mySource = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();
      final guideSource = await File(
        'lib/screens/excursions/guide_dashboard_screen.dart',
      ).readAsString();
      final reviewsSource = await File(
        'lib/screens/excursions/guide_reviews_screen.dart',
      ).readAsString();

      expect(dayStripSource, contains('_guideCalendarDayStripHeight(context)'));
      expect(
        dayStripSource,
        contains('_guideCalendarDayCellMinWidth(context)'),
      );
      expect(dayStripSource, isNot(contains('height: 92')));
      expect(dayStripSource, isNot(contains('minWidth: 62')));

      expect(
        timelineSource,
        contains('_guideTimelineSkeletonMinHeight(context)'),
      );
      expect(timelineSource, isNot(contains('height: 94')));

      expect(locationSource, contains('_locationTopBarMinHeight(context)'));
      expect(locationSource, contains('_locationGridAspectRatio('));
      expect(locationSource, contains('_locationCardMinWidth(context)'));
      expect(locationSource, isNot(contains('height: 74')));
      expect(locationSource, isNot(contains('childAspectRatio: 0.58')));
      expect(locationSource, isNot(contains('minWidth: 320')));

      expect(bookingSource, contains('_bookingFooterButtonMinHeight(context)'));
      expect(bookingSource, contains('_bookingCounterButtonSize(context)'));
      expect(bookingSource, isNot(contains('height: 60')));
      expect(bookingSource, isNot(contains('width: 36')));

      expect(listSource, contains('_excursionFilterHeaderHeight(context)'));
      expect(listSource, contains('_excursionSegmentMainAxisExtent(context)'));
      expect(listSource, contains('_excursionLanguageGridMaxHeight('));
      expect(listSource, isNot(contains('height: 74')));
      expect(listSource, isNot(contains('mainAxisExtent: 48')));
      expect(listSource, isNot(contains('maxHeight: 224')));

      expect(createSource, contains('_createExcursionLanguageGridMaxHeight('));
      expect(
        createSource,
        contains('_createExcursionIncludedItemIconBoxSize('),
      );
      expect(createSource, isNot(contains('maxHeight: 224')));
      expect(createSource, isNot(contains('width: 36')));

      expect(mySource, contains('_myExcursionsCounterButtonSize(context)'));
      expect(mySource, isNot(contains('width: 36')));

      expect(guideSource, contains('_guideQrLoadingMinHeight(context)'));
      expect(
        guideSource,
        contains('_guideDashboardSkeletonMinHeight(context)'),
      );
      expect(guideSource, isNot(contains('height: 180')));
      expect(guideSource, isNot(contains('minHeight: 280')));

      expect(
        reviewsSource,
        contains('_guideReviewsSkeletonMinHeight(context)'),
      );
      expect(reviewsSource, isNot(contains('height: 124')));
    },
  );

  test(
    'details content lays bottom actions outside the scrollable route content',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();
      final contentStart = source.indexOf('class ExcursionDetailsContent');
      final contentEnd = source.indexOf('class _ExcursionDetailsTopBar');

      expect(contentStart, isNonNegative);
      expect(contentEnd, greaterThan(contentStart));

      final contentSource = source.substring(contentStart, contentEnd);

      expect(contentSource, contains('final bottomAction ='));
      expect(contentSource, contains('?bottomAction'));
      expect(
        contentSource,
        contains('padding: const EdgeInsets.only(bottom: 24)'),
      );
      expect(contentSource, isNot(contains('scrollBottomPadding')));
      expect(contentSource, isNot(contains('bottom: 0')));
    },
  );
}

const _excursionScreenPaths = [
  'lib/screens/excursions/excursions_screen.dart',
  'lib/screens/excursions/excursion_details_screen.dart',
  'lib/screens/excursions/excursion_booking_screen.dart',
  'lib/screens/excursions/my_excursions_screen.dart',
  'lib/screens/excursions/guide_dashboard_screen.dart',
  'lib/screens/excursions/excursion_select_location_screen.dart',
  'lib/screens/excursions/create_excursion_screen.dart',
  'lib/screens/excursions/widgets/guide_schedule_slot_card.dart',
  'lib/screens/excursions/widgets/guide_schedule_slot_sheet.dart',
];
