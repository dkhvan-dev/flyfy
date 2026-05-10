class TourVm {
  const TourVm({
    required this.id,
    required this.title,
    required this.summary,
    required this.status,
    required this.visibility,
    required this.priceAmount,
    required this.currency,
    this.landmarkName,
    this.categorySlug,
    this.durationMinutes = 0,
    this.maxGroupSize = 0,
    this.languageCodes = const [],
    this.tags = const [],
    this.cityName,
    this.coverFileId,
  });

  final String id;
  final String? landmarkName;
  final String title;
  final String summary;
  final String? categorySlug;
  final int durationMinutes;
  final int maxGroupSize;
  final List<String> languageCodes;
  final List<String> tags;
  final String status;
  final String visibility;
  final double priceAmount;
  final String currency;
  final String? cityName;
  final String? coverFileId;

  factory TourVm.fromJson(Map<String, dynamic> json) {
    return TourVm(
      id: (json['id'] as String?) ?? '',
      landmarkName: json['landmarkName'] as String?,
      title: (json['title'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      categorySlug: json['categorySlug'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      maxGroupSize: (json['maxGroupSize'] as num?)?.toInt() ?? 0,
      languageCodes: _stringList(json['languageCodes']),
      tags: _stringList(json['tags']),
      status: (json['status'] as String?) ?? 'DRAFT',
      visibility: (json['visibility'] as String?) ?? 'PUBLIC',
      priceAmount: (json['priceAmount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? 'KZT',
      cityName: json['cityName'] as String?,
      coverFileId: json['coverFileId'] as String?,
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
}
