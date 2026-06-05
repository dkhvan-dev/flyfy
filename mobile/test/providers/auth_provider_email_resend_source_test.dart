import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'auth provider keeps pending email registration password for resend only in memory',
    () async {
      final source = await File(
        'lib/providers/auth_provider.dart',
      ).readAsString();

      expect(source, contains('String? _pendingEmailRegistrationEmail;'));
      expect(source, contains('String? _pendingEmailRegistrationPassword;'));
      expect(source, contains('Future<bool> resendEmailRegistrationCode('));
      expect(
        source,
        contains('await _apiClient.startEmailRegistration(email, password);'),
      );
      expect(
        source,
        contains('_pendingEmailRegistrationPassword = password.trim();'),
      );
      expect(source, contains('_pendingEmailRegistrationPassword = null;'));
    },
  );
}
