import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/currency/data/currency_api.dart';
import 'package:inflap/features/currency/data/currency_catalog_repository.dart';
import 'package:inflap/features/currency/models/currency_conversion_result.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/shared/widgets/app_currency_picker_field.dart';

void main() {
  testWidgets(
    'searches the reference catalog by localized name code and symbol',
    (tester) async {
      String? selectedCode;
      final repository = CurrencyCatalogRepository(
        api: _CurrencyApiStub(const [
          CurrencyOption(code: 'VND', name: 'Вьетнамский донг', symbol: '₫'),
          CurrencyOption(code: 'THB', name: 'Тайский бат', symbol: '฿'),
        ]),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppCurrencyPickerField(
              label: 'Валюта',
              selectedCode: 'KZT',
              currencyCatalogRepository: repository,
              onChanged: (value) => selectedCode = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('тенге'));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'вьетнам');
      await tester.pump();
      expect(find.text('Вьетнамский донг'), findsOneWidget);
      expect(find.text('Тайский бат'), findsNothing);

      await tester.enterText(searchField, '฿');
      await tester.pump();
      expect(find.text('Тайский бат'), findsOneWidget);

      await tester.enterText(searchField, 'VND');
      await tester.pump();
      expect(find.text('Вьетнамский донг'), findsOneWidget);
      await tester.tap(find.text('Вьетнамский донг'));
      await tester.pumpAndSettle();

      expect(selectedCode, 'VND');
    },
  );
}

class _CurrencyApiStub extends CurrencyApi {
  _CurrencyApiStub(this.items);

  final List<CurrencyOption> items;

  @override
  Future<List<CurrencyOption>> listCurrencies({String? locale}) async => items;
}
