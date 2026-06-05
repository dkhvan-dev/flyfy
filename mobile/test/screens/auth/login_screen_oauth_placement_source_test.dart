import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'oauth buttons are placed inside auth forms after primary actions',
    () async {
      final source = await File(
        'lib/screens/auth/login_screen.dart',
      ).readAsString();

      final loginForm = source.substring(
        source.indexOf('Widget _buildLoginForm'),
        source.indexOf('Widget _buildRegisterForm'),
      );
      final registerForm = source.substring(
        source.indexOf('Widget _buildRegisterForm'),
        source.indexOf('Widget _buildOAuthButtons'),
      );
      final stackToTerms = source.substring(
        source.indexOf('IndexedStack('),
        source.indexOf('TermsAgreementRichText'),
      );

      expect(
        loginForm.indexOf('label: l10n.authLoginAction'),
        lessThan(
          loginForm.indexOf('_buildOAuthButtons(context, l10n, isNarrow)'),
        ),
      );
      expect(
        registerForm.indexOf('label: l10n.authRegisterAction'),
        lessThan(
          registerForm.indexOf('_buildOAuthButtons(context, l10n, isNarrow)'),
        ),
      );
      expect(stackToTerms, isNot(contains('_buildOAuthButtons')));
    },
  );
}
