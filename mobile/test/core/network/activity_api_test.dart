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

  test('getUserRecentActivities merges hosted and joined profile pages',
      () async {
    final adapter = _ActivityProfileListAdapter(
      hostedPayload: {
        'items': [
          _activityPayload(
            id: 'hosted-old',
            completedAt: '2026-01-10T10:00:00Z',
          ),
        ],
        'hasMore': false,
      },
      joinedPayload: {
        'items': [
          _activityPayload(
            id: 'joined-new',
            completedAt: '2026-01-12T10:00:00Z',
          ),
        ],
        'hasMore': false,
      },
    );
    final api = ActivityApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final items = await api.getUserRecentActivities('user-1', limit: 2);

    expect(items.map((item) => item.id), ['joined-new', 'hosted-old']);
    expect(adapter.requestPaths, [
      '/api/v1/activities/users/user-1/hosted',
      '/api/v1/activities/users/user-1/joined',
    ]);
    expect(adapter.requiresAuthValues, everyElement(isFalse));
    expect(adapter.limits, everyElement('2'));
    expect(adapter.offsets, everyElement('0'));
  });
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

class _ActivityProfileListAdapter implements HttpClientAdapter {
  _ActivityProfileListAdapter({
    required this.hostedPayload,
    required this.joinedPayload,
  });

  final Map<String, Object?> hostedPayload;
  final Map<String, Object?> joinedPayload;
  final List<String> requestPaths = [];
  final List<bool?> requiresAuthValues = [];
  final List<String?> limits = [];
  final List<String?> offsets = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPaths.add(options.uri.path);
    requiresAuthValues.add(options.extra['requiresAuth'] as bool?);
    limits.add(options.uri.queryParameters['limit']);
    offsets.add(options.uri.queryParameters['offset']);

    final payload =
        options.uri.path.endsWith('/hosted') ? hostedPayload : joinedPayload;
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

Map<String, Object?> _activityPayload({
  required String id,
  required String completedAt,
}) {
  return {
    'id': id,
    'hostUserId': 'host-user',
    'title': 'Activity $id',
    'description': 'Description',
    'format': 'OFFLINE',
    'status': 'COMPLETED',
    'moderationStatus': 'APPROVED',
    'visibility': 'PUBLIC',
    'joinMode': 'OPEN',
    'categorySlug': 'walks',
    'languageCode': 'ru',
    'timezone': 'Asia/Almaty',
    'startAt': '2026-01-09T10:00:00Z',
    'endAt': '2026-01-09T12:00:00Z',
    'completedAt': completedAt,
    'capacityType': 'LIMITED',
    'priceType': 'FREE',
    'requiresProfileCompletion': false,
    'requiresAttendanceConfirmation': false,
  };
}
