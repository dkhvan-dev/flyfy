import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'attractions screen exposes stories-style rating duration and price sort controls',
      () async {
    final source = await File('lib/screens/attractions/attractions_screen.dart')
        .readAsString();
    final inlineSortRowSource = await File(
      'lib/core/ui/app_inline_sort_row.dart',
    ).readAsString();
    final loadStart = source.indexOf('Future<void> _loadAttractions');
    final loadEnd = source.indexOf('Future<void> _openFilters');
    final sortBarStart = source.indexOf('class _AttractionSortBar');
    final sortBarEnd = source.indexOf('class _DiscoverCard');

    expect(loadStart, isNonNegative);
    expect(loadEnd, greaterThan(loadStart));
    expect(sortBarStart, isNonNegative);
    expect(sortBarEnd, greaterThan(sortBarStart));

    final loadSource = source.substring(loadStart, loadEnd);
    final sortBarSource = source.substring(sortBarStart, sortBarEnd);

    expect(source, contains('enum _AttractionSortField'));
    expect(source, contains('enum _AttractionSortDirection'));
    expect(loadSource, contains('sort: _sortQueryParam'));
    expect(source, contains('_AttractionSortBar('));
    expect(source, contains('attractionsSortRating'));
    expect(source, contains('attractionsSortDuration'));
    expect(source, contains('attractionsSortPrice'));
    expect(sortBarSource, contains('AppInlineSortRow<_AttractionSortField>'));
    expect(sortBarSource, contains('attractionsSortLabel'));
    expect(inlineSortRowSource, contains('SingleChildScrollView'));
    expect(inlineSortRowSource, contains('scrollDirection: Axis.horizontal'));
    expect(inlineSortRowSource, contains('GestureDetector('));
    expect(inlineSortRowSource, contains("'\$label:'"));
    expect(inlineSortRowSource, contains('Icons.arrow_upward_rounded'));
    expect(inlineSortRowSource, contains('Icons.arrow_downward_rounded'));
    expect(sortBarSource, isNot(contains('_AttractionSortChip(')));
    expect(sortBarSource, isNot(contains('Wrap(')));
    expect(sortBarSource, isNot(contains('BoxDecoration(')));
    expect(source, isNot(contains('class _AttractionSortChip')));
  });

  test('attractions screen does not render curated or recommended headings',
      () async {
    final source = await File('lib/screens/attractions/attractions_screen.dart')
        .readAsString();

    expect(source, isNot(contains('attractionsCuratedListEyebrow')));
    expect(source, isNot(contains('attractionsRecommendedTitle')));
  });

  test('attractions search field shows filter count badge and compact icons',
      () async {
    final source = await File('lib/screens/attractions/attractions_screen.dart')
        .readAsString();

    final searchStart = source.indexOf('Widget _buildSearchBar');
    final bodyStart = source.indexOf('Widget _buildBody');
    expect(searchStart, isNonNegative);
    expect(bodyStart, greaterThan(searchStart));
    final searchSource = source.substring(searchStart, bodyStart);

    expect(searchSource,
        contains('final activeFilterCount = _filters.activeCount;'));
    expect(searchSource, contains('Stack('));
    expect(searchSource, contains('clipBehavior: Clip.none'));
    expect(searchSource, contains('IconButton.styleFrom('));
    expect(
      searchSource,
      contains('backgroundColor: AppColors.accent.withValues(alpha: 0.12)'),
    );
    expect(searchSource, contains('foregroundColor: AppColors.accent'));
    expect(searchSource, contains('if (activeFilterCount > 0)'));
    expect(searchSource, contains('activeFilterCount.toString()'));
    expect(searchSource, contains('a.scale(27'));
    expect(searchSource, contains('a.scale(24'));
    expect(searchSource, contains('a.scale(16'));
    expect(searchSource, isNot(contains('size: a.scale(28)')));
    expect(searchSource, isNot(contains('fontSize: a.scale(21')));
  });

  test(
      'attraction cards display every backend category and use compact save icon',
      () async {
    final source = await File('lib/screens/attractions/attractions_screen.dart')
        .readAsString();
    final sheetSource = await File(
      'lib/screens/attractions/attractions_filter_sheet.dart',
    ).readAsString();

    final labelStart = source.indexOf('String _categoryLabel');
    final placeholderStart = source.indexOf('Widget _placeholder()');
    expect(labelStart, isNonNegative);
    expect(placeholderStart, greaterThan(labelStart));
    final labelSource = source.substring(labelStart, placeholderStart);

    for (final category in [
      'NATURE',
      'ARCHITECTURE',
      'MUSEUM',
      'BEACH',
      'PARK',
      'TEMPLE',
      'ENTERTAINMENT',
      'FOOD',
      'SHOPPING',
      'OTHER',
    ]) {
      expect(labelSource, contains("case '$category':"));
    }
    expect(labelSource, isNot(contains('return null;')));

    final saveButtonStart = source.indexOf('Widget _saveButton()');
    final categoryTagStart = source.indexOf('Widget _categoryTag()');
    expect(saveButtonStart, isNonNegative);
    expect(categoryTagStart, greaterThan(saveButtonStart));
    final saveButtonSource =
        source.substring(saveButtonStart, categoryTagStart);

    expect(saveButtonSource, contains('adaptive.scale(42'));
    expect(saveButtonSource, contains('adaptive.scale(19'));
    expect(saveButtonSource, isNot(contains('adaptive.scale(56')));
    expect(saveButtonSource, isNot(contains('adaptive.scale(27')));

    expect(sheetSource, contains("value: 'PARK'"));
    expect(sheetSource, contains("value: 'MUSEUM'"));
    expect(sheetSource, isNot(contains("value: 'PARKS'")));
    expect(sheetSource, isNot(contains("value: 'MUSEUMS'")));
  });
}
