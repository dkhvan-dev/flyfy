import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'profile settings starts with localized profile parameters only',
    () async {
      final source = await File(
        'lib/screens/profile/profile_settings_screen.dart',
      ).readAsString();

      final overviewStart = _headingIndex(
        source,
        'l10n.profileOverviewSectionTitle',
      );
      final accountStart = _headingIndex(
        source,
        'l10n.profileAccountSectionTitle',
      );

      expect(overviewStart, isNonNegative);
      expect(accountStart, isNonNegative);
      expect(overviewStart, lessThan(accountStart));

      expect(source, contains('ReferenceApi'));
      expect(source, contains('getCountry('));
      expect(source, contains('listTimezones('));
      expect(source, contains('listCurrencies('));
      expect(source, contains('normalizeReferenceCountryCode('));
      expect(source, contains('referenceTimezoneLabel('));
      expect(source, contains('referenceCurrencyLabel('));

      final overviewClassStart = source.indexOf('class _ProfileOverviewCard');
      final actionTileStart = source.indexOf('class _SettingsActionTile');
      expect(overviewClassStart, isNonNegative);
      expect(actionTileStart, greaterThan(overviewClassStart));

      final overviewSource = source.substring(
        overviewClassStart,
        actionTileStart,
      );
      expect(overviewSource, contains('l10n.profileCountry'));
      expect(overviewSource, contains('l10n.profileTimezone'));
      expect(overviewSource, contains('l10n.profileCurrency'));
      expect(overviewSource, isNot(contains('l10n.profileLocale')));
      expect(overviewSource, isNot(contains('profile.locale')));
    },
  );

  test('profile settings removes avatar hero and more section', () async {
    final settingsSource = await File(
      'lib/screens/profile/profile_settings_screen.dart',
    ).readAsString();
    final profileSource = await File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsString();

    expect(settingsSource, isNot(contains('_ProfileSettingsHero')));
    expect(settingsSource, isNot(contains('_SettingsAvatar')));
    expect(settingsSource, isNot(contains('_MiniPill')));
    expect(settingsSource, isNot(contains('FileApi')));
    expect(settingsSource, isNot(contains('profileMoreSectionTitle')));
    expect(settingsSource, isNot(contains('profileGuideWorkspaceTitle')));
    expect(settingsSource, isNot(contains('profileSupportTitle')));

    expect(profileSource, isNot(contains('profilePreferencesTitle')));
    expect(profileSource, isNot(contains('profileNotificationsRowTitle')));
    expect(profileSource, isNot(contains('profileSecurityRowTitle')));
    expect(profileSource, isNot(contains('profileSupportTitle')));
  });
}

int _headingIndex(String source, String titleExpression) {
  final pattern = RegExp(
    r'ProfileSectionHeading\s*\(\s*title:\s*' +
        RegExp.escape(titleExpression) +
        r'\s*,?\s*\)',
  );
  return pattern.firstMatch(source)?.start ?? -1;
}
