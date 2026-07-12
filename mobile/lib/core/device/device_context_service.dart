import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DeviceLocationSuggestion {
  DeviceLocationSuggestion({
    required this.countryCode,
    required this.countryName,
    required this.cityName,
    required this.latitude,
    required this.longitude,
  });

  final String? countryCode;
  final String? countryName;
  final String? cityName;
  final double latitude;
  final double longitude;
}

class DeviceCoordinates {
  const DeviceCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class DeviceContextService {
  const DeviceContextService();

  Future<bool> requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<String?> getLocalTimezone() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final timezone = timezoneInfo.identifier.trim();
      if (timezone.isEmpty) return null;
      return timezone;
    } catch (_) {
      return null;
    }
  }

  Future<DeviceLocationSuggestion?> detectLocationSuggestion({
    bool requestPermission = true,
  }) async {
    final position = await _detectPosition(
      requestPermission: requestPermission,
    );
    if (position == null) {
      return null;
    }

    Placemark? first;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        first = placemarks.first;
      }
    } catch (_) {
      first = null;
    }

    return DeviceLocationSuggestion(
      countryCode: _normalizeCountryCode(first?.isoCountryCode),
      countryName: _normalizeText(first?.country),
      cityName:
          _normalizeText(first?.locality) ??
          _normalizeText(first?.subAdministrativeArea) ??
          _normalizeText(first?.administrativeArea),
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<DeviceCoordinates?> detectCoordinates({
    bool requestPermission = true,
  }) async {
    final position = await _detectPosition(
      requestPermission: requestPermission,
    );
    if (position == null) {
      return null;
    }

    return DeviceCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<Position?> _detectPosition({required bool requestPermission}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('location_services_disabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!requestPermission) {
        return null;
      }
      throw Exception('location_permission_denied');
    }

    if (permission == LocationPermission.deniedForever) {
      if (!requestPermission) {
        return null;
      }
      throw Exception('location_permission_denied_forever');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  String? _normalizeCountryCode(String? value) {
    final normalized = value?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  String? _normalizeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
