import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/network/api_client.dart';
import 'package:superapp/core/network/tour_api.dart';
import 'package:superapp/core/storage/secure_storage.dart';

void main() {
  test('getTourById uses public tour-service endpoint', () async {
    final adapter = _TourJsonAdapter(_tourJson());
    final api = TourApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final tour = await api.getTourById('tour-1');

    expect(adapter.lastOptions?.path, '/tours/tour-1');
    expect(adapter.lastOptions?.extra['requiresAuth'], isFalse);
    expect(tour.id, 'tour-1');
    expect(tour.itinerary.first.title, 'Hotel departure');
  });
}

Map<String, Object?> _tourJson() {
  return {
    'id': 'tour-1',
    'title': 'Almaty Mountain Escape',
    'summary': 'Private mountain route',
    'description': 'A private alpine route through Shymbulak and Medeu.',
    'categorySlug': 'adventure',
    'durationMinutes': 480,
    'maxGroupSize': 4,
    'languageCodes': ['en'],
    'status': 'PUBLISHED',
    'visibility': 'PUBLIC',
    'meetingPoint': 'Hotel pickup',
    'priceAmount': 240,
    'currency': 'USD',
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
  };
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _TourJsonAdapter implements HttpClientAdapter {
  _TourJsonAdapter(this.payload);

  final Map<String, Object?> payload;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
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
