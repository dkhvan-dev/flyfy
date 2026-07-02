import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat image viewer uses adaptive V2 colors directly', () async {
    final source = await File(
      'lib/screens/chat/chat_image_viewer_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.backgroundDeep'));
    expect(source, contains('colors.scrim'));
    expect(source, contains('colors.white'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
