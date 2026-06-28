import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inflap/features/currency/models/currency_conversion_result.dart';
import 'package:inflap/features/places/models/place_vm.dart';
import 'package:inflap/features/places/place_ui.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/currency_rate_provider.dart';

void main() {
  test('PlaceVm parses feeDetails and costBreakdown aliases', () {
    final fromFeeDetails = PlaceVm.fromJson(_placeJson('feeDetails'));
    final fromCostBreakdown = PlaceVm.fromJson(_placeJson('costBreakdown'));

    for (final place in [fromFeeDetails, fromCostBreakdown]) {
      expect(place.feeDetails, hasLength(1));
      expect(place.feeDetails.single.title, 'Вход в национальный парк');
      expect(place.feeDetails.single.amount, 648.75);
      expect(place.feeDetails.single.currency, 'KZT');
      expect(place.feeDetails.single.unit, 'PERSON');
      expect(place.feeDetails.single.isApproximate, isTrue);
    }
  });

  test('PlaceVm parses structured visit planning blocks', () {
    final place = PlaceVm.fromJson(_planningPlaceJson());
    final info = place.visitInfo;

    expect(place.priceSummaryLabel, 'от 650 ₸');
    expect(info.priceNote, 'Наличными удобнее');
    expect(info.timeOnSite?.minMinutes, 90);
    expect(info.timeOnSite?.maxMinutes, 150);
    expect(info.carTravelTime?.minMinutes, 120);
    expect(info.roadCondition, 'GRAVEL');
    expect(info.season?.months, [5, 6, 7, 8, 9]);
    expect(info.season?.note, 'май–сентябрь');
    expect(place.feeDetails, hasLength(1));
    expect(place.feeDetails.single.type, 'ENTRANCE');
    expect(place.feeDetails.single.minAmount, 650);
    expect(place.feeDetails.single.maxAmount, 900);
    expect(place.feeDetails.single.isRequired, isTrue);
    expect(place.feeDetails.single.note, 'Цена примерная');
    expect(info.accessOptions, hasLength(1));
    expect(info.accessOptions.single.transportType, 'CAR');
    expect(info.accessOptions.single.requires4x4, isTrue);
    expect(info.accessOptions.single.routeHint, 'Ориентир — кордон');
    expect(info.practicalNotes.single.noteType, 'CONNECTION');
    expect(info.practicalNotes.single.body, 'Интернет пропадает');
    expect(info.recommendedItems.single.itemType, 'WATER');
    expect(info.recommendedItems.single.importance, 'REQUIRED');
  });

  testWidgets(
    'fee amount formatter uses profile currency when rate is loaded',
    (tester) async {
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
      final place = PlaceVm.fromJson(_placeJson('feeDetails'));

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
      final loadingLabel = formatPlaceFeeAmountLabel(
        capturedContext,
        l10n,
        place,
        place.feeDetails.single,
        preferredCurrency: 'USD',
        currencyRates: rateProvider,
      );
      expect(loadingLabel, contains('₸'));

      await tester.pump();

      final convertedLabel = formatPlaceFeeAmountLabel(
        capturedContext,
        l10n,
        place,
        place.feeDetails.single,
        preferredCurrency: 'USD',
        currencyRates: rateProvider,
      );
      expect(convertedLabel, contains('~'));
      expect(convertedLabel, contains(r'$'));
      expect(convertedLabel, contains('за человека'));
      expect(convertedLabel, isNot(contains('₸')));
    },
  );
}

Map<String, dynamic> _placeJson(String feeKey) {
  return {
    'id': 'place-1',
    'locale': 'ru',
    'defaultLocale': 'ru',
    'title': 'Пик Фурманова',
    'description': 'Маршрут через национальный парк',
    'countryCode': 'KZ',
    'cityId': 'almaty',
    'category': 'NATURE',
    'priceAmount': 648.75,
    'priceCurrency': 'KZT',
    'rating': 4.8,
    'reviewCount': 10,
    'source': 'IMPORT',
    'status': 'PUBLISHED',
    'tags': ['hiking'],
    'visitInfo': {
      feeKey: [
        {
          'title': 'Вход в национальный парк',
          'description': 'Примерный сбор за посещение',
          'amount': 648.75,
          'currency': 'KZT',
          'unit': 'PERSON',
          'isApproximate': true,
          'sortOrder': 10,
        },
      ],
    },
    'media': [],
    'author': {'userId': 'seed-author'},
    'createdAt': '2026-06-24T00:00:00Z',
    'updatedAt': '2026-06-24T00:00:00Z',
  };
}

Map<String, dynamic> _planningPlaceJson() {
  final json = _placeJson('feeItems');
  json['priceSummaryLabel'] = 'от 650 ₸';
  json['visitInfo'] = {
    'priceNote': 'Наличными удобнее',
    'timeOnSite': {'minMinutes': 90, 'maxMinutes': 150, 'note': 'Без спешки'},
    'carTravelTime': {
      'minMinutes': 120,
      'maxMinutes': 180,
      'note': 'От Алматы',
    },
    'roadCondition': 'GRAVEL',
    'season': {
      'months': [5, 6, 7, 8, 9],
      'note': 'май–сентябрь',
    },
    'feeItems': [
      {
        'type': 'ENTRANCE',
        'title': 'Вход',
        'description': 'Билет',
        'minAmount': 650,
        'maxAmount': 900,
        'currency': 'KZT',
        'unit': 'PERSON',
        'required': true,
        'isApproximate': true,
        'note': 'Цена примерная',
        'sortOrder': 10,
      },
    ],
    'accessOptions': [
      {
        'transportType': 'CAR',
        'durationMinMinutes': 120,
        'durationMaxMinutes': 180,
        'distanceKm': 92.5,
        'routeHint': 'Ориентир — кордон',
        'roadCondition': 'GRAVEL',
        'requires4x4': true,
        'parkingNote': 'Парковка у поста',
        'lastSegmentNote': 'Грунтовка',
        'note': 'После дождя осторожно',
        'sortOrder': 20,
      },
    ],
    'practicalNotes': [
      {
        'noteType': 'CONNECTION',
        'title': 'Связь',
        'body': 'Интернет пропадает',
        'priority': 'IMPORTANT',
        'sortOrder': 30,
      },
    ],
    'recommendedItems': [
      {
        'itemType': 'WATER',
        'title': 'Вода',
        'note': '1 литр',
        'importance': 'REQUIRED',
        'season': 'SUMMER',
        'sortOrder': 40,
      },
    ],
  };
  return json;
}
