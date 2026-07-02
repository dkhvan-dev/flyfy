import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat participants screen uses adaptive V2 colors directly', () async {
    final source = await File(
      'lib/screens/chat/chat_participants_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.background'));
    expect(source, contains('colors.screenGradientColors'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
