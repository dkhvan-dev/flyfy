import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'my activities empty state suggests changing city filter when city is active',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();
      final enSource = await File('lib/l10n/app_en.arb').readAsString();
      final ruSource = await File('lib/l10n/app_ru.arb').readAsString();
      final kkSource = await File('lib/l10n/app_kk.arb').readAsString();

      expect(source, contains('_myActivitiesEmptyMessage'));
      expect(source, contains('l10n.cityFilterEmptyHint'));
      expect(source, contains('_filtersForTab(_activeTab).city'));
      expect(enSource, contains('"cityFilterEmptyHint"'));
      expect(ruSource, contains('"cityFilterEmptyHint"'));
      expect(kkSource, contains('"cityFilterEmptyHint"'));
    },
  );

  test(
    'my activities filter starts with current-location city filter',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../providers/home_location_provider.dart';"),
      );
      expect(
        source,
        contains("import '../../shared/widgets/app_city_filter_section.dart';"),
      );
      expect(source, contains('HomeLocationProvider'));
      expect(source, contains('selectedLocation'));
      expect(source, contains('_initializeDefaultCityFilter'));
      expect(source, contains('_applyDefaultCityFilter'));
      expect(source, contains('final AppCityFilterValue? city'));
      expect(source, contains('AppCityFilterSection'));
      expect(source, contains('locationFilterCitySection'));
      expect(source, contains('filters.city'));
      expect(source, contains('item.cityId'));
      expect(source, contains('item.cityName'));
      expect(source, contains('countryCode: item.countryCode'));
      expect(source, isNot(contains('profile?.countryCode')));
    },
  );

  test(
    'my activities city filter is compact and searchable through shared selector',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      expect(source, contains('AppCityFilterSection'));
      expect(source, contains('locationFilterCitySearchHint'));
      expect(source, contains('locationFilterCityNoResults'));
      expect(source, isNot(contains('_countrySearchController')));
      expect(source, isNot(contains('_selectedCountry()')));
      expect(source, isNot(contains('_visibleCountries')));

      final citySectionStart = source.indexOf('AppCityFilterSection(');
      final dateSectionStart = source.indexOf(
        'widget.l10n.myActivitiesFilterDateRange',
      );
      expect(citySectionStart, isNonNegative);
      expect(dateSectionStart, greaterThan(citySectionStart));

      final citySection = source.substring(citySectionStart, dateSectionStart);
      expect(citySection, contains('AppCityFilterSection'));
      expect(citySection, isNot(contains('Wrap(')));
    },
  );

  test(
    'my activities card does not duplicate location under category label',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      final cardStart = source.indexOf('class _MyActivitiesCard');
      final coverStart = source.indexOf('class _ActivityCover');
      expect(cardStart, isNonNegative);
      expect(coverStart, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, coverStart);
      final categoryLabelStart = cardSource.indexOf(
        'normalizedCategoryLabel.toUpperCase()',
      );
      final compactTitleStart = cardSource.indexOf('if (compactCard)');
      expect(categoryLabelStart, isNonNegative);
      expect(compactTitleStart, greaterThan(categoryLabelStart));

      final categoryHeaderSource = cardSource.substring(
        categoryLabelStart,
        compactTitleStart,
      );

      expect(categoryHeaderSource, isNot(contains('locationText')));
      expect(
        cardSource,
        contains(
          'final locationFallbackText = activityLocationFallbackText(item, l10n);',
        ),
      );
      expect(
        cardSource,
        contains('labelBuilder: (style) => AppLocalizedLocationText('),
      );
      expect(cardSource, contains('fallbackText: locationFallbackText'));
      expect(cardSource, isNot(contains('fallbackText: locationText')));
    },
  );
}
