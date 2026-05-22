import '../network/reference_api.dart';
import 'country_filter_utils.dart';

String? normalizeReferenceTimezoneId(String? id) {
  final normalized = id?.trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

List<ReferenceTimezone> withDefaultReferenceTimezone(
  List<ReferenceTimezone> timezones,
  String? defaultTimezoneId, {
  String lang = 'en',
}) {
  if (defaultTimezoneId == null) return timezones;
  final hasDefault = timezones.any(
    (timezone) =>
        normalizeReferenceTimezoneId(timezone.id) == defaultTimezoneId,
  );
  if (hasDefault) return timezones;

  return [
    ReferenceTimezone(
      id: defaultTimezoneId,
      name: localizedReferenceTimezoneFallbackName(defaultTimezoneId, lang),
    ),
    ...timezones,
  ];
}

Map<String, Set<String>> timezoneSearchAliasMap(
  List<ReferenceTimezone> timezones,
) {
  final aliases = <String, Set<String>>{};
  for (final timezone in timezones) {
    final timezoneId = normalizeReferenceTimezoneId(timezone.id);
    if (timezoneId == null) continue;

    final timezoneAliases = aliases.putIfAbsent(timezoneId, () => <String>{});
    timezoneAliases
      ..add(timezoneId)
      ..add(timezone.id.trim())
      ..add(timezone.name.trim());

    final offset = timezone.utcOffset?.trim();
    if (offset != null && offset.isNotEmpty) {
      timezoneAliases.add(offset);
      timezoneAliases.add('UTC$offset');
      timezoneAliases.add('GMT$offset');
    }

    final city = timezoneId.split('/').last.replaceAll('_', ' ').trim();
    if (city.isNotEmpty) {
      timezoneAliases.add(city);
    }
  }
  return aliases;
}

String timezoneFilterSearchHaystack(
  ReferenceTimezone timezone,
  Map<String, Set<String>> aliases,
) {
  final timezoneId = normalizeReferenceTimezoneId(timezone.id);
  final timezoneAliases = timezoneId == null
      ? const <String>{}
      : aliases[timezoneId] ?? const <String>{};

  return [
    timezone.id,
    timezone.name,
    if (timezone.utcOffset != null) timezone.utcOffset!,
    ...timezoneAliases,
  ].map(normalizeCountrySearchText).join(' ');
}

String localizedReferenceTimezoneFallbackName(String timezoneId, String lang) {
  final city = timezoneId.split('/').last.replaceAll('_', ' ').trim();
  if (city.isEmpty || city == timezoneId) return timezoneId;

  switch (lang) {
    case 'ru':
      return '$city, часовой пояс';
    case 'kk':
      return '$city, уақыт белдеуі';
    default:
      return '$city time';
  }
}
