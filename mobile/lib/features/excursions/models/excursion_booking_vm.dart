enum MyExcursionsTab { booked, visited }

enum MyExcursionBookingSortMode { date, price }

class ExcursionBookingVm {
  const ExcursionBookingVm({
    required this.id,
    required this.productId,
    required this.offerId,
    required this.touristUserId,
    required this.guideUserId,
    required this.guideProfileId,
    required this.guideDisplayName,
    required this.title,
    required this.summary,
    required this.scheduledFor,
    required this.adults,
    required this.children,
    required this.totalSeats,
    required this.totalPriceAmount,
    required this.currency,
    required this.status,
    this.legacyExcursionId,
    this.landmarkId,
    this.landmarkName,
    this.categorySlug,
    this.countryCode,
    this.cityName,
    this.coverFileId,
    this.review,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String productId;
  final String offerId;
  final String? legacyExcursionId;
  final String touristUserId;
  final String guideUserId;
  final String guideProfileId;
  final String guideDisplayName;
  final String title;
  final String summary;
  final String? landmarkId;
  final String? landmarkName;
  final String? categorySlug;
  final String? countryCode;
  final String? cityName;
  final String? coverFileId;
  final DateTime scheduledFor;
  final int adults;
  final int children;
  final int totalSeats;
  final double totalPriceAmount;
  final String currency;
  final String status;
  final ExcursionReviewVm? review;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isReviewed => review != null;

  bool isVisited(DateTime now) {
    return !isCancelled && !scheduledFor.isAfter(now);
  }

  bool isBooked(DateTime now) {
    return !isCancelled && scheduledFor.isAfter(now);
  }

  bool get isCancelled => status.trim().toUpperCase() == 'CANCELLED';

  bool canReview(DateTime now) => isVisited(now) && !isReviewed;

  ExcursionBookingVm copyWith({ExcursionReviewVm? review}) {
    return ExcursionBookingVm(
      id: id,
      productId: productId,
      offerId: offerId,
      legacyExcursionId: legacyExcursionId,
      touristUserId: touristUserId,
      guideUserId: guideUserId,
      guideProfileId: guideProfileId,
      guideDisplayName: guideDisplayName,
      title: title,
      summary: summary,
      landmarkId: landmarkId,
      landmarkName: landmarkName,
      categorySlug: categorySlug,
      countryCode: countryCode,
      cityName: cityName,
      coverFileId: coverFileId,
      scheduledFor: scheduledFor,
      adults: adults,
      children: children,
      totalSeats: totalSeats,
      totalPriceAmount: totalPriceAmount,
      currency: currency,
      status: status,
      review: review ?? this.review,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ExcursionBookingVm.fromJson(Map<String, dynamic> json) {
    return ExcursionBookingVm(
      id: _string(json['id']),
      productId: _string(json['productId']),
      offerId: _string(json['offerId']),
      legacyExcursionId: _nullableString(json['legacyExcursionId']),
      touristUserId: _string(json['touristUserId']),
      guideUserId: _string(json['guideUserId']),
      guideProfileId: _string(json['guideProfileId']),
      guideDisplayName: _string(json['guideDisplayName']),
      title: _string(json['title']),
      summary: _string(json['summary']),
      landmarkId: _nullableString(json['landmarkId']),
      landmarkName: _nullableString(json['landmarkName']),
      categorySlug: _nullableString(json['categorySlug']),
      countryCode: _nullableString(json['countryCode']),
      cityName: _nullableString(json['cityName']),
      coverFileId: _nullableString(json['coverFileId']),
      scheduledFor: _date(json['scheduledFor']) ?? DateTime.now().toUtc(),
      adults: _int(json['adults']),
      children: _int(json['children']),
      totalSeats: _int(json['totalSeats']),
      totalPriceAmount: _double(json['totalPriceAmount']),
      currency: _string(json['currency']).isEmpty
          ? 'KZT'
          : _string(json['currency']),
      status: _string(json['status']).isEmpty
          ? 'REQUESTED'
          : _string(json['status']),
      review: json['review'] is Map<String, dynamic>
          ? ExcursionReviewVm.fromJson(json['review'] as Map<String, dynamic>)
          : null,
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }
}

class ExcursionReviewVm {
  const ExcursionReviewVm({
    required this.id,
    required this.bookingId,
    required this.productId,
    required this.offerId,
    required this.touristUserId,
    required this.guideUserId,
    required this.guideProfileId,
    required this.guideDisplayName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.legacyExcursionId,
    this.landmarkId,
    this.landmarkName,
    this.sourceLabel = 'EXCURSION',
  });

  final String id;
  final String bookingId;
  final String productId;
  final String offerId;
  final String? legacyExcursionId;
  final String? landmarkId;
  final String? landmarkName;
  final String touristUserId;
  final String guideUserId;
  final String guideProfileId;
  final String guideDisplayName;
  final double rating;
  final String comment;
  final String sourceLabel;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ExcursionReviewVm.fromJson(Map<String, dynamic> json) {
    return ExcursionReviewVm(
      id: _string(json['id']),
      bookingId: _string(json['bookingId']),
      productId: _string(json['productId']),
      offerId: _string(json['offerId']),
      legacyExcursionId: _nullableString(json['legacyExcursionId']),
      landmarkId: _nullableString(json['landmarkId']),
      landmarkName: _nullableString(json['landmarkName']),
      touristUserId: _string(json['touristUserId']),
      guideUserId: _string(json['guideUserId']),
      guideProfileId: _string(json['guideProfileId']),
      guideDisplayName: _string(json['guideDisplayName']),
      rating: _double(json['rating']),
      comment: _string(json['comment']),
      sourceLabel: _string(json['sourceLabel']).isEmpty
          ? 'EXCURSION'
          : _string(json['sourceLabel']),
      createdAt: _date(json['createdAt']) ?? DateTime.now().toUtc(),
      updatedAt: _date(json['updatedAt']) ?? DateTime.now().toUtc(),
    );
  }
}

List<ExcursionBookingVm> filterMyExcursionBookings(
  List<ExcursionBookingVm> items, {
  required DateTime now,
  required MyExcursionsTab tab,
  String query = '',
  Set<String> statuses = const <String>{},
  bool? reviewed,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return items
      .where((item) {
        if (tab == MyExcursionsTab.booked && !item.isBooked(now)) {
          return false;
        }
        if (tab == MyExcursionsTab.visited && !item.isVisited(now)) {
          return false;
        }
        if (statuses.isNotEmpty &&
            !statuses.contains(item.status.trim().toUpperCase())) {
          return false;
        }
        if (reviewed != null && item.isReviewed != reviewed) {
          return false;
        }
        if (startDate != null) {
          final start = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          if (item.scheduledFor.isBefore(start)) return false;
        }
        if (endDate != null) {
          final end = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
            999,
          );
          if (item.scheduledFor.isAfter(end)) return false;
        }
        if (normalizedQuery.isEmpty) return true;
        final haystack = [
          item.title,
          item.summary,
          item.landmarkName,
          item.guideDisplayName,
          item.cityName,
        ].whereType<String>().join(' ').toLowerCase();
        return haystack.contains(normalizedQuery);
      })
      .toList(growable: false);
}

List<ExcursionBookingVm> sortMyExcursionBookings(
  List<ExcursionBookingVm> items, {
  required DateTime now,
  required MyExcursionsTab tab,
  required MyExcursionBookingSortMode sortMode,
  required bool ascending,
}) {
  final sorted = List<ExcursionBookingVm>.from(items);
  sorted.sort((a, b) {
    if (tab == MyExcursionsTab.visited) {
      final aPriority = a.canReview(now) ? 0 : 1;
      final bPriority = b.canReview(now) ? 0 : 1;
      final priorityCompare = aPriority.compareTo(bPriority);
      if (priorityCompare != 0) return priorityCompare;
    }

    final primary = switch (sortMode) {
      MyExcursionBookingSortMode.date => a.scheduledFor.compareTo(
        b.scheduledFor,
      ),
      MyExcursionBookingSortMode.price => a.totalPriceAmount.compareTo(
        b.totalPriceAmount,
      ),
    };
    final directed = ascending ? primary : -primary;
    if (directed != 0) return directed;
    return a.title.compareTo(b.title);
  });
  return sorted;
}

String _string(Object? value) => value?.toString().trim() ?? '';

String? _nullableString(Object? value) {
  final result = _string(value);
  return result.isEmpty ? null : result;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_string(value)) ?? 0;
}

double _double(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(_string(value)) ?? 0;
}

DateTime? _date(Object? value) {
  final raw = _string(value);
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toUtc();
}
