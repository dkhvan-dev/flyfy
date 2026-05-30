import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  messages(
    id: 'inflap_messages',
    name: 'Messages',
    description: 'Chats and direct messages',
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

typedef PushNotificationRouteHandler = void Function(String route);

class PushNotificationCoordinator {
  PushNotificationCoordinator({
    required PushNotificationSource source,
    required PushNotificationPresenter presenter,
    required PushNotificationRouteHandler routeHandler,
    PushNotificationDeepLinkResolver resolver =
        const PushNotificationDeepLinkResolver(),
  })  : _source = source,
        _presenter = presenter,
        _routeHandler = routeHandler,
        _resolver = resolver;

  final PushNotificationSource _source;
  final PushNotificationPresenter _presenter;
  final PushNotificationRouteHandler _routeHandler;
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

  Future<void> _showForegroundMessage(
    PushNotificationEnvelope envelope,
  ) async {
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
    _routeSafely(_resolver.resolveRoute(envelope.data));
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
  FirebasePushNotificationSource({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Stream<PushNotificationEnvelope> get foregroundMessages =>
      FirebaseMessaging.onMessage.map(_envelopeFromRemoteMessage);

  @override
  Stream<PushNotificationEnvelope> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp.map(_envelopeFromRemoteMessage);

  @override
  Future<PushNotificationEnvelope?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) return null;
    return _envelopeFromRemoteMessage(message);
  }
}

class LocalPushNotificationPresenter implements PushNotificationPresenter {
  LocalPushNotificationPresenter({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> initialize({required void Function(String route) onTap}) async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
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

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      for (final channel in PushNotificationChannel.values) {
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            channel.id,
            channel.name,
            description: channel.description,
            importance: Importance.high,
          ),
        );
      }
    }

    _initialized = true;
  }

  @override
  Future<void> show(PushNotificationDisplay display) async {
    if (kIsWeb) return;
    await _plugin.show(
      id: _notificationId(display.id),
      title: display.title,
      body: display.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          display.channel.id,
          display.channel.name,
          channelDescription: display.channel.description,
          importance: Importance.high,
          priority: Priority.high,
          category: _androidCategory(display.channel),
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
      PushNotificationChannel.activity => AndroidNotificationCategory.event,
      PushNotificationChannel.system => AndroidNotificationCategory.status,
    };
  }

  int _notificationId(String id) {
    final value = id.trim().isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : id.trim();
    return value.codeUnits
        .fold<int>(
          0,
          (hash, unit) => (hash * 31 + unit) & 0x7fffffff,
        )
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

    final attractionId = _value(data, 'attractionId');
    if (attractionId.isNotEmpty) {
      return '/attractions/${Uri.encodeComponent(attractionId)}';
    }

    final storySlug = _value(data, 'storySlug');
    if (storySlug.isNotEmpty) {
      return '/stories/${Uri.encodeComponent(storySlug)}';
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
}

PushNotificationEnvelope _envelopeFromRemoteMessage(RemoteMessage message) {
  final data = <String, Object?>{
    for (final entry in message.data.entries) entry.key: entry.value,
  };
  final notification = message.notification;
  return PushNotificationEnvelope(
    id: message.messageId ??
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
