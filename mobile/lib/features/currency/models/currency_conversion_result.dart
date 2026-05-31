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
