import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'attraction details find excursions CTA opens matching excursion or list fallback',
    () async {
      final source = await File(
        'lib/screens/attractions/attraction_details_screen.dart',
      ).readAsString();

      final ctaStart = source.indexOf('Widget _buildBottomCta');
      expect(ctaStart, isNonNegative);
      final ctaSource = source.substring(ctaStart);

      expect(source, contains('Future<void> _openExcursionsForAttraction()'));
      expect(source, contains('findFirstExcursionForAttraction('));
      expect(
        source,
        contains("context.push('/excursions/\${Uri.encodeComponent"),
      );
      expect(source, contains('ExcursionsRouteArgs.noAttractionExcursions('));
      expect(ctaSource, contains('_isOpeningExcursions'));
      expect(ctaSource, contains('? null'));
      expect(ctaSource, contains(': _openExcursionsForAttraction'));
      expect(ctaSource, isNot(contains('onPressed: () {}')));
    },
  );
}
