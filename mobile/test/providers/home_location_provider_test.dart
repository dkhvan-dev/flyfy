import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/device/device_context_service.dart';
import 'package:inflap/core/network/reference_api.dart';
import 'package:inflap/providers/home_location_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'resolveCityReference adds reference city id to raw city name',
    () async {
      final api = _FakeReferenceApi(
        cities: const [
          ReferenceCity(id: 'almaty', countryCode: 'KZ', name: 'Алматы'),
        ],
      );
      final provider = HomeLocationProvider(referenceApi: api);

      final resolved = await provider.resolveCityReference(
        HomeLocationPreference(
          source: HomeLocationSource.detected,
          countryCode: 'KZ',
          cityName: 'Almaty',
          updatedAt: DateTime.utc(2026, 6, 3),
        ),
        languageCode: 'ru',
      );

      expect(resolved.countryCode, 'KZ');
      expect(resolved.cityId, 'almaty');
      expect(resolved.cityName, 'Алматы');
      expect(api.queries, ['Almaty']);
      expect(api.countryCodes, ['KZ']);
      expect(api.languages, ['ru']);
    },
  );

  test('load prefers silently detected device location', () async {
    SharedPreferences.setMockInitialValues({});
    final api = _FakeReferenceApi(
      cities: const [
        ReferenceCity(id: 'astana', countryCode: 'KZ', name: 'Астана'),
      ],
    );
    final deviceContext = _FakeDeviceContextService(
      suggestion: DeviceLocationSuggestion(
        countryCode: 'KZ',
        countryName: 'Kazakhstan',
        cityName: 'Astana',
        latitude: 51.1605,
        longitude: 71.4704,
      ),
    );
    final provider = HomeLocationProvider(
      referenceApi: api,
      deviceContextService: deviceContext,
    );

    await provider.load(languageCode: 'ru');

    expect(provider.effectiveLocation.source, HomeLocationSource.detected);
    expect(provider.effectiveLocation.countryCode, 'KZ');
    expect(provider.effectiveLocation.cityId, 'astana');
    expect(provider.effectiveLocation.cityName, 'Астана');
    expect(deviceContext.requestPermissionValues, [false]);
    expect(api.queries, ['Astana']);
    expect(api.languages, ['ru']);
  });

  test(
    'load uses neutral fallback when device location is unavailable',
    () async {
      SharedPreferences.setMockInitialValues({});
      final api = _FakeReferenceApi(cities: const []);
      final deviceContext = _FakeDeviceContextService(suggestion: null);
      final provider = HomeLocationProvider(
        referenceApi: api,
        deviceContextService: deviceContext,
      );

      await provider.load();

      expect(provider.effectiveLocation.source, HomeLocationSource.fallback);
      expect(provider.effectiveLocation.countryCode, 'KZ');
      expect(provider.effectiveLocation.cityName, 'Almaty');
      expect(deviceContext.requestPermissionValues, [false]);
      expect(api.queries, ['Almaty']);
      expect(api.countryCodes, ['KZ']);
    },
  );

  test('load waits for an in-flight location detection', () async {
    SharedPreferences.setMockInitialValues({});
    final api = _FakeReferenceApi(
      cities: const [
        ReferenceCity(id: 'astana', countryCode: 'KZ', name: 'Астана'),
      ],
    );
    final deviceContext = _CompleterDeviceContextService();
    final provider = HomeLocationProvider(
      referenceApi: api,
      deviceContextService: deviceContext,
    );

    final firstLoad = provider.load(languageCode: 'ru');
    await Future<void>.delayed(Duration.zero);

    var secondLoadCompleted = false;
    final secondLoad = provider
        .load(languageCode: 'ru')
        .then((_) => secondLoadCompleted = true);
    await Future<void>.delayed(Duration.zero);

    expect(secondLoadCompleted, isFalse);
    expect(deviceContext.requestPermissionValues, [false]);

    deviceContext.complete(
      DeviceLocationSuggestion(
        countryCode: 'KZ',
        countryName: 'Kazakhstan',
        cityName: 'Astana',
        latitude: 51.1605,
        longitude: 71.4704,
      ),
    );

    await firstLoad;
    await secondLoad;

    expect(secondLoadCompleted, isTrue);
    expect(provider.effectiveLocation.source, HomeLocationSource.detected);
    expect(provider.effectiveLocation.cityId, 'astana');
    expect(provider.effectiveLocation.cityName, 'Астана');
  });

  test(
    'load falls back to device timezone when GPS city is unavailable',
    () async {
      SharedPreferences.setMockInitialValues({});
      final api = _FakeReferenceApi(
        cities: const [
          ReferenceCity(id: 'bishkek', countryCode: 'KG', name: 'Бишкек'),
        ],
      );
      final provider = HomeLocationProvider(
        referenceApi: api,
        deviceContextService: _FakeDeviceContextService(
          suggestion: null,
          timezone: 'Asia/Bishkek',
        ),
      );

      await provider.load(languageCode: 'ru');

      expect(provider.effectiveLocation.source, HomeLocationSource.detected);
      expect(provider.effectiveLocation.timezone, 'Asia/Bishkek');
      expect(provider.effectiveLocation.countryCode, 'KG');
      expect(provider.effectiveLocation.cityId, 'bishkek');
      expect(provider.effectiveLocation.cityName, 'Бишкек');
      expect(api.queries, ['Bishkek']);
      expect(api.countryCodes, [null]);
    },
  );

  test(
    'load prefers saved home screen location before detected device location',
    () async {
      SharedPreferences.setMockInitialValues({
        HomeLocationProvider.storageKey: jsonEncode({
          'source': HomeLocationSource.manual.name,
          'countryCode': 'UZ',
          'cityId': 'tashkent',
          'cityName': 'Tashkent',
          'updatedAt': DateTime.utc(2026, 6, 8).toIso8601String(),
        }),
      });
      final api = _FakeReferenceApi(cities: const []);
      final deviceContext = _FakeDeviceContextService(
        suggestion: DeviceLocationSuggestion(
          countryCode: 'KG',
          countryName: 'Kyrgyzstan',
          cityName: 'Bishkek',
          latitude: 42.8746,
          longitude: 74.5698,
        ),
      );
      final provider = HomeLocationProvider(
        referenceApi: api,
        deviceContextService: deviceContext,
      );

      await provider.load(languageCode: 'ru');

      expect(provider.effectiveLocation.source, HomeLocationSource.manual);
      expect(provider.effectiveLocation.countryCode, 'UZ');
      expect(provider.effectiveLocation.cityId, 'tashkent');
      expect(provider.effectiveLocation.cityName, 'Tashkent');
      expect(deviceContext.requestPermissionValues, isEmpty);
      expect(api.queries, isEmpty);
    },
  );

  test('load ignores stored profile-derived location preference', () async {
    SharedPreferences.setMockInitialValues({
      HomeLocationProvider.storageKey: jsonEncode({
        'source': 'profile',
        'countryCode': 'VN',
        'cityName': 'Bishkek',
        'updatedAt': DateTime.utc(2026, 6, 3).toIso8601String(),
      }),
    });
    final api = _FakeReferenceApi(cities: const []);
    final provider = HomeLocationProvider(
      referenceApi: api,
      deviceContextService: _FakeDeviceContextService(suggestion: null),
    );

    await provider.load();

    expect(provider.effectiveLocation.source, HomeLocationSource.fallback);
    expect(provider.effectiveLocation.countryCode, 'KZ');
    expect(provider.effectiveLocation.cityName, 'Almaty');
    expect(api.queries, ['Almaty']);
  });

  test(
    'clearSelection falls back to device timezone before neutral fallback',
    () async {
      SharedPreferences.setMockInitialValues({
        HomeLocationProvider.storageKey: jsonEncode({
          'source': HomeLocationSource.manual.name,
          'countryCode': 'KG',
          'cityName': 'Bishkek',
          'updatedAt': DateTime.utc(2026, 6, 3).toIso8601String(),
        }),
      });
      final api = _FakeReferenceApi(
        cities: const [
          ReferenceCity(id: 'almaty', countryCode: 'KZ', name: 'Алматы'),
        ],
      );
      final provider = HomeLocationProvider(
        referenceApi: api,
        deviceContextService: _FakeDeviceContextService(
          suggestion: null,
          timezone: 'Asia/Almaty',
        ),
      );
      await provider.load(languageCode: 'ru');

      await provider.clearSelection(languageCode: 'ru');

      expect(provider.effectiveLocation.source, HomeLocationSource.detected);
      expect(provider.effectiveLocation.timezone, 'Asia/Almaty');
      expect(provider.effectiveLocation.countryCode, 'KZ');
      expect(provider.effectiveLocation.cityId, 'almaty');
      expect(provider.effectiveLocation.cityName, 'Алматы');
    },
  );

  test('load uses requested language for device location lookup', () async {
    SharedPreferences.setMockInitialValues({});
    final api = _FakeReferenceApi(
      cities: const [
        ReferenceCity(id: 'almaty', countryCode: 'KZ', name: 'Алматы'),
      ],
    );
    final provider = HomeLocationProvider(
      referenceApi: api,
      deviceContextService: _FakeDeviceContextService(
        suggestion: DeviceLocationSuggestion(
          countryCode: 'KZ',
          countryName: 'Kazakhstan',
          cityName: 'Almaty',
          latitude: 43.2389,
          longitude: 76.8897,
        ),
      ),
    );

    await provider.load(languageCode: 'ru');

    expect(provider.effectiveLocation.source, HomeLocationSource.detected);
    expect(provider.effectiveLocation.cityId, 'almaty');
    expect(provider.effectiveLocation.cityName, 'Алматы');
    expect(api.queries, ['Almaty']);
    expect(api.languages, ['ru']);
  });

  test(
    'initial location permission is requested once and updates location',
    () async {
      SharedPreferences.setMockInitialValues({});
      final api = _FakeReferenceApi(
        cities: const [
          ReferenceCity(id: 'astana', countryCode: 'KZ', name: 'Astana'),
        ],
      );
      final deviceContext = _FakeDeviceContextService(
        suggestion: DeviceLocationSuggestion(
          countryCode: 'KZ',
          countryName: 'Kazakhstan',
          cityName: 'Astana',
          latitude: 51.1605,
          longitude: 71.4704,
        ),
      );
      final provider = HomeLocationProvider(
        referenceApi: api,
        deviceContextService: deviceContext,
      );

      await provider.requestInitialLocationPermission(languageCode: 'en');
      await provider.requestInitialLocationPermission(languageCode: 'en');

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(HomeLocationProvider.initialPermissionRequestStorageKey),
        isTrue,
      );
      expect(deviceContext.locationPermissionRequestCount, 1);
      expect(deviceContext.requestPermissionValues, [false]);
      expect(provider.effectiveLocation.source, HomeLocationSource.detected);
      expect(provider.effectiveLocation.cityId, 'astana');
      expect(provider.effectiveLocation.cityName, 'Astana');
    },
  );

  test('denied initial location permission is not requested again', () async {
    SharedPreferences.setMockInitialValues({});
    final deviceContext = _FakeDeviceContextService(
      suggestion: null,
      locationPermissionGranted: false,
    );
    final provider = HomeLocationProvider(
      referenceApi: _FakeReferenceApi(cities: const []),
      deviceContextService: deviceContext,
    );

    await provider.requestInitialLocationPermission(languageCode: 'en');
    await provider.requestInitialLocationPermission(languageCode: 'en');

    expect(deviceContext.locationPermissionRequestCount, 1);
    expect(deviceContext.requestPermissionValues, isEmpty);
    expect(provider.effectiveLocation.source, HomeLocationSource.fallback);
  });

  test('a transient location permission failure can be retried', () async {
    SharedPreferences.setMockInitialValues({});
    final deviceContext = _FakeDeviceContextService(
      suggestion: null,
      locationPermissionFailuresRemaining: 1,
    );
    final provider = HomeLocationProvider(
      referenceApi: _FakeReferenceApi(cities: const []),
      deviceContextService: deviceContext,
    );

    await provider.requestInitialLocationPermission(languageCode: 'en');

    var preferences = await SharedPreferences.getInstance();
    expect(deviceContext.locationPermissionRequestCount, 1);
    expect(
      preferences.getBool(
        HomeLocationProvider.initialPermissionRequestStorageKey,
      ),
      isNull,
    );

    await provider.requestInitialLocationPermission(languageCode: 'en');

    preferences = await SharedPreferences.getInstance();
    expect(deviceContext.locationPermissionRequestCount, 2);
    expect(
      preferences.getBool(
        HomeLocationProvider.initialPermissionRequestStorageKey,
      ),
      isTrue,
    );
  });

  test(
    'initial location detection preserves a manually selected city',
    () async {
      SharedPreferences.setMockInitialValues({
        HomeLocationProvider.storageKey: jsonEncode({
          'source': HomeLocationSource.manual.name,
          'countryCode': 'UZ',
          'cityId': 'tashkent',
          'cityName': 'Tashkent',
          'updatedAt': DateTime.utc(2026, 7, 11).toIso8601String(),
        }),
      });
      final deviceContext = _FakeDeviceContextService(
        suggestion: DeviceLocationSuggestion(
          countryCode: 'KZ',
          countryName: 'Kazakhstan',
          cityName: 'Almaty',
          latitude: 43.2389,
          longitude: 76.8897,
        ),
      );
      final provider = HomeLocationProvider(
        referenceApi: _FakeReferenceApi(cities: const []),
        deviceContextService: deviceContext,
      );

      await provider.requestInitialLocationPermission(languageCode: 'en');

      expect(deviceContext.locationPermissionRequestCount, 1);
      expect(deviceContext.requestPermissionValues, isEmpty);
      expect(provider.effectiveLocation.source, HomeLocationSource.manual);
      expect(provider.effectiveLocation.cityId, 'tashkent');
      expect(provider.effectiveLocation.cityName, 'Tashkent');
    },
  );
}

class _FakeReferenceApi extends ReferenceApi {
  _FakeReferenceApi({required this.cities});

  final List<ReferenceCity> cities;
  final List<ReferenceTimezone> timezones = const [
    ReferenceTimezone(id: 'Asia/Almaty', name: 'Алматы'),
    ReferenceTimezone(id: 'Asia/Bishkek', name: 'Бишкек'),
  ];
  final List<String> queries = [];
  final List<String?> countryCodes = [];
  final List<String> languages = [];

  @override
  Future<List<ReferenceCity>> searchCities(
    String query, {
    String? countryCode,
    String lang = 'en',
    int limit = 10,
  }) async {
    queries.add(query);
    countryCodes.add(countryCode);
    languages.add(lang);
    return cities;
  }

  @override
  Future<List<ReferenceTimezone>> listTimezones({String lang = 'en'}) async {
    return timezones;
  }
}

class _FakeDeviceContextService extends DeviceContextService {
  _FakeDeviceContextService({
    required this.suggestion,
    this.timezone,
    this.locationPermissionGranted = true,
    this.locationPermissionFailuresRemaining = 0,
  });

  final DeviceLocationSuggestion? suggestion;
  final String? timezone;
  final bool locationPermissionGranted;
  int locationPermissionFailuresRemaining;
  final List<bool> requestPermissionValues = [];
  int locationPermissionRequestCount = 0;

  @override
  Future<bool> requestLocationPermission() async {
    locationPermissionRequestCount += 1;
    if (locationPermissionFailuresRemaining > 0) {
      locationPermissionFailuresRemaining -= 1;
      throw StateError('location_service_unavailable');
    }
    return locationPermissionGranted;
  }

  @override
  Future<DeviceLocationSuggestion?> detectLocationSuggestion({
    bool requestPermission = true,
  }) async {
    requestPermissionValues.add(requestPermission);
    return suggestion;
  }

  @override
  Future<String?> getLocalTimezone() async => timezone;
}

class _CompleterDeviceContextService extends DeviceContextService {
  final Completer<DeviceLocationSuggestion?> _completer =
      Completer<DeviceLocationSuggestion?>();
  final List<bool> requestPermissionValues = [];

  void complete(DeviceLocationSuggestion? suggestion) {
    _completer.complete(suggestion);
  }

  @override
  Future<DeviceLocationSuggestion?> detectLocationSuggestion({
    bool requestPermission = true,
  }) async {
    requestPermissionValues.add(requestPermission);
    return _completer.future;
  }
}
