final class AppConfig {
  AppConfig._();

  static const String _baseUrlFromDefine = String.fromEnvironment(
    'INFLAP_API_BASE_URL',
    defaultValue: '',
  );
  static const String _mapStyleUrlFromDefine = String.fromEnvironment(
    'INFLAP_MAP_STYLE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_baseUrlFromDefine.trim().isNotEmpty) {
      return _normalize(_baseUrlFromDefine);
    }

    return '$_baseUrlFromDefine/api/v1';
  }

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
}
