import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/places/models/place_vm.dart';
import 'package:inflap/features/places/place_ui.dart';

void main() {
  test('initial place content is only displayable in the active locale', () {
    expect(
      canDisplayInitialPlaceForLocale(_place(locale: 'en'), const Locale('ru')),
      isFalse,
    );
    expect(
      canDisplayInitialPlaceForLocale(
        _place(locale: 'ru-KZ'),
        const Locale('ru'),
      ),
      isTrue,
    );
    expect(canDisplayInitialPlaceForLocale(null, const Locale('ru')), isFalse);
  });
}

PlaceVm _place({required String locale}) {
  return PlaceVm(
    id: 'place-1',
    locale: locale,
    defaultLocale: 'en',
    title: 'Medeu',
    description: 'Mountain rink',
    countryCode: 'KZ',
    cityId: 'almaty',
    locationSourceUrl: 'https://maps.example.test/medeu',
    category: 'ENTERTAINMENT',
    priceAmount: 1000,
    priceCurrency: 'KZT',
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
