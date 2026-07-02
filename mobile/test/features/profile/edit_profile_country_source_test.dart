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
      final currencyStart = source.indexOf(
        'label: l10n.profileCurrency',
        countryStart,
      );

      expect(countryStart, isNonNegative);
      expect(currencyStart, greaterThan(countryStart));

      final countrySection = source.substring(countryStart, currencyStart);

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
      expect(countrySection, contains('searchHint:'));
      expect(
        countrySection,
        contains('l10n.excursionsFilterCountrySearchHint'),
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
    final l10nSource = await File('lib/l10n/app_ru.arb').readAsString();

    final countryStart = source.indexOf('label: l10n.profileCountry');
    final currencyStart = source.indexOf(
      'label: l10n.profileCurrency',
      countryStart,
    );

    expect(countryStart, isNonNegative);
    expect(currencyStart, greaterThan(countryStart));

    final countrySection = source.substring(countryStart, currencyStart);
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
    expect(
      countryFieldSource,
      isNot(contains('selectedCountryCode ?? searchHint')),
    );
    expect(
      countryFieldSource,
      contains('errorText: hasSelection ? null : errorText'),
    );
  });

  test('save scrolls to first missing required profile field', () async {
    final source = await File(
      'lib/screens/profile/edit_profile_screen.dart',
    ).readAsString();

    expect(source, contains('final _firstNameFieldKey = GlobalKey()'));
    expect(source, contains('final _lastNameFieldKey = GlobalKey()'));
    expect(source, contains('final _countryFieldKey = GlobalKey()'));
    expect(
      source,
      contains('Future<void> _scrollToFirstInvalidRequiredField()'),
    );
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

  test(
    'edit profile screen uses edit title and omits service cities',
    () async {
      final source = await File(
        'lib/screens/profile/edit_profile_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('_EditProfileTopBar(title: l10n.editProfileButton)'),
      );
      expect(source, isNot(contains('title.toUpperCase()')));
      expect(source, isNot(contains('profileSettingsPageTitle')));
      expect(source, isNot(contains('serviceCityChips')));
      expect(source, isNot(contains('profileSettingsServiceCitiesSection')));
      expect(
        source,
        isNot(contains('profileSettingsServiceCitiesUnavailable')),
      );
      expect(source, isNot(contains('class _ServiceChip')));
    },
  );

  test('edit profile does not expose profile timezone setting', () async {
    final source = await File(
      'lib/screens/profile/edit_profile_screen.dart',
    ).readAsString();

    expect(source, isNot(contains('label: l10n.profileTimezone')));
    expect(source, isNot(contains('_timezoneController')));
    expect(source, isNot(contains('_timezoneSearchController')));
    expect(source, isNot(contains('List<ReferenceTimezone> _timezones')));
    expect(source, isNot(contains('_loadTimezones')));
    expect(source, isNot(contains('timezone: _timezoneController.text')));
    expect(source, isNot(contains('class _ProfileTimezoneSearchField')));
    expect(source, isNot(contains('_prefillTimezoneFromDevice')));
  });

  test(
    'edit profile currency uses localized searchable reference selector',
    () async {
      final source = await File(
        'lib/screens/profile/edit_profile_screen.dart',
      ).readAsString();
      final referenceApiSource = await File(
        'lib/core/network/reference_api.dart',
      ).readAsString();
      final l10nSource = await File('lib/l10n/app_ru.arb').readAsString();

      final currencyStart = source.indexOf('label: l10n.profileCurrency');
      final phoneVerificationStart = source.indexOf(
        '_buildPhoneVerificationSection',
        currencyStart,
      );

      expect(currencyStart, isNonNegative);
      expect(phoneVerificationStart, greaterThan(currencyStart));

      final currencySection = source.substring(
        currencyStart,
        phoneVerificationStart,
      );

      expect(referenceApiSource, contains('Future<List<ReferenceCurrency>>'));
      expect(referenceApiSource, contains("'/reference/currencies'"));
      expect(referenceApiSource, contains('class ReferenceCurrency'));
      expect(l10nSource, contains('profileCurrencySearchHint'));
      expect(l10nSource, contains('profileCurrencyNoResults'));
      expect(
        source,
        contains("import '../../core/reference/currency_filter_utils.dart';"),
      );
      expect(source, contains('_currencySearchController'));
      expect(source, contains('List<ReferenceCurrency> _currencies'));
      expect(
        source,
        contains('Map<String, Set<String>> _currencySearchAliases'),
      );
      expect(source, contains('_loadCurrencies'));
      expect(source, contains('withDefaultReferenceCurrency('));
      expect(source, contains('currencySearchAliasMap('));
      expect(source, contains('currencyFilterSearchHaystack('));
      expect(source, contains('referenceCurrencyLabel('));
      expect(source, contains('_selectedCurrency()'));
      expect(source, contains('_visibleCurrencies()'));
      expect(source, contains('_selectCurrency'));
      expect(source, contains('class _ProfileCurrencySearchField'));

      expect(currencySection, contains('_ProfileCurrencySearchField('));
      expect(
        currencySection,
        contains('selectedCurrency: _selectedCurrency()'),
      );
      expect(
        currencySection,
        contains('visibleCurrencies: _visibleCurrencies()'),
      );
      expect(
        currencySection,
        contains('searchHint: l10n.profileCurrencySearchHint'),
      );
      expect(
        currencySection,
        contains('emptyLabel: l10n.profileCurrencyNoResults'),
      );
      expect(currencySection, isNot(contains('_StyledTextField(')));
    },
  );

  test(
    'edit profile does not detect device location for citizenship',
    () async {
      final source = await File(
        'lib/screens/profile/edit_profile_screen.dart',
      ).readAsString();

      expect(source, isNot(contains('DeviceContextService')));
      expect(source, isNot(contains('_resolveLocationFromDevice')));
      expect(source, isNot(contains('_showLocationConfirmDialog')));
      expect(source, isNot(contains('detectLocationButton')));
      expect(source, isNot(contains('useDetectedLocationTitle')));
    },
  );
}
