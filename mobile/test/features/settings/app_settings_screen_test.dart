import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/features/settings/presentation/app_settings_screen.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/auth_provider.dart';
import 'package:inflap/providers/locale_provider.dart';
import 'package:inflap/providers/theme_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('guest settings expose account and app preferences', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final localeProvider = LocaleProvider(systemLocales: const [Locale('en')]);
    final themeModeProvider = ThemeModeProvider();
    await localeProvider.load();
    await themeModeProvider.load();
    addTearDown(localeProvider.dispose);
    addTearDown(themeModeProvider.dispose);

    await tester.pumpWidget(
      _buildApp(
        localeProvider: localeProvider,
        themeModeProvider: themeModeProvider,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('app-settings-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('app-settings-login-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('app-settings-register-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('app-language-preference')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('app-theme-preference')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest can persist language and theme without signing in', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final localeProvider = LocaleProvider(systemLocales: const [Locale('en')]);
    final themeModeProvider = ThemeModeProvider();
    await localeProvider.load();
    await themeModeProvider.load();
    addTearDown(localeProvider.dispose);
    addTearDown(themeModeProvider.dispose);

    await tester.pumpWidget(
      _buildApp(
        localeProvider: localeProvider,
        themeModeProvider: themeModeProvider,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('app-language-preference')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();

    expect(localeProvider.locale.languageCode, 'ru');

    await tester.tap(find.byKey(const ValueKey('app-theme-mode-dark')));
    await tester.pumpAndSettle();

    expect(themeModeProvider.selectedMode, AppThemeModePreference.dark);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(LocaleProvider.storageKey), 'ru');
    expect(
      preferences.getString(ThemeModeProvider.storageKey),
      AppThemeModePreference.dark.name,
    );
    expect(
      preferences.getBool(ThemeModeProvider.explicitSelectionStorageKey),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest settings stay usable on compact screens with large text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);

    final localeProvider = LocaleProvider(systemLocales: const [Locale('kk')]);
    final themeModeProvider = ThemeModeProvider();
    await localeProvider.load();
    await themeModeProvider.load();
    addTearDown(localeProvider.dispose);
    addTearDown(themeModeProvider.dispose);

    await tester.pumpWidget(
      _buildApp(
        localeProvider: localeProvider,
        themeModeProvider: themeModeProvider,
        textScaler: const TextScaler.linear(1.35),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('app-settings-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('app-settings-login-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _buildApp({
  required LocaleProvider localeProvider,
  required ThemeModeProvider themeModeProvider,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => _GuestAuthProvider()),
      ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ChangeNotifierProvider<ThemeModeProvider>.value(value: themeModeProvider),
    ],
    child: Consumer2<LocaleProvider, ThemeModeProvider>(
      builder: (context, locale, themeMode, child) {
        return MaterialApp(
          locale: locale.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppDesignSystem.lightTheme(),
          darkTheme: AppDesignSystem.darkTheme(),
          themeMode: themeMode.themeMode,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child!,
            );
          },
          home: const AppSettingsScreen(),
        );
      },
    ),
  );
}

class _GuestAuthProvider extends AuthProvider {
  @override
  AuthState get state => AuthState.unauthenticated;
}
