import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/device/device_context_service.dart';
import 'notification_api.dart';
import 'push_registration_service.dart';

enum FirebasePushRuntimePlatform { android, ios, unsupported }

typedef FirebasePushPlatformResolver = FirebasePushRuntimePlatform Function();
typedef LocaleResolver = String Function();

abstract interface class FirebaseMessagingTokenClient {
  Stream<String> get tokenRefreshes;

  Future<bool> requestPermission();

  Future<String?> getToken();
}

class DefaultFirebaseMessagingTokenClient
    implements FirebaseMessagingTokenClient {
  DefaultFirebaseMessagingTokenClient({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Future<String?> getToken() {
    return _messaging.getToken();
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
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
}

class FirebaseMessagingPushTokenProvider implements PushTokenProvider {
  FirebaseMessagingPushTokenProvider({
    FirebaseMessagingTokenClient? client,
    DeviceContextService deviceContextService = const DeviceContextService(),
    FirebasePushPlatformResolver? platformResolver,
    LocaleResolver? localeResolver,
  }) : _client = client ?? DefaultFirebaseMessagingTokenClient(),
       _deviceContextService = deviceContextService,
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
  Future<PushTokenSnapshot?> getCurrentToken() async {
    if (!_isSupportedRuntimePlatform()) {
      return null;
    }

    final permissionGranted = await _client.requestPermission();
    if (!permissionGranted) {
      return null;
    }

    final token = await _client.getToken();
    return _snapshotFromToken(token);
  }

  Future<PushTokenSnapshot?> _snapshotFromToken(String? token) async {
    final normalizedToken = token?.trim() ?? '';
    if (normalizedToken.isEmpty || !_isSupportedRuntimePlatform()) {
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

  bool _isSupportedRuntimePlatform() {
    return _platformResolver() == FirebasePushRuntimePlatform.android;
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
