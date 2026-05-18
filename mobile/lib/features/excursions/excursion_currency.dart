import 'package:intl/intl.dart';

String normalizeExcursionCurrencyCode(String? currency) {
  final normalized = (currency ?? '').trim().toUpperCase();
  return normalized.isEmpty ? 'KZT' : normalized;
}

String localizedExcursionCurrencySymbol(String? currency) {
  return switch (normalizeExcursionCurrencyCode(currency)) {
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

String formatLocalizedExcursionMoney({
  required num amount,
  required String? currency,
  required String localeName,
  bool compact = false,
}) {
  final currencyCode = normalizeExcursionCurrencyCode(currency);
  final symbol = localizedExcursionCurrencySymbol(currencyCode);
  final decimalDigits = amount == amount.truncateToDouble() ? 0 : 2;

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
    final numeric = _formatExcursionAmountFallback(
      amount,
      localeName: localeName,
      decimalDigits: decimalDigits,
    );
    return '$numeric $symbol';
  }
}

String _formatExcursionAmountFallback(
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
