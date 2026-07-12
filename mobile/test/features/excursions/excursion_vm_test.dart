import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/places/models/place_vm.dart';
import 'package:inflap/features/excursions/models/excursion_vm.dart';
import 'package:inflap/features/excursions/excursion_localization.dart';

void main() {
  test('parses excursion gallery photos from product payload', () {
    final excursion = ExcursionVm.fromJson(const {
      'id': 'product-1',
      'title': 'Almaty Mountain Escape',
      'summary': 'Private mountain route',
      'status': 'PUBLISHED',
      'visibility': 'PUBLIC',
      'priceAmount': 120,
      'currency': 'KZT',
      'coverFileId': 'cover-file-id',
      'coverImageUrl': '/api/v1/excursion-products/product-1/cover',
      'photoFileIds': ['cover-file-id', 'gallery-file-2'],
      'photoImageUrls': [
        '/api/v1/excursion-products/product-1/photos/0',
        'https://cdn.example.test/gallery-2.jpg',
      ],
    });

    expect(excursion.photoFileIds, ['cover-file-id', 'gallery-file-2']);
    expect(excursion.photoImageUrls, [
      '/api/v1/excursion-products/product-1/photos/0',
      'https://cdn.example.test/gallery-2.jpg',
    ]);
  });

  test(
    'selected offer gallery overrides product gallery for guide details',
    () {
      final excursion = ExcursionVm.fromJson(const {
        'id': 'product-1',
        'title': 'Almaty Mountain Escape',
        'summary': 'Private mountain route',
        'status': 'PUBLISHED',
        'visibility': 'PUBLIC',
        'priceAmount': 120,
        'currency': 'KZT',
        'photoFileIds': ['product-photo'],
        'offers': [
          {
            'id': 'offer-1',
            'productId': 'product-1',
            'guideProfileId': 'guide-profile-1',
            'guideUserId': 'guide-user-1',
            'status': 'PUBLISHED',
            'visibility': 'PUBLIC',
            'durationMinutes': 120,
            'maxGroupSize': 4,
            'meetingPoint': 'Hotel pickup',
            'priceAmount': 140,
            'currency': 'KZT',
            'photoFileIds': ['offer-cover', 'offer-photo-2'],
          },
        ],
      });

      final selected = excursion.withPrimaryOffer(excursion.offers.first);

      expect(selected.photoFileIds, ['offer-cover', 'offer-photo-2']);
    },
  );

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
        'ratingAvg': 4.75,
        'reviewsCount': 12,
        'createdAt': '2026-05-10T09:30:00Z',
      });

      expect(excursion.id, 'excursion-1');
      expect(excursion.landmarkName, 'Medeu');
      expect(excursion.categorySlug, 'adventure');
      expect(excursion.durationMinutes, 240);
      expect(excursion.maxGroupSize, 8);
      expect(excursion.languageCodes, ['en', 'ru']);
      expect(excursion.tags, ['mountains', 'photo']);
      expect(excursion.ratingAvg, 4.75);
      expect(excursion.reviewsCount, 12);
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

  test('removes deprecated included items and keeps translations aligned', () {
    final excursion = ExcursionVm.fromJson(const {
      'id': 'product-legacy-included-items',
      'title': 'Legacy offer',
      'summary': 'Legacy included item payload',
      'includedItems': [
        'transport',
        'guide',
        'accommodation',
        'photo',
        'permits_fees',
      ],
      'includedItemTranslations': {
        'ru': ['Транспорт', 'Гид', 'Проживание', 'Фото', 'Разрешения и сборы'],
      },
      'offers': [
        {
          'id': 'offer-legacy-included-items',
          'productId': 'product-legacy-included-items',
          'guideProfileId': 'guide-profile-1',
          'guideUserId': 'guide-user-1',
          'includedItems': ['food', 'guide', 'permits_fees', 'photo'],
          'includedItemTranslations': {
            'ru': ['Питание', 'Гид', 'Разрешения и сборы', 'Фото'],
          },
        },
      ],
    });

    expect(excursion.includedItems, [
      'transport',
      'accommodation',
      'permits_fees',
    ]);
    expect(excursion.includedItemTranslations['ru'], [
      'Транспорт',
      'Проживание',
      'Разрешения и сборы',
    ]);
    expect(excursion.offers.single.includedItems, ['food', 'permits_fees']);
    expect(excursion.offers.single.localizedIncludedItems('ru'), [
      'Питание',
      'Разрешения и сборы',
    ]);
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

  test('uses productTranslations as detail copy fallback', () {
    final excursion = ExcursionVm.fromJson(const {
      'id': 'excursion-product-1',
      'title': 'Charyn Canyon',
      'summary': 'Shared route',
      'description': 'Shared description',
      'productTranslations': {
        'ru': {
          'title': 'Чарынский каньон',
          'summary': 'Общий маршрут',
          'description': 'Описание общего маршрута',
        },
      },
    });

    expect(excursion.translations['ru']?.title, 'Чарынский каньон');
    expect(
      localizedExcursionDescription(languageCode: 'ru', excursion: excursion),
      'Описание общего маршрута',
    );
  });

  test('prefers live localized place copy over excursion snapshot', () {
    const excursion = ExcursionVm(
      id: 'excursion-product-live-place',
      landmarkId: 'place-1',
      title: 'Snapshot title',
      summary: 'Snapshot summary',
      description: 'Snapshot description',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      priceAmount: 0,
      currency: 'KZT',
      translations: {
        'en': ExcursionLocalizedCopyVm(
          title: 'Stale localized title',
          description: 'Stale localized description.',
        ),
      },
    );
    final place = PlaceVm.fromJson(const {
      'id': 'place-1',
      'locale': 'en',
      'defaultLocale': 'ru',
      'title': 'Current attraction title',
      'description': 'Current attraction description.',
      'countryCode': 'KZ',
      'cityId': 'almaty',
      'category': 'NATURE',
      'rating': 0,
      'reviewCount': 0,
      'source': 'SYSTEM',
      'status': 'PUBLISHED',
      'translations': {
        'en': {
          'title': 'Current attraction title',
          'description': 'Current attraction description.',
        },
      },
    });

    expect(
      localizedExcursionTitle(
        languageCode: 'en',
        excursion: excursion,
        place: place,
      ),
      'Current attraction title',
    );
    expect(
      localizedExcursionDescription(
        languageCode: 'en',
        excursion: excursion,
        place: place,
      ),
      'Current attraction description.',
    );
  });

  test('parses machine translation info for excursion details notice', () {
    final excursion = ExcursionVm.fromJson(const {
      'id': 'excursion-product-1',
      'title': 'Чарынский каньон',
      'summary': 'Маршрут по каньону',
      'status': 'PUBLISHED',
      'visibility': 'PUBLIC',
      'translationInfo': {
        'translated': true,
        'sourceLanguage': 'ru',
        'targetLanguages': ['en', 'kk'],
        'provider': 'azure_translator',
      },
    });

    expect(excursion.translationInfo.translated, isTrue);
    expect(excursion.translationInfo.sourceLanguage, 'ru');
    expect(excursion.translationInfo.targetLanguages, ['en', 'kk']);
    expect(excursion.translationInfo.shouldShowNotice('en'), isTrue);
    expect(excursion.translationInfo.shouldShowNotice('ru'), isFalse);
  });

  test('parses async translation info from details response', () {
    final excursion = ExcursionVm.fromJson(const {
      'id': 'excursion-product-async',
      'title': 'Чарынский каньон',
      'summary': 'Маршрут по каньону',
      'status': 'PUBLISHED',
      'visibility': 'PUBLIC',
      'translationInfo': {
        'status': 'PARTIAL',
        'sourceLanguage': 'ru',
        'currentLanguage': 'en',
        'isTranslated': false,
        'availableLanguages': ['ru'],
        'pendingLanguages': ['en'],
        'failedLanguages': ['kk'],
      },
    });

    expect(excursion.translationInfo.status, 'PARTIAL');
    expect(excursion.translationInfo.currentLanguage, 'en');
    expect(excursion.translationInfo.availableLanguages, ['ru']);
    expect(excursion.translationInfo.pendingLanguages, ['en']);
    expect(excursion.translationInfo.failedLanguages, ['kk']);
    expect(
      excursion.translationInfo.noticeState('en'),
      ExcursionTranslationNoticeState.pending,
    );
    expect(
      excursion.translationInfo.noticeState('kk'),
      ExcursionTranslationNoticeState.unavailable,
    );
  });

  test('infers machine translation info from offer itinerary translations', () {
    final excursion = ExcursionVm.fromJson(
      const {
        'id': 'excursion-product-1',
        'title': 'Charyn Canyon',
        'summary': 'Shared route',
        'description': 'Shared product copy',
        'status': 'PUBLISHED',
        'visibility': 'PUBLIC',
      },
      offers: const [
        ExcursionOfferVm(
          id: 'offer-1',
          productId: 'excursion-product-1',
          guideProfileId: 'guide-profile-1',
          guideUserId: 'guide-user-1',
          title: 'Авторский маршрут',
          summary: 'Маршрут по каньону',
          description: 'Русское описание предложения.',
          status: 'PUBLISHED',
          visibility: 'PUBLIC',
          durationMinutes: 180,
          maxGroupSize: 6,
          meetingPoint: 'Charyn entrance',
          priceAmount: 120,
          currency: 'KZT',
          itinerary: [
            ExcursionItineraryItemVm(
              id: 'step-1',
              sortOrder: 0,
              startOffsetMinutes: 0,
              title: 'Чарынский каньон',
              description: 'Русское описание маршрута.',
              translations: {
                'ru': ExcursionItineraryLocalizedCopyVm(
                  title: 'Чарынский каньон',
                  description: 'Русское описание маршрута.',
                ),
                'en': ExcursionItineraryLocalizedCopyVm(
                  title: 'Charyn Canyon',
                  description: 'English route description.',
                ),
                'kk': ExcursionItineraryLocalizedCopyVm(
                  title: 'Шарын шатқалы',
                  description: 'Қазақша маршрут сипаттамасы.',
                ),
              },
            ),
          ],
        ),
      ],
    );

    expect(excursion.translationInfo.translated, isTrue);
    expect(excursion.translationInfo.sourceLanguage, 'ru');
    expect(excursion.translationInfo.targetLanguages, ['en', 'kk']);
    expect(excursion.translationInfo.shouldShowNotice('en'), isTrue);
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
      'placeIds': ['a', 'b'],
      'placeNames': ['Kok-Tobe', 'Cathedral'],
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
          'placeId': 'a',
          'placeName': 'Kok-Tobe',
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
    expect(excursion.placeIds, ['a', 'b']);
    expect(excursion.placeNames, ['Kok-Tobe', 'Cathedral']);
    expect(excursion.stopCount, 2);
    expect(excursion.transportMode, 'WALKING');
    expect(excursion.routeTheme, 'culture');
    expect(excursion.durationBucket, '2-4h');
    expect(excursion.itinerary.first.placeId, 'a');
    expect(excursion.itinerary.first.placeName, 'Kok-Tobe');
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

  test('localizes a combined route title from all route places', () {
    const excursion = ExcursionVm(
      id: 'combined-route-product',
      title: 'Урочище Бозжыра + Чарынский каньон',
      summary: 'Составной маршрут',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      priceAmount: 0,
      currency: 'KZT',
      routeKind: 'COMBINED_ROUTE',
      placeIds: ['bozjyra', 'charyn'],
      placeNames: ['Урочище Бозжыра', 'Чарынский каньон'],
      stopCount: 2,
    );
    final placesById = <String, PlaceVm>{
      'bozjyra': _localizedRoutePlace(
        id: 'bozjyra',
        ru: 'Урочище Бозжыра',
        en: 'Bozjyra Tract',
        kk: 'Бозжыра шатқалы',
      ),
      'charyn': _localizedRoutePlace(
        id: 'charyn',
        ru: 'Чарынский каньон',
        en: 'Charyn Canyon',
        kk: 'Шарын шатқалы',
      ),
    };

    expect(
      localizedExcursionTitle(
        languageCode: 'en',
        excursion: excursion,
        placesById: placesById,
      ),
      'Bozjyra Tract + Charyn Canyon',
    );
    expect(
      localizedExcursionTitle(
        languageCode: 'kk',
        excursion: excursion,
        placesById: placesById,
      ),
      'Бозжыра шатқалы + Шарын шатқалы',
    );
    expect(
      localizedExcursionTitle(
        languageCode: 'ru',
        excursion: excursion,
        placesById: placesById,
      ),
      'Урочище Бозжыра + Чарынский каньон',
    );
    expect(
      localizedExcursionTitle(
        languageCode: 'en',
        excursion: excursion,
        placesById: {'bozjyra': placesById['bozjyra']!},
      ),
      excursion.title,
    );
  });

  test('localizes landmark based excursion title from place translations', () {
    const excursion = ExcursionVm(
      id: 'excursion-product-1',
      landmarkId: 'place-1',
      landmarkName: 'Charyn Canyon',
      title: 'Charyn Canyon',
      summary: 'Shared route',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      priceAmount: 0,
      currency: 'KZT',
    );
    final place = PlaceVm.fromJson(const {
      'id': 'place-1',
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
        place: place,
      ),
      'Шарын шатқалы',
    );
    expect(
      localizedExcursionDescription(
        languageCode: 'kk',
        excursion: excursion,
        place: place,
      ),
      'Қазақстандағы шатқал.',
    );
  });

  test('localizes place title with booking-safe fallback', () {
    final place = PlaceVm.fromJson(const {
      'id': 'place-1',
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
      localizedPlaceTitle(
        languageCode: 'kk-KZ',
        place: place,
        fallback: 'Charyn Canyon',
      ),
      'Шарын шатқалы',
    );
    expect(
      localizedPlaceTitle(
        languageCode: 'tr',
        place: null,
        fallback: 'Charyn Canyon',
      ),
      'Charyn Canyon',
    );
  });
}

PlaceVm _localizedRoutePlace({
  required String id,
  required String ru,
  required String en,
  required String kk,
}) {
  return PlaceVm.fromJson({
    'id': id,
    'locale': 'en',
    'defaultLocale': 'ru',
    'title': en,
    'description': '',
    'translations': {
      'ru': {'title': ru, 'description': ''},
      'en': {'title': en, 'description': ''},
      'kk': {'title': kk, 'description': ''},
    },
  });
}
