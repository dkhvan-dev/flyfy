class ActivityListItemVm {
  ActivityListItemVm({
    required this.id,
    required this.title,
    required this.description,
    required this.format,
    required this.status,
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
  });

  final String id;
  final String title;
  final String description;
  final String format;
  final String status;
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

  factory ActivityListItemVm.fromJson(Map<String, dynamic> json) {
    return ActivityListItemVm(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      format: json['format']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      categorySlug: json['categorySlug']?.toString() ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      languageCode: json['languageCode']?.toString() ?? 'ru',
      timezone: json['timezone']?.toString() ?? 'Asia/Almaty',
      startAt: DateTime.tryParse(json['startAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endAt: DateTime.tryParse(json['endAt']?.toString() ?? '') ??
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