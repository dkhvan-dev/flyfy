import '../storage/secure_storage.dart';

class AppLockService {
  AppLockService({SecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorage();

  final SecureStorage _secureStorage;

  Future<bool> hasPin() => _secureStorage.hasAppLockPin();

  Future<void> savePin(String pin) => _secureStorage.saveAppLockPin(pin);

  Future<bool> verifyPin(String pin) async {
    final savedPin = await _secureStorage.getAppLockPin();
    return savedPin != null && savedPin == pin;
  }

  Future<void> clear() => _secureStorage.clearLocalAuthConfig();

  Future<bool> isBiometricEnabled() => _secureStorage.isBiometricEnabled();

  Future<void> setBiometricEnabled(bool enabled) =>
      _secureStorage.setBiometricEnabled(enabled);

  Future<bool> hasStoredSession() async {
    final accessToken = await _secureStorage.getAccessToken();
    final refreshToken = await _secureStorage.getRefreshToken();
    return (accessToken != null && accessToken.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);
  }
}
