import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'place details find excursions CTA opens matching excursion or list fallback',
    () async {
      final source = await File(
        'lib/screens/places/place_details_screen.dart',
      ).readAsString();

      final ctaStart = source.indexOf('Widget _buildBottomCta');
      expect(ctaStart, isNonNegative);
      final ctaSource = source.substring(ctaStart);

      expect(source, contains('Future<void> _openExcursionsForPlace()'));
      expect(source, contains('findFirstExcursionForPlace('));
      expect(
        source,
        contains("'/excursions/\${Uri.encodeComponent(excursionId)}'"),
      );
      expect(source, contains('ExcursionsRouteArgs.noPlaceExcursions('));
      expect(ctaSource, contains('_isOpeningExcursions'));
      expect(ctaSource, contains('? null'));
      expect(ctaSource, contains(': _openExcursionsForPlace'));
      expect(ctaSource, isNot(contains('onPressed: () {}')));
    },
  );
}
