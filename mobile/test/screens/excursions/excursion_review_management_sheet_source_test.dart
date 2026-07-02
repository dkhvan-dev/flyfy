import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('excursion review management sheets use V2 colors', () async {
    final source = await File(
      'lib/screens/excursions/widgets/excursion_review_management_sheet.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.danger'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
