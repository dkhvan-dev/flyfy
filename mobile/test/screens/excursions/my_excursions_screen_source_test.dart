import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('my excursions screen uses adaptive V2 colors only', () async {
    final source = await File(
      'lib/screens/excursions/my_excursions_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('myExcursionsColors.primary'));
    expect(source, contains('myExcursionsColors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'my excursions empty state suggests changing city filter when city is active',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();
      final enSource = await File('lib/l10n/app_en.arb').readAsString();
      final ruSource = await File('lib/l10n/app_ru.arb').readAsString();
      final kkSource = await File('lib/l10n/app_kk.arb').readAsString();

      expect(source, contains('_myExcursionsEmptyMessage'));
      expect(source, contains('l10n.cityFilterEmptyHint'));
      expect(source, contains('_filters.city'));
      expect(enSource, contains('"cityFilterEmptyHint"'));
      expect(ruSource, contains('"cityFilterEmptyHint"'));
      expect(kkSource, contains('"cityFilterEmptyHint"'));
    },
  );

  test(
    'my excursions screen uses shared list chrome and paginated tabs',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();

      expect(source, contains('class MyExcursionsScreen'));
      expect(
        source,
        contains("import '../../core/ui/app_list_screen_header.dart';"),
      );
      expect(
        source,
        contains("import '../../core/ui/app_list_search_field.dart';"),
      );
      expect(
        source,
        contains("import '../../core/ui/app_inline_sort_row.dart';"),
      );
      expect(
        source,
        contains("import '../../core/ui/filter_sheet_chrome.dart';"),
      );
      expect(source, contains("import '../../core/ui/pagination_bar.dart';"));
      expect(source, contains('MyExcursionsTab.booked'));
      expect(source, contains('MyExcursionsTab.visited'));
      expect(source, contains('AppListScreenHeader('));
      expect(source, contains('AppListSearchField('));
      expect(source, contains('AppInlineSortRow<MyExcursionBookingSortMode>'));
      expect(source, contains('showAppModalBottomSheet<_MyExcursionsFilters>'));
      expect(source, contains('InflapPaginationBar('));
    },
  );

  test('my excursions tabs have visible V2 borders', () async {
    final source = await File(
      'lib/screens/excursions/my_excursions_screen.dart',
    ).readAsString();

    final switcherStart = source.indexOf('class _MyExcursionsTabSwitcher');
    final segmentStart = source.indexOf('class _SegmentButton');
    final cardStart = source.indexOf('class _MyExcursionBookingCard');
    expect(switcherStart, isNonNegative);
    expect(segmentStart, greaterThan(switcherStart));
    expect(cardStart, greaterThan(segmentStart));

    final switcherSource = source.substring(switcherStart, segmentStart);
    final segmentSource = source.substring(segmentStart, cardStart);

    expect(source, contains('Color get borderSoft => colors.borderSoft;'));
    expect(
      source,
      contains('Color get borderPrimary => colors.borderPrimary;'),
    );
    expect(
      switcherSource,
      contains('border: Border.all(color: colors.borderSoft)'),
    );
    expect(segmentSource, contains('side: BorderSide('));
    expect(segmentSource, contains('colors.borderPrimary'));
  });

  test('my excursions screen does not duplicate guide offer drafts', () async {
    final source = await File(
      'lib/screens/excursions/my_excursions_screen.dart',
    ).readAsString();

    expect(
      source,
      isNot(
        contains("import '../../features/excursions/guide_offer_status.dart';"),
      ),
    );
    expect(source, isNot(contains('_hasRequestedGuideOffersPreview')));
    expect(source, isNot(contains('session.profile?.isGuide == true')));
    expect(source, isNot(contains('loadGuideDashboardData')));
    expect(source, isNot(contains('draftGuideOffers(')));
    expect(source, isNot(contains('reviewGuideOffers(')));
    expect(source, isNot(contains('class _MyExcursionsGuideOfferOverview')));
    expect(source, isNot(contains('myExcursionsGuideOffersTitle')));
    expect(source, isNot(contains('myExcursionsGuideOffersSubtitle')));
    expect(source, isNot(contains('myExcursionsGuideOffersOpenDashboard')));
    expect(source, isNot(contains('editableGuideExcursionId(excursion)')));
    expect(source, isNot(contains("context.push('/profile/guide-dashboard')")));
  });

  test(
    'my excursions screen exposes review action for unrated visits',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();

      expect(source, contains('booking.canReview'));
      expect(source, contains('myExcursionsReviewButton'));
      expect(source, contains('class _ExcursionReviewSheet'));
      expect(source, contains('saveBookingReviews('));
      expect(source, contains('loadExcursionReviews('));
    },
  );

  test(
    'review sheet manages excursion and optional guide reviews together',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();

      expect(source, contains('saveBookingReviews('));
      expect(source, contains('deleteExcursionReview('));
      expect(source, contains('deleteGuideReview('));
      expect(source, contains('class _CombinedReviewDraft'));
      expect(source, contains('class _ReviewSectionCard'));
      expect(source, contains('myExcursionsExcursionReviewSectionTitle'));
      expect(source, contains('myExcursionsGuideReviewSectionTitle'));
      expect(source, contains('booking.guideReview'));
      expect(source, contains('AppModalDraggableSheet'));
      expect(source, contains('MediaQuery.viewInsetsOf(context).bottom'));
    },
  );

  test(
    'review sheet lets tourist choose excursion and guide review sections',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();
      final ruSource = await File('lib/l10n/app_ru.arb').readAsString();

      expect(source, contains('late bool _includeExcursionReview'));
      expect(source, contains('excursion: _includeExcursionReview'));
      expect(source, contains('guide: _includeGuideReview'));
      expect(source, contains('myExcursionsExcursionReviewOptional'));
      expect(source, contains('myExcursionsReviewSelectOneError'));
      expect(ruSource, contains('"myExcursionsExcursionReviewOptional"'));
      expect(ruSource, contains('"myExcursionsReviewSelectOneError"'));
    },
  );

  test(
    'review sheet allows rating-only reviews and keeps delete actions scoped',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();

      expect(source, contains('ReviewDraftRequest('));
      expect(source, isNot(contains('myExcursionsReviewCommentError')));
      expect(source, contains('myExcursionsReviewDeleteExcursion'));
      expect(source, contains('myExcursionsReviewDeleteGuide'));
      expect(source, contains('_deleteExcursionReview'));
      expect(source, contains('_deleteGuideReview'));
    },
  );

  test('visited review badge does not force unwrap excursion review', () async {
    final source = await File(
      'lib/screens/excursions/my_excursions_screen.dart',
    ).readAsString();

    expect(source, isNot(contains('booking.review!.rating')));
    expect(source, contains('booking.reviewBadgeRating'));
  });

  test(
    'my excursions cards resolve localized place text for landmark bookings',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();

      expect(source, contains('dart:async'));
      expect(
        source,
        contains("import '../../features/places/data/place_api.dart';"),
      );
      expect(
        source,
        contains("import '../../features/places/models/place_vm.dart';"),
      );
      expect(
        source,
        contains(
          "import '../../features/excursions/excursion_localization.dart';",
        ),
      );
      expect(source, contains('final PlaceApi _placeApi'));
      expect(source, contains('Map<String, PlaceVm> _localizedLandmarks'));
      expect(source, contains('_scheduleResolveLocalizedLandmarks'));
      expect(source, contains('_loadLocalizedLandmark'));
      expect(source, contains('locale: lang'));
      expect(source, contains('localizedLandmark:'));
      expect(source, contains('localizedPlaceTitle('));
      expect(source, contains('final displayTitle = localizedPlaceTitle('));
      expect(source, contains('final landmarkName = localizedPlaceTitle('));
      expect(source, contains('displayTitle.isEmpty'));
      expect(source, isNot(contains('booking.landmarkName!.trim()')));
      expect(
        source,
        isNot(
          contains(
            'booking.title.isEmpty\n'
            '                              ? l10n.myExcursionsUntitled\n'
            '                              : booking.title',
          ),
        ),
      );
    },
  );

  test(
    'my excursions filter uses activity-style manual date range and excursion result label',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();

      expect(source, contains('TextEditingController _startDateController'));
      expect(source, contains('TextEditingController _endDateController'));
      expect(source, contains('class _FilterDateField'));
      expect(source, contains('class _DateTextInputFormatter'));
      expect(source, contains('myActivitiesFilterInvalidDate'));
      expect(source, contains('myActivitiesFilterInvalidRange'));
      expect(source, contains('excursionsFiltersShowResults('));
      expect(source, contains('previewCount'));
      expect(source, isNot(contains('activitiesShowResults(previewCount)')));
      expect(source, isNot(contains('showDatePicker(')));
      expect(source, isNot(contains('class _DateButton')));
    },
  );

  test(
    'my excursions filter pills keep visible selected and unselected borders',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();

      final pillStart = source.indexOf('class _ChoicePill');
      final dateFieldStart = source.indexOf('class _FilterDateField');
      expect(pillStart, isNonNegative);
      expect(dateFieldStart, greaterThan(pillStart));

      final pillSource = source.substring(pillStart, dateFieldStart);

      expect(
        pillSource,
        contains('final colors = context.myExcursionsColors;'),
      );
      expect(pillSource, contains('selectedColor: colors.primary'));
      expect(pillSource, contains('backgroundColor: colors.surfaceRaised'));
      expect(pillSource, contains('checkmarkColor: colors.textPrimary'));
      expect(pillSource, contains('color: selected ? colors.textPrimary'));
      expect(pillSource, contains('color: selected ? colors.borderPrimary'));
      expect(pillSource, contains('width: selected ? 1.4 : 1'));
      expect(pillSource, isNot(contains('white.withValues(alpha: 0.06)')));
    },
  );

  test(
    'my excursions filter starts with current-location city filter',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../providers/home_location_provider.dart';"),
      );
      expect(
        source,
        contains("import '../../shared/widgets/app_city_filter_section.dart';"),
      );
      expect(
        source,
        contains(
          "import '../../shared/location/home_location_filter_defaults.dart';",
        ),
      );
      expect(source, contains('HomeLocationProvider'));
      expect(source, contains('provider.effectiveLocation'));
      expect(source, contains('HomeLocationFilterDefaults.fromPreference'));
      expect(source, contains('if (!defaults.hasValue) return;'));
      expect(
        source,
        isNot(contains('final location = provider.selectedLocation')),
      );
      expect(source, contains('_initializeDefaultCityFilter'));
      expect(source, contains('_applyDefaultCityFilter'));
      expect(source, contains('final AppCountryFilterValue? country'));
      expect(source, contains('final AppCityFilterValue? city'));
      expect(source, contains('AppCountryFilterSection'));
      expect(source, contains('AppCityFilterSection'));
      expect(source, contains('placeFilterCountrySection'));
      expect(source, contains('placeFilterCountryAll'));
      expect(source, contains('placeFilterCountrySearchHint'));
      expect(source, contains('placeFilterCountryNoResults'));
      expect(source, contains('locationFilterCitySection'));
      expect(source, contains('filters.city'));
      expect(source, contains('filters.country'));
      expect(source, contains('booking.cityName'));
      expect(source, contains('countryCode: booking.countryCode'));
      expect(source, isNot(contains('profile?.countryCode')));
    },
  );

  test(
    'my excursions city filter is compact and searchable through shared selector',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();

      expect(source, contains('AppCityFilterSection'));
      expect(source, contains('_setCountry(AppCountryFilterValue? country)'));
      expect(source, contains('_city = null'));
      expect(source, contains('locationFilterCitySearchHint'));
      expect(source, contains('locationFilterCityNoResults'));
      expect(source, isNot(contains('_countrySearchController')));
      expect(source, isNot(contains('_selectedCountry()')));
      expect(source, isNot(contains('_visibleCountries')));

      final countrySectionStart = source.indexOf('AppCountryFilterSection(');
      final citySectionStart = source.indexOf('AppCityFilterSection(');
      final statusSectionStart = source.indexOf(
        'widget.l10n.myExcursionsFilterStatus',
      );
      expect(countrySectionStart, isNonNegative);
      expect(citySectionStart, isNonNegative);
      expect(citySectionStart, greaterThan(countrySectionStart));
      expect(statusSectionStart, greaterThan(citySectionStart));

      final citySection = source.substring(
        citySectionStart,
        statusSectionStart,
      );
      expect(citySection, contains('AppCityFilterSection'));
      expect(citySection, isNot(contains('Wrap(')));
    },
  );

  test(
    'visited my excursions filter sheet hides booking status filters',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();
      final sheetStart = source.indexOf('class _MyExcursionsFilterSheet');
      final sectionTitleStart = source.indexOf('class _FilterSectionTitle');

      expect(sheetStart, isNonNegative);
      expect(sectionTitleStart, greaterThan(sheetStart));

      final sheetSource = source.substring(sheetStart, sectionTitleStart);

      expect(source, contains('tab: _activeTab'));
      expect(sheetSource, contains('final MyExcursionsTab tab;'));
      expect(sheetSource, contains('widget.tab == MyExcursionsTab.booked'));
      expect(
        RegExp(
          r'statuses:\s*widget\.tab == MyExcursionsTab\.booked\s*\?\s*_statuses\s*:\s*const <String>{}',
        ).hasMatch(sheetSource),
        isTrue,
      );
    },
  );

  test('my excursions filter sheet constrains height above keyboard', () async {
    final source = await File(
      'lib/screens/excursions/my_excursions_screen.dart',
    ).readAsString();
    final sheetStart = source.indexOf('class _MyExcursionsFilterSheetState');
    final sectionTitleStart = source.indexOf('class _FilterSectionTitle');

    expect(sheetStart, isNonNegative);
    expect(sectionTitleStart, greaterThan(sheetStart));

    final sheetSource = source.substring(sheetStart, sectionTitleStart);

    expect(sheetSource, contains('final size = MediaQuery.sizeOf(context);'));
    expect(sheetSource, contains('final keyboardInset ='));
    expect(sheetSource, contains('final availableSheetHeight = math.max('));
    expect(sheetSource, contains('size.height -'));
    expect(sheetSource, contains('keyboardInset -'));
    expect(sheetSource, contains('final maxHeight = math.min('));
    expect(sheetSource, contains('AnimatedPadding('));
  });

  test('my excursions filter sheet closes when tapping outside', () async {
    final source = await File(
      'lib/screens/excursions/my_excursions_screen.dart',
    ).readAsString();
    final sheetStart = source.indexOf('class _MyExcursionsFilterSheetState');
    final sectionTitleStart = source.indexOf('class _FilterSectionTitle');

    expect(sheetStart, isNonNegative);
    expect(sectionTitleStart, greaterThan(sheetStart));

    final sheetSource = source.substring(sheetStart, sectionTitleStart);

    expect(sheetSource, contains('AppModalSheetFrame('));
    expect(
      sheetSource,
      contains('onTapOutside: () => Navigator.of(context).maybePop(),'),
    );
  });

  test(
    'router and drawer expose my excursions as authenticated menu item',
    () async {
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();
      final drawerSource = await File(
        'lib/screens/common/app_side_drawer.dart',
      ).readAsString();

      expect(routerSource, contains("path: '/me/excursions'"));
      expect(routerSource, contains('MyExcursionsScreen'));
      expect(routerSource, isNot(contains("location == '/me/excursions'")));
      expect(drawerSource, contains('AppDrawerActiveItem.myExcursions'));
      expect(drawerSource, contains('onMyExcursionsTap'));
      expect(drawerSource, contains('myExcursionsTitle'));
    },
  );

  test(
    'booking edit and cancel sheets use server quotes before mutation',
    () async {
      final source = await File(
        'lib/screens/excursions/my_excursions_screen.dart',
      ).readAsString();
      final ruSource = await File('lib/l10n/app_ru.arb').readAsString();

      expect(source, contains('quoteExcursionBookingGuests'));
      expect(source, contains('quoteExcursionBookingCancellation'));
      expect(source, contains('_loadQuote'));
      expect(source, isNot(contains('_simulateMockSettlement')));
      expect(source, isNot(contains('estimateCancellationRefund')));
      expect(source, contains('formatLocalizedExcursionMoney'));
      expect(source, contains('myExcursionsGuestsAdditionalCharge'));
      expect(source, contains('myExcursionsGuestsRefundDue'));
      expect(source, contains('myExcursionsGuestsNoPaymentChange'));
      expect(source, contains('myExcursionsPayAndSaveGuests'));
      expect(source, contains('myExcursionsRefundAndSaveGuests'));
      expect(ruSource, contains('"myExcursionsGuestsAdditionalCharge"'));
      expect(ruSource, contains('"myExcursionsGuestsRefundDue"'));
      expect(ruSource, contains('"myExcursionsGuestsQuoteFailed"'));
    },
  );
}
