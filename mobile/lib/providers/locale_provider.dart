import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider();

  static const _storageKey = 'flyfy_locale_code';

  Locale _locale = const Locale('ru');

  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_storageKey);

    if (savedCode != null && savedCode.isNotEmpty) {
      _locale = Locale(savedCode);
      notifyListeners();
      return;
    }
  }

  Future<void> setLocale(String code) async {
    _locale = Locale(code);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, code);

    notifyListeners();
  }
}