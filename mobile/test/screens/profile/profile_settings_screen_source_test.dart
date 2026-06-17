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
      expect(source, contains('normalizeReferenceCurrencyCode('));
      expect(source, contains('referenceTimezoneLabel('));
      expect(source, contains('withDefaultReferenceCurrency('));
      expect(source, contains('_currencyCodeWithSymbol('));
      expect(source, contains(r"'$code ($symbol)'"));

      final overviewClassStart = source.indexOf('class _ProfileOverviewCard');
      final actionTileStart = source.indexOf('class _SettingsActionTile');
      expect(overviewClassStart, isNonNegative);
      expect(actionTileStart, greaterThan(overviewClassStart));

      final overviewSource = source.substring(
        overviewClassStart,
        actionTileStart,
      );
      expect(overviewSource, contains('l10n.profileFullName'));
      expect(overviewSource, contains('profile.fullName'));
      expect(overviewSource, contains('l10n.profilePhone'));
      expect(overviewSource, contains('profile.primaryPhoneDisplay'));
      expect(overviewSource, contains('l10n.profileCountry'));
      expect(overviewSource, contains('labels?.country'));
      expect(overviewSource, contains('l10n.profileTimezone'));
      expect(overviewSource, contains('l10n.profileCurrency'));
      expect(overviewSource, contains('labels?.currency'));
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

  test(
    'profile settings opens app language sheet below edit profile action',
    () async {
      final source = await File(
        'lib/screens/profile/profile_settings_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../core/ui/app_language_sheet.dart';"),
      );
      expect(source, contains('Future<void> _openAppLanguageSettings()'));
      expect(source, contains('showAppLanguageSheet(context)'));

      final editAction = source.indexOf('title: l10n.editProfileButton');
      final languageIcon = source.indexOf(
        'icon: Icons.language_rounded',
        editAction,
      );
      final languageAction = source.indexOf('title: l10n.appLanguageTitle');
      final notificationsAction = source.indexOf(
        'title: l10n.profileNotificationsRowTitle',
      );

      expect(editAction, isNonNegative);
      expect(languageIcon, greaterThan(editAction));
      expect(languageAction, greaterThan(editAction));
      expect(languageAction, greaterThan(languageIcon));
      expect(notificationsAction, greaterThan(languageAction));

      final languageTileSource = source.substring(
        languageIcon,
        notificationsAction,
      );
      expect(languageTileSource, contains('Icons.language_rounded'));
      expect(languageTileSource, contains('l10n.profileLocale'));
      expect(languageTileSource, contains('onTap: _openAppLanguageSettings'));
    },
  );
}

int _headingIndex(String source, String titleExpression) {
  final pattern = RegExp(
    r'ProfileSectionHeading\s*\(\s*title:\s*' +
        RegExp.escape(titleExpression) +
        r'\s*,?\s*\)',
  );
  return pattern.firstMatch(source)?.start ?? -1;
}
