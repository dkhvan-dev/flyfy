import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile activity cards use V2 adaptive colors', () async {
    final source = await File(
      'lib/screens/profile/widgets/profile_activity_card.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('_profileActivityCardDecoration(context, colors)'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.surfaceRaised'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, isNot(contains('profileCardDecoration(context')));
    expect(source, isNot(contains('profileTextSoft')));
    expect(source, isNot(contains('profileTextMuted')));
    expect(source, isNot(contains('AppPalette.')));
  });
}
