import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';

import 'app_map_links.dart';

typedef AppMapShortLinkExpander = Future<Uri?> Function(Uri uri);
typedef AppMapPageLoader = Future<String?> Function(Uri uri);

final class AppMapLinkResolver {
  const AppMapLinkResolver({this.expandShortLink, this.loadMapPage});

  static const _requestTimeout = Duration(seconds: 5);
  static const _maxRedirects = 8;
  static const _maxMapPageBytes = 512 * 1024;
  static const _browserUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/125.0.0.0 Safari/537.36';

  final AppMapShortLinkExpander? expandShortLink;
  final AppMapPageLoader? loadMapPage;

  Future<LatLng?> resolveCoordinates(String rawValue) async {
    final normalizedValue = AppMapLinks.normalizePastedMapLink(rawValue);
    final directPoint = AppMapLinks.tryParseCoordinates(normalizedValue);
    if (directPoint != null) {
      return directPoint;
    }

    final uri = Uri.tryParse(normalizedValue);
    if (uri == null || !canResolveRemoteMapLink(uri.toString())) {
      return null;
    }

    final targetUri = canResolveShortMapLink(uri.toString())
        ? await (expandShortLink ?? _expandShortMapLink)(uri)
        : uri;
    if (targetUri == null || !_isAllowedExpandedMapHost(targetUri)) {
      return null;
    }

    final expandedPoint = AppMapLinks.tryParseCoordinates(targetUri.toString());
    if (expandedPoint != null) {
      return expandedPoint;
    }

    return _resolveFromRemoteMapPage(targetUri);
  }

  static bool canResolveRemoteMapLink(String rawValue) {
    final normalizedValue = AppMapLinks.normalizePastedMapLink(rawValue);
    final uri = Uri.tryParse(normalizedValue);
    if (uri == null || !_hasSupportedHttpScheme(uri)) {
      return false;
    }
    if (canResolveShortMapLink(normalizedValue)) {
      return true;
    }
    return _canLoadMapPageForCoordinates(uri);
  }

  static bool canResolveShortMapLink(String rawValue) {
    final uri = Uri.tryParse(AppMapLinks.normalizePastedMapLink(rawValue));
    if (uri == null || !_hasSupportedHttpScheme(uri)) {
      return false;
    }
    final host = uri.host.toLowerCase();
    if (_isGoogleMapsShortLink(uri)) {
      return true;
    }
    if (host == 'go.2gis.com' || host == '2gis.page.link') {
      return true;
    }
    return false;
  }

  Future<LatLng?> _resolveFromRemoteMapPage(Uri uri) async {
    if (!_canLoadMapPageForCoordinates(uri)) {
      return null;
    }
    final page = await (loadMapPage ?? _loadMapPage)(uri);
    if (page == null || page.trim().isEmpty) {
      return null;
    }
    return _tryParseCoordinatesFromMapPage(page, sourceUri: uri);
  }

  static Future<Uri?> _expandShortMapLink(Uri uri) async {
    final client = HttpClient()..connectionTimeout = _requestTimeout;
    var current = uri;

    try {
      for (var i = 0; i < _maxRedirects; i += 1) {
        final request = await client.getUrl(current).timeout(_requestTimeout);
        request.followRedirects = false;
        if (!_isGoogleMapsShortLink(current)) {
          request.headers.set(HttpHeaders.userAgentHeader, _browserUserAgent);
        }
        request.headers.set(
          HttpHeaders.acceptHeader,
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        );

        final response = await request.close().timeout(_requestTimeout);
        final location = response.headers.value(HttpHeaders.locationHeader);
        final isRedirect =
            response.statusCode >= 300 && response.statusCode < 400;
        if (isRedirect && location != null && location.trim().isNotEmpty) {
          current = current.resolve(location.trim());
          if (AppMapLinks.tryParseCoordinates(current.toString()) != null) {
            return current;
          }
          continue;
        }
        return current;
      }
      return current;
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static Future<String?> _loadMapPage(Uri uri) async {
    final client = HttpClient()..connectionTimeout = _requestTimeout;
    try {
      final request = await client.getUrl(uri).timeout(_requestTimeout);
      request.followRedirects = true;
      request.maxRedirects = _maxRedirects;
      request.headers.set(HttpHeaders.userAgentHeader, _browserUserAgent);
      request.headers.set(
        HttpHeaders.acceptHeader,
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      );
      request.headers.set(
        HttpHeaders.acceptLanguageHeader,
        'ru-RU,ru;q=0.9,en;q=0.8',
      );

      final response = await request.close().timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 400) {
        return null;
      }

      final bytes = <int>[];
      await for (final chunk in response.timeout(_requestTimeout)) {
        bytes.addAll(chunk);
        if (bytes.length > _maxMapPageBytes) {
          return null;
        }
      }
      return utf8.decode(bytes, allowMalformed: true);
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static LatLng? _tryParseCoordinatesFromMapPage(
    String page, {
    required Uri sourceUri,
  }) {
    final host = sourceUri.host.toLowerCase();
    if (_isGoogleMapsPage(sourceUri)) {
      final googleLitePoint = _tryParseGoogleLiteBootstrapCoordinate(page);
      if (googleLitePoint != null) {
        return googleLitePoint;
      }
      return AppMapLinks.tryParseCoordinates(page);
    }

    if (_is2GisPageHost(host)) {
      final jsonPoint = _tryParseJsonLonLatPoint(page);
      if (jsonPoint != null) {
        return jsonPoint;
      }
      return _tryParseWktPoint(page);
    }

    return AppMapLinks.tryParseCoordinates(page);
  }

  static LatLng? _tryParseGoogleLiteBootstrapCoordinate(String page) {
    final match = RegExp(
      r'\[\[\s*[+-]?\d+(?:\.\d+)?\s*,\s*([+-]?\d+(?:\.\d+)?)\s*,\s*([+-]?\d+(?:\.\d+)?)\s*\]\s*,\s*\[\s*0\s*,\s*0\s*,\s*0\s*\]\s*,\s*\[\s*\d+\s*,\s*\d+\s*\]',
    ).firstMatch(page);
    if (match == null) {
      return null;
    }
    final longitude = double.tryParse(match.group(1) ?? '');
    final latitude = double.tryParse(match.group(2) ?? '');
    return _pointFromNullableValues(latitude: latitude, longitude: longitude);
  }

  static LatLng? _tryParseJsonLonLatPoint(String page) {
    final pointFirstMatch = RegExp(
      r'"point"\s*:\s*\{[^{}]*"lon"\s*:\s*([+-]?\d+(?:\.\d+)?)[^{}]*"lat"\s*:\s*([+-]?\d+(?:\.\d+)?)',
      dotAll: true,
    ).firstMatch(page);
    if (pointFirstMatch != null) {
      return _pointFromNullableValues(
        latitude: double.tryParse(pointFirstMatch.group(2) ?? ''),
        longitude: double.tryParse(pointFirstMatch.group(1) ?? ''),
      );
    }

    final latFirstMatch = RegExp(
      r'"point"\s*:\s*\{[^{}]*"lat"\s*:\s*([+-]?\d+(?:\.\d+)?)[^{}]*"lon"\s*:\s*([+-]?\d+(?:\.\d+)?)',
      dotAll: true,
    ).firstMatch(page);
    if (latFirstMatch == null) {
      return null;
    }
    return _pointFromNullableValues(
      latitude: double.tryParse(latFirstMatch.group(1) ?? ''),
      longitude: double.tryParse(latFirstMatch.group(2) ?? ''),
    );
  }

  static LatLng? _tryParseWktPoint(String page) {
    final match = RegExp(
      r'POINT\s*\(\s*([+-]?\d+(?:\.\d+)?)\s+([+-]?\d+(?:\.\d+)?)\s*\)',
    ).firstMatch(page);
    if (match == null) {
      return null;
    }
    return _pointFromNullableValues(
      latitude: double.tryParse(match.group(2) ?? ''),
      longitude: double.tryParse(match.group(1) ?? ''),
    );
  }

  static LatLng? _pointFromNullableValues({
    required double? latitude,
    required double? longitude,
  }) {
    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return LatLng(latitude, longitude);
  }

  static bool _hasSupportedHttpScheme(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return uri.hasScheme && (scheme == 'https' || scheme == 'http');
  }

  static bool _canLoadMapPageForCoordinates(Uri uri) {
    final host = uri.host.toLowerCase();
    return _isGoogleMapsPage(uri) || _is2GisPageHost(host);
  }

  static bool _is2GisPageHost(String host) {
    return host == '2gis.kz' ||
        host == '2gis.ru' ||
        host.endsWith('.2gis.kz') ||
        host.endsWith('.2gis.ru') ||
        host.endsWith('.2gis.com');
  }

  static bool _isGoogleMapsShortLink(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host == 'maps.app.goo.gl') {
      return true;
    }
    return host == 'goo.gl' && uri.path.toLowerCase().startsWith('/maps');
  }

  static bool _isGoogleMapsPage(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host == 'maps.google.com') {
      return true;
    }
    return (host == 'google.com' ||
            host == 'www.google.com' ||
            host.endsWith('.google.com')) &&
        uri.path.toLowerCase().startsWith('/maps');
  }

  static bool _isAllowedExpandedMapHost(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == AppMapLinks.host ||
        _isGoogleMapsPage(uri) ||
        host == 'maps.apple.com' ||
        host == '2gis.kz' ||
        host == '2gis.ru' ||
        host.endsWith('.2gis.kz') ||
        host.endsWith('.2gis.ru') ||
        host.endsWith('.2gis.com') ||
        host.contains('yandex.') ||
        host == 'www.openstreetmap.org' ||
        host == 'openstreetmap.org';
  }
}
