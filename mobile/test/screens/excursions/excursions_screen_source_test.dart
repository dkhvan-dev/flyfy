import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
      expect(source, contains('showModalBottomSheet<_ExcursionsFilters>'));
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

  test('excursions filter sheet starts with current-location city filter',
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
    expect(source, contains('HomeLocationProvider'));
    expect(source, contains('selectedLocation'));
    expect(source, contains('_initializeDefaultCityFilter'));
    expect(source, contains('_applyDefaultCityFilter'));
    expect(source, contains('final AppCityFilterValue? city'));
    expect(source, contains('AppCityFilterSection'));
    expect(source, contains('locationFilterCitySection'));
    expect(source, contains('filters.city'));
    expect(source, contains('departureCityId: city?.cityId'));
    expect(source, contains('cityId: excursion.departureCityId'));
    expect(source, contains('excursion.cityName'));
    expect(source, contains('countryCode: excursion.countryCode'));
    expect(source, isNot(contains('profile?.countryCode')));
  });

  test(
    'excursions city filter is compact and searchable through shared selector',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();

      expect(source, contains('AppCityFilterSection'));
      expect(source, contains('locationFilterCitySearchHint'));
      expect(source, contains('locationFilterCityNoResults'));
      expect(source, isNot(contains('_countrySearchController')));
      expect(source, isNot(contains('_selectedCountry()')));
      expect(source, isNot(contains('_visibleCountries')));

      final citySectionStart = source.indexOf('AppCityFilterSection(');
      final categorySectionStart = source.indexOf(
        'title: l10n.excursionsFilterCategories',
      );
      expect(citySectionStart, isNonNegative);
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

  test('excursions language filter uses searchable single-select field',
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
      'Padding(\n                padding: EdgeInsets.fromLTRB',
      languageSectionStart,
    );
    expect(languageSectionStart, isNonNegative);
    expect(endMarker, greaterThan(languageSectionStart));

    final languageSection = source.substring(
      languageSectionStart,
      endMarker,
    );
    expect(languageSection, contains('TextField'));
    expect(languageSection, contains('selectedLanguage ??'));
    expect(languageSection, contains('l10n.excursionsFilterLanguageAll'));
    expect(
        languageSection, contains('l10n.excursionsFilterLanguageSearchHint'));
    expect(languageSection, contains('l10n.excursionsFilterLanguageNoResults'));
    expect(languageSection, contains('_ExcursionsLanguageOptionRow'));
    expect(languageSection, isNot(contains('Wrap(')));
  });

  test('router exposes excursions list as a public route', () async {
    final routerSource = await File(
      'lib/core/router/app_router.dart',
    ).readAsString();

    expect(routerSource, contains("path: '/excursions'"));
    expect(routerSource, contains('ExcursionsScreen'));
    expect(routerSource, contains("location == '/excursions'"));
  });

  test('excursions list can show attraction-specific empty notice', () async {
    final source = await File(
      'lib/screens/excursions/excursions_screen.dart',
    ).readAsString();
    final routerSource = await File(
      'lib/core/router/app_router.dart',
    ).readAsString();

    expect(source, contains('class ExcursionsRouteArgs'));
    expect(source, contains('ExcursionsRouteArgs.noAttractionExcursions'));
    expect(source, contains('_buildNoAttractionExcursionsNotice'));
    expect(source, contains('excursionsNoAttractionExcursionsTitle'));
    expect(source, contains('excursionsNoAttractionExcursionsSubtitle'));
    expect(source, contains('showNoAttractionExcursionsNotice =='));
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

  test('excursions list resolves cover file ids into real image urls',
      () async {
    final source = await File(
      'lib/screens/excursions/excursions_screen.dart',
    ).readAsString();

    expect(
      source,
      contains("import '../../features/excursions/excursion_cover_url.dart';"),
    );
    expect(source, contains('resolveExcursionCoverUrl(excursion)'));
    expect(source, contains('imageUrl: resolveExcursionCoverUrl(excursion)'));
    expect(source, contains('Image.network'));
  });

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
      'excursions list resolves localized attraction text for landmark excursions',
      () async {
    final source = await File(
      'lib/screens/excursions/excursions_screen.dart',
    ).readAsString();

    expect(
      source,
      contains("import '../../features/attractions/data/attraction_api.dart';"),
    );
    expect(
      source,
      contains(
          "import '../../features/attractions/models/attraction_vm.dart';"),
    );
    expect(source, contains('final AttractionApi _attractionApi'));
    expect(source, contains('Map<String, AttractionVm> _localizedLandmarks'));
    expect(source, contains('_scheduleResolveLocalizedLandmarks'));
    expect(source, contains('_loadLocalizedLandmark'));
    expect(source, contains('locale: lang'));
    expect(source, contains('localizedLandmark:'));
    expect(source, contains('localizedExcursionTitle('));
    expect(source, contains('localizedExcursionLandmarkName('));
  });

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
}
