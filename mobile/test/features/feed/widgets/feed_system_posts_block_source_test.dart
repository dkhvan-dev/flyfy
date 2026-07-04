import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feed system posts block uses adaptive V2 colors only', () {
    final source = File(
      'lib/features/feed/widgets/feed_system_posts_block.dart',
    ).readAsStringSync();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('color: colors.textPrimary'));
    expect(source, contains('foregroundColor: colors.primary'));
    expect(source, contains('color: colors.secondaryContainer'));
    expect(
      source,
      contains('border: Border.all(color: colors.borderSecondary)'),
    );
    expect(source, contains('color: colors.secondary'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
