import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'login screen exposes forgot password action below password field',
    () async {
      final source = await File(
        'lib/screens/auth/login_screen.dart',
      ).readAsString();

      expect(source, contains('l10n.authForgotPasswordAction'));
      expect(source, contains("context.push('/password-reset')"));
      expect(
        source.indexOf('l10n.authForgotPasswordAction'),
        lessThan(source.indexOf('l10n.authLoginAction')),
      );
    },
  );
}
