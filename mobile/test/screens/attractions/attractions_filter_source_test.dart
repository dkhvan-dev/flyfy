import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'attractions filter starts with localized searchable city filter',
    () async {
      final screenSource = await File(
        'lib/screens/attractions/attractions_screen.dart',
      ).readAsString();
      final sheetSource = await File(
        'lib/screens/attractions/attractions_filter_sheet.dart',
      ).readAsString();

      expect(
        sheetSource,
        contains("import '../../shared/widgets/app_city_filter_section.dart';"),
      );
      expect(sheetSource, contains('final AppCountryFilterValue? country'));
      expect(sheetSource, contains('final AppCityFilterValue? city'));
      expect(sheetSource, contains('String? get cityId => city?.cityId'));
      expect(
        sheetSource,
        contains(
          'String? get countryCode => country?.countryCode ?? city?.countryCode',
        ),
      );
      expect(sheetSource, contains('city == null ? 0 : 1'));
      expect(sheetSource, contains('country == null ? 0 : 1'));
      expect(sheetSource, contains('AppCountryFilterSection'));
      expect(sheetSource, contains('AppCityFilterSection'));
      expect(sheetSource, contains('attractionFilterCountrySection'));
      expect(sheetSource, contains('attractionFilterCountryAll'));
      expect(sheetSource, contains('attractionFilterCountrySearchHint'));
      expect(sheetSource, contains('attractionFilterCountryNoResults'));
      expect(sheetSource, contains('locationFilterCitySection'));
      expect(sheetSource, contains('locationFilterCitySearchHint'));
      expect(sheetSource, contains('locationFilterCityNoResults'));
      expect(sheetSource, contains('countryCode: _country?.countryCode'));
      expect(sheetSource, contains('cityId: staged.cityId'));

      final countrySectionStart = sheetSource.indexOf(
        'AppCountryFilterSection(',
      );
      final citySectionStart = sheetSource.indexOf('AppCityFilterSection(');
      final categorySectionStart = sheetSource.indexOf(
        'header: l10n.attractionFilterCategoriesSection',
      );
      expect(countrySectionStart, isNonNegative);
      expect(citySectionStart, isNonNegative);
      expect(citySectionStart, greaterThan(countrySectionStart));
      expect(categorySectionStart, greaterThan(citySectionStart));

      final citySection = sheetSource.substring(
        citySectionStart,
        categorySectionStart,
      );
      expect(citySection, contains('AppCityFilterSection'));
      expect(citySection, isNot(contains('Wrap(')));

      expect(
        screenSource,
        contains("import '../../providers/home_location_provider.dart';"),
      );
      expect(
        screenSource,
        contains("import '../../shared/widgets/app_city_filter_section.dart';"),
      );
      expect(screenSource, contains('HomeLocationProvider'));
      expect(screenSource, contains('selectedLocation'));
      expect(screenSource, contains('_initializeDefaultLocationFilter'));
      expect(screenSource, contains('_applyDefaultLocationFilter'));
      expect(screenSource, contains('country: defaultCountry'));
      expect(screenSource, contains('city: defaultCity'));
      expect(screenSource, contains('cityId: _filters.cityId'));
      expect(screenSource, contains('countryCode: _filters.countryCode'));
      expect(screenSource, isNot(contains('profile?.countryCode')));
    },
  );

  test(
    'attractions city filter is hidden until a country is selected',
    () async {
      final sheetSource = await File(
        'lib/screens/attractions/attractions_filter_sheet.dart',
      ).readAsString();

      expect(
        sheetSource,
        contains('void _setCountry(AppCountryFilterValue? value)'),
      );
      expect(sheetSource, contains('_country = value'));
      expect(sheetSource, contains('_city = null'));
      expect(sheetSource, contains('if (_country != null) ...['));
      expect(sheetSource, contains('countryCode: _country?.countryCode'));
    },
  );

  test('attractions filter does not apply duration by default', () async {
    final sheetSource = await File(
      'lib/screens/attractions/attractions_filter_sheet.dart',
    ).readAsString();

    expect(
      sheetSource,
      contains('static const _defaultRange = RangeValues(1.0, 12.0);'),
    );
    expect(sheetSource, isNot(contains('RangeValues(2.0, 8.0)')));
  });

  test(
    'filtered city results are not mixed with duplicated must visit cards',
    () async {
      final screenSource = await File(
        'lib/screens/attractions/attractions_screen.dart',
      ).readAsString();

      expect(screenSource, contains('static const int _pageSize = 24;'));
      expect(screenSource, contains('final shouldShowMustVisit ='));
      expect(screenSource, contains('_filters.isEmpty'));
      expect(screenSource, contains('search.isEmpty'));
    },
  );
}
