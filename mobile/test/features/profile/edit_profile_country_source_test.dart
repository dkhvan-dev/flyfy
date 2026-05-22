import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'edit profile country uses localized searchable reference selector',
    () async {
      final source = await File(
        'lib/screens/profile/edit_profile_screen.dart',
      ).readAsString();
      final countryStart = source.indexOf('label: l10n.profileCountry');
      final timezoneStart = source.indexOf(
        'label: l10n.profileTimezone',
        countryStart,
      );

      expect(countryStart, isNonNegative);
      expect(timezoneStart, greaterThan(countryStart));

      final countrySection = source.substring(countryStart, timezoneStart);

      expect(
        source,
        contains("import '../../core/network/reference_api.dart';"),
      );
      expect(
        source,
        contains("import '../../core/reference/country_filter_utils.dart';"),
      );
      expect(source, contains('final _referenceApi = ReferenceApi()'));
      expect(source, contains('_countrySearchController'));
      expect(source, contains('List<ReferenceCountry> _countries'));
      expect(
        source,
        contains('Map<String, Set<String>> _countrySearchAliases'),
      );
      expect(source, contains('_loadCountries'));
      expect(source, contains('_loadCountrySearchAliases'));
      expect(source, contains('withDefaultReferenceCountry('));
      expect(source, contains('countrySearchAliasMap('));
      expect(source, contains('countryFilterSearchHaystack('));
      expect(source, contains('normalizeCountrySearchText('));
      expect(source, contains('_selectedCountry()'));
      expect(source, contains('_visibleCountries()'));
      expect(source, contains('class _ProfileCountrySearchField'));

      expect(countrySection, contains('_ProfileCountrySearchField('));
      expect(countrySection, contains('selectedCountry: _selectedCountry()'));
      expect(countrySection, contains('visibleCountries: _visibleCountries()'));
      expect(
        countrySection,
        contains('searchHint: l10n.excursionsFilterCountrySearchHint'),
      );
      expect(
        countrySection,
        contains('emptyLabel: l10n.excursionsFilterCountryNoResults'),
      );
      expect(countrySection, isNot(contains('_StyledTextField(')));
    },
  );

  test('edit profile country is required for profile completion', () async {
    final source = await File(
      'lib/screens/profile/edit_profile_screen.dart',
    ).readAsString();
    final l10nSource = await File(
      'lib/l10n/app_ru.arb',
    ).readAsString();

    final countryStart = source.indexOf('label: l10n.profileCountry');
    final timezoneStart = source.indexOf(
      'label: l10n.profileTimezone',
      countryStart,
    );

    expect(countryStart, isNonNegative);
    expect(timezoneStart, greaterThan(countryStart));

    final countrySection = source.substring(countryStart, timezoneStart);
    final countryFieldStart = source.indexOf(
      'class _ProfileCountrySearchField',
    );

    expect(countryFieldStart, isNonNegative);

    final countryFieldSource = source.substring(countryFieldStart);

    expect(l10nSource, contains('profileCountryRequired'));
    expect(countrySection, contains('validator: (value)'));
    expect(countrySection, contains('normalizeReferenceCountryCode(value)'));
    expect(countrySection, contains('l10n.profileCountryRequired'));
    expect(countryFieldSource, contains('FormField<String>'));
    expect(countryFieldSource, contains('field.didChange'));
    expect(countryFieldSource, contains('field.errorText'));
  });

  test('empty country selector shows only searchable input', () async {
    final source = await File(
      'lib/screens/profile/edit_profile_screen.dart',
    ).readAsString();
    final countryFieldStart = source.indexOf(
      'class _ProfileCountrySearchField',
    );

    expect(countryFieldStart, isNonNegative);

    final countryFieldSource = source.substring(countryFieldStart);

    expect(countryFieldSource, contains('if (hasSelection) ...['));
    expect(countryFieldSource,
        isNot(contains('selectedCountryCode ?? searchHint')));
    expect(countryFieldSource,
        contains('errorText: hasSelection ? null : errorText'));
  });

  test('save scrolls to first missing required profile field', () async {
    final source = await File(
      'lib/screens/profile/edit_profile_screen.dart',
    ).readAsString();

    expect(source, contains('final _firstNameFieldKey = GlobalKey()'));
    expect(source, contains('final _lastNameFieldKey = GlobalKey()'));
    expect(source, contains('final _countryFieldKey = GlobalKey()'));
    expect(
        source, contains('Future<void> _scrollToFirstInvalidRequiredField()'));
    expect(source, contains('Scrollable.ensureVisible'));
    expect(source, contains('await _scrollToFirstInvalidRequiredField();'));
    expect(source, contains('const invalidFieldScrollAlignment = 0.42'));
    expect(source, contains('alignment: invalidFieldScrollAlignment'));
    expect(
      source,
      contains('alignmentPolicy: ScrollPositionAlignmentPolicy.explicit'),
    );
    expect(source, contains('key: _firstNameFieldKey'));
    expect(source, contains('key: _lastNameFieldKey'));
    expect(source, contains('key: _countryFieldKey'));
  });
}
