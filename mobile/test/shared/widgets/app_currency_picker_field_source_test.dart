import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'currency picker sheet supports searching reference currencies',
    () async {
      final source = await File(
        'lib/shared/widgets/app_currency_picker_field.dart',
      ).readAsString();

      expect(source, contains('class _AppCurrencyPickerSheet'));
      expect(source, contains('TextEditingController _searchController'));
      expect(source, contains('List<AppCurrencyOption> _visibleOptions'));
      expect(source, contains('profileCurrencySearchHint'));
      expect(source, contains('profileCurrencyNoResults'));
      expect(source, contains('option.label(l10n)'));
      expect(source, contains('option.symbol'));
      expect(source, contains('option.code'));
      expect(source, contains('AppModalSheetFrame('));
      expect(source, contains('width: double.infinity'));
      expect(source, contains('ListView.separated'));
    },
  );

  test('currency picker sheet remains usable when keyboard is open', () async {
    final source = await File(
      'lib/shared/widgets/app_currency_picker_field.dart',
    ).readAsString();

    expect(source, contains('LayoutBuilder('));
    expect(source, contains('_currencyPickerMaxHeightAboveKeyboard(context)'));
    expect(source, contains('ConstrainedBox('));
    expect(source, contains('Flexible('));
    expect(
      source,
      isNot(contains('padding: AppEdgeInsets.only(bottom: bottomInset)')),
    );
  });
}
