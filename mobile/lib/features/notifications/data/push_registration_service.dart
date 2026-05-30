import 'dart:async';
import 'dart:math';

import 'package:jwt_decoder/jwt_decoder.dart';

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
    return toSessionBoundRegistration(sessionId: '', deviceInstallationId: '');
  }

  DeviceTokenRegistration toSessionBoundRegistration({
    required String sessionId,
    required String deviceInstallationId,
  }) {
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
      sessionId: sessionId,
      deviceInstallationId: deviceInstallationId,
    );
  }

  String fingerprintForUser(
    String userId, {
    required String sessionId,
    required String deviceInstallationId,
  }) {
    return [
      userId.trim(),
      sessionId.trim(),
      deviceInstallationId.trim(),
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

abstract interface class PushSessionBindingProvider {
  Future<String> currentSessionId();

  Future<String> currentDeviceInstallationId();
}

class SecurePushSessionBindingProvider implements PushSessionBindingProvider {
  SecurePushSessionBindingProvider({SecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? SecureStorage();

  static const _deviceInstallationIdKey = 'notifications.deviceInstallationId';

  final SecureStorage _secureStorage;

  @override
  Future<String> currentSessionId() async {
    final stored = (await _secureStorage.getSessionId())?.trim();
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    final accessToken = (await _secureStorage.getAccessToken())?.trim();
    if (accessToken == null || accessToken.isEmpty) {
      return '';
    }
    try {
      final claims = JwtDecoder.decode(accessToken);
      return (claims['sid'] ?? claims['session_id'] ?? claims['sessionId'])
              ?.toString()
              .trim() ??
          '';
    } catch (_) {
      return '';
    }
  }

  @override
  Future<String> currentDeviceInstallationId() async {
    final existing = (await _secureStorage.readString(
      _deviceInstallationIdKey,
    ))?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated = _newUuidV4();
    await _secureStorage.writeString(
      key: _deviceInstallationIdKey,
      value: generated,
    );
    return generated;
  }
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
    PushSessionBindingProvider? sessionBindingProvider,
    PushRegistrationStore? store,
  }) : _client = client ?? NotificationApi(),
       _tokenProvider = tokenProvider ?? const UnavailablePushTokenProvider(),
       _sessionBindingProvider =
           sessionBindingProvider ?? SecurePushSessionBindingProvider(),
       _store = store ?? SecurePushRegistrationStore();

  final NotificationDeviceTokenClient _client;
  final PushTokenProvider _tokenProvider;
  final PushSessionBindingProvider _sessionBindingProvider;
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

    final sessionId = await _sessionBindingProvider.currentSessionId();
    final deviceInstallationId = await _sessionBindingProvider
        .currentDeviceInstallationId();
    final fingerprint = snapshot.fingerprintForUser(
      trimmedUserId,
      sessionId: sessionId,
      deviceInstallationId: deviceInstallationId,
    );
    if (!force) {
      final previousFingerprint = await _store.readLastRegistrationFingerprint(
        trimmedUserId,
      );
      final registeredDeviceTokenId = await _store
          .readRegisteredDeviceTokenId();
      if (previousFingerprint == fingerprint &&
          registeredDeviceTokenId != null &&
          registeredDeviceTokenId.trim().isNotEmpty) {
        return const PushRegistrationResult(
          PushRegistrationStatus.skippedUnchanged,
        );
      }
    }

    final registered = await _client.registerDeviceToken(
      snapshot.toSessionBoundRegistration(
        sessionId: sessionId,
        deviceInstallationId: deviceInstallationId,
      ),
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

String _newUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return [
    hex.substring(0, 8),
    hex.substring(8, 12),
    hex.substring(12, 16),
    hex.substring(16, 20),
    hex.substring(20),
  ].join('-');
}
