import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'shared city filter uses reference city search and localized preview',
    () async {
      final source = await File(
        'lib/shared/widgets/app_city_filter_section.dart',
      ).readAsString();

      expect(source, contains('class AppCityFilterSection'));
      expect(source, contains('class AppCityFilterValue'));
      expect(source, contains('ReferenceApi'));
      expect(source, contains('searchCities('));
      expect(source, contains('AppLocalizedLocationText('));
      expect(source, contains('Icons.location_city_rounded'));
    },
  );

  test(
    'shared country and city filters use secondary for neutral location context',
    () async {
      final source = await File(
        'lib/shared/widgets/app_city_filter_section.dart',
      ).readAsString();

      final countryStart = source.indexOf('class AppCountryFilterSection');
      final cityStart = source.indexOf('class AppCityFilterSection');
      final optionRowsStart = source.indexOf('class _CountryOptionRow');

      expect(countryStart, isNonNegative);
      expect(cityStart, greaterThan(countryStart));
      expect(optionRowsStart, greaterThan(cityStart));

      final countrySource = source.substring(countryStart, cityStart);
      final citySource = source.substring(cityStart, optionRowsStart);

      expect(countrySource, contains('Icons.flag_rounded'));
      expect(countrySource, contains('color: colors.secondary'));
      expect(countrySource, contains('colors.borderSecondary'));
      expect(citySource, contains('Icons.location_city_rounded'));
      expect(citySource, contains('color: colors.secondary'));
      expect(citySource, contains('colors.borderSecondary'));
      expect(citySource, contains('color: colors.primary'));
    },
  );

  test(
    'shared country and city filters use compact modal typography',
    () async {
      final source = await File(
        'lib/shared/widgets/app_city_filter_section.dart',
      ).readAsString();

      final countryStart = source.indexOf('class AppCountryFilterSection');
      final cityStart = source.indexOf('class AppCityFilterSection');
      final optionRowsStart = source.indexOf('class _CountryOptionRow');

      expect(countryStart, isNonNegative);
      expect(cityStart, greaterThan(countryStart));
      expect(optionRowsStart, greaterThan(cityStart));

      final countrySource = source.substring(countryStart, cityStart);
      final citySource = source.substring(cityStart, optionRowsStart);

      expect(countrySource, contains('fontSize: 16'));
      expect(citySource, contains('fontSize: 16'));
      expect(countrySource, contains('fontSize: 14'));
      expect(citySource, contains('fontSize: 14'));
      expect(countrySource, contains('const SizedBox(height: 12)'));
      expect(citySource, contains('const SizedBox(height: 12)'));
      expect(countrySource, isNot(contains('fontSize: 19')));
      expect(citySource, isNot(contains('fontSize: 19')));
    },
  );

  test(
    'discover filters default to effective or selected current location city',
    () async {
      final files = {
        'activities': await File(
          'lib/screens/activities/activities_screen.dart',
        ).readAsString(),
        'excursions': await File(
          'lib/screens/excursions/excursions_screen.dart',
        ).readAsString(),
        'places': await File(
          'lib/screens/places/places_screen.dart',
        ).readAsString(),
        'guides': await File(
          'lib/screens/guides/guides_screen.dart',
        ).readAsString(),
      };

      for (final entry in files.entries) {
        expect(
          entry.value,
          contains("import '../../providers/home_location_provider.dart';"),
          reason: entry.key,
        );
        expect(
          entry.value,
          contains('HomeLocationProvider'),
          reason: entry.key,
        );
        expect(entry.value, contains('effectiveLocation'), reason: entry.key);
        expect(
          entry.value,
          isNot(contains('final location = provider.selectedLocation')),
          reason: entry.key,
        );
        if (entry.key == 'places') {
          expect(
            entry.value,
            contains(
              "import '../../shared/widgets/app_city_filter_section.dart';",
            ),
            reason: entry.key,
          );
        } else {
          expect(
            entry.value,
            contains('AppCityFilterSection'),
            reason: entry.key,
          );
        }
        expect(
          entry.value,
          isNot(contains('profile?.countryCode')),
          reason: '${entry.key} must not default filters from profile country',
        );
      }
    },
  );

  test(
    'home location provider resolves raw city into reference city id',
    () async {
      final source = await File(
        'lib/providers/home_location_provider.dart',
      ).readAsString();

      expect(
        source,
        contains('Future<HomeLocationPreference> resolveCityReference('),
      );
      expect(
        source,
        contains('Future<HomeLocationPreference> _resolveCityReference('),
      );
      expect(source, contains('_referenceApi.searchCities('));
      expect(source, contains('cityId: matchedCity.id.trim()'));
    },
  );

  test(
    'home location provider is independent from profile country and timezone',
    () async {
      final mainSource = await File('lib/main.dart').readAsString();
      final providerSource = await File(
        'lib/providers/home_location_provider.dart',
      ).readAsString();

      expect(
        mainSource,
        contains(
          'ChangeNotifierProvider(create: (_) => HomeLocationProvider())',
        ),
      );
      expect(mainSource, isNot(contains('setProfileFallback(')));
      expect(mainSource, isNot(contains('session.profile?.countryCode')));
      expect(mainSource, isNot(contains('session.profile?.timezone')));
      expect(
        providerSource,
        isNot(contains('static HomeLocationPreference? fromProfile')),
      );
      expect(providerSource, isNot(contains('_profileFallbackLocation')));
    },
  );

  test(
    'discover filters retry default location after provider updates including fallback',
    () async {
      final files = {
        'activities': await File(
          'lib/screens/activities/activities_screen.dart',
        ).readAsString(),
        'excursions': await File(
          'lib/screens/excursions/excursions_screen.dart',
        ).readAsString(),
        'places': await File(
          'lib/screens/places/places_screen.dart',
        ).readAsString(),
        'guides': await File(
          'lib/screens/guides/guides_screen.dart',
        ).readAsString(),
      };

      for (final entry in files.entries) {
        expect(
          entry.value,
          contains('context.watch<HomeLocationProvider>()'),
          reason: entry.key,
        );
        expect(
          entry.value,
          contains('WidgetsBinding.instance.addPostFrameCallback'),
          reason: entry.key,
        );
        expect(
          entry.value,
          isNot(
            contains('effectiveLocation.source == HomeLocationSource.fallback'),
          ),
          reason: entry.key,
        );
      }
    },
  );

  test(
    'discover filters carry city id and city name to local or remote filters',
    () async {
      final activities = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();
      final excursions = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();
      final places = await File(
        'lib/screens/places/places_filter_sheet.dart',
      ).readAsString();
      final guides = await File(
        'lib/features/guides/data/guide_discovery_api.dart',
      ).readAsString();

      expect(activities, contains('filters.city'));
      expect(activities, contains('item.cityId'));
      expect(activities, contains('item.cityName'));
      expect(excursions, contains('filters.city'));
      expect(excursions, contains('excursion.cityName'));
      expect(places, contains('cityId: staged.cityId'));
      expect(guides, contains('String? cityId'));
      expect(guides, contains("queryParameters['cityId']"));
      expect(guides, contains("queryParameters['cityName']"));
      expect(guides, contains("queryParameters['cityCountryCode']"));
    },
  );

  test(
    'city filter localization replaces country wording in discover sheets',
    () async {
      final ruArb = await File('lib/l10n/app_ru.arb').readAsString();
      final enArb = await File('lib/l10n/app_en.arb').readAsString();

      expect(ruArb, contains('"locationFilterCitySection": "Город"'));
      expect(ruArb, contains('"locationFilterCitySearchHint": "Город"'));
      expect(
        ruArb,
        contains('"locationFilterCityNoResults": "Город не найден"'),
      );
      expect(enArb, contains('"locationFilterCitySection": "City"'));
      expect(enArb, contains('"locationFilterCitySearchHint": "City"'));
    },
  );
}
