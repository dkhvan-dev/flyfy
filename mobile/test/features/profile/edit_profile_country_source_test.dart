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

  test('edit profile timezone uses localized searchable reference selector',
      () async {
    final source = await File(
      'lib/screens/profile/edit_profile_screen.dart',
    ).readAsString();
    final referenceApiSource =
        await File('lib/core/network/reference_api.dart').readAsString();
    final l10nSource = await File('lib/l10n/app_ru.arb').readAsString();

    final timezoneStart = source.indexOf('label: l10n.profileTimezone');
    final currencyStart = source.indexOf(
      'label: l10n.profileCurrency',
      timezoneStart,
    );

    expect(timezoneStart, isNonNegative);
    expect(currencyStart, greaterThan(timezoneStart));

    final timezoneSection = source.substring(timezoneStart, currencyStart);

    expect(referenceApiSource, contains('Future<List<ReferenceTimezone>>'));
    expect(referenceApiSource, contains("'/reference/timezones'"));
    expect(referenceApiSource, contains('class ReferenceTimezone'));
    expect(l10nSource, contains('profileTimezoneSearchHint'));
    expect(l10nSource, contains('profileTimezoneNoResults'));
    expect(source, contains('_timezoneSearchController'));
    expect(source, contains('List<ReferenceTimezone> _timezones'));
    expect(source, contains('Map<String, Set<String>> _timezoneSearchAliases'));
    expect(source, contains('_loadTimezones'));
    expect(source, contains('withDefaultReferenceTimezone('));
    expect(source, contains('timezoneSearchAliasMap('));
    expect(source, contains('timezoneFilterSearchHaystack('));
    expect(source, contains('referenceTimezoneLabel('));
    expect(source, contains('lang: timezoneLabelLang'));
    expect(source, contains('_selectedTimezone()'));
    expect(source, contains('_visibleTimezones()'));
    expect(source, contains('_selectTimezone'));
    expect(source, contains('class _ProfileTimezoneSearchField'));

    expect(timezoneSection, contains('_ProfileTimezoneSearchField('));
    expect(timezoneSection, contains('selectedTimezone: _selectedTimezone()'));
    expect(timezoneSection, contains('visibleTimezones: _visibleTimezones()'));
    expect(timezoneSection,
        contains('searchHint: l10n.profileTimezoneSearchHint'));
    expect(
        timezoneSection, contains('emptyLabel: l10n.profileTimezoneNoResults'));
    expect(timezoneSection, isNot(contains('_StyledTextField(')));
  });

  test('geolocation applies resolved timezone to the profile form', () async {
    final source = await File(
      'lib/screens/profile/edit_profile_screen.dart',
    ).readAsString();

    final methodStart = source.indexOf(
      'Future<void> _resolveLocationFromDevice()',
    );
    final methodEnd = source.indexOf(
      'Future<bool?> _showLocationConfirmDialog',
      methodStart,
    );

    expect(methodStart, isNonNegative);
    expect(methodEnd, greaterThan(methodStart));

    final methodSource = source.substring(methodStart, methodEnd);

    expect(methodSource, contains('await _loadTimezones();'));
    expect(methodSource, contains('resolveReferenceTimezoneForLocation('));
    expect(methodSource, contains('cityName: suggestion.cityName'));
    expect(methodSource, contains('countryCode: suggestion.countryCode'));
    expect(methodSource, contains('deviceTimezoneId: detectedTimezone'));
    expect(methodSource, contains('_timezoneController.text ='));
    expect(methodSource, contains('_timezoneSearchController.clear();'));
  });
}
