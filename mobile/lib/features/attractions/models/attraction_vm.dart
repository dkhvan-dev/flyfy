class AttractionMediaVm {
  const AttractionMediaVm({
    required this.id,
    required this.fileId,
    required this.externalUrl,
    required this.sourceUrl,
    required this.credit,
    required this.license,
    required this.mediaType,
    required this.position,
  });

  final String id;
  final String fileId;
  final String externalUrl;
  final String sourceUrl;
  final String credit;
  final String license;
  final String mediaType;
  final int position;

  factory AttractionMediaVm.fromJson(Map<String, dynamic> json) {
    return AttractionMediaVm(
      id: json['id'] as String? ?? '',
      fileId: json['fileId'] as String? ?? '',
      externalUrl: json['externalUrl'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      credit: json['credit'] as String? ?? '',
      license: json['license'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? 'PHOTO',
      position: json['position'] as int? ?? 0,
    );
  }
}

class AttractionAuthorVm {
  const AttractionAuthorVm({
    required this.userId,
    this.displayName,
    this.avatarFileId,
  });

  final String userId;
  final String? displayName;
  final String? avatarFileId;

  factory AttractionAuthorVm.fromJson(Map<String, dynamic> json) {
    return AttractionAuthorVm(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String?,
      avatarFileId: json['avatarFileId'] as String?,
    );
  }
}

class AttractionTranslationVm {
  const AttractionTranslationVm({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  factory AttractionTranslationVm.fromJson(Map<String, dynamic> json) {
    return AttractionTranslationVm(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class AttractionVisitInfoVm {
  const AttractionVisitInfoVm({
    this.bestTime,
    this.accessibility,
    this.bookingRequired,
    this.openingHours,
    required this.amenities,
    required this.audience,
    required this.safetyNotes,
    required this.nearbyIds,
    required this.localizedTips,
  });

  final String? bestTime;
  final String? accessibility;
  final bool? bookingRequired;
  final String? openingHours;
  final List<String> amenities;
  final List<String> audience;
  final List<String> safetyNotes;
  final List<String> nearbyIds;
  final Map<String, String> localizedTips;

  bool get isEmpty =>
      (bestTime ?? '').trim().isEmpty &&
      (accessibility ?? '').trim().isEmpty &&
      bookingRequired == null &&
      (openingHours ?? '').trim().isEmpty &&
      amenities.isEmpty &&
      audience.isEmpty &&
      safetyNotes.isEmpty &&
      nearbyIds.isEmpty &&
      localizedTips.isEmpty;

  factory AttractionVisitInfoVm.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return empty;
    }
    return AttractionVisitInfoVm(
      bestTime: json['bestTime'] as String?,
      accessibility: json['accessibility'] as String?,
      bookingRequired: json['bookingRequired'] as bool?,
      openingHours: json['openingHours'] as String?,
      amenities: (json['amenities'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      audience: (json['audience'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      safetyNotes: (json['safetyNotes'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      nearbyIds: (json['nearbyIds'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      localizedTips: (json['localizedTips'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  static const empty = AttractionVisitInfoVm(
    amenities: [],
    audience: [],
    safetyNotes: [],
    nearbyIds: [],
    localizedTips: {},
  );
}

class AttractionVm {
  const AttractionVm({
    required this.id,
    required this.locale,
    required this.defaultLocale,
    required this.title,
    required this.description,
    required this.countryCode,
    required this.cityId,
    required this.category,
    this.priceAmount,
    this.priceCurrency,
    this.durationValue,
    this.durationUnit,
    required this.rating,
    required this.reviewCount,
    this.spots,
    required this.source,
    required this.status,
    required this.tags,
    required this.visitInfo,
    required this.translations,
    required this.media,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String locale;
  final String defaultLocale;
  final String title;
  final String description;
  final String countryCode;
  final String cityId;
  final String category;
  final double? priceAmount;
  final String? priceCurrency;
  final int? durationValue;
  final String? durationUnit;
  final double rating;
  final int reviewCount;
  final int? spots;
  final String source;
  final String status;
  final List<String> tags;
  final AttractionVisitInfoVm visitInfo;
  final Map<String, AttractionTranslationVm> translations;
  final List<AttractionMediaVm> media;
  final AttractionAuthorVm author;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  AttractionMediaVm? get coverMedia {
    if (media.isEmpty) return null;
    final sorted = List<AttractionMediaVm>.from(media)
      ..sort((a, b) => a.position.compareTo(b.position));
    return sorted.first;
  }

  String? get coverFileId {
    final fileId = coverMedia?.fileId.trim();
    return fileId == null || fileId.isEmpty ? null : fileId;
  }

  factory AttractionVm.fromJson(Map<String, dynamic> json) {
    final mediaList = (json['media'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AttractionMediaVm.fromJson)
        .toList();

    final tagsList = (json['tags'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final translations = (json['translations'] as Map<String, dynamic>? ?? {})
        .map((key, value) {
          if (value is! Map<String, dynamic>) {
            return MapEntry(
              key,
              const AttractionTranslationVm(title: '', description: ''),
            );
          }
          return MapEntry(key, AttractionTranslationVm.fromJson(value));
        });

    return AttractionVm(
      id: json['id'] as String? ?? '',
      locale: json['locale'] as String? ?? 'en',
      defaultLocale: json['defaultLocale'] as String? ?? 'en',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      cityId: json['cityId'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      priceAmount: (json['priceAmount'] as num?)?.toDouble(),
      priceCurrency: json['priceCurrency'] as String?,
      durationValue: json['durationValue'] as int?,
      durationUnit: json['durationUnit'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      spots: json['spots'] as int?,
      source: json['source'] as String? ?? 'USER',
      status: json['status'] as String? ?? 'DRAFT',
      tags: tagsList,
      visitInfo: AttractionVisitInfoVm.fromJson(
        json['visitInfo'] is Map<String, dynamic>
            ? json['visitInfo'] as Map<String, dynamic>
            : null,
      ),
      translations: translations,
      media: mediaList,
      author: json['author'] is Map<String, dynamic>
          ? AttractionAuthorVm.fromJson(json['author'] as Map<String, dynamic>)
          : const AttractionAuthorVm(userId: ''),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      deletedAt: json['deletedAt'] as String?,
    );
  }
}
