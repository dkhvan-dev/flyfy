import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/attractions/models/attraction_vm.dart';
import 'package:superapp/features/tours/models/tour_vm.dart';
import 'package:superapp/features/tours/tour_localization.dart';

void main() {
  test('parses public tour list fields from tour-service response', () {
    final tour = TourVm.fromJson(const {
      'id': 'tour-1',
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

    expect(tour.id, 'tour-1');
    expect(tour.landmarkName, 'Medeu');
    expect(tour.categorySlug, 'adventure');
    expect(tour.durationMinutes, 240);
    expect(tour.maxGroupSize, 8);
    expect(tour.languageCodes, ['en', 'ru']);
    expect(tour.tags, ['mountains', 'photo']);
    expect(tour.createdAt, DateTime.utc(2026, 5, 10, 9, 30));
  });

  test('parses public tour detail fields from tour-service response', () {
    final tour = TourVm.fromJson(const {
      'id': 'tour-1',
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

    expect(tour.guideProfileId, 'guide-profile-1');
    expect(tour.guideUserId, 'guide-user-1');
    expect(tour.description, contains('private alpine route'));
    expect(tour.meetingPoint, 'Hotel pickup');
    expect(tour.countryCode, 'KZ');
    expect(tour.latitude, 43.238949);
    expect(tour.longitude, 76.889709);
    expect(tour.mapUrl, 'https://maps.example.test/medeu');
    expect(tour.coverImageUrl, 'https://cdn.example.test/cover.jpg');
    expect(tour.includedItems, ['Private SUV', 'Gourmet picnic']);
    expect(tour.itinerary, hasLength(1));
    expect(tour.itinerary.first.title, 'Hotel departure');
    expect(tour.itinerary.first.durationMinutes, 45);
  });

  test('keeps offer included items out of the shared tour product', () {
    final tour = TourVm.fromJson(
      const {
        'id': 'tour-product-1',
        'title': 'Shared Medeu route',
        'summary': 'Public route card',
      },
      offers: const [
        TourOfferVm(
          id: 'offer-1',
          productId: 'tour-product-1',
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

    expect(tour.includedItems, isEmpty);
    expect(tour.withPrimaryOffer(tour.offers.first).includedItems, [
      'Transport',
    ]);
  });

  test('does not fallback to product included items for selected offer', () {
    const tour = TourVm(
      id: 'tour-product-1',
      title: 'Shared Medeu route',
      summary: 'Public route card',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      priceAmount: 0,
      currency: 'KZT',
      includedItems: ['Transport'],
      offers: [
        TourOfferVm(
          id: 'offer-1',
          productId: 'tour-product-1',
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

    expect(tour.withPrimaryOffer(tour.offers.first).includedItems, isEmpty);
  });

  test('keeps product copy neutral and applies selected offer copy', () {
    final tour = TourVm.fromJson(
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
        TourOfferVm(
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

    expect(tour.title, 'Medeu');
    expect(tour.description, isNot(contains('author description')));
    expect(tour.offers.first.title, "Aruzhan's sunrise Medeu walk");

    final selected = tour.withPrimaryOffer(tour.offers.first);
    expect(selected.title, "Aruzhan's sunrise Medeu walk");
    expect(selected.summary, 'My private sunrise route');
    expect(
      selected.description,
      'My author description with exact selling points.',
    );
  });

  test('selected offer cover takes precedence over shared product cover', () {
    final tour = TourVm.fromJson(
      const {
        'id': 'product-1',
        'title': 'Medeu',
        'summary': 'Compare guide offers for Medeu.',
        'description': 'Choose a guide before booking.',
        'status': 'PUBLISHED',
        'visibility': 'PUBLIC',
        'coverFileId': 'product-cover-file',
        'coverImageUrl': '/api/v1/tour-products/product-1/cover',
        'minPriceAmount': 100,
        'currency': 'KZT',
      },
      offers: const [
        TourOfferVm(
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

    final selected = tour.withPrimaryOffer(tour.offers.first);

    expect(selected.coverFileId, 'offer-cover-file');
    expect(selected.coverImageUrl, isNull);
  });

  test('parses localized tour copy from product and offer responses', () {
    final tour = TourVm.fromJson(const {
      'id': 'tour-product-1',
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
          'productId': 'tour-product-1',
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

    expect(tour.translations['kk']?.title, 'Шарын шатқалы');
    expect(tour.translations['kk']?.summary, 'Ортақ бағыт');
    expect(tour.offers.first.translations['kk']?.title, 'Менің Шарын бағытым');
    expect(
      tour.offers.first.translations['kk']?.description,
      'Менің толық сипаттамам',
    );
  });

  test('localizes landmark based tour title from attraction translations', () {
    const tour = TourVm(
      id: 'tour-product-1',
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
      localizedTourTitle(
        languageCode: 'kk',
        tour: tour,
        attraction: attraction,
      ),
      'Шарын шатқалы',
    );
    expect(
      localizedTourDescription(
        languageCode: 'kk',
        tour: tour,
        attraction: attraction,
      ),
      'Қазақстандағы шатқал.',
    );
  });
}
