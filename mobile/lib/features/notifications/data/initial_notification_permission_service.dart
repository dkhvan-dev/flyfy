import 'package:shared_preferences/shared_preferences.dart';

enum NotificationPermissionRequestResult { granted, denied, unsupported }

abstract interface class NotificationPermissionRequester {
  Future<NotificationPermissionRequestResult> requestNotificationPermission();
}

class InitialNotificationPermissionService {
  InitialNotificationPermissionService({required this.requester});

  static const permissionRequestStorageKey =
      'inflap_initial_notification_permission_requested';

  final NotificationPermissionRequester requester;

  Future<void>? _requestFuture;

  Future<void> requestPermissionOnce() {
    final currentRequest = _requestFuture;
    if (currentRequest != null) return currentRequest;

    final nextRequest = _requestPermissionOnce();
    _requestFuture = nextRequest.whenComplete(() => _requestFuture = null);
    return _requestFuture!;
  }

  Future<void> _requestPermissionOnce() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final wasRequested =
          preferences.getBool(permissionRequestStorageKey) ?? false;
      if (wasRequested) return;

      final result = await requester.requestNotificationPermission();
      if (result == NotificationPermissionRequestResult.unsupported) return;
      await preferences.setBool(permissionRequestStorageKey, true);
    } catch (_) {
      // A transient Firebase failure should be retried on the next app launch.
    }
  }
}
