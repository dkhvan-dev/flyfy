import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('post create preflight surfaces use V2 adaptive colors', () async {
    final source = await File(
      'lib/features/stories/editor/presentation/post_create_preflight.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(sheetContext)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(sheetContext)'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
