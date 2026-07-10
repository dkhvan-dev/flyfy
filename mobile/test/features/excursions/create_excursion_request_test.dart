import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/excursions/models/create_excursion_request.dart';

void main() {
  test('serializes place based guide offer payload for excursion-service', () {
    final request = CreateExcursionRequest(
      sourceLanguage: 'en',
      landmarkId: 'place-id',
      landmarkName: 'Medeu',
      categorySlug: 'adventure',
      durationMinutes: 240,
      maxGroupSize: 8,
      languageCodes: const ['en', 'ru'],
      visibility: 'UNLISTED',
      meetingPoint: 'Hotel pickup',
      countryCode: 'KZ',
      departureCityId: 'almaty',
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
        CreateExcursionItineraryItemRequest(
          startOffsetMinutes: 0,
          durationMinutes: 45,
          title: 'Hotel departure',
          description: 'Meet your guide and start the route.',
          translations: {
            'ru': CreateExcursionItineraryLocalizedCopyRequest(
              title: 'Выезд из отеля',
              description: 'Встреча с гидом и начало маршрута.',
            ),
            'kk': CreateExcursionItineraryLocalizedCopyRequest(
              title: 'Қонақүйден шығу',
              description: 'Гидпен кездесіп, маршрутты бастау.',
            ),
          },
        ),
      ],
      coverFileId: 'cover-file-id',
      productCoverFileId: 'place-cover-file-id',
      productCoverImageUrl: 'https://upload.wikimedia.org/place.jpg',
      photoFileIds: const ['cover-file-id', 'gallery-file-2'],
      productPhotoFileIds: const ['place-cover-file-id'],
      productPhotoImageUrls: const [
        'https://upload.wikimedia.org/place.jpg',
        'https://upload.wikimedia.org/place-2.jpg',
      ],
    );

    expect(request.toJson(), {
      'sourceLanguage': 'en',
      'landmarkId': 'place-id',
      'landmarkName': 'Medeu',
      'categorySlug': 'adventure',
      'durationMinutes': 240,
      'maxGroupSize': 8,
      'languageCodes': ['en', 'ru'],
      'visibility': 'UNLISTED',
      'meetingPoint': 'Hotel pickup',
      'countryCode': 'KZ',
      'departureCityId': 'almaty',
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
      'productCoverFileId': 'place-cover-file-id',
      'productCoverImageUrl': 'https://upload.wikimedia.org/place.jpg',
      'photoFileIds': ['cover-file-id', 'gallery-file-2'],
      'productPhotoFileIds': ['place-cover-file-id'],
      'productPhotoImageUrls': [
        'https://upload.wikimedia.org/place.jpg',
        'https://upload.wikimedia.org/place-2.jpg',
      ],
    });
  });

  test('deduplicates and trims excursion gallery photo ids and urls', () {
    final request = CreateExcursionRequest(
      categorySlug: 'nature',
      durationMinutes: 90,
      maxGroupSize: 6,
      languageCodes: const ['en'],
      meetingPoint: 'Main square',
      priceAmount: 0,
      currency: 'KZT',
      photoFileIds: const [' cover-file-id ', '', 'cover-file-id', 'two'],
      productPhotoFileIds: const [' place-cover ', 'PLACE-COVER', ''],
      productPhotoImageUrls: const [
        ' https://cdn.example.test/place.jpg ',
        '',
        'https://cdn.example.test/place.jpg',
      ],
      itinerary: const [
        CreateExcursionItineraryItemRequest(
          startOffsetMinutes: 0,
          title: 'Meet and greet',
          description: 'Meet the guide and start exploring.',
        ),
      ],
    );

    final json = request.toJson();

    expect(json['photoFileIds'], ['cover-file-id', 'two']);
    expect(json['productPhotoFileIds'], ['place-cover']);
    expect(json['productPhotoImageUrls'], [
      'https://cdn.example.test/place.jpg',
    ]);
  });

  test('omits optional blank fields from excursion payload', () {
    final request = CreateExcursionRequest(
      landmarkId: 'place-id',
      categorySlug: 'cultural',
      durationMinutes: 90,
      maxGroupSize: 6,
      languageCodes: const ['en'],
      meetingPoint: 'Main square',
      priceAmount: 0,
      currency: 'KZT',
      itinerary: const [
        CreateExcursionItineraryItemRequest(
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
    final request = CreateExcursionRequest(
      landmarkId: 'place-id',
      landmarkName: 'Шарын шатқалы',
      categorySlug: 'adventure',
      durationMinutes: 180,
      maxGroupSize: 6,
      languageCodes: const ['ru', 'kk'],
      meetingPoint: 'Вход в каньон',
      priceAmount: 45000,
      currency: 'KZT',
      productTranslations: const {
        'kk': CreateExcursionLocalizedCopyRequest(
          title: 'Шарын шатқалы',
          summary: 'Шарын шатқалы бойынша гид ұсыныстарын салыстырыңыз.',
          description: 'Гидті, тілді, бағаны және кездесу орнын таңдаңыз.',
        ),
      },
      itinerary: const [
        CreateExcursionItineraryItemRequest(
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

  test('serializes combined route itinerary stop snapshots', () {
    final request = CreateExcursionRequest(
      categorySlug: 'culture',
      durationMinutes: 180,
      maxGroupSize: 6,
      languageCodes: const ['en'],
      meetingPoint: 'Hotel pickup',
      priceAmount: 45000,
      currency: 'KZT',
      cityName: 'Almaty',
      itinerary: const [
        CreateExcursionItineraryItemRequest(
          startOffsetMinutes: 0,
          durationMinutes: 45,
          placeId: 'kok-tobe-id',
          placeName: 'Kok-Tobe',
          latitude: 43.233,
          longitude: 76.976,
          title: 'Kok-Tobe',
          description: 'Start with a panoramic city view.',
        ),
        CreateExcursionItineraryItemRequest(
          startOffsetMinutes: 60,
          durationMinutes: 45,
          placeId: 'cathedral-id',
          placeName: 'Cathedral',
          latitude: 43.258,
          longitude: 76.954,
          travelFromPreviousMinutes: 15,
          title: 'Cathedral',
          description: 'Continue with the cathedral story.',
        ),
      ],
    );

    final itinerary = request.toJson()['itinerary'] as List<dynamic>;
    expect(itinerary.first, containsPair('placeId', 'kok-tobe-id'));
    expect(itinerary.first, containsPair('placeName', 'Kok-Tobe'));
    expect(itinerary.first, containsPair('latitude', 43.233));
    expect(itinerary.first, containsPair('longitude', 76.976));
    expect(itinerary.last, containsPair('travelFromPreviousMinutes', 15));
  });
}
