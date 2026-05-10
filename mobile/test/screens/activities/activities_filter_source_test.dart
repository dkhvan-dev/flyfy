import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('discover activities filter uses the full-width shared apply button',
      () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();
    final scaffoldStart = source.indexOf('class _RangeSheetScaffold');
    final scaffoldEnd = source.indexOf('class _RangeTextField');

    expect(scaffoldStart, isNonNegative);
    expect(scaffoldEnd, greaterThan(scaffoldStart));

    final scaffoldSource = source.substring(scaffoldStart, scaffoldEnd);

    expect(scaffoldSource, contains('AppFilterApplyButton'));
    expect(scaffoldSource, isNot(contains('_PrimaryPillButton(')));
  });
}
