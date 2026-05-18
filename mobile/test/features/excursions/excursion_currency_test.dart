import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/excursions/excursion_currency.dart';

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
}
