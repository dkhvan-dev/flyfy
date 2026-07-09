import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/providers/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('theme mode provider defaults to system mode', () async {
    SharedPreferences.setMockInitialValues({});

    final provider = ThemeModeProvider();
    await provider.load();

    expect(provider.themeMode, ThemeMode.system);
    expect(provider.selectedMode, AppThemeModePreference.system);
  });

  test(
    'theme mode provider persists explicit light and dark choices',
    () async {
      SharedPreferences.setMockInitialValues({});

      final provider = ThemeModeProvider();
      await provider.load();

      await provider.setThemeMode(AppThemeModePreference.light);
      expect(provider.themeMode, ThemeMode.light);

      final reloadedLight = ThemeModeProvider();
      await reloadedLight.load();
      expect(reloadedLight.selectedMode, AppThemeModePreference.light);
      expect(reloadedLight.themeMode, ThemeMode.light);

      await reloadedLight.setThemeMode(AppThemeModePreference.dark);
      final reloadedDark = ThemeModeProvider();
      await reloadedDark.load();
      expect(reloadedDark.selectedMode, AppThemeModePreference.dark);
      expect(reloadedDark.themeMode, ThemeMode.dark);
    },
  );

  test(
    'theme mode provider falls back to system for invalid stored value',
    () async {
      SharedPreferences.setMockInitialValues({
        ThemeModeProvider.storageKey: 'sepia',
      });

      final provider = ThemeModeProvider();
      await provider.load();

      expect(provider.selectedMode, AppThemeModePreference.system);
      expect(provider.themeMode, ThemeMode.system);
    },
  );

  test(
    'theme mode provider ignores legacy stored mode without explicit selection marker',
    () async {
      SharedPreferences.setMockInitialValues({
        ThemeModeProvider.storageKey: 'dark',
      });

      final provider = ThemeModeProvider();
      await provider.load();

      expect(provider.selectedMode, AppThemeModePreference.system);
      expect(provider.themeMode, ThemeMode.system);
    },
  );
}
