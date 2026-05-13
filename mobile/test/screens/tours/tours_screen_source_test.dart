import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'tours screen loads public tours and guards guide-only creation',
    () async {
      final source = await File(
        'lib/screens/tours/tours_screen.dart',
      ).readAsString();

      expect(source, contains('class ToursScreen'));
      expect(source, contains('loadTours('));
      expect(source, contains('refreshTours('));
      expect(source, contains('profile?.isGuide == true'));
      expect(source, contains('ToursBottomNavigation'));
      expect(source, contains('CreateActionBottomNavigationBar'));
      expect(source, contains('CommonBottomNavigationBar'));
      expect(source, contains("context.push('/tours/create')"));
      expect(source, contains("context.push('/map')"));
    },
  );

  test(
    'tours screen uses shared sorting, filter chrome, and accent search',
    () async {
      final source = await File(
        'lib/screens/tours/tours_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../core/ui/app_inline_sort_row.dart';"),
      );
      expect(
        source,
        contains("import '../../core/ui/filter_sheet_chrome.dart';"),
      );
      expect(source, contains('AppInlineSortRow<_ToursSortMode>'));
      expect(source, contains('toursSortLabel'));
      expect(source, contains('_ToursSortMode.createdAt'));
      expect(source, contains('_ToursSortMode.rating'));
      expect(source, contains('_ToursSortMode.price'));
      expect(source, contains('_ToursSortMode.duration'));
      expect(source, contains('toursSortCreatedAt'));
      expect(source, contains('toursSortRating'));
      expect(source, contains('toursSortPrice'));
      expect(source, contains('toursSortDuration'));
      expect(source, contains('showModalBottomSheet<_ToursFilters>'));
      expect(source, contains('class _ToursFiltersSheet'));
      expect(source, contains('class _ToursFilters'));
      expect(source, contains('AppFilterSheetHeader'));
      expect(source, contains('AppFilterApplyButton'));
      expect(
        source,
        contains('const Icon(Icons.search_rounded, color: AppColors.accent'),
      );
      expect(source, isNot(contains('class _ToursSortTabs')));
      expect(source, isNot(contains('class _ToursFilterOption')));
      expect(source, isNot(contains('_ToursSortMode.popular')));
      expect(source, isNot(contains('_ToursSortMode.affordable')));
    },
  );

  test('tours filter sheet starts with country dictionary filter', () async {
    final source = await File(
      'lib/screens/tours/tours_screen.dart',
    ).readAsString();

    expect(source, contains("import '../../core/network/reference_api.dart';"));
    expect(source, contains('final ReferenceApi _referenceApi'));
    expect(source, contains('List<ReferenceCountry> _countries'));
    expect(source, contains('_defaultCountryCode()'));
    expect(source, contains('_applyDefaultCountryFilter()'));
    expect(source, contains('countryCode: defaultCountryCode'));
    expect(source, contains('toursFilterCountry'));
    expect(source, contains('widget.countries'));
    expect(source, contains('_selectCountry(country.code)'));
    expect(source, contains('tour.countryCode'));
  });

  test(
    'tours country filter is compact and searchable by localized aliases',
    () async {
      final source = await File(
        'lib/screens/tours/tours_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('Map<String, Set<String>> _countrySearchAliases'),
      );
      expect(source, contains('_loadCountrySearchAliases'));
      expect(source, contains('toursFilterCountrySearchHint'));
      expect(source, contains('_countrySearchController'));
      expect(source, contains('_selectedCountry()'));
      expect(source, contains('_visibleCountries'));
      expect(source, contains('_countrySearchHaystack'));
      expect(source, contains('_countrySearchQuery.trim().toLowerCase()'));
      expect(source, contains('widget.countrySearchAliases'));
      expect(source, contains('country.phoneCode'));

      final countrySectionStart = source.indexOf(
        'title: l10n.toursFilterCountry',
      );
      final categorySectionStart = source.indexOf(
        'title: l10n.toursFilterCategories',
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
    'tours list search is localized and price filter uses from-to range',
    () async {
      final source = await File(
        'lib/screens/tours/tours_screen.dart',
      ).readAsString();

      expect(source, contains('_tourSearchHaystack'));
      expect(source, contains('_normalizeTourSearchText'));
      expect(source, contains('_tourSearchNeedleGroups'));
      expect(source, contains('_latinToCyrillicTourSearchText'));
      expect(source, contains('_cyrillicToLatinTourSearchText'));
      expect(source, contains('variants.any(haystack.contains)'));
      expect(source, contains('localizedTourCategoryLabel(l10n,'));
      expect(source, contains('localizedTourLanguageLabel(l10n, code)'));
      expect(source, contains('tour.includedItems'));
      expect(source, contains('tour.itinerary'));
      expect(source, contains('_priceFromController'));
      expect(source, contains('_priceToController'));
      expect(source, contains('toursFilterPriceFrom'));
      expect(source, contains('toursFilterPriceTo'));
      expect(source, contains('priceMin'));
      expect(source, contains('priceMax'));
      expect(source, isNot(contains('_ToursPriceFilter')));
      expect(source, isNot(contains('toursFilterBudget')));
      expect(source, isNot(contains('toursFilterPremium')));
    },
  );

  test('router exposes tours list as a public route', () async {
    final routerSource = await File(
      'lib/core/router/app_router.dart',
    ).readAsString();

    expect(routerSource, contains("path: '/tours'"));
    expect(routerSource, contains('ToursScreen'));
    expect(routerSource, contains("location == '/tours'"));
  });

  test('tour provider has list loading and refresh states', () async {
    final providerSource = await File(
      'lib/providers/tour_provider.dart',
    ).readAsString();

    expect(providerSource, contains('Future<void> loadTours'));
    expect(providerSource, contains('Future<void> refreshTours'));
    expect(providerSource, contains('List<TourVm>'));
  });

  test('tours list resolves cover file ids into real image urls', () async {
    final source = await File(
      'lib/screens/tours/tours_screen.dart',
    ).readAsString();

    expect(
      source,
      contains("import '../../features/tours/tour_cover_url.dart';"),
    );
    expect(source, contains('resolveTourCoverUrl(tour)'));
    expect(source, contains('imageUrl: resolveTourCoverUrl(tour)'));
    expect(source, contains('Image.network'));
  });

  test('tour cards display marketplace offer count', () async {
    final source = await File(
      'lib/screens/tours/tours_screen.dart',
    ).readAsString();

    expect(source, contains('publishedOffersCount'));
    expect(source, contains('toursOffersCount'));
  });

  test(
    'tour cards place price under title and avoid duplicate location title',
    () async {
      final source = await File(
        'lib/screens/tours/tours_screen.dart',
      ).readAsString();
      final cardStart = source.indexOf('class TourListCard');
      final coverStart = source.indexOf('class _TourCoverArt');
      expect(cardStart, isNonNegative);
      expect(coverStart, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, coverStart);
      expect(cardSource, contains('final displayTitle'));
      expect(cardSource, contains('maxLines: 2'));
      expect(
        cardSource,
        contains('_primaryLocation(tour, displayTitle, category)'),
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

  test('tours list resolves localized attraction text for landmark tours',
      () async {
    final source = await File(
      'lib/screens/tours/tours_screen.dart',
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
    expect(source, contains('localizedTourTitle('));
    expect(source, contains('localizedTourLandmarkName('));
  });

  test(
    'tour cards show starting price from the cheapest guide offer',
    () async {
      final source = await File(
        'lib/screens/tours/tours_screen.dart',
      ).readAsString();
      final cardStart = source.indexOf('class TourListCard');
      final coverStart = source.indexOf('class _TourCoverArt');
      expect(cardStart, isNonNegative);
      expect(coverStart, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, coverStart);
      expect(cardSource, contains('class _TourCardPrice'));
      expect(cardSource, contains('_displayPriceFor(tour)'));
      expect(cardSource, contains('tour.offers'));
      expect(cardSource, contains('offer.priceAmount < selected.amount'));
      expect(cardSource, contains('l10n.toursPriceFrom(formatted)'));
    },
  );

  test('tour cards do not show check mark badge over cover', () async {
    final source = await File(
      'lib/screens/tours/tours_screen.dart',
    ).readAsString();

    final coverArtIndex = source.indexOf('class _TourCoverArt');
    final coverPainterIndex = source.indexOf('class _TourCoverPainter');
    expect(coverArtIndex, isNonNegative);
    expect(coverPainterIndex, greaterThan(coverArtIndex));

    final coverArtSource = source.substring(coverArtIndex, coverPainterIndex);
    expect(coverArtSource, isNot(contains('Icons.check_rounded')));
  });
}
