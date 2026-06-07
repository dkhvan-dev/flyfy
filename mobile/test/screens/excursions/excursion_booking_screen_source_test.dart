import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'excursion booking screen follows the booking reference structure',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_booking_screen.dart',
      ).readAsString();

      expect(source, contains('class ExcursionBookingRouteArgs'));
      expect(source, contains('class ExcursionBookingScreen'));
      expect(source, contains('ExcursionVm? initialExcursion'));
      expect(source, contains('loadExcursionDetails'));
      expect(source, contains('ExcursionBookingContent'));
      expect(source, contains('_BookingExcursionCard'));
      expect(source, contains('_BookingScheduleCard'));
      expect(source, contains('_BookingSlotSelector'));
      expect(source, contains('loadBookableExcursionSchedule'));
      expect(source, contains('loadMyExcursionBookings'));
      expect(source, contains('_existingBookingForSelectedSlot'));
      expect(source, contains('scheduleSlotId: _selectedSlot?.id'));
      expect(source, contains("context.go('/me/excursions')"));
      expect(source, contains('_TravelerCounterRow'));
      expect(source, contains('_BookingSummarySection'));
      expect(source, contains('_BookingFooter'));
      expect(source, contains('resolveExcursionCoverUrl(excursion)'));
      expect(source, contains('showModalBottomSheet'));
      expect(source, contains('selectedSlot?.availableSeats'));
      expect(source, contains('_selectedSlotUnavailableMessage'));
      expect(source, contains('excursionBookingSelectedSlotUnavailable'));
      expect(source, contains('previousSlotId == null'));
      expect(
        source,
        isNot(contains('_selectedSlot = preservedSlot ?? _firstSlotOrNull')),
      );
      expect(source, isNot(contains('showDatePicker')));
      expect(source, isNot(contains('showTimePicker')));
    },
  );

  test(
    'excursion booking copy is honest while real payments are not connected',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_booking_screen.dart',
      ).readAsString();
      final ruArb = await File('lib/l10n/app_ru.arb').readAsString();

      expect(source, contains('excursionBookingConfirmReservation'));
      expect(source, contains('excursionBookingPaymentPendingNote'));
      expect(source, isNot(contains('excursionBookingSecurePayment')));
      expect(source, isNot(contains('excursionBookingConfirmPay')));
      expect(ruArb, contains('"excursionBookingConfirmReservation"'));
      expect(ruArb, contains('"excursionBookingPaymentPendingNote"'));
    },
  );

  test(
    'router exposes protected booking route before public details route',
    () async {
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();

      final bookingRouteIndex = routerSource.indexOf(
        "path: '/excursions/:excursionId/booking'",
      );
      final detailsRouteIndex = routerSource.indexOf(
        "path: '/excursions/:excursionId'",
      );

      expect(bookingRouteIndex, isNonNegative);
      expect(detailsRouteIndex, isNonNegative);
      expect(bookingRouteIndex, lessThan(detailsRouteIndex));
      expect(routerSource, contains('ExcursionBookingRouteArgs'));
      expect(routerSource, contains('ExcursionBookingScreen'));
      expect(routerSource, contains("location.endsWith('/booking')"));
    },
  );
}
