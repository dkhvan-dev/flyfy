class ExcursionVm {
  const ExcursionVm({
    required this.id,
    required this.title,
    required this.summary,
    required this.status,
    required this.visibility,
    required this.priceAmount,
    required this.currency,
    this.guideProfileId,
    this.guideUserId,
    this.landmarkId,
    this.landmarkName,
    this.routeKind = 'SINGLE_PLACE',
    this.routeFingerprint,
    this.placeIds = const [],
    this.placeNames = const [],
    this.stopCount = 0,
    this.transportMode = 'WALKING',
    this.routeTheme,
    this.durationBucket,
    this.description = '',
    this.categorySlug,
    this.durationMinutes = 0,
    this.maxGroupSize = 0,
    this.languageCodes = const [],
    this.tags = const [],
    this.countryCode,
    this.cityName,
    this.departureCityId,
    this.meetingPoint = '',
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.coverFileId,
    this.coverImageUrl,
    this.photoFileIds = const [],
    this.photoImageUrls = const [],
    this.includedItems = const [],
    this.includedItemTranslations = const {},
    this.itinerary = const [],
    this.translations = const {},
    this.publishingDecision = '',
    this.guideTrustScore = 0,
    this.publishRiskScore = 0,
    this.moderationReasonCodes = const [],
    this.submittedForReviewAt,
    this.publishedOffersCount = 0,
    this.offers = const [],
    this.createdAt,
  });

  final String id;
  final String? guideProfileId;
  final String? guideUserId;
  final String? landmarkId;
  final String? landmarkName;
  final String routeKind;
  final String? routeFingerprint;
  final List<String> placeIds;
  final List<String> placeNames;
  final int stopCount;
  final String transportMode;
  final String? routeTheme;
  final String? durationBucket;
  final String title;
  final String summary;
  final String description;
  final String? categorySlug;
  final int durationMinutes;
  final int maxGroupSize;
  final List<String> languageCodes;
  final List<String> tags;
  final String status;
  final String visibility;
  final double priceAmount;
  final String currency;
  final String? countryCode;
  final String? cityName;
  final String? departureCityId;
  final String meetingPoint;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;
  final String? coverFileId;
  final String? coverImageUrl;
  final List<String> photoFileIds;
  final List<String> photoImageUrls;
  final List<String> includedItems;
  final Map<String, List<String>> includedItemTranslations;
  final List<ExcursionItineraryItemVm> itinerary;
  final Map<String, ExcursionLocalizedCopyVm> translations;
  final String publishingDecision;
  final int guideTrustScore;
  final int publishRiskScore;
  final List<String> moderationReasonCodes;
  final DateTime? submittedForReviewAt;
  final int publishedOffersCount;
  final List<ExcursionOfferVm> offers;
  final DateTime? createdAt;

  ExcursionOfferVm? get primaryOffer => offers.isNotEmpty ? offers.first : null;

  bool get isDraft => status.trim().toUpperCase() == 'DRAFT';

  bool get isPendingReview => status.trim().toUpperCase() == 'PENDING_REVIEW';

  ExcursionVm withPrimaryOffer(ExcursionOfferVm offer) {
    return ExcursionVm(
      id: id,
      guideProfileId: offer.guideProfileId,
      guideUserId: offer.guideUserId,
      landmarkId: landmarkId,
      landmarkName: landmarkName,
      routeKind: routeKind,
      routeFingerprint: routeFingerprint,
      placeIds: placeIds,
      placeNames: placeNames,
      stopCount: stopCount,
      transportMode: transportMode,
      routeTheme: routeTheme,
      durationBucket: durationBucket,
      title: offer.title.trim().isNotEmpty ? offer.title : title,
      summary: offer.summary.trim().isNotEmpty ? offer.summary : summary,
      description: offer.description.trim().isNotEmpty
          ? offer.description
          : description,
      categorySlug: categorySlug,
      durationMinutes: offer.durationMinutes > 0
          ? offer.durationMinutes
          : durationMinutes,
      maxGroupSize: offer.maxGroupSize > 0 ? offer.maxGroupSize : maxGroupSize,
      languageCodes: offer.languageCodes.isNotEmpty
          ? offer.languageCodes
          : languageCodes,
      tags: tags,
      status: status,
      visibility: visibility,
      priceAmount: offer.priceAmount,
      currency: offer.currency,
      countryCode: countryCode,
      cityName: cityName,
      departureCityId: departureCityId,
      meetingPoint: offer.meetingPoint.trim().isNotEmpty
          ? offer.meetingPoint
          : meetingPoint,
      latitude: offer.latitude ?? latitude,
      longitude: offer.longitude ?? longitude,
      mapUrl: offer.mapUrl ?? mapUrl,
      coverFileId: offer.coverFileId ?? coverFileId,
      coverImageUrl: (offer.coverFileId ?? '').trim().isNotEmpty
          ? null
          : coverImageUrl,
      photoFileIds: offer.photoFileIds.isNotEmpty
          ? offer.photoFileIds
          : photoFileIds,
      photoImageUrls: offer.photoFileIds.isNotEmpty ? const [] : photoImageUrls,
      includedItems: offer.includedItems,
      includedItemTranslations: offer.includedItemTranslations,
      itinerary: offer.itinerary,
      translations: translations,
      publishingDecision: publishingDecision,
      guideTrustScore: guideTrustScore,
      publishRiskScore: publishRiskScore,
      moderationReasonCodes: moderationReasonCodes,
      submittedForReviewAt: submittedForReviewAt,
      publishedOffersCount: publishedOffersCount,
      offers: offers,
      createdAt: createdAt,
    );
  }

  factory ExcursionVm.fromJson(
    Map<String, dynamic> json, {
    List<ExcursionOfferVm>? offers,
  }) {
    final parsedOffers = offers ?? _offers(json['offers']);
    final primaryOffer = parsedOffers.isNotEmpty ? parsedOffers.first : null;
    final languageCodes = _stringList(json['languageCodes']);
    final includedItems = _stringList(json['includedItems']);

    return ExcursionVm(
      id: (json['id'] as String?) ?? '',
      guideProfileId:
          json['guideProfileId'] as String? ?? primaryOffer?.guideProfileId,
      guideUserId: json['guideUserId'] as String? ?? primaryOffer?.guideUserId,
      landmarkId: json['landmarkId'] as String?,
      landmarkName: json['landmarkName'] as String?,
      routeKind: (json['routeKind'] as String?) ?? 'SINGLE_PLACE',
      routeFingerprint: json['routeFingerprint'] as String?,
      placeIds: _stringList(json['placeIds']),
      placeNames: _stringList(json['placeNames']),
      stopCount: (json['stopCount'] as num?)?.toInt() ?? 0,
      transportMode: (json['transportMode'] as String?) ?? 'WALKING',
      routeTheme: json['routeTheme'] as String?,
      durationBucket: json['durationBucket'] as String?,
      title: (json['title'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      categorySlug: json['categorySlug'] as String?,
      durationMinutes:
          (json['durationMinutes'] as num?)?.toInt() ??
          primaryOffer?.durationMinutes ??
          0,
      maxGroupSize:
          (json['maxGroupSize'] as num?)?.toInt() ??
          primaryOffer?.maxGroupSize ??
          0,
      languageCodes: languageCodes.isNotEmpty
          ? languageCodes
          : primaryOffer?.languageCodes ?? const [],
      tags: _stringList(json['tags']),
      status: (json['status'] as String?) ?? 'DRAFT',
      visibility: (json['visibility'] as String?) ?? 'PUBLIC',
      priceAmount:
          (json['priceAmount'] as num?)?.toDouble() ??
          primaryOffer?.priceAmount ??
          (json['minPriceAmount'] as num?)?.toDouble() ??
          0,
      currency:
          (json['currency'] as String?) ?? primaryOffer?.currency ?? 'KZT',
      countryCode: json['countryCode'] as String?,
      cityName: json['cityName'] as String?,
      departureCityId: json['departureCityId'] as String?,
      meetingPoint:
          (json['meetingPoint'] as String?) ?? primaryOffer?.meetingPoint ?? '',
      latitude:
          (json['latitude'] as num?)?.toDouble() ?? primaryOffer?.latitude,
      longitude:
          (json['longitude'] as num?)?.toDouble() ?? primaryOffer?.longitude,
      mapUrl: json['mapUrl'] as String? ?? primaryOffer?.mapUrl,
      coverFileId: json['coverFileId'] as String? ?? primaryOffer?.coverFileId,
      coverImageUrl: json['coverImageUrl'] as String?,
      photoFileIds: _stringList(json['photoFileIds']),
      photoImageUrls: _stringList(json['photoImageUrls']),
      includedItems: includedItems,
      includedItemTranslations: _includedItemTranslations(
        json['includedItemTranslations'],
      ),
      itinerary: _itinerary(json['itinerary']),
      translations: _translations(json),
      publishingDecision: (json['publishingDecision'] as String?) ?? '',
      guideTrustScore: (json['guideTrustScore'] as num?)?.toInt() ?? 0,
      publishRiskScore: (json['publishRiskScore'] as num?)?.toInt() ?? 0,
      moderationReasonCodes: _stringList(json['moderationReasonCodes']),
      submittedForReviewAt: DateTime.tryParse(
        (json['submittedForReviewAt'] as String?) ?? '',
      )?.toUtc(),
      publishedOffersCount:
          (json['publishedOffersCount'] as num?)?.toInt() ??
          parsedOffers.length,
      offers: parsedOffers,
      createdAt: DateTime.tryParse(
        (json['createdAt'] as String?) ?? '',
      )?.toUtc(),
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];

    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<ExcursionItineraryItemVm> _itinerary(Object? value) {
    if (value is! List) return const [];

    return value
        .whereType<Map<String, dynamic>>()
        .map(ExcursionItineraryItemVm.fromJson)
        .toList(growable: false);
  }

  static List<ExcursionOfferVm> _offers(Object? value) {
    if (value is! List) return const [];

    return value
        .whereType<Map<String, dynamic>>()
        .map(ExcursionOfferVm.fromJson)
        .toList(growable: false);
  }

  static Map<String, ExcursionLocalizedCopyVm> _translations(
    Map<String, dynamic> json,
  ) {
    final value = json['translations'] ?? json['localizedContent'];
    if (value is! Map<String, dynamic>) return const {};

    final entries = <String, ExcursionLocalizedCopyVm>{};
    for (final entry in value.entries) {
      final locale = entry.key.trim().toLowerCase();
      final rawCopy = entry.value;
      if (locale.isEmpty || rawCopy is! Map<String, dynamic>) continue;

      final copy = ExcursionLocalizedCopyVm.fromJson(rawCopy);
      if (!copy.isEmpty) {
        entries[locale] = copy;
      }
    }
    return Map.unmodifiable(entries);
  }

  static Map<String, List<String>> _includedItemTranslations(Object? value) {
    if (value is! Map<String, dynamic>) return const {};

    final result = <String, List<String>>{};
    for (final entry in value.entries) {
      final locale = entry.key.trim().toLowerCase().replaceAll('_', '-');
      final rawValues = entry.value;
      if (locale.isEmpty || rawValues is! List) continue;

      final values = rawValues
          .whereType<String>()
          .map((item) => item.trim())
          .toList(growable: false);
      if (values.every((item) => item.isEmpty)) continue;

      result[locale] = List.unmodifiable(values);
    }
    return Map.unmodifiable(result);
  }

  List<String> localizedIncludedItems(String languageCode) {
    final normalized = _normalizeLocale(languageCode);
    final localized =
        includedItemTranslations[normalized] ??
        includedItemTranslations[normalized.split('-').first];
    if (localized == null || localized.isEmpty) {
      return includedItems;
    }

    return List<String>.generate(includedItems.length, (index) {
      if (index >= localized.length || localized[index].trim().isEmpty) {
        return includedItems[index];
      }
      return localized[index].trim();
    }, growable: false);
  }
}

class ExcursionLocalizedCopyVm {
  const ExcursionLocalizedCopyVm({
    this.title = '',
    this.summary = '',
    this.description = '',
  });

  final String title;
  final String summary;
  final String description;

  bool get isEmpty =>
      title.trim().isEmpty &&
      summary.trim().isEmpty &&
      description.trim().isEmpty;

  factory ExcursionLocalizedCopyVm.fromJson(Map<String, dynamic> json) {
    return ExcursionLocalizedCopyVm(
      title: (json['title'] as String?)?.trim() ?? '',
      summary: (json['summary'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
    );
  }
}

class ExcursionOfferVm {
  const ExcursionOfferVm({
    required this.id,
    required this.productId,
    required this.guideProfileId,
    required this.guideUserId,
    required this.status,
    required this.visibility,
    required this.durationMinutes,
    required this.maxGroupSize,
    required this.meetingPoint,
    required this.priceAmount,
    required this.currency,
    this.legacyExcursionId,
    this.guideRatingAvg = 0,
    this.guideReviewsCount = 0,
    this.guideExperienceYears = 0,
    this.guideDisplayName = '',
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.coverFileId,
    this.photoFileIds = const [],
    this.title = '',
    this.summary = '',
    this.description = '',
    this.languageCodes = const [],
    this.includedItems = const [],
    this.includedItemTranslations = const {},
    this.itinerary = const [],
    this.translations = const {},
  });

  final String id;
  final String productId;
  final String? legacyExcursionId;
  final String guideProfileId;
  final String guideUserId;
  final double guideRatingAvg;
  final int guideReviewsCount;
  final int guideExperienceYears;
  final String guideDisplayName;
  final String title;
  final String summary;
  final String description;
  final String status;
  final String visibility;
  final int durationMinutes;
  final int maxGroupSize;
  final String meetingPoint;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;
  final double priceAmount;
  final String currency;
  final String? coverFileId;
  final List<String> photoFileIds;
  final List<String> languageCodes;
  final List<String> includedItems;
  final Map<String, List<String>> includedItemTranslations;
  final List<ExcursionItineraryItemVm> itinerary;
  final Map<String, ExcursionLocalizedCopyVm> translations;

  factory ExcursionOfferVm.fromJson(Map<String, dynamic> json) {
    return ExcursionOfferVm(
      id: (json['id'] as String?) ?? '',
      productId: (json['productId'] as String?) ?? '',
      legacyExcursionId: json['legacyExcursionId'] as String?,
      guideProfileId: (json['guideProfileId'] as String?) ?? '',
      guideUserId: (json['guideUserId'] as String?) ?? '',
      guideRatingAvg: (json['guideRatingAvg'] as num?)?.toDouble() ?? 0,
      guideReviewsCount: (json['guideReviewsCount'] as num?)?.toInt() ?? 0,
      guideExperienceYears:
          (json['guideExperienceYears'] as num?)?.toInt() ?? 0,
      guideDisplayName: (json['guideDisplayName'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'DRAFT',
      visibility: (json['visibility'] as String?) ?? 'PUBLIC',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      maxGroupSize: (json['maxGroupSize'] as num?)?.toInt() ?? 0,
      meetingPoint: (json['meetingPoint'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mapUrl: json['mapUrl'] as String?,
      priceAmount: (json['priceAmount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? 'KZT',
      coverFileId: json['coverFileId'] as String?,
      photoFileIds: ExcursionVm._stringList(json['photoFileIds']),
      languageCodes: ExcursionVm._stringList(json['languageCodes']),
      includedItems: ExcursionVm._stringList(json['includedItems']),
      includedItemTranslations: ExcursionVm._includedItemTranslations(
        json['includedItemTranslations'],
      ),
      itinerary: ExcursionVm._itinerary(json['itinerary']),
      translations: ExcursionVm._translations(json),
    );
  }

  List<String> localizedIncludedItems(String languageCode) {
    final normalized = _normalizeLocale(languageCode);
    final localized =
        includedItemTranslations[normalized] ??
        includedItemTranslations[normalized.split('-').first];
    if (localized == null || localized.isEmpty) {
      return includedItems;
    }

    return List<String>.generate(includedItems.length, (index) {
      if (index >= localized.length || localized[index].trim().isEmpty) {
        return includedItems[index];
      }
      return localized[index].trim();
    }, growable: false);
  }
}

class ExcursionItineraryLocalizedCopyVm {
  const ExcursionItineraryLocalizedCopyVm({
    this.title = '',
    this.description = '',
  });

  final String title;
  final String description;

  bool get isEmpty => title.trim().isEmpty && description.trim().isEmpty;

  factory ExcursionItineraryLocalizedCopyVm.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExcursionItineraryLocalizedCopyVm(
      title: (json['title'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
    );
  }
}

class ExcursionItineraryItemVm {
  const ExcursionItineraryItemVm({
    required this.id,
    required this.sortOrder,
    required this.startOffsetMinutes,
    required this.title,
    required this.description,
    this.durationMinutes,
    this.placeId,
    this.placeName,
    this.latitude,
    this.longitude,
    this.travelFromPreviousMinutes,
    this.translations = const {},
  });

  final String id;
  final int sortOrder;
  final int startOffsetMinutes;
  final int? durationMinutes;
  final String? placeId;
  final String? placeName;
  final double? latitude;
  final double? longitude;
  final int? travelFromPreviousMinutes;
  final String title;
  final String description;
  final Map<String, ExcursionItineraryLocalizedCopyVm> translations;

  factory ExcursionItineraryItemVm.fromJson(Map<String, dynamic> json) {
    return ExcursionItineraryItemVm(
      id: (json['id'] as String?) ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      startOffsetMinutes: (json['startOffsetMinutes'] as num?)?.toInt() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      placeId: json['placeId'] as String?,
      placeName: json['placeName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      travelFromPreviousMinutes: (json['travelFromPreviousMinutes'] as num?)
          ?.toInt(),
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      translations: _translations(json['translations']),
    );
  }

  static Map<String, ExcursionItineraryLocalizedCopyVm> _translations(
    Object? value,
  ) {
    if (value is! Map<String, dynamic>) return const {};

    final result = <String, ExcursionItineraryLocalizedCopyVm>{};
    for (final entry in value.entries) {
      final locale = entry.key.trim().toLowerCase().replaceAll('_', '-');
      final rawCopy = entry.value;
      if (locale.isEmpty || rawCopy is! Map<String, dynamic>) continue;

      final copy = ExcursionItineraryLocalizedCopyVm.fromJson(rawCopy);
      if (!copy.isEmpty) {
        result[locale] = copy;
      }
    }
    return Map.unmodifiable(result);
  }

  String localizedTitle(String languageCode) {
    final copy = _copyFor(languageCode);
    final localized = copy?.title.trim() ?? '';
    return localized.isNotEmpty ? localized : title;
  }

  String localizedDescription(String languageCode) {
    final copy = _copyFor(languageCode);
    final localized = copy?.description.trim() ?? '';
    return localized.isNotEmpty ? localized : description;
  }

  ExcursionItineraryLocalizedCopyVm? _copyFor(String languageCode) {
    final normalized = _normalizeLocale(languageCode);
    if (normalized.isEmpty || translations.isEmpty) return null;
    return translations[normalized] ??
        translations[normalized.split('-').first];
  }
}

String _normalizeLocale(String value) {
  return value.trim().replaceAll('_', '-').toLowerCase();
}
