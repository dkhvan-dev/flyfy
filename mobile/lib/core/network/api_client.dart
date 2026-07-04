import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_session_events.dart';
import '../config/app_config.dart';
import '../models/auth_result.dart';
import '../storage/secure_storage.dart';
import 'debug_network_inspector.dart';

class _CompactNetworkLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('HTTP -> ${options.method} ${_safeRoute(options)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final request = response.requestOptions;
    debugPrint(
      'HTTP <- ${response.statusCode ?? '-'} ${request.method} '
      '${_safeRoute(request)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = err.requestOptions;
    final status = err.response?.statusCode?.toString() ?? err.type.name;
    debugPrint('HTTP !! $status ${request.method} ${_safeRoute(request)}');
    handler.next(err);
  }

  String _safeRoute(RequestOptions options) {
    final uri = options.uri;
    final path = uri.path.isEmpty ? options.path : uri.path;
    final queryKeys =
        uri.queryParameters.keys.where((key) => key.trim().isNotEmpty).toList()
          ..sort();

    if (queryKeys.isEmpty) return path;
    return '$path?${queryKeys.join('&')}';
  }
}

class ApiClient {
  ApiClient({
    String? baseUrl,
    SecureStorage? secureStorage,
    Dio? dio,
    AuthSessionEvents? authSessionEvents,
    bool? enableDebugNetworkInspector,
    DebugNetworkInspectorFactory? debugNetworkInspectorFactory,
  }) : _secureStorage = secureStorage ?? SecureStorage(),
       _authSessionEvents = authSessionEvents ?? AuthSessionEvents.instance,
       _enableDebugNetworkInspector =
           enableDebugNetworkInspector ??
           (dio == null && DebugNetworkInspector.isEnabled),
       _dio =
           dio ??
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
    _configureInterceptors(debugNetworkInspectorFactory);
  }

  final Dio _dio;
  final SecureStorage _secureStorage;
  final AuthSessionEvents _authSessionEvents;
  final bool _enableDebugNetworkInspector;

  // SecureStorage is shared app-wide, so refresh must be serialized app-wide too.
  static Future<void>? _sharedRefreshFuture;
  static String _appLocaleCode = 'ru';

  Dio get dio => _dio;

  static void setAppLocale(String code) {
    _appLocaleCode = _normalizeLocaleCode(code);
  }

  void _configureInterceptors(
    DebugNetworkInspectorFactory? debugNetworkInspectorFactory,
  ) {
    DebugNetworkInspector.attachToDio(
      _dio,
      enabled: _enableDebugNetworkInspector,
      factory: debugNetworkInspectorFactory,
    );

    if (kDebugMode) {
      _dio.interceptors.add(_CompactNetworkLogInterceptor());
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          _attachLocaleHeaders(options);

          final requiresAuth = _requiresAuth(options);

          if (requiresAuth) {
            var accessToken = await _secureStorage.getAccessToken();
            if (accessToken == null || accessToken.isEmpty) {
              try {
                accessToken = await _restoreAccessTokenIfPossible();
              } catch (_) {
                accessToken = null;
              }
            }

            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            } else {
              await _expireLocalSession();
              handler.reject(_missingAccessTokenError(options));
              return;
            }
          } else if (_usesOptionalAuth(options)) {
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
              _requiresAuth(request) &&
              request.extra['retried'] != true;

          if (!shouldTryRefresh) {
            handler.next(error);
            return;
          }

          try {
            await _refreshAccessTokenIfNeeded(request);

            final newAccessToken = await _secureStorage.getAccessToken();
            if (newAccessToken == null || newAccessToken.isEmpty) {
              await _expireLocalSession();
              handler.next(error);
              return;
            }

            request.headers['Authorization'] = 'Bearer $newAccessToken';
            request.extra['retried'] = true;

            final response = await _dio.fetch(request);
            handler.resolve(response);
          } catch (_) {
            await _expireLocalSession();
            handler.next(error);
          }
        },
      ),
    );
  }

  bool _requiresAuth(RequestOptions options) {
    final requiresAuthFromExtra = options.extra['requiresAuth'];
    if (requiresAuthFromExtra == true) {
      return true;
    }
    if (requiresAuthFromExtra == false) {
      return false;
    }
    if (_usesOptionalAuth(options)) {
      return false;
    }
    return !_isAuthRoute(options.path);
  }

  bool _usesOptionalAuth(RequestOptions options) {
    return options.extra['optionalAuth'] == true;
  }

  void _attachLocaleHeaders(RequestOptions options) {
    final locale = _appLocaleCode;
    options.headers.putIfAbsent('Accept-Language', () => locale);
    options.headers.putIfAbsent('X-Language', () => locale);
  }

  static String _normalizeLocaleCode(String code) {
    final normalized = code.trim().toLowerCase();
    if (normalized.startsWith('en')) return 'en';
    if (normalized.startsWith('kk')) return 'kk';
    return 'ru';
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
      sessionId: result.sessionId,
    );
  }

  Future<String?> _restoreAccessTokenIfPossible() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      await _refreshAccessTokenShared();
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }
      return accessToken;
    } catch (_) {
      await _secureStorage.deleteTokens();
      return null;
    }
  }

  Future<void> _refreshAccessTokenIfNeeded(RequestOptions failedRequest) async {
    final currentAccessToken = await _secureStorage.getAccessToken();
    final failedAuthorization = failedRequest.headers['Authorization'];
    if (currentAccessToken != null &&
        currentAccessToken.isNotEmpty &&
        failedAuthorization != 'Bearer $currentAccessToken') {
      return;
    }

    await _refreshAccessTokenShared();
  }

  Future<void> _refreshAccessTokenShared() async {
    final existingRefresh = _sharedRefreshFuture;
    if (existingRefresh != null) {
      await existingRefresh;
      return;
    }

    final refresh = _refreshAccessToken();
    _sharedRefreshFuture = refresh;
    try {
      await refresh;
    } finally {
      if (identical(_sharedRefreshFuture, refresh)) {
        _sharedRefreshFuture = null;
      }
    }
  }

  DioException _missingAccessTokenError(RequestOptions options) {
    return DioException(
      requestOptions: options,
      response: Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 401,
        data: const {
          'error': 'authentication_required',
          'message': 'Войдите в аккаунт, чтобы продолжить.',
        },
      ),
      type: DioExceptionType.badResponse,
    );
  }

  Future<void> _expireLocalSession() async {
    await _secureStorage.deleteTokens();
    _authSessionEvents.notifySessionExpired();
  }

  Future<Map<String, dynamic>> initMe({
    String? primaryPhone,
    String? primaryEmail,
  }) async {
    final body = <String, dynamic>{};

    if ((primaryPhone ?? '').trim().isNotEmpty) {
      body['primaryPhone'] = primaryPhone!.trim();
    }
    if ((primaryEmail ?? '').trim().isNotEmpty) {
      body['primaryEmail'] = primaryEmail!.trim();
    }

    final response = await _dio.post('/users/me/init', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/users/me');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUserById(String userId) async {
    final response = await _dio.get('/users/$userId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPublicUserById(String userId) async {
    final encodedUserId = Uri.encodeComponent(userId.trim());
    final response = await _dio.get(
      '/public/users/$encodedUserId',
      options: Options(extra: const {'requiresAuth': false}),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> nicknameAvailability(String nickname) async {
    final response = await _dio.get(
      '/users/nickname-availability',
      queryParameters: {'nickname': nickname},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> updatePresence() async {
    await _dio.post('/users/me/presence');
  }

  Future<void> followUser(String userId) async {
    await _dio.post('/users/$userId/follow');
  }

  Future<void> unfollowUser(String userId) async {
    await _dio.delete('/users/$userId/follow');
  }

  Future<Map<String, dynamic>> sendFriendRequest(String userId) async {
    final response = await _dio.post('/users/$userId/friend-request');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelFriendRequest(String userId) async {
    final response = await _dio.delete('/users/$userId/friend-request');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> declineFriendRequest(String userId) async {
    final response = await _dio.delete('/users/$userId/friend-request');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> acceptFriendRequest(String userId) async {
    final response = await _dio.post('/users/$userId/friendship');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> removeFriend(String userId) async {
    final response = await _dio.delete('/users/$userId/friendship');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUserFollowers(
    String userId, {
    int limit = 20,
    int offset = 0,
    String? query,
  }) async {
    final response = await _dio.get(
      '/users/$userId/followers',
      queryParameters: <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if ((query ?? '').trim().isNotEmpty) 'q': query!.trim(),
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMyFriends({
    int limit = 20,
    int offset = 0,
    String? query,
    String? sort,
    String? sortDirection,
    bool onlineOnly = false,
  }) async {
    final response = await _dio.get(
      '/users/me/friends',
      queryParameters: <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if ((query ?? '').trim().isNotEmpty) 'q': query!.trim(),
        if ((sort ?? '').trim().isNotEmpty) 'sort': sort!.trim(),
        if ((sortDirection ?? '').trim().isNotEmpty)
          'sortDirection': sortDirection,
        if (onlineOnly) 'onlineOnly': true,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMyIncomingFriendRequests({
    int limit = 20,
    int offset = 0,
    String? query,
  }) async {
    final response = await _dio.get(
      '/users/me/friend-requests/incoming',
      queryParameters: <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if ((query ?? '').trim().isNotEmpty) 'q': query!.trim(),
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMyFollowing({
    int limit = 20,
    int offset = 0,
    String? query,
    String? sort,
    String? sortDirection,
    bool onlineOnly = false,
  }) async {
    final response = await _dio.get(
      '/users/me/following',
      queryParameters: <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if ((query ?? '').trim().isNotEmpty) 'q': query!.trim(),
        if ((sort ?? '').trim().isNotEmpty) 'sort': sort!.trim(),
        if ((sortDirection ?? '').trim().isNotEmpty)
          'sortDirection': sortDirection,
        if (onlineOnly) 'onlineOnly': true,
      },
    );
    return response.data as Map<String, dynamic>;
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

  Future<AuthResult> loginWithPassword(
    String identifier,
    String password,
  ) async {
    final response = await _dio.post(
      '/auth/login/password',
      data: {'identifier': identifier, 'password': password},
    );
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> startEmailRegistration(String email, String password) async {
    await _dio.post(
      '/auth/register/email/start',
      data: {'email': email, 'password': password},
    );
  }

  Future<AuthResult> verifyEmailRegistration(String email, String code) async {
    final response = await _dio.post(
      '/auth/register/email/verify',
      data: {'email': email, 'code': code},
    );
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> startPasswordReset(String identifier) async {
    await _dio.post(
      '/auth/password/reset/start',
      data: {'identifier': identifier},
    );
  }

  Future<void> verifyPasswordReset(
    String identifier,
    String code,
    String password,
  ) async {
    await _dio.post(
      '/auth/password/reset/verify',
      data: {'identifier': identifier, 'code': code, 'password': password},
    );
  }

  Future<void> startPasswordChange(String currentPassword) async {
    await _dio.post(
      '/auth/password/change/start',
      data: {'current_password': currentPassword},
      options: Options(extra: {'requiresAuth': true}),
    );
  }

  Future<void> verifyPasswordChange(
    String currentPassword,
    String code,
    String newPassword,
  ) async {
    await _dio.post(
      '/auth/password/change/verify',
      data: {
        'current_password': currentPassword,
        'code': code,
        'new_password': newPassword,
      },
      options: Options(extra: {'requiresAuth': true}),
    );
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
      data: {'access_token': accessToken, 'refresh_token': refreshToken},
    );
  }

  Future<AuthResult> refreshTokens(String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> updateMeProfile(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put('/users/me/profile', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startProfilePhoneVerification(
    String phone,
  ) async {
    final response = await _dio.post(
      '/users/me/phone/verification/start',
      data: {'phone': phone},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyProfilePhoneVerification(
    String challengeId,
    String code,
  ) async {
    final response = await _dio.post(
      '/users/me/phone/verification/verify',
      data: {'challengeId': challengeId, 'code': code},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resendProfilePhoneVerification(
    String challengeId,
  ) async {
    final response = await _dio.post(
      '/users/me/phone/verification/resend',
      data: {'challengeId': challengeId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> cancelPendingProfilePhoneVerification() async {
    await _dio.delete('/users/me/phone/pending');
  }

  Future<Map<String, dynamic>> updateMeSettings(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put('/users/me/settings', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createFileDownloadUrl(String fileId) async {
    final response = await _dio.post('/files/$fileId/download-url');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMyGuideProfile() async {
    final response = await _dio.get('/guides/me');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGuideProfileByUserId(String userId) async {
    final response = await _dio.get('/guides/by-user/$userId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPublicGuideProfileByUserId(
    String userId,
  ) async {
    final encodedUserId = Uri.encodeComponent(userId.trim());
    final response = await _dio.get(
      '/guides/public/by-user/$encodedUserId',
      options: Options(extra: const {'requiresAuth': false}),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitMyGuideApplication(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post('/guides/me/application', data: body);
    return response.data as Map<String, dynamic>;
  }
}
