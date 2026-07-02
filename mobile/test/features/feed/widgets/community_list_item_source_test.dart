import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('community list item uses adaptive V2 colors only', () {
    final source = File(
      'lib/features/feed/widgets/community_list_item.dart',
    ).readAsStringSync();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('color: colors.textPrimary'));
    expect(source, contains('foregroundColor: colors.primary'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
