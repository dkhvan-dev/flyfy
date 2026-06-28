import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:inflap/core/ui/app_design_system.dart';

class PushNotificationEnvelope {
  const PushNotificationEnvelope({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
  });

  final String id;
  final String title;
  final String body;
  final Map<String, Object?> data;
}

class PushNotificationDisplay {
  const PushNotificationDisplay({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    required this.channel,
  });

  final String id;
  final String title;
  final String body;
  final String route;
  final PushNotificationChannel channel;
}

enum PushNotificationChannel {
  activity(
    id: 'inflap_activity',
    name: 'Activity updates',
    description: 'Trips, excursions, bookings, and attendance updates',
  ),
  checklists(
    id: 'inflap_checklists',
    name: 'Checklist reminders',
    description: 'Trip readiness, packing, documents, and baggage reminders',
  ),
  messages(
    id: 'inflap_messages',
    name: 'Messages',
    description: 'Chats and direct messages',
  ),
  content(
    id: 'inflap_content',
    name: 'Posts and stories',
    description: 'Likes, replies, and updates for posts and stories',
  ),
  system(
    id: 'inflap_system',
    name: 'Inflap updates',
    description: 'Account, security, and product updates',
  );

  const PushNotificationChannel({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

abstract interface class PushNotificationSource {
  Stream<PushNotificationEnvelope> get foregroundMessages;

  Stream<PushNotificationEnvelope> get openedMessages;

  Future<PushNotificationEnvelope?> getInitialMessage();
}

abstract interface class PushNotificationPresenter {
  Future<void> initialize({required void Function(String route) onTap});

  Future<void> show(PushNotificationDisplay display);
}

class CompositePushNotificationPresenter implements PushNotificationPresenter {
  const CompositePushNotificationPresenter(this.presenters);

  final List<PushNotificationPresenter> presenters;

  @override
  Future<void> initialize({required void Function(String route) onTap}) async {
    for (final presenter in presenters) {
      await presenter.initialize(onTap: onTap);
    }
  }

  @override
  Future<void> show(PushNotificationDisplay display) async {
    for (final presenter in presenters) {
      await presenter.show(display);
    }
  }
}

typedef PushNotificationRouteHandler = void Function(String route);
typedef PushNotificationReceivedHandler =
    void Function(PushNotificationEnvelope envelope);

class PushNotificationCoordinator {
  PushNotificationCoordinator({
    required this._source,
    required this._presenter,
    required this._routeHandler,
    this.onNotificationReceived,
    this._resolver = const PushNotificationDeepLinkResolver(),
  });

  final PushNotificationSource _source;
  final PushNotificationPresenter _presenter;
  final PushNotificationRouteHandler _routeHandler;
  final PushNotificationReceivedHandler? onNotificationReceived;
  final PushNotificationDeepLinkResolver _resolver;

  final List<StreamSubscription<PushNotificationEnvelope>> _subscriptions = [];
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    await _presenter.initialize(onTap: _routeSafely);
    _subscriptions
      ..add(_source.foregroundMessages.listen(_showForegroundMessage))
      ..add(_source.openedMessages.listen(_routeFromEnvelope));

    final initialMessage = await _source.getInitialMessage();
    if (initialMessage != null) {
      scheduleMicrotask(() => _routeFromEnvelope(initialMessage));
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  Future<void> _showForegroundMessage(PushNotificationEnvelope envelope) async {
    _notifyNotificationReceived(envelope);
    final title = envelope.title.trim().isEmpty ? 'Inflap' : envelope.title;
    await _presenter.show(
      PushNotificationDisplay(
        id: envelope.id,
        title: title,
        body: envelope.body,
        route: _resolver.resolveRoute(envelope.data),
        channel: _channelFor(envelope.data),
      ),
    );
  }

  void _routeFromEnvelope(PushNotificationEnvelope envelope) {
    _notifyNotificationReceived(envelope);
    _routeSafely(_resolver.resolveRoute(envelope.data));
  }

  void _notifyNotificationReceived(PushNotificationEnvelope envelope) {
    final handler = onNotificationReceived;
    if (handler == null) return;
    try {
      handler(envelope);
    } catch (error) {
      debugPrint('push notification received handler error: $error');
    }
  }

  void _routeSafely(String route) {
    final safeRoute = _resolver.sanitizeRoute(route);
    if (safeRoute == null) return;
    _routeHandler(safeRoute);
  }

  PushNotificationChannel _channelFor(Map<String, Object?> data) {
    final category = _value(data, 'category').toLowerCase();
    final type = _value(data, 'type').toLowerCase();
    if (category.contains('chat') ||
        type.contains('chat') ||
        _value(data, 'conversationId').isNotEmpty) {
      return PushNotificationChannel.messages;
    }
    if (category.contains('content') ||
        category.contains('story') ||
        category.contains('post') ||
        _value(data, 'storyId').isNotEmpty ||
        _value(data, 'postId').isNotEmpty) {
      return PushNotificationChannel.content;
    }
    if (category.contains('checklist') ||
        _value(data, 'checklistTripId').isNotEmpty) {
      return PushNotificationChannel.checklists;
    }
    if (category.contains('activity') ||
        category.contains('excursion') ||
        category.contains('booking') ||
        _value(data, 'activityId').isNotEmpty ||
        _value(data, 'excursionId').isNotEmpty) {
      return PushNotificationChannel.activity;
    }
    return PushNotificationChannel.system;
  }
}

class FirebasePushNotificationSource implements PushNotificationSource {
  FirebasePushNotificationSource({
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
  Stream<PushNotificationEnvelope> get foregroundMessages {
    return _firebaseReady.asStream().asyncExpand(
      (_) => FirebaseMessaging.onMessage.map(_envelopeFromRemoteMessage),
    );
  }

  @override
  Stream<PushNotificationEnvelope> get openedMessages {
    return _firebaseReady.asStream().asyncExpand(
      (_) =>
          FirebaseMessaging.onMessageOpenedApp.map(_envelopeFromRemoteMessage),
    );
  }

  @override
  Future<PushNotificationEnvelope?> getInitialMessage() async {
    await _firebaseReady;
    final message = await _resolvedMessaging.getInitialMessage();
    if (message == null) return null;
    return _envelopeFromRemoteMessage(message);
  }
}

class LocalPushNotificationPresenter implements PushNotificationPresenter {
  LocalPushNotificationPresenter({
    FlutterLocalNotificationsPlugin? plugin,
    this._showForegroundNotification = true,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _notificationIcon = 'ic_stat_inflap_notification';
  static const _notificationColor = AppPalette.tealMuted03;

  final FlutterLocalNotificationsPlugin _plugin;
  final bool _showForegroundNotification;
  bool _initialized = false;

  @override
  Future<void> initialize({required void Function(String route) onTap}) async {
    if (_initialized) return;

    const android = AndroidInitializationSettings(
      '@drawable/$_notificationIcon',
    );
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload?.trim();
        if (payload == null || payload.isEmpty) return;
        onTap(payload);
      },
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      for (final channel in PushNotificationChannel.values) {
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            channel.id,
            channel.name,
            description: channel.description,
            importance: Importance.high,
            enableVibration: true,
            showBadge: true,
          ),
        );
      }
    }

    _initialized = true;
  }

  @override
  Future<void> show(PushNotificationDisplay display) async {
    if (kIsWeb || !_showForegroundNotification) return;
    await _plugin.show(
      id: _notificationId(display.id),
      title: display.title,
      body: display.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          display.channel.id,
          display.channel.name,
          channelDescription: display.channel.description,
          icon: _notificationIcon,
          importance: Importance.high,
          priority: Priority.high,
          category: _androidCategory(display.channel),
          visibility: NotificationVisibility.public,
          channelShowBadge: true,
          color: _notificationColor,
          ticker: display.title,
          subText: display.channel.name,
          styleInformation: BigTextStyleInformation(
            display.body,
            contentTitle: display.title,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: display.route,
    );
  }

  AndroidNotificationCategory _androidCategory(
    PushNotificationChannel channel,
  ) {
    return switch (channel) {
      PushNotificationChannel.messages => AndroidNotificationCategory.message,
      PushNotificationChannel.content => AndroidNotificationCategory.social,
      PushNotificationChannel.activity => AndroidNotificationCategory.event,
      PushNotificationChannel.checklists => AndroidNotificationCategory.status,
      PushNotificationChannel.system => AndroidNotificationCategory.status,
    };
  }

  int _notificationId(String id) {
    final value = id.trim().isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : id.trim();
    return value.codeUnits
        .fold<int>(0, (hash, unit) => (hash * 31 + unit) & 0x7fffffff)
        .clamp(1, maxSigned32Bit);
  }
}

class PushNotificationDeepLinkResolver {
  const PushNotificationDeepLinkResolver();

  static const fallbackRoute = '/notifications';
  static const _appScheme = 'inflap';

  String resolveRoute(Map<String, Object?> data) {
    final explicitRoute = sanitizeRoute(
      _value(data, 'deepLink').isNotEmpty
          ? _value(data, 'deepLink')
          : _value(data, 'route'),
    );
    if (explicitRoute != null) return explicitRoute;

    final conversationId = _value(data, 'conversationId');
    if (conversationId.isNotEmpty) {
      return '/chats/${Uri.encodeComponent(conversationId)}';
    }

    final chatActivityId = _value(data, 'chatActivityId');
    if (chatActivityId.isNotEmpty) {
      return '/activities/${Uri.encodeComponent(chatActivityId)}/chat';
    }

    final activityId = _value(data, 'activityId');
    if (activityId.isNotEmpty) {
      return '/activities/${Uri.encodeComponent(activityId)}';
    }

    final excursionId = _value(data, 'excursionId');
    if (excursionId.isNotEmpty) {
      return '/excursions/${Uri.encodeComponent(excursionId)}';
    }

    final placeId = _value(data, 'placeId');
    if (placeId.isNotEmpty) {
      return '/places/${Uri.encodeComponent(placeId)}';
    }

    final storySlug = _value(data, 'storySlug');
    if (storySlug.isNotEmpty) {
      return '/posts/${Uri.encodeComponent(storySlug)}';
    }

    final checklistTripId = _value(data, 'checklistTripId');
    if (checklistTripId.isNotEmpty) {
      return _checklistRouteFromData(data, checklistTripId) ?? '/me/checklists';
    }

    return fallbackRoute;
  }

  String? sanitizeRoute(String rawRoute) {
    final trimmed = rawRoute.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('/') && !trimmed.startsWith('//')) {
      return trimmed;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme != _appScheme) {
      return null;
    }

    if (uri.host.isNotEmpty && uri.path.isNotEmpty) {
      return '/${uri.host}${uri.path}${_query(uri)}';
    }
    if (uri.host.isNotEmpty) {
      return '/${uri.host}${_query(uri)}';
    }
    if (uri.path.isNotEmpty) {
      return '${uri.path}${_query(uri)}';
    }
    return null;
  }

  String _query(Uri uri) {
    return uri.hasQuery ? '?${uri.query}' : '';
  }

  String? _checklistRouteFromData(
    Map<String, Object?> data,
    String checklistTripId,
  ) {
    final countryCode = _value(data, 'countryCode');
    final cityName = _value(data, 'cityName');
    final startAt = _value(data, 'startAt');
    final endAt = _value(data, 'endAt');
    if (countryCode.isEmpty ||
        cityName.isEmpty ||
        startAt.isEmpty ||
        endAt.isEmpty) {
      return null;
    }

    final params = <String, String>{
      'tripId': checklistTripId,
      'countryCode': countryCode,
      'cityName': cityName,
      'startAt': startAt,
      'endAt': endAt,
      if (_value(data, 'cityId').isNotEmpty) 'cityId': _value(data, 'cityId'),
      if (_value(data, 'countryName').isNotEmpty)
        'countryName': _value(data, 'countryName'),
      if (_value(data, 'transportModes').isNotEmpty)
        'transportModes': _value(data, 'transportModes'),
      if (_value(data, 'activitySlugs').isNotEmpty)
        'activitySlugs': _value(data, 'activitySlugs'),
    };
    return '/travel-checklist?${Uri(queryParameters: params).query}';
  }
}

PushNotificationEnvelope _envelopeFromRemoteMessage(RemoteMessage message) {
  final data = <String, Object?>{
    for (final entry in message.data.entries) entry.key: entry.value,
  };
  final notification = message.notification;
  return PushNotificationEnvelope(
    id:
        message.messageId ??
        message.sentTime?.microsecondsSinceEpoch.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString(),
    title: notification?.title ?? _value(data, 'title'),
    body: notification?.body ?? _value(data, 'body'),
    data: data,
  );
}

String _value(Map<String, Object?> data, String key) {
  return data[key]?.toString().trim() ?? '';
}

const maxSigned32Bit = 0x7fffffff;
