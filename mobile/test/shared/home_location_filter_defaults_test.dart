import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/providers/home_location_provider.dart';
import 'package:inflap/shared/location/home_location_filter_defaults.dart';

void main() {
  test('uses home screen location as default country and city filters', () {
    final filters = HomeLocationFilterDefaults.fromPreference(
      HomeLocationPreference(
        source: HomeLocationSource.manual,
        countryCode: 'kg',
        cityId: 'bishkek',
        cityName: 'Бишкек',
        updatedAt: DateTime.utc(2026, 6, 8),
      ),
    );

    expect(filters.hasValue, isTrue);
    expect(filters.country?.countryCode, 'KG');
    expect(filters.city?.cityId, 'bishkek');
    expect(filters.city?.cityName, 'Бишкек');
    expect(filters.city?.countryCode, 'KG');
  });

  test('uses the visible app fallback as a default filter', () {
    final filters = HomeLocationFilterDefaults.fromPreference(
      HomeLocationPreference.fallback(),
    );

    expect(filters.hasValue, isTrue);
    expect(filters.country?.countryCode, 'KZ');
    expect(filters.city?.cityName, 'Almaty');
    expect(filters.city?.countryCode, 'KZ');
  });

  test('keeps city-only location when country reference is unavailable', () {
    final filters = HomeLocationFilterDefaults.fromPreference(
      HomeLocationPreference(
        source: HomeLocationSource.detected,
        cityName: 'Tbilisi',
        updatedAt: DateTime.utc(2026, 6, 8),
      ),
    );

    expect(filters.hasValue, isTrue);
    expect(filters.country, isNull);
    expect(filters.city?.cityName, 'Tbilisi');
    expect(filters.city?.countryCode, isNull);
  });
}
