import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/device/device_context_service.dart';
import 'initial_notification_permission_service.dart';
import 'notification_api.dart';
import 'push_registration_service.dart';

enum FirebasePushRuntimePlatform { android, ios, unsupported }

typedef FirebasePushPlatformResolver = FirebasePushRuntimePlatform Function();
typedef LocaleResolver = String Function();

abstract interface class FirebaseMessagingTokenClient {
  Stream<String> get tokenRefreshes;

  Future<bool> requestPermission();

  Future<bool> isPermissionGranted();

  Future<String?> getToken();
}

class DefaultFirebaseMessagingTokenClient
    implements FirebaseMessagingTokenClient {
  DefaultFirebaseMessagingTokenClient({
    FirebaseMessaging? messaging,
    Future<void>? firebaseReady,
    // Keep the public parameter name stable while storing it privately.
    // ignore: prefer_initializing_formals
  }) : _messaging = messaging,
       _firebaseReady = firebaseReady ?? Future<void>.value();

  final FirebaseMessaging? _messaging;
  final Future<void> _firebaseReady;

  FirebaseMessaging get _resolvedMessaging =>
      _messaging ?? FirebaseMessaging.instance;

  @override
  Stream<String> get tokenRefreshes {
    return _firebaseReady.asStream().asyncExpand(
      (_) => _resolvedMessaging.onTokenRefresh,
    );
  }

  @override
  Future<String?> getToken() async {
    await _firebaseReady;
    return _resolvedMessaging.getToken();
  }

  @override
  Future<bool> requestPermission() async {
    await _firebaseReady;
    final settings = await _resolvedMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return true;
      case AuthorizationStatus.denied:
      case AuthorizationStatus.notDetermined:
        return false;
    }
  }

  @override
  Future<bool> isPermissionGranted() async {
    await _firebaseReady;
    final settings = await _resolvedMessaging.getNotificationSettings();
    return _isGranted(settings.authorizationStatus);
  }

  bool _isGranted(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }
}

class FirebaseMessagingPushTokenProvider
    implements PushTokenProvider, NotificationPermissionRequester {
  FirebaseMessagingPushTokenProvider({
    FirebaseMessagingTokenClient? client,
    this._deviceContextService = const DeviceContextService(),
    FirebasePushPlatformResolver? platformResolver,
    LocaleResolver? localeResolver,
    Future<void>? firebaseReady,
  }) : _client =
           client ??
           DefaultFirebaseMessagingTokenClient(firebaseReady: firebaseReady),
       _platformResolver = platformResolver ?? _defaultPlatformResolver,
       _localeResolver = localeResolver ?? _defaultLocaleResolver;

  static const _androidAppBundleId = String.fromEnvironment(
    'INFLAP_ANDROID_APP_ID',
    defaultValue: 'kz.inflap',
  );

  final FirebaseMessagingTokenClient _client;
  final DeviceContextService _deviceContextService;
  final FirebasePushPlatformResolver _platformResolver;
  final LocaleResolver _localeResolver;

  @override
  Stream<PushTokenSnapshot> get tokenRefreshes async* {
    await for (final token in _client.tokenRefreshes) {
      final snapshot = await _snapshotFromToken(token);
      if (snapshot != null) {
        yield snapshot;
      }
    }
  }

  @override
  Future<NotificationPermissionRequestResult>
  requestNotificationPermission() async {
    if (!_supportsNotificationPermission()) {
      return NotificationPermissionRequestResult.unsupported;
    }
    final granted = await _client.requestPermission();
    return granted
        ? NotificationPermissionRequestResult.granted
        : NotificationPermissionRequestResult.denied;
  }

  @override
  Future<PushTokenSnapshot?> getCurrentToken() async {
    if (!_supportsTokenRegistration()) {
      return null;
    }

    final permissionGranted = await _client.isPermissionGranted();
    if (!permissionGranted) {
      return null;
    }

    final token = await _client.getToken();
    return _snapshotFromToken(token);
  }

  Future<PushTokenSnapshot?> _snapshotFromToken(String? token) async {
    final normalizedToken = token?.trim() ?? '';
    if (normalizedToken.isEmpty || !_supportsTokenRegistration()) {
      return null;
    }

    return PushTokenSnapshot(
      platform: PushPlatform.android,
      provider: PushProvider.fcm,
      environment: PushEnvironment.production,
      token: normalizedToken,
      appBundleId: _androidAppBundleId,
      appVersion: '',
      deviceModel: '',
      manufacturer: '',
      locale: _localeResolver().trim(),
      timezone: await _deviceContextService.getLocalTimezone() ?? '',
    );
  }

  bool _supportsTokenRegistration() {
    return _platformResolver() == FirebasePushRuntimePlatform.android;
  }

  bool _supportsNotificationPermission() {
    final platform = _platformResolver();
    return platform == FirebasePushRuntimePlatform.android ||
        platform == FirebasePushRuntimePlatform.ios;
  }

  static FirebasePushRuntimePlatform _defaultPlatformResolver() {
    if (kIsWeb) return FirebasePushRuntimePlatform.unsupported;
    if (Platform.isAndroid) return FirebasePushRuntimePlatform.android;
    if (Platform.isIOS) {
      // Inflap sends Apple devices through APNs directly once Apple Developer
      // credentials are available; Firebase is currently used for Android FCM.
      return FirebasePushRuntimePlatform.ios;
    }
    return FirebasePushRuntimePlatform.unsupported;
  }

  static String _defaultLocaleResolver() {
    return ui.PlatformDispatcher.instance.locale.toLanguageTag();
  }
}
