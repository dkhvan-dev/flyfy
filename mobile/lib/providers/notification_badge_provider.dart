import 'package:flutter/foundation.dart';

import '../features/notifications/data/notification_api.dart';
import '../features/notifications/utils/notification_visibility.dart';

const _notificationBadgeCacheTtl = Duration(seconds: 20);

class NotificationBadgeProvider extends ChangeNotifier {
  NotificationBadgeProvider({NotificationInboxClient? notificationApi})
    : _notificationApi = notificationApi ?? NotificationApi();

  final NotificationInboxClient _notificationApi;

  int _unreadCount = 0;
  bool _loading = false;
  DateTime? _loadedAt;
  Future<void>? _refreshFuture;

  int get unreadCount => _unreadCount;
  bool get loading => _loading;

  Future<void> refresh({bool forceRefresh = false}) {
    final inFlight = _refreshFuture;
    if (inFlight != null) {
      return inFlight;
    }
    if (!forceRefresh && _hasFreshCache) {
      return Future<void>.value();
    }

    late final Future<void> future;
    future = _refreshFromApi().whenComplete(() {
      if (identical(_refreshFuture, future)) {
        _refreshFuture = null;
      }
    });
    _refreshFuture = future;
    return future;
  }

  bool get _hasFreshCache {
    final loadedAt = _loadedAt;
    return loadedAt != null &&
        DateTime.now().toUtc().difference(loadedAt) <
            _notificationBadgeCacheTtl;
  }

  Future<void> _refreshFromApi() async {
    _loading = true;
    notifyListeners();

    try {
      final categories = await _notificationApi.listNotificationCategories(
        limit: 50,
      );
      _unreadCount = visibleUnreadNotificationCount(categories);
      _loadedAt = DateTime.now().toUtc();
    } catch (error) {
      debugPrint('refresh notification badge error: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
