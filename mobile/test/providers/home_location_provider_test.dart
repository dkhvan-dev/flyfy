import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/device/device_context_service.dart';
import 'package:inflap/core/network/reference_api.dart';
import 'package:inflap/features/profile/models/user_profile_vm.dart';
import 'package:inflap/providers/home_location_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'resolveCityReference adds reference city id to profile fallback city',
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

  test(
    'load prefers silently detected device location over profile fallback',
    () async {
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

      await provider.load(
        profile: UserProfileVm(
          userId: 'user-1',
          status: 'ACTIVE',
          locale: 'ru',
          timezone: 'Asia/Almaty',
          countryCode: 'KZ',
          isProfileCompleted: true,
          roles: const [],
          followersCount: 0,
          isFollowedByMe: false,
          friendshipStatus: UserFriendshipStatus.none,
        ),
      );

      expect(provider.effectiveLocation.source, HomeLocationSource.detected);
      expect(provider.effectiveLocation.countryCode, 'KZ');
      expect(provider.effectiveLocation.cityId, 'astana');
      expect(provider.effectiveLocation.cityName, 'Астана');
      expect(deviceContext.requestPermissionValues, [false]);
      expect(api.queries, ['Astana']);
    },
  );
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
  _FakeDeviceContextService({required this.suggestion});

  final DeviceLocationSuggestion? suggestion;
  final List<bool> requestPermissionValues = [];

  @override
  Future<DeviceLocationSuggestion?> detectLocationSuggestion({
    bool requestPermission = true,
  }) async {
    requestPermissionValues.add(requestPermission);
    return suggestion;
  }
}
