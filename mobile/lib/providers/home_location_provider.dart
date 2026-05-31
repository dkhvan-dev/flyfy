import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/device/device_context_service.dart';
import '../core/network/reference_api.dart';
import '../features/profile/models/user_profile_vm.dart';

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
  HomeLocationPreference _effectiveLocation = HomeLocationPreference.fallback();
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _isDetecting = false;
  String? _errorMessage;
  String? _profileSignature;

  HomeLocationPreference? get selectedLocation => _selectedLocation;
  HomeLocationPreference get effectiveLocation => _effectiveLocation;
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  bool get isDetecting => _isDetecting;
  String? get errorMessage => _errorMessage;

  bool shouldSyncProfile(UserProfileVm? profile) {
    if (!_isLoaded || _selectedLocation != null) return false;
    return _profileSignature != _profileLocationSignature(profile);
  }

  Future<void> load({UserProfileVm? profile}) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    _selectedLocation = _decodeSelectedLocation(raw);
    _profileSignature = _profileLocationSignature(profile);
    _effectiveLocation =
        _selectedLocation ??
        _profileFallback(profile) ??
        HomeLocationPreference.fallback();
    _isLoaded = true;
    _isLoading = false;
    notifyListeners();
  }

  void syncProfileFallback(UserProfileVm? profile) {
    if (!_isLoaded || _selectedLocation != null) return;
    final signature = _profileLocationSignature(profile);
    if (_profileSignature == signature) return;
    _profileSignature = signature;
    _effectiveLocation =
        _profileFallback(profile) ?? HomeLocationPreference.fallback();
    notifyListeners();
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
      final suggestion = await _deviceContextService.detectLocationSuggestion(
        requestPermission: true,
      );
      if (suggestion == null) {
        throw Exception('location_unavailable');
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

  Future<void> clearSelection({UserProfileVm? profile}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
    _selectedLocation = null;
    _profileSignature = _profileLocationSignature(profile);
    _effectiveLocation =
        _profileFallback(profile) ?? HomeLocationPreference.fallback();
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

  HomeLocationPreference? _profileFallback(UserProfileVm? profile) {
    if (profile == null) return null;

    final countryCode = profile.countryCode?.trim().toUpperCase();
    final cityName = _cityFromTimezone(profile.timezone);
    if ((countryCode ?? '').isEmpty && (cityName ?? '').isEmpty) return null;

    return HomeLocationPreference(
      source: HomeLocationSource.profile,
      countryCode: countryCode?.isEmpty == true ? null : countryCode,
      cityName: cityName,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  String _profileLocationSignature(UserProfileVm? profile) {
    if (profile == null) return '';
    return '${profile.countryCode ?? ''}|${profile.timezone}';
  }

  String? _cityFromTimezone(String? timezone) {
    final normalized = timezone?.trim();
    if (normalized == null || normalized.isEmpty || !normalized.contains('/')) {
      return null;
    }
    final city = normalized.split('/').last.trim().replaceAll('_', ' ');
    return city.isEmpty ? null : city;
  }
}

String? _nullableText(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

double? _nullableDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
