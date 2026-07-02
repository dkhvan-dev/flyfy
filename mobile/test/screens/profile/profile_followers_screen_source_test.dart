import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile followers screen uses V2 adaptive colors', () async {
    final source = await File(
      'lib/screens/profile/profile_followers_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.screenGradientColors'));
    expect(source, contains('_followersCardDecoration('));
    expect(source, contains('AppColors colors'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.surfaceRaised'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, isNot(contains('AppPalette.')));
    expect(source, isNot(contains('ProfileGlassBackground(')));
    expect(source, isNot(contains('ProfileTopIconButton(')));
    expect(source, isNot(contains('profileCardDecoration(')));
    expect(source, isNot(contains('profileTextMuted')));
    expect(source, isNot(contains('profileBorder')));
  });
}
