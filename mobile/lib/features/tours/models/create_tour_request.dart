class CreateTourRequest {
  const CreateTourRequest({
    required this.categorySlug,
    required this.durationMinutes,
    required this.maxGroupSize,
    required this.languageCodes,
    required this.meetingPoint,
    required this.priceAmount,
    required this.currency,
    required this.itinerary,
    this.landmarkId,
    this.landmarkName,
    this.visibility = 'PUBLIC',
    this.countryCode,
    this.cityName,
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.includedItems = const [],
    this.includedItemTranslations = const {},
    this.coverFileId,
    this.productCoverFileId,
    this.productTranslations = const {},
  });

  final String? landmarkId;
  final String? landmarkName;
  final String categorySlug;
  final Map<String, CreateTourLocalizedCopyRequest> productTranslations;
  final int durationMinutes;
  final int maxGroupSize;
  final List<String> languageCodes;
  final String visibility;
  final String meetingPoint;
  final String? countryCode;
  final String? cityName;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;
  final double priceAmount;
  final String currency;
  final List<String> includedItems;
  final Map<String, List<String>> includedItemTranslations;
  final List<CreateTourItineraryItemRequest> itinerary;
  final String? coverFileId;
  final String? productCoverFileId;

  Map<String, dynamic> toJson() {
    final normalizedLanguages = _cleanList(
      languageCodes.map((value) => value.toLowerCase()).toList(),
    );
    final normalizedIncludedItems = _cleanList(includedItems);
    final normalizedIncludedItemTranslations = _cleanIncludedItemTranslations(
      includedItemTranslations,
      normalizedIncludedItems.length,
    );
    final normalizedProductTranslations = _cleanTranslations(
      productTranslations,
    );

    return {
      if (_isPresent(landmarkId)) 'landmarkId': landmarkId!.trim(),
      if (_isPresent(landmarkName)) 'landmarkName': landmarkName!.trim(),
      'categorySlug': categorySlug.trim().toLowerCase(),
      if (normalizedProductTranslations.isNotEmpty)
        'productTranslations': normalizedProductTranslations,
      'durationMinutes': durationMinutes,
      'maxGroupSize': maxGroupSize,
      'languageCodes': normalizedLanguages,
      'visibility':
          _isPresent(visibility) ? visibility.trim().toUpperCase() : 'PUBLIC',
      'meetingPoint': meetingPoint.trim(),
      if (_isPresent(countryCode)) 'countryCode': countryCode!.trim(),
      if (_isPresent(cityName)) 'cityName': cityName!.trim(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (_isPresent(mapUrl)) 'mapUrl': mapUrl!.trim(),
      'priceAmount': priceAmount,
      'currency': currency.trim().toUpperCase(),
      if (normalizedIncludedItems.isNotEmpty)
        'includedItems': normalizedIncludedItems,
      if (normalizedIncludedItemTranslations.isNotEmpty)
        'includedItemTranslations': normalizedIncludedItemTranslations,
      'itinerary':
          itinerary.map((item) => item.toJson()).toList(growable: false),
      if (_isPresent(coverFileId)) 'coverFileId': coverFileId!.trim(),
      if (_isPresent(productCoverFileId))
        'productCoverFileId': productCoverFileId!.trim(),
    };
  }

  static bool _isPresent(String? value) =>
      value != null && value.trim().isNotEmpty;

  static List<String> _cleanList(List<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty || !seen.add(normalized.toLowerCase())) {
        continue;
      }
      result.add(normalized);
    }
    return result;
  }

  static Map<String, Map<String, dynamic>> _cleanTranslations(
    Map<String, CreateTourLocalizedCopyRequest> values,
  ) {
    final result = <String, Map<String, dynamic>>{};
    values.forEach((locale, copy) {
      final normalizedLocale = locale.trim().toLowerCase().replaceAll('_', '-');
      final normalizedCopy = copy.toJson();
      if (normalizedLocale.isEmpty || normalizedCopy.isEmpty) {
        return;
      }
      result[normalizedLocale] = normalizedCopy;
    });
    return result;
  }

  static Map<String, List<String>> _cleanIncludedItemTranslations(
    Map<String, List<String>> values,
    int itemCount,
  ) {
    if (itemCount <= 0 || values.isEmpty) return const {};

    final result = <String, List<String>>{};
    values.forEach((locale, rawValues) {
      final normalizedLocale = locale.trim().toLowerCase().replaceAll('_', '-');
      if (normalizedLocale.isEmpty) return;

      final localizedValues = List<String>.generate(itemCount, (index) {
        if (index >= rawValues.length) return '';
        return rawValues[index].trim();
      }, growable: false);
      if (localizedValues.every((value) => value.isEmpty)) return;

      result[normalizedLocale] = localizedValues;
    });
    return result;
  }
}

class CreateTourLocalizedCopyRequest {
  const CreateTourLocalizedCopyRequest({
    this.title,
    this.summary,
    this.description,
  });

  final String? title;
  final String? summary;
  final String? description;

  Map<String, dynamic> toJson() {
    return {
      if (CreateTourRequest._isPresent(title)) 'title': title!.trim(),
      if (CreateTourRequest._isPresent(summary)) 'summary': summary!.trim(),
      if (CreateTourRequest._isPresent(description))
        'description': description!.trim(),
    };
  }
}

class CreateTourItineraryItemRequest {
  const CreateTourItineraryItemRequest({
    required this.startOffsetMinutes,
    required this.title,
    required this.description,
    this.durationMinutes,
    this.translations = const {},
  });

  final int startOffsetMinutes;
  final int? durationMinutes;
  final String title;
  final String description;
  final Map<String, CreateTourItineraryLocalizedCopyRequest> translations;

  Map<String, dynamic> toJson() {
    final normalizedTranslations = _cleanItineraryTranslations(translations);
    return {
      'startOffsetMinutes': startOffsetMinutes,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      'title': title.trim(),
      'description': description.trim(),
      if (normalizedTranslations.isNotEmpty)
        'translations': normalizedTranslations,
    };
  }

  static Map<String, Map<String, dynamic>> _cleanItineraryTranslations(
    Map<String, CreateTourItineraryLocalizedCopyRequest> values,
  ) {
    final result = <String, Map<String, dynamic>>{};
    values.forEach((locale, copy) {
      final normalizedLocale = locale.trim().toLowerCase().replaceAll('_', '-');
      final normalizedCopy = copy.toJson();
      if (normalizedLocale.isEmpty || normalizedCopy.isEmpty) {
        return;
      }
      result[normalizedLocale] = normalizedCopy;
    });
    return result;
  }
}

class CreateTourItineraryLocalizedCopyRequest {
  const CreateTourItineraryLocalizedCopyRequest({
    this.title,
    this.description,
  });

  final String? title;
  final String? description;

  Map<String, dynamic> toJson() {
    return {
      if (CreateTourRequest._isPresent(title)) 'title': title!.trim(),
      if (CreateTourRequest._isPresent(description))
        'description': description!.trim(),
    };
  }
}
