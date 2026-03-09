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
  AuthProvider({
    ApiClient? apiClient,
    SecureStorage? secureStorage,
    BiometricAuthService? biometricAuthService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorage(),
        _biometricAuthService =
            biometricAuthService ?? BiometricAuthService();

  final ApiClient _apiClient;
  final SecureStorage _secureStorage;
  final BiometricAuthService _biometricAuthService;

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
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      return false;
    } catch (_) {
      return false;
    } finally {
      _isSendingOtp = false;
      notifyListeners();
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
      _state = AuthState.authenticated;
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      return false;
    } catch (_) {
      return false;
    } finally {
      _isVerifyingOtp = false;
      notifyListeners();
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
      _state = AuthState.authenticated;
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      return false;
    } catch (_) {
      return false;
    } finally {
      _isGoogleLoading = false;
      notifyListeners();
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
      _state = AuthState.authenticated;
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      return false;
    } catch (_) {
      return false;
    } finally {
      _isAppleLoading = false;
      notifyListeners();
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
      // ignore
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
      final available = await _biometricAuthService.isAvailable();
      if (!available) {
        return false;
      }

      final ok = await _biometricAuthService.authenticate();
      if (!ok) {
        return false;
      }

      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
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
      notifyListeners();
      return false;
    }
  }

  Future<bool> hasRefreshTokenForBiometricLogin() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      return refreshToken != null && refreshToken.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}