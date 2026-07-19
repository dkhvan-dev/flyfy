import 'package:flutter/foundation.dart';

final class AppConfig {
  AppConfig._();

  static const String _defaultApiBaseUrl = 'https://test-api.inflap.app/api/v1';
  static const String _baseUrlFromDefine = String.fromEnvironment(
    'INFLAP_API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );
  static const String _mapStyleUrlFromDefine = String.fromEnvironment(
    'INFLAP_MAP_STYLE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl => normalizeApiBaseUrl(_baseUrlFromDefine);

  static String get mapStyleUrl {
    final configuredValue = _mapStyleUrlFromDefine.trim();
    if (configuredValue.isNotEmpty) {
      return configuredValue;
    }

    return 'https://tiles.openfreemap.org/styles/liberty';
  }

  static String _normalize(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  @visibleForTesting
  static String normalizeApiBaseUrl(String value, {bool isWeb = kIsWeb}) {
    final configured = value.trim();
    final normalized = _normalize(
      configured.isEmpty ? _defaultApiBaseUrl : configured,
    );
    final uri = Uri.tryParse(normalized);

    if (uri == null) {
      throw FormatException('INFLAP_API_BASE_URL is not a valid URL.');
    }

    final isRelativeWebUrl = isWeb && normalized.startsWith('/');
    if (isRelativeWebUrl) {
      return normalized;
    }

    final scheme = uri.scheme.toLowerCase();
    final hasSupportedScheme = scheme == 'https' || scheme == 'http';
    if (!hasSupportedScheme || !uri.hasAuthority) {
      throw FormatException(
        'INFLAP_API_BASE_URL must be an absolute http(s) URL on mobile. '
        'Use a value like https://test-api.inflap.app.',
      );
    }

    final normalizedPath = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (normalizedPath.isEmpty) {
      return '$normalized/api/v1';
    }

    return normalized;
  }
}
