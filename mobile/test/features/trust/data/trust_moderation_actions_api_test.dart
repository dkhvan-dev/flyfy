import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/trust/data/trust_moderation_actions_api.dart';

void main() {
  test(
    'trust moderation API contract accepts injectable request handlers',
    () async {
      final api = _RecordingTrustModerationActionsApi();
      const target = TrustModerationTarget(
        entityType: TrustModerationEntityType.story,
        entityId: 'story-123',
        ownerUserId: 'author-456',
        contextId: 'community-789',
      );

      await api.reportContent(
        const TrustReportContentRequest(
          target: target,
          reason: TrustReportReason.harassment,
          details: 'Repeated unsafe messages',
        ),
      );
      await api.muteTarget(const TrustMuteTargetRequest(target: target));
      await api.unmuteTarget(const TrustMuteTargetRequest(target: target));
      await api.muteUser(const TrustMuteUserRequest(userId: 'author-456'));
      await api.unmuteUser(const TrustMuteUserRequest(userId: 'author-456'));
      await api.appealRestriction(
        const TrustRestrictionAppealRequest(
          restrictionId: 'restriction-001',
          message: 'I can provide more context for review.',
        ),
      );

      expect(api.reportRequest?.target, target);
      expect(api.reportRequest?.reason, TrustReportReason.harassment);
      expect(api.muteTargetRequest?.target, target);
      expect(api.unmuteTargetRequest?.target, target);
      expect(api.muteRequest?.userId, 'author-456');
      expect(api.unmuteRequest?.userId, 'author-456');
      expect(api.appealRequest?.restrictionId, 'restriction-001');
    },
  );

  test(
    'gateway trust API reports story content through story report endpoint',
    () async {
      final adapter = _JsonAdapter({'status': 'RECEIVED'});
      final api = GatewayTrustModerationActionsApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      await api.reportContent(
        const TrustReportContentRequest(
          target: TrustModerationTarget(
            entityType: TrustModerationEntityType.story,
            entityId: ' story-123 ',
          ),
          reason: TrustReportReason.hateSpeech,
          details: ' unsafe copy ',
        ),
      );

      expect(adapter.requestPath, '/api/v1/posts/story-123/report');
      expect(adapter.method, 'POST');
      expect(adapter.requiresAuth, isTrue);
      expect(adapter.requestBody, {
        'reason': 'HATE_SPEECH',
        'details': 'unsafe copy',
      });
    },
  );

  test(
    'gateway trust API submits restriction appeal through trust endpoint',
    () async {
      final adapter = _JsonAdapter({
        'appeal': {'appealId': 'appeal-1'},
      });
      final api = GatewayTrustModerationActionsApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      await api.appealRestriction(
        const TrustRestrictionAppealRequest(
          restrictionId: ' restriction-123 ',
          reasonCode: 'mistaken_restriction',
          message: ' Please review again. ',
          idempotencyKey: ' appeal-key-1 ',
        ),
      );

      expect(
        adapter.requestPath,
        '/api/v1/trust/restrictions/restriction-123/appeals',
      );
      expect(adapter.method, 'POST');
      expect(adapter.requiresAuth, isTrue);
      expect(adapter.requestBody, {
        'reasonCode': 'mistaken_restriction',
        'userMessage': 'Please review again.',
        'idempotencyKey': 'appeal-key-1',
      });
    },
  );

  test('gateway trust API reports and mutes community targets', () async {
    final adapter = _JsonAdapter({'status': 'OK'});
    final api = GatewayTrustModerationActionsApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );
    const target = TrustModerationTarget(
      entityType: TrustModerationEntityType.community,
      entityId: ' community-1 ',
    );

    await api.reportContent(
      const TrustReportContentRequest(
        target: target,
        reason: TrustReportReason.scam,
        details: ' unsafe offers ',
      ),
    );
    expect(adapter.requestPath, '/api/v1/communities/community-1/report');
    expect(adapter.method, 'POST');
    expect(adapter.requiresAuth, isTrue);
    expect(adapter.requestBody, {'reason': 'SCAM', 'details': 'unsafe offers'});

    await api.muteTarget(const TrustMuteTargetRequest(target: target));
    expect(adapter.requestPath, '/api/v1/communities/community-1/mute');
    expect(adapter.method, 'POST');
    expect(adapter.requiresAuth, isTrue);

    await api.unmuteTarget(const TrustMuteTargetRequest(target: target));
    expect(adapter.requestPath, '/api/v1/communities/community-1/mute');
    expect(adapter.method, 'DELETE');
    expect(adapter.requiresAuth, isTrue);
  });

  test('gateway trust API rejects unsupported generic mute contract', () async {
    final api = GatewayTrustModerationActionsApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1')),
        secureStorage: _FakeSecureStorage(),
      ),
    );

    expect(
      () => api.muteUser(const TrustMuteUserRequest(userId: 'user-1')),
      throwsUnsupportedError,
    );
  });
}

class _RecordingTrustModerationActionsApi implements TrustModerationActionsApi {
  TrustReportContentRequest? reportRequest;
  TrustMuteTargetRequest? muteTargetRequest;
  TrustMuteTargetRequest? unmuteTargetRequest;
  TrustMuteUserRequest? muteRequest;
  TrustMuteUserRequest? unmuteRequest;
  TrustRestrictionAppealRequest? appealRequest;

  @override
  Future<void> reportContent(TrustReportContentRequest request) async {
    reportRequest = request;
  }

  @override
  Future<void> muteTarget(TrustMuteTargetRequest request) async {
    muteTargetRequest = request;
  }

  @override
  Future<void> unmuteTarget(TrustMuteTargetRequest request) async {
    unmuteTargetRequest = request;
  }

  @override
  Future<void> muteUser(TrustMuteUserRequest request) async {
    muteRequest = request;
  }

  @override
  Future<void> unmuteUser(TrustMuteUserRequest request) async {
    unmuteRequest = request;
  }

  @override
  Future<void> appealRestriction(TrustRestrictionAppealRequest request) async {
    appealRequest = request;
  }
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.payload);

  final Map<String, Object?> payload;
  String? requestPath;
  String? method;
  bool? requiresAuth;
  Map<String, dynamic> requestBody = const {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    requestPath = options.uri.path;
    requiresAuth = options.extra['requiresAuth'] as bool?;
    requestBody = await _decodeRequestBody(requestStream);
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<Map<String, dynamic>> _decodeRequestBody(
  Stream<Uint8List>? requestStream,
) async {
  if (requestStream == null) {
    return const {};
  }
  final chunks = await requestStream.toList();
  if (chunks.isEmpty) {
    return const {};
  }
  final bytes = chunks.expand((chunk) => chunk).toList(growable: false);
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  return const {};
}
