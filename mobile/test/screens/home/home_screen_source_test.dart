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

  test('logout confirmation uses branded adaptive dialog chrome', () async {
    final source =
        await File('lib/screens/home/home_screen.dart').readAsString();
    final confirmStart = source.indexOf('Future<void> _confirmLogout()');
    final confirmEnd = source.indexOf('Future<void> _loadTopAttractions');
    final dialogStart = source.indexOf('class _LogoutConfirmDialog');
    final dialogEnd = source.indexOf('class _HomeHeader');

    expect(confirmStart, isNonNegative);
    expect(confirmEnd, greaterThan(confirmStart));
    expect(dialogStart, isNonNegative);
    expect(dialogEnd, greaterThan(dialogStart));

    final confirmSource = source.substring(confirmStart, confirmEnd);
    final dialogSource = source.substring(dialogStart, dialogEnd);

    expect(confirmSource, contains('_LogoutConfirmDialog('));
    expect(confirmSource, isNot(contains('AlertDialog(')));
    expect(dialogSource, contains('Icons.logout_rounded'));
    expect(dialogSource, contains('LinearGradient'));
    expect(dialogSource, contains('Wrap('));
    expect(dialogSource, contains('AppColors.accent'));
  });

  test('excursions quick action opens the excursions list screen', () async {
    final source =
        await File('lib/screens/home/home_screen.dart').readAsString();

    expect(source, contains('void _openExcursions()'));
    expect(source, contains("context.push('/excursions')"));
    expect(source, contains('onTap: _openExcursions'));
  });
}
