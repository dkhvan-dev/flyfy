import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('discover empty states suggest trying another city', () async {
    final enArb = await File('lib/l10n/app_en.arb').readAsString();
    final ruArb = await File('lib/l10n/app_ru.arb').readAsString();
    final kkArb = await File('lib/l10n/app_kk.arb').readAsString();
    final placesScreen = await File(
      'lib/screens/places/places_screen.dart',
    ).readAsString();

    expect(
      enArb,
      contains(
        '"activitiesFilteredEmptySubtitle": '
        '"Try widening the category, date range, pricing filters, or choose another city"',
      ),
    );
    expect(
      enArb,
      contains(
        '"placesNoResultsSubtitle": "Try choosing another city in filters."',
      ),
    );
    expect(
      enArb,
      contains(
        '"excursionsEmptySubtitle": '
        '"Verified guide routes will appear here. Try choosing another city in filters."',
      ),
    );
    expect(
      enArb,
      contains(
        '"guidesNoResultsSubtitle": '
        '"Try another city, name, expertise, language, or filter."',
      ),
    );

    expect(ruArb, contains('выбрать другой город'));
    expect(kkArb, contains('басқа қаланы'));
    expect(placesScreen, contains('l10n.placesNoResultsSubtitle'));
  });
}
