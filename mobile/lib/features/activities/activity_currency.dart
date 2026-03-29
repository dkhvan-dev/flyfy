String? normalizeActivityCurrencyCode(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

String? normalizeActivityCountryCode(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

String? activityCurrencyForCountryCode(String? countryCode) {
  switch (normalizeActivityCountryCode(countryCode)) {
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

String? resolveActivityCurrencyCode({String? currency, String? countryCode}) {
  return normalizeActivityCurrencyCode(currency) ??
      activityCurrencyForCountryCode(countryCode);
}

String filterCurrencyCode({String? currency, String? countryCode}) {
  return activityCurrencyForCountryCode(countryCode) ??
      normalizeActivityCurrencyCode(currency) ??
      'KZT';
}

String filterCurrencyLabel({String? currency, String? countryCode}) {
  switch (filterCurrencyCode(currency: currency, countryCode: countryCode)) {
    case 'USD':
    case 'CAD':
    case 'AUD':
    case 'NZD':
    case 'SGD':
    case 'HKD':
      return r'$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'RUB':
      return '₽';
    case 'KZT':
      return '₸';
    case 'JPY':
    case 'CNY':
      return '¥';
    case 'KRW':
      return '₩';
    case 'INR':
      return '₹';
    case 'THB':
      return '฿';
    default:
      return filterCurrencyCode(currency: currency, countryCode: countryCode);
  }
}

double pricePresetNominalUnit({String? currency, String? countryCode}) {
  switch (normalizeActivityCountryCode(countryCode)) {
    case 'KZ':
      return 50;
    case 'UZ':
      return 1000;
    case 'JP':
      return 100;
    case 'KR':
      return 1000;
    case 'VN':
      return 10000;
  }

  switch (resolveActivityCurrencyCode(
    currency: currency,
    countryCode: countryCode,
  )) {
    case 'KZT':
      return 50;
    case 'KGS':
      return 10;
    case 'UZS':
      return 1000;
    case 'TJS':
      return 10;
    case 'RUB':
      return 10;
    case 'JPY':
      return 100;
    case 'KRW':
      return 1000;
    case 'VND':
      return 10000;
    case 'IDR':
      return 1000;
    default:
      return 1;
  }
}

String formatActivityMoney({
  required num? amount,
  String? currency,
  String? countryCode,
}) {
  final resolvedCurrency = resolveActivityCurrencyCode(
    currency: currency,
    countryCode: countryCode,
  );
  if (amount == null) {
    return resolvedCurrency == null ? '0' : '0 $resolvedCurrency';
  }

  final numeric = amount % 1 == 0
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  if (resolvedCurrency == null) {
    return numeric;
  }
  return '$numeric $resolvedCurrency';
}
