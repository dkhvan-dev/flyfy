import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stories filters live in one modal opened from the search bar',
      () async {
    final source = await File(
      'lib/screens/stories/stories_screen.dart',
    ).readAsString();
    final searchBarStart = source.indexOf('class _StoriesSearchBar');
    final filterSheetStart = source.indexOf('class _StoryFiltersSheet');
    final sortRowStart = source.indexOf('class _StoriesSortRow');

    expect(searchBarStart, isNonNegative);
    expect(filterSheetStart, isNonNegative);
    expect(sortRowStart, isNonNegative);

    final searchBarSource = source.substring(searchBarStart, sortRowStart);

    expect(source, isNot(contains('_StoriesFilterRow(')));
    expect(source, isNot(contains('class _StoriesFilterRow')));
    expect(source, isNot(contains('_showCategorySheet')));
    expect(source, isNot(contains('_showPlaceSheet')));
    expect(source, contains('Future<void> _openFilters()'));
    expect(source, contains('showModalBottomSheet<_StoryFiltersResult>'));
    expect(source, contains('class _StoryFiltersSheet'));
    expect(searchBarSource, contains('onFilterTap'));
    expect(searchBarSource, contains('Icons.tune_rounded'));
    expect(searchBarSource, contains('hasActiveFilters'));
  });
}
