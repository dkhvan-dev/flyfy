import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('travel checklist screen uses V2 design system colors', () async {
    final source = await File(
      'lib/screens/checklists/travel_checklist_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'travel checklist root background uses shared V2 screen gradient',
    () async {
      final source = await File(
        'lib/screens/checklists/travel_checklist_screen.dart',
      ).readAsString();

      expect(source, contains('List<Color> get screenGradientColors'));
      expect(source, contains('colors.screenGradientColors'));
      expect(source, contains('colors: palette.screenGradientColors'));
      expect(
        source,
        isNot(contains('colors: [\n                palette.backgroundTop')),
      );
      expect(
        source,
        isNot(
          contains(
            'palette.backgroundWarm,\n                palette.backgroundBottom',
          ),
        ),
      );
    },
  );
}
