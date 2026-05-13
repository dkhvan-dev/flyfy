class TourVm {
  const TourVm({
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
    this.description = '',
    this.categorySlug,
    this.durationMinutes = 0,
    this.maxGroupSize = 0,
    this.languageCodes = const [],
    this.tags = const [],
    this.countryCode,
    this.cityName,
    this.meetingPoint = '',
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.coverFileId,
    this.coverImageUrl,
    this.includedItems = const [],
    this.includedItemTranslations = const {},
    this.itinerary = const [],
    this.translations = const {},
    this.publishedOffersCount = 0,
    this.offers = const [],
    this.createdAt,
  });

  final String id;
  final String? guideProfileId;
  final String? guideUserId;
  final String? landmarkId;
  final String? landmarkName;
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
  final String meetingPoint;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;
  final String? coverFileId;
  final String? coverImageUrl;
  final List<String> includedItems;
  final Map<String, List<String>> includedItemTranslations;
  final List<TourItineraryItemVm> itinerary;
  final Map<String, TourLocalizedCopyVm> translations;
  final int publishedOffersCount;
  final List<TourOfferVm> offers;
  final DateTime? createdAt;

  TourOfferVm? get primaryOffer => offers.isNotEmpty ? offers.first : null;

  TourVm withPrimaryOffer(TourOfferVm offer) {
    return TourVm(
      id: id,
      guideProfileId: offer.guideProfileId,
      guideUserId: offer.guideUserId,
      landmarkId: landmarkId,
      landmarkName: landmarkName,
      title: offer.title.trim().isNotEmpty ? offer.title : title,
      summary: offer.summary.trim().isNotEmpty ? offer.summary : summary,
      description:
          offer.description.trim().isNotEmpty ? offer.description : description,
      categorySlug: categorySlug,
      durationMinutes:
          offer.durationMinutes > 0 ? offer.durationMinutes : durationMinutes,
      maxGroupSize: offer.maxGroupSize > 0 ? offer.maxGroupSize : maxGroupSize,
      languageCodes:
          offer.languageCodes.isNotEmpty ? offer.languageCodes : languageCodes,
      tags: tags,
      status: status,
      visibility: visibility,
      priceAmount: offer.priceAmount,
      currency: offer.currency,
      countryCode: countryCode,
      cityName: cityName,
      meetingPoint: offer.meetingPoint.trim().isNotEmpty
          ? offer.meetingPoint
          : meetingPoint,
      latitude: offer.latitude ?? latitude,
      longitude: offer.longitude ?? longitude,
      mapUrl: offer.mapUrl ?? mapUrl,
      coverFileId: offer.coverFileId ?? coverFileId,
      coverImageUrl:
          (offer.coverFileId ?? '').trim().isNotEmpty ? null : coverImageUrl,
      includedItems: offer.includedItems,
      includedItemTranslations: offer.includedItemTranslations,
      itinerary: offer.itinerary,
      translations: translations,
      publishedOffersCount: publishedOffersCount,
      offers: offers,
      createdAt: createdAt,
    );
  }

  factory TourVm.fromJson(
    Map<String, dynamic> json, {
    List<TourOfferVm>? offers,
  }) {
    final parsedOffers = offers ?? _offers(json['offers']);
    final primaryOffer = parsedOffers.isNotEmpty ? parsedOffers.first : null;
    final languageCodes = _stringList(json['languageCodes']);
    final includedItems = _stringList(json['includedItems']);

    return TourVm(
      id: (json['id'] as String?) ?? '',
      guideProfileId:
          json['guideProfileId'] as String? ?? primaryOffer?.guideProfileId,
      guideUserId: json['guideUserId'] as String? ?? primaryOffer?.guideUserId,
      landmarkId: json['landmarkId'] as String?,
      landmarkName: json['landmarkName'] as String?,
      title: (json['title'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      categorySlug: json['categorySlug'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ??
          primaryOffer?.durationMinutes ??
          0,
      maxGroupSize: (json['maxGroupSize'] as num?)?.toInt() ??
          primaryOffer?.maxGroupSize ??
          0,
      languageCodes: languageCodes.isNotEmpty
          ? languageCodes
          : primaryOffer?.languageCodes ?? const [],
      tags: _stringList(json['tags']),
      status: (json['status'] as String?) ?? 'DRAFT',
      visibility: (json['visibility'] as String?) ?? 'PUBLIC',
      priceAmount: (json['priceAmount'] as num?)?.toDouble() ??
          primaryOffer?.priceAmount ??
          (json['minPriceAmount'] as num?)?.toDouble() ??
          0,
      currency:
          (json['currency'] as String?) ?? primaryOffer?.currency ?? 'KZT',
      countryCode: json['countryCode'] as String?,
      cityName: json['cityName'] as String?,
      meetingPoint:
          (json['meetingPoint'] as String?) ?? primaryOffer?.meetingPoint ?? '',
      latitude:
          (json['latitude'] as num?)?.toDouble() ?? primaryOffer?.latitude,
      longitude:
          (json['longitude'] as num?)?.toDouble() ?? primaryOffer?.longitude,
      mapUrl: json['mapUrl'] as String? ?? primaryOffer?.mapUrl,
      coverFileId: json['coverFileId'] as String? ?? primaryOffer?.coverFileId,
      coverImageUrl: json['coverImageUrl'] as String?,
      includedItems: includedItems,
      includedItemTranslations: _includedItemTranslations(
        json['includedItemTranslations'],
      ),
      itinerary: _itinerary(json['itinerary']),
      translations: _translations(json),
      publishedOffersCount: (json['publishedOffersCount'] as num?)?.toInt() ??
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

  static List<TourItineraryItemVm> _itinerary(Object? value) {
    if (value is! List) return const [];

    return value
        .whereType<Map<String, dynamic>>()
        .map(TourItineraryItemVm.fromJson)
        .toList(growable: false);
  }

  static List<TourOfferVm> _offers(Object? value) {
    if (value is! List) return const [];

    return value
        .whereType<Map<String, dynamic>>()
        .map(TourOfferVm.fromJson)
        .toList(growable: false);
  }

  static Map<String, TourLocalizedCopyVm> _translations(
    Map<String, dynamic> json,
  ) {
    final value = json['translations'] ?? json['localizedContent'];
    if (value is! Map<String, dynamic>) return const {};

    final entries = <String, TourLocalizedCopyVm>{};
    for (final entry in value.entries) {
      final locale = entry.key.trim().toLowerCase();
      final rawCopy = entry.value;
      if (locale.isEmpty || rawCopy is! Map<String, dynamic>) continue;

      final copy = TourLocalizedCopyVm.fromJson(rawCopy);
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
    final localized = includedItemTranslations[normalized] ??
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

class TourLocalizedCopyVm {
  const TourLocalizedCopyVm({
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

  factory TourLocalizedCopyVm.fromJson(Map<String, dynamic> json) {
    return TourLocalizedCopyVm(
      title: (json['title'] as String?)?.trim() ?? '',
      summary: (json['summary'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
    );
  }
}

class TourOfferVm {
  const TourOfferVm({
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
    this.legacyTourId,
    this.guideRatingAvg = 0,
    this.guideReviewsCount = 0,
    this.guideExperienceYears = 0,
    this.guideDisplayName = '',
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.coverFileId,
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
  final String? legacyTourId;
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
  final List<String> languageCodes;
  final List<String> includedItems;
  final Map<String, List<String>> includedItemTranslations;
  final List<TourItineraryItemVm> itinerary;
  final Map<String, TourLocalizedCopyVm> translations;

  factory TourOfferVm.fromJson(Map<String, dynamic> json) {
    return TourOfferVm(
      id: (json['id'] as String?) ?? '',
      productId: (json['productId'] as String?) ?? '',
      legacyTourId: json['legacyTourId'] as String?,
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
      languageCodes: TourVm._stringList(json['languageCodes']),
      includedItems: TourVm._stringList(json['includedItems']),
      includedItemTranslations: TourVm._includedItemTranslations(
        json['includedItemTranslations'],
      ),
      itinerary: TourVm._itinerary(json['itinerary']),
      translations: TourVm._translations(json),
    );
  }

  List<String> localizedIncludedItems(String languageCode) {
    final normalized = _normalizeLocale(languageCode);
    final localized = includedItemTranslations[normalized] ??
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

class TourItineraryLocalizedCopyVm {
  const TourItineraryLocalizedCopyVm({
    this.title = '',
    this.description = '',
  });

  final String title;
  final String description;

  bool get isEmpty => title.trim().isEmpty && description.trim().isEmpty;

  factory TourItineraryLocalizedCopyVm.fromJson(Map<String, dynamic> json) {
    return TourItineraryLocalizedCopyVm(
      title: (json['title'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
    );
  }
}

class TourItineraryItemVm {
  const TourItineraryItemVm({
    required this.id,
    required this.sortOrder,
    required this.startOffsetMinutes,
    required this.title,
    required this.description,
    this.durationMinutes,
    this.translations = const {},
  });

  final String id;
  final int sortOrder;
  final int startOffsetMinutes;
  final int? durationMinutes;
  final String title;
  final String description;
  final Map<String, TourItineraryLocalizedCopyVm> translations;

  factory TourItineraryItemVm.fromJson(Map<String, dynamic> json) {
    return TourItineraryItemVm(
      id: (json['id'] as String?) ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      startOffsetMinutes: (json['startOffsetMinutes'] as num?)?.toInt() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      translations: _translations(json['translations']),
    );
  }

  static Map<String, TourItineraryLocalizedCopyVm> _translations(
    Object? value,
  ) {
    if (value is! Map<String, dynamic>) return const {};

    final result = <String, TourItineraryLocalizedCopyVm>{};
    for (final entry in value.entries) {
      final locale = entry.key.trim().toLowerCase().replaceAll('_', '-');
      final rawCopy = entry.value;
      if (locale.isEmpty || rawCopy is! Map<String, dynamic>) continue;

      final copy = TourItineraryLocalizedCopyVm.fromJson(rawCopy);
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

  TourItineraryLocalizedCopyVm? _copyFor(String languageCode) {
    final normalized = _normalizeLocale(languageCode);
    if (normalized.isEmpty || translations.isEmpty) return null;
    return translations[normalized] ??
        translations[normalized.split('-').first];
  }
}

String _normalizeLocale(String value) {
  return value.trim().replaceAll('_', '-').toLowerCase();
}
