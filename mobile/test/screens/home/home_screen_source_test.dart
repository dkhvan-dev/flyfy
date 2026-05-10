import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('top destinations cards size their footer from scaled text metrics',
      () async {
    final source =
        await File('lib/screens/home/home_screen.dart').readAsString();
    final rowStart = source.indexOf('class _TopDestinationsRow');
    final rowEnd = source.indexOf('class _TopDestinationAttractionCard');
    final cardStart = rowEnd;
    final cardEnd = source.indexOf('class _DestinationBookmarkBadge');

    expect(rowStart, isNonNegative);
    expect(rowEnd, greaterThan(rowStart));
    expect(cardEnd, greaterThan(cardStart));

    final rowSource = source.substring(rowStart, rowEnd);
    final cardSource = source.substring(cardStart, cardEnd);

    expect(rowSource, contains('_homeTopDestinationCardHeight'));
    expect(rowSource, isNot(contains('final infoHeight =')));
    expect(cardSource,
        contains('final textScale = _homeTextScaleFactor(context);'));
    expect(cardSource, contains('_homeTopDestinationTitleBlockHeight'));
  });

  test('language sheet is height constrained and scrollable', () async {
    final source =
        await File('lib/screens/home/home_screen.dart').readAsString();
    final sheetStart = source.indexOf('Future<void> _showLanguageSheet()');
    final sheetEnd = source.indexOf('void _ensureGuideBadgeState');

    expect(sheetStart, isNonNegative);
    expect(sheetEnd, greaterThan(sheetStart));

    final sheetSource = source.substring(sheetStart, sheetEnd);

    expect(sheetSource, contains('maxSheetHeight'));
    expect(sheetSource, contains('ConstrainedBox'));
    expect(sheetSource, contains('SingleChildScrollView'));
  });
}
