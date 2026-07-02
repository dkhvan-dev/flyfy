import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('activity category decorative art uses adaptive V2 colors', () async {
    final source = await File(
      'lib/features/activities/activity_category_art.dart',
    ).readAsString();

    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('enum ActivityCardArtTone'));
    expect(source, contains('List<Color> colorsFor(BuildContext context)'));
    expect(source, isNot(contains('AppPalette.')));
  });
}
