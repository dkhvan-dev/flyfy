import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat screen uses adaptive V2 colors only', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('chatColors.primary'));
    expect(source, contains('chatColors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
