import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/auth/auth_session_events.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/storage/secure_storage.dart';

void main() {
  test(
    'protected request without stored tokens fails locally and expires session',
    () async {
      final events = AuthSessionEvents();
      var expiredCount = 0;
      final sub = events.sessionExpired.listen((_) => expiredCount++);
      final adapter = _AuthAdapter();
      final client = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _MemorySecureStorage(),
        authSessionEvents: events,
      );

      await expectLater(client.getMe(), throwsA(isA<DioException>()));
      await Future<void>.delayed(Duration.zero);

      expect(adapter.requests, isEmpty);
      expect(expiredCount, 1);
      await sub.cancel();
    },
  );

  test(
    'session expiration is emitted before token cleanup completes',
    () async {
      final events = AuthSessionEvents();
      var expiredCount = 0;
      final sub = events.sessionExpired.listen((_) => expiredCount++);
      final storage = _BlockingDeleteSecureStorage();
      final client = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1')),
        secureStorage: storage,
        authSessionEvents: events,
      );

      final requestExpectation = expectLater(
        client.getMe(),
        throwsA(isA<DioException>()),
      );
      await storage.deleteStarted;

      expect(expiredCount, 1);

      storage.completeDelete();
      await requestExpectation;
      await sub.cancel();
    },
  );

  test('refresh failure deletes tokens and expires session', () async {
    final events = AuthSessionEvents();
    var expiredCount = 0;
    final sub = events.sessionExpired.listen((_) => expiredCount++);
    final storage = _MemorySecureStorage(
      accessToken: 'expired-access',
      refreshToken: 'expired-refresh',
    );
    final adapter = _AuthAdapter(
      responses: {
        '/api/v1/users/me': _JsonResponse(401, {'error': 'token expired'}),
        '/api/v1/auth/refresh': _JsonResponse(401, {
          'error': 'refresh token expired',
        }),
      },
    );
    final client = ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
        ..httpClientAdapter = adapter,
      secureStorage: storage,
      authSessionEvents: events,
    );

    await expectLater(client.getMe(), throwsA(isA<DioException>()));
    await Future<void>.delayed(Duration.zero);

    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
    expect(expiredCount, 1);
    expect(adapter.requests.map((item) => item.uri.path), [
      '/api/v1/users/me',
      '/api/v1/auth/refresh',
    ]);
    await sub.cancel();
  });

  test('refresh success without access token expires session', () async {
    final events = AuthSessionEvents();
    var expiredCount = 0;
    final sub = events.sessionExpired.listen((_) => expiredCount++);
    final storage = _MemorySecureStorage(
      accessToken: 'expired-access',
      refreshToken: 'refresh-token',
    );
    final adapter = _AuthAdapter(
      responses: {
        '/api/v1/users/me': _JsonResponse(401, {'error': 'token expired'}),
        '/api/v1/auth/refresh': _JsonResponse(200, {
          'access_token': '',
          'refresh_token': '',
          'is_new_user': false,
        }),
      },
    );
    final client = ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
        ..httpClientAdapter = adapter,
      secureStorage: storage,
      authSessionEvents: events,
    );

    await expectLater(client.getMe(), throwsA(isA<DioException>()));
    await Future<void>.delayed(Duration.zero);

    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
    expect(expiredCount, 1);
    expect(adapter.requests.map((item) => item.uri.path), [
      '/api/v1/users/me',
      '/api/v1/auth/refresh',
    ]);
    await sub.cancel();
  });

  test(
    'concurrent 401 responses across api clients share one token refresh',
    () async {
      final events = AuthSessionEvents();
      var expiredCount = 0;
      final sub = events.sessionExpired.listen((_) => expiredCount++);
      final storage = _MemorySecureStorage(
        accessToken: 'expired-access',
        refreshToken: 'rotating-refresh',
      );
      final adapter = _RotatingRefreshAdapter();
      final firstClient = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: storage,
        authSessionEvents: events,
      );
      final secondClient = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: storage,
        authSessionEvents: events,
      );

      await expectLater(
        Future.wait([firstClient.getMe(), secondClient.getMe()]),
        completes,
      );
      await Future<void>.delayed(Duration.zero);

      expect(adapter.refreshRequests, 1);
      expect(storage.accessToken, 'fresh-access');
      expect(storage.refreshToken, 'fresh-refresh');
      expect(expiredCount, 0);
      await sub.cancel();
    },
  );

  test(
    'optional auth request attaches stored access token without requiring one',
    () async {
      final events = AuthSessionEvents();
      var expiredCount = 0;
      final sub = events.sessionExpired.listen((_) => expiredCount++);
      final storage = _MemorySecureStorage(accessToken: 'access-token');
      final adapter = _AuthAdapter();
      final client = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: storage,
        authSessionEvents: events,
      );

      await client.dio.get(
        '/feed',
        options: Options(extra: const {'optionalAuth': true}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer access-token',
      );
      expect(expiredCount, 0);
      await sub.cancel();
    },
  );

  test(
    'optional auth 401 refresh failure expires the authenticated session',
    () async {
      final events = AuthSessionEvents();
      var expiredCount = 0;
      final sub = events.sessionExpired.listen((_) => expiredCount++);
      final storage = _MemorySecureStorage(
        accessToken: 'expired-access',
        refreshToken: 'expired-refresh',
      );
      final adapter = _AuthAdapter(
        responses: {
          '/api/v1/feed': _JsonResponse(401, {'error': 'token expired'}),
          '/api/v1/auth/refresh': _JsonResponse(401, {
            'error': 'refresh token expired',
          }),
        },
      );
      final client = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: storage,
        authSessionEvents: events,
      );

      await expectLater(
        client.dio.get(
          '/feed',
          options: Options(extra: const {'optionalAuth': true}),
        ),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(expiredCount, 1);
      expect(adapter.requests.map((item) => item.uri.path), [
        '/api/v1/feed',
        '/api/v1/auth/refresh',
      ]);
      await sub.cancel();
    },
  );

  test(
    'optional auth request continues anonymously when tokens are missing',
    () async {
      final events = AuthSessionEvents();
      var expiredCount = 0;
      final sub = events.sessionExpired.listen((_) => expiredCount++);
      final adapter = _AuthAdapter();
      final client = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _MemorySecureStorage(),
        authSessionEvents: events,
      );

      await client.dio.get(
        '/feed',
        options: Options(extra: const {'optionalAuth': true}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(adapter.requests.single.headers['Authorization'], isNull);
      expect(expiredCount, 0);
      await sub.cancel();
    },
  );

  test(
    'optional auth request does not refresh when only refresh token exists',
    () async {
      final events = AuthSessionEvents();
      var expiredCount = 0;
      final sub = events.sessionExpired.listen((_) => expiredCount++);
      final storage = _MemorySecureStorage(refreshToken: 'refresh-token');
      final adapter = _AuthAdapter(
        responses: {
          '/api/v1/auth/refresh': _JsonResponse(200, {
            'access_token': 'fresh-access',
            'refresh_token': 'fresh-refresh',
            'is_new_user': false,
          }),
        },
      );
      final client = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: storage,
        authSessionEvents: events,
      );

      await client.dio.get(
        '/feed',
        options: Options(extra: const {'optionalAuth': true}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(adapter.requests.map((item) => item.uri.path), ['/api/v1/feed']);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, 'refresh-token');
      expect(expiredCount, 0);
      await sub.cancel();
    },
  );

  test('attaches current app locale headers to every request', () async {
    final adapter = _AuthAdapter();
    final client = ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
        ..httpClientAdapter = adapter,
      secureStorage: _MemorySecureStorage(),
      authSessionEvents: AuthSessionEvents(),
    );

    ApiClient.setAppLocale('kk');
    addTearDown(() => ApiClient.setAppLocale('ru'));

    await client.dio.get(
      '/feed',
      options: Options(extra: const {'optionalAuth': true}),
    );

    expect(adapter.requests.single.headers['Accept-Language'], 'kk');
    expect(adapter.requests.single.headers['X-Language'], 'kk');
  });

  test('attaches bounded rollout metadata only to Saved requests', () async {
    final adapter = _AuthAdapter();
    final client = ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
        ..httpClientAdapter = adapter,
      secureStorage: _MemorySecureStorage(accessToken: 'access-token'),
      authSessionEvents: AuthSessionEvents(),
      clientPlatform: 'android',
      appBuild: 42,
    );

    await client.dio.get('/users/me/saved-items/capabilities');
    await client.dio.get('/users/me');

    expect(adapter.requests.first.headers['X-Client-Platform'], 'android');
    expect(adapter.requests.first.headers['X-App-Build'], '42');
    expect(adapter.requests.last.headers['X-Client-Platform'], isNull);
    expect(adapter.requests.last.headers['X-App-Build'], isNull);
  });

  test('attaches debug network inspector only when enabled', () {
    final enabledDio = Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'));
    final disabledDio = Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'));

    ApiClient(
      dio: enabledDio,
      secureStorage: _MemorySecureStorage(),
      authSessionEvents: AuthSessionEvents(),
      enableDebugNetworkInspector: true,
      debugNetworkInspectorFactory: _FakeNetworkInspector.new,
    );
    ApiClient(
      dio: disabledDio,
      secureStorage: _MemorySecureStorage(),
      authSessionEvents: AuthSessionEvents(),
      enableDebugNetworkInspector: false,
      debugNetworkInspectorFactory: _FakeNetworkInspector.new,
    );

    expect(
      enabledDio.interceptors.whereType<_FakeNetworkInspector>(),
      hasLength(1),
    );
    expect(
      disabledDio.interceptors.whereType<_FakeNetworkInspector>(),
      isEmpty,
    );
  });

  test('keeps debug network inspector off by default in tests', () {
    final client = ApiClient(
      baseUrl: 'http://backend.test/api/v1',
      secureStorage: _MemorySecureStorage(),
      authSessionEvents: AuthSessionEvents(),
      debugNetworkInspectorFactory: _FakeNetworkInspector.new,
    );

    expect(client.dio.interceptors.whereType<_FakeNetworkInspector>(), isEmpty);
  });
}

class _FakeNetworkInspector extends Interceptor {}

class _MemorySecureStorage extends SecureStorage {
  _MemorySecureStorage({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? sessionId,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> deleteTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

class _BlockingDeleteSecureStorage extends _MemorySecureStorage {
  final Completer<void> _deleteStartedCompleter = Completer<void>();
  final Completer<void> _deleteCompleter = Completer<void>();

  Future<void> get deleteStarted => _deleteStartedCompleter.future;

  void completeDelete() {
    if (!_deleteCompleter.isCompleted) {
      _deleteCompleter.complete();
    }
  }

  @override
  Future<void> deleteTokens() async {
    if (!_deleteStartedCompleter.isCompleted) {
      _deleteStartedCompleter.complete();
    }
    await _deleteCompleter.future;
    await super.deleteTokens();
  }
}

class _AuthAdapter implements HttpClientAdapter {
  _AuthAdapter({this.responses = const {}});

  final Map<String, _JsonResponse> responses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response =
        responses[options.uri.path] ??
        const _JsonResponse(200, {
          'user': {'id': 'user-1', 'status': 'ACTIVE'},
          'profile': {'locale': 'ru', 'timezone': 'Asia/Almaty'},
        });
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _JsonResponse {
  const _JsonResponse(this.statusCode, this.body);

  final int statusCode;
  final Map<String, Object?> body;
}

class _RotatingRefreshAdapter implements HttpClientAdapter {
  int refreshRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path == '/api/v1/auth/refresh') {
      refreshRequests++;
      if (refreshRequests == 1) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return _json(200, {
          'access_token': 'fresh-access',
          'refresh_token': 'fresh-refresh',
          'is_new_user': false,
        });
      }

      return _json(401, {'error': 'refresh token already used'});
    }

    if (options.headers['Authorization'] == 'Bearer fresh-access') {
      return _json(200, {
        'user': {'id': 'user-1', 'status': 'ACTIVE'},
        'profile': {'locale': 'ru', 'timezone': 'Asia/Almaty'},
      });
    }

    return _json(401, {'error': 'token expired'});
  }

  ResponseBody _json(int statusCode, Map<String, Object?> body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
