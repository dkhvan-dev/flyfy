import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app lock pin and biometric implementation is removed from mobile app',
      () async {
    expect(File('lib/core/auth/app_lock_gate.dart').existsSync(), isFalse);
    expect(File('lib/core/auth/app_lock_service.dart').existsSync(), isFalse);
    expect(File('lib/core/auth/biometric_auth_service.dart').existsSync(),
        isFalse);

    final pubspec = await File('pubspec.yaml').readAsString();
    final mainSource = await File('lib/main.dart').readAsString();
    final authProviderSource =
        await File('lib/providers/auth_provider.dart').readAsString();
    final secureStorageSource =
        await File('lib/core/storage/secure_storage.dart').readAsString();
    final loginSource =
        await File('lib/screens/auth/login_screen.dart').readAsString();
    final profileSecuritySource =
        await File('lib/screens/profile/profile_security_screen.dart')
            .readAsString();
    final editProfileSource =
        await File('lib/screens/profile/edit_profile_screen.dart')
            .readAsString();
    final iosInfoPlist = await File('ios/Runner/Info.plist').readAsString();

    expect(pubspec, isNot(contains('local_auth')));
    expect(mainSource, isNot(contains('hasStoredSessionForUnlock')));
    expect(authProviderSource, isNot(contains('biometric_auth_service')));
    expect(authProviderSource, isNot(contains('loginWithBiometrics')));
    expect(authProviderSource,
        isNot(contains('hasRefreshTokenForBiometricLogin')));
    expect(secureStorageSource, isNot(contains('BiometricEnabled')));
    expect(secureStorageSource, isNot(contains('AppLockPin')));
    expect(secureStorageSource, isNot(contains('clearLocalAuthConfig')));
    expect(loginSource, isNot(contains('loginWithBiometrics')));
    expect(loginSource, isNot(contains('biometricLoginFailed')));
    expect(loginSource, isNot(contains('Icons.fingerprint')));
    expect(profileSecuritySource, isNot(contains('AppLockService')));
    expect(profileSecuritySource, isNot(contains('BiometricAuthService')));
    expect(profileSecuritySource, isNot(contains('profileSecurityPin')));
    expect(profileSecuritySource, isNot(contains('profileSecurityBiometric')));
    expect(profileSecuritySource,
        isNot(contains('profileSecurityProtectedSession')));
    expect(editProfileSource, isNot(contains('_SecurityLinkCard')));
    expect(
        editProfileSource, isNot(contains('profileSettingsSecuritySection')));
    expect(
        editProfileSource, isNot(contains('profileSettingsSecurityPinTitle')));
    expect(iosInfoPlist, isNot(contains('NSFaceIDUsageDescription')));
  });

  test('app lock localization keys are removed from arb files', () async {
    for (final locale in ['en', 'ru', 'kk']) {
      final arb = await File('lib/l10n/app_$locale.arb').readAsString();

      expect(arb, isNot(contains('loginWithBiometrics')));
      expect(arb, isNot(contains('biometricLoginFailed')));
      expect(arb, isNot(contains('appLock')));
      expect(arb, isNot(contains('profileSettingsSecurityPin')));
      expect(arb, isNot(contains('profileSecurityLocalAccessSection')));
      expect(arb, isNot(contains('profileSecurityPin')));
      expect(arb, isNot(contains('profileSecurityBiometric')));
      expect(arb, isNot(contains('profileSecurityProtectedSession')));
      expect(arb, isNot(contains('profileSecurityNoStoredSession')));
    }
  });
}
