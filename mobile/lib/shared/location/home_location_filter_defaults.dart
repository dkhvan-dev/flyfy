import '../../providers/home_location_provider.dart';
import '../widgets/app_city_filter_section.dart';

class HomeLocationFilterDefaults {
  const HomeLocationFilterDefaults({this.country, this.city});

  final AppCountryFilterValue? country;
  final AppCityFilterValue? city;

  bool get hasValue => country != null || city != null;

  static const empty = HomeLocationFilterDefaults();

  factory HomeLocationFilterDefaults.fromPreference(
    HomeLocationPreference location,
  ) {
    final country = AppCountryFilterValue.fromParts(
      countryCode: location.countryCode,
    );
    final city = AppCityFilterValue.fromParts(
      cityId: location.cityId,
      cityName: location.cityName,
      countryCode: location.countryCode,
    );

    if (country == null && city == null) {
      return empty;
    }

    return HomeLocationFilterDefaults(country: country, city: city);
  }
}
