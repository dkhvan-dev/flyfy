import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'place list card secondary label stays on short price summary',
    () async {
      final source = await File(
        'lib/screens/places/places_screen.dart',
      ).readAsString();

      final helperStart = source.indexOf('String _secondaryLabel');
      expect(helperStart, isNonNegative);
      final helperEnd = source.indexOf('Widget _ratingBadge', helperStart);
      expect(helperEnd, greaterThan(helperStart));
      final helperSource = source.substring(helperStart, helperEnd);

      expect(helperSource, contains('formatPlacePriceLabel('));
      expect(helperSource, isNot(contains('formatPlaceDurationLabel')));
    },
  );
}
