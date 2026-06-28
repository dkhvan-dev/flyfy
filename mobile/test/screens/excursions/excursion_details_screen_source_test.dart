import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('excursion details screen follows the reference structure', () async {
    final source = await File(
      'lib/screens/excursions/excursion_details_screen.dart',
    ).readAsString();

    expect(source, contains('class ExcursionDetailsScreen'));
    expect(source, contains('initialExcursion'));
    expect(source, contains('loadExcursionDetails'));
    expect(source, contains('ExcursionDetailsContent'));
    expect(source, contains('_ExcursionHero'));
    expect(source, contains('_ExcursionStatsGrid'));
    expect(source, contains('_ExcursionExperienceSection'));
    expect(source, contains('_ExcursionSelectedOfferIncludedSection'));
    expect(source, contains('_ExcursionMapPreview'));
    expect(source, contains('_ExcursionItinerarySection'));
    expect(source, contains('_ExcursionCheckoutBar'));
    expect(source, contains('SingleChildScrollView'));
    expect(source, contains('MediaQuery.paddingOf(context).bottom'));
  });

  test(
    'router exposes public excursion details without opening create route',
    () async {
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();

      expect(routerSource, contains("path: '/excursions/:excursionId'"));
      expect(routerSource, contains('ExcursionDetailsScreen'));
      expect(routerSource, contains("location.startsWith('/excursions/')"));
      expect(
        routerSource,
        contains("location.startsWith('/excursions/create')"),
      );
      expect(routerSource, contains('return false;'));
    },
  );

  test(
    'excursions list opens details with cached excursion as route extra',
    () async {
      final listSource = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();

      expect(listSource, contains("_openExcursionDetails"));
      expect(listSource, contains("context.push('/excursions/"));
      expect(listSource, contains('extra: excursion'));
    },
  );

  test(
    'excursion details displays localized language names instead of codes',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();
      final localizationSource = await File(
        'lib/features/excursions/excursion_localization.dart',
      ).readAsString();

      expect(source, contains('_formatLanguageLabels'));
      expect(localizationSource, contains('localizedExcursionLanguageLabel'));
      expect(localizationSource, contains('excursionLanguageEnglish'));
      expect(localizationSource, contains('excursionLanguageRussian'));
      expect(localizationSource, contains('excursionLanguageKazakh'));
      expect(source, isNot(contains("join(', ').toUpperCase()")));
    },
  );

  test('excursion details displays every selected offer language', () async {
    final source = await File(
      'lib/screens/excursions/excursion_details_screen.dart',
    ).readAsString();
    final localizationSource = await File(
      'lib/features/excursions/excursion_localization.dart',
    ).readAsString();

    expect(source, contains('_ExcursionStatsGrid('));
    expect(source, contains('selectedOffer: activeSelectedOffer'));
    expect(source, contains('selectedOffer?.languageCodes'));
    expect(
      source,
      contains('_formatLanguageLabels(l10n, offer.languageCodes)'),
    );
    expect(localizationSource, contains('int? maxItems'));
    expect(localizationSource, contains('maxItems == null'));
    expect(localizationSource, isNot(contains('int maxItems = 2')));
  });

  test('excursion details does not truncate language labels', () async {
    final source = await File(
      'lib/screens/excursions/excursion_details_screen.dart',
    ).readAsString();

    expect(source, contains('allowMultiline: true'));
    expect(source, contains('maxLines: data.allowMultiline ? null : 2'));
    expect(source, contains('overflow: data.allowMultiline'));
    expect(source, contains('? TextOverflow.visible'));
    expect(source, contains('maxLines: allowMultiline ? null : 1'));
  });

  test(
    'excursion details links description section to place details',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(source, contains('_openLandmarkDetails'));
      expect(source, contains('context.push('));
      expect(source, contains("'/places/\${Uri.encodeComponent(landmarkId)}'"));
      expect(source, contains('extra: localizedLandmark'));
      expect(source, contains('actionLabel:'));
      expect(source, contains('l10n.detailsButton'));
      expect(source, contains('AppPalette.primary'));
    },
  );

  test(
    'excursion details resolves guide profile and hides guide chat for author',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(source, contains('ProfileApi'));
      expect(source, contains('UserProfileVm'));
      expect(source, contains('_resolveGuideProfile'));
      expect(source, contains('getPublicUserById(guideUserId)'));
      expect(source, contains('excursion.guideUserId'));
      expect(source, contains('context.push('));
      expect(source, contains("'/users/\$guideUserId/profile'"));
      expect(source, contains('_formatGuideFullName'));
      expect(source, contains("return '\$lastName \${firstName[0]}.';"));
      expect(source, isNot(contains('_formatGuideSurnameInitials')));
      expect(source, contains('showMessageGuide: !isAuthor'));
      expect(source, contains('showMessageGuide'));
      expect(source, isNot(contains('l10n.excursionDetailsGuideName,')));
      expect(source, isNot(contains('bool canFetch')));
      expect(source, isNot(contains('if (!canFetch)')));
      expect(source, isNot(contains('session.isAuthenticated')));
    },
  );

  test(
    'excursion details keeps offer inclusions scoped to selected guide',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();
      final modelSource = await File(
        'lib/features/excursions/models/excursion_vm.dart',
      ).readAsString();

      expect(source, contains('_ExcursionSelectedOfferIncludedSection'));
      expect(source, contains('selectedOffer.localizedIncludedItems'));
      expect(source, isNot(contains('_ExcursionGuideAndMapSection')));
      expect(
        modelSource,
        isNot(contains('primaryOffer?.includedItems ?? const []')),
      );
    },
  );

  test(
    'excursion details resolves cover file id and hides booking for author',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(
        source,
        contains(
          "import '../../features/excursions/excursion_cover_url.dart';",
        ),
      );
      expect(source, contains('resolveExcursionCoverUrl(excursion)'));
      expect(
        source,
        contains('!isAuthor && hasBookableOffer && hasAvailableSchedule'),
      );
      expect(source, contains('showEditOfferAction'));
      expect(source, contains('showBottomBookingNotice'));
      expect(source, contains('class _ExcursionCheckoutBar'));
    },
  );

  test(
    'excursion details checks selected guide schedule before booking CTA',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(source, contains('_scheduleLoadSelectedOfferAvailability'));
      expect(source, contains('loadBookableExcursionSchedule'));
      expect(source, contains('selectedOfferScheduleKey'));
      expect(source, contains('bookingUnavailableMessage'));
      expect(source, contains('excursionDetailsNoAvailableSlots'));
      expect(source, contains('excursionDetailsCheckingSchedule'));
      expect(source, contains('excursionDetailsBookingSeatCheckNote'));
      expect(source, contains('helperText: showBookingAction'));
    },
  );

  test(
    'excursion details reads route-scoped details instead of global selection',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('provider.excursionDetailsFor(widget.excursionId)'),
      );
      expect(
        source,
        contains('provider.isDetailLoadingFor(widget.excursionId)'),
      );
      expect(source, contains('provider.isDetailErrorFor(widget.excursionId)'));
      expect(
        source,
        isNot(contains('final excursion = provider.selectedExcursion;')),
      );
    },
  );

  test('excursion details opens booking screen from booking CTA', () async {
    final source = await File(
      'lib/screens/excursions/excursion_details_screen.dart',
    ).readAsString();

    expect(source, contains('_openBooking'));
    expect(source, contains('ExcursionBookingRouteArgs'));
    expect(
      source,
      contains("'/excursions/\${Uri.encodeComponent(excursion.id)}/booking'"),
    );
    expect(
      source,
      contains('onBookTap: () => _openBooking(excursion, selectedOffer)'),
    );
    expect(source, contains('selectedOfferId: selectedOffer?.id'));
    expect(
      source,
      isNot(
        contains(
          'onBookTap: () => _showSoon(l10n.excursionDetailsBookingComingSoon)',
        ),
      ),
    );
  });

  test(
    'excursion details checklist and booking CTAs use primary text chevron actions',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();
      final ctaSource = await File(
        'lib/shared/widgets/trip_preparation_cta.dart',
      ).readAsString();

      expect(source, contains('TripPreparationCta('));
      expect(ctaSource, contains('Icons.chevron_right_rounded'));
      expect(ctaSource, contains('iconAlignment: IconAlignment.end'));
      expect(ctaSource, contains('foregroundColor: AppPalette.textPrimary'));

      final bottomActionStart = source.indexOf('final bottomAction =');
      final contentStart = source.indexOf(
        'return DecoratedBox(',
        bottomActionStart,
      );
      expect(bottomActionStart, isNonNegative);
      expect(contentStart, greaterThan(bottomActionStart));

      final bottomActionSource = source.substring(
        bottomActionStart,
        contentStart,
      );
      expect(bottomActionSource, contains(': l10n.excursionDetailsBook'));
      expect(bottomActionSource, contains(': Icons.chevron_right_rounded'));
      expect(
        bottomActionSource,
        isNot(contains('Icons.arrow_forward_ios_rounded')),
      );

      final checkoutStart = source.indexOf('class _ExcursionCheckoutBar');
      final loadingStart = source.indexOf(
        'class _ExcursionDetailsLoading',
        checkoutStart,
      );
      expect(checkoutStart, isNonNegative);
      expect(loadingStart, greaterThan(checkoutStart));

      final checkoutSource = source.substring(checkoutStart, loadingStart);
      expect(
        checkoutSource,
        contains('foregroundColor: AppPalette.textPrimary'),
      );
      expect(checkoutSource, contains('iconAlignment: IconAlignment.end'));
    },
  );

  test(
    'excursion details keeps checklist preview public but full checklist booking scoped',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(source, contains('loadMyExcursionBookings()'));
      expect(source, contains('_activeExcursionChecklistBooking('));
      expect(
        source,
        contains('activeChecklistBooking: activeChecklistBooking'),
      );
      expect(source, contains('onFullChecklistTap: () => context.push('));
      expect(
        source,
        contains('TravelChecklistRouteArgs.fromExcursionBooking('),
      );
      expect(
        source,
        contains('TravelChecklistRouteArgs.fromExcursionPreview('),
      );
      expect(source, isNot(contains('_ExcursionChecklistPreviewSheet')));
      expect(source, contains('travelChecklistPreviewAction'));
      expect(source, contains('activeChecklistBooking == null'));
      expect(source, contains('actionLabel: activeChecklistBooking == null'));
      expect(source, contains('onTap: activeChecklistBooking == null'));
      expect(source, isNot(contains("tripId: 'excursion:\$excursionId'")));
    },
  );

  test(
    'excursion details creates direct chat with guide from message CTA',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
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
            'onMessageGuideTap: () =>\n                _showSoon(l10n.excursionDetailsGuideChatComingSoon)',
          ),
        ),
      );
    },
  );

  test('excursion details opens own offer editor for author guide', () async {
    final source = await File(
      'lib/screens/excursions/excursion_details_screen.dart',
    ).readAsString();
    final routerSource = await File(
      'lib/core/router/app_router.dart',
    ).readAsString();

    expect(source, contains('_openEditOffer'));
    expect(source, contains('legacyExcursionId'));
    expect(
      source,
      contains("'/excursions/\${Uri.encodeComponent(legacyExcursionId)}/edit'"),
    );
    expect(source, contains('onEditOfferTap'));
    expect(routerSource, contains("path: '/excursions/:excursionId/edit'"));
    expect(routerSource, contains('CreateExcursionScreen('));
    expect(routerSource, contains("location.endsWith('/edit')"));
  });

  test(
    'excursion details hides footer price for guide offer editing',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('showPrice: showCheckoutPrice && showBookingAction'),
      );
      expect(source, contains('required this.showPrice'));
      expect(source, contains('final bool showPrice'));
      expect(source, contains('if (showPrice) ...['));
    },
  );

  test(
    'excursion details hides footer price for any guide user role',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
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
    },
  );

  test(
    'excursion details offers list is searchable filterable sortable and paginated',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();
      final apiSource = await File(
        'lib/core/network/excursion_api.dart',
      ).readAsString();

      expect(source, contains('class _ExcursionOffersSectionState'));
      expect(source, contains('_offerSearchController'));
      expect(source, contains('_ExcursionOffersSearchField'));
      expect(source, contains('_visibleOffers'));
      expect(
        source,
        contains("import '../../features/excursions/excursion_search.dart';"),
      );
      expect(source, contains('excursionSearchNeedleGroups'));
      expect(source, contains('variants.any(haystack.contains)'));
      expect(source, contains('_offerSearchHaystack'));
      expect(source, contains('_normalizeOfferSearchText'));
      expect(source, contains('_queryMatchesResolvedGuideProfile'));
      expect(source, contains('localizedExcursionLanguageLabel(l10n, code)'));
      expect(source, contains('profile.nickname'));
      expect(source, contains('profile.primaryPhone'));
      expect(source, contains('_ExcursionOffersFilterSheet'));
      expect(source, contains('availableDate'));
      expect(source, contains('loadBookableExcursionSchedule'));
      expect(source, contains('_offerHasBookableSlotOnDate'));
      expect(source, contains('excursionDetailsOffersAvailableDate'));
      expect(source, contains('excursionDetailsOffersAvailableDateHint'));
      expect(source, contains('_languageSearchController'));
      expect(source, contains('_visibleLanguages'));
      expect(source, contains('_languageSearchHaystack'));
      expect(source, contains('excursionDetailsOffersLanguageSearchHint'));
      expect(source, contains('excursionDetailsOffersLanguageNoResults'));
      expect(source, contains('selectedLanguage ??'));
      expect(source, contains('excursionDetailsOffersLanguageAny'));
      expect(source, contains('_ExcursionOffersSortBar'));
      expect(source, contains('_ExcursionOfferSortMode.rating'));
      expect(source, contains('_ExcursionOfferSortMode.experience'));
      expect(source, contains('_ExcursionOfferSortMode.price'));
      expect(source, contains('_ExcursionOfferSortDirection'));
      expect(source, contains('_toggleSortDirection'));
      expect(source, contains('sortDirection: _sortDirection.apiValue'));
      expect(source, isNot(contains('_ExcursionOfferSortMode.priceAsc')));
      expect(source, isNot(contains('_ExcursionOfferSortMode.priceDesc')));
      expect(source, contains('_loadMoreOffers'));
      expect(source, contains('excursionDetailsOffersLoadMore'));
      expect(source, contains('preferredGuideUserId'));
      expect(
        apiSource,
        contains('Future<ExcursionOffersPage> getExcursionOffers'),
      );
    },
  );

  test(
    'excursion details uses shared MapLibre map for meeting point',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../shared/widgets/app_map_card.dart';"),
      );
      expect(source, contains("import 'package:latlong2/latlong.dart'"));
      expect(source, contains('AppMapCard('));
      expect(source, contains('hasMarker: true'));
      expect(source, contains('LatLng('));
      expect(source, contains('excursion.latitude'));
      expect(source, contains('excursion.longitude'));
      expect(source, isNot(contains("package:flutter_map/flutter_map.dart")));
      expect(source, isNot(contains('FlutterMap(')));
      expect(source, isNot(contains('TileLayer(')));
      expect(source, isNot(contains('MarkerLayer(')));
      expect(source, isNot(contains('tile.openstreetmap.org')));
      expect(source, isNot(contains('InteractiveFlag.all')));
      expect(source, isNot(contains('class _MapPreviewPainter')));
      expect(
        source,
        isNot(contains('CustomPaint(painter: const _MapPreviewPainter())')),
      );
    },
  );

  test(
    'excursion details meeting map disables native preview on mobile',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      final helperStart = source.indexOf(
        'bool _shouldUseNativeReadOnlyExcursionMap',
      );
      expect(helperStart, isNonNegative);
      final helperEnd = source.indexOf('class ', helperStart);
      expect(helperEnd, greaterThan(helperStart));

      final helperSource = source.substring(helperStart, helperEnd);
      expect(helperSource, contains('TargetPlatform.iOS'));
      expect(helperSource, contains('TargetPlatform.android'));
      expect(helperSource, contains('Theme.of(context).platform'));

      final mapPreviewStart = source.indexOf('class _ExcursionMapPreview');
      final nextClassStart = source.indexOf('class ', mapPreviewStart + 1);
      expect(mapPreviewStart, isNonNegative);
      expect(nextClassStart, greaterThan(mapPreviewStart));

      final mapPreviewSource = source.substring(
        mapPreviewStart,
        nextClassStart,
      );
      expect(mapPreviewSource, contains('nativeMapEnabled:'));
      expect(
        mapPreviewSource,
        contains('_shouldUseNativeReadOnlyExcursionMap(context)'),
      );
    },
  );

  test(
    'excursion details keeps itinerary textual but routes to meeting point',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(source, contains('_ExcursionMapPreview('));
      expect(source, contains('_ExcursionItinerarySection('));
      expect(source, contains('title: l10n.excursionDetailsItinerary'));
      expect(
        source,
        contains("import '../../features/routing/models/routing_models.dart';"),
      );
      expect(
        source,
        contains("import '../../providers/routing_provider.dart';"),
      );
      expect(source, contains("import '../map/map_screen.dart';"));
      expect(source, contains('bool _isBuildingExcursionRoute'));
      expect(source, contains('Future<void> _openExcursionRoutePreview'));
      expect(source, contains('context.read<RoutingProvider>()'));
      expect(source, contains('RouteRequestVm('));
      expect(source, contains('RouteProfile.touristWalk'));
      expect(source, contains('MapRoutePreview('));
      expect(source, isNot(contains('routePoints: routePoints')));
      expect(source, contains("context.push('/map', extra: routePreview)"));
      expect(source, contains('onRoutePreviewTap'));
      expect(source, contains('isBuildingRoute'));
    },
  );

  test(
    'excursion details resolves localized place text for landmark excursions',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../features/places/data/place_api.dart';"),
      );
      expect(
        source,
        contains("import '../../features/places/models/place_vm.dart';"),
      );
      expect(source, contains('final PlaceApi _placeApi'));
      expect(source, contains('PlaceVm? _localizedLandmark'));
      expect(source, contains('_loadLocalizedLandmark'));
      expect(source, contains('locale: lang'));
      expect(source, contains('localizedLandmark:'));
      expect(source, contains('localizedExcursionTitle('));
      expect(source, contains('localizedExcursionDescription('));
    },
  );

  test(
    'excursion details pins current guide offer and hides profile action for it',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(source, contains('_prioritizeCurrentGuideOffer'));
      expect(source, contains('isCurrentUserOffer'));
      expect(source, contains('excursionDetailsOfferCurrentUser'));
      expect(source, contains('onProfileTap: isCurrentUserOffer'));
    },
  );

  test(
    'excursion details lets authors manage their reviews from long press',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(source, contains('showExcursionReviewActionsSheet('));
      expect(source, contains('showExcursionReviewEditSheet('));
      expect(source, contains('_openExcursionReviewActions'));
      expect(source, contains('onLongPress:'));
      expect(source, contains('review.author.userId'));
      expect(source, contains('saveExcursionReview('));
      expect(source, contains('deleteExcursionReview('));
    },
  );

  test(
    'excursion details refreshes empty stale offer lists and keeps itinerary text visible',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(source, contains('_shouldRefreshOffersAfterWidgetUpdate'));
      expect(source, contains('widget.offers.isEmpty'));
      expect(source, contains('widget.excursion.publishedOffersCount > 0'));
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

  test(
    'excursion details timeline displays combined route stop metadata',
    () async {
      final source = await File(
        'lib/screens/excursions/excursion_details_screen.dart',
      ).readAsString();

      expect(source, contains("excursion.routeKind == 'COMBINED_ROUTE'"));
      expect(source, contains('excursion.stopCount > 1'));
      expect(source, contains('excursionDetailsRouteStopsCount'));
      expect(source, contains('step.placeName'));
      expect(source, contains('step.travelFromPreviousMinutes'));
      expect(source, contains('excursionDetailsTravelFromPrevious'));
      expect(source, contains('class _RouteStopMetaChip'));
      expect(source, contains('Wrap('));
    },
  );
}
