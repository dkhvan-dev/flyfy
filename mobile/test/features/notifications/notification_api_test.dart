import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/notifications/data/notification_api.dart';

void main() {
  test(
    'registerDeviceToken posts authenticated device token payload',
    () async {
      final adapter = _RecordingAdapter(
        response: const _JsonResponse(201, {
          'id': '0d5d33d7-7fa5-452c-b341-bdf3a51861e3',
          'platform': 'android',
          'provider': 'fcm',
          'environment': 'production',
          'appBundleId': 'kz.inflap',
          'appVersion': '1.0.0+1',
          'enabled': true,
          'lastSeenAt': '2026-05-30T10:00:00Z',
          'registeredAt': '2026-05-30T10:00:00Z',
        }),
      );
      final api = NotificationApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _MemorySecureStorage(accessToken: 'access-token'),
        ),
      );

      final registered = await api.registerDeviceToken(
        const DeviceTokenRegistration(
          platform: PushPlatform.android,
          provider: PushProvider.fcm,
          environment: PushEnvironment.production,
          token: 'push-token',
          appBundleId: 'kz.inflap',
          appVersion: '1.0.0+1',
          deviceModel: 'Pixel 8',
          manufacturer: 'Google',
          locale: 'ru',
          timezone: 'Asia/Almaty',
        ),
      );

      expect(registered.id, '0d5d33d7-7fa5-452c-b341-bdf3a51861e3');
      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/v1/notifications/device-tokens');
      expect(request.headers['Authorization'], 'Bearer access-token');
      expect(request.data, {
        'platform': 'android',
        'provider': 'fcm',
        'environment': 'production',
        'token': 'push-token',
        'appBundleId': 'kz.inflap',
        'appVersion': '1.0.0+1',
        'deviceModel': 'Pixel 8',
        'manufacturer': 'Google',
        'locale': 'ru',
        'timezone': 'Asia/Almaty',
      });
    },
  );

  test('deleteDeviceToken deletes encoded device token id', () async {
    final adapter = _RecordingAdapter(response: const _JsonResponse(204, {}));
    final api = NotificationApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _MemorySecureStorage(accessToken: 'access-token'),
      ),
    );

    await api.deleteDeviceToken('0d5d33d7-7fa5-452c-b341-bdf3a51861e3');

    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(
      request.uri.path,
      '/api/v1/notifications/device-tokens/'
      '0d5d33d7-7fa5-452c-b341-bdf3a51861e3',
    );
    expect(request.headers['Authorization'], 'Bearer access-token');
  });

  test('listNotificationCategories fetches category inbox summaries', () async {
    final adapter = _RecordingAdapter(
      response: const _JsonResponse(200, {
        'categories': [
          {
            'category': 'activity',
            'unreadCount': 2,
            'totalCount': 3,
            'latest': {
              'id': 'request-1',
              'category': 'activity',
              'priority': 'high',
              'title': 'New participant',
              'body': 'A traveler joined your activity',
              'imageUrl': '',
              'deepLink': '/activities/activity-1',
              'data': {'activityId': 'activity-1'},
              'createdAt': '2026-05-30T10:00:00Z',
              'readAt': null,
            },
          },
        ],
      }),
    );
    final api = NotificationApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _MemorySecureStorage(accessToken: 'access-token'),
      ),
    );

    final categories = await api.listNotificationCategories(limit: 20);

    expect(categories, hasLength(1));
    expect(categories.single.category, 'activity');
    expect(categories.single.unreadCount, 2);
    expect(categories.single.latest.title, 'New participant');
    expect(categories.single.latest.data['activityId'], 'activity-1');
    final request = adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.uri.path, '/api/v1/notifications/categories');
    expect(request.uri.queryParameters['limit'], '20');
    expect(request.headers['Authorization'], 'Bearer access-token');
  });

  test('markNotificationCategoryRead posts encoded category', () async {
    final adapter = _RecordingAdapter(
      response: const _JsonResponse(200, {'updatedCount': 4}),
    );
    final api = NotificationApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _MemorySecureStorage(accessToken: 'access-token'),
      ),
    );

    final result = await api.markNotificationCategoryRead(
      category: 'activity updates',
    );

    expect(result.updatedCount, 4);
    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.path, '/api/v1/notifications/read-all');
    expect(request.data, {'category': 'activity updates'});
    expect(request.headers['Authorization'], 'Bearer access-token');
  });
}

class _MemorySecureStorage extends SecureStorage {
  _MemorySecureStorage({this.accessToken});

  String? accessToken;

  @override
  Future<String?> getAccessToken() async => accessToken;
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({required this.response});

  final _JsonResponse response;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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
