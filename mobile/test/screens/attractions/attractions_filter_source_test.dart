import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('attractions filter starts with localized searchable country filter',
      () async {
    final screenSource = await File(
      'lib/screens/attractions/attractions_screen.dart',
    ).readAsString();
    final sheetSource = await File(
      'lib/screens/attractions/attractions_filter_sheet.dart',
    ).readAsString();

    expect(
      sheetSource,
      contains("import '../../core/network/reference_api.dart';"),
    );
    expect(
      sheetSource,
      contains("import '../../core/reference/country_filter_utils.dart';"),
    );
    expect(sheetSource, contains('final String? countryCode'));
    expect(sheetSource, contains('countryCode == null ? 0 : 1'));
    expect(sheetSource, contains('List<ReferenceCountry> countries'));
    expect(
        sheetSource, contains('Map<String, Set<String>> countrySearchAliases'));
    expect(sheetSource, contains('_countrySearchController'));
    expect(sheetSource, contains('_visibleCountries'));
    expect(sheetSource, contains('countryFilterSearchHaystack'));
    expect(sheetSource, contains('attractionFilterCountrySection'));
    expect(sheetSource, contains('attractionFilterCountrySearchHint'));
    expect(sheetSource, contains('attractionFilterCountryNoResults'));
    expect(sheetSource, contains('_selectCountry(country.code)'));

    final countrySectionStart = sheetSource.indexOf(
      'header: l10n.attractionFilterCountrySection',
    );
    final categorySectionStart = sheetSource.indexOf(
      'header: l10n.attractionFilterCategoriesSection',
    );
    expect(countrySectionStart, isNonNegative);
    expect(categorySectionStart, greaterThan(countrySectionStart));

    final countrySection = sheetSource.substring(
      countrySectionStart,
      categorySectionStart,
    );
    expect(countrySection, contains('TextField'));
    expect(countrySection, contains('selectedCountry == null'));
    expect(countrySection, isNot(contains('Wrap(')));

    expect(screenSource,
        contains("import '../../core/network/reference_api.dart';"));
    expect(
      screenSource,
      contains("import '../../core/reference/country_filter_utils.dart';"),
    );
    expect(screenSource,
        contains("import '../../providers/session_provider.dart';"));
    expect(screenSource, contains('final ReferenceApi _referenceApi'));
    expect(screenSource, contains('List<ReferenceCountry> _countries'));
    expect(screenSource, contains('_defaultCountryCode()'));
    expect(screenSource, contains('_applyDefaultCountryFilter()'));
    expect(screenSource, contains('countryCode: defaultCountryCode'));
    expect(screenSource, contains('_loadCountrySearchAliases'));
    expect(screenSource, contains('countryCode: _filters.countryCode'));
    expect(
        screenSource, contains('countrySearchAliases: _countrySearchAliases'));
  });
}
