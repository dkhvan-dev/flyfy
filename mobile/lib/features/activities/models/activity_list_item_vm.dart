import '../../../shared/formatters/app_money_formatter.dart';

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
    this.subcategorySlug,
    required this.languageCode,
    required this.timezone,
    required this.startAt,
    required this.endAt,
    required this.capacityType,
    required this.priceType,
    required this.requiresProfileCompletion,
    required this.requiresAttendanceConfirmation,
    this.allowsParticipantInvites = false,
    this.tags = const [],
    this.cityName,
    this.cityId,
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
    this.hostActivityRating = 5.0,
    this.cancellationReason,
    this.cancelledAt,
    this.startedAt,
    this.completedAt,
    this.completionReason,
    this.publishedAt,
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
  final String? subcategorySlug;
  final List<String> tags;
  final String languageCode;
  final String timezone;
  final DateTime startAt;
  final DateTime endAt;
  final String capacityType;
  final String priceType;
  final bool requiresProfileCompletion;
  final bool requiresAttendanceConfirmation;
  final bool allowsParticipantInvites;

  final String? cityName;
  final String? cityId;
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
  final double hostActivityRating;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? completionReason;
  final DateTime? publishedAt;

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
      subcategorySlug: _nullableString(
        json['subcategorySlug'] ?? json['subCategorySlug'],
      ),
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
      allowsParticipantInvites: json['allowsParticipantInvites'] == true,
      cityName: json['cityName']?.toString(),
      cityId: json['cityId']?.toString(),
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
      hostActivityRating: _ratingOrDefault(json['hostActivityRating']),
      cancellationReason: json['cancellationReason']?.toString(),
      cancelledAt: DateTime.tryParse(json['cancelledAt']?.toString() ?? ''),
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
      completionReason: json['completionReason']?.toString(),
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
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

  bool get isCompletedEarly =>
      status.toUpperCase() == 'COMPLETED' &&
      completedAt != null &&
      completedAt!.isBefore(endAt);

  String? get resolvedCurrencyCode =>
      resolveAppCurrencyCode(currency: currency, countryCode: countryCode);

  String get priceLabel => formattedPriceLabel('ru');

  String formattedPriceLabel(String localeName) {
    if (isFree) return 'FREE';
    if (priceAmount == null) return priceType;
    final resolvedCurrency = resolvedCurrencyCode;
    if (resolvedCurrency == null) {
      return priceAmount! % 1 == 0
          ? priceAmount!.toStringAsFixed(0)
          : priceAmount!.toStringAsFixed(2);
    }
    return formatAppMoney(
      amount: priceAmount!,
      currency: resolvedCurrency,
      localeName: localeName,
      useListCurrencyFormat: true,
    );
  }
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

double _ratingOrDefault(dynamic value) {
  const defaultRating = 5.0;
  if (value is num) {
    final rating = value.toDouble();
    return rating > 0 ? rating : defaultRating;
  }
  final rating = double.tryParse(value?.toString() ?? '');
  return rating != null && rating > 0 ? rating : defaultRating;
}
