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
    expect(routerSource, contains("location.startsWith('/tours/create')"));
    expect(routerSource, contains('return false;'));
  });

  test('tours list opens details with cached tour as route extra', () async {
    final listSource =
        await File('lib/screens/tours/tours_screen.dart').readAsString();

    expect(listSource, contains("_openTourDetails"));
    expect(listSource, contains("context.push('/tours/"));
    expect(listSource, contains('extra: tour'));
  });

  test('tour details displays localized language names instead of codes',
      () async {
    final source =
        await File('lib/screens/tours/tour_details_screen.dart').readAsString();
    final localizationSource =
        await File('lib/features/tours/tour_localization.dart').readAsString();

    expect(source, contains('_formatLanguageLabels'));
    expect(localizationSource, contains('localizedTourLanguageLabel'));
    expect(localizationSource, contains('tourLanguageEnglish'));
    expect(localizationSource, contains('tourLanguageRussian'));
    expect(localizationSource, contains('tourLanguageKazakh'));
    expect(source, isNot(contains("join(', ').toUpperCase()")));
  });

  test('tour details resolves guide profile and hides guide chat for author',
      () async {
    final source =
        await File('lib/screens/tours/tour_details_screen.dart').readAsString();

    expect(source, contains('ProfileApi'));
    expect(source, contains('UserProfileVm'));
    expect(source, contains('_resolveGuideProfile'));
    expect(source, contains('tour.guideUserId'));
    expect(source, contains("context.push('/users/\$guideUserId/profile'"));
    expect(source, contains('showMessageGuide: !isAuthor'));
    expect(source, contains('showMessageGuide'));
    expect(source, isNot(contains('l10n.tourDetailsGuideName,')));
  });

  test('tour details resolves cover file id and hides booking for author',
      () async {
    final source =
        await File('lib/screens/tours/tour_details_screen.dart').readAsString();

    expect(
        source, contains("import '../../features/tours/tour_cover_url.dart';"));
    expect(source, contains('resolveTourCoverUrl(tour)'));
    expect(source, contains('showBookingAction: !isAuthor'));
    expect(source, contains('if (showBookingAction)'));
    expect(source, contains('class _TourCheckoutBar'));
  });

  test('tour details opens booking screen from booking CTA', () async {
    final source =
        await File('lib/screens/tours/tour_details_screen.dart').readAsString();

    expect(source, contains('_openBooking'));
    expect(source, contains('TourBookingRouteArgs'));
    expect(
      source,
      contains("'/tours/\${Uri.encodeComponent(tour.id)}/booking'"),
    );
    expect(source, contains('onBookTap: () => _openBooking(tour)'));
    expect(
      source,
      isNot(contains(
          'onBookTap: () => _showSoon(l10n.tourDetailsBookingComingSoon)')),
    );
  });
}
