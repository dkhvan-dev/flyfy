import '../../shared/formatters/app_money_formatter.dart';

String? normalizeActivityCurrencyCode(String? value) {
  return normalizeAppCurrencyCode(value);
}

String? normalizeActivityCountryCode(String? value) {
  return normalizeAppCountryCode(value);
}

String? activityCurrencyForCountryCode(String? countryCode) {
  return appCurrencyForCountryCode(countryCode);
}

String? resolveActivityCurrencyCode({String? currency, String? countryCode}) {
  return resolveAppCurrencyCode(currency: currency, countryCode: countryCode);
}

String filterCurrencyCode({String? currency, String? countryCode}) {
  return activityCurrencyForCountryCode(countryCode) ??
      normalizeActivityCurrencyCode(currency) ??
      'KZT';
}

String filterCurrencyLabel({String? currency, String? countryCode}) {
  return appCurrencySymbol(
    filterCurrencyCode(currency: currency, countryCode: countryCode),
  );
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
  String localeName = 'ru',
}) {
  return formatOptionalAppMoney(
    amount: amount,
    currency: currency,
    countryCode: countryCode,
    localeName: localeName,
    useListCurrencyFormat: true,
  );
}
