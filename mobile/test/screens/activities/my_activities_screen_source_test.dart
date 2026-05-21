import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'my activities card does not duplicate location under category label',
    () async {
      final source = await File(
        'lib/screens/activities/my_activities_screen.dart',
      ).readAsString();

      final cardStart = source.indexOf('class _MyActivitiesCard');
      final coverStart = source.indexOf('class _ActivityCover');
      expect(cardStart, isNonNegative);
      expect(coverStart, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, coverStart);
      final categoryLabelStart = cardSource.indexOf(
        'normalizedCategoryLabel.toUpperCase()',
      );
      final compactTitleStart = cardSource.indexOf('if (compactCard)');
      expect(categoryLabelStart, isNonNegative);
      expect(compactTitleStart, greaterThan(categoryLabelStart));

      final categoryHeaderSource = cardSource.substring(
        categoryLabelStart,
        compactTitleStart,
      );

      expect(categoryHeaderSource, isNot(contains('locationText')));
      expect(
        cardSource,
        contains(
          'final locationFallbackText = activityLocationFallbackText(item, l10n);',
        ),
      );
      expect(
        cardSource,
        contains('labelBuilder: (style) => AppLocalizedLocationText('),
      );
      expect(cardSource, contains('fallbackText: locationFallbackText'));
      expect(cardSource, isNot(contains('fallbackText: locationText')));
    },
  );
}
