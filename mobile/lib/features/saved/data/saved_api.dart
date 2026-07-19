import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/saved_error.dart';
import '../domain/saved_operation.dart';
import '../domain/saved_status.dart';
import '../domain/saved_target.dart';

abstract interface class SavedApiClient {
  Future<SavedOperationResult> putSavedItem({
    required SavedTarget target,
    required SavedOperationIdentity identity,
    SavedSourceSurface sourceSurface = SavedSourceSurface.unknown,
  });

  Future<SavedOperationResult> deleteSavedItem({
    required SavedTarget target,
    required SavedOperationIdentity identity,
    SavedSourceSurface sourceSurface = SavedSourceSurface.unknown,
  });

  Future<List<SavedTargetSnapshot>> getStatuses(Iterable<SavedTarget> targets);

  Future<SavedOperationResult> getOperation(String operationId);
}

final class SavedApi implements SavedApiClient {
  SavedApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static const int maxBatchSize = 100;

  final ApiClient _apiClient;

  @override
  Future<SavedOperationResult> putSavedItem({
    required SavedTarget target,
    required SavedOperationIdentity identity,
    SavedSourceSurface sourceSurface = SavedSourceSurface.unknown,
  }) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        _targetPath(target),
        options: _mutationOptions(identity, sourceSurface),
      );
      return _parseMutationResult(
        response.data,
        httpStatusCode: response.statusCode,
        expectedTarget: target,
        expectedOperationId: identity.operationId,
        expectedOperationKind: SavedOperationKind.saveTarget,
      );
    } on DioException catch (error) {
      throw SavedApiException.fromDio(error);
    }
  }

  @override
  Future<SavedOperationResult> deleteSavedItem({
    required SavedTarget target,
    required SavedOperationIdentity identity,
    SavedSourceSurface sourceSurface = SavedSourceSurface.unknown,
  }) async {
    try {
      final response = await _apiClient.dio.delete<Map<String, dynamic>>(
        _targetPath(target),
        options: _mutationOptions(identity, sourceSurface),
      );
      return _parseMutationResult(
        response.data,
        httpStatusCode: response.statusCode,
        expectedTarget: target,
        expectedOperationId: identity.operationId,
        expectedOperationKind: SavedOperationKind.unsaveTarget,
      );
    } on DioException catch (error) {
      throw SavedApiException.fromDio(error);
    }
  }

  @override
  Future<List<SavedTargetSnapshot>> getStatuses(
    Iterable<SavedTarget> targets,
  ) async {
    final requestedTargets = List<SavedTarget>.unmodifiable(targets);
    if (requestedTargets.isEmpty) {
      return const <SavedTargetSnapshot>[];
    }
    if (requestedTargets.length > maxBatchSize) {
      throw RangeError.range(
        requestedTargets.length,
        1,
        maxBatchSize,
        'targets.length',
      );
    }

    final requestedSet = requestedTargets.toSet();
    if (requestedSet.length != requestedTargets.length) {
      throw ArgumentError.value(
        requestedTargets,
        'targets',
        'Duplicate Saved targets are not allowed.',
      );
    }

    late final SavedStatusBatch batch;
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/users/me/saved-items/status:batch',
        data: <String, Object?>{
          'targets': requestedTargets
              .map((target) => target.toJson())
              .toList(growable: false),
        },
        options: Options(extra: const <String, dynamic>{'requiresAuth': true}),
      );
      batch = SavedStatusBatch.fromJson(_requireBody(response.data));
    } on DioException catch (error) {
      throw SavedApiException.fromDio(error);
    }
    final returnedSet = batch.statuses.map((status) => status.target).toSet();
    if (returnedSet.length != requestedSet.length ||
        !returnedSet.containsAll(requestedSet)) {
      throw const FormatException(
        'Saved status response must contain every requested target exactly once.',
      );
    }
    return batch.statuses;
  }

  @override
  Future<SavedOperationResult> getOperation(String operationId) async {
    validateSavedOperationId(operationId);
    final encodedOperationId = Uri.encodeComponent(operationId);
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/users/me/saved-operations/$encodedOperationId',
        options: Options(extra: const <String, dynamic>{'requiresAuth': true}),
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

  String _targetPath(SavedTarget target) {
    final encodedType = Uri.encodeComponent(target.entityType.wireValue);
    final encodedKey = Uri.encodeComponent(target.entityId);
    return '/users/me/saved-items/$encodedType/$encodedKey';
  }

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

  SavedOperationResult _parseMutationResult(
    Map<String, dynamic>? body, {
    required int? httpStatusCode,
    required SavedTarget expectedTarget,
    required String expectedOperationId,
    required SavedOperationKind expectedOperationKind,
  }) {
    final result = SavedOperationResult.fromJson(_requireBody(body));
    final responseSemanticsAreValid = switch (httpStatusCode) {
      200 => result.status.isTerminal,
      202 => result.status == SavedOperationStatus.pending,
      _ => false,
    };
    if (!responseSemanticsAreValid) {
      throw const FormatException(
        'Saved mutation HTTP status does not match operation_status.',
      );
    }
    if (result.operationId != expectedOperationId) {
      throw const FormatException(
        'Saved mutation response contains a different operation_id.',
      );
    }
    if (result.operationKind != expectedOperationKind) {
      throw const FormatException(
        'Saved mutation response contains a different operation_kind.',
      );
    }
    final snapshot = result.savedItemSnapshot;
    if (snapshot != null && snapshot.target != expectedTarget) {
      throw const FormatException(
        'Saved mutation response contains a snapshot for another target.',
      );
    }
    return result;
  }

  Map<String, dynamic> _requireBody(Map<String, dynamic>? body) {
    if (body == null) {
      throw const FormatException('Saved API response body must be an object.');
    }
    return body;
  }
}

final class SavedApiException implements Exception {
  SavedApiException._({
    required this.cause,
    required this.error,
    required this.errorEnvelopeFormatException,
  });

  factory SavedApiException.fromDio(DioException cause) {
    SavedErrorEnvelope? envelope;
    FormatException? formatException;
    if (cause.response != null) {
      try {
        envelope = SavedErrorEnvelope.fromJson(
          _requireErrorBody(cause.response?.data),
        );
      } on FormatException catch (error) {
        formatException = error;
      }
    }
    return SavedApiException._(
      cause: cause,
      error: envelope,
      errorEnvelopeFormatException: formatException,
    );
  }

  final DioException cause;
  final SavedErrorEnvelope? error;
  final FormatException? errorEnvelopeFormatException;

  int? get statusCode => cause.response?.statusCode;

  @override
  String toString() {
    final code = error?.code.wireValue ?? 'UNPARSEABLE_ERROR';
    return 'SavedApiException(${statusCode ?? cause.type.name}, $code)';
  }
}

Map<String, dynamic> _requireErrorBody(Object? value) {
  if (value is! Map<dynamic, dynamic> ||
      value.keys.any((key) => key is! String)) {
    throw const FormatException(
      'Saved error response must be an object with string keys.',
    );
  }
  return Map<String, dynamic>.from(value);
}

final class SavedOperationNotFoundException implements Exception {
  const SavedOperationNotFoundException(this.operationId);

  final String operationId;

  @override
  String toString() => 'Saved operation was not found.';
}
