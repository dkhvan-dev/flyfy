import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:inflap/features/excursions/excursion_currency.dart';

void main() {
  test('formats tenge with localized compact number and currency symbol', () {
    final label = formatLocalizedExcursionMoney(
      amount: 12500,
      currency: 'KZT',
      localeName: 'ru',
      compact: true,
    );

    expect(label, contains('₸'));
    expect(label, isNot(contains('KZT')));
  });

  test('uses localized symbols for common currencies instead of codes', () {
    expect(localizedExcursionCurrencySymbol('KZT'), '₸');
    expect(localizedExcursionCurrencySymbol('usd'), r'$');
    expect(localizedExcursionCurrencySymbol('EUR'), '€');
    expect(localizedExcursionCurrencySymbol('RUB'), '₽');
  });

  test('formats full amount like excursion list when requested', () {
    final expected = NumberFormat.simpleCurrency(
      name: 'KZT',
      decimalDigits: 0,
    ).format(5250);

    final label = formatLocalizedExcursionMoney(
      amount: 5250,
      currency: 'KZT',
      localeName: 'ru',
      useExcursionListCurrencyFormat: true,
    );

    expect(label, expected);
  });

  test('formats common foreign currencies like excursion list', () {
    final expected = NumberFormat.simpleCurrency(
      name: 'USD',
      decimalDigits: 0,
    ).format(50);

    final label = formatLocalizedExcursionMoney(
      amount: 50,
      currency: 'USD',
      localeName: 'ru',
      useExcursionListCurrencyFormat: true,
    );

    expect(label, expected);
  });
}
