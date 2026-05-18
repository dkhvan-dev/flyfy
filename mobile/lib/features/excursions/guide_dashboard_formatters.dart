import 'excursion_currency.dart';

String formatGuideDashboardRevenue({
  required num amount,
  required String? currency,
  required String localeName,
}) {
  return formatLocalizedExcursionMoney(
    amount: amount,
    currency: currency,
    localeName: localeName,
    useExcursionListCurrencyFormat: true,
  );
}
