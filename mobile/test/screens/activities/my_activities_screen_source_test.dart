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
      expect(source, contains('final filters = _filtersForTab(_activeTab)'));
      expect(
          source, contains('filters.city == null && filters.country == null'));
      expect(enSource, contains('"cityFilterEmptyHint"'));
      expect(ruSource, contains('"cityFilterEmptyHint"'));
      expect(kkSource, contains('"cityFilterEmptyHint"'));
    },
  );

  test(
    'my activities filter starts with current-location country and city filter',
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
      expect(source, contains('_initializeDefaultLocationFilter'));
      expect(source, contains('_applyDefaultLocationFilter'));
      expect(source, contains('final AppCountryFilterValue? country'));
      expect(source, contains('final AppCityFilterValue? city'));
      expect(source, contains('country: defaultCountry'));
      expect(source, contains('city: defaultCity'));
      expect(source, contains('AppCountryFilterSection'));
      expect(source, contains('AppCityFilterSection'));
      expect(source, contains('activitiesFilterCountrySection'));
      expect(source, contains('activitiesFilterCountryAll'));
      expect(source, contains('activitiesFilterCountrySearchHint'));
      expect(source, contains('activitiesFilterCountryNoResults'));
      expect(source, contains('locationFilterCitySection'));
      expect(source, contains('filters.country'));
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
      expect(source, contains('AppCountryFilterSection'));
      expect(source, contains('countryCode: _country?.countryCode'));
      expect(source, contains('if (_country != null) ...['));

      final countrySectionStart = source.indexOf('AppCountryFilterSection(');
      final citySectionStart = source.indexOf('AppCityFilterSection(');
      final dateSectionStart = source.indexOf(
        'widget.l10n.myActivitiesFilterDateRange',
      );
      expect(countrySectionStart, isNonNegative);
      expect(citySectionStart, isNonNegative);
      expect(citySectionStart, greaterThan(countrySectionStart));
      expect(dateSectionStart, greaterThan(citySectionStart));

      final citySection = source.substring(citySectionStart, dateSectionStart);
      expect(citySection, contains('AppCityFilterSection'));
      expect(citySection, isNot(contains('Wrap(')));
    },
  );

  test(
    'my activities country changes reset city to all cities',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      expect(
          source, contains('void _setCountry(AppCountryFilterValue? country)'));
      expect(source, contains('_country = country'));
      expect(source, contains('_city = null'));
    },
  );

  test(
    'my activities can filter by country without selecting a city',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      expect(source, contains('filters.country != null'));
      expect(source, contains('!filters.country!.matches('));
      expect(source, contains('countryCode: item.countryCode'));
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
