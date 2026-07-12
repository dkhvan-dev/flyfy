import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/device/device_context_service.dart';
import '../core/network/reference_api.dart';
import '../core/reference/timezone_filter_utils.dart';

enum HomeLocationSource { manual, detected, fallback }

class HomeLocationPreference {
  const HomeLocationPreference({
    required this.source,
    this.countryCode,
    this.cityId,
    this.cityName,
    this.timezone,
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  final HomeLocationSource source;
  final String? countryCode;
  final String? cityId;
  final String? cityName;
  final String? timezone;
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;

  bool get isUserSelected =>
      source == HomeLocationSource.manual ||
      source == HomeLocationSource.detected;

  String get fallbackLabel {
    final city = (cityName ?? '').trim();
    final country = (countryCode ?? '').trim();
    if (city.isNotEmpty) return city;
    if (country.isNotEmpty) return country;
    return 'Almaty';
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source.name,
      'countryCode': countryCode,
      'cityId': cityId,
      'cityName': cityName,
      'timezone': timezone,
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory HomeLocationPreference.fromJson(Map<String, dynamic> json) {
    final rawSource = json['source']?.toString();
    final source = HomeLocationSource.values.firstWhere(
      (item) => item.name == rawSource,
      orElse: () => HomeLocationSource.fallback,
    );
    return HomeLocationPreference(
      source: source,
      countryCode: _nullableText(json['countryCode']),
      cityId: _nullableText(json['cityId']),
      cityName: _nullableText(json['cityName']),
      timezone: normalizeReferenceTimezoneId(json['timezone']?.toString()),
      latitude: _nullableDouble(json['latitude']),
      longitude: _nullableDouble(json['longitude']),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  static HomeLocationPreference fallback() {
    return HomeLocationPreference(
      source: HomeLocationSource.fallback,
      countryCode: 'KZ',
      cityName: 'Almaty',
      timezone: 'Asia/Almaty',
      updatedAt: DateTime.now().toUtc(),
    );
  }

  static HomeLocationPreference? fromDeviceTimezone(String? timezone) {
    final normalizedTimezone = normalizeReferenceTimezoneId(timezone);
    final cityName = _cityNameFromTimezone(normalizedTimezone);
    if (cityName == null) return null;

    return HomeLocationPreference(
      source: HomeLocationSource.detected,
      cityName: cityName,
      timezone: normalizedTimezone,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}

class HomeLocationProvider extends ChangeNotifier {
  HomeLocationProvider({
    ReferenceApi? referenceApi,
    DeviceContextService? deviceContextService,
  }) : _referenceApi = referenceApi ?? ReferenceApi(),
       _deviceContextService =
           deviceContextService ?? const DeviceContextService();

  static const storageKey = 'inflap_home_location_preference';
  static const initialPermissionRequestStorageKey =
      'inflap_initial_location_permission_requested';

  final ReferenceApi _referenceApi;
  final DeviceContextService _deviceContextService;

  HomeLocationPreference? _selectedLocation;
  HomeLocationPreference _effectiveLocation = HomeLocationPreference.fallback();
  Future<void>? _loadFuture;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _isDetecting = false;
  bool _isInitialPermissionRequestInFlight = false;
  String? _errorMessage;

  HomeLocationPreference? get selectedLocation => _selectedLocation;
  HomeLocationPreference get effectiveLocation => _effectiveLocation;
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  bool get isDetecting => _isDetecting;
  String? get errorMessage => _errorMessage;

  Future<void> load({String languageCode = 'en'}) {
    final currentLoad = _loadFuture;
    if (currentLoad != null) return currentLoad;

    final nextLoad = _load(languageCode: languageCode);
    _loadFuture = nextLoad.whenComplete(() => _loadFuture = null);
    return _loadFuture!;
  }

  Future<void> _load({required String languageCode}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      _selectedLocation = _decodeSelectedLocation(raw);
      final deviceLocation = _selectedLocation == null
          ? await _detectDeviceLocationPreference(
              languageCode: languageCode,
              requestPermission: false,
            )
          : null;
      _effectiveLocation =
          _selectedLocation ??
          deviceLocation ??
          HomeLocationPreference.fallback();
      _effectiveLocation = await _resolveCityReference(
        _effectiveLocation,
        languageCode: languageCode,
      );
      _isLoaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<HomeLocationPreference> resolveCityReference(
    HomeLocationPreference location, {
    required String languageCode,
  }) async {
    final resolved = await _resolveCityReference(
      location,
      languageCode: languageCode,
    );
    if (_sameLocation(_effectiveLocation, location) &&
        !_sameLocation(_effectiveLocation, resolved)) {
      _effectiveLocation = resolved;
      notifyListeners();
    }
    return resolved;
  }

  Future<void> selectCity(
    ReferenceCity city, {
    String languageCode = 'en',
  }) async {
    final countryCode = city.countryCode.trim().toUpperCase();
    final cityName = city.name.trim();
    final preference = HomeLocationPreference(
      source: HomeLocationSource.manual,
      countryCode: countryCode,
      cityId: city.id.trim().isEmpty ? null : city.id.trim(),
      cityName: cityName.isEmpty ? null : cityName,
      timezone: await _resolveTimezoneForLocation(
        cityName: cityName,
        countryCode: countryCode,
        languageCode: languageCode,
      ),
      updatedAt: DateTime.now().toUtc(),
    );
    await _setSelectedLocation(preference);
  }

  Future<void> detectCurrentLocation({required String languageCode}) async {
    if (_isDetecting) return;

    _isDetecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final preference = await _detectDeviceLocationPreference(
        languageCode: languageCode,
        requestPermission: true,
      );
      if (preference == null) {
        throw Exception('location_unavailable');
      }
      await _setSelectedLocation(preference);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isDetecting = false;
      notifyListeners();
    }
  }

  Future<void> requestInitialLocationPermission({
    required String languageCode,
  }) async {
    if (_isInitialPermissionRequestInFlight) return;

    _isInitialPermissionRequestInFlight = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasRequested =
          prefs.getBool(initialPermissionRequestStorageKey) ?? false;
      if (wasRequested) return;

      final permissionGranted = await _deviceContextService
          .requestLocationPermission();
      await prefs.setBool(initialPermissionRequestStorageKey, true);
      if (!permissionGranted) return;

      if (!_isLoaded) {
        await load(languageCode: languageCode);
      }
      if (_selectedLocation != null) return;

      if (_effectiveLocation.source == HomeLocationSource.detected &&
          _effectiveLocation.latitude != null &&
          _effectiveLocation.longitude != null) {
        return;
      }

      final detectedLocation = await _detectDeviceLocationPreference(
        languageCode: languageCode,
        requestPermission: false,
      );
      if (detectedLocation == null) return;

      final resolvedLocation = await _resolveCityReference(
        detectedLocation,
        languageCode: languageCode,
      );
      if (_sameLocation(_effectiveLocation, resolvedLocation)) return;

      _effectiveLocation = resolvedLocation;
      notifyListeners();
    } catch (_) {
      // Initial permission setup is best effort and must not block startup.
    } finally {
      _isInitialPermissionRequestInFlight = false;
    }
  }

  Future<void> clearSelection({String languageCode = 'en'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
    _selectedLocation = null;
    final nextLocation =
        await _detectDeviceLocationPreference(
          languageCode: languageCode,
          requestPermission: false,
        ) ??
        HomeLocationPreference.fallback();
    _effectiveLocation = await _resolveCityReference(
      nextLocation,
      languageCode: languageCode,
    );
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _setSelectedLocation(HomeLocationPreference preference) async {
    _selectedLocation = preference;
    _effectiveLocation = preference;
    _errorMessage = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(preference.toJson()));
    notifyListeners();
  }

  HomeLocationPreference? _decodeSelectedLocation(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final preference = HomeLocationPreference.fromJson(decoded);
      if (!preference.isUserSelected) return null;
      if ((preference.countryCode ?? '').trim().isEmpty &&
          (preference.cityName ?? '').trim().isEmpty &&
          (preference.cityId ?? '').trim().isEmpty) {
        return null;
      }
      return preference;
    } catch (_) {
      return null;
    }
  }

  Future<HomeLocationPreference?> _detectDeviceLocationPreference({
    required String languageCode,
    required bool requestPermission,
  }) async {
    try {
      final suggestion = await _deviceContextService.detectLocationSuggestion(
        requestPermission: requestPermission,
      );
      if (suggestion == null) {
        return requestPermission ? null : await _detectDeviceTimezone();
      }

      final cityName = suggestion.cityName?.trim() ?? '';
      final countryCode = suggestion.countryCode?.trim().toUpperCase();
      ReferenceCity? matchedCity;
      if (cityName.isNotEmpty) {
        final cities = await _referenceApi.searchCities(
          cityName,
          countryCode: countryCode,
          lang: languageCode,
          limit: 8,
        );
        matchedCity = cities.cast<ReferenceCity?>().firstWhere((city) {
          if (city == null) return false;
          if (countryCode == null || countryCode.isEmpty) return true;
          return city.countryCode.trim().toUpperCase() == countryCode;
        }, orElse: () => cities.isEmpty ? null : cities.first);
      }
      final resolvedCountryCode = (matchedCity?.countryCode ?? countryCode)
          ?.trim()
          .toUpperCase();
      final resolvedCityName = (matchedCity?.name.trim().isNotEmpty == true)
          ? matchedCity!.name.trim()
          : (cityName.isEmpty ? null : cityName);

      final preference = HomeLocationPreference(
        source: HomeLocationSource.detected,
        countryCode: resolvedCountryCode,
        cityId: matchedCity?.id.trim().isEmpty == true
            ? null
            : matchedCity?.id.trim(),
        cityName: resolvedCityName,
        timezone: await _resolveTimezoneForLocation(
          cityName: resolvedCityName,
          countryCode: resolvedCountryCode,
          languageCode: languageCode,
        ),
        latitude: suggestion.latitude,
        longitude: suggestion.longitude,
        updatedAt: DateTime.now().toUtc(),
      );
      if ((preference.countryCode ?? '').trim().isEmpty &&
          (preference.cityName ?? '').trim().isEmpty) {
        return requestPermission ? null : await _detectDeviceTimezone();
      }
      return preference;
    } catch (_) {
      if (requestPermission) rethrow;
    }

    return _detectDeviceTimezone();
  }

  Future<String?> _resolveTimezoneForLocation({
    required String languageCode,
    String? cityName,
    String? countryCode,
  }) async {
    final deviceTimezone = await _deviceContextService.getLocalTimezone();

    try {
      final timezones = await _referenceApi.listTimezones(lang: languageCode);
      final aliases = await _timezoneAliasesForLocation(
        timezones,
        languageCode,
      );
      final timezone = resolveReferenceTimezoneForLocation(
        timezones: timezones,
        aliases: aliases,
        cityName: cityName,
        countryCode: countryCode,
        deviceTimezoneId: deviceTimezone,
      );
      return normalizeReferenceTimezoneId(timezone?.id) ??
          normalizeReferenceTimezoneId(deviceTimezone);
    } catch (_) {
      return normalizeReferenceTimezoneId(deviceTimezone);
    }
  }

  Future<Map<String, Set<String>>> _timezoneAliasesForLocation(
    List<ReferenceTimezone> timezones,
    String languageCode,
  ) async {
    final languages = {'en', 'ru', 'kk'}..remove(languageCode);
    final localizedLists = await Future.wait(
      languages.map((lang) async {
        try {
          return await _referenceApi.listTimezones(lang: lang);
        } catch (_) {
          return const <ReferenceTimezone>[];
        }
      }),
    );

    return timezoneSearchAliasMap([
      ...timezones,
      for (final localizedTimezones in localizedLists) ...localizedTimezones,
    ]);
  }

  Future<HomeLocationPreference?> _detectDeviceTimezone() async {
    final timezone = await _deviceContextService.getLocalTimezone();
    return HomeLocationPreference.fromDeviceTimezone(timezone);
  }

  Future<HomeLocationPreference> _resolveCityReference(
    HomeLocationPreference location, {
    required String languageCode,
  }) async {
    if ((location.cityId ?? '').trim().isNotEmpty) return location;

    final cityName = location.cityName?.trim();
    if (cityName == null || cityName.isEmpty) return location;

    try {
      final countryCode = location.countryCode?.trim().toUpperCase();
      final cities = await _referenceApi.searchCities(
        cityName,
        countryCode: countryCode,
        lang: languageCode,
        limit: 8,
      );
      ReferenceCity? matchedCity;
      for (final city in cities) {
        final cityId = city.id.trim();
        if (cityId.isEmpty) continue;
        if ((countryCode ?? '').isNotEmpty &&
            city.countryCode.trim().toUpperCase() != countryCode) {
          continue;
        }
        matchedCity = city;
        break;
      }
      if (matchedCity == null) {
        for (final city in cities) {
          if (city.id.trim().isEmpty) continue;
          matchedCity = city;
          break;
        }
      }
      if (matchedCity == null) return location;

      return HomeLocationPreference(
        source: location.source,
        countryCode: matchedCity.countryCode.trim().isEmpty
            ? location.countryCode
            : matchedCity.countryCode.trim().toUpperCase(),
        cityId: matchedCity.id.trim(),
        cityName: matchedCity.name.trim().isEmpty
            ? location.cityName
            : matchedCity.name.trim(),
        timezone: location.timezone,
        latitude: location.latitude,
        longitude: location.longitude,
        updatedAt: location.updatedAt,
      );
    } catch (_) {
      return location;
    }
  }

  bool _sameLocation(
    HomeLocationPreference first,
    HomeLocationPreference second,
  ) {
    return first.source == second.source &&
        first.countryCode == second.countryCode &&
        first.cityId == second.cityId &&
        first.cityName == second.cityName &&
        first.timezone == second.timezone &&
        first.latitude == second.latitude &&
        first.longitude == second.longitude;
  }
}

String? _nullableText(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

String? _cityNameFromTimezone(String? timezone) {
  final normalized = _nullableText(timezone);
  if (normalized == null) return null;
  if (normalized.startsWith('Etc/')) return null;

  final slashIndex = normalized.lastIndexOf('/');
  final rawCity = slashIndex >= 0
      ? normalized.substring(slashIndex + 1)
      : normalized;
  final city = rawCity.replaceAll('_', ' ').trim();
  final upperCity = city.toUpperCase();
  if (city.isEmpty || upperCity == 'UTC' || upperCity.startsWith('GMT')) {
    return null;
  }
  return city;
}

double? _nullableDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
