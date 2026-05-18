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
    this.scheduleSlotId,
    this.legacyExcursionId,
    this.maxGroupSize,
    this.landmarkId,
    this.landmarkName,
    this.categorySlug,
    this.countryCode,
    this.cityName,
    this.coverFileId,
    this.author = const ExcursionReviewAuthorVm(userId: ''),
    this.review,
    this.cancelledAt,
    this.cancelledBy,
    this.cancelReason,
    this.refundPercent = 0,
    this.refundAmount = 0,
    this.refundCurrency,
    this.refundPolicyCode,
    this.refundStatus,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String productId;
  final String offerId;
  final String? scheduleSlotId;
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
  final ExcursionReviewAuthorVm author;
  final DateTime scheduledFor;
  final int adults;
  final int children;
  final int totalSeats;
  final int? maxGroupSize;
  final double totalPriceAmount;
  final String currency;
  final String status;
  final ExcursionReviewVm? review;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancelReason;
  final int refundPercent;
  final double refundAmount;
  final String? refundCurrency;
  final String? refundPolicyCode;
  final String? refundStatus;
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

  bool canBeCancelledByGuide(DateTime now) {
    return !isCancelled && scheduledFor.toUtc().isAfter(now.toUtc());
  }

  bool canBeCancelledByTourist(DateTime now) {
    return !isCancelled && scheduledFor.toUtc().isAfter(now.toUtc());
  }

  ExcursionBookingCancellationQuote estimateCancellationRefund(DateTime now) {
    return ExcursionBookingCancellationQuote.fromBooking(
      totalAmount: totalPriceAmount,
      currency: currency,
      scheduledFor: scheduledFor,
      now: now,
    );
  }

  ExcursionBookingVm copyWith({
    ExcursionReviewVm? review,
    String? status,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? cancelReason,
    int? refundPercent,
    double? refundAmount,
    String? refundCurrency,
    String? refundPolicyCode,
    String? refundStatus,
  }) {
    return ExcursionBookingVm(
      id: id,
      productId: productId,
      offerId: offerId,
      scheduleSlotId: scheduleSlotId,
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
      author: author,
      scheduledFor: scheduledFor,
      adults: adults,
      children: children,
      totalSeats: totalSeats,
      maxGroupSize: maxGroupSize,
      totalPriceAmount: totalPriceAmount,
      currency: currency,
      status: status ?? this.status,
      review: review ?? this.review,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelReason: cancelReason ?? this.cancelReason,
      refundPercent: refundPercent ?? this.refundPercent,
      refundAmount: refundAmount ?? this.refundAmount,
      refundCurrency: refundCurrency ?? this.refundCurrency,
      refundPolicyCode: refundPolicyCode ?? this.refundPolicyCode,
      refundStatus: refundStatus ?? this.refundStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ExcursionBookingVm.fromJson(Map<String, dynamic> json) {
    return ExcursionBookingVm(
      id: _string(json['id']),
      productId: _string(json['productId']),
      offerId: _string(json['offerId']),
      scheduleSlotId: _nullableString(json['scheduleSlotId']),
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
      author: json['author'] is Map<String, dynamic>
          ? ExcursionReviewAuthorVm.fromJson(
              json['author'] as Map<String, dynamic>,
              fallbackUserId: _string(json['touristUserId']),
            )
          : ExcursionReviewAuthorVm(userId: _string(json['touristUserId'])),
      scheduledFor: _date(json['scheduledFor']) ?? DateTime.now().toUtc(),
      adults: _int(json['adults']),
      children: _int(json['children']),
      totalSeats: _int(json['totalSeats']),
      maxGroupSize: _optionalPositiveInt(json['maxGroupSize']),
      totalPriceAmount: _double(json['totalPriceAmount']),
      currency:
          _string(json['currency']).isEmpty ? 'KZT' : _string(json['currency']),
      status: _string(json['status']).isEmpty
          ? 'REQUESTED'
          : _string(json['status']),
      review: json['review'] is Map<String, dynamic>
          ? ExcursionReviewVm.fromJson(json['review'] as Map<String, dynamic>)
          : null,
      cancelledAt: _date(json['cancelledAt']),
      cancelledBy: _nullableString(json['cancelledBy']),
      cancelReason: _nullableString(json['cancelReason']),
      refundPercent: _int(json['refundPercent']),
      refundAmount: _double(json['refundAmount']),
      refundCurrency: _nullableString(json['refundCurrency']),
      refundPolicyCode: _nullableString(json['refundPolicyCode']),
      refundStatus: _nullableString(json['refundStatus']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }
}

class ExcursionBookingCancellationQuote {
  const ExcursionBookingCancellationQuote({
    required this.percent,
    required this.amount,
    required this.currency,
    required this.policyCode,
    required this.status,
  });

  final int percent;
  final double amount;
  final String currency;
  final String policyCode;
  final String status;

  bool get hasRefund => amount > 0;

  factory ExcursionBookingCancellationQuote.fromBooking({
    required double totalAmount,
    required String currency,
    required DateTime scheduledFor,
    required DateTime now,
  }) {
    final untilStart = scheduledFor.toUtc().difference(now.toUtc());
    var percent = 0;
    var policyCode = 'NO_REFUND_INSIDE_2H';

    if (untilStart >= const Duration(hours: 24)) {
      percent = 100;
      policyCode = 'FULL_REFUND_BEFORE_24H';
    } else if (untilStart >= const Duration(hours: 12)) {
      percent = 75;
      policyCode = 'PARTIAL_REFUND_BEFORE_12H';
    } else if (untilStart >= const Duration(hours: 6)) {
      percent = 50;
      policyCode = 'PARTIAL_REFUND_BEFORE_6H';
    } else if (untilStart >= const Duration(hours: 2)) {
      percent = 25;
      policyCode = 'PARTIAL_REFUND_BEFORE_2H';
    }

    final amount = ((totalAmount * percent / 100) * 100).roundToDouble() / 100;
    return ExcursionBookingCancellationQuote(
      percent: percent,
      amount: amount,
      currency: currency.trim().isEmpty ? 'KZT' : currency.trim(),
      policyCode: policyCode,
      status: amount > 0 ? 'PENDING_PAYMENT_INTEGRATION' : 'NOT_REFUNDABLE',
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
    this.author = const ExcursionReviewAuthorVm(userId: ''),
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
  final ExcursionReviewAuthorVm author;
  final double rating;
  final String comment;
  final String sourceLabel;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ExcursionReviewVm.fromJson(Map<String, dynamic> json) {
    final touristUserId = _string(json['touristUserId']);
    final author = json['author'] is Map<String, dynamic>
        ? ExcursionReviewAuthorVm.fromJson(
            json['author'] as Map<String, dynamic>,
            fallbackUserId: touristUserId,
          )
        : ExcursionReviewAuthorVm(userId: touristUserId);
    return ExcursionReviewVm(
      id: _string(json['id']),
      bookingId: _string(json['bookingId']),
      productId: _string(json['productId']),
      offerId: _string(json['offerId']),
      legacyExcursionId: _nullableString(json['legacyExcursionId']),
      landmarkId: _nullableString(json['landmarkId']),
      landmarkName: _nullableString(json['landmarkName']),
      touristUserId: touristUserId,
      guideUserId: _string(json['guideUserId']),
      guideProfileId: _string(json['guideProfileId']),
      guideDisplayName: _string(json['guideDisplayName']),
      author: author,
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

class ExcursionReviewAuthorVm {
  const ExcursionReviewAuthorVm({
    required this.userId,
    this.displayName,
    this.avatarFileId,
  });

  final String userId;
  final String? displayName;
  final String? avatarFileId;

  factory ExcursionReviewAuthorVm.fromJson(
    Map<String, dynamic> json, {
    String fallbackUserId = '',
  }) {
    final userId = _string(json['userId']);
    return ExcursionReviewAuthorVm(
      userId: userId.isEmpty ? fallbackUserId : userId,
      displayName: _nullableString(json['displayName']),
      avatarFileId: _nullableString(json['avatarFileId']),
    );
  }

  String get resolvedDisplayName => (displayName ?? '').trim();
  String get resolvedAvatarFileId => (avatarFileId ?? '').trim();
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
  return items.where((item) {
    final isUpcoming = item.scheduledFor.toUtc().isAfter(now.toUtc());
    if (tab == MyExcursionsTab.booked && !isUpcoming) {
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
  }).toList(growable: false);
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

int? _optionalPositiveInt(Object? value) {
  final parsed = _int(value);
  return parsed > 0 ? parsed : null;
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
