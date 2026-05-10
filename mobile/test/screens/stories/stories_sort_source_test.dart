import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stories sort row exposes ascending and descending direction controls',
      () async {
    final source = await File(
      'lib/screens/stories/stories_screen.dart',
    ).readAsString();
    final sortRowStart = source.indexOf('class _StoriesSortRow');
    final storyCardStart = source.indexOf('class _StoryListCard');

    expect(sortRowStart, isNonNegative);
    expect(storyCardStart, greaterThan(sortRowStart));

    final sortRowSource = source.substring(sortRowStart, storyCardStart);

    expect(source, contains('enum _StorySortDirection'));
    expect(source, contains('_StorySortDirection _sortDirection'));
    expect(source, contains('String get _sortQueryParam'));
    expect(source, contains('void _handleSortSelected(String value)'));
    expect(source, contains('sort: _sortQueryParam'));
    expect(source, contains('sortDirection: _sortDirection'));
    expect(sortRowSource, contains('Icons.arrow_upward_rounded'));
    expect(sortRowSource, contains('Icons.arrow_downward_rounded'));
    expect(sortRowSource, contains('sortDirection == _StorySortDirection.asc'));
  });
}
