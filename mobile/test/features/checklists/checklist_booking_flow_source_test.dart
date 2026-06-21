import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'excursion booking success can open trip checklist with booking context',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_booking_screen.dart',
      ).readAsString();

      expect(source, contains('TravelChecklistRouteArgs.fromExcursionBooking'));
      expect(source, contains('lastCreatedExcursionBooking'));
      expect(source, contains("'/travel-checklist'"));
      expect(source, contains('excursionBookingChecklistAddedTitle'));
    },
  );

  test('router exposes dedicated saved checklist list route', () async {
    final source = await File('lib/core/router/app_router.dart').readAsString();

    expect(source, contains("path: '/me/checklists'"));
    expect(source, contains('TravelChecklistListScreen'));
  });
}
