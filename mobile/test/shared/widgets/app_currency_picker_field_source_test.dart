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
      expect(source, contains('List<CurrencyOption> _visibleOptions'));
      expect(source, contains('CurrencyCatalogRepository'));
      expect(source, contains('listCurrencies('));
      expect(source, contains('profileCurrencySearchHint'));
      expect(source, contains('profileCurrencyNoResults'));
      expect(source, contains('option.name'));
      expect(source, contains('option.symbol'));
      expect(source, contains('option.code'));
      expect(source, contains('AppModalSheetFrame('));
      expect(source, contains('width: double.infinity'));
      expect(source, contains('ListView.separated'));
      expect(source, isNot(contains('const appCurrencyOptions =')));
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

  test(
    'currency picker delegates physical-bottom safety to app modal template',
    () async {
      final source = await File(
        'lib/shared/widgets/app_currency_picker_field.dart',
      ).readAsString();
      final modalSource = await File(
        'lib/core/ui/app_modal_templates.dart',
      ).readAsString();

      expect(source, isNot(contains('extendSheetToBottom')));
      expect(source, isNot(contains('extendToBottom')));
      expect(source, isNot(contains('systemBottomPadding')));
      expect(source, contains('AppEdgeInsets.fromLTRB(16, 12, 16, 16)'));
      expect(
        modalSource,
        contains("ValueKey('app-modal-custom-sheet-surface')"),
      );
      expect(modalSource, contains('navigationSafeInset'));
    },
  );
}
