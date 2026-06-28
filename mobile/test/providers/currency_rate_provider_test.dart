import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/currency/models/currency_conversion_result.dart';
import 'package:inflap/providers/currency_rate_provider.dart';

void main() {
  test('converts amount with a cached latest exchange rate', () async {
    var calls = 0;
    final provider = CurrencyRateProvider(
      latestRates: ({required baseCurrency, required quoteCurrencies}) async {
        calls += 1;
        expect(baseCurrency, 'KZT');
        expect(quoteCurrencies, ['USD']);
        return const CurrencyRateSnapshot(
          baseCurrency: 'KZT',
          rates: {'USD': 0.002},
          rateAsOf: null,
          provider: 'test',
          stale: false,
        );
      },
    );

    expect(
      provider.convertAmount(
        amount: 1000,
        fromCurrency: 'KZT',
        toCurrency: 'USD',
      ),
      isNull,
    );
    expect(
      provider.convertAmount(
        amount: 1500,
        fromCurrency: 'kzt',
        toCurrency: 'usd',
      ),
      isNull,
    );

    await Future<void>.delayed(Duration.zero);

    expect(
      provider.convertAmount(
        amount: 1500,
        fromCurrency: 'KZT',
        toCurrency: 'USD',
      ),
      3,
    );
    expect(calls, 1);
  });

  test('returns the source amount when currencies are the same', () {
    final provider = CurrencyRateProvider(
      latestRates: ({required baseCurrency, required quoteCurrencies}) async {
        fail('same-currency conversion should not call rates API');
      },
    );

    expect(
      provider.convertAmount(
        amount: 6300,
        fromCurrency: 'KZT',
        toCurrency: 'kzt',
      ),
      6300,
    );
  });
}
