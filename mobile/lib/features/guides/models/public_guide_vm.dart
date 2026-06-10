class PublicGuideVm {
  const PublicGuideVm({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.headline,
    required this.about,
    required this.isPrivateGuideAvailable,
    required this.isActivityHostAvailable,
    required this.isExcursionGuideAvailable,
    required this.ratingAvg,
    required this.reviewsCount,
    required this.languageCodes,
    required this.specializationCodes,
    this.excursionLanguageCodes = const [],
    this.experienceYears,
    this.firstName,
    this.lastName,
    this.nickname,
    this.avatarFileId,
    this.countryCode,
  });

  final String id;
  final String userId;
  final String type;
  final String status;
  final String headline;
  final String about;
  final int? experienceYears;
  final bool isPrivateGuideAvailable;
  final bool isActivityHostAvailable;
  final bool isExcursionGuideAvailable;
  final double ratingAvg;
  final int reviewsCount;
  final List<String> languageCodes;
  final List<String> specializationCodes;
  final List<String> excursionLanguageCodes;
  final String? firstName;
  final String? lastName;
  final String? nickname;
  final String? avatarFileId;
  final String? countryCode;

  factory PublicGuideVm.fromJson(Map<String, dynamic> json) {
    final guideProfile =
        json['guideProfile'] as Map<String, dynamic>? ?? const {};
    final userProfile =
        json['userProfile'] as Map<String, dynamic>? ?? const {};

    final userId = _string(guideProfile['userId']).isNotEmpty
        ? _string(guideProfile['userId'])
        : _string(userProfile['userId']);
    final reviewsCount = _int(guideProfile['reviewsCount']);

    return PublicGuideVm(
      id: _string(guideProfile['id']),
      userId: userId,
      type: _string(guideProfile['type']),
      status: _string(guideProfile['status']),
      headline: _string(guideProfile['headline']),
      about: _string(guideProfile['about']),
      experienceYears: _nullableInt(guideProfile['experienceYears']),
      isPrivateGuideAvailable: guideProfile['isPrivateGuideAvailable'] == true,
      isActivityHostAvailable: guideProfile['isActivityHostAvailable'] == true,
      isExcursionGuideAvailable:
          guideProfile['isExcursionGuideAvailable'] == true,
      ratingAvg: _rating(guideProfile['ratingAvg'], reviewsCount),
      reviewsCount: reviewsCount,
      languageCodes: _codes(
        json['languages'] ??
            guideProfile['languages'] ??
            guideProfile['languageCodes'],
        preferredKey: 'languageCode',
      ),
      excursionLanguageCodes: _codes(
        json['excursionLanguageCodes'] ??
            json['excursionLanguages'] ??
            guideProfile['excursionLanguageCodes'] ??
            guideProfile['excursionLanguages'],
        preferredKey: 'languageCode',
        normalizeLowercase: true,
      ),
      specializationCodes: _codes(
        json['specializations'] ??
            guideProfile['specializations'] ??
            guideProfile['specializationCodes'],
        preferredKey: 'specializationCode',
      ),
      firstName: _nullableString(userProfile['firstName']),
      lastName: _nullableString(userProfile['lastName']),
      nickname: _nullableString(userProfile['nickname']),
      avatarFileId: _nullableString(userProfile['avatarFileId']),
      countryCode: _nullableString(userProfile['countryCode']),
    );
  }

  PublicGuideVm copyWith({List<String>? excursionLanguageCodes}) {
    return PublicGuideVm(
      id: id,
      userId: userId,
      type: type,
      status: status,
      headline: headline,
      about: about,
      experienceYears: experienceYears,
      isPrivateGuideAvailable: isPrivateGuideAvailable,
      isActivityHostAvailable: isActivityHostAvailable,
      isExcursionGuideAvailable: isExcursionGuideAvailable,
      ratingAvg: ratingAvg,
      reviewsCount: reviewsCount,
      languageCodes: languageCodes,
      specializationCodes: specializationCodes,
      excursionLanguageCodes:
          excursionLanguageCodes ?? this.excursionLanguageCodes,
      firstName: firstName,
      lastName: lastName,
      nickname: nickname,
      avatarFileId: avatarFileId,
      countryCode: countryCode,
    );
  }

  String get preferredName {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    final legalName = [
      last,
      first,
    ].where((value) => value.isNotEmpty).join(' ');
    if (legalName.isNotEmpty) return legalName;

    final display = nickname?.trim() ?? '';
    if (display.isNotEmpty) return display;

    final shortId = userId.replaceAll('-', '');
    if (shortId.isNotEmpty) {
      final length = shortId.length >= 8 ? 8 : shortId.length;
      return 'Guide ${shortId.substring(0, length)}';
    }

    return 'Inflap Guide';
  }

  String get initials {
    final parts = preferredName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'F';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

String _string(dynamic value) => value?.toString().trim() ?? '';

String? _nullableString(dynamic value) {
  final parsed = _string(value);
  return parsed.isEmpty ? null : parsed;
}

int _int(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

int? _nullableInt(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  return parsed == null || parsed < 0 ? null : parsed;
}

double _double(dynamic value) {
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double _rating(dynamic value, int reviewsCount) {
  if (reviewsCount <= 0) return 5;
  return _double(value);
}

List<String> _codes(
  dynamic raw, {
  required String preferredKey,
  bool normalizeLowercase = false,
}) {
  if (raw is! List) return const [];

  final values = <String>{};
  for (final item in raw) {
    if (item is String) {
      final code = _normalizeCode(item, normalizeLowercase);
      if (code.isNotEmpty) values.add(code);
      continue;
    }

    if (item is Map<String, dynamic>) {
      final code = _string(item[preferredKey]).isNotEmpty
          ? _string(item[preferredKey])
          : _string(item['code']);
      final normalizedCode = _normalizeCode(code, normalizeLowercase);
      if (normalizedCode.isNotEmpty) values.add(normalizedCode);
    }
  }

  return values.toList(growable: false);
}

String _normalizeCode(String value, bool normalizeLowercase) {
  final code = value.trim();
  return normalizeLowercase ? code.toLowerCase() : code;
}
