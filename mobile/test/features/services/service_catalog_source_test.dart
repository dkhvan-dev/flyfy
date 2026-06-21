import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'travel checklist is available from services catalog and router',
    () async {
      final catalogSource = await File(
        'lib/features/services/service_catalog.dart',
      ).readAsString();
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();

      expect(catalogSource, contains('l10n.serviceTravelChecklist'));
      expect(catalogSource, contains("route: '/travel-checklist'"));
      expect(routerSource, contains("path: '/travel-checklist'"));
      expect(routerSource, contains('TravelChecklistScreen'));
      expect(routerSource, contains('TravelChecklistRouteArgs'));
      expect(routerSource, contains('routeArgs: checklistArgs'));
    },
  );

  test('future services are marked unavailable in the catalog', () async {
    final source = await File(
      'lib/features/services/service_catalog.dart',
    ).readAsString();

    expect(source, contains('this.isAvailable = true'));
    expect(source, contains('final bool isAvailable;'));

    for (final titleGetter in [
      'l10n.homeServiceStays',
      'l10n.serviceTransport',
      'l10n.homeServiceDelivery',
      'l10n.homeServiceTaxi',
    ]) {
      final titleIndex = source.indexOf('title: $titleGetter');
      expect(titleIndex, isNonNegative);

      final entryEnd = source.indexOf('),', titleIndex);
      expect(entryEnd, greaterThan(titleIndex));

      final entrySource = source.substring(titleIndex, entryEnd);
      expect(entrySource, contains('isAvailable: false'));
    }
  });

  test(
    'activity and excursion details expose travel checklist entry point',
    () async {
      final activitySource = await File(
        'lib/screens/activities/activity_details_screen.dart',
      ).readAsString();
      final excursionSource = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(activitySource, contains('TripPreparationCta'));
      expect(activitySource, contains("'/travel-checklist'"));
      expect(activitySource, contains('extra:'));
      expect(activitySource, contains('TravelChecklistRouteArgs('));

      expect(excursionSource, contains('TripPreparationCta'));
      expect(excursionSource, contains("'/travel-checklist'"));
      expect(excursionSource, contains('extra:'));
      expect(
        excursionSource,
        contains('TravelChecklistRouteArgs.fromExcursionBooking('),
      );
    },
  );
}
