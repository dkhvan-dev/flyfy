class UpdateActivityRequest {
  UpdateActivityRequest({
    this.title,
    this.description,
    this.visibility,
    this.categorySlug,
    this.subcategorySlug,
    this.hasSubcategorySlug = false,
    this.tags,
    this.languageCode,
    this.timezone,
    this.startAt,
    this.endAt,
    this.capacityType,
    this.minParticipants,
    this.hasMinParticipants = false,
    this.maxParticipants,
    this.hasMaxParticipants = false,
    this.priceType,
    this.allowsParticipantInvites,
    this.priceAmount,
    this.hasPriceAmount = false,
    this.currency,
    this.hasCurrency = false,
    this.countryCode,
    this.hasCountryCode = false,
    this.cityId,
    this.hasCityId = false,
    this.cityName,
    this.hasCityName = false,
    this.addressText,
    this.hasAddressText = false,
    this.latitude,
    this.hasLatitude = false,
    this.longitude,
    this.hasLongitude = false,
    this.mapUrl,
    this.hasMapUrl = false,
    this.meetingUrl,
    this.hasMeetingUrl = false,
    this.visibilityPassword,
    this.hasVisibilityPassword = false,
    this.coverFileId,
    this.hasCoverFileId = false,
  });

  final String? title;
  final String? description;
  final String? visibility;
  final String? categorySlug;
  final String? subcategorySlug;
  final bool hasSubcategorySlug;
  final List<String>? tags;
  final String? languageCode;
  final String? timezone;

  final DateTime? startAt;
  final DateTime? endAt;

  final String? capacityType;
  final int? minParticipants;
  final bool hasMinParticipants;
  final int? maxParticipants;
  final bool hasMaxParticipants;

  final String? priceType;
  final bool? allowsParticipantInvites;
  final double? priceAmount;
  final bool hasPriceAmount;
  final String? currency;
  final bool hasCurrency;

  final String? countryCode;
  final bool hasCountryCode;
  final String? cityId;
  final bool hasCityId;
  final String? cityName;
  final bool hasCityName;
  final String? addressText;
  final bool hasAddressText;
  final double? latitude;
  final bool hasLatitude;
  final double? longitude;
  final bool hasLongitude;
  final String? mapUrl;
  final bool hasMapUrl;
  final String? meetingUrl;
  final bool hasMeetingUrl;
  final String? visibilityPassword;
  final bool hasVisibilityPassword;
  final String? coverFileId;
  final bool hasCoverFileId;

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (visibility != null) 'visibility': visibility,
      if (categorySlug != null) 'categorySlug': categorySlug,
      if (hasSubcategorySlug) 'hasSubcategorySlug': true,
      if (subcategorySlug != null) 'subcategorySlug': subcategorySlug,
      if (tags != null) ...{'tags': tags, 'hasTags': true},
      if (languageCode != null) 'languageCode': languageCode,
      if (timezone != null) 'timezone': timezone,
      if (startAt != null) 'startAt': startAt!.toUtc().toIso8601String(),
      if (endAt != null) 'endAt': endAt!.toUtc().toIso8601String(),
      if (capacityType != null) 'capacityType': capacityType,
      if (hasMinParticipants) 'hasMinParticipants': true,
      if (minParticipants != null) 'minParticipants': minParticipants,
      if (hasMaxParticipants) 'hasMaxParticipants': true,
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
      if (priceType != null) 'priceType': priceType,
      if (allowsParticipantInvites != null)
        'allowsParticipantInvites': allowsParticipantInvites,
      if (hasPriceAmount) 'hasPriceAmount': true,
      if (priceAmount != null) 'priceAmount': priceAmount,
      if (hasCurrency) 'hasCurrency': true,
      if (currency != null) 'currency': currency,
      if (hasCountryCode) 'hasCountryCode': true,
      if (countryCode != null) 'countryCode': countryCode,
      if (hasCityId) 'hasCityId': true,
      if (cityId != null) 'cityId': cityId,
      if (hasCityName) 'hasCityName': true,
      if (cityName != null) 'cityName': cityName,
      if (hasAddressText) 'hasAddressText': true,
      if (addressText != null) 'addressText': addressText,
      if (hasLatitude) 'hasLatitude': true,
      if (latitude != null) 'latitude': latitude,
      if (hasLongitude) 'hasLongitude': true,
      if (longitude != null) 'longitude': longitude,
      if (hasMapUrl) 'hasMapUrl': true,
      if (mapUrl != null) 'mapUrl': mapUrl,
      if (hasMeetingUrl) 'hasMeetingUrl': true,
      if (meetingUrl != null) 'meetingUrl': meetingUrl,
      if (hasVisibilityPassword) 'hasVisibilityPassword': true,
      if (visibilityPassword != null) 'visibilityPassword': visibilityPassword,
      if (hasCoverFileId) 'hasCoverFileId': true,
      if (coverFileId != null) 'coverFileId': coverFileId,
    };
  }
}
