import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('discover activities sort row matches the stories text control style',
      () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();
    final inlineSortRowSource = await File(
      'lib/core/ui/app_inline_sort_row.dart',
    ).readAsString();
    final sortBarStart = source.indexOf('class _DiscoverSortBar');
    final sortBarEnd = source.indexOf('class _FiltersSummaryBar');

    expect(sortBarStart, isNonNegative);
    expect(sortBarEnd, greaterThan(sortBarStart));

    final sortBarSource = source.substring(sortBarStart, sortBarEnd);

    expect(sortBarSource, contains('AppInlineSortRow<_ActivitySortField>'));
    expect(sortBarSource, contains('activitiesSortLabel'));
    expect(inlineSortRowSource, contains('SingleChildScrollView'));
    expect(inlineSortRowSource, contains('scrollDirection: Axis.horizontal'));
    expect(inlineSortRowSource, contains('GestureDetector('));
    expect(inlineSortRowSource, contains("'\$label:'"));
    expect(inlineSortRowSource, contains('Icons.arrow_upward_rounded'));
    expect(inlineSortRowSource, contains('Icons.arrow_downward_rounded'));
    expect(sortBarSource, isNot(contains('_DiscoverSortButton(')));
    expect(sortBarSource, isNot(contains('LinearGradient(')));
    expect(source, isNot(contains('class _DiscoverSortButton')));
  });

  test('discover activities filter uses the full-width shared apply button',
      () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();
    final scaffoldStart = source.indexOf('class _RangeSheetScaffold');
    final scaffoldEnd = source.indexOf('class _RangeTextField');

    expect(scaffoldStart, isNonNegative);
    expect(scaffoldEnd, greaterThan(scaffoldStart));

    final scaffoldSource = source.substring(scaffoldStart, scaffoldEnd);

    expect(scaffoldSource, contains('AppFilterApplyButton'));
    expect(scaffoldSource, isNot(contains('_PrimaryPillButton(')));
  });
}
