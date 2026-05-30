import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:inflap/shared/formatters/app_money_formatter.dart';

void main() {
  test('formats money with app-wide localized currency symbols', () {
    final label = formatAppMoney(
      amount: 12500,
      currency: 'KZT',
      localeName: 'ru',
      compact: true,
    );

    expect(label, contains('₸'));
    expect(label, isNot(contains('KZT')));
  });

  test('formats list money the same way guide dashboard does', () {
    final expected = NumberFormat.simpleCurrency(
      name: 'USD',
      decimalDigits: 0,
    ).format(50);

    final label = formatAppMoney(
      amount: 50,
      currency: 'USD',
      localeName: 'ru',
      useListCurrencyFormat: true,
    );

    expect(label, expected);
  });

  test('normalizes currency and resolves country default currency', () {
    expect(normalizeAppCurrencyCode(' usd '), 'USD');
    expect(appCurrencyForCountryCode('kz'), 'KZT');
    expect(resolveAppCurrencyCode(currency: null, countryCode: 'GB'), 'GBP');
  });
}
