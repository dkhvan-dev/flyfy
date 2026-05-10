import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tour booking screen follows the booking reference structure', () async {
    final source =
        await File('lib/screens/tours/tour_booking_screen.dart').readAsString();

    expect(source, contains('class TourBookingRouteArgs'));
    expect(source, contains('class TourBookingScreen'));
    expect(source, contains('TourVm? initialTour'));
    expect(source, contains('loadTourDetails'));
    expect(source, contains('TourBookingContent'));
    expect(source, contains('_BookingTourCard'));
    expect(source, contains('_BookingScheduleCard'));
    expect(source, contains('_TravelerCounterRow'));
    expect(source, contains('_BookingSummarySection'));
    expect(source, contains('_BookingFooter'));
    expect(source, contains('resolveTourCoverUrl(tour)'));
  });

  test('router exposes protected booking route before public details route',
      () async {
    final routerSource =
        await File('lib/core/router/app_router.dart').readAsString();

    final bookingRouteIndex =
        routerSource.indexOf("path: '/tours/:tourId/booking'");
    final detailsRouteIndex = routerSource.indexOf("path: '/tours/:tourId'");

    expect(bookingRouteIndex, isNonNegative);
    expect(detailsRouteIndex, isNonNegative);
    expect(bookingRouteIndex, lessThan(detailsRouteIndex));
    expect(routerSource, contains('TourBookingRouteArgs'));
    expect(routerSource, contains('TourBookingScreen'));
    expect(routerSource, contains("location.endsWith('/booking')"));
  });
}
