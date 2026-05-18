import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guide dashboard screen uses adaptive tabs without draft tab', () async {
    final source = await File(
      'lib/screens/excursions/guide_dashboard_screen.dart',
    ).readAsString();

    expect(source, contains('class GuideDashboardScreen'));
    expect(source, contains('GuideDashboardSection.offers'));
    expect(source, contains('GuideDashboardSection.bookings'));
    expect(source, contains('GuideOfferDashboardTab.active'));
    expect(source, contains('GuideOfferDashboardTab.archive'));
    expect(source, contains('GuideOfferDashboardTab.rejected'));
    expect(source, contains('GuideOfferDashboardTab.review'));
    expect(source, contains('GuideBookingDashboardTab.active'));
    expect(source, contains('GuideBookingDashboardTab.cancelled'));
    expect(source, contains('GuideBookingDashboardTab.completed'));
    expect(source, isNot(contains('GuideDashboardTab.draft')));
    expect(source, isNot(contains('Draft')));
    expect(source, contains('TextEditingController _searchController'));
    expect(source, contains('class _GuideDashboardSearchField'));
    expect(source, contains('AppColors.accent'));
    expect(source, contains('_matchesSmartQuery'));
    expect(source, contains('_bookingCountForOffer'));
    expect(source, contains('_archiveOffer'));
    expect(source, contains('archiveExcursionOffer'));
    expect(source, contains('guideDashboardBookingCount'));
    expect(source, contains('formatLocalizedExcursionMoney'));
    expect(source, isNot(contains('symbol: excursion.currency')));
    expect(source, isNot(contains('symbol: booking.currency')));
    expect(source, contains('guideDashboardArchiveTab'));
    expect(source, contains('guideDashboardArchiveOffer'));
    expect(
        source, contains('imageUrl: resolveOwnedExcursionCoverUrl(excursion)'));
    expect(source, isNot(contains('guideDashboardHeroTitle')));
    expect(source, isNot(contains('guideDashboardOfferCount')));
    expect(source, contains('MediaQuery.sizeOf(context)'));
    expect(source, contains('LayoutBuilder('));
    expect(source, contains('Wrap('));
    expect(source, contains('AspectRatio('));
    expect(source, contains('RefreshIndicator('));
    expect(source, contains('FlyfyPaginationBar('));
    expect(source, isNot(contains('bottomNavigationBar:')));
    expect(source, isNot(contains('CommonBottomNavigationBar')));
  });

  test('edit excursion screen keeps the existing cover visible', () async {
    final source = await File(
      'lib/screens/excursions/create_excursion_screen.dart',
    ).readAsString();

    expect(source, contains('String? _existingCoverImageUrl'));
    expect(source, contains('resolveExcursionCoverUrl(excursion)'));
    expect(source, contains('_effectiveCoverImageUrl'));
    expect(source, contains('_existingCoverImageUrl'));
    expect(source, contains('_ExcursionCoverUploadCard'));
  });

  test('cancelled guide dashboard copy is only about bookings', () async {
    final ruSource = await File('lib/l10n/app_ru.arb').readAsString();
    final enSource = await File('lib/l10n/app_en.arb').readAsString();
    final kkSource = await File('lib/l10n/app_kk.arb').readAsString();

    expect(ruSource,
        contains('"guideDashboardCancelledEmpty": "Отмененных броней нет"'));
    expect(ruSource, isNot(contains('Отмененных предложений и броней')));
    expect(ruSource, isNot(contains('закрытые предложения')));
    expect(enSource,
        contains('"guideDashboardCancelledEmpty": "No cancelled bookings"'));
    expect(enSource, isNot(contains('No cancelled offers or bookings')));
    expect(enSource, isNot(contains('closed offers')));
    expect(
        kkSource,
        contains(
            '"guideDashboardCancelledEmpty": "Бас тартылған брондар жоқ"'));
    expect(kkSource, isNot(contains('ұсыныс немесе брон')));
  });

  test('guide dashboard booking cards use excursion covers', () async {
    final source = await File(
      'lib/screens/excursions/guide_dashboard_screen.dart',
    ).readAsString();

    final bookingCardStart = source.indexOf('class _GuideBookingCard');
    final journeyCardStart = source.indexOf('class _GuideJourneyCard');
    expect(bookingCardStart, isNonNegative);
    expect(journeyCardStart, greaterThan(bookingCardStart));

    final bookingCardSource = source.substring(
      bookingCardStart,
      journeyCardStart,
    );

    expect(
      bookingCardSource,
      contains('imageUrl: resolveExcursionBookingCoverUrl(booking)'),
    );
    expect(bookingCardSource, isNot(contains('imageUrl: null')));
  });

  test('profile and router expose guide dashboard only from guide profile',
      () async {
    final profileSource = await File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsString();
    final routerSource = await File(
      'lib/core/router/app_router.dart',
    ).readAsString();

    expect(routerSource, contains("path: '/profile/guide-dashboard'"));
    expect(routerSource, contains('GuideDashboardScreen'));
    expect(routerSource,
        isNot(contains("location == '/profile/guide-dashboard'")));
    expect(profileSource, contains('isGuideProfile: isGuideProfile'));
    expect(profileSource, contains("context.push('/profile/guide-dashboard')"));
    expect(profileSource, contains('profileGuideDashboardTitle'));
    expect(profileSource, contains('profileGuideDashboardSubtitle'));
  });
}
