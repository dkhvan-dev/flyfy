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
          source: HomeLocationSource.profile,
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
    'load uses profile fallback when device location is unavailable',
    () async {
      SharedPreferences.setMockInitialValues({});
      final api = _FakeReferenceApi(
        cities: const [
          ReferenceCity(id: 'almaty', countryCode: 'KZ', name: 'Алматы'),
        ],
      );
      final provider = HomeLocationProvider(
        referenceApi: api,
        deviceContextService: _FakeDeviceContextService(suggestion: null),
      );

      await provider.load(
        languageCode: 'ru',
        profileFallback: HomeLocationPreference.fromProfile(
          countryCode: 'KZ',
          timezone: 'Asia/Almaty',
        ),
      );

      expect(provider.effectiveLocation.source, HomeLocationSource.profile);
      expect(provider.effectiveLocation.countryCode, 'KZ');
      expect(provider.effectiveLocation.cityId, 'almaty');
      expect(provider.effectiveLocation.cityName, 'Алматы');
      expect(api.queries, ['Almaty']);
      expect(api.countryCodes, ['KZ']);
    },
  );

  test('load prefers device timezone before profile fallback', () async {
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

    await provider.load(
      languageCode: 'ru',
      profileFallback: HomeLocationPreference.fromProfile(
        countryCode: 'KZ',
        timezone: 'Asia/Almaty',
      ),
    );

    expect(provider.effectiveLocation.source, HomeLocationSource.detected);
    expect(provider.effectiveLocation.countryCode, 'KG');
    expect(provider.effectiveLocation.cityId, 'bishkek');
    expect(provider.effectiveLocation.cityName, 'Бишкек');
    expect(api.queries, ['Bishkek']);
    expect(api.countryCodes, [null]);
  });

  test('load ignores stored profile-derived location preference', () async {
    SharedPreferences.setMockInitialValues({
      HomeLocationProvider.storageKey: jsonEncode({
        'source': HomeLocationSource.profile.name,
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
    'clearSelection falls back to profile location before neutral fallback',
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
        deviceContextService: _FakeDeviceContextService(suggestion: null),
      );
      await provider.load(
        languageCode: 'ru',
        profileFallback: HomeLocationPreference.fromProfile(
          countryCode: 'KZ',
          timezone: 'Asia/Almaty',
        ),
      );

      await provider.clearSelection(languageCode: 'ru');

      expect(provider.effectiveLocation.source, HomeLocationSource.profile);
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
}

class _FakeReferenceApi extends ReferenceApi {
  _FakeReferenceApi({required this.cities});

  final List<ReferenceCity> cities;
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
}

class _FakeDeviceContextService extends DeviceContextService {
  _FakeDeviceContextService({required this.suggestion, this.timezone});

  final DeviceLocationSuggestion? suggestion;
  final String? timezone;
  final List<bool> requestPermissionValues = [];

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
