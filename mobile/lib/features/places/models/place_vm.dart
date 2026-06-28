class PlaceMediaVm {
  const PlaceMediaVm({
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

  factory PlaceMediaVm.fromJson(Map<String, dynamic> json) {
    return PlaceMediaVm(
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

class PlaceAuthorVm {
  const PlaceAuthorVm({required this.userId, this.nickname, this.avatarFileId});

  final String userId;
  final String? nickname;
  final String? avatarFileId;

  factory PlaceAuthorVm.fromJson(Map<String, dynamic> json) {
    return PlaceAuthorVm(
      userId: json['userId'] as String? ?? '',
      nickname: json['nickname'] as String?,
      avatarFileId: json['avatarFileId'] as String?,
    );
  }
}

class PlaceTranslationVm {
  const PlaceTranslationVm({required this.title, required this.description});

  final String title;
  final String description;

  factory PlaceTranslationVm.fromJson(Map<String, dynamic> json) {
    return PlaceTranslationVm(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class PlaceFeeDetailVm {
  const PlaceFeeDetailVm({
    this.type = '',
    required this.title,
    required this.description,
    this.amount,
    this.minAmount,
    this.maxAmount,
    required this.currency,
    required this.unit,
    this.isRequired = false,
    required this.isApproximate,
    this.note = '',
    required this.sortOrder,
  });

  final String type;
  final String title;
  final String description;
  final double? amount;
  final double? minAmount;
  final double? maxAmount;
  final String currency;
  final String unit;
  final bool isRequired;
  final bool isApproximate;
  final String note;
  final int sortOrder;

  factory PlaceFeeDetailVm.fromJson(Map<String, dynamic> json) {
    final minAmount = (json['minAmount'] as num?)?.toDouble();
    final amount = (json['amount'] as num?)?.toDouble() ?? minAmount;
    return PlaceFeeDetailVm(
      type: _stringFromJson(json['type']),
      title: _stringFromJson(json['title']),
      description: _stringFromJson(json['description']),
      amount: amount,
      minAmount: minAmount,
      maxAmount: (json['maxAmount'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      isRequired:
          json['required'] as bool? ?? json['isRequired'] as bool? ?? false,
      isApproximate: json['isApproximate'] as bool? ?? false,
      note: _stringFromJson(json['note']),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class PlaceVisitDurationVm {
  const PlaceVisitDurationVm({
    this.minMinutes,
    this.maxMinutes,
    this.note = '',
  });

  final int? minMinutes;
  final int? maxMinutes;
  final String note;

  bool get isEmpty =>
      minMinutes == null && maxMinutes == null && note.trim().isEmpty;

  factory PlaceVisitDurationVm.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlaceVisitDurationVm();
    return PlaceVisitDurationVm(
      minMinutes: json['minMinutes'] as int?,
      maxMinutes: json['maxMinutes'] as int?,
      note: _stringFromJson(json['note']),
    );
  }
}

class PlaceSeasonVm {
  const PlaceSeasonVm({required this.months, this.note = ''});

  final List<int> months;
  final String note;

  bool get isEmpty => months.isEmpty && note.trim().isEmpty;

  factory PlaceSeasonVm.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlaceSeasonVm(months: []);
    return PlaceSeasonVm(
      months: (json['months'] as List<dynamic>? ?? [])
          .whereType<int>()
          .toList(),
      note: _stringFromJson(json['note']),
    );
  }
}

class PlaceAccessOptionVm {
  const PlaceAccessOptionVm({
    required this.transportType,
    this.durationMinMinutes,
    this.durationMaxMinutes,
    this.distanceKm,
    required this.routeHint,
    required this.roadCondition,
    required this.requires4x4,
    required this.parkingNote,
    required this.lastSegmentNote,
    required this.note,
    required this.sortOrder,
  });

  final String transportType;
  final int? durationMinMinutes;
  final int? durationMaxMinutes;
  final double? distanceKm;
  final String routeHint;
  final String roadCondition;
  final bool requires4x4;
  final String parkingNote;
  final String lastSegmentNote;
  final String note;
  final int sortOrder;

  bool get isEmpty =>
      transportType.trim().isEmpty &&
      durationMinMinutes == null &&
      durationMaxMinutes == null &&
      distanceKm == null &&
      routeHint.trim().isEmpty &&
      roadCondition.trim().isEmpty &&
      !requires4x4 &&
      parkingNote.trim().isEmpty &&
      lastSegmentNote.trim().isEmpty &&
      note.trim().isEmpty;

  factory PlaceAccessOptionVm.fromJson(Map<String, dynamic> json) {
    return PlaceAccessOptionVm(
      transportType: _stringFromJson(json['transportType']),
      durationMinMinutes: json['durationMinMinutes'] as int?,
      durationMaxMinutes: json['durationMaxMinutes'] as int?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      routeHint: _stringFromJson(json['routeHint']),
      roadCondition: _stringFromJson(json['roadCondition']),
      requires4x4: json['requires4x4'] as bool? ?? false,
      parkingNote: _stringFromJson(json['parkingNote']),
      lastSegmentNote: _stringFromJson(json['lastSegmentNote']),
      note: _stringFromJson(json['note']),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class PlacePracticalNoteVm {
  const PlacePracticalNoteVm({
    required this.noteType,
    required this.title,
    required this.body,
    required this.priority,
    required this.sortOrder,
  });

  final String noteType;
  final String title;
  final String body;
  final String priority;
  final int sortOrder;

  bool get isEmpty =>
      noteType.trim().isEmpty && title.trim().isEmpty && body.trim().isEmpty;

  factory PlacePracticalNoteVm.fromJson(Map<String, dynamic> json) {
    return PlacePracticalNoteVm(
      noteType: _stringFromJson(json['noteType']),
      title: _stringFromJson(json['title']),
      body: _stringFromJson(json['body']),
      priority: _stringFromJson(json['priority']),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class PlaceRecommendedItemVm {
  const PlaceRecommendedItemVm({
    required this.itemType,
    required this.title,
    required this.note,
    required this.importance,
    required this.season,
    required this.sortOrder,
  });

  final String itemType;
  final String title;
  final String note;
  final String importance;
  final String season;
  final int sortOrder;

  bool get isEmpty =>
      itemType.trim().isEmpty && title.trim().isEmpty && note.trim().isEmpty;

  factory PlaceRecommendedItemVm.fromJson(Map<String, dynamic> json) {
    return PlaceRecommendedItemVm(
      itemType: _stringFromJson(json['itemType']),
      title: _stringFromJson(json['title']),
      note: _stringFromJson(json['note']),
      importance: _stringFromJson(json['importance']),
      season: _stringFromJson(json['season']),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class PlaceVisitInfoVm {
  const PlaceVisitInfoVm({
    this.bestTime,
    this.accessibility,
    this.bookingRequired,
    this.openingHours,
    required this.amenities,
    required this.audience,
    required this.safetyNotes,
    required this.nearbyIds,
    required this.localizedTips,
    this.feeDetails = const [],
    this.priceNote,
    this.season,
    this.timeOnSite,
    this.carTravelTime,
    this.roadCondition,
    this.accessOptions = const [],
    this.practicalNotes = const [],
    this.recommendedItems = const [],
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
  final List<PlaceFeeDetailVm> feeDetails;
  final String? priceNote;
  final PlaceSeasonVm? season;
  final PlaceVisitDurationVm? timeOnSite;
  final PlaceVisitDurationVm? carTravelTime;
  final String? roadCondition;
  final List<PlaceAccessOptionVm> accessOptions;
  final List<PlacePracticalNoteVm> practicalNotes;
  final List<PlaceRecommendedItemVm> recommendedItems;

  bool get isEmpty =>
      (bestTime ?? '').trim().isEmpty &&
      (accessibility ?? '').trim().isEmpty &&
      bookingRequired == null &&
      (openingHours ?? '').trim().isEmpty &&
      amenities.isEmpty &&
      audience.isEmpty &&
      safetyNotes.isEmpty &&
      nearbyIds.isEmpty &&
      localizedTips.isEmpty &&
      feeDetails.isEmpty &&
      (priceNote ?? '').trim().isEmpty &&
      (season == null || season!.isEmpty) &&
      (timeOnSite == null || timeOnSite!.isEmpty) &&
      (carTravelTime == null || carTravelTime!.isEmpty) &&
      (roadCondition ?? '').trim().isEmpty &&
      accessOptions.isEmpty &&
      practicalNotes.isEmpty &&
      recommendedItems.isEmpty;

  factory PlaceVisitInfoVm.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return empty;
    }
    final timeOnSite = PlaceVisitDurationVm.fromJson(
      json['timeOnSite'] is Map<String, dynamic>
          ? json['timeOnSite'] as Map<String, dynamic>
          : null,
    );
    final carTravelTime = PlaceVisitDurationVm.fromJson(
      json['carTravelTime'] is Map<String, dynamic>
          ? json['carTravelTime'] as Map<String, dynamic>
          : null,
    );
    final season = PlaceSeasonVm.fromJson(
      json['season'] is Map<String, dynamic>
          ? json['season'] as Map<String, dynamic>
          : null,
    );
    return PlaceVisitInfoVm(
      bestTime: json['bestTime'] as String?,
      accessibility: json['accessibility'] as String?,
      bookingRequired: json['bookingRequired'] as bool?,
      openingHours: _stringFromJson(json['openingHours']),
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
      feeDetails: parsePlaceFeeDetails(json),
      priceNote: _nullableStringFromJson(json['priceNote']),
      season: season.isEmpty ? null : season,
      timeOnSite: timeOnSite.isEmpty ? null : timeOnSite,
      carTravelTime: carTravelTime.isEmpty ? null : carTravelTime,
      roadCondition: _nullableStringFromJson(json['roadCondition']),
      accessOptions: _parseAccessOptions(json['accessOptions']),
      practicalNotes: _parsePracticalNotes(json['practicalNotes']),
      recommendedItems: _parseRecommendedItems(json['recommendedItems']),
    );
  }

  static const empty = PlaceVisitInfoVm(
    amenities: [],
    audience: [],
    safetyNotes: [],
    nearbyIds: [],
    localizedTips: {},
    feeDetails: [],
    accessOptions: [],
    practicalNotes: [],
    recommendedItems: [],
  );
}

class PlaceVm {
  const PlaceVm({
    required this.id,
    required this.locale,
    required this.defaultLocale,
    required this.title,
    required this.description,
    required this.countryCode,
    required this.cityId,
    this.latitude,
    this.longitude,
    required this.locationSourceUrl,
    required this.category,
    this.priceAmount,
    this.priceCurrency,
    this.priceSummaryLabel,
    this.durationValue,
    this.durationUnit,
    required this.rating,
    required this.reviewCount,
    this.spots,
    required this.source,
    required this.status,
    required this.tags,
    required this.visitInfo,
    this.feeDetails = const [],
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
  final double? latitude;
  final double? longitude;
  final String locationSourceUrl;
  final String category;
  final double? priceAmount;
  final String? priceCurrency;
  final String? priceSummaryLabel;
  final int? durationValue;
  final String? durationUnit;
  final double rating;
  final int reviewCount;
  final int? spots;
  final String source;
  final String status;
  final List<String> tags;
  final PlaceVisitInfoVm visitInfo;
  final List<PlaceFeeDetailVm> feeDetails;
  final Map<String, PlaceTranslationVm> translations;
  final List<PlaceMediaVm> media;
  final PlaceAuthorVm author;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  PlaceMediaVm? get coverMedia {
    if (media.isEmpty) return null;
    final sorted = List<PlaceMediaVm>.from(media)
      ..sort((a, b) => a.position.compareTo(b.position));
    for (final item in sorted) {
      final fileId = item.fileId.trim();
      if (fileId.isNotEmpty &&
          fileId != '00000000-0000-0000-0000-000000000000') {
        return item;
      }
    }
    return sorted.first;
  }

  String? get coverFileId {
    final fileId = coverMedia?.fileId.trim();
    return fileId == null ||
            fileId.isEmpty ||
            fileId == '00000000-0000-0000-0000-000000000000'
        ? null
        : fileId;
  }

  bool get hasLocation => latitude != null && longitude != null;

  factory PlaceVm.fromJson(Map<String, dynamic> json) {
    final mediaList = (json['media'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PlaceMediaVm.fromJson)
        .toList();

    final tagsList = (json['tags'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final translations = (json['translations'] as Map<String, dynamic>? ?? {})
        .map((key, value) {
          if (value is! Map<String, dynamic>) {
            return MapEntry(
              key,
              const PlaceTranslationVm(title: '', description: ''),
            );
          }
          return MapEntry(key, PlaceTranslationVm.fromJson(value));
        });

    final visitInfo = PlaceVisitInfoVm.fromJson(
      json['visitInfo'] is Map<String, dynamic>
          ? json['visitInfo'] as Map<String, dynamic>
          : null,
    );
    final feeDetails = parsePlaceFeeDetails(json).isNotEmpty
        ? parsePlaceFeeDetails(json)
        : visitInfo.feeDetails;

    return PlaceVm(
      id: json['id'] as String? ?? '',
      locale: json['locale'] as String? ?? 'en',
      defaultLocale: json['defaultLocale'] as String? ?? 'en',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      cityId: json['cityId'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationSourceUrl: json['locationSourceUrl'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      priceAmount: (json['priceAmount'] as num?)?.toDouble(),
      priceCurrency: json['priceCurrency'] as String?,
      priceSummaryLabel: _nullableStringFromJson(json['priceSummaryLabel']),
      durationValue: json['durationValue'] as int?,
      durationUnit: json['durationUnit'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      spots: json['spots'] as int?,
      source: json['source'] as String? ?? 'USER',
      status: json['status'] as String? ?? 'DRAFT',
      tags: tagsList,
      visitInfo: visitInfo,
      feeDetails: feeDetails,
      translations: translations,
      media: mediaList,
      author: json['author'] is Map<String, dynamic>
          ? PlaceAuthorVm.fromJson(json['author'] as Map<String, dynamic>)
          : const PlaceAuthorVm(userId: ''),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      deletedAt: json['deletedAt'] as String?,
    );
  }
}

List<PlaceFeeDetailVm> parsePlaceFeeDetails(Map<String, dynamic> json) {
  final raw = json['feeItems'] ?? json['feeDetails'] ?? json['costBreakdown'];
  final details =
      (raw as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PlaceFeeDetailVm.fromJson)
          .where(
            (item) =>
                item.title.trim().isNotEmpty ||
                item.description.trim().isNotEmpty ||
                item.note.trim().isNotEmpty ||
                item.amount != null ||
                item.minAmount != null ||
                item.maxAmount != null,
          )
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return details;
}

List<PlaceAccessOptionVm> _parseAccessOptions(dynamic raw) {
  final items =
      (raw as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PlaceAccessOptionVm.fromJson)
          .where((item) => !item.isEmpty)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return items;
}

List<PlacePracticalNoteVm> _parsePracticalNotes(dynamic raw) {
  final items =
      (raw as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PlacePracticalNoteVm.fromJson)
          .where((item) => !item.isEmpty)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return items;
}

List<PlaceRecommendedItemVm> _parseRecommendedItems(dynamic raw) {
  final items =
      (raw as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PlaceRecommendedItemVm.fromJson)
          .where((item) => !item.isEmpty)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return items;
}

String? _nullableStringFromJson(dynamic value) {
  final text = _stringFromJson(value).trim();
  return text.isEmpty ? null : text;
}

String _stringFromJson(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  if (value is Map<String, dynamic>) {
    final summary = _stringFromJson(value['summary']);
    if (summary.trim().isNotEmpty) return summary;
    for (final key in const ['ru', 'en', 'kk', 'note', 'title', 'body']) {
      final localized = _stringFromJson(value[key]);
      if (localized.trim().isNotEmpty) return localized;
    }
    for (final entry in value.values) {
      final nested = _stringFromJson(entry);
      if (nested.trim().isNotEmpty) return nested;
    }
  }
  return '';
}
