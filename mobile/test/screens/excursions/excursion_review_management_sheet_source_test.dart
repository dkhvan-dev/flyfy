import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('excursion review management sheets use V2 colors', () async {
    final source = await File(
      'lib/screens/excursions/widgets/excursion_review_management_sheet.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.secondary'));
    expect(source, contains('colors.secondaryContainer'));
    expect(source, contains('colors.borderSecondary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.danger'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'excursion review edit sheet uses secondary only for neutral metadata hint',
    () async {
      final source = await File(
        'lib/screens/excursions/widgets/excursion_review_management_sheet.dart',
      ).readAsString();
      final hintStart = source.indexOf('class _ExcursionReviewMetadataHint');
      final editStart = source.indexOf('class _ExcursionReviewEditSheet');

      expect(hintStart, isNonNegative);
      expect(editStart, isNonNegative);

      final hintSource = source.substring(hintStart, editStart);
      final editSource = source.substring(editStart);

      expect(hintSource, contains('colors.secondaryContainer'));
      expect(hintSource, contains('colors.borderSecondary'));
      expect(hintSource, contains('color: colors.secondary'));
      expect(hintSource, contains('l10n.myExcursionsReviewRating'));
      expect(editSource, contains('_ExcursionReviewMetadataHint('));
      expect(editSource, contains('color: colors.primary'));
      expect(source, contains('colors.danger'));
    },
  );
}
