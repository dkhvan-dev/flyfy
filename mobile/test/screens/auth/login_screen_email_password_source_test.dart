import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login screen separates login and registration flows', () async {
    final source = await File(
      'lib/screens/auth/login_screen.dart',
    ).readAsString();

    expect(source, contains('enum _AuthEntryMode'));
    expect(source, contains('_AuthEntryMode.login'));
    expect(source, contains('_AuthEntryMode.register'));
    expect(source, contains('l10n.authLoginTab'));
    expect(source, contains('l10n.authRegisterTab'));
    expect(source, contains('_identifierController'));
    expect(source, contains('_loginPasswordController'));
    expect(source, contains('_registerEmailController'));
    expect(source, contains('_registerPasswordController'));
    expect(source, contains('_confirmPasswordController'));
    expect(source, contains('loginWithPassword('));
    expect(source, contains('startEmailRegistration('));
    expect(source, contains("'mode': 'emailRegistration'"));
    expect(source, isNot(contains('sendOtp(phone)')));
    expect(source, isNot(contains('_PhonePrefixFormatter')));
  });
}
