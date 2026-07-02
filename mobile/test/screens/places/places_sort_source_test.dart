import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'places screen exposes stories-style rating duration and price sort controls',
    () async {
      final source = await File(
        'lib/screens/places/places_screen.dart',
      ).readAsString();
      final inlineSortRowSource = await File(
        'lib/core/ui/app_inline_sort_row.dart',
      ).readAsString();
      final loadStart = source.indexOf('Future<void> _loadPlaces');
      final loadEnd = source.indexOf('Future<void> _openFilters');
      final sortBarStart = source.indexOf('class _PlaceSortBar');
      final sortBarEnd = source.indexOf('class _DiscoverCard');

      expect(loadStart, isNonNegative);
      expect(loadEnd, greaterThan(loadStart));
      expect(sortBarStart, isNonNegative);
      expect(sortBarEnd, greaterThan(sortBarStart));

      final loadSource = source.substring(loadStart, loadEnd);
      final sortBarSource = source.substring(sortBarStart, sortBarEnd);

      expect(source, contains('enum _PlaceSortField'));
      expect(source, contains('enum _PlaceSortDirection'));
      expect(loadSource, contains('sort: _sortQueryParam'));
      expect(source, contains('_PlaceSortBar('));
      expect(source, contains('placesSortRating'));
      expect(source, contains('placesSortDuration'));
      expect(source, contains('placesSortPrice'));
      expect(sortBarSource, contains('AppInlineSortRow<_PlaceSortField>'));
      expect(sortBarSource, contains('placesSortLabel'));
      expect(inlineSortRowSource, contains('SingleChildScrollView'));
      expect(inlineSortRowSource, contains('scrollDirection: Axis.horizontal'));
      expect(inlineSortRowSource, contains('GestureDetector('));
      expect(inlineSortRowSource, contains("'\$label:'"));
      expect(inlineSortRowSource, contains('Icons.arrow_upward_rounded'));
      expect(inlineSortRowSource, contains('Icons.arrow_downward_rounded'));
      expect(sortBarSource, isNot(contains('_PlaceSortChip(')));
      expect(sortBarSource, isNot(contains('Wrap(')));
      expect(sortBarSource, isNot(contains('AppBoxDecoration(')));
      expect(source, isNot(contains('class _PlaceSortChip')));
    },
  );

  test(
    'places screen does not render curated or recommended headings',
    () async {
      final source = await File(
        'lib/screens/places/places_screen.dart',
      ).readAsString();

      expect(source, isNot(contains('placesCuratedListEyebrow')));
      expect(source, isNot(contains('placesRecommendedTitle')));
    },
  );

  test(
    'places search field shows filter count badge and compact icons',
    () async {
      final source = await File(
        'lib/screens/places/places_screen.dart',
      ).readAsString();

      final searchStart = source.indexOf('Widget _buildSearchBar');
      final bodyStart = source.indexOf('Widget _buildBody');
      expect(searchStart, isNonNegative);
      expect(bodyStart, greaterThan(searchStart));
      final searchSource = source.substring(searchStart, bodyStart);

      expect(
        source,
        contains("import '../../core/ui/app_list_search_field.dart';"),
      );
      expect(
        searchSource,
        contains('final activeFilterCount = _filters.activeCount;'),
      );
      expect(searchSource, contains('AppListSearchField('));
      expect(searchSource, contains('activeFilterCount: activeFilterCount'));
      expect(searchSource, contains('_loadPlaces(page: 1);'));
      expect(searchSource, isNot(contains('size: a.scale(28)')));
      expect(searchSource, isNot(contains('fontSize: a.scale(21')));
    },
  );

  test(
    'place cards display every backend category and use compact save icon',
    () async {
      final source = await File(
        'lib/screens/places/places_screen.dart',
      ).readAsString();
      final sheetSource = await File(
        'lib/screens/places/places_filter_sheet.dart',
      ).readAsString();
      final uiSource = await File(
        'lib/features/places/place_ui.dart',
      ).readAsString();

      expect(source, contains('localizedPlaceCategoryLabel(l10n, category)'));
      for (final category in [
        'NATURE',
        'ARCHITECTURE',
        'MUSEUM',
        'BEACH',
        'PARK',
        'TEMPLE',
        'ENTERTAINMENT',
        'FOOD',
        'MARKET',
        'SHOPPING',
        'OTHER',
      ]) {
        expect(uiSource, contains("case '$category':"));
      }

      final saveButtonStart = source.indexOf(
        'Widget _saveButton(BuildContext context)',
      );
      final categoryTagStart = source.indexOf(
        'Widget _categoryTag(BuildContext context)',
      );
      expect(saveButtonStart, isNonNegative);
      expect(categoryTagStart, greaterThan(saveButtonStart));
      final saveButtonSource = source.substring(
        saveButtonStart,
        categoryTagStart,
      );

      expect(saveButtonSource, contains('adaptive.scale(42'));
      expect(saveButtonSource, contains('adaptive.scale(19'));
      expect(saveButtonSource, isNot(contains('adaptive.scale(56')));
      expect(saveButtonSource, isNot(contains('adaptive.scale(27')));

      expect(sheetSource, contains("value: 'PARK'"));
      expect(sheetSource, contains("value: 'MUSEUM'"));
      expect(sheetSource, contains("value: 'MARKET'"));
      expect(sheetSource, isNot(contains("value: 'PARKS'")));
      expect(sheetSource, isNot(contains("value: 'MUSEUMS'")));
    },
  );
}
