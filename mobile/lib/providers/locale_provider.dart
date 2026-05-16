import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider();

  static const _storageKey = 'flyfy_locale_code';

  Locale _locale = const Locale('ru');
  bool _isLoaded = false;

  Locale get locale => _locale;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_storageKey);

    if (savedCode != null && savedCode.trim().isNotEmpty) {
      _locale = Locale(savedCode.trim());
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    final normalized = code.trim();
    if (normalized.isEmpty) return;

    if (_locale.languageCode == normalized) return;

    _locale = Locale(normalized);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, normalized);

    notifyListeners();
  }
}
