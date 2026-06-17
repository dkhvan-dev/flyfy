import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('currency converter screen is localized and adaptive', () async {
    final source = await File(
      'lib/screens/currency/currency_converter_screen.dart',
    ).readAsString();

    expect(source, contains('class CurrencyConverterScreen'));
    expect(source, contains('l10n.currencyConverterTitle'));
    expect(source, contains('l10n.currencyConverterYouSend'));
    expect(source, contains('l10n.currencyConverterYouReceive'));
    expect(source, contains('l10n.currencyConverterQuickSwitch'));
    expect(source, contains('class _CurrencyPickerScreen'));
    expect(source, contains('l10n.currencyConverterSelectCurrencyTitle'));
    expect(source, contains('l10n.currencyConverterSearchCurrencyHint'));
    expect(source, contains('_localizedCurrencyName(currency, l10n)'));
    expect(
      source,
      contains('class _CurrencyFlagPainter extends CustomPainter'),
    );
    expect(source, contains('String? _currencyFlagRegion(String code)'));
    expect(source, contains('SingleChildScrollView'));
    expect(source, contains('SafeArea'));
    expect(source, contains('Wrap('));
    expect(source, contains('TextOverflow.ellipsis'));
    expect(source, contains('CurrencyApi'));
    expect(source, isNot(contains('DropdownButtonFormField')));
    expect(source, isNot(contains('code.substring(0, 2)')));
  });

  test(
    'currency converter refreshes daily and shows date-only update label',
    () async {
      final source = await File(
        'lib/screens/currency/currency_converter_screen.dart',
      ).readAsString();

      expect(source, contains('Timer? _dailyRateRefreshTimer;'));
      expect(source, contains('Timer.periodic(const Duration(days: 1), (_) {'));
      expect(source, contains('_dailyRateRefreshTimer?.cancel();'));
      expect(source, contains('DateFormat.yMMMd('));
      expect(source, contains(').format(result!.rateAsOf!.toLocal())'));
      expect(source, isNot(contains('.add_Hm()')));
    },
  );

  test('currency picker search icon uses accent color', () async {
    final source = await File(
      'lib/screens/currency/currency_converter_screen.dart',
    ).readAsString();

    expect(source, contains('prefixIcon: const Icon('));
    expect(source, contains('Icons.search_rounded'));
    expect(source, contains('color: AppColors.accent'));
  });

  test('currency flag icon uses local vector flags instead of emoji', () async {
    final source = await File(
      'lib/screens/currency/currency_converter_screen.dart',
    ).readAsString();
    final flagIconStart = source.indexOf('class _CurrencyFlagIcon');
    final flagIconEnd = source.indexOf('CurrencyOption _currencyByCode');

    expect(flagIconStart, isNonNegative);
    expect(flagIconEnd, greaterThan(flagIconStart));

    final flagIconSource = source.substring(flagIconStart, flagIconEnd);

    expect(flagIconSource, contains('_currencyFlagRegion(code)'));
    expect(flagIconSource, contains('CustomPaint('));
    expect(flagIconSource, contains('_CurrencyFlagPainter('));
    expect(flagIconSource, contains('class _CurrencyFlagPainter'));
    expect(flagIconSource, isNot(contains('_CurrencyEmojiFlag')));
    expect(flagIconSource, isNot(contains('_currencyFlagEmoji')));
    expect(flagIconSource, isNot(contains('Apple Color Emoji')));
  });

  test('currency flag regions cover default currency options', () async {
    final source = await File(
      'lib/screens/currency/currency_converter_screen.dart',
    ).readAsString();

    for (final code in const [
      'AED',
      'CNY',
      'EUR',
      'GBP',
      'JPY',
      'KGS',
      'KRW',
      'KZT',
      'RUB',
      'TRY',
      'USD',
      'UZS',
    ]) {
      expect(source, contains("'$code':"));
    }
  });

  test(
    'currency flags cover every default option as compact inner flags',
    () async {
      final converterSource = await File(
        'lib/screens/currency/currency_converter_screen.dart',
      ).readAsString();
      final apiSource = await File(
        'lib/features/currency/data/currency_api.dart',
      ).readAsString();

      final defaultCurrencyCodes = RegExp(
        r"CurrencyOption\(code: '([A-Z]{3})'",
      ).allMatches(apiSource).map((match) => match.group(1)!).toSet();
      expect(defaultCurrencyCodes, isNotEmpty);

      final currencyFlagRegionsStart = converterSource.indexOf(
        'const _currencyFlagRegions = {',
      );
      expect(currencyFlagRegionsStart, isNonNegative);
      final currencyFlagRegionsEnd = converterSource.indexOf(
        '};',
        currencyFlagRegionsStart,
      );
      expect(currencyFlagRegionsEnd, greaterThan(currencyFlagRegionsStart));

      final currencyFlagRegionSource = converterSource.substring(
        currencyFlagRegionsStart,
        currencyFlagRegionsEnd,
      );
      final currencyFlagRegions = {
        for (final match in RegExp(
          r"'([A-Z]{3})': '([A-Z]{2})'",
        ).allMatches(currencyFlagRegionSource))
          match.group(1)!: match.group(2)!,
      };

      final missingRegionCodes = defaultCurrencyCodes
          .where((code) => !currencyFlagRegions.containsKey(code))
          .toList();
      expect(missingRegionCodes, isEmpty);

      final painterStart = converterSource.indexOf(
        'class _CurrencyFlagPainter',
      );
      final painterEnd = converterSource.indexOf(
        'class _CurrencyFallbackGlyph',
        painterStart,
      );
      expect(painterStart, isNonNegative);
      expect(painterEnd, greaterThan(painterStart));

      final painterSource = converterSource.substring(painterStart, painterEnd);
      final paintedRegions = RegExp(
        r"case '([A-Z]{2})':",
      ).allMatches(painterSource).map((match) => match.group(1)!).toSet();
      final missingPainterRegions = [
        for (final code in defaultCurrencyCodes)
          if (!paintedRegions.contains(currencyFlagRegions[code]))
            '$code:${currencyFlagRegions[code]}',
      ];
      expect(missingPainterRegions, isEmpty);

      expect(
        converterSource,
        contains('const _compactCurrencyFlagScale = 0.72;'),
      );
      expect(
        converterSource,
        contains('final innerSize = size * _compactCurrencyFlagScale;'),
      );
    },
  );

  test('home service grid links to the currency converter route', () async {
    final homeSource = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();
    final catalogSource = await File(
      'lib/features/services/service_catalog.dart',
    ).readAsString();
    final routerSource = await File(
      'lib/core/router/app_router.dart',
    ).readAsString();
    final ruArb = await File('lib/l10n/app_ru.arb').readAsString();
    final enArb = await File('lib/l10n/app_en.arb').readAsString();
    final kkArb = await File('lib/l10n/app_kk.arb').readAsString();

    expect(homeSource, contains('buildTravelServiceCatalog('));
    expect(catalogSource, contains('l10n.homeServiceCurrencyConverter'));
    expect(catalogSource, contains("route: '/currency-converter'"));
    expect(routerSource, contains("path: '/currency-converter'"));
    expect(routerSource, contains('CurrencyConverterScreen'));
    expect(ruArb, contains('homeServiceCurrencyConverter'));
    expect(enArb, contains('homeServiceCurrencyConverter'));
    expect(kkArb, contains('homeServiceCurrencyConverter'));
  });
}
