import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('attractions screen exposes rating duration and price sort controls',
      () async {
    final source = await File('lib/screens/attractions/attractions_screen.dart')
        .readAsString();
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
    expect(source, contains('Icons.star_rounded'));
    expect(source, contains('Icons.schedule_rounded'));
    expect(source, contains('Icons.payments_rounded'));
    expect(sortBarSource, contains('Icons.arrow_upward_rounded'));
    expect(sortBarSource, contains('Icons.arrow_downward_rounded'));
  });

  test('attractions screen does not render curated or recommended headings',
      () async {
    final source = await File('lib/screens/attractions/attractions_screen.dart')
        .readAsString();

    expect(source, isNot(contains('attractionsCuratedListEyebrow')));
    expect(source, isNot(contains('attractionsRecommendedTitle')));
  });
}
