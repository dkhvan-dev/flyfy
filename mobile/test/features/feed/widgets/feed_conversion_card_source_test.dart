import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feed conversion card uses V2 design colors only', () {
    final source = File(
      'lib/features/feed/widgets/feed_conversion_card.dart',
    ).readAsStringSync();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('color: colors.secondaryContainer'));
    expect(
      source,
      contains('border: Border.all(color: colors.borderSecondary)'),
    );
    expect(source, contains('Icon(icon, color: colors.secondary'));
    expect(source, contains('AppButtonStyles.primary(colors)'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
