import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/excursions/models/excursion_booking_vm.dart';

void main() {
  test('booking vm parses excursion review and guide context', () {
    final booking = ExcursionBookingVm.fromJson({
      'id': 'booking-1',
      'productId': 'product-1',
      'offerId': 'offer-1',
      'scheduleSlotId': 'slot-1',
      'touristUserId': 'tourist-1',
      'guideUserId': 'guide-user-1',
      'guideProfileId': 'guide-profile-1',
      'guideDisplayName': 'Aruzhan',
      'title': 'Medeu sunrise walk',
      'summary': 'Private city-to-mountain route',
      'landmarkId': 'attraction-1',
      'landmarkName': 'Medeu',
      'scheduledFor': '2026-05-01T08:00:00Z',
      'adults': 2,
      'children': 1,
      'totalSeats': 3,
      'totalPriceAmount': 45000,
      'currency': 'KZT',
      'status': 'REQUESTED',
      'review': {
        'id': 'review-1',
        'bookingId': 'booking-1',
        'productId': 'product-1',
        'landmarkId': 'attraction-1',
        'guideUserId': 'guide-user-1',
        'guideDisplayName': 'Aruzhan',
        'rating': 4.5,
        'comment': 'Warm guide and a smooth route.',
        'createdAt': '2026-05-02T10:00:00Z',
      },
    });

    expect(booking.id, 'booking-1');
    expect(booking.isReviewed, isTrue);
    expect(booking.review?.rating, 4.5);
    expect(booking.review?.guideDisplayName, 'Aruzhan');
    expect(booking.landmarkId, 'attraction-1');
    expect(booking.scheduleSlotId, 'slot-1');
    expect(booking.scheduledFor, DateTime.utc(2026, 5, 1, 8));
  });

  test(
    'completed bookings are sorted by unrated first then newest visit date',
    () {
      final now = DateTime.utc(2026, 5, 17);
      final sorted = sortMyExcursionBookings(
        [
          _booking('rated-newer', DateTime.utc(2026, 5, 10), reviewed: true),
          _booking('unrated-older', DateTime.utc(2026, 5, 1)),
          _booking('unrated-newer', DateTime.utc(2026, 5, 12)),
          _booking('rated-older', DateTime.utc(2026, 4, 25), reviewed: true),
        ],
        now: now,
        tab: MyExcursionsTab.visited,
        sortMode: MyExcursionBookingSortMode.date,
        ascending: false,
      );

      expect(sorted.map((item) => item.id), [
        'unrated-newer',
        'unrated-older',
        'rated-newer',
        'rated-older',
      ]);
    },
  );
}

ExcursionBookingVm _booking(
  String id,
  DateTime scheduledFor, {
  bool reviewed = false,
}) {
  return ExcursionBookingVm(
    id: id,
    productId: 'product-$id',
    offerId: 'offer-$id',
    touristUserId: 'tourist-1',
    guideUserId: 'guide-user-1',
    guideProfileId: 'guide-profile-1',
    guideDisplayName: 'Aruzhan',
    title: 'Tour $id',
    summary: 'Summary',
    scheduledFor: scheduledFor,
    adults: 1,
    children: 0,
    totalSeats: 1,
    totalPriceAmount: 100,
    currency: 'KZT',
    status: 'REQUESTED',
    review: reviewed
        ? ExcursionReviewVm(
            id: 'review-$id',
            bookingId: id,
            productId: 'product-$id',
            offerId: 'offer-$id',
            touristUserId: 'tourist-1',
            guideUserId: 'guide-user-1',
            guideProfileId: 'guide-profile-1',
            guideDisplayName: 'Aruzhan',
            rating: 5,
            comment: 'Great',
            createdAt: DateTime.utc(2026, 5, 13),
            updatedAt: DateTime.utc(2026, 5, 13),
          )
        : null,
  );
}
