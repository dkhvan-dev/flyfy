import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../core/network/dio_error_mapper.dart';
import '../core/storage/secure_storage.dart';

enum AuthState { initial, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    ApiClient? apiClient,
    SecureStorage? secureStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorage();

  final ApiClient _apiClient;
  final SecureStorage _secureStorage;

  AuthState _state = AuthState.initial;
  String? _errorMessage;
  String? _lastPrimaryPhoneHint;
  String? _lastPrimaryEmailHint;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get lastPrimaryPhoneHint => _lastPrimaryPhoneHint;
  String? get lastPrimaryEmailHint => _lastPrimaryEmailHint;
  bool get isSendingOtp => _isSendingOtp;
  bool get isVerifyingOtp => _isVerifyingOtp;
  bool get isGoogleLoading => _isGoogleLoading;
  bool get isAppleLoading => _isAppleLoading;

  Future<void> checkAuthStatus() async {
    try {
      final token = await _secureStorage.getAccessToken();
      final refreshToken = await _secureStorage.getRefreshToken();
      final hasAccess = token != null && token.isNotEmpty;
      final hasRefresh = refreshToken != null && refreshToken.isNotEmpty;
      _state = hasAccess || hasRefresh
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

      _lastPrimaryPhoneHint = result.primaryPhoneHint ?? phone;
      _lastPrimaryEmailHint = result.primaryEmailHint;

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

      _lastPrimaryPhoneHint = result.primaryPhoneHint;
      _lastPrimaryEmailHint = result.primaryEmailHint;

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

      _lastPrimaryPhoneHint = result.primaryPhoneHint;
      _lastPrimaryEmailHint = result.primaryEmailHint;

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
      _lastPrimaryPhoneHint = null;
      _lastPrimaryEmailHint = null;
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }
}
