import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/auth/auth_session_events.dart';
import '../core/auth/google_auth_service.dart';
import '../core/network/api_client.dart';
import '../core/network/dio_error_mapper.dart';
import '../core/storage/secure_storage.dart';

enum AuthState { initial, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    ApiClient? apiClient,
    SecureStorage? secureStorage,
    AuthSessionEvents? authSessionEvents,
    GoogleAuthTokenProvider? googleAuthTokenProvider,
  }) : this._(
         apiClient: apiClient,
         secureStorage: secureStorage ?? SecureStorage(),
         authSessionEvents: authSessionEvents ?? AuthSessionEvents.instance,
         googleAuthTokenProvider: googleAuthTokenProvider,
       );

  AuthProvider._({
    required ApiClient? apiClient,
    required SecureStorage secureStorage,
    required AuthSessionEvents authSessionEvents,
    required GoogleAuthTokenProvider? googleAuthTokenProvider,
  }) : _apiClient =
           apiClient ??
           ApiClient(
             secureStorage: secureStorage,
             authSessionEvents: authSessionEvents,
           ),
       _secureStorage = secureStorage,
       _authSessionEvents = authSessionEvents,
       _googleAuthTokenProvider =
           googleAuthTokenProvider ?? GoogleAuthService() {
    _sessionExpiredSubscription = _authSessionEvents.sessionExpired.listen((_) {
      unawaited(_handleSessionExpired());
    });
  }

  final ApiClient _apiClient;
  final SecureStorage _secureStorage;
  final AuthSessionEvents _authSessionEvents;
  final GoogleAuthTokenProvider _googleAuthTokenProvider;
  late final StreamSubscription<void> _sessionExpiredSubscription;

  AuthState _state = AuthState.initial;
  String? _errorMessage;
  String? _lastPrimaryPhoneHint;
  String? _lastPrimaryEmailHint;
  String? _pendingEmailRegistrationEmail;
  String? _pendingEmailRegistrationPassword;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isPasswordLoginLoading = false;
  bool _isEmailRegistrationLoading = false;
  bool _isPasswordResetLoading = false;
  bool _isPasswordChangeLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _wasLastOAuthCancelled = false;

  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get lastPrimaryPhoneHint => _lastPrimaryPhoneHint;
  String? get lastPrimaryEmailHint => _lastPrimaryEmailHint;
  bool get isSendingOtp => _isSendingOtp;
  bool get isVerifyingOtp => _isVerifyingOtp;
  bool get isPasswordLoginLoading => _isPasswordLoginLoading;
  bool get isEmailRegistrationLoading => _isEmailRegistrationLoading;
  bool get isPasswordResetLoading => _isPasswordResetLoading;
  bool get isPasswordChangeLoading => _isPasswordChangeLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  bool get isAppleLoading => _isAppleLoading;
  bool get wasLastOAuthCancelled => _wasLastOAuthCancelled;

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
        sessionId: result.sessionId,
      );

      _lastPrimaryPhoneHint = result.primaryPhoneHint ?? phone;
      _lastPrimaryEmailHint = result.primaryEmailHint;
      _clearPendingEmailRegistration();

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

  Future<bool> loginWithPassword(String identifier, String password) async {
    _isPasswordLoginLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiClient.loginWithPassword(identifier, password);
      await _secureStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        sessionId: result.sessionId,
      );

      _lastPrimaryPhoneHint = result.primaryPhoneHint;
      _lastPrimaryEmailHint = result.primaryEmailHint;
      _clearPendingEmailRegistration();

      _state = AuthState.authenticated;
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      return false;
    } catch (_) {
      return false;
    } finally {
      _isPasswordLoginLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startEmailRegistration(String email, String password) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();
    _isEmailRegistrationLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.startEmailRegistration(
        normalizedEmail,
        normalizedPassword,
      );
      _lastPrimaryEmailHint = normalizedEmail;
      _pendingEmailRegistrationEmail = normalizedEmail;
      _pendingEmailRegistrationPassword = password.trim();
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      return false;
    } catch (_) {
      return false;
    } finally {
      _isEmailRegistrationLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resendEmailRegistrationCode(String email) async {
    final normalizedEmail = email.trim();
    final pendingEmail = _pendingEmailRegistrationEmail;
    final password = _pendingEmailRegistrationPassword;
    if (normalizedEmail.isEmpty ||
        pendingEmail == null ||
        pendingEmail != normalizedEmail ||
        password == null ||
        password.isEmpty) {
      return false;
    }

    _isEmailRegistrationLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final email = normalizedEmail;
      await _apiClient.startEmailRegistration(email, password);
      _lastPrimaryEmailHint = email;
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      return false;
    } catch (_) {
      return false;
    } finally {
      _isEmailRegistrationLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyEmailRegistration(String email, String code) async {
    _isVerifyingOtp = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiClient.verifyEmailRegistration(email, code);
      await _secureStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        sessionId: result.sessionId,
      );

      _lastPrimaryPhoneHint = result.primaryPhoneHint;
      _lastPrimaryEmailHint = result.primaryEmailHint ?? email.trim();
      _clearPendingEmailRegistration();

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

  Future<bool> startPasswordReset(String identifier) async {
    _isPasswordResetLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.startPasswordReset(identifier);
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      return false;
    } catch (_) {
      return false;
    } finally {
      _isPasswordResetLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyPasswordReset(
    String identifier,
    String code,
    String password,
  ) async {
    _isPasswordResetLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.verifyPasswordReset(identifier, code, password);
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      return false;
    } catch (_) {
      return false;
    } finally {
      _isPasswordResetLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startPasswordChange(String currentPassword) async {
    _isPasswordChangeLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.startPasswordChange(currentPassword);
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      return false;
    } catch (_) {
      return false;
    } finally {
      _isPasswordChangeLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyPasswordChange(
    String currentPassword,
    String code,
    String newPassword,
  ) async {
    _isPasswordChangeLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.verifyPasswordChange(currentPassword, code, newPassword);
      return true;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      return false;
    } catch (_) {
      return false;
    } finally {
      _isPasswordChangeLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    _isGoogleLoading = true;
    _errorMessage = null;
    _wasLastOAuthCancelled = false;
    notifyListeners();

    try {
      final idToken = await _googleAuthTokenProvider.requestIdToken();
      if (idToken == null) {
        _wasLastOAuthCancelled = true;
        return false;
      }

      final result = await _apiClient.loginWithGoogle(idToken);
      await _secureStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        sessionId: result.sessionId,
      );

      _lastPrimaryPhoneHint = result.primaryPhoneHint;
      _lastPrimaryEmailHint = result.primaryEmailHint;
      _clearPendingEmailRegistration();

      _state = AuthState.authenticated;
      return true;
    } on GoogleAuthException catch (e) {
      _errorMessage = e.message;
      return false;
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
    _wasLastOAuthCancelled = false;
    notifyListeners();

    try {
      final result = await _apiClient.loginWithApple(idToken);
      await _secureStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        sessionId: result.sessionId,
      );

      _lastPrimaryPhoneHint = result.primaryPhoneHint;
      _lastPrimaryEmailHint = result.primaryEmailHint;
      _clearPendingEmailRegistration();

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
      _clearPendingEmailRegistration();
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _handleSessionExpired() async {
    await _secureStorage.deleteTokens();
    _lastPrimaryPhoneHint = null;
    _lastPrimaryEmailHint = null;
    _clearPendingEmailRegistration();
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  void _clearPendingEmailRegistration() {
    _pendingEmailRegistrationEmail = null;
    _pendingEmailRegistrationPassword = null;
  }

  @override
  void dispose() {
    _sessionExpiredSubscription.cancel();
    super.dispose();
  }
}
