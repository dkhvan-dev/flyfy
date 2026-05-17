import '../network/reference_api.dart';

String? normalizeReferenceCountryCode(String? code) {
  final normalized = code?.trim().toUpperCase() ?? '';
  return normalized.isEmpty ? null : normalized;
}

String normalizeCountrySearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[@_.,;:\/\\|()\[\]{}<>+\-=]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<ReferenceCountry> withDefaultReferenceCountry(
  List<ReferenceCountry> countries,
  String? defaultCountryCode,
) {
  if (defaultCountryCode == null) return countries;
  final hasDefault = countries.any(
    (country) =>
        normalizeReferenceCountryCode(country.code) == defaultCountryCode,
  );
  if (hasDefault) return countries;

  return [
    ReferenceCountry(code: defaultCountryCode, name: defaultCountryCode),
    ...countries,
  ];
}

Map<String, Set<String>> countrySearchAliasMap(
  List<ReferenceCountry> countries,
) {
  final aliases = <String, Set<String>>{};
  for (final country in countries) {
    final code = normalizeReferenceCountryCode(country.code);
    if (code == null) continue;

    final countryAliases = aliases.putIfAbsent(code, () => <String>{});
    countryAliases
      ..add(code)
      ..add(country.code.trim())
      ..add(country.name.trim());

    final phoneCode = country.phoneCode?.trim();
    if (phoneCode != null && phoneCode.isNotEmpty) {
      countryAliases.add(phoneCode);
    }
  }
  return aliases;
}

String countryFilterSearchHaystack(
  ReferenceCountry country,
  Map<String, Set<String>> aliases,
) {
  final countryCode = normalizeReferenceCountryCode(country.code);
  final countryAliases = countryCode == null
      ? const <String>{}
      : aliases[countryCode] ?? const <String>{};

  return [
    country.code,
    country.name,
    if (country.phoneCode != null) country.phoneCode!,
    ...countryAliases,
  ].map(normalizeCountrySearchText).join(' ');
}
