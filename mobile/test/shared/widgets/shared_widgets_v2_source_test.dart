import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selected shared widgets consume adaptive v2 colors', () async {
    final paths = [
      'lib/shared/widgets/trip_preparation_cta.dart',
      'lib/shared/widgets/app_currency_picker_field.dart',
      'lib/shared/widgets/app_map_attribution.dart',
      'lib/shared/widgets/app_city_filter_section.dart',
    ];

    for (final path in paths) {
      final source = await File(path).readAsString();

      expect(
        source,
        contains('AppDesignSystem.colorsFor(context)'),
        reason: path,
      );
      expect(source, isNot(contains('AppPalette.')), reason: path);
    }
  });
}
