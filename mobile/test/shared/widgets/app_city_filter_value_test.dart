import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/shared/widgets/app_city_filter_section.dart';

void main() {
  test('city filter matches legacy city names by selected reference id', () {
    const selected = AppCityFilterValue(
      cityId: 'almaty',
      cityName: 'Алматы',
      countryCode: 'KZ',
    );

    expect(
      selected.matches(cityName: 'Almaty', countryCode: 'KZ'),
      isTrue,
    );
  });

  test('city filter matches new departure city ids directly', () {
    const selected = AppCityFilterValue(
      cityId: 'almaty',
      cityName: 'Алматы',
      countryCode: 'KZ',
    );

    expect(
      selected.matches(cityId: 'almaty', cityName: 'Almaty', countryCode: 'KZ'),
      isTrue,
    );
  });
}
