import 'package:latlong2/latlong.dart';

final class AppMapLinks {
  const AppMapLinks._();

  static const String host = 'inflap.app';
  static const String path = '/map';

  static String buildUrl({
    required double latitude,
    required double longitude,
    String? title,
    String? subtitle,
  }) {
    return Uri.https(
      host,
      path,
      _queryParameters(
        latitude: latitude,
        longitude: longitude,
        title: title,
        subtitle: subtitle,
      ),
    ).toString();
  }

  static String buildRoute({
    required double latitude,
    required double longitude,
    String? title,
    String? subtitle,
  }) {
    return Uri(
      path: path,
      queryParameters: _queryParameters(
        latitude: latitude,
        longitude: longitude,
        title: title,
        subtitle: subtitle,
      ),
    ).toString();
  }

  static String normalizePastedMapLink(String rawValue) {
    final value = rawValue.trim();
    final match = RegExp(r'https?://', caseSensitive: false).firstMatch(value);
    if (match == null) {
      return value;
    }
    return value.substring(match.start).trim();
  }

  static LatLng? tryParseCoordinates(String rawValue) {
    try {
      return _tryParseCoordinates(rawValue);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  static LatLng? _tryParseCoordinates(String rawValue) {
    final value = normalizePastedMapLink(rawValue);
    if (value.isEmpty) {
      return null;
    }

    final rawCoordinatePair = _tryParseCoordinatePair(
      value,
      order: _CoordinateOrder.latitudeLongitude,
      requireFullMatch: true,
    );
    if (rawCoordinatePair != null) {
      return rawCoordinatePair;
    }

    final googleDataPoint = _tryParseGoogleDataCoordinate(value);
    if (googleDataPoint != null) {
      return googleDataPoint;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) {
      return null;
    }

    final priorityPathPoint = _tryParsePriorityPathCoordinate(uri);
    if (priorityPathPoint != null) {
      return priorityPathPoint;
    }

    final queryPoint = _tryParseQueryPoint(uri);
    if (queryPoint != null) {
      return queryPoint;
    }

    final pathCoordinatePoint = _tryParsePathCoordinate(uri);
    if (pathCoordinatePoint != null) {
      return pathCoordinatePoint;
    }

    final pathPoint = _tryParseAtCoordinate(value);
    if (pathPoint != null) {
      return pathPoint;
    }

    return _tryParseOsmFragment(uri.fragment);
  }

  static LatLng? _tryParsePriorityPathCoordinate(Uri uri) {
    final host = uri.host.toLowerCase();
    if (!host.contains('2gis') || !uri.path.toLowerCase().contains('/geo/')) {
      return null;
    }
    return _tryParseCoordinatePair(
      uri.path,
      order: _CoordinateOrder.longitudeLatitude,
    );
  }

  static Map<String, String> _queryParameters({
    required double latitude,
    required double longitude,
    String? title,
    String? subtitle,
  }) {
    final params = <String, String>{
      'lat': _formatCoordinate(latitude),
      'lon': _formatCoordinate(longitude),
    };
    final normalizedTitle = title?.trim();
    if (normalizedTitle != null && normalizedTitle.isNotEmpty) {
      params['title'] = normalizedTitle;
    }
    final normalizedSubtitle = subtitle?.trim();
    if (normalizedSubtitle != null && normalizedSubtitle.isNotEmpty) {
      params['subtitle'] = normalizedSubtitle;
    }
    return params;
  }

  static LatLng? _tryParseQueryPoint(Uri uri) {
    final latitude =
        double.tryParse(uri.queryParameters['lat'] ?? '') ??
        double.tryParse(uri.queryParameters['mlat'] ?? '');
    final longitude =
        double.tryParse(uri.queryParameters['lon'] ?? '') ??
        double.tryParse(uri.queryParameters['lng'] ?? '') ??
        double.tryParse(uri.queryParameters['mlon'] ?? '');
    if (latitude != null || longitude != null) {
      final explicitPoint = latitude != null && longitude != null
          ? _pointFromValues(
              latitude,
              longitude,
              order: _CoordinateOrder.latitudeLongitude,
            )
          : null;
      if (explicitPoint != null) {
        return explicitPoint;
      }
    }

    final host = uri.host.toLowerCase();
    final ll = uri.queryParameters['ll'];
    if (ll != null) {
      final order = host.contains('yandex')
          ? _CoordinateOrder.longitudeLatitude
          : _CoordinateOrder.latitudeLongitude;
      final point = _tryParseCoordinatePair(ll, order: order);
      if (point != null) {
        return point;
      }
    }

    for (final key in const ['pt', 'm', 'whatshere[point]']) {
      final value = uri.queryParameters[key];
      if (value == null) {
        continue;
      }
      final point = _tryParseCoordinatePair(
        value,
        order: _CoordinateOrder.longitudeLatitude,
      );
      if (point != null) {
        return point;
      }
    }

    for (final key in const [
      'q',
      'query',
      'center',
      'destination',
      'origin',
      'daddr',
      'saddr',
    ]) {
      final value = uri.queryParameters[key];
      if (value == null) {
        continue;
      }
      final point = _tryParseCoordinatePair(
        value,
        order: _CoordinateOrder.latitudeLongitude,
      );
      if (point != null) {
        return point;
      }
    }

    return null;
  }

  static LatLng? _tryParsePathCoordinate(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host.contains('2gis')) {
      return _tryParseCoordinatePair(
        uri.path,
        order: _CoordinateOrder.longitudeLatitude,
      );
    }
    if (host == 'maps.google.com' ||
        host == 'www.google.com' ||
        host.endsWith('.google.com')) {
      return _tryParseCoordinatePair(
        uri.path,
        order: _CoordinateOrder.latitudeLongitude,
      );
    }
    return null;
  }

  static LatLng? _tryParseOsmFragment(String fragment) {
    if (fragment.isEmpty) {
      return null;
    }
    final match = RegExp(
      r'map=\d+(?:\.\d+)?\/([+-]?\d+(?:\.\d+)?)\/([+-]?\d+(?:\.\d+)?)',
    ).firstMatch(fragment);
    if (match == null) {
      return null;
    }
    final latitude = double.tryParse(match.group(1) ?? '');
    final longitude = double.tryParse(match.group(2) ?? '');
    if (latitude == null || longitude == null) return null;
    return _pointFromValues(
      latitude,
      longitude,
      order: _CoordinateOrder.latitudeLongitude,
    );
  }

  static LatLng? _tryParseAtCoordinate(String value) {
    final decoded = _safeDecodeFull(value);
    final atIndex = decoded.indexOf('@');
    if (atIndex < 0 || atIndex == decoded.length - 1) {
      return null;
    }
    return _tryParseCoordinatePair(
      decoded.substring(atIndex + 1),
      order: _CoordinateOrder.latitudeLongitude,
    );
  }

  static LatLng? _tryParseGoogleDataCoordinate(String value) {
    final decoded = _safeDecodeFull(value);
    final latLonMatch = RegExp(
      r'!3d([+-]?\d+(?:\.\d+)?)!4d([+-]?\d+(?:\.\d+)?)',
    ).firstMatch(decoded);
    if (latLonMatch != null) {
      final latitude = double.tryParse(latLonMatch.group(1) ?? '');
      final longitude = double.tryParse(latLonMatch.group(2) ?? '');
      if (latitude != null && longitude != null) {
        return _pointFromValues(
          latitude,
          longitude,
          order: _CoordinateOrder.latitudeLongitude,
        );
      }
    }

    final lonLatMatch = RegExp(
      r'!2d([+-]?\d+(?:\.\d+)?)!3d([+-]?\d+(?:\.\d+)?)',
    ).firstMatch(decoded);
    if (lonLatMatch == null) {
      return null;
    }
    final longitude = double.tryParse(lonLatMatch.group(1) ?? '');
    final latitude = double.tryParse(lonLatMatch.group(2) ?? '');
    if (latitude == null || longitude == null) return null;
    return _pointFromValues(
      latitude,
      longitude,
      order: _CoordinateOrder.latitudeLongitude,
    );
  }

  static LatLng? _tryParseCoordinatePair(
    String value, {
    required _CoordinateOrder order,
    bool requireFullMatch = false,
  }) {
    final decoded = _safeDecodeComponent(value.trim());
    final pattern = requireFullMatch
        ? RegExp(r'^\s*([+-]?\d+(?:\.\d+)?)\s*,\s*([+-]?\d+(?:\.\d+)?)\s*$')
        : RegExp(r'([+-]?\d+(?:\.\d+)?)\s*,\s*([+-]?\d+(?:\.\d+)?)');
    final match = pattern.firstMatch(decoded);
    if (match == null) {
      return null;
    }

    final first = double.tryParse(match.group(1) ?? '');
    final second = double.tryParse(match.group(2) ?? '');
    if (first == null || second == null) {
      return null;
    }
    return _pointFromValues(first, second, order: order);
  }

  static LatLng? _pointFromValues(
    double first,
    double second, {
    required _CoordinateOrder order,
  }) {
    final latitude = switch (order) {
      _CoordinateOrder.latitudeLongitude => first,
      _CoordinateOrder.longitudeLatitude => second,
    };
    final longitude = switch (order) {
      _CoordinateOrder.latitudeLongitude => second,
      _CoordinateOrder.longitudeLatitude => first,
    };
    if (!_isValidCoordinate(latitude, longitude)) {
      return null;
    }
    return LatLng(latitude, longitude);
  }

  static bool _isValidCoordinate(double? latitude, double? longitude) {
    return latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  static String _formatCoordinate(double value) => value.toStringAsFixed(6);

  static String _safeDecodeComponent(String value) {
    return _safeDecode(value, Uri.decodeComponent);
  }

  static String _safeDecodeFull(String value) {
    return _safeDecode(value, Uri.decodeFull);
  }

  static String _safeDecode(String value, String Function(String) decode) {
    try {
      return decode(value);
    } on FormatException {
      return _tryDecodeWithEscapedInvalidPercents(value, decode);
    } on ArgumentError {
      return _tryDecodeWithEscapedInvalidPercents(value, decode);
    }
  }

  static String _tryDecodeWithEscapedInvalidPercents(
    String value,
    String Function(String) decode,
  ) {
    final sanitized = value.replaceAllMapped(
      RegExp(r'%(?![0-9A-Fa-f]{2})'),
      (_) => '%25',
    );
    if (sanitized == value) {
      return value;
    }
    try {
      return decode(sanitized);
    } on FormatException {
      return value;
    } on ArgumentError {
      return value;
    }
  }
}

enum _CoordinateOrder { latitudeLongitude, longitudeLatitude }
