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

  test('discover activities hides summary bar for empty filtered results',
      () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();
    final summaryBarCall = source.indexOf('_FiltersSummaryBar(');
    final summaryCondition = source.lastIndexOf('if (', summaryBarCall);

    expect(summaryBarCall, isNonNegative);
    expect(summaryCondition, isNonNegative);

    final conditionSource = source.substring(summaryCondition, summaryBarCall);
    expect(conditionSource, contains('filteredItems.isNotEmpty'));
    expect(conditionSource, contains('_searchQuery.isNotEmpty'));
    expect(conditionSource, contains('_filters.hasAnyValue'));
  });

  test('discover activities price filter keeps only a free preset', () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();
    final priceSectionStart = source.indexOf('Widget _buildPriceSection');
    final priceSectionEnd = source.indexOf('Widget _buildVisibilitySection');
    final presetsStart =
        source.indexOf('List<_PricePreset> _buildPricePresets');
    final presetsEnd = source.indexOf('List<_DatePreset> _buildDatePresets');

    expect(priceSectionStart, isNonNegative);
    expect(priceSectionEnd, greaterThan(priceSectionStart));
    expect(presetsStart, isNonNegative);
    expect(presetsEnd, greaterThan(presetsStart));

    final priceSectionSource = source.substring(
      priceSectionStart,
      priceSectionEnd,
    );
    final presetsSource = source.substring(presetsStart, presetsEnd);

    expect(priceSectionSource, contains("prefix: ''"));
    expect(priceSectionSource, isNot(contains('filterCurrencyLabel')));
    expect(priceSectionSource, isNot(contains('pricePresetNominalUnit')));
    expect(presetsSource, contains('l10n.createPriceFree'));
    expect(RegExp(r'_PricePreset\(').allMatches(presetsSource), hasLength(1));
    expect(presetsSource, isNot(contains('currencyLabel')));
    expect(presetsSource, isNot(contains('nominalUnit')));
  });

  test('discover activities filter option cards avoid fixed heights', () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();
    final categoryStart = source.indexOf('class _CategoryFilterPill');
    final visibilityStart = source.indexOf('class _VisibilityOptionCard');
    final filterSectionStart = source.indexOf('class _FilterSection');

    expect(categoryStart, isNonNegative);
    expect(visibilityStart, greaterThan(categoryStart));
    expect(filterSectionStart, greaterThan(visibilityStart));

    final categorySource = source.substring(categoryStart, visibilityStart);
    final visibilitySource = source.substring(
      visibilityStart,
      filterSectionStart,
    );

    expect(categorySource, contains('constraints: BoxConstraints('));
    expect(categorySource, contains('minHeight:'));
    expect(
      categorySource,
      isNot(contains('height: _activitiesScaled(context, 58')),
    );
    expect(visibilitySource, contains('constraints: BoxConstraints('));
    expect(visibilitySource, contains('minHeight:'));
    expect(
      visibilitySource,
      isNot(contains('height: _activitiesScaled(context, 76')),
    );
  });
}
