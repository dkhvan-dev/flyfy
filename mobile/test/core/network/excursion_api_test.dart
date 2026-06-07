import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/network/excursion_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/excursions/models/create_excursion_booking_request.dart';
import 'package:inflap/features/excursions/models/create_excursion_review_request.dart';
import 'package:inflap/features/excursions/models/create_excursion_request.dart';

void main() {
  test('getExcursions uses public excursion product endpoint', () async {
    final adapter = _ExcursionJsonAdapter({
      '/excursion-products': {
        'items': [_productJson()],
        'hasMore': false,
      },
    });
    final api = ExcursionApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final excursions = await api.getExcursions();

    expect(adapter.requests.single.path, '/excursion-products');
    expect(adapter.requests.single.extra['requiresAuth'], isFalse);
    expect(excursions.single.id, 'product-1');
    expect(excursions.single.priceAmount, 120);
    expect(excursions.single.publishedOffersCount, 2);
  });

  test(
    'getExcursions can narrow public products by landmark and city',
    () async {
      final adapter = _ExcursionJsonAdapter({
        '/excursion-products': {
          'items': [_productJson()],
          'hasMore': false,
        },
      });
      final api = ExcursionApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      await api.getExcursions(
        limit: 1,
        landmarkId: ' landmark-1 ',
        countryCode: ' kz ',
        cityName: ' Алматы ',
        departureCityId: ' almaty ',
      );

      expect(adapter.requests.single.path, '/excursion-products');
      expect(adapter.requests.single.extra['requiresAuth'], isFalse);
      expect(adapter.requests.single.queryParameters, {
        'limit': 1,
        'offset': 0,
        'landmarkId': 'landmark-1',
        'countryCode': 'KZ',
        'cityName': 'Алматы',
        'departureCityId': 'almaty',
      });
    },
  );

  test(
    'getExcursionsPage exposes product pagination for preview counts',
    () async {
      final adapter = _ExcursionJsonAdapter({
        '/excursion-products': {
          'items': [_productJson()],
          'hasMore': true,
        },
      });
      final api = ExcursionApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final page = await api.getExcursionsPage(
        limit: 100,
        offset: 200,
        query: ' canyon ',
        countryCode: ' kz ',
        departureCityId: ' almaty ',
      );

      expect(page.items.single.id, 'product-1');
      expect(page.hasMore, isTrue);
      expect(adapter.requests.single.path, '/excursion-products');
      expect(adapter.requests.single.queryParameters, {
        'limit': 100,
        'offset': 200,
        'q': 'canyon',
        'countryCode': 'KZ',
        'departureCityId': 'almaty',
      });
    },
  );

  test('getExcursionById loads product details and public offers', () async {
    final adapter = _ExcursionJsonAdapter({
      '/excursion-products/product-1': _productJson(),
      '/excursion-products/product-1/offers': {
        'items': [_offerJson()],
        'hasMore': false,
      },
    });
    final api = ExcursionApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final excursion = await api.getExcursionById('product-1');

    expect(adapter.requests.map((request) => request.path), [
      '/excursion-products/product-1',
      '/excursion-products/product-1/offers',
    ]);
    expect(adapter.lastOptions?.extra['requiresAuth'], isFalse);
    expect(excursion.id, 'product-1');
    expect(excursion.guideUserId, 'guide-user-1');
    expect(excursion.maxGroupSize, 4);
    expect(excursion.priceAmount, 240);
    expect(excursion.offers.single.legacyExcursionId, 'excursion-1');
    expect(excursion.offers.single.title, "Aruzhan's sunrise Medeu walk");
  });

  test(
    'getExcursionOffers sends pagination search filters sort and pinned guide',
    () async {
      final adapter = _ExcursionJsonAdapter({
        '/excursion-products/product-1/offers': {
          'items': [_offerJson()],
          'hasMore': true,
        },
      });
      final api = ExcursionApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final page = await api.getExcursionOffers(
        'product-1',
        limit: 12,
        offset: 24,
        query: 'Aruzhan',
        sort: 'rating',
        sortDirection: 'asc',
        languageCode: 'ru',
        priceMax: 50000,
        maxGroupSizeMin: 4,
        preferredGuideUserId: 'guide-user-1',
      );

      expect(
        adapter.requests.single.path,
        '/excursion-products/product-1/offers',
      );
      expect(adapter.requests.single.extra['requiresAuth'], isFalse);
      expect(adapter.requests.single.queryParameters, {
        'limit': 12,
        'offset': 24,
        'q': 'Aruzhan',
        'sort': 'rating',
        'sortDirection': 'asc',
        'languageCode': 'ru',
        'priceMax': 50000.0,
        'maxGroupSizeMin': 4,
        'preferredGuideUserId': 'guide-user-1',
      });
      expect(page.items.single.id, 'offer-1');
      expect(page.hasMore, isTrue);
    },
  );

  test(
    'createExcursionBooking posts selected product and offer to authenticated endpoint',
    () async {
      final adapter = _ExcursionJsonAdapter({
        '/me/excursion-bookings': {
          'id': 'booking-1',
          'productId': 'product-1',
          'offerId': 'offer-1',
          'status': 'REQUESTED',
        },
      });
      final api = ExcursionApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      await api.createExcursionBooking(
        CreateExcursionBookingRequest(
          productId: 'product-1',
          offerId: 'offer-1',
          scheduledFor: DateTime.utc(2026, 6, 1, 10),
          adults: 2,
          children: 1,
        ),
      );

      expect(adapter.requests.single.path, '/me/excursion-bookings');
      expect(adapter.lastOptions?.method, 'POST');
      expect(adapter.lastJsonBody?['productId'], 'product-1');
      expect(adapter.lastJsonBody?['offerId'], 'offer-1');
      expect(adapter.lastJsonBody?['adults'], 2);
      expect(adapter.lastJsonBody?['children'], 1);
    },
  );

  test(
    'quoteExcursionBookingGuests requests server settlement before guest edit',
    () async {
      final adapter = _ExcursionJsonAdapter({
        '/me/excursion-bookings/booking-1/guests/quote': {
          'adults': 3,
          'children': 1,
          'totalSeats': 4,
          'currentTotalAmount': 45000,
          'newTotalAmount': 60000,
          'deltaAmount': 15000,
          'currency': 'KZT',
          'status': 'PENDING_PAYMENT_INTEGRATION',
        },
      });
      final api = ExcursionApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final quote = await api.quoteExcursionBookingGuests(
        'booking-1',
        adults: 3,
        children: 1,
      );

      expect(
        adapter.requests.single.path,
        '/me/excursion-bookings/booking-1/guests/quote',
      );
      expect(adapter.lastOptions?.method, 'POST');
      expect(adapter.lastJsonBody, {'adults': 3, 'children': 1});
      expect(quote.deltaAmount, 15000);
      expect(quote.status, 'PENDING_PAYMENT_INTEGRATION');
    },
  );

  test(
    'quoteExcursionBookingCancellation requests server refund policy before cancel',
    () async {
      final adapter = _ExcursionJsonAdapter({
        '/me/excursion-bookings/booking-1/cancel/quote': {
          'percent': 75,
          'amount': 33750,
          'currency': 'KZT',
          'policyCode': 'PARTIAL_REFUND_BEFORE_12H',
          'status': 'PENDING_PAYMENT_INTEGRATION',
        },
      });
      final api = ExcursionApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final quote = await api.quoteExcursionBookingCancellation(
        'booking-1',
        reason: 'Plans changed',
      );

      expect(
        adapter.requests.single.path,
        '/me/excursion-bookings/booking-1/cancel/quote',
      );
      expect(adapter.lastOptions?.method, 'POST');
      expect(adapter.lastJsonBody, {'reason': 'Plans changed'});
      expect(quote.percent, 75);
      expect(quote.policyCode, 'PARTIAL_REFUND_BEFORE_12H');
    },
  );

  test(
    'getMyExcursionBookings reads authenticated booking list endpoint',
    () async {
      final adapter = _ExcursionJsonAdapter({
        '/me/excursion-bookings': {
          'items': [_bookingJson()],
          'hasMore': false,
        },
      });
      final api = ExcursionApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final page = await api.getMyExcursionBookings(limit: 12, offset: 24);

      expect(adapter.requests.single.path, '/me/excursion-bookings');
      expect(adapter.requests.single.queryParameters, {
        'limit': 12,
        'offset': 24,
      });
      expect(page.items.single.id, 'booking-1');
      expect(page.items.single.title, 'Medeu sunrise walk');
      expect(page.items.single.review?.rating, 4.5);
      expect(page.items.single.guideReview?.rating, 5);
      expect(page.hasMore, isFalse);
    },
  );

  test(
    'getMyExcursions reads authenticated guide offers endpoint with statuses',
    () async {
      final adapter = _ExcursionJsonAdapter({
        '/me/excursions': {
          'items': [_legacyExcursionJson()],
          'hasMore': false,
        },
      });
      final api = ExcursionApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final page = await api.getMyExcursions(
        limit: 20,
        offset: 40,
        statuses: const ['PUBLISHED', 'IN_REVIEW'],
      );

      expect(adapter.requests.single.path, '/me/excursions');
      expect(adapter.requests.single.queryParameters, {
        'limit': 20,
        'offset': 40,
        'status': 'PUBLISHED,IN_REVIEW',
      });
      expect(page.items.single.id, 'excursion-1');
      expect(page.hasMore, isFalse);
    },
  );

  test('archiveExcursionOffer posts authenticated archive action', () async {
    final adapter = _ExcursionJsonAdapter({
      '/me/excursions/excursion-1/archive': {
        ..._legacyExcursionJson(),
        'status': 'ARCHIVED',
      },
    });
    final api = ExcursionApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final archived = await api.archiveExcursionOffer('excursion-1');

    expect(adapter.requests.single.path, '/me/excursions/excursion-1/archive');
    expect(adapter.lastOptions?.method, 'POST');
    expect(archived.status, 'ARCHIVED');
  });

  test(
    'deleteExcursionOffer sends authenticated draft delete request',
    () async {
      final adapter = _ExcursionJsonAdapter({
        '/me/excursions/excursion-1': <String, Object?>{},
      });
      final api = ExcursionApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      await api.deleteExcursionOffer('excursion-1');

      expect(adapter.requests.single.path, '/me/excursions/excursion-1');
      expect(adapter.lastOptions?.method, 'DELETE');
    },
  );

  test('publishExcursion submits guide offer for publishing review', () async {
    final adapter = _ExcursionJsonAdapter({
      '/me/excursions/excursion-1/submit-for-publish': {
        ..._legacyExcursionJson(),
        'status': 'PENDING_REVIEW',
      },
    });
    final api = ExcursionApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final submitted = await api.publishExcursion('excursion-1');

    expect(
      adapter.requests.single.path,
      '/me/excursions/excursion-1/submit-for-publish',
    );
    expect(adapter.lastOptions?.method, 'POST');
    expect(submitted.status, 'PENDING_REVIEW');
  });

  test(
    'getMyGuideExcursionBookings reads authenticated guide booking endpoint',
    () async {
      final adapter = _ExcursionJsonAdapter({
        '/me/guide-excursion-bookings': {
          'items': [_bookingJson()],
          'hasMore': false,
        },
      });
      final api = ExcursionApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final page = await api.getMyGuideExcursionBookings(limit: 25, offset: 0);

      expect(adapter.requests.single.path, '/me/guide-excursion-bookings');
      expect(adapter.requests.single.queryParameters, {
        'limit': 25,
        'offset': 0,
      });
      expect(page.items.single.guideUserId, 'guide-user-1');
      expect(page.hasMore, isFalse);
    },
  );

  test('updateExcursionBookingGuests patches adults and children', () async {
    final adapter = _ExcursionJsonAdapter({
      '/me/excursion-bookings/booking-1': _bookingJson(),
    });
    final api = ExcursionApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final booking = await api.updateExcursionBookingGuests(
      'booking-1',
      adults: 3,
      children: 1,
    );

    expect(adapter.requests.single.path, '/me/excursion-bookings/booking-1');
    expect(adapter.lastOptions?.method, 'PATCH');
    expect(adapter.lastJsonBody, {'adults': 3, 'children': 1});
    expect(booking.id, 'booking-1');
  });

  test(
    'createExcursionReview posts rating and comment for visited booking',
    () async {
      final adapter = _ExcursionJsonAdapter({
        '/me/excursion-bookings/booking-1/review': _reviewJson(),
      });
      final api = ExcursionApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final review = await api.createExcursionReview(
        'booking-1',
        const CreateExcursionReviewRequest(
          rating: 4.5,
          comment: 'Warm guide and a smooth route.',
        ),
      );

      expect(
        adapter.requests.single.path,
        '/me/excursion-bookings/booking-1/review',
      );
      expect(adapter.lastOptions?.method, 'POST');
      expect(adapter.lastJsonBody?['rating'], 4.5);
      expect(
        adapter.lastJsonBody?['comment'],
        'Warm guide and a smooth route.',
      );
      expect(review.id, 'review-1');
      expect(review.guideDisplayName, 'Aruzhan');
    },
  );

  test(
    'saveBookingReviews puts excursion and optional guide review in one request',
    () async {
      final adapter = _ExcursionJsonAdapter({
        '/me/excursion-bookings/booking-1/reviews': {
          'excursionReview': _reviewJson(),
          'guideReview': _guideReviewJson(),
        },
      });
      final api = ExcursionApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final result = await api.saveBookingReviews(
        'booking-1',
        SaveBookingReviewsRequest(
          excursionReview: ReviewMutationRequest.fromDraft(
            ReviewDraftRequest(
              rating: 4.5,
              comment: 'Warm guide and a smooth route.',
            ),
          ),
          guideReview: ReviewMutationRequest.fromDraft(
            ReviewDraftRequest(
              rating: 5,
              comment: 'Thoughtful pacing and clear stories.',
            ),
          ),
        ),
      );

      expect(
        adapter.requests.single.path,
        '/me/excursion-bookings/booking-1/reviews',
      );
      expect(adapter.lastOptions?.method, 'PUT');
      expect(adapter.lastJsonBody?['excursionReview'], {
        'rating': 4.5,
        'comment': 'Warm guide and a smooth route.',
      });
      expect(adapter.lastJsonBody?['guideReview'], {
        'rating': 5.0,
        'comment': 'Thoughtful pacing and clear stories.',
      });
      expect(result.excursionReview?.id, 'review-1');
      expect(result.guideReview?.id, 'guide-review-1');
    },
  );

  test(
    'saveBookingReviews can delete direct guide review from booking',
    () async {
      final adapter = _ExcursionJsonAdapter({
        '/me/excursion-bookings/booking-1/reviews': {
          'excursionReview': _reviewJson(),
        },
      });
      final api = ExcursionApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final result = await api.saveBookingReviews(
        'booking-1',
        const SaveBookingReviewsRequest(
          guideReview: ReviewMutationRequest.delete(),
        ),
      );

      expect(
        adapter.requests.single.path,
        '/me/excursion-bookings/booking-1/reviews',
      );
      expect(adapter.lastOptions?.method, 'PUT');
      expect(adapter.lastJsonBody?['guideReview'], {'delete': true});
      expect(result.excursionReview?.id, 'review-1');
      expect(result.guideReview, isNull);
    },
  );

  test('getGuideReviews reads public direct guide reviews endpoint', () async {
    final adapter = _ExcursionJsonAdapter({
      '/guide-reviews': {
        'items': [_guideReviewJson()],
        'hasMore': false,
      },
    });
    final api = ExcursionApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.getGuideReviews(
      guideUserId: 'guide-user-1',
      limit: 20,
      sort: 'latest',
    );

    expect(adapter.requests.single.path, '/guide-reviews');
    expect(adapter.requests.single.extra['requiresAuth'], isFalse);
    expect(adapter.requests.single.queryParameters, {
      'guideUserId': 'guide-user-1',
      'sort': 'latest',
      'limit': 20,
      'offset': 0,
    });
    expect(page.items.single.id, 'guide-review-1');
  });

  test('getExcursionReviews can filter public reviews by attraction', () async {
    final adapter = _ExcursionJsonAdapter({
      '/excursion-reviews': {
        'items': [_reviewJson()],
        'hasMore': false,
      },
    });
    final api = ExcursionApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.getExcursionReviews(
      landmarkId: 'attraction-1',
      limit: 5,
      offset: 0,
    );

    expect(adapter.requests.single.path, '/excursion-reviews');
    expect(adapter.requests.single.extra['requiresAuth'], isFalse);
    expect(adapter.requests.single.queryParameters, {
      'landmarkId': 'attraction-1',
      'limit': 5,
      'offset': 0,
    });
    expect(page.items.single.sourceLabel, 'EXCURSION');
  });

  test('getGuideExcursionReviews sends guide filter and sort mode', () async {
    final adapter = _ExcursionJsonAdapter({
      '/excursion-reviews': {
        'items': [_reviewJson()],
        'hasMore': false,
      },
    });
    final api = ExcursionApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final page = await api.getGuideExcursionReviews(
      guideUserId: 'guide-user-1',
      limit: 10,
      sort: 'rating_desc',
    );

    expect(adapter.requests.single.path, '/excursion-reviews');
    expect(adapter.requests.single.extra['requiresAuth'], isFalse);
    expect(adapter.requests.single.queryParameters, {
      'guideUserId': 'guide-user-1',
      'sort': 'rating_desc',
      'limit': 10,
      'offset': 0,
    });
    expect(page.items.single.guideUserId, 'guide-user-1');
  });

  test(
    'updateExcursionOffer uses legacy my excursion endpoint for the guide offer',
    () async {
      final adapter = _ExcursionJsonAdapter({
        '/me/excursions/excursion-1': _legacyExcursionJson(),
      });
      final api = ExcursionApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      await api.updateExcursionOffer(
        'excursion-1',
        const CreateExcursionRequest(
          landmarkId: 'attraction-1',
          landmarkName: 'Medeu',
          categorySlug: 'adventure',
          durationMinutes: 180,
          maxGroupSize: 4,
          languageCodes: ['en'],
          meetingPoint: 'Medeu entrance',
          priceAmount: 130,
          currency: 'KZT',
          itinerary: [
            CreateExcursionItineraryItemRequest(
              startOffsetMinutes: 0,
              title: 'Meet',
              description: 'Meet the guide and start exploring.',
            ),
          ],
        ),
      );

      expect(adapter.requests.single.path, '/me/excursions/excursion-1');
      expect(adapter.lastOptions?.method, 'PUT');
    },
  );
}

Map<String, Object?> _productJson() {
  return {
    'id': 'product-1',
    'title': 'Almaty Mountain Escape',
    'summary': 'Private mountain route',
    'description': 'A private alpine route through Shymbulak and Medeu.',
    'categorySlug': 'adventure',
    'durationMinutes': 480,
    'status': 'PUBLISHED',
    'visibility': 'PUBLIC',
    'minPriceAmount': 120,
    'currency': 'USD',
    'publishedOffersCount': 2,
    'coverImageUrl': '/api/v1/excursion-products/product-1/cover',
  };
}

Map<String, Object?> _offerJson() {
  return {
    'id': 'offer-1',
    'productId': 'product-1',
    'legacyExcursionId': 'excursion-1',
    'guideProfileId': 'guide-profile-1',
    'guideUserId': 'guide-user-1',
    'title': "Aruzhan's sunrise Medeu walk",
    'summary': 'My private sunrise route',
    'description': 'My author description with exact selling points.',
    'durationMinutes': 480,
    'maxGroupSize': 4,
    'languageCodes': ['en'],
    'status': 'PUBLISHED',
    'visibility': 'PUBLIC',
    'meetingPoint': 'Hotel pickup',
    'priceAmount': 240,
    'currency': 'USD',
    'includedItems': ['Private SUV'],
  };
}

Map<String, Object?> _legacyExcursionJson() {
  return {
    'id': 'excursion-1',
    'guideProfileId': 'guide-profile-1',
    'guideUserId': 'guide-user-1',
    'title': 'Updated offer',
    'summary': 'Updated summary',
    'description':
        'Updated guide offer description with enough detail for validation.',
    'categorySlug': 'adventure',
    'durationMinutes': 180,
    'maxGroupSize': 4,
    'languageCodes': ['en'],
    'status': 'PUBLISHED',
    'visibility': 'PUBLIC',
    'meetingPoint': 'Medeu entrance',
    'priceAmount': 130,
    'currency': 'KZT',
  };
}

Map<String, Object?> _bookingJson() {
  return {
    'id': 'booking-1',
    'productId': 'product-1',
    'offerId': 'offer-1',
    'scheduleSlotId': 'slot-1',
    'touristUserId': 'tourist-1',
    'guideProfileId': 'guide-profile-1',
    'guideUserId': 'guide-user-1',
    'guideDisplayName': 'Aruzhan',
    'title': 'Medeu sunrise walk',
    'summary': 'Private city-to-mountain route',
    'landmarkId': 'attraction-1',
    'landmarkName': 'Medeu',
    'scheduledFor': '2026-05-01T08:00:00Z',
    'adults': 2,
    'children': 1,
    'totalSeats': 3,
    'totalPriceAmount': 45000,
    'currency': 'KZT',
    'status': 'REQUESTED',
    'review': _reviewJson(),
    'guideReview': _guideReviewJson(),
  };
}

Map<String, Object?> _reviewJson() {
  return {
    'id': 'review-1',
    'bookingId': 'booking-1',
    'productId': 'product-1',
    'offerId': 'offer-1',
    'touristUserId': 'tourist-1',
    'guideProfileId': 'guide-profile-1',
    'guideUserId': 'guide-user-1',
    'guideDisplayName': 'Aruzhan',
    'landmarkId': 'attraction-1',
    'landmarkName': 'Medeu',
    'rating': 4.5,
    'comment': 'Warm guide and a smooth route.',
    'createdAt': '2026-05-02T10:00:00Z',
    'updatedAt': '2026-05-02T10:00:00Z',
  };
}

Map<String, Object?> _guideReviewJson() {
  return {
    'id': 'guide-review-1',
    'bookingId': 'booking-1',
    'touristUserId': 'tourist-1',
    'guideProfileId': 'guide-profile-1',
    'guideUserId': 'guide-user-1',
    'guideDisplayName': 'Aruzhan',
    'rating': 5,
    'comment': 'Thoughtful pacing and clear stories.',
    'createdAt': '2026-05-02T10:05:00Z',
    'updatedAt': '2026-05-02T10:05:00Z',
  };
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _ExcursionJsonAdapter implements HttpClientAdapter {
  _ExcursionJsonAdapter(this.payloads);

  final Map<String, Object?> payloads;
  final List<RequestOptions> requests = [];
  RequestOptions? lastOptions;
  Map<String, dynamic>? lastJsonBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    requests.add(options);
    if (options.data is Map<String, dynamic>) {
      lastJsonBody = options.data as Map<String, dynamic>;
    }
    final payload = payloads[options.path];
    if (payload == null) {
      return ResponseBody.fromString(
        jsonEncode({'error': 'not found'}),
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
