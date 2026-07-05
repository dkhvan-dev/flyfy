import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile settings screen uses V2 design colors only', () async {
    final source = await File(
      'lib/screens/profile/profile_settings_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.screenGradientColors'));
    expect(source, contains('colors.primary'));
    expect(source, isNot(contains('AppPalette.')));
  });

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
      expect(source, contains('listCurrencies('));
      expect(source, contains('normalizeReferenceCountryCode('));
      expect(source, contains('normalizeReferenceCurrencyCode('));
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
      expect(overviewSource, isNot(contains('l10n.profileTimezone')));
      expect(overviewSource, isNot(contains('profile.timezone')));
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

  test(
    'profile settings opens app theme sheet below app language action',
    () async {
      final source = await File(
        'lib/screens/profile/profile_settings_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../providers/theme_mode_provider.dart';"),
      );
      expect(source, contains('Future<void> _openAppThemeSettings()'));
      expect(source, contains('context.read<ThemeModeProvider>()'));
      expect(source, contains('AppThemeModePreference.values'));
      expect(source, contains('RadioListTile<AppThemeModePreference>'));

      final languageAction = source.indexOf('title: l10n.appLanguageTitle');
      final themeIcon = source.indexOf(
        'icon: Icons.contrast_rounded',
        languageAction,
      );
      final themeAction = source.indexOf(
        'title: l10n.appThemeTitle',
        themeIcon,
      );
      final notificationsAction = source.indexOf(
        'title: l10n.profileNotificationsRowTitle',
      );

      expect(languageAction, isNonNegative);
      expect(themeIcon, greaterThan(languageAction));
      expect(themeAction, greaterThan(languageAction));
      expect(themeAction, greaterThan(themeIcon));
      expect(notificationsAction, greaterThan(themeAction));

      final themeTileSource = source.substring(themeIcon, notificationsAction);
      expect(themeTileSource, contains('Icons.contrast_rounded'));
      expect(themeTileSource, contains('_themeModeLabel(l10n'));
      expect(themeTileSource, contains('onTap: _openAppThemeSettings'));
    },
  );

  test('main app listens to persisted app theme mode', () async {
    final source = await File('lib/main.dart').readAsString();
    final designSystemSource = await File(
      'lib/core/ui/app_design_system.dart',
    ).readAsString();

    expect(source, contains("import 'providers/theme_mode_provider.dart';"));
    expect(
      source,
      contains('late final ThemeModeProvider _themeModeProvider;'),
    );
    expect(source, contains('_themeModeProvider = ThemeModeProvider();'));
    expect(
      source,
      contains('ChangeNotifierProvider<ThemeModeProvider>.value('),
    );
    expect(source, contains('value: _themeModeProvider'));
    expect(source, contains('Consumer2<LocaleProvider, ThemeModeProvider>'));
    expect(source, contains('themeMode: themeModeProvider.themeMode'));
    expect(source, contains('theme: AppDesignSystem.lightTheme()'));
    expect(source, contains('darkTheme: AppDesignSystem.darkTheme()'));
    expect(source, contains('unawaited(_themeModeProvider.load())'));

    expect(designSystemSource, contains('static ThemeData lightTheme()'));
    expect(designSystemSource, contains('static ThemeData light()'));
    expect(designSystemSource, contains('Brightness.light'));
  });

  test('profile settings action subtitles do not end with periods', () async {
    final ruArb = await File('lib/l10n/app_ru.arb').readAsString();
    final enArb = await File('lib/l10n/app_en.arb').readAsString();
    final kkArb = await File('lib/l10n/app_kk.arb').readAsString();

    expect(
      ruArb,
      contains(
        '"profileSettingsEditSubtitle": "Измените имя, фото, описание и базовые данные профиля"',
      ),
    );
    expect(
      ruArb,
      contains(
        '"profileNotificationsRowSubtitle": "Push, email и SMS-уведомления по вашим активностям"',
      ),
    );
    expect(
      ruArb,
      contains('"appThemeSubtitle": "Светлая, темная или как в системе"'),
    );
    expect(
      ruArb,
      contains(
        '"profileSecurityRowSubtitle": "Защита аккаунта, экспорт данных и настройки приватности"',
      ),
    );

    expect(
      enArb,
      contains(
        '"profileSettingsEditSubtitle": "Update your name, photo, bio, and core profile details"',
      ),
    );
    expect(
      enArb,
      contains(
        '"profileNotificationsRowSubtitle": "Push, email, and SMS updates for your activity flow"',
      ),
    );
    expect(
      enArb,
      contains('"appThemeSubtitle": "Light, dark, or system default"'),
    );
    expect(
      enArb,
      contains(
        '"profileSecurityRowSubtitle": "Account protection, data export, and privacy controls"',
      ),
    );

    expect(
      kkArb,
      contains(
        '"profileSettingsEditSubtitle": "Атыңызды, фотоңызды, биоңызды және негізгі профиль деректерін өзгертіңіз"',
      ),
    );
    expect(
      kkArb,
      contains(
        '"profileNotificationsRowSubtitle": "Белсенділіктерге қатысты push, email және SMS жаңартулары"',
      ),
    );
    expect(
      kkArb,
      contains('"appThemeSubtitle": "Жарық, қараңғы немесе жүйе бойынша"'),
    );
    expect(
      kkArb,
      contains(
        '"profileSecurityRowSubtitle": "Аккаунт қорғанысы, деректерді экспорттау және құпиялылық баптаулары"',
      ),
    );
  });

  test('profile settings logout dialog uses amber branded chrome', () async {
    final source = await File(
      'lib/screens/profile/profile_settings_screen.dart',
    ).readAsString();
    final dialogStart = source.indexOf('class _LogoutConfirmDialog');

    expect(dialogStart, isNonNegative);

    final dialogSource = source.substring(dialogStart);

    expect(source, contains('_LogoutConfirmDialog('));
    expect(source, isNot(contains('return AlertDialog(')));
    expect(dialogSource, contains('Dialog('));
    expect(dialogSource, contains('colors.primary'));
    expect(dialogSource, contains('LinearGradient('));
    expect(dialogSource, contains('colors.screenGradientColors'));
    expect(dialogSource, contains('Icons.logout_rounded'));
    expect(dialogSource, contains('profileScaled(context'));
    expect(dialogSource, contains('SafeArea('));
    expect(dialogSource, contains('ConstrainedBox('));
  });

  test('profile settings exposes debug network inspector below logout', () async {
    final source = await File(
      'lib/screens/profile/profile_settings_screen.dart',
    ).readAsString();
    final enArb = await File('lib/l10n/app_en.arb').readAsString();
    final ruArb = await File('lib/l10n/app_ru.arb').readAsString();
    final kkArb = await File('lib/l10n/app_kk.arb').readAsString();

    expect(
      source,
      contains("import '../../core/network/debug_network_inspector.dart';"),
    );
    expect(source, contains('void _openDebugNetworkInspector()'));
    expect(source, contains('DebugNetworkInspector.open();'));

    final logoutButton = source.indexOf('l10n.logoutButton');
    final debugGate = source.indexOf(
      'if (DebugNetworkInspector.isEnabled)',
      logoutButton,
    );
    final debugIcon = source.indexOf('Icons.bug_report_outlined', debugGate);
    final debugTitle = source.indexOf(
      'l10n.profileDebugNetworkInspectorTitle',
      debugIcon,
    );
    final debugAction = source.indexOf(
      'onPressed: _openDebugNetworkInspector',
      debugGate,
    );

    expect(logoutButton, isNonNegative);
    expect(debugGate, greaterThan(logoutButton));
    expect(debugIcon, greaterThan(debugGate));
    expect(debugTitle, greaterThan(debugIcon));
    expect(debugAction, greaterThan(debugGate));

    expect(
      enArb,
      contains('"profileDebugNetworkInspectorTitle": "Network inspector"'),
    );
    expect(
      enArb,
      contains(
        '"profileDebugNetworkInspectorSubtitle": "Open Chucker requests and responses"',
      ),
    );
    expect(
      ruArb,
      contains('"profileDebugNetworkInspectorTitle": "Инспектор сети"'),
    );
    expect(
      ruArb,
      contains(
        '"profileDebugNetworkInspectorSubtitle": "Открыть запросы и ответы Chucker"',
      ),
    );
    expect(
      kkArb,
      contains('"profileDebugNetworkInspectorTitle": "Желі инспекторы"'),
    );
    expect(
      kkArb,
      contains(
        '"profileDebugNetworkInspectorSubtitle": "Chucker сұраулары мен жауаптарын ашу"',
      ),
    );
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
