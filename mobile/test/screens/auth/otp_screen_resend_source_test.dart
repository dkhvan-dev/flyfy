import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'otp screen exposes interactive resend action for email and phone flows',
    () async {
      final source = await File(
        'lib/screens/auth/otp_screen.dart',
      ).readAsString();

      expect(source, contains('Future<void> _resendCode() async'));
      expect(source, contains('TextButton('));
      expect(
        source,
        matches(
          RegExp(r'onPressed:\s*canResend\s*\?\s*_resendCode\s*:\s*null'),
        ),
      );
      expect(
        source,
        contains('auth.resendEmailRegistrationCode(widget.email)'),
      );
      expect(source, contains('auth.sendOtp(widget.phone)'));
      expect(source, contains('_startCountdown();'));
      expect(source, contains('_codeController.clear();'));
    },
  );
}
