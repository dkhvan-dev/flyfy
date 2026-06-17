import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search placeholders omit redundant search verbs', () {
    final files = {
      'en': File('lib/l10n/app_en.arb'),
      'ru': File('lib/l10n/app_ru.arb'),
      'kk': File('lib/l10n/app_kk.arb'),
    };
    final explicitSearchHintKeys = {
      'storyPlaceHint',
      'storyCountryHint',
      'storyCityHint',
    };
    final forbiddenByLocale = {
      'en': RegExp(r'^\s*Search\b'),
      'ru': RegExp(r'^\s*(Поиск|Искать)\b', caseSensitive: false),
      'kk': RegExp(r'\bіздеу\b', caseSensitive: false),
    };

    for (final entry in files.entries) {
      final values =
          jsonDecode(entry.value.readAsStringSync()) as Map<String, dynamic>;
      final forbidden = forbiddenByLocale[entry.key]!;

      for (final valueEntry in values.entries) {
        final key = valueEntry.key;
        final value = valueEntry.value;
        final isSearchPlaceholder =
            key.endsWith('SearchHint') || explicitSearchHintKeys.contains(key);
        if (!isSearchPlaceholder || value is! String) continue;

        expect(
          forbidden.hasMatch(value),
          isFalse,
          reason: '${entry.value.path}: $key should not be "$value"',
        );
      }
    }
  });
}
