import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/network/api_client.dart';
import 'package:superapp/core/network/tour_api.dart';
import 'package:superapp/core/storage/secure_storage.dart';
import 'package:superapp/features/tours/models/create_tour_booking_request.dart';
import 'package:superapp/features/tours/models/create_tour_request.dart';

void main() {
  test('getTours uses public tour product endpoint', () async {
    final adapter = _TourJsonAdapter({
      '/tour-products': {
        'items': [_productJson()],
        'hasMore': false,
      },
    });
    final api = TourApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final tours = await api.getTours();

    expect(adapter.requests.single.path, '/tour-products');
    expect(adapter.requests.single.extra['requiresAuth'], isFalse);
    expect(tours.single.id, 'product-1');
    expect(tours.single.priceAmount, 120);
    expect(tours.single.publishedOffersCount, 2);
  });

  test('getTourById loads product details and public offers', () async {
    final adapter = _TourJsonAdapter({
      '/tour-products/product-1': _productJson(),
      '/tour-products/product-1/offers': {
        'items': [_offerJson()],
        'hasMore': false,
      },
    });
    final api = TourApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final tour = await api.getTourById('product-1');

    expect(adapter.requests.map((request) => request.path), [
      '/tour-products/product-1',
      '/tour-products/product-1/offers',
    ]);
    expect(adapter.lastOptions?.extra['requiresAuth'], isFalse);
    expect(tour.id, 'product-1');
    expect(tour.guideUserId, 'guide-user-1');
    expect(tour.maxGroupSize, 4);
    expect(tour.priceAmount, 240);
    expect(tour.offers.single.legacyTourId, 'tour-1');
    expect(tour.offers.single.title, "Aruzhan's sunrise Medeu walk");
  });

  test(
    'getTourOffers sends pagination search filters sort and pinned guide',
    () async {
      final adapter = _TourJsonAdapter({
        '/tour-products/product-1/offers': {
          'items': [_offerJson()],
          'hasMore': true,
        },
      });
      final api = TourApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final page = await api.getTourOffers(
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

      expect(adapter.requests.single.path, '/tour-products/product-1/offers');
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
    'createTourBooking posts selected product and offer to authenticated endpoint',
    () async {
      final adapter = _TourJsonAdapter({
        '/me/tour-bookings': {
          'id': 'booking-1',
          'productId': 'product-1',
          'offerId': 'offer-1',
          'status': 'REQUESTED',
        },
      });
      final api = TourApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      await api.createTourBooking(
        CreateTourBookingRequest(
          productId: 'product-1',
          offerId: 'offer-1',
          scheduledFor: DateTime.utc(2026, 6, 1, 10),
          adults: 2,
          children: 1,
        ),
      );

      expect(adapter.requests.single.path, '/me/tour-bookings');
      expect(adapter.lastOptions?.method, 'POST');
      expect(adapter.lastJsonBody?['productId'], 'product-1');
      expect(adapter.lastJsonBody?['offerId'], 'offer-1');
      expect(adapter.lastJsonBody?['adults'], 2);
      expect(adapter.lastJsonBody?['children'], 1);
    },
  );

  test(
    'updateTourOffer uses legacy my tour endpoint for the guide offer',
    () async {
      final adapter = _TourJsonAdapter({'/me/tours/tour-1': _legacyTourJson()});
      final api = TourApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      await api.updateTourOffer(
        'tour-1',
        const CreateTourRequest(
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
            CreateTourItineraryItemRequest(
              startOffsetMinutes: 0,
              title: 'Meet',
              description: 'Meet the guide and start exploring.',
            ),
          ],
        ),
      );

      expect(adapter.requests.single.path, '/me/tours/tour-1');
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
    'coverImageUrl': '/api/v1/tour-products/product-1/cover',
  };
}

Map<String, Object?> _offerJson() {
  return {
    'id': 'offer-1',
    'productId': 'product-1',
    'legacyTourId': 'tour-1',
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

Map<String, Object?> _legacyTourJson() {
  return {
    'id': 'tour-1',
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

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _TourJsonAdapter implements HttpClientAdapter {
  _TourJsonAdapter(this.payloads);

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
