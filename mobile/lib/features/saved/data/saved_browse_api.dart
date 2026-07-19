import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/saved_browse_models.dart';
import '../domain/saved_error.dart';
import '../domain/saved_operation.dart';
import '../domain/saved_target.dart';
import 'saved_api.dart';

abstract interface class SavedBrowseApiClient {
  Future<SavedCapabilities> getCapabilities({CancelToken? cancelToken});

  Future<SavedPage<SavedListItem>> listItems({
    SavedEntityType? entityType,
    String? collectionId,
    bool uncollected = false,
    String? cursor,
    int limit = 30,
    CancelToken? cancelToken,
  });

  Future<SavedPage<SavedSearchItem>> searchItems({
    required String search,
    SavedEntityType? entityType,
    String? collectionId,
    bool uncollected = false,
    String? cursor,
    int limit = 30,
    CancelToken? cancelToken,
  });

  Future<SavedCollectionsList> listCollections({CancelToken? cancelToken});

  Future<SavedCollectionDetail> getCollection(
    String collectionId, {
    CancelToken? cancelToken,
  });

  Future<SavedTargetCollectionsSnapshot> getTargetCollections(
    SavedTarget target, {
    CancelToken? cancelToken,
  });

  Future<SavedOperationResult> replaceTargetCollections({
    required SavedTargetCollectionsSnapshot current,
    required Iterable<String> desiredCollectionIds,
    SavedNewCollection? newCollection,
    required SavedOperationIdentity identity,
    required SavedSourceSurface sourceSurface,
  });

  Future<SavedOperationResult> createCollection({
    required SavedNewCollection collection,
    required SavedOperationIdentity identity,
    required SavedSourceSurface sourceSurface,
  });

  Future<SavedOperationResult> renameCollection({
    required SavedCollectionRecord collection,
    required String title,
    required SavedOperationIdentity identity,
    required SavedSourceSurface sourceSurface,
  });

  Future<SavedOperationResult> deleteCollection({
    required SavedCollectionRecord collection,
    required SavedOperationIdentity identity,
    required SavedSourceSurface sourceSurface,
  });

  Future<SavedOperationResult> getOperation(String operationId);
}

final class SavedBrowseApi implements SavedBrowseApiClient {
  SavedBrowseApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static const int defaultPageLimit = 30;
  static const int maxPageLimit = 100;

  final ApiClient _apiClient;

  @override
  Future<SavedCapabilities> getCapabilities({CancelToken? cancelToken}) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/users/me/saved-items/capabilities',
        cancelToken: cancelToken,
        options: _readOptions,
      );
      return SavedCapabilities.fromJson(_requireBody(response.data));
    } on DioException catch (error) {
      throw SavedApiException.fromDio(error);
    }
  }

  @override
  Future<SavedPage<SavedListItem>> listItems({
    SavedEntityType? entityType,
    String? collectionId,
    bool uncollected = false,
    String? cursor,
    int limit = defaultPageLimit,
    CancelToken? cancelToken,
  }) async {
    _validateFilters(
      collectionId: collectionId,
      uncollected: uncollected,
      cursor: cursor,
      limit: limit,
    );
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/users/me/saved-items',
        queryParameters: _queryParameters(
          entityType: entityType,
          collectionId: collectionId,
          uncollected: uncollected,
          cursor: cursor,
          limit: limit,
        ),
        cancelToken: cancelToken,
        options: _readOptions,
      );
      return parseSavedItemsPage(_requireBody(response.data));
    } on DioException catch (error) {
      throw SavedApiException.fromDio(error);
    }
  }

  @override
  Future<SavedPage<SavedSearchItem>> searchItems({
    required String search,
    SavedEntityType? entityType,
    String? collectionId,
    bool uncollected = false,
    String? cursor,
    int limit = defaultPageLimit,
    CancelToken? cancelToken,
  }) async {
    _validateSearch(search);
    _validateFilters(
      collectionId: collectionId,
      uncollected: uncollected,
      cursor: cursor,
      limit: limit,
    );
    final body = <String, Object?>{
      if (entityType != null) 'type': entityType.wireValue,
      'collection_id': ?collectionId,
      if (uncollected) 'uncollected': true,
      'search': search,
      'cursor': ?cursor,
      'limit': limit,
    };
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/users/me/saved-items/query',
        data: body,
        cancelToken: cancelToken,
        options: _readOptions,
      );
      return parseSavedSearchPage(_requireBody(response.data));
    } on DioException catch (error) {
      throw SavedApiException.fromDio(error);
    }
  }

  @override
  Future<SavedCollectionsList> listCollections({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/users/me/saved-collections',
        cancelToken: cancelToken,
        options: _readOptions,
      );
      return SavedCollectionsList.fromJson(_requireBody(response.data));
    } on DioException catch (error) {
      throw SavedApiException.fromDio(error);
    }
  }

  @override
  Future<SavedCollectionDetail> getCollection(
    String collectionId, {
    CancelToken? cancelToken,
  }) async {
    final encodedId = Uri.encodeComponent(_validateUuid(collectionId));
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/users/me/saved-collections/$encodedId',
        cancelToken: cancelToken,
        options: _readOptions,
      );
      final detail = SavedCollectionDetail.fromJson(
        _requireBody(response.data),
      );
      if (detail.collection.collectionId != collectionId) {
        throw const FormatException(
          'Saved collection response does not match the requested collection.',
        );
      }
      return detail;
    } on DioException catch (error) {
      throw SavedApiException.fromDio(error);
    }
  }

  @override
  Future<SavedTargetCollectionsSnapshot> getTargetCollections(
    SavedTarget target, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '${_targetPath(target)}/collections',
        cancelToken: cancelToken,
        options: _readOptions,
      );
      final snapshot = SavedTargetCollectionsSnapshot.fromJson(
        _requireBody(response.data),
      );
      if (snapshot.target != target) {
        throw const FormatException(
          'Collection assignment response does not match the requested target.',
        );
      }
      return snapshot;
    } on DioException catch (error) {
      throw SavedApiException.fromDio(error);
    }
  }

  @override
  Future<SavedOperationResult> replaceTargetCollections({
    required SavedTargetCollectionsSnapshot current,
    required Iterable<String> desiredCollectionIds,
    SavedNewCollection? newCollection,
    required SavedOperationIdentity identity,
    required SavedSourceSurface sourceSurface,
  }) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '${_targetPath(current.target)}/collections',
        data: current.desiredSetJson(
          desiredCollectionIds: desiredCollectionIds,
          newCollection: newCollection,
        ),
        options: _mutationOptions(identity, sourceSurface),
      );
      return _parseMutation(
        response,
        identity: identity,
        expectedKind: SavedOperationKind.setTargetCollections,
        expectedTarget: current.target,
      );
    } on DioException catch (error) {
      throw SavedApiException.fromDio(error);
    }
  }

  @override
  Future<SavedOperationResult> createCollection({
    required SavedNewCollection collection,
    required SavedOperationIdentity identity,
    required SavedSourceSurface sourceSurface,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/users/me/saved-collections',
        data: collection.toJson(),
        options: _mutationOptions(identity, sourceSurface),
      );
      return _parseMutation(
        response,
        identity: identity,
        expectedKind: SavedOperationKind.createCollection,
      );
    } on DioException catch (error) {
      throw SavedApiException.fromDio(error);
    }
  }

  @override
  Future<SavedOperationResult> renameCollection({
    required SavedCollectionRecord collection,
    required String title,
    required SavedOperationIdentity identity,
    required SavedSourceSurface sourceSurface,
  }) async {
    _validateTitle(title);
    try {
      final response = await _apiClient.dio.patch<Map<String, dynamic>>(
        '/users/me/saved-collections/${Uri.encodeComponent(collection.collectionId)}',
        data: <String, Object?>{
          'expected_metadata_version': collection.metadataVersion,
          'title': title,
        },
        options: _mutationOptions(identity, sourceSurface),
      );
      return _parseMutation(
        response,
        identity: identity,
        expectedKind: SavedOperationKind.renameCollection,
        expectedCollectionId: collection.collectionId,
      );
    } on DioException catch (error) {
      throw SavedApiException.fromDio(error);
    }
  }

  @override
  Future<SavedOperationResult> deleteCollection({
    required SavedCollectionRecord collection,
    required SavedOperationIdentity identity,
    required SavedSourceSurface sourceSurface,
  }) async {
    try {
      final response = await _apiClient.dio.delete<Map<String, dynamic>>(
        '/users/me/saved-collections/${Uri.encodeComponent(collection.collectionId)}',
        data: <String, Object?>{
          'expected_metadata_version': collection.metadataVersion,
          'expected_lifecycle_version': collection.lifecycleVersion,
        },
        options: _mutationOptions(identity, sourceSurface),
      );
      return _parseMutation(
        response,
        identity: identity,
        expectedKind: SavedOperationKind.deleteCollection,
        expectedCollectionId: collection.collectionId,
      );
    } on DioException catch (error) {
      throw SavedApiException.fromDio(error);
    }
  }

  @override
  Future<SavedOperationResult> getOperation(String operationId) async {
    validateSavedOperationId(operationId);
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/users/me/saved-operations/${Uri.encodeComponent(operationId)}',
        options: _readOptions,
      );
      final result = SavedOperationResult.fromJson(_requireBody(response.data));
      if (result.operationId != operationId) {
        throw const FormatException(
          'Saved operation response does not match the requested operation.',
        );
      }
      return result;
    } on DioException catch (error) {
      final apiError = SavedApiException.fromDio(error);
      if (apiError.statusCode == 404 &&
          apiError.error?.code == SavedErrorCode.notFound) {
        throw SavedOperationNotFoundException(operationId);
      }
      throw apiError;
    }
  }

  Options get _readOptions =>
      Options(extra: const <String, dynamic>{'requiresAuth': true});

  Options _mutationOptions(
    SavedOperationIdentity identity,
    SavedSourceSurface sourceSurface,
  ) {
    return Options(
      extra: const <String, dynamic>{'requiresAuth': true},
      headers: <String, String>{
        'Operation-Id': identity.operationId,
        'Idempotency-Key': identity.idempotencyKey,
        'Saved-Source-Surface': sourceSurface.wireValue,
      },
    );
  }

  SavedOperationResult _parseMutation(
    Response<Map<String, dynamic>> response, {
    required SavedOperationIdentity identity,
    required SavedOperationKind expectedKind,
    SavedTarget? expectedTarget,
    String? expectedCollectionId,
  }) {
    final result = SavedOperationResult.fromJson(_requireBody(response.data));
    final validStatus = switch (response.statusCode) {
      200 => result.status.isTerminal,
      202 => result.status == SavedOperationStatus.pending,
      _ => false,
    };
    if (!validStatus ||
        result.operationId != identity.operationId ||
        result.operationKind != expectedKind) {
      throw const FormatException(
        'Saved mutation response does not match the accepted request.',
      );
    }
    final snapshot = result.currentResourceSnapshot;
    if (expectedTarget != null &&
        snapshot is TargetCollectionsCurrentSnapshot &&
        snapshot.target != expectedTarget) {
      throw const FormatException(
        'Saved assignment result belongs to a different target.',
      );
    }
    if (expectedCollectionId != null &&
        snapshot is CollectionCurrentSnapshot &&
        snapshot.collectionId != expectedCollectionId) {
      throw const FormatException(
        'Saved collection result belongs to a different collection.',
      );
    }
    return result;
  }

  String _targetPath(SavedTarget target) {
    return '/users/me/saved-items/'
        '${Uri.encodeComponent(target.entityType.wireValue)}/'
        '${Uri.encodeComponent(target.entityId)}';
  }

  Map<String, Object?> _queryParameters({
    required SavedEntityType? entityType,
    required String? collectionId,
    required bool uncollected,
    required String? cursor,
    required int limit,
  }) {
    return <String, Object?>{
      if (entityType != null) 'type': entityType.wireValue,
      'collection_id': ?collectionId,
      if (uncollected) 'uncollected': true,
      'cursor': ?cursor,
      'limit': limit,
    };
  }

  void _validateFilters({
    required String? collectionId,
    required bool uncollected,
    required String? cursor,
    required int limit,
  }) {
    if (collectionId != null && uncollected) {
      throw ArgumentError(
        'collectionId and uncollected are mutually exclusive.',
      );
    }
    if (collectionId != null) _validateUuid(collectionId);
    if (cursor != null && (cursor.isEmpty || cursor.length > 4096)) {
      throw ArgumentError.value(cursor, 'cursor');
    }
    if (limit < 1 || limit > maxPageLimit) {
      throw RangeError.range(limit, 1, maxPageLimit, 'limit');
    }
  }

  Map<String, dynamic> _requireBody(Map<String, dynamic>? body) {
    if (body == null) {
      throw const FormatException('Saved API response body must be an object.');
    }
    return body;
  }
}

void _validateSearch(String value) {
  if (value.runes.isEmpty || value.runes.length > 200 || value.trim().isEmpty) {
    throw ArgumentError.value(
      value,
      'search',
      'Must contain 1-200 code points.',
    );
  }
  if (value.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
    throw ArgumentError.value(
      value,
      'search',
      'Control characters are forbidden.',
    );
  }
}

void _validateTitle(String value) {
  if (value.runes.isEmpty || value.runes.length > 80 || value.trim().isEmpty) {
    throw ArgumentError.value(value, 'title', 'Must contain 1-80 code points.');
  }
  if (value.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
    throw ArgumentError.value(
      value,
      'title',
      'Control characters are forbidden.',
    );
  }
}

String _validateUuid(String value) {
  final uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  if (!uuid.hasMatch(value)) {
    throw ArgumentError.value(value, 'collectionId', 'Must be a UUID.');
  }
  return value;
}
