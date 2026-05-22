import '../network/reference_api.dart';
import 'country_filter_utils.dart';

String? normalizeReferenceCurrencyCode(String? code) {
  final normalized = code?.trim().toUpperCase() ?? '';
  return normalized.isEmpty ? null : normalized;
}

String normalizeCurrencySearchText(String value) {
  return normalizeCountrySearchText(value);
}

List<ReferenceCurrency> withDefaultReferenceCurrency(
  List<ReferenceCurrency> currencies,
  String? defaultCurrencyCode,
) {
  if (defaultCurrencyCode == null) return currencies;
  final hasDefault = currencies.any(
    (currency) =>
        normalizeReferenceCurrencyCode(currency.code) == defaultCurrencyCode,
  );
  if (hasDefault) return currencies;

  return [
    ReferenceCurrency(
      code: defaultCurrencyCode,
      numeric: '',
      decimals: 2,
      symbol: defaultCurrencyCode,
      name: defaultCurrencyCode,
    ),
    ...currencies,
  ];
}

Map<String, Set<String>> currencySearchAliasMap(
  List<ReferenceCurrency> currencies,
) {
  final aliases = <String, Set<String>>{};
  for (final currency in currencies) {
    final code = normalizeReferenceCurrencyCode(currency.code);
    if (code == null) continue;

    final currencyAliases = aliases.putIfAbsent(code, () => <String>{});
    currencyAliases
      ..add(code)
      ..add(currency.code.trim())
      ..add(currency.name.trim())
      ..add(currency.symbol.trim())
      ..add(currency.numeric.trim());
  }
  return aliases;
}

String currencyFilterSearchHaystack(
  ReferenceCurrency currency,
  Map<String, Set<String>> aliases,
) {
  final code = normalizeReferenceCurrencyCode(currency.code);
  final currencyAliases =
      code == null ? const <String>{} : aliases[code] ?? const <String>{};

  return [
    currency.code,
    currency.name,
    currency.symbol,
    currency.numeric,
    ...currencyAliases,
  ].map(normalizeCurrencySearchText).join(' ');
}

String referenceCurrencyLabel(ReferenceCurrency currency) {
  final name = currency.name.trim();
  if (name.isNotEmpty) return name;
  return normalizeReferenceCurrencyCode(currency.code) ?? currency.code.trim();
}
