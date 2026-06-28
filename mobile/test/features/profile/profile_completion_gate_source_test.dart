import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile completion gate uses excursions filter sheet palette', () {
    final gateSource = File(
      'lib/features/profile/profile_completion_gate.dart',
    ).readAsStringSync();
    final chromeSource = File(
      'lib/core/ui/filter_sheet_chrome.dart',
    ).readAsStringSync();

    expect(
      gateSource,
      contains("import '../../core/ui/filter_sheet_chrome.dart';"),
    );
    expect(gateSource, contains('AppFilterPaletteDialog('));
    expect(gateSource, contains('Icons.manage_accounts_rounded'));
    expect(gateSource, isNot(contains('AlertDialog(')));

    expect(chromeSource, contains('class AppFilterPaletteDialog'));
    expect(chromeSource, contains('AppPalette.surface'));
    expect(chromeSource, contains('AppPalette.border'));
    expect(chromeSource, contains('AppPalette.warmSurface28'));
    expect(chromeSource, contains('AppPalette.warmSurface66'));
    expect(chromeSource, contains('AppPalette.primary'));
    expect(chromeSource, contains('SingleChildScrollView'));
    expect(chromeSource, contains('Wrap('));
  });
}
