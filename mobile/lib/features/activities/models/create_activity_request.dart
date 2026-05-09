class CreateActivityRequest {
  CreateActivityRequest({
    required this.title,
    required this.description,
    required this.format,
    required this.visibility,
    required this.categorySlug,
    required this.languageCode,
    required this.timezone,
    required this.startAt,
    required this.endAt,
    required this.capacityType,
    required this.priceType,
    this.tags = const [],
    this.minParticipants,
    this.maxParticipants,
    this.priceAmount,
    this.currency,
    this.countryCode,
    this.cityName,
    this.addressText,
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.meetingUrl,
    this.visibilityPassword,
    this.coverFileId,
  });

  final String title;
  final String description;
  final String format;
  final String visibility;
  final String categorySlug;
  final List<String> tags;
  final String languageCode;
  final String timezone;
  final DateTime startAt;
  final DateTime endAt;
  final String capacityType;
  final int? minParticipants;
  final int? maxParticipants;
  final String priceType;
  final double? priceAmount;
  final String? currency;
  final String? countryCode;
  final String? cityName;
  final String? addressText;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;
  final String? meetingUrl;
  final String? visibilityPassword;
  final String? coverFileId;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'format': format,
      'visibility': visibility,
      'categorySlug': categorySlug,
      'tags': tags,
      'languageCode': languageCode,
      'timezone': timezone,
      'startAt': startAt.toUtc().toIso8601String(),
      'endAt': endAt.toUtc().toIso8601String(),
      'capacityType': capacityType,
      'priceType': priceType,
      if (minParticipants != null) 'minParticipants': minParticipants,
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
      if (priceAmount != null) 'priceAmount': priceAmount,
      if (currency != null && currency!.trim().isNotEmpty) 'currency': currency,
      if (countryCode != null && countryCode!.trim().isNotEmpty)
        'countryCode': countryCode,
      if (cityName != null && cityName!.trim().isNotEmpty) 'cityName': cityName,
      if (addressText != null && addressText!.trim().isNotEmpty)
        'addressText': addressText,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (mapUrl != null && mapUrl!.trim().isNotEmpty) 'mapUrl': mapUrl,
      if (meetingUrl != null && meetingUrl!.trim().isNotEmpty)
        'meetingUrl': meetingUrl,
      if (visibilityPassword != null && visibilityPassword!.trim().isNotEmpty)
        'visibilityPassword': visibilityPassword,
      if (coverFileId != null && coverFileId!.trim().isNotEmpty)
        'coverFileId': coverFileId,
    };
  }
}
