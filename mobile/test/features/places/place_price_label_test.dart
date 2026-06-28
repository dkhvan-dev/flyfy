import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inflap/features/currency/models/currency_conversion_result.dart';
import 'package:inflap/features/places/models/place_vm.dart';
import 'package:inflap/features/places/place_ui.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/currency_rate_provider.dart';

void main() {
  testWidgets('place price label uses free entry and from-price copy', (
    tester,
  ) async {
    late String freeLabel;
    late String paidLabel;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            freeLabel = formatPlacePriceLabel(
              context,
              l10n,
              _place(priceAmount: 0, priceCurrency: 'KZT'),
            );
            paidLabel = formatPlacePriceLabel(
              context,
              l10n,
              _place(priceAmount: 1000, priceCurrency: 'KZT'),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(freeLabel, 'Бесплатно');
    expect(paidLabel, startsWith('от '));
    expect(paidLabel, contains('₸'));
  });

  testWidgets('place price label uses profile currency when rate is loaded', (
    tester,
  ) async {
    late BuildContext capturedContext;
    final rateProvider = CurrencyRateProvider(
      latestRates: ({required baseCurrency, required quoteCurrencies}) async {
        return const CurrencyRateSnapshot(
          baseCurrency: 'KZT',
          rates: {'USD': 0.002},
          rateAsOf: null,
          provider: 'test',
          stale: false,
        );
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final l10n = AppLocalizations.of(capturedContext)!;
    final place = _place(priceAmount: 1000, priceCurrency: 'KZT');
    final loadingLabel = formatPlacePriceLabel(
      capturedContext,
      l10n,
      place,
      preferredCurrency: 'USD',
      currencyRates: rateProvider,
    );
    expect(loadingLabel, contains('₸'));

    await tester.pump();

    final convertedLabel = formatPlacePriceLabel(
      capturedContext,
      l10n,
      place,
      preferredCurrency: 'USD',
      currencyRates: rateProvider,
    );
    expect(convertedLabel, startsWith('от '));
    expect(convertedLabel, contains(r'$'));
    expect(convertedLabel, contains('2'));
    expect(convertedLabel, isNot(contains('₸')));
  });

  testWidgets(
    'place price label can use backend summary when amount is absent',
    (tester) async {
      late String label;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              label = formatPlacePriceLabel(
                context,
                l10n,
                _place(
                  priceAmount: null,
                  priceCurrency: null,
                  priceSummaryLabel: 'от 650 ₸',
                ),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(label, 'от 650 ₸');
    },
  );
}

PlaceVm _place({
  required double? priceAmount,
  required String? priceCurrency,
  String? priceSummaryLabel,
}) {
  return PlaceVm(
    id: 'place-1',
    locale: 'ru',
    defaultLocale: 'ru',
    title: 'Медеу',
    description: 'Каток в горах',
    countryCode: 'KZ',
    cityId: 'almaty',
    locationSourceUrl: 'https://maps.example.test/medeu',
    category: 'ENTERTAINMENT',
    priceAmount: priceAmount,
    priceCurrency: priceCurrency,
    priceSummaryLabel: priceSummaryLabel,
    rating: 4.8,
    reviewCount: 0,
    source: 'IMPORT',
    status: 'PUBLISHED',
    tags: const ['almaty'],
    visitInfo: PlaceVisitInfoVm.empty,
    translations: const {},
    media: const [],
    author: const PlaceAuthorVm(userId: 'seed-author'),
    createdAt: '2026-06-22T00:00:00Z',
    updatedAt: '2026-06-22T00:00:00Z',
  );
}
