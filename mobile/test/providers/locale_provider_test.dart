import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'first launch resolves locale from prioritized system languages',
    () async {
      SharedPreferences.setMockInitialValues({});

      final provider = LocaleProvider(
        systemLocales: const [Locale('de', 'DE'), Locale('kk', 'KZ')],
      );

      expect(provider.locale, const Locale('kk'));
      expect(provider.isLoaded, isFalse);

      await provider.load();

      expect(provider.locale, const Locale('kk'));
      expect(provider.isLoaded, isTrue);
    },
  );

  test('unsupported system languages fall back to English', () async {
    SharedPreferences.setMockInitialValues({});

    final provider = LocaleProvider(
      systemLocales: const [Locale('de', 'DE'), Locale('fr', 'FR')],
    );

    expect(provider.locale, const Locale('en'));

    await provider.load();

    expect(provider.locale, const Locale('en'));
  });

  test('saved user locale overrides the system locale', () async {
    SharedPreferences.setMockInitialValues({LocaleProvider.storageKey: 'ru'});

    final provider = LocaleProvider(systemLocales: const [Locale('kk', 'KZ')]);

    expect(provider.locale, const Locale('kk'));

    await provider.load();

    expect(provider.locale, const Locale('ru'));
  });

  test('explicit locale selection persists across launches', () async {
    SharedPreferences.setMockInitialValues({});

    final provider = LocaleProvider(systemLocales: const [Locale('en', 'US')]);
    await provider.load();
    await provider.setLocale('kk-KZ');

    expect(provider.locale, const Locale('kk'));

    final reloaded = LocaleProvider(systemLocales: const [Locale('ru', 'RU')]);
    await reloaded.load();

    expect(reloaded.locale, const Locale('kk'));
  });

  test(
    'selecting current system language still records explicit choice',
    () async {
      SharedPreferences.setMockInitialValues({});

      final provider = LocaleProvider(
        systemLocales: const [Locale('en', 'US')],
      );
      await provider.load();
      await provider.setLocale('en');

      final reloaded = LocaleProvider(
        systemLocales: const [Locale('ru', 'RU')],
      );
      await reloaded.load();

      expect(reloaded.locale, const Locale('en'));
    },
  );

  test('unsupported explicit locale is ignored', () async {
    SharedPreferences.setMockInitialValues({});

    final provider = LocaleProvider(systemLocales: const [Locale('ru', 'RU')]);
    await provider.load();
    await provider.setLocale('de');

    expect(provider.locale, const Locale('ru'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(LocaleProvider.storageKey), isFalse);
  });
}
