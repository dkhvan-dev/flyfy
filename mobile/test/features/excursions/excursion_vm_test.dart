import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/attractions/models/attraction_vm.dart';
import 'package:superapp/features/excursions/models/excursion_vm.dart';
import 'package:superapp/features/excursions/excursion_localization.dart';

void main() {
  test(
    'parses public excursion list fields from excursion-service response',
    () {
      final excursion = ExcursionVm.fromJson(const {
        'id': 'excursion-1',
        'landmarkName': 'Medeu',
        'title': 'Almaty Mountain Escape',
        'summary': 'Private mountain route',
        'categorySlug': 'adventure',
        'tags': ['mountains', 'photo'],
        'durationMinutes': 240,
        'maxGroupSize': 8,
        'languageCodes': ['en', 'ru'],
        'status': 'PUBLISHED',
        'visibility': 'PUBLIC',
        'priceAmount': 120,
        'currency': 'USD',
        'cityName': 'Almaty',
        'coverFileId': 'cover-file-id',
        'createdAt': '2026-05-10T09:30:00Z',
      });

      expect(excursion.id, 'excursion-1');
      expect(excursion.landmarkName, 'Medeu');
      expect(excursion.categorySlug, 'adventure');
      expect(excursion.durationMinutes, 240);
      expect(excursion.maxGroupSize, 8);
      expect(excursion.languageCodes, ['en', 'ru']);
      expect(excursion.tags, ['mountains', 'photo']);
      expect(excursion.createdAt, DateTime.utc(2026, 5, 10, 9, 30));
    },
  );

  test(
    'parses public excursion detail fields from excursion-service response',
    () {
      final excursion = ExcursionVm.fromJson(const {
        'id': 'excursion-1',
        'guideProfileId': 'guide-profile-1',
        'guideUserId': 'guide-user-1',
        'landmarkName': 'Medeu',
        'title': 'Almaty Mountain Escape',
        'summary': 'Private mountain route',
        'description': 'A private alpine route through Shymbulak and Medeu.',
        'categorySlug': 'adventure',
        'tags': ['mountains', 'photo'],
        'durationMinutes': 480,
        'maxGroupSize': 4,
        'languageCodes': ['en', 'ru'],
        'status': 'PUBLISHED',
        'visibility': 'PUBLIC',
        'meetingPoint': 'Hotel pickup',
        'countryCode': 'KZ',
        'cityName': 'Almaty',
        'latitude': 43.238949,
        'longitude': 76.889709,
        'mapUrl': 'https://maps.example.test/medeu',
        'priceAmount': 240,
        'currency': 'USD',
        'coverFileId': 'cover-file-id',
        'coverImageUrl': 'https://cdn.example.test/cover.jpg',
        'includedItems': ['Private SUV', 'Gourmet picnic'],
        'itinerary': [
          {
            'id': 'step-1',
            'sortOrder': 0,
            'startOffsetMinutes': 0,
            'durationMinutes': 45,
            'title': 'Hotel departure',
            'description': 'Luxury SUV pickup from your hotel.',
          },
        ],
      });

      expect(excursion.guideProfileId, 'guide-profile-1');
      expect(excursion.guideUserId, 'guide-user-1');
      expect(excursion.description, contains('private alpine route'));
      expect(excursion.meetingPoint, 'Hotel pickup');
      expect(excursion.countryCode, 'KZ');
      expect(excursion.latitude, 43.238949);
      expect(excursion.longitude, 76.889709);
      expect(excursion.mapUrl, 'https://maps.example.test/medeu');
      expect(excursion.coverImageUrl, 'https://cdn.example.test/cover.jpg');
      expect(excursion.includedItems, ['Private SUV', 'Gourmet picnic']);
      expect(excursion.itinerary, hasLength(1));
      expect(excursion.itinerary.first.title, 'Hotel departure');
      expect(excursion.itinerary.first.durationMinutes, 45);
    },
  );

  test('keeps offer included items out of the shared excursion product', () {
    final excursion = ExcursionVm.fromJson(
      const {
        'id': 'excursion-product-1',
        'title': 'Shared Medeu route',
        'summary': 'Public route card',
      },
      offers: const [
        ExcursionOfferVm(
          id: 'offer-1',
          productId: 'excursion-product-1',
          guideProfileId: 'guide-profile-1',
          guideUserId: 'guide-user-1',
          status: 'PUBLISHED',
          visibility: 'PUBLIC',
          durationMinutes: 180,
          maxGroupSize: 4,
          meetingPoint: 'Medeu entrance',
          priceAmount: 120,
          currency: 'USD',
          includedItems: ['Transport'],
        ),
      ],
    );

    expect(excursion.includedItems, isEmpty);
    expect(excursion.withPrimaryOffer(excursion.offers.first).includedItems, [
      'Transport',
    ]);
  });

  test('does not fallback to product included items for selected offer', () {
    const excursion = ExcursionVm(
      id: 'excursion-product-1',
      title: 'Shared Medeu route',
      summary: 'Public route card',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      priceAmount: 0,
      currency: 'KZT',
      includedItems: ['Transport'],
      offers: [
        ExcursionOfferVm(
          id: 'offer-1',
          productId: 'excursion-product-1',
          guideProfileId: 'guide-profile-1',
          guideUserId: 'guide-user-1',
          status: 'PUBLISHED',
          visibility: 'PUBLIC',
          durationMinutes: 180,
          maxGroupSize: 4,
          meetingPoint: 'Medeu entrance',
          priceAmount: 120,
          currency: 'USD',
        ),
      ],
    );

    expect(
      excursion.withPrimaryOffer(excursion.offers.first).includedItems,
      isEmpty,
    );
  });

  test('keeps product copy neutral and applies selected offer copy', () {
    final excursion = ExcursionVm.fromJson(
      const {
        'id': 'product-1',
        'landmarkName': 'Medeu',
        'title': 'Medeu',
        'summary': 'Compare guide offers for Medeu.',
        'description': 'Choose a guide, language, price, and inclusions.',
        'status': 'PUBLISHED',
        'visibility': 'PUBLIC',
        'minPriceAmount': 120,
        'currency': 'USD',
      },
      offers: const [
        ExcursionOfferVm(
          id: 'offer-1',
          productId: 'product-1',
          guideProfileId: 'guide-profile-1',
          guideUserId: 'guide-user-1',
          title: "Aruzhan's sunrise Medeu walk",
          summary: 'My private sunrise route',
          description: 'My author description with exact selling points.',
          status: 'PUBLISHED',
          visibility: 'PUBLIC',
          durationMinutes: 180,
          maxGroupSize: 4,
          meetingPoint: 'Medeu entrance',
          priceAmount: 120,
          currency: 'USD',
        ),
      ],
    );

    expect(excursion.title, 'Medeu');
    expect(excursion.description, isNot(contains('author description')));
    expect(excursion.offers.first.title, "Aruzhan's sunrise Medeu walk");

    final selected = excursion.withPrimaryOffer(excursion.offers.first);
    expect(selected.title, "Aruzhan's sunrise Medeu walk");
    expect(selected.summary, 'My private sunrise route');
    expect(
      selected.description,
      'My author description with exact selling points.',
    );
  });

  test('selected offer cover takes precedence over shared product cover', () {
    final excursion = ExcursionVm.fromJson(
      const {
        'id': 'product-1',
        'title': 'Medeu',
        'summary': 'Compare guide offers for Medeu.',
        'description': 'Choose a guide before booking.',
        'status': 'PUBLISHED',
        'visibility': 'PUBLIC',
        'coverFileId': 'product-cover-file',
        'coverImageUrl': '/api/v1/excursion-products/product-1/cover',
        'minPriceAmount': 100,
        'currency': 'KZT',
      },
      offers: const [
        ExcursionOfferVm(
          id: 'offer-1',
          productId: 'product-1',
          guideProfileId: 'guide-profile-1',
          guideUserId: 'guide-user-1',
          status: 'PUBLISHED',
          visibility: 'PUBLIC',
          durationMinutes: 120,
          maxGroupSize: 4,
          meetingPoint: 'Medeu entrance',
          priceAmount: 120,
          currency: 'KZT',
          coverFileId: 'offer-cover-file',
        ),
      ],
    );

    final selected = excursion.withPrimaryOffer(excursion.offers.first);

    expect(selected.coverFileId, 'offer-cover-file');
    expect(selected.coverImageUrl, isNull);
  });

  test('parses localized excursion copy from product and offer responses', () {
    final excursion = ExcursionVm.fromJson(const {
      'id': 'excursion-product-1',
      'title': 'Charyn Canyon',
      'summary': 'Shared route',
      'description': 'Shared description',
      'translations': {
        'kk': {
          'title': 'Шарын шатқалы',
          'summary': 'Ортақ бағыт',
          'description': 'Ортақ сипаттама',
        },
      },
      'offers': [
        {
          'id': 'offer-1',
          'productId': 'excursion-product-1',
          'guideProfileId': 'guide-profile-1',
          'guideUserId': 'guide-user-1',
          'title': 'My Charyn route',
          'summary': 'My summary',
          'description': 'My description',
          'status': 'PUBLISHED',
          'visibility': 'PUBLIC',
          'translations': {
            'kk': {
              'title': 'Менің Шарын бағытым',
              'summary': 'Менің қысқаша сипаттамам',
              'description': 'Менің толық сипаттамам',
            },
          },
        },
      ],
    });

    expect(excursion.translations['kk']?.title, 'Шарын шатқалы');
    expect(excursion.translations['kk']?.summary, 'Ортақ бағыт');
    expect(
      excursion.offers.first.translations['kk']?.title,
      'Менің Шарын бағытым',
    );
    expect(
      excursion.offers.first.translations['kk']?.description,
      'Менің толық сипаттамам',
    );
  });

  test('parses combined route product and itinerary stop fields', () {
    final excursion = ExcursionVm.fromJson(const {
      'id': 'route-product-1',
      'title': 'Kok-Tobe + Cathedral',
      'summary': 'Compare guide offers for this route.',
      'status': 'PUBLISHED',
      'visibility': 'PUBLIC',
      'routeKind': 'COMBINED_ROUTE',
      'routeFingerprint': 'route:kz:almaty:culture:2-4h:walking:a,b',
      'attractionIds': ['a', 'b'],
      'attractionNames': ['Kok-Tobe', 'Cathedral'],
      'stopCount': 2,
      'transportMode': 'WALKING',
      'routeTheme': 'culture',
      'durationBucket': '2-4h',
      'itinerary': [
        {
          'id': 'step-1',
          'sortOrder': 0,
          'startOffsetMinutes': 0,
          'durationMinutes': 45,
          'attractionId': 'a',
          'attractionName': 'Kok-Tobe',
          'latitude': 43.233,
          'longitude': 76.976,
          'title': 'Kok-Tobe',
          'description': 'Start with a panoramic city view.',
        },
      ],
    });

    expect(excursion.routeKind, 'COMBINED_ROUTE');
    expect(
      excursion.routeFingerprint,
      'route:kz:almaty:culture:2-4h:walking:a,b',
    );
    expect(excursion.attractionIds, ['a', 'b']);
    expect(excursion.attractionNames, ['Kok-Tobe', 'Cathedral']);
    expect(excursion.stopCount, 2);
    expect(excursion.transportMode, 'WALKING');
    expect(excursion.routeTheme, 'culture');
    expect(excursion.durationBucket, '2-4h');
    expect(excursion.itinerary.first.attractionId, 'a');
    expect(excursion.itinerary.first.attractionName, 'Kok-Tobe');
    expect(excursion.itinerary.first.latitude, 43.233);
    expect(excursion.itinerary.first.longitude, 76.976);
    expect(
      excursion
          .withPrimaryOffer(
            const ExcursionOfferVm(
              id: 'offer-1',
              productId: 'route-product-1',
              guideProfileId: 'guide-profile-1',
              guideUserId: 'guide-user-1',
              status: 'PUBLISHED',
              visibility: 'PUBLIC',
              durationMinutes: 180,
              maxGroupSize: 6,
              meetingPoint: 'Hotel pickup',
              priceAmount: 45000,
              currency: 'KZT',
            ),
          )
          .routeKind,
      'COMBINED_ROUTE',
    );
  });

  test(
    'localizes landmark based excursion title from attraction translations',
    () {
      const excursion = ExcursionVm(
        id: 'excursion-product-1',
        landmarkId: 'attraction-1',
        landmarkName: 'Charyn Canyon',
        title: 'Charyn Canyon',
        summary: 'Shared route',
        status: 'PUBLISHED',
        visibility: 'PUBLIC',
        priceAmount: 0,
        currency: 'KZT',
      );
      final attraction = AttractionVm.fromJson(const {
        'id': 'attraction-1',
        'locale': 'kk',
        'defaultLocale': 'ru',
        'title': 'Шарын шатқалы',
        'description': 'Қазақстандағы шатқал.',
        'translations': {
          'ru': {
            'title': 'Чарынский каньон',
            'description': 'Каньон в Казахстане.',
          },
          'kk': {
            'title': 'Шарын шатқалы',
            'description': 'Қазақстандағы шатқал.',
          },
        },
      });

      expect(
        localizedExcursionTitle(
          languageCode: 'kk',
          excursion: excursion,
          attraction: attraction,
        ),
        'Шарын шатқалы',
      );
      expect(
        localizedExcursionDescription(
          languageCode: 'kk',
          excursion: excursion,
          attraction: attraction,
        ),
        'Қазақстандағы шатқал.',
      );
    },
  );

  test('localizes attraction title with booking-safe fallback', () {
    final attraction = AttractionVm.fromJson(const {
      'id': 'attraction-1',
      'locale': 'ru',
      'defaultLocale': 'en',
      'title': 'Чарынский каньон',
      'description': 'Каньон в Казахстане.',
      'translations': {
        'en': {
          'title': 'Charyn Canyon',
          'description': 'Canyon in Kazakhstan.',
        },
        'kk': {
          'title': 'Шарын шатқалы',
          'description': 'Қазақстандағы шатқал.',
        },
      },
    });

    expect(
      localizedAttractionTitle(
        languageCode: 'kk-KZ',
        attraction: attraction,
        fallback: 'Charyn Canyon',
      ),
      'Шарын шатқалы',
    );
    expect(
      localizedAttractionTitle(
        languageCode: 'tr',
        attraction: null,
        fallback: 'Charyn Canyon',
      ),
      'Charyn Canyon',
    );
  });
}
