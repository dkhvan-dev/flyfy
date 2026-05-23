import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('attractions filter starts with localized searchable city filter',
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
    expect(sheetSource, contains('final AppCityFilterValue? city'));
    expect(sheetSource, contains('String? get cityId => city?.cityId'));
    expect(sheetSource, contains('city == null ? 0 : 1'));
    expect(sheetSource, contains('AppCityFilterSection'));
    expect(sheetSource, contains('locationFilterCitySection'));
    expect(sheetSource, contains('locationFilterCitySearchHint'));
    expect(sheetSource, contains('locationFilterCityNoResults'));
    expect(sheetSource, contains('cityId: staged.cityId'));
    expect(sheetSource, isNot(contains('country_filter_utils.dart')));
    expect(sheetSource, isNot(contains('List<ReferenceCountry> countries')));

    final citySectionStart = sheetSource.indexOf('AppCityFilterSection(');
    final categorySectionStart = sheetSource.indexOf(
      'header: l10n.attractionFilterCategoriesSection',
    );
    expect(citySectionStart, isNonNegative);
    expect(categorySectionStart, greaterThan(citySectionStart));

    final citySection = sheetSource.substring(
      citySectionStart,
      categorySectionStart,
    );
    expect(citySection, contains('AppCityFilterSection'));
    expect(citySection, isNot(contains('Wrap(')));

    expect(screenSource,
        contains("import '../../providers/home_location_provider.dart';"));
    expect(
      screenSource,
      contains("import '../../shared/widgets/app_city_filter_section.dart';"),
    );
    expect(screenSource, contains('HomeLocationProvider'));
    expect(screenSource, contains('selectedLocation'));
    expect(screenSource, contains('_initializeDefaultCityFilter'));
    expect(screenSource, contains('_applyDefaultCityFilter'));
    expect(screenSource, contains('cityId: _filters.cityId'));
    expect(screenSource, contains('countryCode: _filters.countryCode'));
    expect(screenSource, isNot(contains('profile?.countryCode')));
  });
}
