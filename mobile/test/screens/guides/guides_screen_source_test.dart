import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'guides screen follows reference text with shared sort and filter chrome',
      () async {
    final source =
        await File('lib/screens/guides/guides_screen.dart').readAsString();

    expect(source, contains('class GuidesScreen'));
    expect(source, contains("import '../../core/network/reference_api.dart';"));
    expect(source, contains("import '../../providers/session_provider.dart';"));
    expect(
        source, contains("import '../../core/ui/app_inline_sort_row.dart';"));
    expect(
        source, contains("import '../../core/ui/filter_sheet_chrome.dart';"));
    expect(source, contains('AppInlineSortRow<_GuideSortMode>'));
    expect(source, contains('guidesSortLabel'));
    expect(source, contains('guidesSortRating'));
    expect(source, contains('guidesSortExperience'));
    expect(source, contains('guidesSearchHint'));
    expect(source, contains('showModalBottomSheet<_GuideFilters>'));
    expect(source, contains('class _GuidesFiltersSheet'));
    expect(source, contains('ReferenceCountry'));
    expect(source, contains('_loadCountries'));
    expect(source, contains('_defaultCountryCode'));
    expect(source, contains('countryCodes:'));
    expect(source, contains('AppFilterSheetHeader'));
    expect(source, contains('AppFilterApplyButton'));
    expect(source, contains('guideSearchMatches('));
  });

  test('guides screen enriches cards with excursion language summaries',
      () async {
    final apiSource =
        await File('lib/features/guides/data/guide_discovery_api.dart')
            .readAsString();

    expect(apiSource, contains("'/guides/excursion-languages'"));
    expect(apiSource, contains('guideUserIds'));
    expect(apiSource, contains('copyWith(excursionLanguageCodes:'));
    expect(apiSource, contains('Options(extra: const {'));
    expect(apiSource, contains("'requiresAuth': false"));
  });

  test('guides country filter is searchable by localized aliases', () async {
    final source =
        await File('lib/screens/guides/guides_screen.dart').readAsString();

    expect(source, contains('Map<String, Set<String>> _countrySearchAliases'));
    expect(source, contains('_loadCountrySearchAliases'));
    expect(source, contains('guidesFilterCountrySearchHint'));
    expect(source, contains('guidesFilterCountryNoResults'));
    expect(source, contains('_countrySearchController'));
    expect(source, contains('_selectedCountry()'));
    expect(source, contains('_visibleCountries'));
    expect(source, contains('_countrySearchAliasesFor'));
    expect(source, contains('guideSearchMatches('));
    expect(source, contains('country.phoneCode'));

    final countrySectionStart = source.indexOf('title: l10n.profileCountry');
    final expertiseSectionStart = source.indexOf(
      'title: l10n.guidesFilterExpertise',
    );
    expect(countrySectionStart, isNonNegative);
    expect(expertiseSectionStart, greaterThan(countrySectionStart));

    final countrySection = source.substring(
      countrySectionStart,
      expertiseSectionStart,
    );
    expect(countrySection, contains('TextField'));
    expect(countrySection, contains('selectedCountry == null'));
    expect(countrySection, isNot(contains('Wrap(')));
  });

  test('guides language filter uses searchable single-select field', () async {
    final source =
        await File('lib/screens/guides/guides_screen.dart').readAsString();

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
    final ratingSectionStart = source.indexOf(
      'title: l10n.guidesFilterRating',
    );
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
    final source =
        await File('lib/screens/guides/guides_screen.dart').readAsString();

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

  test('router exposes guides list as a public route and home opens it',
      () async {
    final routerSource =
        await File('lib/core/router/app_router.dart').readAsString();
    final homeSource =
        await File('lib/screens/home/home_screen.dart').readAsString();

    expect(routerSource, contains("path: '/guides'"));
    expect(routerSource, contains('GuidesScreen'));
    expect(routerSource, contains("location == '/guides'"));
    expect(homeSource, contains('void _openGuides()'));
    expect(homeSource, contains("context.push('/guides')"));
    expect(homeSource, contains('onTap: _openGuides'));
  });
}
