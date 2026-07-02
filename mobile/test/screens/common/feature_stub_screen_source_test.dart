import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature stub screen consumes adaptive v2 colors', () async {
    final source = await File(
      'lib/screens/common/feature_stub_screen.dart',
    ).readAsString();

    expect(
      source,
      contains("import 'package:inflap/core/ui/app_design_system.dart';"),
    );
    expect(
      source,
      contains('final colors = AppDesignSystem.colorsFor(context)'),
    );
    expect(source, contains('Theme.of(context).brightness == Brightness.dark'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test('feature stub background uses shared V2 screen gradient', () async {
    final source = await File(
      'lib/screens/common/feature_stub_screen.dart',
    ).readAsString();

    expect(source, contains('colors: colors.screenGradientColors'));
    expect(
      source,
      isNot(contains('[colors.backgroundDeep, colors.background')),
    );
  });
}
