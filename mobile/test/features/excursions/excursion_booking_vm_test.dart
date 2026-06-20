import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/excursions/models/excursion_booking_vm.dart';

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
      'landmarkId': 'place-1',
      'landmarkName': 'Medeu',
      'scheduledFor': '2026-05-01T08:00:00Z',
      'adults': 2,
      'children': 1,
      'totalSeats': 3,
      'totalPriceAmount': 45000,
      'currency': 'KZT',
      'status': 'REQUESTED',
      'author': {
        'userId': 'tourist-1',
        'nickname': '@booking_author',
        'avatarFileId': 'booking-avatar-1',
      },
      'review': {
        'id': 'review-1',
        'bookingId': 'booking-1',
        'productId': 'product-1',
        'landmarkId': 'place-1',
        'touristUserId': 'tourist-1',
        'guideUserId': 'guide-user-1',
        'guideProfileId': 'guide-profile-1',
        'guideDisplayName': 'Aruzhan',
        'author': {
          'userId': 'tourist-1',
          'nickname': '@nomad_aru',
          'avatarFileId': 'avatar-1',
        },
        'rating': 4.5,
        'comment': 'Warm guide and a smooth route.',
        'createdAt': '2026-05-02T10:00:00Z',
      },
      'guideReview': {
        'id': 'guide-review-1',
        'bookingId': 'booking-1',
        'touristUserId': 'tourist-1',
        'guideUserId': 'guide-user-1',
        'guideProfileId': 'guide-profile-1',
        'guideDisplayName': 'Aruzhan',
        'author': {
          'userId': 'tourist-1',
          'nickname': '@nomad_aru',
          'avatarFileId': 'avatar-1',
        },
        'rating': 5,
        'comment': 'Thoughtful pacing and clear stories.',
        'createdAt': '2026-05-02T10:05:00Z',
      },
    });

    expect(booking.id, 'booking-1');
    expect(booking.isReviewed, isTrue);
    expect(booking.review?.rating, 4.5);
    expect(booking.review?.guideDisplayName, 'Aruzhan');
    expect(booking.review?.author.userId, 'tourist-1');
    expect(booking.review?.author.nickname, '@nomad_aru');
    expect(booking.review?.author.avatarFileId, 'avatar-1');
    expect(booking.guideReview?.id, 'guide-review-1');
    expect(booking.guideReview?.rating, 5);
    expect(
      booking.guideReview?.comment,
      'Thoughtful pacing and clear stories.',
    );
    expect(booking.guideReview?.author.nickname, '@nomad_aru');
    expect(booking.author.userId, 'tourist-1');
    expect(booking.author.nickname, '@booking_author');
    expect(booking.author.avatarFileId, 'booking-avatar-1');
    expect(booking.landmarkId, 'place-1');
    expect(booking.scheduleSlotId, 'slot-1');
    expect(booking.scheduledFor, DateTime.utc(2026, 5, 1, 8));
  });

  test(
    'completed bookings are sorted by unrated first then newest visit date',
    () {
      final now = DateTime.utc(2026, 5, 17);
      final sorted = sortMyExcursionBookings(
        [
          _booking(
            'rated-newer',
            DateTime.utc(2026, 5, 10),
            checkedInAt: DateTime.utc(2026, 5, 10, 8),
            reviewed: true,
          ),
          _booking(
            'unrated-older',
            DateTime.utc(2026, 5, 1),
            checkedInAt: DateTime.utc(2026, 5, 1, 8),
          ),
          _booking(
            'unrated-newer',
            DateTime.utc(2026, 5, 12),
            checkedInAt: DateTime.utc(2026, 5, 12, 8),
          ),
          _booking(
            'rated-older',
            DateTime.utc(2026, 4, 25),
            checkedInAt: DateTime.utc(2026, 4, 25, 8),
            reviewed: true,
          ),
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

  test(
    'visited filter keeps past bookings in history even without check-in',
    () {
      final now = DateTime.utc(2026, 5, 17);
      final visited = _booking(
        'visited',
        DateTime.utc(2026, 5, 10),
        checkedInAt: DateTime.utc(2026, 5, 10, 8),
      );
      final bookedPast = _booking('booked-past', DateTime.utc(2026, 5, 10));
      final futureCheckedIn = _booking(
        'future-checked-in',
        DateTime.utc(2026, 5, 18),
        checkedInAt: DateTime.utc(2026, 5, 18, 7),
      );
      final cancelledCheckedIn = _booking(
        'cancelled-checked-in',
        DateTime.utc(2026, 5, 10),
        checkedInAt: DateTime.utc(2026, 5, 10, 8),
        status: 'CANCELLED',
      );

      final filtered = filterMyExcursionBookings(
        [visited, bookedPast, futureCheckedIn, cancelledCheckedIn],
        now: now,
        tab: MyExcursionsTab.visited,
        statuses: const {'CANCELLED'},
      );

      expect(filtered.map((item) => item.id), ['visited', 'booked-past']);
      expect(bookedPast.canReview(now), isFalse);
    },
  );

  test('attendance QR action is available only from one hour before start', () {
    final startsAt = DateTime.utc(2026, 5, 1, 8);
    final booking = _booking('with-slot', startsAt, scheduleSlotId: 'slot-1');

    expect(
      booking.canShowAttendanceQr(DateTime.utc(2026, 5, 1, 6, 59)),
      isFalse,
    );
    expect(booking.canShowAttendanceQr(DateTime.utc(2026, 5, 1, 7)), isTrue);
    expect(
      booking.canShowAttendanceQr(DateTime.utc(2026, 5, 1, 8, 30)),
      isTrue,
    );
    expect(
      _booking(
        'without-slot',
        startsAt,
      ).canShowAttendanceQr(DateTime.utc(2026, 5, 1, 7)),
      isFalse,
    );
  });

  test('booking exposes checked-in attendance status', () {
    final checkedIn = ExcursionBookingVm.fromJson({
      'id': 'booking-1',
      'productId': 'product-1',
      'offerId': 'offer-1',
      'scheduleSlotId': 'slot-1',
      'touristUserId': 'tourist-1',
      'guideUserId': 'guide-user-1',
      'guideProfileId': 'guide-profile-1',
      'scheduledFor': '2026-05-01T08:00:00Z',
      'adults': 1,
      'children': 0,
      'totalSeats': 1,
      'totalPriceAmount': 100,
      'currency': 'KZT',
      'status': 'REQUESTED',
      'checkedInAt': '2026-05-01T07:45:00Z',
    });

    expect(checkedIn.isCheckedIn, isTrue);
    expect(checkedIn.checkedInAt, DateTime.utc(2026, 5, 1, 7, 45));
    expect(
      _booking('waiting', DateTime.utc(2026, 5, 1, 8)).isCheckedIn,
      isFalse,
    );
  });

  test('visited reviewed bookings still allow author review management', () {
    final booking = _booking(
      'rated-visited',
      DateTime.utc(2026, 5, 10),
      checkedInAt: DateTime.utc(2026, 5, 10, 8),
      reviewed: true,
    );

    expect(booking.isReviewed, isTrue);
    expect(booking.canReview(DateTime.utc(2026, 5, 17)), isTrue);
  });

  test('review badge rating uses available excursion and guide reviews', () {
    final unrated = _booking('unrated', DateTime.utc(2026, 5, 10));
    final guideOnly = _booking(
      'guide-only',
      DateTime.utc(2026, 5, 10),
      guideReviewed: true,
    );
    final both = _booking(
      'both',
      DateTime.utc(2026, 5, 10),
      reviewed: true,
      guideReviewed: true,
    );

    expect(unrated.reviewBadgeRating, isNull);
    expect(guideOnly.review, isNull);
    expect(guideOnly.isReviewed, isTrue);
    expect(guideOnly.reviewBadgeRating, 4);
    expect(both.reviewBadgeRating, 4.5);
  });
}

ExcursionBookingVm _booking(
  String id,
  DateTime scheduledFor, {
  bool reviewed = false,
  bool guideReviewed = false,
  String? scheduleSlotId,
  DateTime? checkedInAt,
  String status = 'REQUESTED',
}) {
  return ExcursionBookingVm(
    id: id,
    productId: 'product-$id',
    offerId: 'offer-$id',
    touristUserId: 'tourist-1',
    guideUserId: 'guide-user-1',
    guideProfileId: 'guide-profile-1',
    guideDisplayName: 'Aruzhan',
    scheduleSlotId: scheduleSlotId,
    title: 'Tour $id',
    summary: 'Summary',
    scheduledFor: scheduledFor,
    adults: 1,
    children: 0,
    totalSeats: 1,
    totalPriceAmount: 100,
    currency: 'KZT',
    status: status,
    checkedInAt: checkedInAt,
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
    guideReview: guideReviewed
        ? GuideReviewVm(
            id: 'guide-review-$id',
            bookingId: id,
            touristUserId: 'tourist-1',
            guideUserId: 'guide-user-1',
            guideProfileId: 'guide-profile-1',
            guideDisplayName: 'Aruzhan',
            rating: 4,
            comment: 'Careful guide',
            createdAt: DateTime.utc(2026, 5, 13),
            updatedAt: DateTime.utc(2026, 5, 13),
          )
        : null,
  );
}
