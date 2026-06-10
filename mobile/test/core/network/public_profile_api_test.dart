import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/storage/secure_storage.dart';

void main() {
  test('public user profile request does not require a bearer token', () async {
    final adapter = _PublicProfileAdapter({
      '/api/v1/public/users/user-1': _JsonResponse(200, {
        'userId': 'user-1',
        'nickname': '@guide',
        'locale': 'ru',
        'timezone': 'Asia/Almaty',
      }),
    });
    final client = ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
        ..httpClientAdapter = adapter,
      secureStorage: _EmptySecureStorage(),
    );

    final response = await client.getPublicUserById('user-1');

    expect(response['userId'], 'user-1');
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.uri.path, '/api/v1/public/users/user-1');
    expect(adapter.requests.single.extra['requiresAuth'], isFalse);
    expect(adapter.requests.single.headers['Authorization'], isNull);
  });

  test(
    'public guide profile request does not require a bearer token',
    () async {
      final adapter = _PublicProfileAdapter({
        '/api/v1/guides/public/by-user/user-1': _JsonResponse(200, {
          'guideProfile': {
            'id': 'guide-profile-1',
            'userId': 'user-1',
            'ratingAvg': 5.0,
            'reviewsCount': 0,
          },
          'languages': <Map<String, Object?>>[],
          'specializations': <Map<String, Object?>>[],
        }),
      });
      final client = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _EmptySecureStorage(),
      );

      final response = await client.getPublicGuideProfileByUserId('user-1');

      expect(response['guideProfile'], isA<Map<String, dynamic>>());
      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.uri.path,
        '/api/v1/guides/public/by-user/user-1',
      );
      expect(adapter.requests.single.extra['requiresAuth'], isFalse);
      expect(adapter.requests.single.headers['Authorization'], isNull);
    },
  );
}

class _EmptySecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;
}

class _PublicProfileAdapter implements HttpClientAdapter {
  _PublicProfileAdapter(this.responses);

  final Map<String, _JsonResponse> responses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response =
        responses[options.uri.path] ??
        const _JsonResponse(404, {'error': 'not found'});
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _JsonResponse {
  const _JsonResponse(this.statusCode, this.body);

  final int statusCode;
  final Map<String, Object?> body;
}
