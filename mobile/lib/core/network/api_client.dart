import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_result.dart';

class ApiClient {
  final Dio _dio;

  static String _defaultBaseUrl() {
    if (Platform.isIOS) {
      return 'http://localhost:8082/api/v1';
    }
    return 'http://10.0.2.2:8082/api/v1';
  }

  ApiClient({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? _defaultBaseUrl(),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            contentType: 'application/json',
          ),
        ) {
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
  }

  Future<void> sendCode(String phone) async {
    await _dio.post('/auth/phone/send-code', data: {'phone': phone});
  }

  Future<AuthResult> verifyOtp(String phone, String code) async {
    final response = await _dio.post(
      '/auth/phone/verify',
      data: {'phone': phone, 'code': code},
    );
    return AuthResult.fromJson(response.data);
  }

  Future<AuthResult> loginWithGoogle(String idToken) async {
    final response = await _dio.post(
      '/auth/google',
      data: {'id_token': idToken},
    );
    return AuthResult.fromJson(response.data);
  }

  Future<AuthResult> loginWithApple(String idToken) async {
    final response = await _dio.post(
      '/auth/apple',
      data: {'id_token': idToken},
    );
    return AuthResult.fromJson(response.data);
  }

  Future<void> logout(String accessToken, String refreshToken) async {
    await _dio.post('/auth/logout', data: {
      'access_token': accessToken,
      'refresh_token': refreshToken,
    });
  }

  Future<AuthResult> refreshTokens(String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {
        'refresh_token': refreshToken,
      },
    );

    return AuthResult.fromJson(response.data);
  }
}
