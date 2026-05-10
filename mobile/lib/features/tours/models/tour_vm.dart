class TourVm {
  const TourVm({
    required this.id,
    required this.title,
    required this.summary,
    required this.status,
    required this.visibility,
    required this.priceAmount,
    required this.currency,
    this.cityName,
    this.coverFileId,
  });

  final String id;
  final String title;
  final String summary;
  final String status;
  final String visibility;
  final double priceAmount;
  final String currency;
  final String? cityName;
  final String? coverFileId;

  factory TourVm.fromJson(Map<String, dynamic> json) {
    return TourVm(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'DRAFT',
      visibility: (json['visibility'] as String?) ?? 'PUBLIC',
      priceAmount: (json['priceAmount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? 'KZT',
      cityName: json['cityName'] as String?,
      coverFileId: json['coverFileId'] as String?,
    );
  }
}
