import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('edit profile screen uses adaptive V2 design system colors', () async {
    final source = await File(
      'lib/screens/profile/edit_profile_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
