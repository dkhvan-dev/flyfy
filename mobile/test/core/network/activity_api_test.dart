import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/network/activity_api.dart';
import 'package:superapp/core/network/api_client.dart';
import 'package:superapp/core/storage/secure_storage.dart';

void main() {
  test(
    'countCompletedActivitiesForUser reads total completion stats endpoint',
    () async {
      final adapter = _ActivityStatsAdapter({
        'userId': 'user-1',
        'hostedCompleted': 9,
        'joinedCompleted': 2,
        'totalCompleted': 11,
      });
      final api = ActivityApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final count = await api.countCompletedActivitiesForUser('user-1');

      expect(count, 11);
      expect(
        adapter.requestPath,
        '/api/v1/activities/users/user-1/completion-stats',
      );
      expect(adapter.requiresAuth, isFalse);
    },
  );
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _ActivityStatsAdapter implements HttpClientAdapter {
  _ActivityStatsAdapter(this.payload);

  final Map<String, Object?> payload;
  String? requestPath;
  bool? requiresAuth;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPath = options.uri.path;
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
