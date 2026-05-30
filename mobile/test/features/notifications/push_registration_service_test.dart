import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/notifications/data/notification_api.dart';
import 'package:inflap/features/notifications/data/push_registration_service.dart';

void main() {
  test(
    'registerCurrentDevice stores backend token id and skips unchanged token',
    () async {
      final client = _FakeNotificationDeviceTokenClient();
      final store = _MemoryPushRegistrationStore();
      final provider = _FakePushTokenProvider(
        snapshot: const PushTokenSnapshot(
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
      final service = PushRegistrationService(
        client: client,
        tokenProvider: provider,
        store: store,
        sessionBindingProvider: const _FakePushSessionBindingProvider(
          sessionId: 'session-1',
          deviceInstallationId: 'installation-1',
        ),
      );

      final first = await service.registerCurrentDevice(userId: 'user-1');
      final second = await service.registerCurrentDevice(userId: 'user-1');
      final forced = await service.registerCurrentDevice(
        userId: 'user-1',
        force: true,
      );

      expect(first.status, PushRegistrationStatus.registered);
      expect(second.status, PushRegistrationStatus.skippedUnchanged);
      expect(forced.status, PushRegistrationStatus.registered);
      expect(client.registrations, hasLength(2));
      expect(client.registrations.first.token, 'push-token');
      expect(client.registrations.first.sessionId, 'session-1');
      expect(client.registrations.first.deviceInstallationId, 'installation-1');
      expect(store.registeredDeviceTokenId, 'device-token-id-2');
    },
  );

  test(
    'registerCurrentDevice skips when native token provider is unavailable',
    () async {
      final client = _FakeNotificationDeviceTokenClient();
      final service = PushRegistrationService(
        client: client,
        tokenProvider: _FakePushTokenProvider(),
        store: _MemoryPushRegistrationStore(),
      );

      final result = await service.registerCurrentDevice(userId: 'user-1');

      expect(result.status, PushRegistrationStatus.skippedUnavailable);
      expect(client.registrations, isEmpty);
    },
  );

  test(
    'registerCurrentDevice re-registers unchanged token when backend id is missing',
    () async {
      final client = _FakeNotificationDeviceTokenClient();
      final store = _MemoryPushRegistrationStore()
        ..fingerprints['user-1'] =
            'user-1|session-1|installation-1|android|fcm|production|push-token|kz.inflap|1.0.0+1|ru|Asia/Almaty';
      final service = PushRegistrationService(
        client: client,
        tokenProvider: _FakePushTokenProvider(
          snapshot: const PushTokenSnapshot(
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
        ),
        sessionBindingProvider: const _FakePushSessionBindingProvider(
          sessionId: 'session-1',
          deviceInstallationId: 'installation-1',
        ),
        store: store,
      );

      final result = await service.registerCurrentDevice(userId: 'user-1');

      expect(result.status, PushRegistrationStatus.registered);
      expect(client.registrations, hasLength(1));
      expect(store.registeredDeviceTokenId, 'device-token-id-1');
    },
  );

  test('unregisterCurrentDevice deletes stored backend token id', () async {
    final client = _FakeNotificationDeviceTokenClient();
    final store = _MemoryPushRegistrationStore()
      ..registeredDeviceTokenId = 'device-token-id-1';
    final service = PushRegistrationService(
      client: client,
      tokenProvider: _FakePushTokenProvider(),
      store: store,
    );

    final result = await service.unregisterCurrentDevice();

    expect(result.status, PushRegistrationStatus.unregistered);
    expect(client.deletedDeviceTokenIds, ['device-token-id-1']);
    expect(store.registeredDeviceTokenId, isNull);
  });
}

class _FakeNotificationDeviceTokenClient
    implements NotificationDeviceTokenClient {
  final List<DeviceTokenRegistration> registrations = [];
  final List<String> deletedDeviceTokenIds = [];

  @override
  Future<RegisteredDeviceToken> registerDeviceToken(
    DeviceTokenRegistration registration,
  ) async {
    registrations.add(registration);
    return RegisteredDeviceToken(id: 'device-token-id-${registrations.length}');
  }

  @override
  Future<void> deleteDeviceToken(String deviceTokenId) async {
    deletedDeviceTokenIds.add(deviceTokenId);
  }
}

class _FakePushTokenProvider implements PushTokenProvider {
  _FakePushTokenProvider({this.snapshot});

  final PushTokenSnapshot? snapshot;

  @override
  Stream<PushTokenSnapshot> get tokenRefreshes => const Stream.empty();

  @override
  Future<PushTokenSnapshot?> getCurrentToken() async => snapshot;
}

class _FakePushSessionBindingProvider implements PushSessionBindingProvider {
  const _FakePushSessionBindingProvider({
    required this.sessionId,
    required this.deviceInstallationId,
  });

  final String sessionId;
  final String deviceInstallationId;

  @override
  Future<String> currentSessionId() async => sessionId;

  @override
  Future<String> currentDeviceInstallationId() async => deviceInstallationId;
}

class _MemoryPushRegistrationStore implements PushRegistrationStore {
  String? registeredDeviceTokenId;
  final Map<String, String> fingerprints = {};

  @override
  Future<void> clearLastRegistrationFingerprint(String userId) async {
    fingerprints.remove(userId);
  }

  @override
  Future<void> clearRegisteredDeviceTokenId() async {
    registeredDeviceTokenId = null;
  }

  @override
  Future<String?> readLastRegistrationFingerprint(String userId) async {
    return fingerprints[userId];
  }

  @override
  Future<String?> readRegisteredDeviceTokenId() async {
    return registeredDeviceTokenId;
  }

  @override
  Future<void> writeLastRegistrationFingerprint({
    required String userId,
    required String fingerprint,
  }) async {
    fingerprints[userId] = fingerprint;
  }

  @override
  Future<void> writeRegisteredDeviceTokenId(String deviceTokenId) async {
    registeredDeviceTokenId = deviceTokenId;
  }
}
