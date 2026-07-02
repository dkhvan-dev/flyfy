import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'auth and registration screen is migrated to adaptive v2 design system',
    () async {
      final source = await File(
        'lib/screens/auth/login_screen.dart',
      ).readAsString();

      expect(source, contains('app_design_system.dart'));
      expect(source, contains('AppDesignSystem.themeFor(context)'));
      expect(
        source,
        contains('final colors = AppDesignSystem.colorsFor(context)'),
      );
      expect(source, contains('AppPalette.primary'));
      expect(source, contains('AppPalette.secondary'));
      expect(
        source,
        matches(
          RegExp(r'AppButtonStyles\.primary\(\s*context\.appColors\s*,?\s*\)'),
        ),
      );
      expect(source, contains('context.appColors.textPrimary'));
      expect(source, isNot(contains('AppPalette.onPrimary')));
      expect(source, isNot(contains('AppPalette.backgroundWarm')));
      expect(source, isNot(contains('AppPalette.textCoolSecondary')));
    },
  );

  test('auth entry actions use requested v2 text colors', () async {
    final source = await File(
      'lib/screens/auth/login_screen.dart',
    ).readAsString();
    final switchStart = source.indexOf('class _AuthModeSwitch');
    final fieldStart = source.indexOf('class _AuthTextField');
    final buttonStart = source.indexOf('class _PrimaryAuthButton');
    final oauthStart = source.indexOf('class _OAuthButton');

    expect(switchStart, isNonNegative);
    expect(fieldStart, greaterThan(switchStart));
    expect(buttonStart, isNonNegative);
    expect(oauthStart, greaterThan(buttonStart));

    final switchSource = source.substring(switchStart, fieldStart);
    final buttonSource = source.substring(buttonStart, oauthStart);

    expect(
      source,
      matches(RegExp(r"l10n\.skip,[\s\S]*?color:\s*AppPalette\.primary")),
    );
    expect(switchSource, contains('context.appColors.textPrimary'));
    expect(switchSource, isNot(contains('AppPalette.onPrimary')));
    expect(switchSource, isNot(contains('AppPalette.textSecondary')));
    expect(buttonSource, contains(': context.appColors.textPrimary'));
    expect(buttonSource, contains('color: contentColor'));
  });

  test('auth background keeps a scenic image under the v2 overlay', () async {
    final source = await File(
      'lib/screens/auth/login_screen.dart',
    ).readAsString();
    final backgroundStart = source.indexOf('class _AuthV2Background');
    final paneStart = source.indexOf('class _AuthModePane');

    expect(backgroundStart, isNonNegative);
    expect(paneStart, greaterThan(backgroundStart));

    final backgroundSource = source.substring(backgroundStart, paneStart);

    expect(backgroundSource, contains('_authScenicBackgroundUrl'));
    expect(backgroundSource, contains('Image.network('));
    expect(backgroundSource, contains('fit: BoxFit.cover'));
    expect(backgroundSource, contains('errorBuilder:'));
    expect(backgroundSource, contains('colors.scrim'));
    expect(backgroundSource, contains('BlendMode.lighten'));
  });

  test('otp and password reset screens use the same v2 auth surface', () async {
    final otpSource = await File(
      'lib/screens/auth/otp_screen.dart',
    ).readAsString();
    final resetSource = await File(
      'lib/screens/auth/password_reset_screen.dart',
    ).readAsString();

    for (final source in [otpSource, resetSource]) {
      expect(source, contains('app_design_system.dart'));
      expect(source, contains('AppDesignSystem.themeFor(context)'));
      expect(
        source,
        contains('final colors = AppDesignSystem.colorsFor(context)'),
      );
      expect(source, contains('AppPalette.primary'));
      expect(source, contains('context.appColors.textSecondary'));
      expect(
        source,
        matches(
          RegExp(r'AppButtonStyles\.primary\(\s*context\.appColors\s*,?\s*\)'),
        ),
      );
      expect(source, contains('context.appColors.textPrimary'));
      expect(source, isNot(contains('AppPalette.onPrimary')));
      expect(source, isNot(contains('AppPalette.backgroundWarm')));
      expect(source, isNot(contains('AppPalette.textCoolSecondary')));
    }
  });

  test('otp submit action uses textPrimary on the primary button', () async {
    final source = await File(
      'lib/screens/auth/otp_screen.dart',
    ).readAsString();

    expect(
      source,
      matches(
        RegExp(
          r'l10n\.verifyAndLogin[\s\S]*?color:\s*canSubmit\s*\?\s*context\s*\.\s*appColors\s*\.\s*textPrimary\s*:\s*AppPalette\s*\.\s*textDisabled',
        ),
      ),
    );
  });
}
