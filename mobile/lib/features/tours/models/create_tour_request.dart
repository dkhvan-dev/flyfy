class CreateTourRequest {
  const CreateTourRequest({
    required this.title,
    required this.summary,
    required this.description,
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
    this.tags = const [],
    this.visibility = 'PUBLIC',
    this.countryCode,
    this.cityName,
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.includedItems = const [],
    this.coverFileId,
  });

  final String? landmarkId;
  final String? landmarkName;
  final String title;
  final String summary;
  final String description;
  final String categorySlug;
  final List<String> tags;
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
  final List<CreateTourItineraryItemRequest> itinerary;
  final String? coverFileId;

  Map<String, dynamic> toJson() {
    final normalizedTags = _cleanList(tags);
    final normalizedLanguages = _cleanList(
      languageCodes.map((value) => value.toLowerCase()).toList(),
    );
    final normalizedIncludedItems = _cleanList(includedItems);

    return {
      if (_isPresent(landmarkId)) 'landmarkId': landmarkId!.trim(),
      if (_isPresent(landmarkName)) 'landmarkName': landmarkName!.trim(),
      'title': title.trim(),
      'summary': summary.trim(),
      'description': description.trim(),
      'categorySlug': categorySlug.trim().toLowerCase(),
      if (normalizedTags.isNotEmpty) 'tags': normalizedTags,
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
      'itinerary':
          itinerary.map((item) => item.toJson()).toList(growable: false),
      if (_isPresent(coverFileId)) 'coverFileId': coverFileId!.trim(),
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
}

class CreateTourItineraryItemRequest {
  const CreateTourItineraryItemRequest({
    required this.startOffsetMinutes,
    required this.title,
    required this.description,
    this.durationMinutes,
  });

  final int startOffsetMinutes;
  final int? durationMinutes;
  final String title;
  final String description;

  Map<String, dynamic> toJson() {
    return {
      'startOffsetMinutes': startOffsetMinutes,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      'title': title.trim(),
      'description': description.trim(),
    };
  }
}
