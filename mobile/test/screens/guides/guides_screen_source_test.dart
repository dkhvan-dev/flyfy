import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
      expect(source, contains('showModalBottomSheet<_GuideFilters>'));
      expect(source, contains('class _GuidesFiltersSheet'));
      expect(source, contains('HomeLocationProvider'));
      expect(source, contains('provider.effectiveLocation'));
      expect(
        source,
        contains('location.source == HomeLocationSource.fallback'),
      );
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
    expect(source, contains('attractionFilterCountrySection'));
    expect(source, contains('attractionFilterCountryAll'));
    expect(source, contains('attractionFilterCountrySearchHint'));
    expect(source, contains('attractionFilterCountryNoResults'));
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
    },
  );
}
