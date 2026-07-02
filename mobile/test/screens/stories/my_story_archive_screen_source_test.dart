import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('my story archive screen uses adaptive V2 colors', () async {
    final source = await File(
      'lib/screens/stories/my_story_archive_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.screenGradientColors'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.primary'));
    expect(source, isNot(contains('StoryPalette.')));
    expect(source, isNot(contains('AppPalette.')));
  });
}
