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

  test('oauth buttons expose semantic button targets', () async {
    final source = await File(
      'lib/screens/auth/login_screen.dart',
    ).readAsString();
    final buttonStart = source.indexOf('class _OAuthButton');

    expect(buttonStart, isNonNegative);

    final buttonSource = source.substring(buttonStart);

    expect(buttonSource, contains('Semantics('));
    expect(buttonSource, contains('button: true'));
    expect(buttonSource, contains('enabled: onPressed != null'));
    expect(buttonSource, contains('label: label'));
    expect(buttonSource, contains('ExcludeSemantics('));
  });

  test('auth header exposes public app settings shortcut', () async {
    final source = await File(
      'lib/screens/auth/login_screen.dart',
    ).readAsString();
    final routerSource = await File(
      'lib/core/router/app_router.dart',
    ).readAsString();

    expect(source, contains("context.push('/app-settings')"));
    expect(source, contains("'auth-app-settings-button'"));
    expect(source, contains('tooltip: l10n.profileSettingsPageTitle'));
    expect(source, contains('widget.initialRegister'));
    expect(routerSource, contains("path: '/app-settings'"));
    expect(routerSource, contains("queryParameters['mode'] == 'register'"));
  });

  test('primary auth action uses the design-system on-primary color', () async {
    final source = await File(
      'lib/screens/auth/login_screen.dart',
    ).readAsString();
    final buttonStart = source.indexOf('class _PrimaryAuthButton');
    final buttonEnd = source.indexOf('class _OAuthButton', buttonStart);

    expect(buttonStart, isNonNegative);
    expect(buttonEnd, greaterThan(buttonStart));

    final buttonSource = source.substring(buttonStart, buttonEnd);
    expect(buttonSource, contains('context.appColors.onPrimary'));
    expect(buttonSource, isNot(contains(': context.appColors.textPrimary;')));
  });

  test(
    'authenticated entry keeps previous route under protected target',
    () async {
      final source = await File(
        'lib/screens/auth/login_screen.dart',
      ).readAsString();
      final otpSource = await File(
        'lib/screens/auth/otp_screen.dart',
      ).readAsString();
      final helperStart = source.indexOf('void _finishAuthenticatedNavigation');

      expect(helperStart, isNonNegative);

      final helperEnd = source.indexOf('enum _OAuthProvider', helperStart);
      expect(helperEnd, greaterThan(helperStart));

      final helperSource = source.substring(helperStart, helperEnd);

      expect(
        source,
        contains('_finishAuthenticatedNavigation(ctx, widget.from)'),
      );
      expect(helperSource, contains('ctx.pushReplacement(target)'));
      expect(helperSource, contains("ctx.go('/')"));
      expect(helperSource, isNot(contains('ctx.go(target)')));
      expect(source, contains('ctx.pushReplacement(uri.toString())'));
      expect(source, isNot(contains('ctx.go(widget.from ??')));
      expect(
        otpSource,
        contains('_finishOtpAuthenticatedNavigation(ctx, widget.from)'),
      );
      expect(otpSource, contains('ctx.pushReplacement(target)'));
      expect(otpSource, isNot(contains('ctx.go(widget.from?.isNotEmpty')));
    },
  );
}
