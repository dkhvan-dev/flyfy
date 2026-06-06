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
    'discover filters default to effective or selected current location city',
    () async {
      final files = {
        'activities': await File(
          'lib/screens/activities/activities_screen.dart',
        ).readAsString(),
        'excursions': await File(
          'lib/screens/excursions/excursions_screen.dart',
        ).readAsString(),
        'attractions': await File(
          'lib/screens/attractions/attractions_screen.dart',
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
        if (entry.key == 'attractions') {
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
    'home location provider resolves profile timezone city into reference city id',
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
    'home location provider receives profile fallback from app bootstrap',
    () async {
      final mainSource = await File('lib/main.dart').readAsString();
      final providerSource = await File(
        'lib/providers/home_location_provider.dart',
      ).readAsString();

      expect(
        mainSource,
        matches(
          RegExp(
            r'ChangeNotifierProxyProvider2<\s*SessionProvider,\s*LocaleProvider,\s*HomeLocationProvider\s*>',
            multiLine: true,
          ),
        ),
      );
      expect(mainSource, contains('setProfileFallback('));
      expect(mainSource, contains('session.profile?.countryCode'));
      expect(mainSource, contains('session.profile?.timezone'));
      expect(
        providerSource,
        contains('static HomeLocationPreference? fromProfile'),
      );
      expect(providerSource, contains('HomeLocationSource.profile'));
    },
  );

  test(
    'discover filters retry default location after provider updates',
    () async {
      final files = {
        'activities': await File(
          'lib/screens/activities/activities_screen.dart',
        ).readAsString(),
        'excursions': await File(
          'lib/screens/excursions/excursions_screen.dart',
        ).readAsString(),
        'attractions': await File(
          'lib/screens/attractions/attractions_screen.dart',
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
          contains('effectiveLocation.source == HomeLocationSource.fallback'),
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
      final attractions = await File(
        'lib/screens/attractions/attractions_filter_sheet.dart',
      ).readAsString();
      final guides = await File(
        'lib/features/guides/data/guide_discovery_api.dart',
      ).readAsString();

      expect(activities, contains('filters.city'));
      expect(activities, contains('item.cityId'));
      expect(activities, contains('item.cityName'));
      expect(excursions, contains('filters.city'));
      expect(excursions, contains('excursion.cityName'));
      expect(attractions, contains('cityId: staged.cityId'));
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
      expect(ruArb, contains('"locationFilterCitySearchHint": "Поиск города"'));
      expect(
        ruArb,
        contains('"locationFilterCityNoResults": "Город не найден"'),
      );
      expect(enArb, contains('"locationFilterCitySection": "City"'));
      expect(enArb, contains('"locationFilterCitySearchHint": "Search city"'));
    },
  );
}
