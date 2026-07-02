import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('community discovery screen uses V2 adaptive colors', () async {
    final source = await File(
      'lib/features/feed/presentation/community_discovery_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.background'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
