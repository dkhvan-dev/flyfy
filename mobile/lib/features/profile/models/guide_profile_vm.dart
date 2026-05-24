class GuideProfileVm {
  GuideProfileVm({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.headline,
    required this.about,
    required this.experienceYears,
    required this.isPrivateGuideAvailable,
    required this.isActivityHostAvailable,
    required this.isExcursionGuideAvailable,
    required this.ratingAvg,
    required this.reviewsCount,
    required this.languages,
    required this.specializations,
    this.statusReason,
    this.statusChangedAt,
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
  final List<String> languages;
  final List<String> specializations;
  final String? statusReason;
  final DateTime? statusChangedAt;

  factory GuideProfileVm.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? const {};
    final languages = json['languages'] as List<dynamic>? ?? const [];
    final specializations =
        json['specializations'] as List<dynamic>? ?? const [];

    int? parseNullableInt(dynamic value) {
      final parsed = int.tryParse(value?.toString() ?? '');
      return parsed;
    }

    return GuideProfileVm(
      id: profile['id']?.toString() ?? '',
      userId: profile['userId']?.toString() ?? '',
      type: profile['type']?.toString() ?? '',
      status: profile['status']?.toString() ?? '',
      headline: profile['headline']?.toString() ?? '',
      about: profile['about']?.toString() ?? '',
      experienceYears: parseNullableInt(profile['experienceYears']),
      isPrivateGuideAvailable: profile['isPrivateGuideAvailable'] == true,
      isActivityHostAvailable: profile['isActivityHostAvailable'] == true,
      isExcursionGuideAvailable: profile['isExcursionGuideAvailable'] == true,
      ratingAvg: double.tryParse(profile['ratingAvg']?.toString() ?? '') ?? 0,
      reviewsCount:
          int.tryParse(profile['reviewsCount']?.toString() ?? '') ?? 0,
      statusReason: _trimmedStringOrNull(profile['statusReason']),
      statusChangedAt: DateTime.tryParse(
        profile['statusChangedAt']?.toString() ?? '',
      ),
      languages: languages
          .map((item) => (item as Map<String, dynamic>)['languageCode'])
          .whereType<Object?>()
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false),
      specializations: specializations
          .map((item) => (item as Map<String, dynamic>)['specializationCode'])
          .whereType<Object?>()
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false),
    );
  }

  bool get isVerified =>
      status.trim().toUpperCase() == 'ACTIVE' ||
      status.trim().toUpperCase() == 'APPROVED';

  bool get isPendingReview => status.trim().toUpperCase() == 'PENDING_REVIEW';

  bool get isRejected => status.trim().toUpperCase() == 'REJECTED';

  bool get isRevoked => status.trim().toUpperCase() == 'REVOKED';

  bool get isDraft => status.trim().toUpperCase() == 'DRAFT';

  List<String> get serviceBadges {
    final values = <String>[...specializations, ...languages];
    return values.toSet().toList(growable: false);
  }
}

String? _trimmedStringOrNull(dynamic value) {
  final trimmed = value?.toString().trim() ?? '';
  if (trimmed.isEmpty) return null;
  return trimmed;
}
