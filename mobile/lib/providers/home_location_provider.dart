import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/device/device_context_service.dart';
import '../core/network/reference_api.dart';

enum HomeLocationSource { manual, detected, profile, fallback }

class HomeLocationPreference {
  const HomeLocationPreference({
    required this.source,
    this.countryCode,
    this.cityId,
    this.cityName,
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  final HomeLocationSource source;
  final String? countryCode;
  final String? cityId;
  final String? cityName;
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
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory HomeLocationPreference.fromJson(Map<String, dynamic> json) {
    final rawSource = json['source']?.toString();
    final source = HomeLocationSource.values.firstWhere(
      (item) => item.name == rawSource,
      orElse: () => HomeLocationSource.manual,
    );
    return HomeLocationPreference(
      source: source,
      countryCode: _nullableText(json['countryCode']),
      cityId: _nullableText(json['cityId']),
      cityName: _nullableText(json['cityName']),
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
      updatedAt: DateTime.now().toUtc(),
    );
  }

  static HomeLocationPreference? fromProfile({
    required String? countryCode,
    required String? timezone,
  }) {
    final normalizedCountryCode = _nullableText(countryCode)?.toUpperCase();
    final cityName = _cityNameFromTimezone(timezone);
    if (normalizedCountryCode == null && cityName == null) return null;

    return HomeLocationPreference(
      source: HomeLocationSource.profile,
      countryCode: normalizedCountryCode,
      cityName: cityName,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  static HomeLocationPreference? fromDeviceTimezone(String? timezone) {
    final cityName = _cityNameFromTimezone(timezone);
    if (cityName == null) return null;

    return HomeLocationPreference(
      source: HomeLocationSource.detected,
      cityName: cityName,
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

  final ReferenceApi _referenceApi;
  final DeviceContextService _deviceContextService;

  HomeLocationPreference? _selectedLocation;
  HomeLocationPreference? _profileFallbackLocation;
  HomeLocationPreference _effectiveLocation = HomeLocationPreference.fallback();
  Future<void>? _loadFuture;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _isDetecting = false;
  String? _errorMessage;

  HomeLocationPreference? get selectedLocation => _selectedLocation;
  HomeLocationPreference get effectiveLocation => _effectiveLocation;
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  bool get isDetecting => _isDetecting;
  String? get errorMessage => _errorMessage;

  Future<void> load({
    String languageCode = 'en',
    HomeLocationPreference? profileFallback,
  }) {
    if (profileFallback != null) {
      _profileFallbackLocation = profileFallback;
    }
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
          _profileFallbackLocation ??
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

  Future<void> setProfileFallback(
    HomeLocationPreference? profileFallback, {
    required String languageCode,
  }) async {
    _profileFallbackLocation = profileFallback;
    if (profileFallback == null || _selectedLocation != null) return;

    final currentLoad = _loadFuture;
    if (currentLoad != null) {
      await currentLoad;
      if (_selectedLocation != null ||
          _effectiveLocation.source != HomeLocationSource.fallback) {
        return;
      }
    } else if (!_isLoaded ||
        _effectiveLocation.source != HomeLocationSource.fallback) {
      return;
    }

    final resolved = await _resolveCityReference(
      profileFallback,
      languageCode: languageCode,
    );
    if (_sameLocation(_effectiveLocation, resolved)) return;

    _effectiveLocation = resolved;
    notifyListeners();
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

  Future<void> selectCity(ReferenceCity city) async {
    final preference = HomeLocationPreference(
      source: HomeLocationSource.manual,
      countryCode: city.countryCode.trim().toUpperCase(),
      cityId: city.id.trim().isEmpty ? null : city.id.trim(),
      cityName: city.name.trim().isEmpty ? null : city.name.trim(),
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

  Future<void> clearSelection({String languageCode = 'en'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
    _selectedLocation = null;
    final nextLocation =
        await _detectDeviceLocationPreference(
          languageCode: languageCode,
          requestPermission: false,
        ) ??
        _profileFallbackLocation ??
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

      final preference = HomeLocationPreference(
        source: HomeLocationSource.detected,
        countryCode: (matchedCity?.countryCode ?? countryCode)
            ?.trim()
            .toUpperCase(),
        cityId: matchedCity?.id.trim().isEmpty == true
            ? null
            : matchedCity?.id.trim(),
        cityName: (matchedCity?.name.trim().isNotEmpty == true)
            ? matchedCity!.name.trim()
            : (cityName.isEmpty ? null : cityName),
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
