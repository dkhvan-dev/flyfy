import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/tours/models/create_tour_request.dart';

void main() {
  test('serializes attraction based guide offer payload for tour-service', () {
    final request = CreateTourRequest(
      landmarkId: 'attraction-id',
      landmarkName: 'Medeu',
      categorySlug: 'adventure',
      durationMinutes: 240,
      maxGroupSize: 8,
      languageCodes: const ['en', 'ru'],
      visibility: 'UNLISTED',
      meetingPoint: 'Hotel pickup',
      countryCode: 'KZ',
      cityName: 'Almaty',
      latitude: 43.238949,
      longitude: 76.889709,
      mapUrl: 'https://maps.example.test/medeu',
      priceAmount: 120,
      currency: 'USD',
      includedItems: const ['Private SUV', 'Gourmet picnic'],
      includedItemTranslations: const {
        'ru': ['Частный внедорожник', 'Пикник'],
        'kk': ['Жеке жол талғамайтын көлік', 'Пикник'],
      },
      itinerary: const [
        CreateTourItineraryItemRequest(
          startOffsetMinutes: 0,
          durationMinutes: 45,
          title: 'Hotel departure',
          description: 'Meet your guide and start the route.',
          translations: {
            'ru': CreateTourItineraryLocalizedCopyRequest(
              title: 'Выезд из отеля',
              description: 'Встреча с гидом и начало маршрута.',
            ),
            'kk': CreateTourItineraryLocalizedCopyRequest(
              title: 'Қонақүйден шығу',
              description: 'Гидпен кездесіп, маршрутты бастау.',
            ),
          },
        ),
      ],
      coverFileId: 'cover-file-id',
      productCoverFileId: 'attraction-cover-file-id',
    );

    expect(request.toJson(), {
      'landmarkId': 'attraction-id',
      'landmarkName': 'Medeu',
      'categorySlug': 'adventure',
      'durationMinutes': 240,
      'maxGroupSize': 8,
      'languageCodes': ['en', 'ru'],
      'visibility': 'UNLISTED',
      'meetingPoint': 'Hotel pickup',
      'countryCode': 'KZ',
      'cityName': 'Almaty',
      'latitude': 43.238949,
      'longitude': 76.889709,
      'mapUrl': 'https://maps.example.test/medeu',
      'priceAmount': 120.0,
      'currency': 'USD',
      'includedItems': ['Private SUV', 'Gourmet picnic'],
      'includedItemTranslations': {
        'ru': ['Частный внедорожник', 'Пикник'],
        'kk': ['Жеке жол талғамайтын көлік', 'Пикник'],
      },
      'itinerary': [
        {
          'startOffsetMinutes': 0,
          'durationMinutes': 45,
          'title': 'Hotel departure',
          'description': 'Meet your guide and start the route.',
          'translations': {
            'ru': {
              'title': 'Выезд из отеля',
              'description': 'Встреча с гидом и начало маршрута.',
            },
            'kk': {
              'title': 'Қонақүйден шығу',
              'description': 'Гидпен кездесіп, маршрутты бастау.',
            },
          },
        },
      ],
      'coverFileId': 'cover-file-id',
      'productCoverFileId': 'attraction-cover-file-id',
    });
  });

  test('omits optional blank fields from tour payload', () {
    final request = CreateTourRequest(
      landmarkId: 'attraction-id',
      categorySlug: 'cultural',
      durationMinutes: 90,
      maxGroupSize: 6,
      languageCodes: const ['en'],
      meetingPoint: 'Main square',
      priceAmount: 0,
      currency: 'KZT',
      itinerary: const [
        CreateTourItineraryItemRequest(
          startOffsetMinutes: 0,
          title: 'Meet and greet',
          description: 'Meet the guide and start exploring.',
        ),
      ],
    );

    final json = request.toJson();

    expect(json, isNot(contains('landmarkName')));
    expect(json, isNot(contains('title')));
    expect(json, isNot(contains('summary')));
    expect(json, isNot(contains('description')));
    expect(json, isNot(contains('tags')));
    expect(json, isNot(contains('includedItems')));
    expect(json, isNot(contains('coverFileId')));
    expect(json['visibility'], 'PUBLIC');
    expect(json['priceAmount'], 0.0);
  });

  test('serializes prepared translations without runtime translation', () {
    final request = CreateTourRequest(
      landmarkId: 'attraction-id',
      landmarkName: 'Шарын шатқалы',
      categorySlug: 'adventure',
      durationMinutes: 180,
      maxGroupSize: 6,
      languageCodes: const ['ru', 'kk'],
      meetingPoint: 'Вход в каньон',
      priceAmount: 45000,
      currency: 'KZT',
      productTranslations: const {
        'kk': CreateTourLocalizedCopyRequest(
          title: 'Шарын шатқалы',
          summary: 'Шарын шатқалы бойынша гид ұсыныстарын салыстырыңыз.',
          description: 'Гидті, тілді, бағаны және кездесу орнын таңдаңыз.',
        ),
      },
      itinerary: const [
        CreateTourItineraryItemRequest(
          startOffsetMinutes: 0,
          title: 'Старт',
          description: 'Встреча с гидом.',
        ),
      ],
    );

    expect(request.toJson(), isNot(contains('translations')));
    expect(
      request.toJson(),
      containsPair('productTranslations', {
        'kk': {
          'title': 'Шарын шатқалы',
          'summary': 'Шарын шатқалы бойынша гид ұсыныстарын салыстырыңыз.',
          'description': 'Гидті, тілді, бағаны және кездесу орнын таңдаңыз.',
        },
      }),
    );
  });
}
