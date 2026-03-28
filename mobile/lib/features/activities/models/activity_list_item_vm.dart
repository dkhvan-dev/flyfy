class ActivityListItemVm {
  ActivityListItemVm({
    required this.id,
    required this.hostUserId,
    required this.title,
    required this.description,
    required this.format,
    required this.status,
    required this.moderationStatus,
    required this.visibility,
    required this.joinMode,
    required this.categorySlug,
    required this.languageCode,
    required this.timezone,
    required this.startAt,
    required this.endAt,
    required this.capacityType,
    required this.priceType,
    required this.requiresProfileCompletion,
    required this.requiresAttendanceConfirmation,
    this.tags = const [],
    this.cityName,
    this.countryCode,
    this.priceAmount,
    this.currency,
    this.registrationDeadline,
    this.minParticipants,
    this.maxParticipants,
    this.addressText,
    this.meetingUrl,
    this.mapUrl,
    this.latitude,
    this.longitude,
    this.coverFileId,
    this.coverImageUrl,
  });

  final String id;
  final String hostUserId;
  final String title;
  final String description;
  final String format;
  final String status;
  final String moderationStatus;
  final String visibility;
  final String joinMode;
  final String categorySlug;
  final List<String> tags;
  final String languageCode;
  final String timezone;
  final DateTime startAt;
  final DateTime endAt;
  final String capacityType;
  final String priceType;
  final bool requiresProfileCompletion;
  final bool requiresAttendanceConfirmation;

  final String? cityName;
  final String? countryCode;
  final double? priceAmount;
  final String? currency;
  final DateTime? registrationDeadline;
  final int? minParticipants;
  final int? maxParticipants;
  final String? addressText;
  final String? meetingUrl;
  final String? mapUrl;
  final double? latitude;
  final double? longitude;
  final String? coverFileId;
  final String? coverImageUrl;

  factory ActivityListItemVm.fromJson(Map<String, dynamic> json) {
    return ActivityListItemVm(
      id: json['id']?.toString() ?? '',
      hostUserId: json['hostUserId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      format: json['format']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      moderationStatus: json['moderationStatus']?.toString() ?? '',
      visibility: json['visibility']?.toString() ?? '',
      joinMode: json['joinMode']?.toString() ?? '',
      categorySlug: json['categorySlug']?.toString() ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      languageCode: json['languageCode']?.toString() ?? 'ru',
      timezone: json['timezone']?.toString() ?? 'Asia/Almaty',
      startAt:
          DateTime.tryParse(json['startAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endAt:
          DateTime.tryParse(json['endAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      capacityType: json['capacityType']?.toString() ?? '',
      priceType: json['priceType']?.toString() ?? 'FREE',
      requiresProfileCompletion: json['requiresProfileCompletion'] == true,
      requiresAttendanceConfirmation:
          json['requiresAttendanceConfirmation'] == true,
      cityName: json['cityName']?.toString(),
      countryCode: json['countryCode']?.toString(),
      priceAmount: (json['priceAmount'] as num?)?.toDouble(),
      currency: json['currency']?.toString(),
      registrationDeadline: DateTime.tryParse(
        json['registrationDeadline']?.toString() ?? '',
      ),
      minParticipants: (json['minParticipants'] as num?)?.toInt(),
      maxParticipants: (json['maxParticipants'] as num?)?.toInt(),
      addressText: json['addressText']?.toString(),
      meetingUrl: json['meetingUrl']?.toString(),
      mapUrl: json['mapUrl']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      coverFileId: json['coverFileId']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
    );
  }

  String get shortLocation {
    final city = (cityName ?? '').trim();
    final country = (countryCode ?? '').trim();

    if (city.isNotEmpty && country.isNotEmpty) {
      return '$city, $country';
    }
    if (city.isNotEmpty) return city;
    if (country.isNotEmpty) return country;
    return '';
  }

  bool get isFree => priceType.toUpperCase() == 'FREE';

  String get priceLabel {
    if (isFree) return 'FREE';
    if (priceAmount == null) return priceType;
    final amount = priceAmount! % 1 == 0
        ? priceAmount!.toStringAsFixed(0)
        : priceAmount!.toStringAsFixed(2);
    if ((currency ?? '').trim().isEmpty) return amount;
    return '$amount $currency';
  }
}
