import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/network/reference_api.dart';
import 'package:superapp/core/reference/currency_filter_utils.dart';

void main() {
  test('currency label uses localized reference name instead of code', () {
    const currency = ReferenceCurrency(
      code: 'KZT',
      numeric: '398',
      decimals: 2,
      symbol: '₸',
      name: 'Казахстанский тенге',
    );

    expect(referenceCurrencyLabel(currency), 'Казахстанский тенге');
  });

  test('currency search matches localized name code and symbol', () {
    const currencies = [
      ReferenceCurrency(
        code: 'KZT',
        numeric: '398',
        decimals: 2,
        symbol: '₸',
        name: 'Казахстанский тенге',
      ),
    ];
    final aliases = currencySearchAliasMap(currencies);
    final haystack = currencyFilterSearchHaystack(currencies.first, aliases);

    expect(haystack, contains(normalizeCurrencySearchText('тенге')));
    expect(haystack, contains(normalizeCurrencySearchText('KZT')));
    expect(haystack, contains(normalizeCurrencySearchText('₸')));
  });
}
