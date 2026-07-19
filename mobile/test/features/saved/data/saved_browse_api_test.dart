import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/saved/data/saved_browse_api.dart';
import 'package:inflap/features/saved/domain/saved_browse_models.dart';
import 'package:inflap/features/saved/domain/saved_operation.dart';
import 'package:inflap/features/saved/domain/saved_target.dart';

import '../domain/saved_browse_models_test.dart' show savedItemJson;
import '../support/saved_test_fakes.dart'
    show collectionA, savedCollection, targetCollections;

void main() {
  test(
    'browse endpoints preserve exact filters, search body, and auth',
    () async {
      final adapter = _QueueAdapter([
        _JsonResponse(200, _capabilitiesBody),
        _JsonResponse(200, <String, Object?>{
          'items': [
            savedItemJson(id: 'activity-1', savedAt: '2026-07-16T10:00:00Z'),
          ],
          'next_cursor': null,
          'has_more': false,
        }),
        _JsonResponse(200, <String, Object?>{
          'items': [
            <String, Object?>{
              ...savedItemJson(
                id: 'activity-1',
                savedAt: '2026-07-16T10:00:00Z',
              ),
              'match': const <String, Object?>{
                'match_rank': 0,
                'match_kind': 'EXACT',
                'matched_field': 'TITLE',
                'matched_locale': 'en',
              },
            },
          ],
          'next_cursor': null,
          'has_more': false,
        }),
      ]);
      final api = _apiWith(adapter);

      final capabilities = await api.getCapabilities();
      final page = await api.listItems(
        entityType: SavedEntityType.activity,
        collectionId: collectionA,
        limit: 30,
      );
      final search = await api.searchItems(
        search: 'mountain',
        entityType: SavedEntityType.activity,
        collectionId: collectionA,
        limit: 30,
      );

      expect(capabilities.productFlags.savedItemsEnabled, isTrue);
      expect(page.items.single.target.entityId, 'activity-1');
      expect(search.items.single.match.matchKind, SavedSearchMatchKind.exact);
      expect(
        adapter.requests[0].uri.path,
        '/api/v1/users/me/saved-items/capabilities',
      );
      expect(adapter.requests[1].uri.queryParameters, <String, String>{
        'type': 'ACTIVITY',
        'collection_id': collectionA,
        'limit': '30',
      });
      expect(adapter.requests[2].data, <String, Object?>{
        'type': 'ACTIVITY',
        'collection_id': collectionA,
        'search': 'mountain',
        'limit': 30,
      });
      for (final request in adapter.requests) {
        expect(request.headers['Authorization'], 'Bearer access-token');
      }
    },
  );

  test(
    'assignment and collection CRUD use exact versioned mutation contracts',
    () async {
      final target = SavedTarget(
        entityType: SavedEntityType.activity,
        entityId: 'activity-1',
      );
      final current = targetCollections(target);
      final collection = savedCollection();
      final identities = List.generate(
        4,
        (index) => SavedOperationIdentity(
          operationId: '11111111-2222-4${index + 1}33-8444-555555555555',
          idempotencyKey: base64Url
              .encode(List<int>.filled(32, index))
              .replaceAll('=', ''),
        ),
      );
      final adapter = _QueueAdapter([
        for (var index = 0; index < 4; index++)
          _JsonResponse(
            200,
            _operationBody(
              identities[index].operationId,
              [
                'SET_TARGET_COLLECTIONS',
                'CREATE_COLLECTION',
                'RENAME_COLLECTION',
                'DELETE_COLLECTION',
              ][index],
            ),
          ),
      ]);
      final api = _apiWith(adapter);

      await api.replaceTargetCollections(
        current: current,
        desiredCollectionIds: const [],
        newCollection: SavedNewCollection(
          clientCreationId: 'bbbbbbbb-cccc-4ddd-8eee-ffffffffffff',
          title: 'Fresh collection',
        ),
        identity: identities[0],
        sourceSurface: SavedSourceSurface.savedCollection,
      );
      await api.createCollection(
        collection: SavedNewCollection(
          clientCreationId: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
          title: 'Weekend',
        ),
        identity: identities[1],
        sourceSurface: SavedSourceSurface.savedAll,
      );
      await api.renameCollection(
        collection: collection,
        title: 'Renamed',
        identity: identities[2],
        sourceSurface: SavedSourceSurface.savedCollection,
      );
      await api.deleteCollection(
        collection: collection,
        identity: identities[3],
        sourceSurface: SavedSourceSurface.savedCollection,
      );

      expect(adapter.requests.map((request) => request.method), [
        'PUT',
        'POST',
        'PATCH',
        'DELETE',
      ]);
      expect(adapter.requests[0].data, <String, Object?>{
        'expected_relationship': <String, Object?>{
          'state': 'EXPECTED_ACTIVE',
          'generation': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          'version': 1,
        },
        'expected_dependent_membership_version': 1,
        'desired_collection_ids': <String>[],
        'new_collection': <String, Object?>{
          'client_creation_id': 'bbbbbbbb-cccc-4ddd-8eee-ffffffffffff',
          'title': 'Fresh collection',
        },
      });
      expect(adapter.requests[1].data, <String, Object?>{
        'client_creation_id': 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
        'title': 'Weekend',
      });
      expect(adapter.requests[2].data, <String, Object?>{
        'expected_metadata_version': 1,
        'title': 'Renamed',
      });
      expect(adapter.requests[3].data, <String, Object?>{
        'expected_metadata_version': 1,
        'expected_lifecycle_version': 1,
      });
      for (var index = 0; index < adapter.requests.length; index++) {
        expect(
          adapter.requests[index].headers['Operation-Id'],
          identities[index].operationId,
        );
        expect(
          adapter.requests[index].headers['Idempotency-Key'],
          identities[index].idempotencyKey,
        );
      }
    },
  );
}

SavedBrowseApi _apiWith(_QueueAdapter adapter) {
  return SavedBrowseApi(
    apiClient: ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
        ..httpClientAdapter = adapter,
      secureStorage: _MemorySecureStorage(),
    ),
  );
}

Map<String, Object?> _operationBody(String operationId, String kind) {
  return <String, Object?>{
    'operation_id': operationId,
    'operation_kind': kind,
    'operation_status': 'SUCCEEDED',
    'operation_outcome': 'APPLIED',
    'commit_deadline': '2026-07-16T10:00:15Z',
    'refresh_scope': 'BOTH',
    'applied_resource_versions': const <String, Object?>{},
    'result_recorded_at': '2026-07-16T10:00:01Z',
  };
}

const _capabilitiesBody = <String, Object?>{
  'capability_revision': 'revision-1',
  'product_flags': <String, Object?>{
    'saved_items_enabled': true,
    'search_enabled': true,
    'collections_enabled': true,
  },
  'has_confirmed_saved_data': true,
  'supported_entity_types': <Object?>['ATTRACTION', 'ACTIVITY', 'USER'],
  'effective_locale': 'en',
};

final class _MemorySecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';
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
      headers: const <String, List<String>>{
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
