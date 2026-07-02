import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile notifications screen uses V2 design colors only', () async {
    final source = await File(
      'lib/screens/profile/profile_notifications_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.screenGradientColors'));
    expect(source, contains('colors.primary'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
