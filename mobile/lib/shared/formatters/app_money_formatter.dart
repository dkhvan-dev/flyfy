import 'package:intl/intl.dart';

String? normalizeAppCurrencyCode(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

String normalizeAppCurrencyCodeOrDefault(
  String? value, {
  String fallback = 'KZT',
}) {
  return normalizeAppCurrencyCode(value) ??
      normalizeAppCurrencyCode(fallback) ??
      'KZT';
}

String? normalizeAppCountryCode(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

String? appCurrencyForCountryCode(String? countryCode) {
  switch (normalizeAppCountryCode(countryCode)) {
    case 'KZ':
      return 'KZT';
    case 'KG':
      return 'KGS';
    case 'UZ':
      return 'UZS';
    case 'TJ':
      return 'TJS';
    case 'TM':
      return 'TMT';
    case 'RU':
      return 'RUB';
    case 'BY':
      return 'BYN';
    case 'UA':
      return 'UAH';
    case 'AZ':
      return 'AZN';
    case 'AM':
      return 'AMD';
    case 'GE':
      return 'GEL';
    case 'TR':
      return 'TRY';
    case 'AE':
      return 'AED';
    case 'SA':
      return 'SAR';
    case 'QA':
      return 'QAR';
    case 'KW':
      return 'KWD';
    case 'BH':
      return 'BHD';
    case 'OM':
      return 'OMR';
    case 'EG':
      return 'EGP';
    case 'IL':
      return 'ILS';
    case 'JO':
      return 'JOD';
    case 'US':
      return 'USD';
    case 'CA':
      return 'CAD';
    case 'MX':
      return 'MXN';
    case 'BR':
      return 'BRL';
    case 'AR':
      return 'ARS';
    case 'CL':
      return 'CLP';
    case 'CO':
      return 'COP';
    case 'PE':
      return 'PEN';
    case 'GB':
      return 'GBP';
    case 'CH':
      return 'CHF';
    case 'NO':
      return 'NOK';
    case 'SE':
      return 'SEK';
    case 'DK':
      return 'DKK';
    case 'PL':
      return 'PLN';
    case 'CZ':
      return 'CZK';
    case 'HU':
      return 'HUF';
    case 'RO':
      return 'RON';
    case 'BG':
      return 'BGN';
    case 'RS':
      return 'RSD';
    case 'IS':
      return 'ISK';
    case 'DE':
    case 'FR':
    case 'ES':
    case 'IT':
    case 'NL':
    case 'BE':
    case 'AT':
    case 'IE':
    case 'PT':
    case 'FI':
    case 'GR':
    case 'LU':
    case 'SI':
    case 'SK':
    case 'EE':
    case 'LV':
    case 'LT':
    case 'CY':
    case 'MT':
    case 'HR':
      return 'EUR';
    case 'IN':
      return 'INR';
    case 'CN':
      return 'CNY';
    case 'JP':
      return 'JPY';
    case 'KR':
      return 'KRW';
    case 'HK':
      return 'HKD';
    case 'SG':
      return 'SGD';
    case 'MY':
      return 'MYR';
    case 'TH':
      return 'THB';
    case 'ID':
      return 'IDR';
    case 'PH':
      return 'PHP';
    case 'VN':
      return 'VND';
    case 'PK':
      return 'PKR';
    case 'AU':
      return 'AUD';
    case 'NZ':
      return 'NZD';
    default:
      return null;
  }
}

String? resolveAppCurrencyCode({String? currency, String? countryCode}) {
  return normalizeAppCurrencyCode(currency) ??
      appCurrencyForCountryCode(countryCode);
}

String appCurrencySymbol(String? currency) {
  return switch (normalizeAppCurrencyCodeOrDefault(currency)) {
    'USD' || 'CAD' || 'AUD' || 'NZD' || 'SGD' || 'HKD' => r'$',
    'EUR' => '€',
    'GBP' => '£',
    'RUB' => '₽',
    'KZT' => '₸',
    'JPY' || 'CNY' => '¥',
    'KRW' => '₩',
    'INR' => '₹',
    'THB' => '฿',
    final code => code,
  };
}

String formatAppMoney({
  required num amount,
  required String? currency,
  required String localeName,
  bool compact = false,
  bool useListCurrencyFormat = false,
}) {
  final currencyCode = normalizeAppCurrencyCodeOrDefault(currency);
  final symbol = appCurrencySymbol(currencyCode);
  final decimalDigits = amount == amount.truncateToDouble() ? 0 : 2;

  if (useListCurrencyFormat) {
    return _formatListMoney(
      amount,
      currencyCode: currencyCode,
      decimalDigits: decimalDigits,
    );
  }

  try {
    final formatter = compact
        ? NumberFormat.compactCurrency(
            locale: localeName,
            name: currencyCode,
            symbol: symbol,
          )
        : NumberFormat.currency(
            locale: localeName,
            name: currencyCode,
            symbol: symbol,
            decimalDigits: decimalDigits,
          );
    return formatter.format(amount);
  } catch (_) {
    final numeric = _formatAmountFallback(
      amount,
      localeName: localeName,
      decimalDigits: decimalDigits,
    );
    return '$numeric $symbol';
  }
}

String formatOptionalAppMoney({
  required num? amount,
  String? currency,
  String? countryCode,
  required String localeName,
  bool compact = false,
  bool useListCurrencyFormat = false,
}) {
  final resolvedCurrency = resolveAppCurrencyCode(
    currency: currency,
    countryCode: countryCode,
  );
  if (amount == null) {
    return resolvedCurrency == null
        ? '0'
        : '0 ${appCurrencySymbol(resolvedCurrency)}';
  }
  return formatAppMoney(
    amount: amount,
    currency: resolvedCurrency,
    localeName: localeName,
    compact: compact,
    useListCurrencyFormat: useListCurrencyFormat,
  );
}

String _formatListMoney(
  num amount, {
  required String currencyCode,
  required int decimalDigits,
}) {
  try {
    return NumberFormat.simpleCurrency(
      name: currencyCode,
      decimalDigits: decimalDigits,
    ).format(amount);
  } catch (_) {
    return '${amount.toStringAsFixed(decimalDigits)} $currencyCode';
  }
}

String _formatAmountFallback(
  num amount, {
  required String localeName,
  required int decimalDigits,
}) {
  try {
    return NumberFormat.decimalPatternDigits(
      locale: localeName,
      decimalDigits: decimalDigits,
    ).format(amount);
  } catch (_) {
    return amount.toStringAsFixed(decimalDigits);
  }
}
