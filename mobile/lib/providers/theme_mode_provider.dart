import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeModePreference { system, light, dark }

class ThemeModeProvider extends ChangeNotifier {
  static const storageKey = 'inflap_theme_mode';

  AppThemeModePreference _selectedMode = AppThemeModePreference.system;
  bool _isLoaded = false;

  AppThemeModePreference get selectedMode => _selectedMode;
  bool get isLoaded => _isLoaded;

  ThemeMode get themeMode {
    return switch (_selectedMode) {
      AppThemeModePreference.system => ThemeMode.system,
      AppThemeModePreference.light => ThemeMode.light,
      AppThemeModePreference.dark => ThemeMode.dark,
    };
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedMode = _parse(prefs.getString(storageKey));
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeModePreference mode) async {
    if (_selectedMode == mode) return;

    _selectedMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, mode.name);
    notifyListeners();
  }

  static AppThemeModePreference _parse(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final mode in AppThemeModePreference.values) {
      if (mode.name == normalized) return mode;
    }
    return AppThemeModePreference.system;
  }
}
