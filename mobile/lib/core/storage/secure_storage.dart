import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keySessionId = 'session_id';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? sessionId,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    if (sessionId != null) {
      await _storage.write(key: _keySessionId, value: sessionId);
    }
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<String?> getSessionId() async {
    return await _storage.read(key: _keySessionId);
  }

  Future<void> deleteTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keySessionId);
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
}
