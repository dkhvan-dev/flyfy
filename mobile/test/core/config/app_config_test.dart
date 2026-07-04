import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/config/app_config.dart';

void main() {
  group('AppConfig.normalizeApiBaseUrl', () {
    test('uses default absolute API URL when dart define is blank', () {
      final value = AppConfig.normalizeApiBaseUrl('');

      expect(value, 'https://api-dev.inflap.app/api/v1');
      expect(Uri.parse(value).hasAuthority, isTrue);
    });

    test('adds API prefix to configured host-only URL', () {
      expect(
        AppConfig.normalizeApiBaseUrl('https://test-api.inflap.app'),
        'https://test-api.inflap.app/api/v1',
      );
    });

    test('trims configured absolute API URL and removes trailing slash', () {
      expect(
        AppConfig.normalizeApiBaseUrl(' https://test-api.inflap.app/api/v1/ '),
        'https://test-api.inflap.app/api/v1',
      );
    });

    test('rejects relative API URL for non-web platforms', () {
      expect(
        () => AppConfig.normalizeApiBaseUrl('/api/v1', isWeb: false),
        throwsA(isA<FormatException>()),
      );
    });

    test('keeps relative API URL for web builds', () {
      expect(AppConfig.normalizeApiBaseUrl('/api/v1', isWeb: true), '/api/v1');
    });
  });
}
