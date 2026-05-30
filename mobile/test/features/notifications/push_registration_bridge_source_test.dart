import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SuperApp wires push registration to authenticated session lifecycle',
      () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('PushRegistrationService'));
    expect(source, contains('Firebase.initializeApp'));
    expect(source, contains('FirebaseMessagingPushTokenProvider'));
    expect(source, contains('PushNotificationCoordinator'));
    expect(source, contains('FirebasePushNotificationSource'));
    expect(source, contains('LocalPushNotificationPresenter'));
    expect(source, contains('_PushRegistrationBridge'));
    expect(source, contains('registerCurrentDevice'));
    expect(source, contains('tokenRefreshes.listen'));
  });
}
