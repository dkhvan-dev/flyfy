import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/screens/places/places_filter_sheet.dart';
import 'package:inflap/shared/widgets/app_city_filter_section.dart';

void main() {
  test('country filter can target a country without selecting a city', () {
    const result = PlaceFilterResult(
      country: AppCountryFilterValue(countryCode: 'vn', countryName: 'Vietnam'),
    );

    expect(result.countryCode, 'VN');
    expect(result.cityId, isNull);
    expect(result.isEmpty, isFalse);
    expect(result.activeCount, 1);
  });

  test('city filter stays scoped to the selected country', () {
    final city = AppCityFilterValue.fromParts(
      cityId: 'da-nang',
      cityName: 'Da Nang',
      countryCode: 'VN',
    );

    final result = PlaceFilterResult(
      country: const AppCountryFilterValue(
        countryCode: 'VN',
        countryName: 'Vietnam',
      ),
      city: city,
    );

    expect(result.countryCode, 'VN');
    expect(result.cityId, 'da-nang');
    expect(result.activeCount, 2);
  });

  test('places filter sheet uses adaptive V2 colors', () async {
    final source = await File(
      'lib/screens/places/places_filter_sheet.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('_placesFilterSheetDecoration('));
    expect(source, contains('AppColors colors'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.surfaceRaised'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
