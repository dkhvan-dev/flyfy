import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('currency converter screen is localized and adaptive', () async {
    final source = await File(
      'lib/screens/currency/currency_converter_screen.dart',
    ).readAsString();

    expect(source, contains('class CurrencyConverterScreen'));
    expect(source, contains('l10n.currencyConverterTitle'));
    expect(source, contains('l10n.currencyConverterYouSend'));
    expect(source, contains('l10n.currencyConverterYouReceive'));
    expect(source, contains('l10n.currencyConverterQuickSwitch'));
    expect(source, contains('class _CurrencyPickerScreen'));
    expect(source, contains('l10n.currencyConverterSelectCurrencyTitle'));
    expect(source, contains('l10n.currencyConverterSearchCurrencyHint'));
    expect(source, contains('_localizedCurrencyName(currency, l10n)'));
    expect(source, contains('String _currencyFlagEmoji(String code)'));
    expect(source, contains('SingleChildScrollView'));
    expect(source, contains('SafeArea'));
    expect(source, contains('Wrap('));
    expect(source, contains('TextOverflow.ellipsis'));
    expect(source, contains('CurrencyApi'));
    expect(source, isNot(contains('DropdownButtonFormField')));
    expect(source, isNot(contains('code.substring(0, 2)')));
  });

  test('home service grid links to the currency converter route', () async {
    final homeSource = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();
    final catalogSource = await File(
      'lib/features/services/service_catalog.dart',
    ).readAsString();
    final routerSource = await File(
      'lib/core/router/app_router.dart',
    ).readAsString();
    final ruArb = await File('lib/l10n/app_ru.arb').readAsString();
    final enArb = await File('lib/l10n/app_en.arb').readAsString();
    final kkArb = await File('lib/l10n/app_kk.arb').readAsString();

    expect(homeSource, contains('buildTravelServiceCatalog('));
    expect(catalogSource, contains('l10n.homeServiceCurrencyConverter'));
    expect(catalogSource, contains("route: '/currency-converter'"));
    expect(routerSource, contains("path: '/currency-converter'"));
    expect(routerSource, contains('CurrencyConverterScreen'));
    expect(ruArb, contains('homeServiceCurrencyConverter'));
    expect(enArb, contains('homeServiceCurrencyConverter'));
    expect(kkArb, contains('homeServiceCurrencyConverter'));
  });
}
