import '../../shared/formatters/app_money_formatter.dart';

String normalizeExcursionCurrencyCode(String? currency) {
  return normalizeAppCurrencyCodeOrDefault(currency);
}

String localizedExcursionCurrencySymbol(String? currency) {
  return appCurrencySymbol(currency);
}

String formatLocalizedExcursionMoney({
  required num amount,
  required String? currency,
  required String localeName,
  bool compact = false,
  bool useExcursionListCurrencyFormat = false,
}) {
  return formatAppMoney(
    amount: amount,
    currency: currency,
    localeName: localeName,
    compact: compact,
    useListCurrencyFormat: useExcursionListCurrencyFormat,
  );
}
