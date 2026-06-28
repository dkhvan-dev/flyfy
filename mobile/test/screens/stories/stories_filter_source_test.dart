import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'stories filters live in one modal opened from the search bar',
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
      expect(source, contains('showAppModalBottomSheet<_StoryFiltersResult>'));
      expect(source, contains('class _StoryFiltersSheet'));
      expect(searchBarSource, contains('onFilterTap'));
      expect(searchBarSource, contains('AppListSearchField('));
      expect(searchBarSource, contains('activeFilterCount'));
      expect(searchBarSource, contains('showClearButton: true'));
    },
  );

  test(
    'stories location filter uses shared searchable country and city controls without defaults',
    () async {
      final source = await File(
        'lib/screens/stories/stories_screen.dart',
      ).readAsString();

      final filterSheetStart = source.indexOf('class _StoryFiltersSheet');
      final filterSheetEnd = source.indexOf('class _FilterSheet');
      expect(filterSheetStart, isNonNegative);
      expect(filterSheetEnd, greaterThan(filterSheetStart));
      final filterSheetSource = source.substring(
        filterSheetStart,
        filterSheetEnd,
      );

      expect(
        source,
        contains("import '../../shared/widgets/app_city_filter_section.dart';"),
      );
      expect(source, contains('AppCountryFilterValue? _selectedCountry'));
      expect(source, contains('AppCityFilterValue? _selectedCity'));
      expect(
        source,
        contains('void _setCountry(AppCountryFilterValue? country)'),
      );
      expect(source, contains('_selectedCountry = country'));
      expect(source, contains('_selectedCity = null'));
      expect(source, contains('void _setCity(AppCityFilterValue? city)'));
      expect(source, contains('countryCode: _selectedCountry?.countryCode'));
      expect(
        source,
        contains('String? get _selectedCityId => _selectedCity?.cityId'),
      );
      expect(source, contains('placeCityId'));
      expect(source, isNot(contains('HomeLocationProvider')));
      expect(source, isNot(contains('selectedLocation')));
      expect(source, isNot(contains('_applyDefaultCountryFilter')));
      expect(source, isNot(contains('withDefaultReferenceCountry(')));

      expect(filterSheetSource, contains('AppCountryFilterSection('));
      expect(filterSheetSource, contains('AppCityFilterSection('));
      expect(filterSheetSource, contains('storyFilterCountryAll'));
      expect(filterSheetSource, contains('storyFilterCountrySearchHint'));
      expect(filterSheetSource, contains('storyFilterCountryNoResults'));
      expect(filterSheetSource, contains('locationFilterAllCities'));
      expect(filterSheetSource, contains('locationFilterCitySearchHint'));
      expect(
        filterSheetSource,
        isNot(contains('if (_selectedCountry != null) ...[')),
      );
      expect(filterSheetSource, isNot(contains('_countrySearchController')));
      expect(
        filterSheetSource,
        isNot(contains('countryFilterSearchHaystack(')),
      );

      final countrySectionCall = filterSheetSource.indexOf(
        '_buildCountrySection(l10n, adaptive)',
      );
      final citySectionCall = filterSheetSource.indexOf(
        '_buildCitySection(l10n, adaptive)',
      );
      final categoryTitleCall = filterSheetSource.indexOf(
        '_FilterSectionTitle(label: l10n.storyFilterCategory)',
      );

      expect(countrySectionCall, isNonNegative);
      expect(citySectionCall, isNonNegative);
      expect(categoryTitleCall, isNonNegative);
      expect(countrySectionCall, lessThan(categoryTitleCall));
      expect(citySectionCall, lessThan(categoryTitleCall));
    },
  );

  test(
    'stories filter modal separates material type and theme filters',
    () async {
      final source = await File(
        'lib/screens/stories/stories_screen.dart',
      ).readAsString();

      final filterSheetStart = source.indexOf('class _StoryFiltersSheet');
      final filterSheetEnd = source.indexOf('class _FilterSheet');
      expect(filterSheetStart, isNonNegative);
      expect(filterSheetEnd, greaterThan(filterSheetStart));
      final filterSheetSource = source.substring(
        filterSheetStart,
        filterSheetEnd,
      );

      expect(source, contains('String? _selectedFormat'));
      expect(source, contains('formats: _selectedFormat == null'));
      expect(filterSheetSource, contains('initialFormat'));
      expect(filterSheetSource, contains('storyFilterFormat'));
      expect(filterSheetSource, contains('storyFilterCategory'));
      expect(filterSheetSource, contains('_FilterFormatGrid('));
      expect(filterSheetSource, contains('_FilterCategoryGrid('));
      expect(filterSheetSource, contains('formatStoryFormat(l10n, option)'));
      expect(filterSheetSource, contains('formatStoryCategory(l10n, option)'));
    },
  );
}
