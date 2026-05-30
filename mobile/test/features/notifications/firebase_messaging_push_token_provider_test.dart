import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/device/device_context_service.dart';
import 'package:inflap/features/notifications/data/firebase_messaging_push_token_provider.dart';
import 'package:inflap/features/notifications/data/notification_api.dart';

void main() {
  test('getCurrentToken builds an Android FCM token snapshot', () async {
    final client = _FakeFirebaseMessagingTokenClient(
      permissionGranted: true,
      token: 'fcm-token',
    );
    final provider = FirebaseMessagingPushTokenProvider(
      client: client,
      deviceContextService: const _FakeDeviceContextService('Asia/Almaty'),
      platformResolver: () => FirebasePushRuntimePlatform.android,
      localeResolver: () => 'ru',
    );

    final snapshot = await provider.getCurrentToken();

    expect(snapshot, isNotNull);
    expect(snapshot!.platform, PushPlatform.android);
    expect(snapshot.provider, PushProvider.fcm);
    expect(snapshot.environment, PushEnvironment.production);
    expect(snapshot.token, 'fcm-token');
    expect(snapshot.appBundleId, 'kz.inflap');
    expect(snapshot.locale, 'ru');
    expect(snapshot.timezone, 'Asia/Almaty');
    expect(client.requestPermissionCalls, 1);
    expect(client.getTokenCalls, 1);
  });

  test(
    'getCurrentToken skips when notification permission is denied',
    () async {
      final client = _FakeFirebaseMessagingTokenClient(
        permissionGranted: false,
        token: 'fcm-token',
      );
      final provider = FirebaseMessagingPushTokenProvider(
        client: client,
        platformResolver: () => FirebasePushRuntimePlatform.android,
      );

      final snapshot = await provider.getCurrentToken();

      expect(snapshot, isNull);
      expect(client.requestPermissionCalls, 1);
      expect(client.getTokenCalls, 0);
    },
  );

  test('getCurrentToken skips unsupported platforms', () async {
    final client = _FakeFirebaseMessagingTokenClient(
      permissionGranted: true,
      token: 'fcm-token',
    );
    final provider = FirebaseMessagingPushTokenProvider(
      client: client,
      platformResolver: () => FirebasePushRuntimePlatform.unsupported,
    );

    final snapshot = await provider.getCurrentToken();

    expect(snapshot, isNull);
    expect(client.requestPermissionCalls, 0);
    expect(client.getTokenCalls, 0);
  });
}

class _FakeFirebaseMessagingTokenClient
    implements FirebaseMessagingTokenClient {
  _FakeFirebaseMessagingTokenClient({
    required this.permissionGranted,
    required this.token,
  });

  final bool permissionGranted;
  final String? token;
  int requestPermissionCalls = 0;
  int getTokenCalls = 0;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Future<String?> getToken() async {
    getTokenCalls++;
    return token;
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    return permissionGranted;
  }
}

class _FakeDeviceContextService extends DeviceContextService {
  const _FakeDeviceContextService(this.timezone);

  final String timezone;

  @override
  Future<String?> getLocalTimezone() async => timezone;
}
