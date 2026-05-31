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

String referenceTimezoneLabel(ReferenceTimezone timezone, {String? lang}) {
  final offset = timezone.utcOffset?.trim();
  final label = _compactReferenceTimezoneName(timezone, lang: lang);

  if (offset == null || offset.isEmpty) return label;
  return '$label UTC$offset';
}

String _compactReferenceTimezoneName(
  ReferenceTimezone timezone, {
  String? lang,
}) {
  final name = timezone.name.trim();
  final fallbackId =
      normalizeReferenceTimezoneId(timezone.id) ?? timezone.id.trim();
  final localizedPlaceName = _localizedTimezonePlaceName(
    fallbackId,
    lang: lang,
    sourceName: name,
  );
  if (localizedPlaceName != null) return localizedPlaceName;

  if (name.isEmpty) return fallbackId;

  final compactName = _stripGenericTimezoneWords(name);
  return compactName.isNotEmpty ? compactName : fallbackId;
}

ReferenceTimezone? resolveReferenceTimezoneForLocation({
  required List<ReferenceTimezone> timezones,
  required Map<String, Set<String>> aliases,
  String? cityName,
  String? countryCode,
  String? deviceTimezoneId,
}) {
  final cityQuery = normalizeCountrySearchText(cityName ?? '');
  if (cityQuery.isNotEmpty) {
    final timezone = _findTimezoneBySearchQuery(timezones, aliases, cityQuery);
    if (timezone != null) return timezone;
  }

  final normalizedCountryCode = normalizeReferenceCountryCode(countryCode);
  final countryDefaultTimezoneId =
      _defaultTimezoneIdByCountryCode[normalizedCountryCode];
  if (countryDefaultTimezoneId != null) {
    final timezone = _findTimezoneById(timezones, countryDefaultTimezoneId);
    if (timezone != null) return timezone;
  }

  final normalizedDeviceTimezoneId = normalizeReferenceTimezoneId(
    deviceTimezoneId,
  );
  if (normalizedDeviceTimezoneId == null) return null;

  return _findTimezoneById(timezones, normalizedDeviceTimezoneId);
}

String localizedReferenceTimezoneFallbackName(String timezoneId, String lang) {
  final city = timezoneId.split('/').last.replaceAll('_', ' ').trim();
  if (city.isEmpty || city == timezoneId) return timezoneId;
  return city;
}

String? _localizedTimezonePlaceName(
  String timezoneId, {
  required String? lang,
  required String sourceName,
}) {
  final names = _timezonePlaceNamesById[timezoneId];
  if (names == null) return null;

  final normalizedLang = lang?.trim().toLowerCase();
  if (normalizedLang != null && normalizedLang.isNotEmpty) {
    final localized = names[normalizedLang];
    if (localized != null) return localized;
  }

  final normalizedSource = normalizeCountrySearchText(sourceName);
  if (normalizedSource.contains('уақыты')) {
    return names['kk'] ?? names['ru'] ?? names['en'];
  }
  if (normalizedSource.contains('время')) {
    return names['ru'] ?? names['kk'] ?? names['en'];
  }

  if (normalizedSource.endsWith(' time') ||
      normalizedSource.startsWith('time ')) {
    return names['en'] ?? names.values.first;
  }

  return null;
}

String _stripGenericTimezoneWords(String value) {
  return value
      .trim()
      .replaceFirst(RegExp(r'\s+time$', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^time\s+', caseSensitive: false), '')
      .replaceFirst(RegExp(r'\s+уақыты$'), '')
      .replaceFirst(RegExp(r'\s+время$', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^время\s+', caseSensitive: false), '')
      .trim();
}

ReferenceTimezone? _findTimezoneBySearchQuery(
  List<ReferenceTimezone> timezones,
  Map<String, Set<String>> aliases,
  String query,
) {
  for (final timezone in timezones) {
    if (timezoneFilterSearchHaystack(timezone, aliases).contains(query)) {
      return timezone;
    }
  }
  return null;
}

ReferenceTimezone? _findTimezoneById(
  List<ReferenceTimezone> timezones,
  String timezoneId,
) {
  for (final timezone in timezones) {
    if (normalizeReferenceTimezoneId(timezone.id) == timezoneId) {
      return timezone;
    }
  }
  return null;
}

const _defaultTimezoneIdByCountryCode = <String, String>{
  'AE': 'Asia/Dubai',
  'CN': 'Asia/Shanghai',
  'IN': 'Asia/Kolkata',
  'JP': 'Asia/Tokyo',
  'KG': 'Asia/Bishkek',
  'KR': 'Asia/Seoul',
  'KZ': 'Asia/Almaty',
  'SG': 'Asia/Singapore',
  'TR': 'Europe/Istanbul',
  'UZ': 'Asia/Tashkent',
};

const _timezonePlaceNamesById = <String, Map<String, String>>{
  'UTC': {'en': 'UTC', 'ru': 'UTC', 'kk': 'UTC'},
  'Asia/Almaty': {'en': 'Almaty', 'ru': 'Алматы', 'kk': 'Алматы'},
  'Asia/Aqtau': {'en': 'Aktau', 'ru': 'Актау', 'kk': 'Ақтау'},
  'Asia/Aqtobe': {'en': 'Aktobe', 'ru': 'Актобе', 'kk': 'Ақтөбе'},
  'Asia/Atyrau': {'en': 'Atyrau', 'ru': 'Атырау', 'kk': 'Атырау'},
  'Asia/Oral': {'en': 'Oral', 'ru': 'Уральск', 'kk': 'Орал'},
  'Asia/Qyzylorda': {'en': 'Kyzylorda', 'ru': 'Кызылорда', 'kk': 'Қызылорда'},
  'Asia/Bishkek': {'en': 'Bishkek', 'ru': 'Бишкек', 'kk': 'Бішкек'},
  'Asia/Tashkent': {'en': 'Tashkent', 'ru': 'Ташкент', 'kk': 'Ташкент'},
  'Asia/Dubai': {'en': 'Dubai', 'ru': 'Дубай', 'kk': 'Дубай'},
  'Europe/Moscow': {'en': 'Moscow', 'ru': 'Москва', 'kk': 'Мәскеу'},
  'Europe/Istanbul': {'en': 'Istanbul', 'ru': 'Стамбул', 'kk': 'Ыстамбұл'},
  'Europe/London': {'en': 'London', 'ru': 'Лондон', 'kk': 'Лондон'},
  'Europe/Paris': {'en': 'Paris', 'ru': 'Париж', 'kk': 'Париж'},
  'Europe/Berlin': {'en': 'Berlin', 'ru': 'Берлин', 'kk': 'Берлин'},
  'Asia/Tokyo': {'en': 'Tokyo', 'ru': 'Токио', 'kk': 'Токио'},
  'Asia/Seoul': {'en': 'Seoul', 'ru': 'Сеул', 'kk': 'Сеул'},
  'Asia/Shanghai': {'en': 'Shanghai', 'ru': 'Шанхай', 'kk': 'Шанхай'},
  'Asia/Singapore': {'en': 'Singapore', 'ru': 'Сингапур', 'kk': 'Сингапур'},
  'Asia/Kolkata': {'en': 'India', 'ru': 'Индия', 'kk': 'Үндістан'},
  'America/New_York': {'en': 'New York', 'ru': 'Нью-Йорк', 'kk': 'Нью-Йорк'},
  'America/Chicago': {'en': 'Chicago', 'ru': 'Чикаго', 'kk': 'Чикаго'},
  'America/Denver': {'en': 'Denver', 'ru': 'Денвер', 'kk': 'Денвер'},
  'America/Los_Angeles': {
    'en': 'Los Angeles',
    'ru': 'Лос-Анджелес',
    'kk': 'Лос-Анджелес',
  },
  'America/Sao_Paulo': {
    'en': 'Sao Paulo',
    'ru': 'Сан-Паулу',
    'kk': 'Сан-Паулу',
  },
  'Australia/Sydney': {'en': 'Sydney', 'ru': 'Сидней', 'kk': 'Сидней'},
};
