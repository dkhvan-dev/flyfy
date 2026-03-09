import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/auth_result.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    SecureStorage? secureStorage,
    Dio? dio,
  })  : _secureStorage = secureStorage ?? SecureStorage(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                sendTimeout: const Duration(seconds: 10),
                contentType: 'application/json',
                responseType: ResponseType.json,
              ),
            ) {
    _configureInterceptors();
  }

  final Dio _dio;
  final SecureStorage _secureStorage;

  Future<void>? _refreshFuture;

  void _configureInterceptors() {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          requestHeader: true,
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_isAuthRoute(options.path)) {
            final accessToken = await _secureStorage.getAccessToken();
            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final statusCode = error.response?.statusCode;

          final shouldTryRefresh =
              statusCode == 401 &&
              !_isAuthRoute(request.path) &&
              request.extra['retried'] != true;

          if (!shouldTryRefresh) {
            handler.next(error);
            return;
          }

          try {
            await (_refreshFuture ??= _refreshAccessToken());
            _refreshFuture = null;

            final newAccessToken = await _secureStorage.getAccessToken();
            if (newAccessToken == null || newAccessToken.isEmpty) {
              handler.next(error);
              return;
            }

            request.headers['Authorization'] = 'Bearer $newAccessToken';
            request.extra['retried'] = true;

            final response = await _dio.fetch(request);
            handler.resolve(response);
          } catch (_) {
            _refreshFuture = null;
            await _secureStorage.deleteTokens();
            handler.next(error);
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>> initMe() async {
    final response = await _dio.post('/users/me/init');
    return response.data as Map<String, dynamic>;
  }

  bool _isAuthRoute(String path) => path.startsWith('/auth/');

  Future<void> _refreshAccessToken() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('Missing refresh token');
    }

    final result = await refreshTokens(refreshToken);
    await _secureStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
  }

  Future<void> sendCode(String phone) async {
    await _dio.post('/auth/phone/send-code', data: {'phone': phone});
  }

  Future<AuthResult> verifyOtp(String phone, String code) async {
    final response = await _dio.post(
      '/auth/phone/verify',
      data: {'phone': phone, 'code': code},
    );
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResult> loginWithGoogle(String idToken) async {
    final response = await _dio.post(
      '/auth/google',
      data: {'id_token': idToken},
    );
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResult> loginWithApple(String idToken) async {
    final response = await _dio.post(
      '/auth/apple',
      data: {'id_token': idToken},
    );
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout(String accessToken, String refreshToken) async {
    await _dio.post(
      '/auth/logout',
      data: {
        'access_token': accessToken,
        'refresh_token': refreshToken,
      },
    );
  }

  Future<AuthResult> refreshTokens(String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/users/me');
    return response.data as Map<String, dynamic>;
  }
}