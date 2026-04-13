import 'package:local_auth/local_auth.dart';

enum AppBiometricKind { none, face, fingerprint, biometrics }

enum AppBiometricAttemptResult { success, failed, canceled, fallbackToPin }

class AppBiometricAttemptOutcome {
  const AppBiometricAttemptOutcome(this.result, {this.code, this.description});

  final AppBiometricAttemptResult result;
  final LocalAuthExceptionCode? code;
  final String? description;
}

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<List<BiometricType>> availableBiometrics() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) {
        return const <BiometricType>[];
      }

      final available = await _auth.getAvailableBiometrics();
      return available.where(_isSupportedBiometric).toList(growable: false);
    } on LocalAuthException {
      return const <BiometricType>[];
    }
  }

  Future<bool> isAvailable() async {
    final biometrics = await availableBiometrics();
    return biometrics.isNotEmpty;
  }

  Future<AppBiometricKind> preferredBiometricKind() async {
    final biometrics = await availableBiometrics();
    if (biometrics.isEmpty) {
      return AppBiometricKind.none;
    }

    final names = biometrics.map((type) => type.name).toSet();
    if (names.contains('face')) {
      return AppBiometricKind.face;
    }
    if (names.contains('fingerprint') || names.contains('touchId')) {
      return AppBiometricKind.fingerprint;
    }

    return AppBiometricKind.biometrics;
  }

  Future<bool> authenticate({
    String reason = 'Подтвердите вход в аккаунт',
  }) async {
    final outcome = await authenticateWithOutcome(reason: reason);
    return outcome.result == AppBiometricAttemptResult.success;
  }

  Future<AppBiometricAttemptOutcome> authenticateWithOutcome({
    String reason = 'Подтвердите вход в аккаунт',
  }) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      return AppBiometricAttemptOutcome(
        authenticated
            ? AppBiometricAttemptResult.success
            : AppBiometricAttemptResult.failed,
      );
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
          return AppBiometricAttemptOutcome(
            AppBiometricAttemptResult.canceled,
            code: e.code,
            description: e.description,
          );
        case LocalAuthExceptionCode.authInProgress:
        case LocalAuthExceptionCode.uiUnavailable:
          return AppBiometricAttemptOutcome(
            AppBiometricAttemptResult.fallbackToPin,
            code: e.code,
            description: e.description,
          );
        case LocalAuthExceptionCode.userRequestedFallback:
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          return AppBiometricAttemptOutcome(
            AppBiometricAttemptResult.fallbackToPin,
            code: e.code,
            description: e.description,
          );
        case LocalAuthExceptionCode.deviceError:
        case LocalAuthExceptionCode.unknownError:
          return AppBiometricAttemptOutcome(
            AppBiometricAttemptResult.failed,
            code: e.code,
            description: e.description,
          );
      }
    }
  }

  bool _isSupportedBiometric(BiometricType type) {
    final name = type.name;
    return name == 'face' ||
        name == 'fingerprint' ||
        name == 'touchId' ||
        name == 'iris' ||
        name == 'strong' ||
        name == 'weak';
  }
}
