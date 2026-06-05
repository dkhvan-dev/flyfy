import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email password auth exposes separated primary actions', () async {
    final source = await File(
      'lib/screens/auth/login_screen.dart',
    ).readAsString();

    expect(source, contains('_PrimaryAuthButton('));
    expect(source, contains('label: l10n.authLoginAction'));
    expect(source, contains('label: l10n.authRegisterAction'));
    expect(source, contains('isLoading: auth.isPasswordLoginLoading'));
    expect(source, contains('isLoading: auth.isEmailRegistrationLoading'));
    expect(source, contains('onPressed: canSubmit ? _submitLogin : null'));
    expect(
      source,
      contains('onPressed: canSubmit ? _submitRegistration : null'),
    );
    expect(source, isNot(contains('label: Flexible(')));
    expect(source, contains('IndexedStack('));
    expect(source, isNot(contains('AnimatedSwitcher(')));
  });
}
