import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quick post thread card uses adaptive V2 colors only', () {
    final source = File(
      'lib/features/feed/widgets/quick_post_thread_card.dart',
    ).readAsStringSync();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('final isDark'));
    expect(source, contains('color: colors.textPrimary'));
    expect(source, contains('foregroundColor: colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
