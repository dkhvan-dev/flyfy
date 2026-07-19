import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/saved/data/saved_api.dart';
import 'package:inflap/features/saved/domain/saved_error.dart';
import 'package:inflap/features/saved/domain/saved_operation.dart';
import 'package:inflap/features/saved/domain/saved_status.dart';
import 'package:inflap/features/saved/domain/saved_target.dart';

void main() {
  final identity = SavedOperationIdentity(
    operationId: '11111111-2222-4333-8444-555555555555',
    idempotencyKey: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
  );
  final target = SavedTarget(
    entityType: SavedEntityType.activity,
    entityId: 'opaque /?% key',
  );

  test(
    'PUT and DELETE encode opaque target and preserve operation headers',
    () async {
      final adapter = _QueueAdapter(<_JsonResponse>[
        _JsonResponse(
          200,
          _operationBody(
            target,
            identity.operationId,
            kind: 'SAVE_TARGET',
            saved: true,
            version: 1,
          ),
        ),
        _JsonResponse(
          200,
          _operationBody(
            target,
            identity.operationId,
            kind: 'UNSAVE_TARGET',
            saved: false,
            version: 2,
          ),
        ),
      ]);
      final api = _apiWith(adapter);

      final saved = await api.putSavedItem(
        target: target,
        identity: identity,
        sourceSurface: SavedSourceSurface.card,
      );
      final unsaved = await api.deleteSavedItem(
        target: target,
        identity: identity,
        sourceSurface: SavedSourceSurface.savedAll,
      );

      expect(saved.savedItemSnapshot?.savedState, SavedConfirmation.saved);
      expect(
        unsaved.savedItemSnapshot?.savedState,
        SavedConfirmation.confirmedUnsaved,
      );
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests[0].method, 'PUT');
      expect(adapter.requests[1].method, 'DELETE');
      for (final request in adapter.requests) {
        expect(
          request.uri.path,
          '/api/v1/users/me/saved-items/ACTIVITY/opaque%20%2F%3F%25%20key',
        );
        expect(request.headers['Authorization'], 'Bearer access-token');
        expect(request.headers['Operation-Id'], identity.operationId);
        expect(request.headers['Idempotency-Key'], identity.idempotencyKey);
      }
      expect(adapter.requests[0].headers['Saved-Source-Surface'], 'CARD');
      expect(adapter.requests[1].headers['Saved-Source-Surface'], 'SAVED_ALL');
    },
  );

  test(
    'status batch posts target JSON and parses exact nested status',
    () async {
      final adapter = _QueueAdapter(<_JsonResponse>[
        _JsonResponse(200, <String, Object?>{
          'statuses': <Object?>[
            <String, Object?>{
              'target': target.toJson(),
              'saved_state': 'SAVED',
              'effective_collection_count': 3,
              'eligibility_hint': 'ELIGIBLE',
              'relationship_generation': _relationshipGeneration,
              'resource_version': 9,
            },
          ],
        }),
      ]);
      final api = _apiWith(adapter);

      final statuses = await api.getStatuses(<SavedTarget>[target]);

      expect(statuses.single.target, target);
      expect(statuses.single.resourceVersion, 9);
      expect(statuses.single.relationshipGeneration, _relationshipGeneration);
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/v1/users/me/saved-items/status:batch');
      expect(request.data, <String, Object?>{
        'targets': <Object?>[target.toJson()],
      });
      expect(request.headers['Authorization'], 'Bearer access-token');
    },
  );

  test(
    'operation status GET validates echo and maps stable neutral 404',
    () async {
      final adapter = _QueueAdapter(<_JsonResponse>[
        _JsonResponse(
          200,
          _operationBody(
            target,
            identity.operationId,
            kind: 'SAVE_TARGET',
            saved: true,
            version: 4,
          ),
        ),
        const _JsonResponse(404, <String, Object?>{
          'code': 'NOT_FOUND',
          'retryable': false,
        }),
      ]);
      final api = _apiWith(adapter);

      final result = await api.getOperation(identity.operationId);
      expect(result.operationId, identity.operationId);
      expect(
        adapter.requests.first.uri.path,
        '/api/v1/users/me/saved-operations/${identity.operationId}',
      );
      await expectLater(
        api.getOperation(identity.operationId),
        throwsA(isA<SavedOperationNotFoundException>()),
      );
    },
  );

  test('mutation rejects a different operation ID echo', () async {
    final adapter = _QueueAdapter(<_JsonResponse>[
      _JsonResponse(
        200,
        _operationBody(
          target,
          '99999999-8888-4777-8666-555555555555',
          kind: 'SAVE_TARGET',
          saved: true,
          version: 4,
        ),
      ),
    ]);

    await expectLater(
      _apiWith(adapter).putSavedItem(target: target, identity: identity),
      throwsFormatException,
    );
  });

  test('mutation HTTP status matches pending or terminal result', () async {
    final pendingBody =
        _operationBody(
            target,
            identity.operationId,
            kind: 'SAVE_TARGET',
            saved: true,
            version: 4,
          )
          ..['operation_status'] = 'PENDING'
          ..['operation_outcome'] = 'PENDING';
    final adapter = _QueueAdapter(<_JsonResponse>[
      _JsonResponse(202, pendingBody),
      _JsonResponse(200, pendingBody),
    ]);
    final api = _apiWith(adapter);

    expect(
      (await api.putSavedItem(target: target, identity: identity)).status,
      SavedOperationStatus.pending,
    );
    await expectLater(
      api.putSavedItem(target: target, identity: identity),
      throwsFormatException,
    );
  });

  test(
    'HTTP failures expose a strictly parsed stable error envelope',
    () async {
      final adapter = _QueueAdapter(<_JsonResponse>[
        const _JsonResponse(409, <String, Object?>{
          'code': 'SAVED_MUTATION_REPLAY_MISMATCH',
          'retryable': false,
          'request_id': 'request-409',
        }),
      ]);

      try {
        await _apiWith(
          adapter,
        ).putSavedItem(target: target, identity: identity);
        fail('Expected SavedApiException.');
      } on SavedApiException catch (error) {
        expect(error.statusCode, 409);
        expect(error.error?.code, SavedErrorCode.mutationReplayMismatch);
        expect(error.error?.requestId, 'request-409');
        expect(error.errorEnvelopeFormatException, isNull);
      }
    },
  );
}

SavedApi _apiWith(_QueueAdapter adapter) {
  return SavedApi(
    apiClient: ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
        ..httpClientAdapter = adapter,
      secureStorage: _MemorySecureStorage('access-token'),
    ),
  );
}

Map<String, Object?> _operationBody(
  SavedTarget target,
  String operationId, {
  required String kind,
  required bool saved,
  required int version,
}) {
  return <String, Object?>{
    'operation_id': operationId,
    'operation_kind': kind,
    'operation_status': 'SUCCEEDED',
    'operation_outcome': 'APPLIED',
    'commit_deadline': '2026-07-16T10:00:15.000Z',
    'refresh_scope': 'SAVED_ITEMS',
    'applied_resource_versions': <String, Object?>{
      if (saved)
        'relationship': <String, Object?>{
          'generation': _relationshipGeneration,
          'version': version,
        },
    },
    'result_recorded_at': '2026-07-16T10:00:01.000Z',
    'current_resource_snapshot': <String, Object?>{
      'resource_kind': 'SAVED_ITEM',
      'snapshot_version': version,
      'snapshot_recorded_at': '2026-07-16T10:00:01.000Z',
      'target': target.toJson(),
      'saved_state': saved ? 'SAVED' : 'CONFIRMED_UNSAVED',
      'relationship': saved
          ? <String, Object?>{
              'state': 'ACTIVE',
              'generation': _relationshipGeneration,
              'version': version,
            }
          : const <String, Object?>{'state': 'ABSENT'},
      'effective_collection_count': 0,
    },
  };
}

const String _relationshipGeneration = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';

final class _MemorySecureStorage extends SecureStorage {
  _MemorySecureStorage(this.accessToken);

  final String? accessToken;

  @override
  Future<String?> getAccessToken() async => accessToken;
}

final class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter(List<_JsonResponse> responses)
    : _responses = List<_JsonResponse>.of(responses);

  final List<_JsonResponse> _responses;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = _responses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _JsonResponse {
  const _JsonResponse(this.statusCode, this.body);

  final int statusCode;
  final Map<String, Object?> body;
}
