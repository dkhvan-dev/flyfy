import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

final class AppConfig {
  AppConfig._();

  static const String _baseUrlFromDefine =
      String.fromEnvironment('FLYFY_API_BASE_URL', defaultValue: '');

  static String get apiBaseUrl {
    if (_baseUrlFromDefine.trim().isNotEmpty) {
      return _normalize(_baseUrlFromDefine);
    }

    if (kIsWeb) {
      return "https://moved-markets-honey-auckland.trycloudflare.com/api/v1";
      // return 'http://localhost:8080/api/v1';
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return "https://moved-markets-honey-auckland.trycloudflare.com/api/v1";
      // return 'http://localhost:8080/api/v1';
    }

    if (Platform.isAndroid) {
      return "https://moved-markets-honey-auckland.trycloudflare.com/api/v1";
      // return 'http://10.0.2.2:8080/api/v1';
    }

      return "https://moved-markets-honey-auckland.trycloudflare.com/api/v1";
    // return 'http://localhost:8080/api/v1';
  }

  static String _normalize(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}