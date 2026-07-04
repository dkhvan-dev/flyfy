import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guides screen uses V2 design system colors', () async {
    final source = await File(
      'lib/screens/guides/guides_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.screenGradientColors'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'guides screen follows reference text with shared sort and filter chrome',
    () async {
      final source = await File(
        'lib/screens/guides/guides_screen.dart',
      ).readAsString();

      expect(source, contains('class GuidesScreen'));
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
        contains("import '../../core/ui/app_inline_sort_row.dart';"),
      );
      expect(
        source,
        contains("import '../../core/ui/filter_sheet_chrome.dart';"),
      );
      expect(source, contains('AppInlineSortRow<_GuideSortMode>'));
      expect(source, contains('guidesSortLabel'));
      expect(source, contains('guidesSortRating'));
      expect(source, contains('guidesSortExperience'));
      expect(source, contains('guidesSearchHint'));
      expect(source, contains('showAppModalBottomSheet<_GuideFilters>'));
      expect(source, contains('class _GuidesFiltersSheet'));
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
      expect(source, contains('_initializeGuides'));
      expect(source, contains('_applyDefaultCityFilter'));
      expect(source, contains('cityId: _filters.city?.cityId'));
      expect(source, contains('cityName: _filters.city?.cityName'));
      expect(source, contains('cityCountryCode: _filters.city?.countryCode'));
      expect(source, isNot(contains('profile?.countryCode')));
      expect(source, contains('AppFilterSheetHeader'));
      expect(source, contains('AppFilterApplyButton'));
      expect(source, contains('guideSearchMatches('));
    },
  );

  test(
    'guides screen enriches cards with excursion language summaries',
    () async {
      final apiSource = await File(
        'lib/features/guides/data/guide_discovery_api.dart',
      ).readAsString();

      expect(apiSource, contains("'/guides/excursion-languages'"));
      expect(apiSource, contains('guideUserIds'));
      expect(apiSource, contains('copyWith(excursionLanguageCodes:'));
      expect(apiSource, contains('Options(extra: const {'));
      expect(apiSource, contains("'requiresAuth': false"));
    },
  );

  test('guides city filter uses shared searchable city selector', () async {
    final source = await File(
      'lib/screens/guides/guides_screen.dart',
    ).readAsString();

    expect(source, contains('final AppCountryFilterValue? country'));
    expect(source, contains('final AppCityFilterValue? city'));
    expect(source, contains('countryCodes: _filters.countryCodes'));
    expect(source, contains('countryCodes: filters.countryCodes'));
    expect(source, contains('AppCountryFilterSection'));
    expect(source, contains('AppCityFilterSection'));
    expect(source, contains('guidesFilterCountry'));
    expect(source, contains('guidesFilterCountryAll'));
    expect(source, contains('guidesFilterCountrySearchHint'));
    expect(source, contains('guidesFilterCountryNoResults'));
    expect(source, contains('locationFilterCitySection'));
    expect(source, contains('locationFilterCitySearchHint'));
    expect(source, contains('locationFilterCityNoResults'));
    expect(source, contains('_setCountry(AppCountryFilterValue? country)'));
    expect(source, contains('city: null'));
    expect(source, contains('_setCity(AppCityFilterValue? city)'));
    expect(source, contains('guideSearchMatches('));

    final countrySectionStart = source.indexOf('AppCountryFilterSection(');
    final citySectionStart = source.indexOf('AppCityFilterSection(');
    final expertiseSectionStart = source.indexOf(
      'title: l10n.guidesFilterExpertise',
    );
    expect(countrySectionStart, isNonNegative);
    expect(citySectionStart, isNonNegative);
    expect(citySectionStart, greaterThan(countrySectionStart));
    expect(expertiseSectionStart, greaterThan(citySectionStart));

    final citySection = source.substring(
      citySectionStart,
      expertiseSectionStart,
    );
    expect(citySection, contains('AppCityFilterSection'));
    expect(citySection, isNot(contains('Wrap(')));
  });

  test('guides language filter uses searchable single-select field', () async {
    final source = await File(
      'lib/screens/guides/guides_screen.dart',
    ).readAsString();

    expect(source, contains('_languageSearchController'));
    expect(source, contains('_handleLanguageSearchChanged'));
    expect(source, contains('_selectLanguage(String code)'));
    expect(source, contains('_selectedLanguage(AppLocalizations l10n)'));
    expect(source, contains('_visibleLanguages(AppLocalizations l10n)'));
    expect(source, contains('_languageSearchHaystack('));
    expect(source, contains('guidesFilterLanguageAll'));
    expect(source, contains('guidesFilterLanguageSearchHint'));
    expect(source, contains('guidesFilterLanguageNoResults'));

    final languageSectionStart = source.indexOf(
      'title: l10n.guidesFilterLanguage',
    );
    final ratingSectionStart = source.indexOf('title: l10n.guidesFilterRating');
    expect(languageSectionStart, isNonNegative);
    expect(ratingSectionStart, greaterThan(languageSectionStart));

    final languageSection = source.substring(
      languageSectionStart,
      ratingSectionStart,
    );
    expect(languageSection, contains('TextField'));
    expect(languageSection, contains('selectedLanguage ??'));
    expect(languageSection, contains('l10n.guidesFilterLanguageAll'));
    expect(languageSection, contains('l10n.guidesFilterLanguageSearchHint'));
    expect(languageSection, contains('l10n.guidesFilterLanguageNoResults'));
    expect(languageSection, contains('_GuideLanguageOptionRow'));
    expect(languageSection, isNot(contains('Wrap(')));
    expect(languageSection, isNot(contains('_GuideFilterChip(')));
  });

  test('guides filters load reference options outside the screen UI', () async {
    final source = await File(
      'lib/screens/guides/guides_screen.dart',
    ).readAsString();
    final optionsSource = await File(
      'lib/features/guides/guide_filter_options.dart',
    ).readAsString();
    final apiSource = await File(
      'lib/features/guides/data/guide_discovery_api.dart',
    ).readAsString();

    expect(source, contains('GuideFilterOptions.fallback'));
    expect(source, contains('_loadGuideFilterOptions'));
    expect(source, contains('listPublicGuideFilterOptions'));
    expect(source, contains('filterOptions: _filterOptions'));
    expect(source, isNot(contains('const _guideLanguageFilterCodes')));
    expect(source, isNot(contains('const _guideSpecializationFilterCodes')));
    expect(optionsSource, contains('class GuideFilterOptions'));
    expect(optionsSource, contains('languageAliases'));
    expect(optionsSource, contains('specializationCodes'));
    expect(apiSource, contains("'/guides/public/filter-options'"));
  });

  test('guide cards show excursion languages and use compact sizing', () async {
    final source = await File(
      'lib/screens/guides/guides_screen.dart',
    ).readAsString();

    expect(source, contains('guideExcursionLanguageLabel(l10n, guide)'));
    expect(source, contains('if (languageLabel.isNotEmpty)'));
    expect(source, isNot(contains('final role = guideRoleLabel(l10n, guide)')));
    expect(source, contains('imageHeight + _guideCardBodyHeight(context)'));
    expect(source, contains('MediaQuery.textScalerOf(context)'));
    expect(source, isNot(contains('cardHeight = imageHeight + 122')));
    expect(source, contains('clamp(118.0, 156.0)'));
    expect(source, contains('guide.preferredName'));
    expect(source, contains('maxLines: 1'));
  });

  test(
    'guide list keeps sort and cards adaptive for large accessibility text',
    () async {
      final source = await File(
        'lib/screens/guides/guides_screen.dart',
      ).readAsString();
      final sortRowSource = await File(
        'lib/core/ui/app_inline_sort_row.dart',
      ).readAsString();

      expect(sortRowSource, contains('final bool wrap'));
      expect(sortRowSource, contains('return wrap'));
      expect(sortRowSource, contains('? Wrap('));
      expect(source, contains('wrap: true'));
      expect(source, contains('_guideGridColumnCount('));
      expect(source, contains('MediaQuery.textScalerOf(context).scale(1)'));
      expect(
        source,
        contains('if (textScale >= 1.3 && width < 600) return 1;'),
      );
    },
  );

  test('guide card exposes profile navigation as a semantic button', () async {
    final source = await File(
      'lib/screens/guides/guides_screen.dart',
    ).readAsString();
    final cardStart = source.indexOf('class _GuideCard');
    final fallbackStart = source.indexOf('class _GuideFallbackArt');

    expect(cardStart, isNonNegative);
    expect(fallbackStart, greaterThan(cardStart));

    final cardSource = source.substring(cardStart, fallbackStart);

    expect(cardSource, contains('Semantics('));
    expect(cardSource, contains('button: true'));
    expect(cardSource, contains('onTap: onTap'));
    expect(cardSource, contains('label: semanticsLabel'));
    expect(cardSource, contains('final semanticsLabel'));
    expect(cardSource, contains('l10n.guidesViewProfile'));
  });

  test('guide filter segments grow for accessibility text scale', () async {
    final source = await File(
      'lib/screens/guides/guides_screen.dart',
    ).readAsString();
    final gridStart = source.indexOf('class _GuideSegmentGrid');
    final buttonStart = source.indexOf('class _GuideSegmentButton');

    expect(gridStart, isNonNegative);
    expect(buttonStart, greaterThan(gridStart));

    final gridSource = source.substring(gridStart, buttonStart);

    expect(gridSource, contains('MediaQuery.textScalerOf(context).scale(1)'));
    expect(gridSource, contains('final itemExtent'));
    expect(gridSource, contains('mainAxisExtent: itemExtent'));
    expect(gridSource, isNot(contains('mainAxisExtent: 48')));
  });

  test('guide filters sheet closes when tapping outside the sheet', () async {
    final source = await File(
      'lib/screens/guides/guides_screen.dart',
    ).readAsString();
    final sheetStart = source.indexOf('class _GuidesFiltersSheetState');
    final sectionStart = source.indexOf('class _GuideFilterSection');

    expect(sheetStart, isNonNegative);
    expect(sectionStart, greaterThan(sheetStart));

    final sheetSource = source.substring(sheetStart, sectionStart);

    expect(sheetSource, contains('AppModalSheetFrame('));
    expect(
      sheetSource,
      contains('onTapOutside: () => Navigator.of(context).maybePop(),'),
    );
  });

  test('guide list avoids stale loads and exposes recovery actions', () async {
    final source = await File(
      'lib/screens/guides/guides_screen.dart',
    ).readAsString();

    expect(source, contains('_loadGuidesRequestId'));
    expect(source, contains('requestId != _loadGuidesRequestId'));
    expect(source, contains('showErrorDialog('));
    expect(source, contains('message: l10n.guidesLoadFailed'));
    expect(source, contains('showClearButton: true'));
    expect(source, contains('onClear: _clearSearch'));
    expect(source, contains('onClearFilters: _clearFilters'));
    expect(source, contains('showLabel: false'));
  });

  test('guide cards expose decision signals beyond name and image', () async {
    final source = await File(
      'lib/screens/guides/guides_screen.dart',
    ).readAsString();

    expect(source, contains('guideRoleLabel(l10n, guide)'));
    expect(source, contains('guideServiceLabels(l10n, guide)'));
    expect(source, contains('guide.reviewsCount'));
    expect(source, contains('guide.experienceYears'));
    expect(source, contains('guidesRatingNew'));
    expect(source, contains('guidesReviewsCount'));
  });

  test(
    'router exposes guides list as a public route and home opens it',
    () async {
      final routerSource = await File(
        'lib/core/router/app_router.dart',
      ).readAsString();
      final homeSource = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();
      final serviceCatalogSource = await File(
        'lib/features/services/service_catalog.dart',
      ).readAsString();

      expect(routerSource, contains("path: '/guides'"));
      expect(routerSource, contains('GuidesScreen'));
      expect(routerSource, contains("location == '/guides'"));
      expect(serviceCatalogSource, contains("route: '/guides'"));
      expect(
        homeSource,
        contains('void _openService(TravelServiceEntry service)'),
      );
      expect(homeSource, contains('context.push(service.route)'));
      expect(homeSource, contains('onServiceTap: _openService'));
      expect(routerSource, contains("location.startsWith('/users/')"));
    },
  );

  test(
    'foreign guide profile keeps public browsing read-only for guests',
    () async {
      final profileSource = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final profileApiSource = await File(
        'lib/features/profile/data/profile_api.dart',
      ).readAsString();
      final guideApiSource = await File(
        'lib/features/profile/data/guide_api.dart',
      ).readAsString();

      expect(profileSource, contains('session.isAuthenticated'));
      expect(profileSource, contains('_openLoginForProtectedAction'));
      expect(profileSource, contains('getPublicUserById'));
      expect(profileSource, contains('getPublicGuideProfileByUserIdOrNull'));
      expect(profileApiSource, contains('getPublicUserById'));
      expect(guideApiSource, contains('getPublicGuideProfileByUserIdOrNull'));
    },
  );
}
