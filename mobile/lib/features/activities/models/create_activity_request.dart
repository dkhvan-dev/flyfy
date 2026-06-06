import '../../../core/time/app_time.dart';

class CreateActivityRequest {
  CreateActivityRequest({
    required this.title,
    required this.description,
    required this.format,
    required this.visibility,
    required this.categorySlug,
    this.subcategorySlug,
    required this.languageCode,
    required this.timezone,
    required this.startAt,
    required this.endAt,
    required this.capacityType,
    required this.priceType,
    this.allowsParticipantInvites = false,
    this.tags = const [],
    this.minParticipants,
    this.maxParticipants,
    this.priceAmount,
    this.currency,
    this.countryCode,
    this.cityId,
    this.cityName,
    this.addressText,
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.meetingUrl,
    this.authorCountryCode,
    this.authorCityId,
    this.authorCityName,
    this.visibilityPassword,
    this.coverFileId,
  });

  final String title;
  final String description;
  final String format;
  final String visibility;
  final String categorySlug;
  final String? subcategorySlug;
  final List<String> tags;
  final String languageCode;
  final String timezone;
  final DateTime startAt;
  final DateTime endAt;
  final String capacityType;
  final int? minParticipants;
  final int? maxParticipants;
  final String priceType;
  final bool allowsParticipantInvites;
  final double? priceAmount;
  final String? currency;
  final String? countryCode;
  final String? cityId;
  final String? cityName;
  final String? addressText;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;
  final String? meetingUrl;
  final String? authorCountryCode;
  final String? authorCityId;
  final String? authorCityName;
  final String? visibilityPassword;
  final String? coverFileId;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'format': format,
      'visibility': visibility,
      'categorySlug': categorySlug,
      if (subcategorySlug != null && subcategorySlug!.trim().isNotEmpty)
        'subcategorySlug': subcategorySlug,
      'tags': tags,
      'languageCode': languageCode,
      'timezone': timezone,
      'startAt': eventWallClockToUtc(startAt, timezone).toIso8601String(),
      'endAt': eventWallClockToUtc(endAt, timezone).toIso8601String(),
      'capacityType': capacityType,
      'priceType': priceType,
      'allowsParticipantInvites': allowsParticipantInvites,
      if (minParticipants != null) 'minParticipants': minParticipants,
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
      if (priceAmount != null) 'priceAmount': priceAmount,
      if (currency != null && currency!.trim().isNotEmpty) 'currency': currency,
      if (countryCode != null && countryCode!.trim().isNotEmpty)
        'countryCode': countryCode,
      if (cityId != null && cityId!.trim().isNotEmpty) 'cityId': cityId,
      if (cityName != null && cityName!.trim().isNotEmpty) 'cityName': cityName,
      if (addressText != null && addressText!.trim().isNotEmpty)
        'addressText': addressText,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (mapUrl != null && mapUrl!.trim().isNotEmpty) 'mapUrl': mapUrl,
      if (meetingUrl != null && meetingUrl!.trim().isNotEmpty)
        'meetingUrl': meetingUrl,
      if (authorCountryCode != null && authorCountryCode!.trim().isNotEmpty)
        'authorCountryCode': authorCountryCode,
      if (authorCityId != null && authorCityId!.trim().isNotEmpty)
        'authorCityId': authorCityId,
      if (authorCityName != null && authorCityName!.trim().isNotEmpty)
        'authorCityName': authorCityName,
      if (visibilityPassword != null && visibilityPassword!.trim().isNotEmpty)
        'visibilityPassword': visibilityPassword,
      if (coverFileId != null && coverFileId!.trim().isNotEmpty)
        'coverFileId': coverFileId,
    };
  }
}
