import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('story document renderer uses adaptive V2 colors directly', () async {
    final source = await File(
      'lib/features/stories/widgets/story_document_renderer.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, contains('colors.primary'));
    expect(source, isNot(contains('AppPalette.')));
    expect(source, isNot(contains('StoryPalette.')));
  });
}
