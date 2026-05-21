import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'activities card does not duplicate location under category label',
    () async {
      final source = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();

      final cardStart = source.indexOf('class _DiscoverActivityCard');
      final metaStart = source.indexOf('class _CardMetaItem');
      expect(cardStart, isNonNegative);
      expect(metaStart, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, metaStart);
      final categoryLabelStart = cardSource.indexOf(
        'categoryLabel.toUpperCase()',
      );
      final titleStart =
          cardSource.indexOf('Text(\n                      item.title');
      expect(categoryLabelStart, isNonNegative);
      expect(titleStart, greaterThan(categoryLabelStart));

      final categoryHeaderSource = cardSource.substring(
        categoryLabelStart,
        titleStart,
      );

      expect(categoryHeaderSource, isNot(contains('locationText')));
    },
  );

  test('activities card location meta uses localized location text', () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();

    final cardStart = source.indexOf('class _DiscoverActivityCard');
    final metaStart = source.indexOf('class _CardMetaItem');
    expect(cardStart, isNonNegative);
    expect(metaStart, greaterThan(cardStart));

    final cardSource = source.substring(cardStart, metaStart);

    expect(
      cardSource,
      contains('labelBuilder: (style) => AppLocalizedLocationText('),
    );
    expect(cardSource, contains('countryCode: item.countryCode'));
    expect(cardSource, contains('cityId: item.cityId'));
    expect(
      cardSource,
      isNot(
        contains(
            '_CardMetaData(icon: Icons.place_outlined, label: locationText)'),
      ),
    );
  });
}
