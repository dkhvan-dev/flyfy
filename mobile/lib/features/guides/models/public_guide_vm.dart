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
    this.experienceYears,
    this.displayName,
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
  final String? displayName;
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
      ratingAvg: _double(guideProfile['ratingAvg']),
      reviewsCount: _int(guideProfile['reviewsCount']),
      languageCodes: _codes(
        json['languages'] ??
            guideProfile['languages'] ??
            guideProfile['languageCodes'],
        preferredKey: 'languageCode',
      ),
      specializationCodes: _codes(
        json['specializations'] ??
            guideProfile['specializations'] ??
            guideProfile['specializationCodes'],
        preferredKey: 'specializationCode',
      ),
      displayName: _nullableString(userProfile['displayName']),
      avatarFileId: _nullableString(userProfile['avatarFileId']),
      countryCode: _nullableString(userProfile['countryCode']),
    );
  }

  String get preferredName {
    final display = displayName?.trim() ?? '';
    if (display.isNotEmpty) return display;

    final shortId = userId.replaceAll('-', '');
    if (shortId.isNotEmpty) {
      final length = shortId.length >= 8 ? 8 : shortId.length;
      return 'Guide ${shortId.substring(0, length)}';
    }

    return 'FlyFy Guide';
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

List<String> _codes(dynamic raw, {required String preferredKey}) {
  if (raw is! List) return const [];

  final values = <String>{};
  for (final item in raw) {
    if (item is String) {
      final code = item.trim();
      if (code.isNotEmpty) values.add(code);
      continue;
    }

    if (item is Map<String, dynamic>) {
      final code = _string(item[preferredKey]).isNotEmpty
          ? _string(item[preferredKey])
          : _string(item['code']);
      if (code.isNotEmpty) values.add(code);
    }
  }

  return values.toList(growable: false);
}
