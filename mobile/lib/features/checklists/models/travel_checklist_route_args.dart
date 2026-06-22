import '../../../core/network/checklist_api.dart';
import '../../excursions/models/excursion_booking_vm.dart';
import '../../excursions/models/excursion_vm.dart';

class TravelChecklistRouteArgs {
  const TravelChecklistRouteArgs({
    required this.tripId,
    required this.destination,
    required this.startAt,
    required this.endAt,
    this.destinationCountryName,
    this.transportModes = const [],
    this.activitySlugs = const [],
    this.routeStops = const [],
    this.hasChildren = false,
    this.isPreview = false,
  });

  final String tripId;
  final TripChecklistDestinationRequest destination;
  final String? destinationCountryName;
  final DateTime startAt;
  final DateTime endAt;
  final List<String> transportModes;
  final List<String> activitySlugs;
  final List<TravelChecklistRouteStop> routeStops;
  final bool hasChildren;
  final bool isPreview;

  factory TravelChecklistRouteArgs.fromJson(Map<String, dynamic> json) {
    return TravelChecklistRouteArgs(
      tripId: json['tripId']?.toString() ?? '',
      destination: TripChecklistDestinationRequest(
        countryCode: _stringFromMap(json['destination'], 'countryCode'),
        cityName: _stringFromMap(json['destination'], 'cityName'),
        cityId: _nullableStringFromMap(json['destination'], 'cityId'),
      ),
      destinationCountryName: _firstNonBlank([
        _nullableStringFromMap(json['destination'], 'countryName'),
        json['destinationCountryName']?.toString(),
      ]),
      startAt: _dateTimeFromJson(json['startAt']),
      endAt: _dateTimeFromJson(json['endAt']),
      transportModes: _stringListFromJson(json['transportModes']),
      activitySlugs: _stringListFromJson(json['activitySlugs']),
      routeStops: _routeStopsFromJson(json['routeStops']),
      hasChildren: json['hasChildren'] == true,
      isPreview: json['isPreview'] == true,
    );
  }

  factory TravelChecklistRouteArgs.fromQueryParameters(
    Map<String, String> queryParameters,
  ) {
    return TravelChecklistRouteArgs(
      tripId: queryParameters['tripId'] ?? '',
      destination: TripChecklistDestinationRequest(
        countryCode: queryParameters['countryCode'] ?? '',
        cityName: queryParameters['cityName'] ?? '',
        cityId: _blankToNull(queryParameters['cityId']),
      ),
      destinationCountryName: _firstNonBlank([
        queryParameters['countryName'],
        queryParameters['destinationCountryName'],
      ]),
      startAt: _dateTimeFromJson(queryParameters['startAt']),
      endAt: _dateTimeFromJson(queryParameters['endAt']),
      transportModes: _tokensFromQuery(queryParameters['transportModes']),
      activitySlugs: _tokensFromQuery(queryParameters['activitySlugs']),
      hasChildren: queryParameters['hasChildren'] == 'true',
      isPreview: queryParameters['isPreview'] == 'true',
    );
  }

  factory TravelChecklistRouteArgs.sample({DateTime? now}) {
    final baseDate = (now ?? DateTime.now()).toUtc();
    return TravelChecklistRouteArgs(
      tripId: 'sample-tokyo-july',
      destination: const TripChecklistDestinationRequest(
        countryCode: 'JP',
        cityName: 'Tokyo',
      ),
      startAt: DateTime.utc(baseDate.year + 1, 7, 11, 10),
      endAt: DateTime.utc(baseDate.year + 1, 7, 18, 10),
      transportModes: const ['flight'],
      activitySlugs: const ['hiking'],
    );
  }

  factory TravelChecklistRouteArgs.fromExcursionBooking({
    required ExcursionBookingVm booking,
    ExcursionVm? excursion,
  }) {
    final startAt = booking.scheduledFor.toUtc();
    final durationMinutes = _excursionBookingDurationMinutes(
      booking,
      excursion,
    );

    return TravelChecklistRouteArgs(
      tripId: 'excursion_booking:${booking.id.trim()}',
      destination: TripChecklistDestinationRequest(
        countryCode: _firstNonBlank([
          booking.countryCode,
          excursion?.countryCode,
        ]),
        cityName: _firstNonBlank([booking.cityName, excursion?.cityName]),
      ),
      startAt: startAt,
      endAt: startAt.add(Duration(minutes: durationMinutes)),
      transportModes: normalizedTokens(['flight', excursion?.transportMode]),
      activitySlugs: normalizedTokens([
        booking.categorySlug,
        excursion?.routeKind,
        excursion?.routeTheme,
        excursion?.transportMode,
        ...?excursion?.tags,
        excursion?.categorySlug,
      ]),
      routeStops: _routeStopsFromExcursion(
        _bookingExcursionRoute(excursion, booking.offerId),
      ),
      hasChildren: booking.children > 0,
    );
  }

  factory TravelChecklistRouteArgs.fromExcursionPreview({
    required ExcursionVm excursion,
    ExcursionOfferVm? selectedOffer,
    DateTime? now,
  }) {
    final previewExcursion = selectedOffer == null
        ? excursion
        : excursion.withPrimaryOffer(selectedOffer);
    final startAt = _nextPreviewStartAt(now ?? DateTime.now());
    final durationMinutes = _excursionPreviewDurationMinutes(
      previewExcursion,
      selectedOffer,
    );
    final productId = excursion.id.trim();
    final offerId = selectedOffer?.id.trim() ?? '';
    final tripId = [
      'excursion_preview',
      productId.isNotEmpty ? productId : 'unknown',
      if (offerId.isNotEmpty) offerId,
    ].join(':');

    return TravelChecklistRouteArgs(
      tripId: tripId,
      destination: TripChecklistDestinationRequest(
        countryCode: previewExcursion.countryCode ?? '',
        cityName: previewExcursion.cityName ?? '',
        cityId: previewExcursion.departureCityId,
      ),
      startAt: startAt,
      endAt: startAt.add(Duration(minutes: durationMinutes)),
      transportModes: normalizedTokens([
        'flight',
        previewExcursion.transportMode,
      ]),
      activitySlugs: normalizedTokens([
        previewExcursion.categorySlug,
        previewExcursion.routeKind,
        previewExcursion.routeTheme,
        previewExcursion.transportMode,
        ...previewExcursion.tags,
      ]),
      routeStops: _routeStopsFromExcursion(previewExcursion),
      isPreview: true,
    );
  }

  String get normalizedTripId {
    final trimmed = tripId.trim();
    if (trimmed.isNotEmpty) return trimmed;

    final countryCode = destination.countryCode.trim().toLowerCase();
    final cityName = destination.cityName.trim().toLowerCase();
    final destinationKey = [
      countryCode,
      cityName,
    ].where((part) => part.isNotEmpty).join(':');
    final fallbackDestination = destinationKey.isNotEmpty
        ? destinationKey
        : 'unknown';
    return 'trip:$fallbackDestination:${startAt.toUtc().millisecondsSinceEpoch}';
  }

  String get primaryTransportMode {
    final modes = normalizedTokens(transportModes);
    if (modes.isNotEmpty) return modes.first;
    return 'flight';
  }

  Map<String, Object?> toJson() {
    return {
      'tripId': normalizedTripId,
      'destination': destination.toJson(),
      if ((destinationCountryName ?? '').trim().isNotEmpty)
        'destinationCountryName': destinationCountryName!.trim(),
      'startAt': startAt.toUtc().toIso8601String(),
      'endAt': safeEndAt.toUtc().toIso8601String(),
      'transportModes': normalizedTokens(transportModes),
      'activitySlugs': normalizedTokens(activitySlugs),
      if (routeStops.isNotEmpty)
        'routeStops': routeStops
            .map((stop) => stop.toJson())
            .toList(growable: false),
      'hasChildren': hasChildren,
      if (isPreview) 'isPreview': true,
    };
  }

  TripChecklistPreviewRequest toRequest({required String preferredLanguage}) {
    return TripChecklistPreviewRequest(
      tripId: normalizedTripId,
      destination: destination,
      startAt: startAt.toUtc(),
      endAt: safeEndAt,
      transportModes: normalizedTokens(transportModes),
      activitySlugs: normalizedTokens(activitySlugs),
      hasChildren: hasChildren,
      preferredLanguage: preferredLanguage.trim().isNotEmpty
          ? preferredLanguage.trim()
          : 'ru',
    );
  }

  DateTime get safeEndAt {
    final utcStartAt = startAt.toUtc();
    final utcEndAt = endAt.toUtc();
    return utcEndAt.isAfter(utcStartAt)
        ? utcEndAt
        : utcStartAt.add(const Duration(hours: 2));
  }

  static List<String> normalizedTokens(
    Iterable<String?> values, {
    int maxItems = 8,
  }) {
    final tokens = <String>[];
    final seen = <String>{};

    for (final rawValue in values) {
      final token = (rawValue ?? '').trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '_',
      );
      if (token.isEmpty || !seen.add(token)) continue;

      tokens.add(token);
      if (tokens.length >= maxItems) break;
    }

    return List.unmodifiable(tokens);
  }

  static int _excursionBookingDurationMinutes(
    ExcursionBookingVm booking,
    ExcursionVm? excursion,
  ) {
    final offerId = booking.offerId.trim();
    if (excursion != null && offerId.isNotEmpty) {
      for (final offer in excursion.offers) {
        if (offer.id == offerId && offer.durationMinutes > 0) {
          return offer.durationMinutes;
        }
      }
    }
    if ((excursion?.durationMinutes ?? 0) > 0) {
      return excursion!.durationMinutes;
    }
    return 240;
  }

  static int _excursionPreviewDurationMinutes(
    ExcursionVm excursion,
    ExcursionOfferVm? selectedOffer,
  ) {
    final offerDurationMinutes = selectedOffer?.durationMinutes ?? 0;
    if (offerDurationMinutes > 0) return offerDurationMinutes;
    if (excursion.durationMinutes > 0) return excursion.durationMinutes;
    return 240;
  }

  static DateTime _nextPreviewStartAt(DateTime now) {
    final utcNow = now.toUtc();
    return DateTime.utc(utcNow.year, utcNow.month, utcNow.day + 1, 10);
  }

  static String _firstNonBlank(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = (value ?? '').trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static DateTime _dateTimeFromJson(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed?.toUtc() ?? DateTime.now().toUtc();
  }

  static List<String> _stringListFromJson(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _tokensFromQuery(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String _stringFromMap(Object? value, String key) {
    if (value is! Map) return '';
    return value[key]?.toString() ?? '';
  }

  static String? _nullableStringFromMap(Object? value, String key) {
    if (value is! Map) return null;
    final stringValue = value[key]?.toString().trim();
    return stringValue == null || stringValue.isEmpty ? null : stringValue;
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class TravelChecklistRouteStop {
  const TravelChecklistRouteStop({
    required this.latitude,
    required this.longitude,
    this.name,
    this.sourceId,
  });

  final double latitude;
  final double longitude;
  final String? name;
  final String? sourceId;

  factory TravelChecklistRouteStop.fromJson(Map<String, dynamic> json) {
    return TravelChecklistRouteStop(
      latitude: _doubleFromMap(json, 'latitude'),
      longitude: _doubleFromMap(json, 'longitude'),
      name: _blankToNullValue(json['name']?.toString()),
      sourceId: _blankToNullValue(json['sourceId']?.toString()),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if ((name ?? '').trim().isNotEmpty) 'name': name!.trim(),
      if ((sourceId ?? '').trim().isNotEmpty) 'sourceId': sourceId!.trim(),
    };
  }
}

ExcursionVm? _bookingExcursionRoute(ExcursionVm? excursion, String offerId) {
  if (excursion == null) return null;
  final normalizedOfferId = offerId.trim();
  if (normalizedOfferId.isEmpty) return excursion;

  for (final offer in excursion.offers) {
    if (offer.id == normalizedOfferId && offer.itinerary.isNotEmpty) {
      return excursion.withPrimaryOffer(offer);
    }
  }
  return excursion;
}

List<TravelChecklistRouteStop> _routeStopsFromExcursion(
  ExcursionVm? excursion,
) {
  if (excursion == null) return const [];

  final stops = <TravelChecklistRouteStop>[];
  for (final item in excursion.itinerary) {
    final latitude = item.latitude;
    final longitude = item.longitude;
    if (latitude == null ||
        longitude == null ||
        !_isValidCoordinate(latitude, longitude)) {
      continue;
    }

    stops.add(
      TravelChecklistRouteStop(
        latitude: latitude,
        longitude: longitude,
        name: _firstNonBlankValue([item.placeName, item.title]),
        sourceId: _firstNonBlankValue([item.placeId, item.id]),
      ),
    );
  }
  return List.unmodifiable(stops);
}

List<TravelChecklistRouteStop> _routeStopsFromJson(Object? value) {
  if (value is! List) return const [];

  final stops = <TravelChecklistRouteStop>[];
  for (final item in value) {
    if (item is! Map) continue;
    final stop = TravelChecklistRouteStop.fromJson(
      item.cast<String, dynamic>(),
    );
    if (!_isValidCoordinate(stop.latitude, stop.longitude)) continue;
    stops.add(stop);
  }
  return List.unmodifiable(stops);
}

bool _isValidCoordinate(double latitude, double longitude) {
  return latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

double _doubleFromMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

String? _firstNonBlankValue(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

String? _blankToNullValue(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
