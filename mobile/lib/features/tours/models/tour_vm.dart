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
    this.itinerary = const [],
  });

  final String id;
  final String? guideProfileId;
  final String? guideUserId;
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
  final List<TourItineraryItemVm> itinerary;

  factory TourVm.fromJson(Map<String, dynamic> json) {
    return TourVm(
      id: (json['id'] as String?) ?? '',
      guideProfileId: json['guideProfileId'] as String?,
      guideUserId: json['guideUserId'] as String?,
      landmarkName: json['landmarkName'] as String?,
      title: (json['title'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      categorySlug: json['categorySlug'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      maxGroupSize: (json['maxGroupSize'] as num?)?.toInt() ?? 0,
      languageCodes: _stringList(json['languageCodes']),
      tags: _stringList(json['tags']),
      status: (json['status'] as String?) ?? 'DRAFT',
      visibility: (json['visibility'] as String?) ?? 'PUBLIC',
      priceAmount: (json['priceAmount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? 'KZT',
      countryCode: json['countryCode'] as String?,
      cityName: json['cityName'] as String?,
      meetingPoint: (json['meetingPoint'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mapUrl: json['mapUrl'] as String?,
      coverFileId: json['coverFileId'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      includedItems: _stringList(json['includedItems']),
      itinerary: _itinerary(json['itinerary']),
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
}

class TourItineraryItemVm {
  const TourItineraryItemVm({
    required this.id,
    required this.sortOrder,
    required this.startOffsetMinutes,
    required this.title,
    required this.description,
    this.durationMinutes,
  });

  final String id;
  final int sortOrder;
  final int startOffsetMinutes;
  final int? durationMinutes;
  final String title;
  final String description;

  factory TourItineraryItemVm.fromJson(Map<String, dynamic> json) {
    return TourItineraryItemVm(
      id: (json['id'] as String?) ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      startOffsetMinutes: (json['startOffsetMinutes'] as num?)?.toInt() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
    );
  }
}
