import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyAppLockPin = 'app_lock_pin';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<void> deleteTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  Future<void> writeString({
    required String key,
    required String? value,
  }) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> readString(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> deleteKey(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _keyBiometricEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> isBiometricEnabled() async {
    return (await _storage.read(key: _keyBiometricEnabled)) == 'true';
  }

  Future<void> saveAppLockPin(String pin) async {
    await _storage.write(key: _keyAppLockPin, value: pin);
  }

  Future<String?> getAppLockPin() async {
    return await _storage.read(key: _keyAppLockPin);
  }

  Future<bool> hasAppLockPin() async {
    final pin = await _storage.read(key: _keyAppLockPin);
    return pin != null && pin.isNotEmpty;
  }

  Future<void> deleteAppLockPin() async {
    await _storage.delete(key: _keyAppLockPin);
  }

  Future<void> clearLocalAuthConfig() async {
    await deleteAppLockPin();
    await _storage.delete(key: _keyBiometricEnabled);
  }
}
