import 'dart:async';

import '../../../core/storage/secure_storage.dart';
import 'notification_api.dart';

class PushTokenSnapshot {
  const PushTokenSnapshot({
    required this.platform,
    required this.provider,
    required this.environment,
    required this.token,
    required this.appBundleId,
    required this.appVersion,
    required this.deviceModel,
    required this.manufacturer,
    required this.locale,
    required this.timezone,
  });

  final PushPlatform platform;
  final PushProvider provider;
  final PushEnvironment environment;
  final String token;
  final String appBundleId;
  final String appVersion;
  final String deviceModel;
  final String manufacturer;
  final String locale;
  final String timezone;

  DeviceTokenRegistration toRegistration() {
    return DeviceTokenRegistration(
      platform: platform,
      provider: provider,
      environment: environment,
      token: token,
      appBundleId: appBundleId,
      appVersion: appVersion,
      deviceModel: deviceModel,
      manufacturer: manufacturer,
      locale: locale,
      timezone: timezone,
    );
  }

  String fingerprintForUser(String userId) {
    return [
      userId.trim(),
      platform.wireValue,
      provider.wireValue,
      environment.wireValue,
      token.trim(),
      appBundleId.trim(),
      appVersion.trim(),
      locale.trim(),
      timezone.trim(),
    ].join('|');
  }
}

abstract interface class PushTokenProvider {
  Stream<PushTokenSnapshot> get tokenRefreshes;

  Future<PushTokenSnapshot?> getCurrentToken();
}

class UnavailablePushTokenProvider implements PushTokenProvider {
  const UnavailablePushTokenProvider();

  @override
  Stream<PushTokenSnapshot> get tokenRefreshes => const Stream.empty();

  @override
  Future<PushTokenSnapshot?> getCurrentToken() async => null;
}

abstract interface class PushRegistrationStore {
  Future<String?> readRegisteredDeviceTokenId();

  Future<void> writeRegisteredDeviceTokenId(String deviceTokenId);

  Future<void> clearRegisteredDeviceTokenId();

  Future<String?> readLastRegistrationFingerprint(String userId);

  Future<void> writeLastRegistrationFingerprint({
    required String userId,
    required String fingerprint,
  });

  Future<void> clearLastRegistrationFingerprint(String userId);
}

class SecurePushRegistrationStore implements PushRegistrationStore {
  SecurePushRegistrationStore({SecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorage();

  static const _registeredDeviceTokenIdKey =
      'notifications.registeredDeviceTokenId';
  static const _fingerprintKeyPrefix = 'notifications.lastFingerprint';

  final SecureStorage _secureStorage;

  @override
  Future<String?> readRegisteredDeviceTokenId() {
    return _secureStorage.readString(_registeredDeviceTokenIdKey);
  }

  @override
  Future<void> writeRegisteredDeviceTokenId(String deviceTokenId) {
    return _secureStorage.writeString(
      key: _registeredDeviceTokenIdKey,
      value: deviceTokenId.trim(),
    );
  }

  @override
  Future<void> clearRegisteredDeviceTokenId() {
    return _secureStorage.deleteKey(_registeredDeviceTokenIdKey);
  }

  @override
  Future<String?> readLastRegistrationFingerprint(String userId) {
    return _secureStorage.readString(_fingerprintKey(userId));
  }

  @override
  Future<void> writeLastRegistrationFingerprint({
    required String userId,
    required String fingerprint,
  }) {
    return _secureStorage.writeString(
      key: _fingerprintKey(userId),
      value: fingerprint,
    );
  }

  @override
  Future<void> clearLastRegistrationFingerprint(String userId) {
    return _secureStorage.deleteKey(_fingerprintKey(userId));
  }

  String _fingerprintKey(String userId) {
    return '$_fingerprintKeyPrefix.${userId.trim()}';
  }
}

enum PushRegistrationStatus {
  registered,
  unregistered,
  skippedUnauthenticated,
  skippedUnavailable,
  skippedUnchanged,
  skippedNoRegisteredDevice,
}

class PushRegistrationResult {
  const PushRegistrationResult(this.status);

  final PushRegistrationStatus status;
}

class PushRegistrationService {
  PushRegistrationService({
    NotificationDeviceTokenClient? client,
    PushTokenProvider? tokenProvider,
    PushRegistrationStore? store,
  })  : _client = client ?? NotificationApi(),
        _tokenProvider = tokenProvider ?? const UnavailablePushTokenProvider(),
        _store = store ?? SecurePushRegistrationStore();

  final NotificationDeviceTokenClient _client;
  final PushTokenProvider _tokenProvider;
  final PushRegistrationStore _store;

  Stream<PushTokenSnapshot> get tokenRefreshes => _tokenProvider.tokenRefreshes;

  Future<PushRegistrationResult> registerCurrentDevice({
    required String userId,
    bool force = false,
  }) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      return const PushRegistrationResult(
        PushRegistrationStatus.skippedUnauthenticated,
      );
    }

    final snapshot = await _tokenProvider.getCurrentToken();
    if (snapshot == null || snapshot.token.trim().isEmpty) {
      return const PushRegistrationResult(
        PushRegistrationStatus.skippedUnavailable,
      );
    }

    final fingerprint = snapshot.fingerprintForUser(trimmedUserId);
    if (!force) {
      final previousFingerprint =
          await _store.readLastRegistrationFingerprint(trimmedUserId);
      final registeredDeviceTokenId =
          await _store.readRegisteredDeviceTokenId();
      if (previousFingerprint == fingerprint &&
          registeredDeviceTokenId != null &&
          registeredDeviceTokenId.trim().isNotEmpty) {
        return const PushRegistrationResult(
          PushRegistrationStatus.skippedUnchanged,
        );
      }
    }

    final registered = await _client.registerDeviceToken(
      snapshot.toRegistration(),
    );
    await _store.writeRegisteredDeviceTokenId(registered.id);
    await _store.writeLastRegistrationFingerprint(
      userId: trimmedUserId,
      fingerprint: fingerprint,
    );
    return const PushRegistrationResult(PushRegistrationStatus.registered);
  }

  Future<PushRegistrationResult> unregisterCurrentDevice() async {
    final deviceTokenId = await _store.readRegisteredDeviceTokenId();
    if (deviceTokenId == null || deviceTokenId.trim().isEmpty) {
      return const PushRegistrationResult(
        PushRegistrationStatus.skippedNoRegisteredDevice,
      );
    }

    await _client.deleteDeviceToken(deviceTokenId);
    await _store.clearRegisteredDeviceTokenId();
    return const PushRegistrationResult(PushRegistrationStatus.unregistered);
  }
}
