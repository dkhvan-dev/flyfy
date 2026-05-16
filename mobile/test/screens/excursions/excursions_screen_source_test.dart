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
      expect(
        source,
        contains('const Icon(Icons.search_rounded, color: AppColors.accent'),
      );
      expect(source, isNot(contains('class _ExcursionsSortTabs')));
      expect(source, isNot(contains('class _ExcursionsFilterOption')));
      expect(source, isNot(contains('_ExcursionsSortMode.popular')));
      expect(source, isNot(contains('_ExcursionsSortMode.affordable')));
    },
  );

  test('excursions filter sheet starts with country dictionary filter',
      () async {
    final source = await File(
      'lib/screens/excursions/excursions_screen.dart',
    ).readAsString();

    expect(source, contains("import '../../core/network/reference_api.dart';"));
    expect(source, contains('final ReferenceApi _referenceApi'));
    expect(source, contains('List<ReferenceCountry> _countries'));
    expect(source, contains('_defaultCountryCode()'));
    expect(source, contains('_applyDefaultCountryFilter()'));
    expect(source, contains('countryCode: defaultCountryCode'));
    expect(source, contains('excursionsFilterCountry'));
    expect(source, contains('widget.countries'));
    expect(source, contains('_selectCountry(country.code)'));
    expect(source, contains('excursion.countryCode'));
  });

  test(
    'excursions country filter is compact and searchable by localized aliases',
    () async {
      final source = await File(
        'lib/screens/excursions/excursions_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('Map<String, Set<String>> _countrySearchAliases'),
      );
      expect(source, contains('_loadCountrySearchAliases'));
      expect(source, contains('excursionsFilterCountrySearchHint'));
      expect(source, contains('_countrySearchController'));
      expect(source, contains('_selectedCountry()'));
      expect(source, contains('_visibleCountries'));
      expect(source, contains('_countrySearchHaystack'));
      expect(source, contains('_countrySearchQuery.trim().toLowerCase()'));
      expect(source, contains('widget.countrySearchAliases'));
      expect(source, contains('country.phoneCode'));

      final countrySectionStart = source.indexOf(
        'title: l10n.excursionsFilterCountry',
      );
      final categorySectionStart = source.indexOf(
        'title: l10n.excursionsFilterCategories',
      );
      expect(countrySectionStart, isNonNegative);
      expect(categorySectionStart, greaterThan(countrySectionStart));

      final countrySection = source.substring(
        countrySectionStart,
        categorySectionStart,
      );
      expect(countrySection, contains('TextField'));
      expect(countrySection, contains('selectedCountry == null'));
      expect(countrySection, isNot(contains('Wrap(')));
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

  test('router exposes excursions list as a public route', () async {
    final routerSource = await File(
      'lib/core/router/app_router.dart',
    ).readAsString();

    expect(routerSource, contains("path: '/excursions'"));
    expect(routerSource, contains('ExcursionsScreen'));
    expect(routerSource, contains("location == '/excursions'"));
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
