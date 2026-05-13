import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tour details screen follows the reference structure', () async {
    final source = await File(
      'lib/screens/tours/tour_details_screen.dart',
    ).readAsString();

    expect(source, contains('class TourDetailsScreen'));
    expect(source, contains('initialTour'));
    expect(source, contains('loadTourDetails'));
    expect(source, contains('TourDetailsContent'));
    expect(source, contains('_TourHero'));
    expect(source, contains('_TourStatsGrid'));
    expect(source, contains('_TourExperienceSection'));
    expect(source, contains('_TourSelectedOfferIncludedSection'));
    expect(source, contains('_TourMapPreview'));
    expect(source, contains('_TourItinerarySection'));
    expect(source, contains('_TourCheckoutBar'));
    expect(source, contains('SingleChildScrollView'));
    expect(source, contains('MediaQuery.paddingOf(context).bottom'));
  });

  test(
    'router exposes public tour details without opening create route',
    () async {
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();

      expect(routerSource, contains("path: '/tours/:tourId'"));
      expect(routerSource, contains('TourDetailsScreen'));
      expect(routerSource, contains("location.startsWith('/tours/')"));
      expect(routerSource, contains("location.startsWith('/tours/create')"));
      expect(routerSource, contains('return false;'));
    },
  );

  test('tours list opens details with cached tour as route extra', () async {
    final listSource = await File(
      'lib/screens/tours/tours_screen.dart',
    ).readAsString();

    expect(listSource, contains("_openTourDetails"));
    expect(listSource, contains("context.push('/tours/"));
    expect(listSource, contains('extra: tour'));
  });

  test(
    'tour details displays localized language names instead of codes',
    () async {
      final source = await File(
        'lib/screens/tours/tour_details_screen.dart',
      ).readAsString();
      final localizationSource = await File(
        'lib/features/tours/tour_localization.dart',
      ).readAsString();

      expect(source, contains('_formatLanguageLabels'));
      expect(localizationSource, contains('localizedTourLanguageLabel'));
      expect(localizationSource, contains('tourLanguageEnglish'));
      expect(localizationSource, contains('tourLanguageRussian'));
      expect(localizationSource, contains('tourLanguageKazakh'));
      expect(source, isNot(contains("join(', ').toUpperCase()")));
    },
  );

  test(
    'tour details resolves guide profile and hides guide chat for author',
    () async {
      final source = await File(
        'lib/screens/tours/tour_details_screen.dart',
      ).readAsString();

      expect(source, contains('ProfileApi'));
      expect(source, contains('UserProfileVm'));
      expect(source, contains('_resolveGuideProfile'));
      expect(source, contains('tour.guideUserId'));
      expect(source, contains('context.push('));
      expect(source, contains("'/users/\$guideUserId/profile'"));
      expect(source, contains('_formatGuideSurnameInitials'));
      expect(source, contains('showMessageGuide: !isAuthor'));
      expect(source, contains('showMessageGuide'));
      expect(source, isNot(contains('l10n.tourDetailsGuideName,')));
    },
  );

  test(
    'tour details keeps offer inclusions scoped to selected guide',
    () async {
      final source = await File(
        'lib/screens/tours/tour_details_screen.dart',
      ).readAsString();
      final modelSource = await File(
        'lib/features/tours/models/tour_vm.dart',
      ).readAsString();

      expect(source, contains('_TourSelectedOfferIncludedSection'));
      expect(source, contains('selectedOffer.localizedIncludedItems'));
      expect(source, isNot(contains('_TourGuideAndMapSection')));
      expect(
        modelSource,
        isNot(contains('primaryOffer?.includedItems ?? const []')),
      );
    },
  );

  test(
    'tour details resolves cover file id and hides booking for author',
    () async {
      final source = await File(
        'lib/screens/tours/tour_details_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../features/tours/tour_cover_url.dart';"),
      );
      expect(source, contains('resolveTourCoverUrl(tour)'));
      expect(
        source,
        contains('showBookingAction: !isAuthor && hasBookableOffer'),
      );
      expect(source, contains('showEditOfferAction'));
      expect(source, contains('showBookingAction || showEditOfferAction'));
      expect(source, contains('class _TourCheckoutBar'));
    },
  );

  test('tour details opens booking screen from booking CTA', () async {
    final source = await File(
      'lib/screens/tours/tour_details_screen.dart',
    ).readAsString();

    expect(source, contains('_openBooking'));
    expect(source, contains('TourBookingRouteArgs'));
    expect(
      source,
      contains("'/tours/\${Uri.encodeComponent(tour.id)}/booking'"),
    );
    expect(
      source,
      contains('onBookTap: () => _openBooking(tour, selectedOffer)'),
    );
    expect(source, contains('selectedOfferId: selectedOffer?.id'));
    expect(
      source,
      isNot(
        contains(
          'onBookTap: () => _showSoon(l10n.tourDetailsBookingComingSoon)',
        ),
      ),
    );
  });

  test('tour details creates direct chat with guide from message CTA', () async {
    final source = await File(
      'lib/screens/tours/tour_details_screen.dart',
    ).readAsString();

    expect(source, contains('ChatApi'));
    expect(source, contains('_isMessageGuideLoading'));
    expect(source, contains('_openGuideChat'));
    expect(source, contains('createDirectConversation('));
    expect(source, contains("context.push('/chats/\$conversationId')"));
    expect(source, contains('DioErrorMapper.toMessage'));
    expect(source, contains('showErrorDialog'));
    expect(source, contains('isMessageGuideLoading: _isMessageGuideLoading'));
    expect(
      source,
      isNot(
        contains(
          'onMessageGuideTap: () =>\n                _showSoon(l10n.tourDetailsGuideChatComingSoon)',
        ),
      ),
    );
  });

  test('tour details opens own offer editor for author guide', () async {
    final source = await File(
      'lib/screens/tours/tour_details_screen.dart',
    ).readAsString();
    final routerSource = await File(
      'lib/core/router/app_router.dart',
    ).readAsString();

    expect(source, contains('_openEditOffer'));
    expect(source, contains('legacyTourId'));
    expect(
      source,
      contains("'/tours/\${Uri.encodeComponent(legacyTourId)}/edit'"),
    );
    expect(source, contains('onEditOfferTap'));
    expect(routerSource, contains("path: '/tours/:tourId/edit'"));
    expect(routerSource, contains('CreateTourScreen('));
    expect(routerSource, contains("location.endsWith('/edit')"));
  });

  test('tour details hides footer price for guide offer editing', () async {
    final source = await File(
      'lib/screens/tours/tour_details_screen.dart',
    ).readAsString();

    expect(
      source,
      contains('showPrice: showCheckoutPrice && showBookingAction'),
    );
    expect(source, contains('required this.showPrice'));
    expect(source, contains('final bool showPrice'));
    expect(source, contains('if (showPrice) ...['));
  });

  test('tour details hides footer price for any guide user role', () async {
    final source = await File(
      'lib/screens/tours/tour_details_screen.dart',
    ).readAsString();

    expect(source, contains('final isCurrentUserGuide'));
    expect(source, contains("role.trim().toUpperCase() == 'GUIDE'"));
    expect(source, contains('showCheckoutPrice:'));
    expect(
      source,
      contains('!isCurrentUserGuide && !isAuthor && hasBookableOffer'),
    );
    expect(
      source,
      contains('showPrice: showCheckoutPrice && showBookingAction'),
    );
  });

  test(
    'tour details offers list is searchable filterable sortable and paginated',
    () async {
      final source = await File(
        'lib/screens/tours/tour_details_screen.dart',
      ).readAsString();
      final apiSource = await File(
        'lib/core/network/tour_api.dart',
      ).readAsString();

      expect(source, contains('class _TourOffersSectionState'));
      expect(source, contains('_offerSearchController'));
      expect(source, contains('_TourOffersSearchField'));
      expect(source, contains('_visibleOffers'));
      expect(
        source,
        contains("import '../../features/tours/tour_search.dart';"),
      );
      expect(source, contains('tourSearchNeedleGroups'));
      expect(source, contains('variants.any(haystack.contains)'));
      expect(source, contains('_offerSearchHaystack'));
      expect(source, contains('_normalizeOfferSearchText'));
      expect(source, contains('_queryMatchesResolvedGuideProfile'));
      expect(source, contains('localizedTourLanguageLabel(l10n, code)'));
      expect(source, contains('profile.displayName'));
      expect(source, contains('profile.primaryPhone'));
      expect(source, contains('_TourOffersFilterSheet'));
      expect(source, contains('_languageSearchController'));
      expect(source, contains('_visibleLanguages'));
      expect(source, contains('_languageSearchHaystack'));
      expect(source, contains('tourDetailsOffersLanguageSearchHint'));
      expect(source, contains('tourDetailsOffersLanguageNoResults'));
      expect(source, contains('selectedLanguage ??'));
      expect(source, contains('tourDetailsOffersLanguageAny'));
      expect(source, contains('_TourOffersSortBar'));
      expect(source, contains('_TourOfferSortMode.rating'));
      expect(source, contains('_TourOfferSortMode.experience'));
      expect(source, contains('_TourOfferSortMode.price'));
      expect(source, contains('_TourOfferSortDirection'));
      expect(source, contains('_toggleSortDirection'));
      expect(source, contains('sortDirection: _sortDirection.apiValue'));
      expect(source, isNot(contains('_TourOfferSortMode.priceAsc')));
      expect(source, isNot(contains('_TourOfferSortMode.priceDesc')));
      expect(source, contains('_loadMoreOffers'));
      expect(source, contains('tourDetailsOffersLoadMore'));
      expect(source, contains('preferredGuideUserId'));
      expect(apiSource, contains('Future<TourOffersPage> getTourOffers'));
    },
  );

  test('tour details uses real interactive map for meeting point', () async {
    final source = await File(
      'lib/screens/tours/tour_details_screen.dart',
    ).readAsString();

    expect(source, contains("import 'package:flutter_map/flutter_map.dart';"));
    expect(source, contains("import 'package:latlong2/latlong.dart'"));
    expect(source, contains('FlutterMap('));
    expect(source, contains('TileLayer('));
    expect(source, contains('MarkerLayer('));
    expect(source, contains('LatLng('));
    expect(source, contains('tour.latitude'));
    expect(source, contains('tour.longitude'));
    expect(source, contains('InteractiveFlag.all'));
    expect(source, isNot(contains('class _MapPreviewPainter')));
    expect(
      source,
      isNot(contains('CustomPaint(painter: const _MapPreviewPainter())')),
    );
  });

  test(
    'tour details resolves localized attraction text for landmark tours',
    () async {
      final source = await File(
        'lib/screens/tours/tour_details_screen.dart',
      ).readAsString();

      expect(
        source,
        contains(
          "import '../../features/attractions/data/attraction_api.dart';",
        ),
      );
      expect(
        source,
        contains(
          "import '../../features/attractions/models/attraction_vm.dart';",
        ),
      );
      expect(source, contains('final AttractionApi _attractionApi'));
      expect(source, contains('AttractionVm? _localizedLandmark'));
      expect(source, contains('_loadLocalizedLandmark'));
      expect(source, contains('locale: lang'));
      expect(source, contains('localizedLandmark:'));
      expect(source, contains('localizedTourTitle('));
      expect(source, contains('localizedTourDescription('));
    },
  );

  test(
    'tour details pins current guide offer and hides profile action for it',
    () async {
      final source = await File(
        'lib/screens/tours/tour_details_screen.dart',
      ).readAsString();

      expect(source, contains('_prioritizeCurrentGuideOffer'));
      expect(source, contains('isCurrentUserOffer'));
      expect(source, contains('tourDetailsOfferCurrentUser'));
      expect(source, contains('onProfileTap: isCurrentUserOffer'));
    },
  );

  test(
    'tour details refreshes empty stale offer lists and keeps itinerary text visible',
    () async {
      final source = await File(
        'lib/screens/tours/tour_details_screen.dart',
      ).readAsString();

      expect(source, contains('_shouldRefreshOffersAfterWidgetUpdate'));
      expect(source, contains('widget.offers.isEmpty'));
      expect(source, contains('widget.tour.publishedOffersCount > 0'));
      expect(source, contains('if (title.isNotEmpty) return title;'));
      expect(
        source,
        contains('if (description.isNotEmpty) return description;'),
      );
      expect(
        source,
        isNot(contains('_isTextCompatibleWithLocale(title, languageCode)')),
      );
      expect(
        source,
        isNot(
          contains('_isTextCompatibleWithLocale(description, languageCode)'),
        ),
      );
    },
  );
}
