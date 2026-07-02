import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('community discovery sheet uses adaptive V2 colors only', () {
    final source = File(
      'lib/features/feed/widgets/community_discovery_sheet.dart',
    ).readAsStringSync();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('AppButtonStyles.primary(colors)'));
    expect(source, contains('_communityDiscoveryCardDecoration('));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, contains('colors.border'));
    expect(source, contains('colors.transparent'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
