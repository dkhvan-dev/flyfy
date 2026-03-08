import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../core/network/dio_error_mapper.dart';
import '../core/auth/biometric_auth_service.dart';

enum AuthState { 
  initial,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final SecureStorage _secureStorage = SecureStorage();
  final BiometricAuthService _biometricAuthService = BiometricAuthService();

  AuthState _state = AuthState.initial;
  String? _errorMessage;

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  AuthState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isSendingOtp => _isSendingOtp;
  bool get isVerifyingOtp => _isVerifyingOtp;
  bool get isGoogleLoading => _isGoogleLoading;
  bool get isAppleLoading => _isAppleLoading;

  Future<void> checkAuthStatus() async {
    try {
      final token = await _secureStorage.getAccessToken();
      _state = (token != null && token.isNotEmpty)
          ? AuthState.authenticated
          : AuthState.unauthenticated;
    } catch (_) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> sendOtp(String phone) async {
    _isSendingOtp = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.sendCode(phone);
      _isSendingOtp = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      _isSendingOtp = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Не удалось отправить код.';
      _isSendingOtp = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String code) async {
    _isVerifyingOtp = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiClient.verifyOtp(phone, code);

      await _secureStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );

      _isVerifyingOtp = false;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      _isVerifyingOtp = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Не удалось подтвердить код.';
      _isVerifyingOtp = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle(String idToken) async {
    _isGoogleLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiClient.loginWithGoogle(idToken);

      await _secureStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );

      _isGoogleLoading = false;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      _isGoogleLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Не удалось выполнить вход через Google.';
      _isGoogleLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithApple(String idToken) async {
    _isAppleLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiClient.loginWithApple(idToken);

      await _secureStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );

      _isAppleLoading = false;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      _isAppleLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Не удалось выполнить вход через Apple ID.';
      _isAppleLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      final refreshToken = await _secureStorage.getRefreshToken();

      if (accessToken != null && refreshToken != null) {
        await _apiClient.logout(accessToken, refreshToken);
      }
    } catch (_) {
    } finally {
      await _secureStorage.deleteTokens();
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> loginWithBiometrics() async {
    _errorMessage = null;
    notifyListeners();

    try {
      final biometric = BiometricAuthService();
      final available = await biometric.isAvailable();
      if (!available) {
        _errorMessage = 'Биометрия недоступна на этом устройстве';
        notifyListeners();
        return false;
      }

      final ok = await biometric.authenticate();
      if (!ok) {
        _errorMessage = 'Биометрическая аутентификация не пройдена';
        notifyListeners();
        return false;
      }

      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _errorMessage = 'Сессия не найдена, выполните обычный вход';
        notifyListeners();
        return false;
      }

      final result = await _apiClient.refreshTokens(refreshToken);

      await _secureStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );

      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Не удалось выполнить вход по биометрии';
      notifyListeners();
      return false;
    }
  }
}
