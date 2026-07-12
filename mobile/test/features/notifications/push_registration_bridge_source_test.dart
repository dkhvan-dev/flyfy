import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'SuperApp wires push registration to authenticated session lifecycle',
    () {
      final source = File('lib/main.dart').readAsStringSync();

      expect(source, contains('PushRegistrationService'));
      expect(source, contains('Firebase.initializeApp'));
      expect(source, contains('FirebaseMessagingPushTokenProvider'));
      expect(source, contains('PushNotificationCoordinator'));
      expect(source, contains('PushNotificationBannerController'));
      expect(source, contains('PushNotificationBannerHost'));
      expect(source, contains('InAppPushNotificationPresenter'));
      expect(source, contains('FirebasePushNotificationSource'));
      expect(source, contains('LocalPushNotificationPresenter'));
      expect(source, contains('onNotificationReceived'));
      expect(source, contains('_handlePushNotificationReceived'));
      expect(
        source,
        contains('_refreshNotificationBadgeAfterPropagationDelay'),
      );
      expect(source, contains('_PushRegistrationBridge'));
      expect(source, contains('registerCurrentDevice'));
      expect(source, contains('registrationService.tokenRefreshes'));
      expect(source, contains('.listen((_) => _scheduleRegistration'));
      expect(source, contains('initialPermissionsReady'));
    },
  );

  test(
    'initial permissions run without authentication before push registration',
    () {
      final source = File('lib/main.dart').readAsStringSync();
      final flowStart = source.indexOf(
        'Future<void> _requestInitialPermissions()',
      );
      expect(flowStart, greaterThanOrEqualTo(0));
      final flowEnd = source.indexOf(
        'bool get _canContinueInitialPermissionFlow',
        flowStart,
      );
      expect(flowEnd, greaterThan(flowStart));
      final flowSource = source.substring(flowStart, flowEnd);

      expect(flowSource, isNot(contains('SessionProvider')));
      expect(
        flowSource.indexOf('requestPermissionOnce()'),
        lessThan(flowSource.indexOf('_pushTokenProvider.getCurrentToken()')),
      );
      expect(
        flowSource.indexOf('_pushTokenProvider.getCurrentToken()'),
        lessThan(flowSource.indexOf('requestInitialLocationPermission(')),
      );

      final registrationStart = source.indexOf(
        'Future<void> _registerCurrentDevice',
      );
      expect(registrationStart, greaterThanOrEqualTo(0));
      final registrationEnd = source.indexOf(
        'void _scheduleUnregistration',
        registrationStart,
      );
      expect(registrationEnd, greaterThan(registrationStart));
      final registrationSource = source.substring(
        registrationStart,
        registrationEnd,
      );
      expect(
        registrationSource.indexOf('await widget.initialPermissionsReady'),
        lessThan(
          registrationSource.indexOf(
            'registrationService.registerCurrentDevice',
          ),
        ),
      );
    },
  );
}
