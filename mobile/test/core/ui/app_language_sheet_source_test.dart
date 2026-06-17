import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app language sheet is reusable, constrained, and scrollable', () async {
    final source = await File(
      'lib/core/ui/app_language_sheet.dart',
    ).readAsString();

    expect(source, contains('Future<void> showAppLanguageSheet('));
    expect(source, contains('LocaleProvider'));
    expect(source, contains('localeProvider.setLocale(selectedCode)'));
    expect(source, contains('maxSheetHeight'));
    expect(source, contains('ConstrainedBox'));
    expect(source, contains('SingleChildScrollView'));
    expect(source, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
  });

  test('app language sheet options expose selected semantic buttons', () async {
    final source = await File(
      'lib/core/ui/app_language_sheet.dart',
    ).readAsString();
    final optionStart = source.indexOf('class _LanguageOptionTile');

    expect(optionStart, isNonNegative);

    final optionSource = source.substring(optionStart);

    expect(optionSource, contains('Semantics('));
    expect(optionSource, contains('button: true'));
    expect(optionSource, contains('enabled: true'));
    expect(optionSource, contains('selected: isSelected'));
    expect(optionSource, contains('label: label'));
    expect(optionSource, contains('ExcludeSemantics('));
  });
}
