import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'my excursions screen uses shared list chrome and paginated tabs',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();

      expect(source, contains('class MyExcursionsScreen'));
      expect(
        source,
        contains("import '../../core/ui/app_list_screen_header.dart';"),
      );
      expect(
        source,
        contains("import '../../core/ui/app_list_search_field.dart';"),
      );
      expect(
        source,
        contains("import '../../core/ui/app_inline_sort_row.dart';"),
      );
      expect(
        source,
        contains("import '../../core/ui/filter_sheet_chrome.dart';"),
      );
      expect(source, contains("import '../../core/ui/pagination_bar.dart';"));
      expect(source, contains('MyExcursionsTab.booked'));
      expect(source, contains('MyExcursionsTab.visited'));
      expect(source, contains('AppListScreenHeader('));
      expect(source, contains('AppListSearchField('));
      expect(source, contains('AppInlineSortRow<MyExcursionBookingSortMode>'));
      expect(source, contains('showModalBottomSheet<_MyExcursionsFilters>'));
      expect(source, contains('FlyfyPaginationBar('));
    },
  );

  test(
    'my excursions screen exposes review action for unrated visits',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();

      expect(source, contains('booking.canReview'));
      expect(source, contains('myExcursionsReviewButton'));
      expect(source, contains('class _ExcursionReviewSheet'));
      expect(source, contains('createExcursionReview('));
      expect(source, contains('loadExcursionReviews('));
    },
  );

  test(
    'my excursions filter uses activity-style manual date range and excursion result label',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();

      expect(source, contains('TextEditingController _startDateController'));
      expect(source, contains('TextEditingController _endDateController'));
      expect(source, contains('class _FilterDateField'));
      expect(source, contains('class _DateTextInputFormatter'));
      expect(source, contains('myActivitiesFilterInvalidDate'));
      expect(source, contains('myActivitiesFilterInvalidRange'));
      expect(source, contains('excursionsFiltersShowResults('));
      expect(source, contains('previewCount'));
      expect(source, isNot(contains('activitiesShowResults(previewCount)')));
      expect(source, isNot(contains('showDatePicker(')));
      expect(source, isNot(contains('class _DateButton')));
    },
  );

  test('my excursions filter sheet constrains height above keyboard', () async {
    final source = await File(
      'lib/screens/excursions/my_excursions_screen.dart',
    ).readAsString();
    final sheetStart = source.indexOf('class _MyExcursionsFilterSheetState');
    final sectionTitleStart = source.indexOf('class _FilterSectionTitle');

    expect(sheetStart, isNonNegative);
    expect(sectionTitleStart, greaterThan(sheetStart));

    final sheetSource = source.substring(sheetStart, sectionTitleStart);

    expect(sheetSource, contains('final size = MediaQuery.sizeOf(context);'));
    expect(sheetSource, contains('final keyboardInset ='));
    expect(sheetSource, contains('final availableSheetHeight = math.max('));
    expect(sheetSource, contains('size.height -'));
    expect(sheetSource, contains('keyboardInset -'));
    expect(sheetSource, contains('final maxHeight = math.min('));
    expect(sheetSource, contains('AnimatedPadding('));
  });

  test(
    'router and drawer expose my excursions as authenticated menu item',
    () async {
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();
      final drawerSource = await File(
        'lib/screens/common/app_side_drawer.dart',
      ).readAsString();

      expect(routerSource, contains("path: '/me/excursions'"));
      expect(routerSource, contains('MyExcursionsScreen'));
      expect(routerSource, isNot(contains("location == '/me/excursions'")));
      expect(drawerSource, contains('AppDrawerActiveItem.myExcursions'));
      expect(drawerSource, contains('onMyExcursionsTap'));
      expect(drawerSource, contains('myExcursionsTitle'));
    },
  );

  test('edit guests sheet shows mock settlement for payment deltas', () async {
    final source = await File(
      'lib/screens/excursions/my_excursions_screen.dart',
    ).readAsString();
    final ruSource = await File('lib/l10n/app_ru.arb').readAsString();

    expect(source, contains('_settlementDeltaAmount'));
    expect(source, contains('_simulateMockSettlement'));
    expect(source, contains('formatLocalizedExcursionMoney'));
    expect(source, contains('myExcursionsGuestsChargeMock'));
    expect(source, contains('myExcursionsGuestsRefundMock'));
    expect(source, contains('myExcursionsGuestsNoPaymentChange'));
    expect(source, contains('myExcursionsPayAndSaveGuests'));
    expect(source, contains('myExcursionsRefundAndSaveGuests'));
    expect(ruSource, contains('"myExcursionsGuestsChargeMock"'));
    expect(ruSource, contains('"myExcursionsGuestsRefundMock"'));
  });
}
