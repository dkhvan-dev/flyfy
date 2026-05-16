import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/network/api_client.dart';
import 'package:superapp/core/network/excursion_api.dart';
import 'package:superapp/core/storage/secure_storage.dart';
import 'package:superapp/features/excursions/models/create_excursion_booking_request.dart';
import 'package:superapp/features/excursions/models/create_excursion_request.dart';

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
          adapter.requests.single.path, '/excursion-products/product-1/offers');
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
    'updateExcursionOffer uses legacy my excursion endpoint for the guide offer',
    () async {
      final adapter = _ExcursionJsonAdapter(
          {'/me/excursions/excursion-1': _legacyExcursionJson()});
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
