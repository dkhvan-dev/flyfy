import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'home location picker uses secondary for location context and neutral states',
    () async {
      final source = await File(
        'lib/screens/home/widgets/home_location_picker_sheet.dart',
      ).readAsString();

      final previewStart = source.indexOf('class _CurrentLocationPreview');
      final detectStart = source.indexOf('class _DetectLocationButton');
      final searchStart = source.indexOf('class _LocationSearchField');
      final cityTileStart = source.indexOf('class _CityResultTile');
      final messageStart = source.indexOf('class _LocationMessage');

      expect(previewStart, isNonNegative);
      expect(detectStart, greaterThan(previewStart));
      expect(searchStart, greaterThan(detectStart));
      expect(cityTileStart, greaterThan(searchStart));
      expect(messageStart, greaterThan(cityTileStart));

      final previewSource = source.substring(previewStart, detectStart);
      final detectSource = source.substring(detectStart, searchStart);
      final cityTileSource = source.substring(cityTileStart, messageStart);
      final messageSource = source.substring(messageStart);

      expect(previewSource, contains('colors.secondaryContainer'));
      expect(previewSource, contains('colors.borderSecondary'));
      expect(previewSource, contains('color: colors.secondary'));
      expect(detectSource, contains('foregroundColor: colors.primary'));
      expect(detectSource, contains('BorderSide(color: colors.borderPrimary)'));
      expect(cityTileSource, contains('color: colors.secondary'));
      expect(messageSource, contains('color ?? colors.secondary'));
    },
  );

  test(
    'home location picker apply footer stays close to bottom edge',
    () async {
      final source = await File(
        'lib/screens/home/widgets/home_location_picker_sheet.dart',
      ).readAsString();

      final buildStart = source.indexOf('@override\n  Widget build');
      final previewStart = source.indexOf('class _CurrentLocationPreview');

      expect(buildStart, isNonNegative);
      expect(previewStart, greaterThan(buildStart));

      final buildSource = source.substring(buildStart, previewStart);

      expect(
        buildSource,
        contains(
          'SafeArea(\n            top: false,\n            bottom: false,',
        ),
      );
      expect(
        buildSource,
        contains(
          'padding: AppEdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset)',
        ),
      );
    },
  );
}
