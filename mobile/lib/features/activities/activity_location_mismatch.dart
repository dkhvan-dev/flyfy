bool activityMeetingLocationDiffersFromAuthorLocation({
  required String format,
  required bool didApplyAuthorLocationSnapshot,
  String? authorCountryCode,
  String? authorCityId,
  String? authorCityName,
  String? meetingCountryCode,
  String? meetingCityId,
  String? meetingCityName,
}) {
  if (format.trim().toUpperCase() == 'ONLINE' ||
      !didApplyAuthorLocationSnapshot) {
    return false;
  }

  final authorCountry = _normalizeCode(authorCountryCode);
  final meetingCountry = _normalizeCode(meetingCountryCode);
  if (authorCountry != null &&
      meetingCountry != null &&
      authorCountry != meetingCountry) {
    return true;
  }

  final authorCityKey = _normalizeCode(authorCityId);
  final meetingCityKey = _normalizeCode(meetingCityId);
  if (authorCityKey != null &&
      meetingCityKey != null &&
      authorCityKey == meetingCityKey) {
    return false;
  }

  final authorCity = _canonicalCityName(authorCityName);
  final meetingCity = _canonicalCityName(meetingCityName);
  if (authorCity != null && meetingCity != null) {
    return authorCity != meetingCity;
  }

  if (authorCityKey != null && meetingCityKey != null) {
    return authorCityKey != meetingCityKey;
  }

  return false;
}

String? _normalizeCode(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

String? _canonicalCityName(String? value) {
  final normalized = _normalizeCityName(value);
  if (normalized == null) {
    return null;
  }

  for (final entry in _knownCityAliases.entries) {
    if (entry.value.contains(normalized)) {
      return entry.key;
    }
  }
  return normalized;
}

String? _normalizeCityName(String? value) {
  final normalized = value
      ?.trim()
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[-_/.,()]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  final meaningfulTokens = normalized
      .split(' ')
      .where(
        (token) => token.isNotEmpty && !_cityDescriptorTokens.contains(token),
      )
      .toList(growable: false);
  if (meaningfulTokens.isEmpty) {
    return null;
  }
  return meaningfulTokens.join(' ');
}

const _knownCityAliases = <String, Set<String>>{
  'almaty': {'almaty', 'алматы'},
  'astana': {
    'astana',
    'астана',
    'nur sultan',
    'nursultan',
    'нур султан',
    'нурсултан',
  },
  'shymkent': {'shymkent', 'шымкент'},
};

const _cityDescriptorTokens = <String>{
  'city',
  'g',
  'gorod',
  'qala',
  'qalasy',
  'город',
  'г',
  'қ',
  'қала',
  'қаласы',
};
