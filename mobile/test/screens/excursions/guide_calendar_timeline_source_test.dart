import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guide calendar timeline uses V2 colors', () async {
    final source = await File(
      'lib/screens/excursions/widgets/guide_calendar_timeline.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
