class CurrencyConversionResult {
  const CurrencyConversionResult({
    required this.sourceAmount,
    required this.sourceCurrency,
    required this.convertedAmount,
    required this.targetCurrency,
    required this.rate,
    required this.rateAsOf,
    required this.provider,
    required this.stale,
  });

  factory CurrencyConversionResult.fromJson(Map<String, dynamic> json) {
    return CurrencyConversionResult(
      sourceAmount: (json['sourceAmount'] ?? '').toString(),
      sourceCurrency: (json['sourceCurrency'] ?? '').toString(),
      convertedAmount: (json['convertedAmount'] ?? '').toString(),
      targetCurrency: (json['targetCurrency'] ?? '').toString(),
      rate: (json['rate'] ?? '').toString(),
      rateAsOf: DateTime.tryParse((json['rateAsOf'] ?? '').toString()),
      provider: (json['provider'] ?? '').toString(),
      stale: json['stale'] == true,
    );
  }

  final String sourceAmount;
  final String sourceCurrency;
  final String convertedAmount;
  final String targetCurrency;
  final String rate;
  final DateTime? rateAsOf;
  final String provider;
  final bool stale;
}

class CurrencyRateSnapshot {
  const CurrencyRateSnapshot({
    required this.baseCurrency,
    required this.rates,
    required this.rateAsOf,
    required this.provider,
    required this.stale,
  });

  factory CurrencyRateSnapshot.fromJson(Map<String, dynamic> json) {
    final rawRates = json['rates'];
    final parsedRates = <String, double>{};
    if (rawRates is Map<String, dynamic>) {
      for (final entry in rawRates.entries) {
        final currency = entry.key.trim().toUpperCase();
        final rate = _parseRate(entry.value);
        if (currency.isNotEmpty && rate != null) {
          parsedRates[currency] = rate;
        }
      }
    }

    return CurrencyRateSnapshot(
      baseCurrency: (json['baseCurrency'] ?? '').toString().toUpperCase(),
      rates: Map.unmodifiable(parsedRates),
      rateAsOf: DateTime.tryParse((json['rateAsOf'] ?? '').toString()),
      provider: (json['provider'] ?? '').toString(),
      stale: json['stale'] == true,
    );
  }

  final String baseCurrency;
  final Map<String, double> rates;
  final DateTime? rateAsOf;
  final String provider;
  final bool stale;

  double? rateFor(String currencyCode) {
    return rates[currencyCode.trim().toUpperCase()];
  }
}

class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
  });

  factory CurrencyOption.fromJson(Map<String, dynamic> json) {
    return CurrencyOption(
      code: (json['Code'] ?? json['code'] ?? '').toString(),
      name: (json['Name'] ?? json['name'] ?? '').toString(),
      symbol: (json['Symbol'] ?? json['symbol'] ?? '').toString(),
    );
  }

  final String code;
  final String name;
  final String symbol;
}

double? _parseRate(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString());
}
