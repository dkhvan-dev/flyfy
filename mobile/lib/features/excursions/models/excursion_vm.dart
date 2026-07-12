import '../excursion_included_items.dart';

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
    this.translationInfo = ExcursionTranslationInfoVm.none,
    this.publishingDecision = '',
    this.guideTrustScore = 0,
    this.publishRiskScore = 0,
    this.moderationReasonCodes = const [],
    this.submittedForReviewAt,
    this.publishedOffersCount = 0,
    this.ratingAvg = 0,
    this.reviewsCount = 0,
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
  final ExcursionTranslationInfoVm translationInfo;
  final String publishingDecision;
  final int guideTrustScore;
  final int publishRiskScore;
  final List<String> moderationReasonCodes;
  final DateTime? submittedForReviewAt;
  final int publishedOffersCount;
  final double ratingAvg;
  final int reviewsCount;
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
      translations: offer.translations.isNotEmpty
          ? offer.translations
          : translations,
      translationInfo: offer.translationInfo.hasState
          ? offer.translationInfo
          : translationInfo,
      publishingDecision: publishingDecision,
      guideTrustScore: guideTrustScore,
      publishRiskScore: publishRiskScore,
      moderationReasonCodes: moderationReasonCodes,
      submittedForReviewAt: submittedForReviewAt,
      publishedOffersCount: publishedOffersCount,
      ratingAvg: ratingAvg,
      reviewsCount: reviewsCount,
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
    final includedItemsPayload = _includedItemsPayload(
      json['includedItems'],
      json['includedItemTranslations'],
    );
    final translationInfo = _translationInfo(json, parsedOffers);

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
      includedItems: includedItemsPayload.items,
      includedItemTranslations: includedItemsPayload.translations,
      itinerary: _itinerary(json['itinerary']),
      translations: _translations(json),
      translationInfo: translationInfo,
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
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
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
    final value =
        json['translations'] ??
        json['productTranslations'] ??
        json['localizedContent'];
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

  static ({List<String> items, Map<String, List<String>> translations})
  _includedItemsPayload(Object? rawItems, Object? rawTranslations) {
    final items = _stringList(rawItems);
    final translations = _includedItemTranslations(rawTranslations);
    final retainedIndexes = <int>[
      for (var index = 0; index < items.length; index++)
        if (!ExcursionIncludedItemKey.isDeprecated(items[index])) index,
    ];
    if (retainedIndexes.length == items.length) {
      return (items: items, translations: translations);
    }

    final filteredItems = List<String>.unmodifiable(
      retainedIndexes.map((index) => items[index]),
    );
    final filteredTranslations = <String, List<String>>{};
    for (final entry in translations.entries) {
      final values = List<String>.unmodifiable(
        retainedIndexes.map(
          (index) => index < entry.value.length ? entry.value[index] : '',
        ),
      );
      if (values.any((value) => value.trim().isNotEmpty)) {
        filteredTranslations[entry.key] = values;
      }
    }
    return (
      items: filteredItems,
      translations: Map.unmodifiable(filteredTranslations),
    );
  }

  static ExcursionTranslationInfoVm _translationInfo(
    Map<String, dynamic> json,
    List<ExcursionOfferVm> offers,
  ) {
    if (offers.isNotEmpty && offers.first.translationInfo.hasState) {
      return offers.first.translationInfo;
    }
    final explicit = ExcursionTranslationInfoVm.fromJson(
      json['translationInfo'],
    );
    if (explicit.hasState) {
      return explicit;
    }

    final sourceLanguage = _inferTranslationSourceLanguage(json, offers);
    if (sourceLanguage.isEmpty) {
      return ExcursionTranslationInfoVm.none;
    }

    final targetLanguages = <String>{};
    _collectCopyTranslationTargets(
      _translations(json),
      sourceLanguage,
      targetLanguages,
    );
    for (final offer in offers) {
      _collectCopyTranslationTargets(
        offer.translations,
        sourceLanguage,
        targetLanguages,
      );
      for (final item in offer.itinerary) {
        _collectItineraryTranslationTargets(
          item.translations,
          sourceLanguage,
          targetLanguages,
        );
      }
    }

    if (targetLanguages.isEmpty) {
      return ExcursionTranslationInfoVm.none;
    }

    final orderedTargets = targetLanguages.toList(growable: false)..sort();
    return ExcursionTranslationInfoVm(
      translated: true,
      sourceLanguage: sourceLanguage,
      targetLanguages: orderedTargets,
      provider: 'translation_service',
    );
  }

  static String _inferTranslationSourceLanguage(
    Map<String, dynamic> json,
    List<ExcursionOfferVm> offers,
  ) {
    final productSource = _inferCopyTranslationSourceLanguage(
      title: (json['title'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      translations: _translations(json),
    );
    if (productSource.isNotEmpty) {
      return productSource;
    }

    for (final offer in offers) {
      final offerSource = _inferCopyTranslationSourceLanguage(
        title: offer.title,
        summary: offer.summary,
        description: offer.description,
        translations: offer.translations,
      );
      if (offerSource.isNotEmpty) {
        return offerSource;
      }

      for (final item in offer.itinerary) {
        final itinerarySource = _inferItineraryTranslationSourceLanguage(item);
        if (itinerarySource.isNotEmpty) {
          return itinerarySource;
        }
      }
    }

    return '';
  }

  static String _inferCopyTranslationSourceLanguage({
    required String title,
    required String summary,
    required String description,
    required Map<String, ExcursionLocalizedCopyVm> translations,
  }) {
    if (translations.isEmpty) return '';

    final baseTitle = _normalizeTranslatedTextForCompare(title);
    final baseSummary = _normalizeTranslatedTextForCompare(summary);
    final baseDescription = _normalizeTranslatedTextForCompare(description);
    if (baseTitle.isEmpty && baseSummary.isEmpty && baseDescription.isEmpty) {
      return '';
    }

    for (final locale in _supportedTranslationLocales) {
      final copy = translations[locale];
      if (copy == null) continue;
      if (_copyMatchesBase(
        copy,
        baseTitle: baseTitle,
        baseSummary: baseSummary,
        baseDescription: baseDescription,
      )) {
        return locale;
      }
    }
    return '';
  }

  static String _inferItineraryTranslationSourceLanguage(
    ExcursionItineraryItemVm item,
  ) {
    if (item.translations.isEmpty) return '';

    final baseTitle = _normalizeTranslatedTextForCompare(item.title);
    final baseDescription = _normalizeTranslatedTextForCompare(
      item.description,
    );
    if (baseTitle.isEmpty && baseDescription.isEmpty) {
      return '';
    }

    for (final locale in _supportedTranslationLocales) {
      final copy = item.translations[locale];
      if (copy == null) continue;
      if (_itineraryCopyMatchesBase(
        copy,
        baseTitle: baseTitle,
        baseDescription: baseDescription,
      )) {
        return locale;
      }
    }
    return '';
  }

  static void _collectCopyTranslationTargets(
    Map<String, ExcursionLocalizedCopyVm> translations,
    String sourceLanguage,
    Set<String> targets,
  ) {
    for (final entry in translations.entries) {
      final language = _normalizeSupportedTranslationLocale(entry.key);
      if (language.isEmpty || language == sourceLanguage) continue;
      if (entry.value.isEmpty) continue;
      targets.add(language);
    }
  }

  static void _collectItineraryTranslationTargets(
    Map<String, ExcursionItineraryLocalizedCopyVm> translations,
    String sourceLanguage,
    Set<String> targets,
  ) {
    for (final entry in translations.entries) {
      final language = _normalizeSupportedTranslationLocale(entry.key);
      if (language.isEmpty || language == sourceLanguage) continue;
      if (entry.value.isEmpty) continue;
      targets.add(language);
    }
  }

  static bool _copyMatchesBase(
    ExcursionLocalizedCopyVm copy, {
    required String baseTitle,
    required String baseSummary,
    required String baseDescription,
  }) {
    final title = _normalizeTranslatedTextForCompare(copy.title);
    final summary = _normalizeTranslatedTextForCompare(copy.summary);
    final description = _normalizeTranslatedTextForCompare(copy.description);
    final titleMatches = baseTitle.isEmpty || title == baseTitle;
    final summaryMatches = baseSummary.isEmpty || summary == baseSummary;
    final descriptionMatches =
        baseDescription.isEmpty || description == baseDescription;
    return titleMatches && summaryMatches && descriptionMatches;
  }

  static bool _itineraryCopyMatchesBase(
    ExcursionItineraryLocalizedCopyVm copy, {
    required String baseTitle,
    required String baseDescription,
  }) {
    final title = _normalizeTranslatedTextForCompare(copy.title);
    final description = _normalizeTranslatedTextForCompare(copy.description);
    final titleMatches = baseTitle.isEmpty || title == baseTitle;
    final descriptionMatches =
        baseDescription.isEmpty || description == baseDescription;
    return titleMatches && descriptionMatches;
  }

  static String _normalizeTranslatedTextForCompare(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) {
          return item.isNotEmpty;
        })
        .join(' ');
  }

  static String _normalizeSupportedTranslationLocale(String value) {
    final normalized = _normalizeLocale(value).split('-').first;
    return _supportedTranslationLocales.contains(normalized) ? normalized : '';
  }

  static const _supportedTranslationLocales = ['en', 'ru', 'kk'];

  List<String> localizedIncludedItems(String languageCode) {
    return _localizedIncludedItems(
      includedItems,
      includedItemTranslations,
      languageCode,
    );
  }
}

enum ExcursionTranslationNoticeState { none, translated, pending, unavailable }

class ExcursionTranslationInfoVm {
  const ExcursionTranslationInfoVm({
    this.status = 'NONE',
    this.translated = false,
    this.sourceLanguage = '',
    this.currentLanguage = '',
    this.isTranslated = false,
    this.availableLanguages = const [],
    this.pendingLanguages = const [],
    this.failedLanguages = const [],
    this.targetLanguages = const [],
    this.provider = '',
  });

  static const none = ExcursionTranslationInfoVm();

  final String status;
  final bool translated;
  final String sourceLanguage;
  final String currentLanguage;
  final bool isTranslated;
  final List<String> availableLanguages;
  final List<String> pendingLanguages;
  final List<String> failedLanguages;
  final List<String> targetLanguages;
  final String provider;

  bool get hasState =>
      sourceLanguage.isNotEmpty &&
      (status != 'NONE' ||
          translated ||
          currentLanguage.isNotEmpty ||
          availableLanguages.isNotEmpty ||
          pendingLanguages.isNotEmpty ||
          failedLanguages.isNotEmpty);

  factory ExcursionTranslationInfoVm.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return none;

    final sourceLanguage = _normalizeLocale(
      value['sourceLanguage']?.toString() ?? '',
    ).split('-').first;
    final currentLanguage = _normalizeLocale(
      value['currentLanguage']?.toString() ?? '',
    ).split('-').first;
    final legacyTargets = _normalizedLanguages(value['targetLanguages']);
    final parsedAvailable = _normalizedLanguages(value['availableLanguages']);
    final available = <String>{...parsedAvailable};
    if (sourceLanguage.isNotEmpty) available.add(sourceLanguage);
    available.addAll(legacyTargets);
    final targetLanguages = legacyTargets.isNotEmpty
        ? legacyTargets
        : available
              .where((language) => language != sourceLanguage)
              .toList(growable: false);
    final isTranslated = value['isTranslated'] == true;
    final translated =
        value['translated'] == true ||
        isTranslated ||
        targetLanguages.isNotEmpty;
    final rawStatus = value['status']?.toString().trim().toUpperCase() ?? '';

    return ExcursionTranslationInfoVm(
      status: rawStatus.isNotEmpty
          ? rawStatus
          : translated
          ? 'COMPLETED'
          : 'NONE',
      translated: translated,
      sourceLanguage: sourceLanguage,
      currentLanguage: currentLanguage,
      isTranslated: isTranslated,
      availableLanguages: available.toList(growable: false)..sort(),
      pendingLanguages: _normalizedLanguages(value['pendingLanguages']),
      failedLanguages: _normalizedLanguages(value['failedLanguages']),
      targetLanguages: targetLanguages,
      provider: value['provider']?.toString().trim() ?? '',
    );
  }

  ExcursionTranslationNoticeState noticeState(String effectiveAppLanguage) {
    final source = _normalizeLocale(sourceLanguage).split('-').first;
    final target = _normalizeLocale(effectiveAppLanguage).split('-').first;
    if (source.isEmpty || target.isEmpty || source == target) {
      return ExcursionTranslationNoticeState.none;
    }
    final available = availableLanguages
        .map(_normalizeLocale)
        .map((language) => language.split('-').first)
        .contains(target);
    final legacyAvailable = targetLanguages
        .map(_normalizeLocale)
        .map((language) => language.split('-').first)
        .contains(target);
    if (available ||
        legacyAvailable ||
        (isTranslated && currentLanguage == target)) {
      return ExcursionTranslationNoticeState.translated;
    }
    final failed = failedLanguages
        .map(_normalizeLocale)
        .map((language) => language.split('-').first)
        .contains(target);
    if (failed || status == 'FAILED' || status == 'DISABLED') {
      return ExcursionTranslationNoticeState.unavailable;
    }
    final pending = pendingLanguages
        .map(_normalizeLocale)
        .map((language) => language.split('-').first)
        .contains(target);
    if (pending || status == 'PENDING' || status == 'PARTIAL') {
      return ExcursionTranslationNoticeState.pending;
    }
    return ExcursionTranslationNoticeState.none;
  }

  bool shouldShowNotice(String effectiveAppLanguage) {
    return noticeState(effectiveAppLanguage) !=
        ExcursionTranslationNoticeState.none;
  }

  static List<String> _normalizedLanguages(Object? value) {
    final result = <String>{};
    for (final language in ExcursionVm._stringList(value)) {
      final normalized = _normalizeLocale(language).split('-').first;
      if (normalized.isNotEmpty) result.add(normalized);
    }
    return result.toList(growable: false)..sort();
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
    this.translationInfo = ExcursionTranslationInfoVm.none,
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
  final ExcursionTranslationInfoVm translationInfo;

  factory ExcursionOfferVm.fromJson(Map<String, dynamic> json) {
    final includedItemsPayload = ExcursionVm._includedItemsPayload(
      json['includedItems'],
      json['includedItemTranslations'],
    );
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
      includedItems: includedItemsPayload.items,
      includedItemTranslations: includedItemsPayload.translations,
      itinerary: ExcursionVm._itinerary(json['itinerary']),
      translations: ExcursionVm._translations(json),
      translationInfo: ExcursionTranslationInfoVm.fromJson(
        json['translationInfo'],
      ),
    );
  }

  List<String> localizedIncludedItems(String languageCode) {
    return _localizedIncludedItems(
      includedItems,
      includedItemTranslations,
      languageCode,
    );
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

List<String> _localizedIncludedItems(
  List<String> items,
  Map<String, List<String>> translations,
  String languageCode,
) {
  final normalized = _normalizeLocale(languageCode);
  final localized =
      translations[normalized] ?? translations[normalized.split('-').first];
  final result = <String>[];
  for (var index = 0; index < items.length; index++) {
    final item = items[index].trim();
    if (item.isEmpty || ExcursionIncludedItemKey.isDeprecated(item)) continue;
    final localizedItem = localized != null && index < localized.length
        ? localized[index].trim()
        : '';
    result.add(localizedItem.isEmpty ? item : localizedItem);
  }
  return List.unmodifiable(result);
}

String _normalizeLocale(String value) {
  return value.trim().replaceAll('_', '-').toLowerCase();
}
