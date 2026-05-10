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
}
