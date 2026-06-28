import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/places/data/place_api.dart';

void main() {
  test('getPlaces sends search query without requiring auth', () async {
    final adapter = _JsonAdapter({'items': const [], 'total': 0});
    final api = PlaceApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    await api.getPlaces(search: '  Алматы  ', limit: 24, offset: 0);

    expect(adapter.requestPath, '/places');
    expect(adapter.queryParameters['search'], 'Алматы');
    expect(adapter.queryParameters['limit'], '24');
    expect(adapter.queryParameters['offset'], '0');
    expect(adapter.requiresAuth, isFalse);
  });

  test('getPlaces sends device coordinates for nearby sorting', () async {
    final adapter = _JsonAdapter({'items': const [], 'total': 0});
    final api = PlaceApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    await api.getPlaces(
      latitude: 43.238949,
      longitude: 76.889709,
      sort: 'distance',
      limit: 10,
    );

    expect(adapter.requestPath, '/places');
    expect(adapter.queryParameters['latitude'], '43.238949');
    expect(adapter.queryParameters['longitude'], '76.889709');
    expect(adapter.queryParameters['sort'], 'distance');
    expect(adapter.queryParameters['limit'], '10');
    expect(adapter.requiresAuth, isFalse);
  });
}

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.payload);

  final Map<String, dynamic> payload;
  String? requestPath;
  Map<String, String> queryParameters = const {};
  bool? requiresAuth;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPath = options.path;
    queryParameters = options.queryParameters.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    requiresAuth = options.extra['requiresAuth'] as bool?;
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

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<String?> getSessionId() async => null;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? sessionId,
  }) async {}

  @override
  Future<void> deleteTokens() async {}
}
