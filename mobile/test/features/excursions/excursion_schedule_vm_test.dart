import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/excursions/models/excursion_schedule_vm.dart';

void main() {
  test('schedule slot parses booked wire status and computed flags', () {
    final slot = ExcursionScheduleSlotVm.fromJson({
      'id': 'slot-1',
      'seriesId': 'series-1',
      'offerId': 'offer-1',
      'productId': 'product-1',
      'legacyExcursionId': 'excursion-1',
      'startAt': '2026-06-01T08:00:00Z',
      'endAt': '2026-06-01T10:30:00Z',
      'timezone': 'Asia/Almaty',
      'capacity': 6,
      'bookedSeats': 2,
      'status': 'BOOKED',
      'title': 'Medeu sunrise walk',
    });

    expect(slot.id, 'slot-1');
    expect(slot.status, ExcursionScheduleSlotStatus.booked);
    expect(slot.startAt, DateTime.utc(2026, 6, 1, 8));
    expect(slot.endAt, DateTime.utc(2026, 6, 1, 10, 30));
    expect(slot.duration, const Duration(hours: 2, minutes: 30));
    expect(slot.availableSeats, 4);
    expect(slot.isAvailableFor(4), isTrue);
    expect(slot.isAvailableFor(5), isFalse);
    expect(slot.isBooked, isTrue);
    expect(slot.isBookable, isTrue);
  });

  test('create slot request serializes startAt as UTC ISO', () {
    final request = CreateExcursionScheduleSlotRequest(
      offerId: ' offer-1 ',
      startAt: DateTime.parse('2026-06-01T13:00:00+05:00'),
      timezone: ' Asia/Almaty ',
      capacity: 8,
    );

    expect(request.toJson(), {
      'offerId': 'offer-1',
      'startAt': '2026-06-01T08:00:00.000Z',
      'timezone': 'Asia/Almaty',
      'capacity': 8,
    });
  });

  test('booking availability requires two hour lead time', () {
    final now = DateTime.utc(2026, 6, 1, 8);
    final nearSlot = ExcursionScheduleSlotVm.fromJson({
      'id': 'slot-near',
      'offerId': 'offer-1',
      'productId': 'product-1',
      'startAt': '2026-06-01T09:30:00Z',
      'endAt': '2026-06-01T12:30:00Z',
      'timezone': 'Asia/Almaty',
      'capacity': 6,
      'bookedSeats': 0,
      'status': 'AVAILABLE',
    });
    final bookableSlot = ExcursionScheduleSlotVm.fromJson({
      'id': 'slot-bookable',
      'offerId': 'offer-1',
      'productId': 'product-1',
      'startAt': '2026-06-01T10:00:00Z',
      'endAt': '2026-06-01T13:00:00Z',
      'timezone': 'Asia/Almaty',
      'capacity': 6,
      'bookedSeats': 0,
      'status': 'AVAILABLE',
    });

    expect(nearSlot.isBookableForBooking(1, now: now), isFalse);
    expect(bookableSlot.isBookableForBooking(1, now: now), isTrue);
  });

  test('completed schedule slot parses as readonly non-bookable history', () {
    final slot = ExcursionScheduleSlotVm.fromJson({
      'id': 'slot-completed',
      'offerId': 'offer-1',
      'productId': 'product-1',
      'startAt': '2026-06-01T08:00:00Z',
      'endAt': '2026-06-01T10:00:00Z',
      'timezone': 'Asia/Almaty',
      'capacity': 6,
      'bookedSeats': 3,
      'status': 'COMPLETED',
    });

    expect(slot.status, ExcursionScheduleSlotStatus.completed);
    expect(slot.isBookable, isFalse);
    expect(slot.isReadonly, isTrue);
  });

  test('update slot request serializes editable fields as UTC ISO', () {
    final request = UpdateExcursionScheduleSlotRequest(
      offerId: ' offer-2 ',
      startAt: DateTime.parse('2026-06-05T14:30:00+05:00'),
      timezone: ' Asia/Almaty ',
      capacity: 5,
    );

    expect(request.toJson(), {
      'offerId': 'offer-2',
      'startAt': '2026-06-05T09:30:00.000Z',
      'timezone': 'Asia/Almaty',
      'capacity': 5,
    });
  });

  test('weekly series request serializes recurrence dates as yyyy-mm-dd', () {
    final request = CreateExcursionScheduleSeriesRequest(
      offerId: 'offer-1',
      startsOn: DateTime(2026, 6, 1),
      startTime: '09:30',
      timezone: 'Asia/Almaty',
      weekdays: const [1, 3, 5],
      endsOn: DateTime(2026, 8, 31),
      occurrenceLimit: 12,
      capacity: 6,
    );

    expect(request.toJson(), {
      'offerId': 'offer-1',
      'startsOn': '2026-06-01',
      'startTime': '09:30',
      'timezone': 'Asia/Almaty',
      'weekdays': [1, 3, 5],
      'endsOn': '2026-08-31',
      'occurrenceLimit': 12,
      'capacity': 6,
    });
  });
}
