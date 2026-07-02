import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile screen uses adaptive V2 design system colors', () async {
    final source = await File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test('profile style helpers use V2 design system colors', () async {
    final source = await File(
      'lib/screens/profile/profile_style.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test('profile shell background uses shared V2 screen gradient', () async {
    final source = await File(
      'lib/screens/profile/profile_style.dart',
    ).readAsString();

    final backgroundStart = source.indexOf('class ProfileGlassBackground');
    expect(backgroundStart, isNonNegative);

    final backgroundSource = source.substring(backgroundStart);

    expect(backgroundSource, contains('colors.screenGradientColors'));
    expect(
      backgroundSource,
      isNot(contains('[colors.backgroundDeep, colors.background]')),
    );
  });
}
