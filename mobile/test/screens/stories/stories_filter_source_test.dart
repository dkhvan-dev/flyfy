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
    expect(searchBarSource, contains('IconButton.styleFrom('));
    expect(
      searchBarSource,
      contains('backgroundColor: AppColors.accent.withValues(alpha: 0.12)'),
    );
    expect(searchBarSource, contains('foregroundColor: AppColors.accent'));
    expect(searchBarSource, contains('minimumSize: Size('));
  });

  test(
      'stories country filter uses localized searchable countries and defaults to all countries',
      () async {
    final source = await File(
      'lib/screens/stories/stories_screen.dart',
    ).readAsString();

    final filterSheetStart = source.indexOf('class _StoryFiltersSheet');
    final filterSheetEnd = source.indexOf('class _FilterSheet');
    expect(filterSheetStart, isNonNegative);
    expect(filterSheetEnd, greaterThan(filterSheetStart));
    final filterSheetSource =
        source.substring(filterSheetStart, filterSheetEnd);

    expect(
      source,
      contains("import '../../core/reference/country_filter_utils.dart';"),
    );
    expect(source, contains('Map<String, Set<String>> _countrySearchAliases'));
    expect(source, contains('Future<void> _loadCountries()'));
    expect(source, contains('countrySearchAliasMap(['));
    expect(source, contains('countrySearchAliases: _countrySearchAliases'));
    expect(source, isNot(contains('_applyDefaultCountryFilter')));
    expect(source, isNot(contains('withDefaultReferenceCountry(')));

    expect(
        filterSheetSource, contains('final List<ReferenceCountry> countries'));
    expect(
      filterSheetSource,
      contains('final Map<String, Set<String>> countrySearchAliases'),
    );
    expect(filterSheetSource, contains('_countrySearchController'));
    expect(filterSheetSource, contains('_countrySearchQuery'));
    expect(filterSheetSource, contains('countryFilterSearchHaystack('));
    expect(filterSheetSource, contains('storyFilterCountryAll'));
    expect(filterSheetSource, contains('storyFilterCountrySearchHint'));
    expect(filterSheetSource, contains('storyFilterCountryNoResults'));
    expect(filterSheetSource, contains('selectedCountry == null'));
    expect(filterSheetSource, isNot(contains('searchCountries(')));
  });
}
