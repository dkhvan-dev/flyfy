import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/notifications/data/initial_notification_permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('requests notification permission only once per installation', () async {
    SharedPreferences.setMockInitialValues({});
    final requester = _FakeNotificationPermissionRequester();
    final service = InitialNotificationPermissionService(requester: requester);

    await service.requestPermissionOnce();
    await service.requestPermissionOnce();

    final preferences = await SharedPreferences.getInstance();
    expect(requester.calls, 1);
    expect(
      preferences.getBool(
        InitialNotificationPermissionService.permissionRequestStorageKey,
      ),
      isTrue,
    );
  });

  test(
    'a denied notification permission is still marked as requested',
    () async {
      SharedPreferences.setMockInitialValues({});
      final requester = _FakeNotificationPermissionRequester(
        result: NotificationPermissionRequestResult.denied,
      );
      final service = InitialNotificationPermissionService(
        requester: requester,
      );

      await service.requestPermissionOnce();
      await service.requestPermissionOnce();

      expect(requester.calls, 1);
    },
  );

  test('a transient request failure is retried on the next launch', () async {
    SharedPreferences.setMockInitialValues({});
    final requester = _FakeNotificationPermissionRequester(
      failuresRemaining: 1,
    );
    final firstLaunchService = InitialNotificationPermissionService(
      requester: requester,
    );

    await firstLaunchService.requestPermissionOnce();

    var preferences = await SharedPreferences.getInstance();
    expect(requester.calls, 1);
    expect(
      preferences.getBool(
        InitialNotificationPermissionService.permissionRequestStorageKey,
      ),
      isNull,
    );

    final nextLaunchService = InitialNotificationPermissionService(
      requester: requester,
    );
    await nextLaunchService.requestPermissionOnce();

    preferences = await SharedPreferences.getInstance();
    expect(requester.calls, 2);
    expect(
      preferences.getBool(
        InitialNotificationPermissionService.permissionRequestStorageKey,
      ),
      isTrue,
    );
  });

  test('an unsupported platform is not marked as requested', () async {
    SharedPreferences.setMockInitialValues({});
    final requester = _FakeNotificationPermissionRequester(
      result: NotificationPermissionRequestResult.unsupported,
    );
    final service = InitialNotificationPermissionService(requester: requester);

    await service.requestPermissionOnce();

    final preferences = await SharedPreferences.getInstance();
    expect(requester.calls, 1);
    expect(
      preferences.getBool(
        InitialNotificationPermissionService.permissionRequestStorageKey,
      ),
      isNull,
    );
  });
}

class _FakeNotificationPermissionRequester
    implements NotificationPermissionRequester {
  _FakeNotificationPermissionRequester({
    this.result = NotificationPermissionRequestResult.granted,
    this.failuresRemaining = 0,
  });

  final NotificationPermissionRequestResult result;
  int failuresRemaining;
  int calls = 0;

  @override
  Future<NotificationPermissionRequestResult>
  requestNotificationPermission() async {
    calls += 1;
    if (failuresRemaining > 0) {
      failuresRemaining -= 1;
      throw StateError('firebase_unavailable');
    }
    return result;
  }
}
