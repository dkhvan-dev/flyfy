import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile security screen provides OTP password change flow', () async {
    final source = await File(
      'lib/screens/profile/profile_security_screen.dart',
    ).readAsString();

    expect(source, contains('profileSecurityPasswordTitle'));
    expect(source, contains('showModalBottomSheet<void>'));
    expect(source, contains('isDismissible: true'));
    expect(source, isNot(contains('showDialog<void>')));
    expect(source, isNot(contains('FractionallySizedBox(')));
    expect(source, contains('Alignment.bottomCenter'));
    expect(source, contains('heightFactor: 1'));
    expect(source, contains('AnimatedPadding('));
    expect(source, contains('EdgeInsets.only(bottom: bottomInset)'));
    expect(source, contains('maxHeight: availableHeight * 0.92'));
    expect(source, contains('Flexible('));
    expect(source, contains('class _PasswordChangeActions'));
    expect(
      source.indexOf('SingleChildScrollView'),
      lessThan(source.indexOf('_PasswordChangeActions(')),
    );
    expect(source, contains('class _ChangePasswordSheet'));
    expect(source, contains('auth.startPasswordChange('));
    expect(source, contains('auth.verifyPasswordChange('));
    expect(
      source,
      contains(
        'String? _firstPasswordChangeValidationError({required bool requireCode})',
      ),
    );
    expect(
      source,
      matches(
        RegExp(r'_firstPasswordChangeValidationError\(\s*requireCode: false'),
      ),
    );
    expect(
      source,
      matches(
        RegExp(r'_firstPasswordChangeValidationError\(\s*requireCode: true'),
      ),
    );
    expect(
      source.indexOf('label: l10n.profileSecurityPasswordNewLabel'),
      lessThan(source.indexOf('if (_codeSent) ...[')),
    );
    expect(
      source.indexOf('label: l10n.passwordResetCodeLabel'),
      greaterThan(source.indexOf('if (_codeSent) ...[')),
    );
    expect(
      source,
      contains('static const int _changePasswordCooldownSeconds = 60'),
    );
    expect(source, contains('profileSecurityPasswordResendCodeCountdown'));
    expect(source, contains('SingleChildScrollView'));
  });
}
