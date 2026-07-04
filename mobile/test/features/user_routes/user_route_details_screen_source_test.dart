import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user route details screen uses V2 design system colors', () async {
    final source = await File(
      'lib/features/user_routes/presentation/user_route_details_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.secondaryContainer'));
    expect(source, contains('colors.borderSecondary'));
    expect(source, contains('colors.secondary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test('user route detail primary actions remain amber', () async {
    final source = await File(
      'lib/features/user_routes/presentation/user_route_details_screen.dart',
    ).readAsString();

    expect(source, contains('backgroundColor: colors.primary'));
    expect(
      source,
      contains(
        'side: BorderSide(color: colors.primary.withValues(alpha: 0.7))',
      ),
    );
  });
}
