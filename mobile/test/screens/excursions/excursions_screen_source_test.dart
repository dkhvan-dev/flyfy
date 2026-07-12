import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('excursions screen uses adaptive V2 colors only', () async {
    final source = await File(
      'lib/screens/excursions/excursions_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('excursionsColors.primary'));
    expect(source, contains('excursionsColors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test('excursions screen renders the excursions story tray surface', () async {
    final source = await File(
      'lib/screens/excursions/excursions_screen.dart',
    ).readAsString();

    expect(source, contains('SurfaceStoryTray('));
    expect(source, contains("surface: 'excursions'"));
    expect(source, contains('viewerAvatarFileId: profile?.avatarFileId'));
    expect(source, contains('viewerInitials: profile?.initials ??'));
    expect(source, contains('auth.state == AuthState.authenticated'));

    final trayStart = source.indexOf('SurfaceStoryTray(');
    final authGuardStart = source.lastIndexOf(
      'if (isLoggedIn) ...[',
      trayStart,
    );
    expect(authGuardStart, isNonNegative);
    expect(trayStart - authGuardStart, lessThan(180));
  });

  test(
    'excursions screen loads public excursions and guards guide-only creation',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();

      expect(source, contains('class ExcursionsScreen'));
      expect(source, contains('loadExcursions('));
      expect(source, contains('refreshExcursions('));
      expect(source, contains('profile?.isGuide == true'));
      expect(source, contains('ExcursionsBottomNavigation'));
      expect(source, contains('CreateActionBottomNavigationBar'));
      expect(source, contains('CommonBottomNavigationBar'));
      expect(source, contains("context.push('/excursions/create')"));
      expect(source, contains("context.push('/map')"));
    },
  );

  test(
    'excursions screen uses shared sorting, filter chrome, and accent search',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../core/ui/app_inline_sort_row.dart';"),
      );
      expect(
        source,
        contains("import '../../core/ui/app_list_search_field.dart';"),
      );
      expect(
        source,
        contains("import '../../core/ui/filter_sheet_chrome.dart';"),
      );
      expect(source, contains('AppInlineSortRow<_ExcursionsSortMode>'));
      expect(source, contains('excursionsSortLabel'));
      expect(source, contains('_ExcursionsSortMode.createdAt'));
      expect(source, contains('_ExcursionsSortMode.rating'));
      expect(source, contains('_ExcursionsSortMode.price'));
      expect(source, contains('_ExcursionsSortMode.duration'));
      expect(source, contains('excursionsSortCreatedAt'));
      expect(source, contains('excursionsSortRating'));
      expect(source, contains('excursionsSortPrice'));
      expect(source, contains('excursionsSortDuration'));
      expect(source, contains('showAppModalBottomSheet<_ExcursionsFilters>'));
      expect(source, contains('class _ExcursionsFiltersSheet'));
      expect(source, contains('class _ExcursionsFilters'));
      expect(source, contains('AppFilterSheetHeader'));
      expect(source, contains('AppFilterApplyButton'));
      expect(source, contains('AppListSearchField('));
      expect(source, isNot(contains('class _ExcursionsSortTabs')));
      expect(source, isNot(contains('class _ExcursionsFilterOption')));
      expect(source, isNot(contains('_ExcursionsSortMode.popular')));
      expect(source, isNot(contains('_ExcursionsSortMode.affordable')));
    },
  );

  test(
    'excursions filter sheet starts with current-location city filter',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
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
      expect(source, contains('SessionProvider'));
      expect(source, isNot(contains('profile: sessionProvider.profile')));
      expect(source, isNot(contains('provider.shouldSyncProfile(')));
      expect(source, isNot(contains('provider.syncProfileFallback(')));
      expect(source, contains('provider.resolveCityReference('));
      expect(
        source,
        contains('languageCode: Localizations.localeOf(context).languageCode'),
      );
      expect(
        source,
        contains('final location = await provider.resolveCityReference('),
      );
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
      expect(source, contains('countryCode: _filters.country?.countryCode'));
      expect(source, contains('countryCode: _filters.countryCode'));
      expect(source, contains('departureCityId: city?.cityId'));
      expect(source, contains('cityId: excursion.departureCityId'));
      expect(source, contains('excursion.cityName'));
      expect(source, contains('countryCode: excursion.countryCode'));
      expect(source, isNot(contains('profile?.countryCode')));
    },
  );

  test(
    'excursions city filter is compact and searchable through shared selector',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();

      expect(source, contains('AppCityFilterSection'));
      expect(source, contains('_setCountry(AppCountryFilterValue? country)'));
      expect(source, contains('city: null'));
      expect(source, contains('locationFilterCitySearchHint'));
      expect(source, contains('locationFilterCityNoResults'));
      expect(source, isNot(contains('_countrySearchController')));
      expect(source, isNot(contains('_selectedCountry()')));
      expect(source, isNot(contains('_visibleCountries')));

      final countrySectionStart = source.indexOf('AppCountryFilterSection(');
      final citySectionStart = source.indexOf('AppCityFilterSection(');
      final categorySectionStart = source.indexOf(
        'title: l10n.excursionsFilterCategories',
      );
      expect(countrySectionStart, isNonNegative);
      expect(citySectionStart, isNonNegative);
      expect(citySectionStart, greaterThan(countrySectionStart));
      expect(categorySectionStart, greaterThan(citySectionStart));

      final citySection = source.substring(
        citySectionStart,
        categorySectionStart,
      );
      expect(citySection, contains('AppCityFilterSection'));
      expect(citySection, isNot(contains('Wrap(')));
    },
  );

  test(
    'excursions filter sheet refreshes preview count for draft location changes',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();

      expect(
        source,
        contains(
          'final Future<int> Function(_ExcursionsFilters filters) resultCountLoader;',
        ),
      );
      expect(source, contains('Timer? _resultCountDebounce'));
      expect(source, contains('int _resultCountRequestId = 0'));
      expect(source, contains('Future<void> _loadResultCount() async'));
      expect(source, contains('widget.resultCountLoader(filters)'));
      expect(source, contains('_scheduleResultCountLoad'));
      expect(source, contains('void _setCity(AppCityFilterValue? city)'));
      expect(source, contains('onChanged: _setCity'));
      expect(source, contains('isLoading: _isResultCountLoading'));
    },
  );

  test(
    'excursions list search is localized and price filter uses from-to range',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();

      expect(source, contains('_excursionSearchHaystack'));
      expect(source, contains('_normalizeExcursionSearchText'));
      expect(source, contains('_excursionSearchNeedleGroups'));
      expect(source, contains('_latinToCyrillicExcursionSearchText'));
      expect(source, contains('_cyrillicToLatinExcursionSearchText'));
      expect(source, contains('variants.any(haystack.contains)'));
      expect(source, contains('localizedExcursionCategoryLabel(l10n,'));
      expect(source, contains('localizedExcursionLanguageLabel(l10n, code)'));
      expect(source, contains('excursion.includedItems'));
      expect(source, contains('excursion.itinerary'));
      expect(source, contains('_priceFromController'));
      expect(source, contains('_priceToController'));
      expect(source, contains('excursionsFilterPriceFrom'));
      expect(source, contains('excursionsFilterPriceTo'));
      expect(source, contains('priceMin'));
      expect(source, contains('priceMax'));
      expect(source, isNot(contains('_ExcursionsPriceFilter')));
      expect(source, isNot(contains('excursionsFilterBudget')));
      expect(source, isNot(contains('excursionsFilterPremium')));
    },
  );

  test(
    'excursions language filter uses searchable single-select field',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();

      expect(source, contains('_languageSearchController'));
      expect(source, contains('_handleLanguageSearchChanged'));
      expect(source, contains('_selectLanguage(String code)'));
      expect(source, contains('_selectedLanguage(AppLocalizations l10n)'));
      expect(source, contains('_visibleLanguages(AppLocalizations l10n)'));
      expect(source, contains('_languageSearchHaystack('));
      expect(source, contains('excursionsFilterLanguageAll'));
      expect(source, contains('excursionsFilterLanguageSearchHint'));
      expect(source, contains('excursionsFilterLanguageNoResults'));
      expect(source, contains('_ExcursionsLanguageOptionRow'));
      expect(source, isNot(contains('void _toggleLanguage(String code)')));

      final languageSectionStart = source.indexOf(
        'title: l10n.excursionsFilterLanguage',
      );
      final endMarker = source.indexOf(
        'Padding(\n                padding: AppEdgeInsets.fromLTRB',
        languageSectionStart,
      );
      expect(languageSectionStart, isNonNegative);
      expect(endMarker, greaterThan(languageSectionStart));

      final languageSection = source.substring(languageSectionStart, endMarker);
      expect(languageSection, contains('TextField'));
      expect(languageSection, contains('selectedLanguage ??'));
      expect(languageSection, contains('l10n.excursionsFilterLanguageAll'));
      expect(
        languageSection,
        contains('l10n.excursionsFilterLanguageSearchHint'),
      );
      expect(
        languageSection,
        contains('l10n.excursionsFilterLanguageNoResults'),
      );
      expect(languageSection, contains('_ExcursionsLanguageOptionRow'));
      expect(languageSection, isNot(contains('Wrap(')));
    },
  );

  test('router exposes excursions list as a public route', () async {
    final routerSource = await File(
      'lib/core/router/app_router.dart',
    ).readAsString();

    expect(routerSource, contains("path: '/excursions'"));
    expect(routerSource, contains('ExcursionsScreen'));
    expect(routerSource, contains("location == '/excursions'"));
  });

  test('excursions list can show place-specific empty notice', () async {
    final source = await File(
      'lib/screens/excursions/excursions_screen.dart',
    ).readAsString();
    final routerSource = await File(
      'lib/core/router/app_router.dart',
    ).readAsString();

    expect(source, contains('class ExcursionsRouteArgs'));
    expect(source, contains('ExcursionsRouteArgs.noPlaceExcursions'));
    expect(source, contains('_buildNoPlaceExcursionsNotice'));
    expect(source, contains('excursionsNoPlaceExcursionsTitle'));
    expect(source, contains('excursionsNoPlaceExcursionsSubtitle'));
    expect(source, contains('showNoPlaceExcursionsNotice =='));
    expect(routerSource, contains('ExcursionsRouteArgs'));
    expect(routerSource, contains('ExcursionsScreen(routeArgs: args)'));
  });

  test('excursion provider has list loading and refresh states', () async {
    final providerSource = await File(
      'lib/providers/excursion_provider.dart',
    ).readAsString();

    expect(providerSource, contains('Future<void> loadExcursions'));
    expect(providerSource, contains('Future<void> refreshExcursions'));
    expect(providerSource, contains('List<ExcursionVm>'));
  });

  test(
    'excursions list resolves cover file ids into real image urls',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();

      expect(
        source,
        contains(
          "import '../../features/excursions/excursion_cover_url.dart';",
        ),
      );
      expect(source, contains('resolveExcursionCoverUrl(excursion)'));
      expect(source, contains('imageUrl: resolveExcursionCoverUrl(excursion)'));
      expect(source, contains('Image.network'));
    },
  );

  test('excursion cards display marketplace offer count', () async {
    final source = await File(
      'lib/screens/excursions/excursions_screen.dart',
    ).readAsString();

    expect(source, contains('publishedOffersCount'));
    expect(source, contains('excursionsOffersCount'));
  });

  test(
    'excursion cards place price under title and avoid duplicate location title',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();
      final cardStart = source.indexOf('class ExcursionListCard');
      final coverStart = source.indexOf('class _ExcursionCoverArt');
      expect(cardStart, isNonNegative);
      expect(coverStart, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, coverStart);
      expect(cardSource, contains('final displayTitle'));
      expect(cardSource, contains('maxLines: 2'));
      expect(
        cardSource,
        contains('_primaryLocation(excursion, displayTitle, category)'),
      );
      expect(cardSource, contains('if (location.isNotEmpty)'));
      expect(cardSource, contains('_isSameLabel'));
      expect(
        cardSource.indexOf('price,'),
        lessThan(cardSource.indexOf('meta.isEmpty')),
      );
      expect(
        cardSource,
        isNot(
          contains(
            'Flexible(\n                          child: Text(\n                            displayTitle',
          ),
        ),
      );
      expect(cardSource, isNot(contains('const Spacer()')));
      expect(cardSource, isNot(contains('textAlign: TextAlign.end')));
    },
  );

  test(
    'excursions list resolves localized place text for every route kind',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
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
      expect(source, contains('Map<String, PlaceVm> _localizedPlaces'));
      expect(source, contains('_scheduleResolveLocalizedPlaces'));
      expect(source, contains('_loadLocalizedPlace'));
      expect(source, contains('...excursion.placeIds.map('));
      expect(source, contains('locale: lang'));
      expect(source, contains('localizedLandmark:'));
      expect(source, contains('localizedPlacesById: _localizedPlaces'));
      expect(source, contains('placesById: _localizedPlaces'));
      expect(source, contains('localizedExcursionTitle('));
      expect(source, contains('localizedExcursionLandmarkName('));
    },
  );

  test(
    'excursion cards use balanced V2 surfaces, text hierarchy, and dark-only depth',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();
      final helperStart = source.indexOf('bool _isLightExcursionsTheme');
      final cardStart = source.indexOf('class ExcursionListCard');
      final coverStart = source.indexOf('class _ExcursionCoverArt');
      final painterStart = source.indexOf('class _ExcursionCoverPainter');

      expect(helperStart, isNonNegative);
      expect(cardStart, isNonNegative);
      expect(coverStart, greaterThan(cardStart));
      expect(painterStart, greaterThan(coverStart));

      final helperSource = source.substring(helperStart, cardStart);
      final cardSource = source.substring(cardStart, coverStart);
      final coverSource = source.substring(coverStart, painterStart);

      expect(helperSource, contains('Brightness.light'));
      expect(helperSource, contains('List<BoxShadow>? _excursionsCardShadow'));
      expect(helperSource, contains('return null;'));
      expect(helperSource, contains('Color _excursionsPrimaryTextColor'));

      expect(cardSource, contains('surfaceRaised'));
      expect(cardSource, contains('boxShadow: _excursionsCardShadow(context)'));
      expect(cardSource, contains('_excursionsPrimaryTextColor(context)'));
      expect(cardSource, contains('context.excursionsColors.textPrimary'));
      expect(cardSource, contains('context.excursionsColors.textSecondary'));
      expect(cardSource, isNot(contains('orangeLight28')));
      expect(cardSource, isNot(contains('orangeSoft06')));

      expect(coverSource, contains('_excursionCoverScrimGradient(context)'));
      expect(coverSource, contains('if (scrimGradient != null)'));
      expect(coverSource, contains('_excursionRatingBadgeBackground(context)'));
      expect(coverSource, contains('if (rating != null)'));
      expect(coverSource, contains('rating!.toStringAsFixed(1)'));
      expect(coverSource, isNot(contains("'4.9'")));
      expect(coverSource, contains('context.excursionsColors.textPrimary'));
    },
  );

  test(
    'excursion cards use V2 primary for card accent text without raw brown colors',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();
      final helperStart = source.indexOf('Color _excursionsPrimaryTextColor');
      final shadowStart = source.indexOf(
        'List<BoxShadow>? _excursionsCardShadow',
        helperStart,
      );
      final cardStart = source.indexOf('class ExcursionListCard');
      final coverStart = source.indexOf('class _ExcursionCoverArt');

      expect(helperStart, isNonNegative);
      expect(shadowStart, greaterThan(helperStart));
      expect(cardStart, isNonNegative);
      expect(coverStart, greaterThan(cardStart));

      final helperSource = source.substring(helperStart, shadowStart);
      final cardSource = source.substring(cardStart, coverStart);

      expect(helperSource, contains('context.excursionsColors.primary'));
      expect(helperSource, isNot(contains('Color(0xFFB45309)')));
      expect(helperSource, isNot(contains('Brightness.light')));
      expect(cardSource, contains('_excursionsPrimaryTextColor(context)'));
    },
  );

  test('excursion grid cards keep a roomy responsive aspect ratio', () async {
    final source = await File(
      'lib/screens/excursions/excursions_screen.dart',
    ).readAsString();

    expect(source, contains('_excursionGridAspectRatioForWidth'));
    expect(source, contains('return 0.64 + normalizedWidth * 0.10'));
    expect(source, contains('childAspectRatio: _gridAspectRatio(context)'));
    expect(source, isNot(contains('return 0.56')));
    expect(source, isNot(contains('return 0.60')));
    expect(source, isNot(contains('? 0.63')));
  });

  test(
    'excursion cards allow text column to shrink without bottom overflow',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();
      final cardStart = source.indexOf('class ExcursionListCard');
      final coverStart = source.indexOf('class _ExcursionCoverArt');
      expect(cardStart, isNonNegative);
      expect(coverStart, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, coverStart);
      expect(cardSource, contains('flex: 4'));
      expect(cardSource, contains('flex: 6'));
      expect(cardSource, contains('Flexible('));
      expect(cardSource, contains('fit: BoxFit.scaleDown'));
      expect(cardSource, contains('maxLines: 2'));
    },
  );

  test(
    'excursions filter sheet is compact and dismisses outside taps',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();
      final sheetStart = source.indexOf('class _ExcursionsFiltersSheetState');
      final sectionStart = source.indexOf('class _ExcursionsFilterSection');
      final chipStart = source.indexOf('class _ExcursionsFilterChip');
      final segmentStart = source.indexOf('class _ExcursionsSegmentButton');
      final sortStart = source.indexOf('class _ExcursionsSortBar');
      expect(sheetStart, isNonNegative);
      expect(sectionStart, greaterThan(sheetStart));
      expect(chipStart, greaterThan(sectionStart));
      expect(segmentStart, greaterThan(chipStart));
      expect(sortStart, greaterThan(segmentStart));

      final sheetSource = source.substring(sheetStart, sectionStart);
      final sectionSource = source.substring(sectionStart, chipStart);
      final chipSource = source.substring(chipStart, segmentStart);
      final segmentSource = source.substring(segmentStart, sortStart);

      expect(sheetSource, contains('AppModalSheetFrame('));
      expect(
        sheetSource,
        contains('onTapOutside: () => Navigator.of(context).maybePop(),'),
      );
      expect(sheetSource, contains('titleFontSize: 16'));
      expect(sectionSource, contains('fontSize: 16'));
      expect(chipSource, contains('constraints: const BoxConstraints('));
      expect(chipSource, contains('maxWidth: 220'));
      expect(chipSource, contains('fontSize: 13'));
      expect(segmentSource, contains('FittedBox('));
      expect(segmentSource, contains('fontSize: 13'));
    },
  );

  test(
    'excursions filter modal controls use visible light theme borders',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();

      final sheetStart = source.indexOf('class _ExcursionsFiltersSheetState');
      final priceFieldStart = source.indexOf(
        'class _ExcursionsPriceInputField',
      );
      final languageOptionStart = source.indexOf(
        'class _ExcursionsLanguageOptionRow',
      );
      final chipStart = source.indexOf('class _ExcursionsFilterChip');
      final segmentStart = source.indexOf('class _ExcursionsSegmentButton');
      final sortStart = source.indexOf('class _ExcursionsSortBar');
      expect(sheetStart, isNonNegative);
      expect(priceFieldStart, greaterThan(sheetStart));
      expect(languageOptionStart, greaterThan(priceFieldStart));
      expect(chipStart, greaterThan(languageOptionStart));
      expect(segmentStart, greaterThan(chipStart));
      expect(sortStart, greaterThan(segmentStart));

      final sheetSource = source.substring(sheetStart, priceFieldStart);
      final priceFieldSource = source.substring(
        priceFieldStart,
        languageOptionStart,
      );
      final languageOptionSource = source.substring(
        languageOptionStart,
        chipStart,
      );
      final chipSource = source.substring(chipStart, segmentStart);
      final segmentSource = source.substring(segmentStart, sortStart);

      expect(sheetSource, isNot(contains('white.withValues(alpha: 0.06)')));
      expect(priceFieldSource, contains('context.excursionsColors.border'));
      expect(
        priceFieldSource,
        isNot(contains('white.withValues(alpha: 0.06)')),
      );
      expect(
        languageOptionSource,
        isNot(contains('white.withValues(alpha: 0.07)')),
      );
      expect(chipSource, contains('border: Border.all('));
      expect(chipSource, contains('context.excursionsColors.borderSoft'));
      expect(segmentSource, contains('border: Border.all('));
      expect(segmentSource, contains('context.excursionsColors.borderSoft'));
    },
  );

  test(
    'excursion cards show starting price from the cheapest guide offer',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();
      final cardStart = source.indexOf('class ExcursionListCard');
      final coverStart = source.indexOf('class _ExcursionCoverArt');
      expect(cardStart, isNonNegative);
      expect(coverStart, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, coverStart);
      expect(cardSource, contains('class _ExcursionCardPrice'));
      expect(cardSource, contains('_displayPriceFor(excursion)'));
      expect(cardSource, contains('excursion.offers'));
      expect(cardSource, contains('offer.priceAmount < selected.amount'));
      expect(cardSource, contains('l10n.excursionsPriceFrom(formatted)'));
    },
  );

  test('excursion cards do not show check mark badge over cover', () async {
    final source = await File(
      'lib/screens/excursions/excursions_screen.dart',
    ).readAsString();

    final coverArtIndex = source.indexOf('class _ExcursionCoverArt');
    final coverPainterIndex = source.indexOf('class _ExcursionCoverPainter');
    expect(coverArtIndex, isNonNegative);
    expect(coverPainterIndex, greaterThan(coverArtIndex));

    final coverArtSource = source.substring(coverArtIndex, coverPainterIndex);
    expect(coverArtSource, isNot(contains('Icons.check_rounded')));
  });

  test(
    'excursion filters preserve the dimmed list outside the sheet',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();
      final openStart = source.indexOf('Future<void> _showFilters()');
      final buildStart = source.indexOf('class _ExcursionsFiltersSheetState');

      expect(openStart, isNonNegative);
      expect(buildStart, greaterThan(openStart));

      final openSource = source.substring(openStart, buildStart);
      expect(openSource, contains('contentHandlesBottomSafeArea: true'));
      expect(
        openSource,
        contains('backgroundColor: context.excursionsColors.transparent'),
      );
      expect(
        source,
        contains('maxHeight: MediaQuery.sizeOf(context).height * 0.86'),
      );
    },
  );
}
