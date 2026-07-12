import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/generated/app_localizations.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider({List<Locale>? systemLocales})
    : _locale = _resolveSystemLocale(
        systemLocales ?? WidgetsBinding.instance.platformDispatcher.locales,
      );

  static const storageKey = 'inflap_locale_code';

  Locale _locale;
  bool _isLoaded = false;

  Locale get locale => _locale;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = _supportedLocaleForCode(prefs.getString(storageKey));

    if (savedLocale != null) {
      _locale = savedLocale;
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    final nextLocale = _supportedLocaleForCode(code);
    if (nextLocale == null) return;

    final localeChanged = _locale.languageCode != nextLocale.languageCode;
    if (localeChanged) {
      _locale = nextLocale;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, nextLocale.languageCode);

    if (localeChanged) {
      notifyListeners();
    }
  }

  static Locale _resolveSystemLocale(List<Locale> systemLocales) {
    return basicLocaleListResolution(
      systemLocales,
      AppLocalizations.supportedLocales,
    );
  }

  static Locale? _supportedLocaleForCode(String? code) {
    final languageCode = code?.trim().toLowerCase().split(RegExp('[-_]')).first;
    if (languageCode == null || languageCode.isEmpty) return null;

    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == languageCode) return locale;
    }
    return null;
  }
}
