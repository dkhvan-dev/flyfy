import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'password reset screen implements identifier OTP and new password steps',
    () async {
      final source = await File(
        'lib/screens/auth/password_reset_screen.dart',
      ).readAsString();

      expect(source, contains('class PasswordResetScreen'));
      expect(source, contains('_PasswordResetStep.request'));
      expect(source, contains('_PasswordResetStep.verify'));
      expect(source, contains('l10n.passwordResetIdentifierLabel'));
      expect(source, contains('auth.startPasswordReset('));
      expect(source, contains('auth.verifyPasswordReset('));
      expect(source, contains("ctx.go('/login')"));
    },
  );

  test(
    'password reset screen avoids double keyboard inset and top-aligns form',
    () async {
      final source = await File(
        'lib/screens/auth/password_reset_screen.dart',
      ).readAsString();

      expect(source, contains('resizeToAvoidBottomInset: true'));
      expect(source, contains('alignment: Alignment.topCenter'));
      expect(
        source,
        isNot(contains('MediaQuery.viewInsetsOf(context).bottom')),
      );
      expect(source, isNot(contains('AnimatedPadding')));
    },
  );

  test(
    'password reset screen does not auto-focus code field after start',
    () async {
      final source = await File(
        'lib/screens/auth/password_reset_screen.dart',
      ).readAsString();

      expect(source, contains('_dismissKeyboardBeforeStepChange();'));
      expect(
        source,
        contains('_dismissKeyboardBeforeStepChange();\n      setState(() {'),
      );
      expect(
        source,
        isNot(
          contains(
            '_showVerifyValidation = false;\n'
            '      });\n'
            '      _codeFocusNode.requestFocus();',
          ),
        ),
      );
    },
  );

  test('password reset resend code action is protected by countdown', () async {
    final source = await File(
      'lib/screens/auth/password_reset_screen.dart',
    ).readAsString();

    expect(source, contains('static const int _resendCooldownSeconds = 60'));
    expect(source, contains('Timer? _resendCooldownTimer;'));
    expect(source, contains('int _resendRemainingSeconds = 0;'));
    expect(source, contains('void _startResendCooldown()'));
    expect(source, contains('String _formatResendCountdown()'));
    expect(source, contains('_startResendCooldown();'));
    expect(
      source,
      matches(
        RegExp(
          r'onPressed:\s*canResendPasswordResetCode\s*\?\s*_resendPasswordResetCode\s*:\s*null',
        ),
      ),
    );
    expect(source, contains('l10n.passwordResetResendCodeCountdown'));
  });
}
