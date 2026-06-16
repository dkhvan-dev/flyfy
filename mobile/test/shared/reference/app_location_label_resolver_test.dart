import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/reference_api.dart';
import 'package:inflap/shared/reference/app_location_label_resolver.dart';

void main() {
  test('resolves city and country to localized display names', () async {
    final resolver = AppLocationLabelResolver(
      countryLookup: (code, {required lang}) async {
        expect(code, 'KZ');
        expect(lang, 'ru');
        return const ReferenceCountry(code: 'KZ', name: 'Казахстан');
      },
      cityLookup: (id, {required lang}) async {
        expect(id, 'almaty');
        expect(lang, 'ru');
        return const ReferenceCity(
          id: 'almaty',
          countryCode: 'KZ',
          name: 'Алматы',
        );
      },
    );

    final label = await resolver.resolve(
      countryCode: 'KZ',
      cityId: 'almaty',
      cityName: 'Almaty',
      localeName: 'ru',
    );

    expect(label, 'Алматы, Казахстан');
  });

  test('does not fall back to country code as a display label', () async {
    final resolver = AppLocationLabelResolver(
      countryLookup: (_, {required lang}) async => null,
      cityLookup: (_, {required lang}) async => null,
      citySearchLookup:
          (_, {required lang, String? countryCode, int limit = 10}) async =>
              const [],
    );

    final label = await resolver.resolve(
      countryCode: 'KZ',
      cityName: 'Almaty',
      localeName: 'ru',
    );

    expect(label, 'Almaty');
  });

  test('localizes legacy city name when city id is missing', () async {
    final resolver = AppLocationLabelResolver(
      countryLookup: (code, {required lang}) async {
        expect(code, 'KZ');
        expect(lang, 'ru');
        return const ReferenceCountry(code: 'KZ', name: 'Казахстан');
      },
      cityLookup: (_, {required lang}) async => null,
      citySearchLookup:
          (query, {required lang, String? countryCode, int limit = 10}) async {
            expect(query, 'Almaty');
            expect(countryCode, 'KZ');
            expect(lang, 'ru');
            expect(limit, 5);
            return const [
              ReferenceCity(id: 'almaty', countryCode: 'KZ', name: 'Алматы'),
            ];
          },
    );

    final label = await resolver.resolve(
      countryCode: 'KZ',
      cityName: 'Almaty',
      localeName: 'ru',
    );

    expect(label, 'Алматы, Казахстан');
  });

  test(
    'falls back to country city catalog when direct city lookup fails',
    () async {
      final resolver = AppLocationLabelResolver(
        countryLookup: (code, {required lang}) async {
          expect(code, 'KZ');
          expect(lang, 'ru');
          return const ReferenceCountry(code: 'KZ', name: 'Казахстан');
        },
        cityLookup: (_, {required lang}) async => null,
        citySearchLookup:
            (_, {required lang, String? countryCode, int limit = 10}) async =>
                const [],
        citiesByCountryLookup: (countryCode, {required lang}) async {
          expect(countryCode, 'KZ');
          expect(lang, 'ru');
          return const [
            ReferenceCity(id: 'almaty', countryCode: 'KZ', name: 'Алматы'),
          ];
        },
      );

      final label = await resolver.resolve(
        countryCode: 'KZ',
        cityId: 'almaty',
        cityName: 'Almaty',
        localeName: 'ru',
      );

      expect(label, 'Алматы, Казахстан');
    },
  );

  test('shares in-flight country city catalog lookup', () async {
    var catalogCalls = 0;
    final catalogCompleter = Completer<List<ReferenceCity>>();
    final resolver = AppLocationLabelResolver(
      countryLookup: (_, {required lang}) async =>
          const ReferenceCountry(code: 'KZ', name: 'Казахстан'),
      cityLookup: (_, {required lang}) async => null,
      citySearchLookup:
          (_, {required lang, String? countryCode, int limit = 10}) async =>
              const [],
      citiesByCountryLookup: (_, {required lang}) {
        catalogCalls += 1;
        return catalogCompleter.future;
      },
    );

    final first = resolver.resolve(
      countryCode: 'KZ',
      cityId: 'almaty',
      cityName: 'Almaty',
      localeName: 'ru',
    );
    final second = resolver.resolve(
      countryCode: 'KZ',
      cityId: 'almaty',
      cityName: 'Almaty',
      localeName: 'ru',
    );
    await Future<void>.delayed(Duration.zero);

    expect(catalogCalls, 1);

    catalogCompleter.complete(const [
      ReferenceCity(id: 'almaty', countryCode: 'KZ', name: 'Алматы'),
    ]);

    expect(await Future.wait([first, second]), [
      'Алматы, Казахстан',
      'Алматы, Казахстан',
    ]);
  });

  test(
    'localizes address city and country with country city catalog fallback',
    () async {
      final resolver = AppLocationLabelResolver(
        countryLookup: (_, {required lang}) async =>
            const ReferenceCountry(code: 'KZ', name: 'Казахстан'),
        cityLookup: (_, {required lang}) async => null,
        citySearchLookup:
            (_, {required lang, String? countryCode, int limit = 10}) async =>
                const [],
        citiesByCountryLookup: (_, {required lang}) async => const [
          ReferenceCity(id: 'almaty', countryCode: 'KZ', name: 'Алматы'),
        ],
      );

      final label = await resolver.resolveAddress(
        countryCode: 'KZ',
        cityId: 'almaty',
        cityName: 'Almaty',
        addressText: 'Almaty, Kazakhstan, Bayzakova 127',
        localeName: 'ru',
      );

      expect(label, 'Алматы, Казахстан, Bayzakova 127');
    },
  );

  test(
    'does not duplicate localized city and country already present in address',
    () async {
      final resolver = AppLocationLabelResolver(
        countryLookup: (_, {required lang}) async =>
            const ReferenceCountry(code: 'KZ', name: 'Казахстан'),
        cityLookup: (_, {required lang}) async => const ReferenceCity(
          id: 'almaty',
          countryCode: 'KZ',
          name: 'Алматы',
        ),
      );

      final label = await resolver.resolveAddress(
        countryCode: 'KZ',
        cityId: 'almaty',
        cityName: 'Алматы',
        addressText: 'Алматы, Казахстан, Байзакова 127',
        localeName: 'ru',
      );

      expect(label, 'Алматы, Казахстан, Байзакова 127');
    },
  );

  test('formats map-picked address with city and country first', () {
    final label = formatLocationAddressLabel(
      city: 'Алматы',
      country: 'Казахстан',
      address: 'проспект Абая, 10',
    );

    expect(label, 'Алматы, Казахстан, проспект Абая, 10');
  });
}
