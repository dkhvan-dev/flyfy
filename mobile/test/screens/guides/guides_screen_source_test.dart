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
