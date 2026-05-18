enum ExcursionScheduleSlotStatus {
  available,
  booked,
  full,
  closed,
  cancelled;

  static ExcursionScheduleSlotStatus fromWire(String? value) {
    return switch ((value ?? '').trim().toUpperCase()) {
      'AVAILABLE' => ExcursionScheduleSlotStatus.available,
      'BOOKED' => ExcursionScheduleSlotStatus.booked,
      'FULL' => ExcursionScheduleSlotStatus.full,
      'CLOSED' => ExcursionScheduleSlotStatus.closed,
      'CANCELLED' => ExcursionScheduleSlotStatus.cancelled,
      _ => ExcursionScheduleSlotStatus.closed,
    };
  }
}

const excursionScheduleBookingLeadTime = Duration(hours: 2);

class ExcursionScheduleSlotVm {
  const ExcursionScheduleSlotVm({
    required this.id,
    required this.offerId,
    required this.productId,
    required this.startAt,
    required this.endAt,
    required this.timezone,
    required this.capacity,
    required this.bookedSeats,
    required this.status,
    this.seriesId,
    this.legacyExcursionId,
    this.title = '',
    this.cancelReason,
  });

  final String id;
  final String? seriesId;
  final String offerId;
  final String productId;
  final String? legacyExcursionId;
  final DateTime startAt;
  final DateTime endAt;
  final String timezone;
  final int capacity;
  final int bookedSeats;
  final ExcursionScheduleSlotStatus status;
  final String title;
  final String? cancelReason;

  Duration get duration => endAt.difference(startAt);

  int get availableSeats {
    final remaining = capacity - bookedSeats;
    return remaining > 0 ? remaining : 0;
  }

  bool isAvailableFor(int seats) {
    final requestedSeats = seats <= 0 ? 1 : seats;
    return isBookable && availableSeats >= requestedSeats;
  }

  bool isBookableForBooking(
    int seats, {
    DateTime? now,
    Duration leadTime = excursionScheduleBookingLeadTime,
  }) {
    final cutoff = (now ?? DateTime.now()).toUtc().add(leadTime);
    return isAvailableFor(seats) && !startAt.toUtc().isBefore(cutoff);
  }

  bool get isBooked =>
      bookedSeats > 0 ||
      status == ExcursionScheduleSlotStatus.booked ||
      status == ExcursionScheduleSlotStatus.full;

  bool get isBookable =>
      status == ExcursionScheduleSlotStatus.available ||
      status == ExcursionScheduleSlotStatus.booked;

  factory ExcursionScheduleSlotVm.fromJson(Map<String, dynamic> json) {
    return ExcursionScheduleSlotVm(
      id: _string(json['id']),
      seriesId: _optionalString(json['seriesId']),
      offerId: _string(json['offerId']),
      productId: _string(json['productId']),
      legacyExcursionId: _optionalString(json['legacyExcursionId']),
      startAt: _dateTimeUtc(json['startAt']),
      endAt: _dateTimeUtc(json['endAt']),
      timezone: _string(json['timezone']),
      capacity: _int(json['capacity']),
      bookedSeats: _int(json['bookedSeats']),
      status: ExcursionScheduleSlotStatus.fromWire(json['status'] as String?),
      title: _string(json['title']),
      cancelReason: _optionalString(json['cancelReason']),
    );
  }
}

class CreateExcursionScheduleSlotRequest {
  const CreateExcursionScheduleSlotRequest({
    required this.offerId,
    required this.startAt,
    required this.timezone,
    this.capacity,
  });

  final String offerId;
  final DateTime startAt;
  final String timezone;
  final int? capacity;

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId.trim(),
      'startAt': startAt.toUtc().toIso8601String(),
      'timezone': timezone.trim(),
      if (capacity != null) 'capacity': capacity,
    };
  }
}

class UpdateExcursionScheduleSlotRequest {
  const UpdateExcursionScheduleSlotRequest({
    required this.offerId,
    required this.startAt,
    required this.timezone,
    this.capacity,
  });

  final String offerId;
  final DateTime startAt;
  final String timezone;
  final int? capacity;

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId.trim(),
      'startAt': startAt.toUtc().toIso8601String(),
      'timezone': timezone.trim(),
      if (capacity != null) 'capacity': capacity,
    };
  }
}

class CreateExcursionScheduleSeriesRequest {
  const CreateExcursionScheduleSeriesRequest({
    required this.offerId,
    required this.startsOn,
    required this.startTime,
    required this.timezone,
    required this.weekdays,
    this.endsOn,
    this.occurrenceLimit,
    this.capacity,
  });

  final String offerId;
  final DateTime startsOn;
  final String startTime;
  final String timezone;
  final List<int> weekdays;
  final DateTime? endsOn;
  final int? occurrenceLimit;
  final int? capacity;

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId.trim(),
      'startsOn': _dateOnly(startsOn),
      'startTime': startTime.trim(),
      'timezone': timezone.trim(),
      'weekdays': weekdays,
      if (endsOn != null) 'endsOn': _dateOnly(endsOn!),
      if (occurrenceLimit != null) 'occurrenceLimit': occurrenceLimit,
      if (capacity != null) 'capacity': capacity,
    };
  }
}

String _string(Object? value) => value is String ? value.trim() : '';

String? _optionalString(Object? value) {
  final normalized = _string(value);
  return normalized.isEmpty ? null : normalized;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

DateTime _dateTimeUtc(Object? value) {
  if (value is DateTime) return value.toUtc();
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.parse(value.trim()).toUtc();
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

String _dateOnly(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
