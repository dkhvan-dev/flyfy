import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tour details screen follows the reference structure', () async {
    final source =
        await File('lib/screens/tours/tour_details_screen.dart').readAsString();

    expect(source, contains('class TourDetailsScreen'));
    expect(source, contains('initialTour'));
    expect(source, contains('loadTourDetails'));
    expect(source, contains('TourDetailsContent'));
    expect(source, contains('_TourHero'));
    expect(source, contains('_TourStatsGrid'));
    expect(source, contains('_TourExperienceSection'));
    expect(source, contains('_TourGuideAndMapSection'));
    expect(source, contains('_TourItinerarySection'));
    expect(source, contains('_TourCheckoutBar'));
    expect(source, contains('SingleChildScrollView'));
    expect(source, contains('MediaQuery.paddingOf(context).bottom'));
  });

  test('router exposes public tour details without opening create route',
      () async {
    final routerSource =
        await File('lib/core/router/app_router.dart').readAsString();

    expect(routerSource, contains("path: '/tours/:tourId'"));
    expect(routerSource, contains('TourDetailsScreen'));
    expect(routerSource, contains("location.startsWith('/tours/')"));
    expect(routerSource, contains("location != '/tours/create'"));
  });

  test('tours list opens details with cached tour as route extra', () async {
    final listSource =
        await File('lib/screens/tours/tours_screen.dart').readAsString();

    expect(listSource, contains("_openTourDetails"));
    expect(listSource, contains("context.push('/tours/"));
    expect(listSource, contains('extra: tour'));
  });
}
