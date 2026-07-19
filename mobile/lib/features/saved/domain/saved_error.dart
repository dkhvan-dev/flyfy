enum SavedErrorCode {
  invalidArgument('INVALID_ARGUMENT'),
  unauthenticated('UNAUTHENTICATED'),
  notFound('NOT_FOUND'),
  targetTypeUnsupported('SAVED_TARGET_TYPE_UNSUPPORTED'),
  targetUnavailable('SAVED_TARGET_UNAVAILABLE'),
  dependencyUnavailable('SAVED_DEPENDENCY_UNAVAILABLE'),
  mutationStale('SAVED_MUTATION_STALE'),
  mutationReplayMismatch('SAVED_MUTATION_REPLAY_MISMATCH'),
  collectionNotFound('SAVED_COLLECTION_NOT_FOUND'),
  collectionDeleted('SAVED_COLLECTION_DELETED'),
  collectionTitleInvalid('SAVED_COLLECTION_TITLE_INVALID'),
  collectionTitleConflict('SAVED_COLLECTION_TITLE_CONFLICT'),
  collectionLimitReached('SAVED_COLLECTION_LIMIT_REACHED'),
  collectionItemLimitReached('SAVED_COLLECTION_ITEM_LIMIT_REACHED'),
  membershipLimitReached('SAVED_MEMBERSHIP_LIMIT_REACHED'),
  itemLimitReached('SAVED_ITEM_LIMIT_REACHED'),
  requestInProgress('SAVED_REQUEST_IN_PROGRESS'),
  operationExpired('SAVED_OPERATION_EXPIRED'),
  cursorInvalid('SAVED_CURSOR_INVALID'),
  rateLimited('SAVED_RATE_LIMITED'),
  temporarilyUnavailable('SAVED_TEMPORARILY_UNAVAILABLE'),
  platformPersonalDataLocked('PLATFORM_PERSONAL_DATA_LOCKED');

  const SavedErrorCode(this.wireValue);

  final String wireValue;

  static SavedErrorCode fromWireValue(Object? value) {
    if (value is! String) {
      throw const FormatException('error code must be a string.');
    }

    for (final code in SavedErrorCode.values) {
      if (code.wireValue == value) {
        return code;
      }
    }
    throw FormatException('Unsupported Saved error code: $value.');
  }
}

final class SavedOperationError {
  SavedOperationError({
    required this.code,
    required this.retryable,
    int? retryAfterMilliseconds,
  }) : retryAfterMilliseconds = _requireRetryAfter(retryAfterMilliseconds);

  factory SavedOperationError.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const <String>{'code', 'retryable'},
      optionalKeys: const <String>{'retry_after_ms'},
    );
    final retryable = json['retryable'];
    if (retryable is! bool) {
      throw const FormatException('operation_error.retryable must be boolean.');
    }
    final retryAfter = json['retry_after_ms'];
    if (json.containsKey('retry_after_ms') && retryAfter is! int) {
      throw const FormatException(
        'operation_error.retry_after_ms must be an integer when present.',
      );
    }

    try {
      return SavedOperationError(
        code: SavedErrorCode.fromWireValue(json['code']),
        retryable: retryable,
        retryAfterMilliseconds: retryAfter as int?,
      );
    } on ArgumentError catch (error) {
      throw FormatException(
        error.message?.toString() ?? 'Invalid operation_error.',
      );
    }
  }

  final SavedErrorCode code;
  final bool retryable;
  final int? retryAfterMilliseconds;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'code': code.wireValue,
      'retryable': retryable,
      if (retryAfterMilliseconds != null)
        'retry_after_ms': retryAfterMilliseconds,
    };
  }
}

final class SavedErrorEnvelope {
  SavedErrorEnvelope({
    required this.code,
    required this.retryable,
    int? retryAfterMilliseconds,
    String? requestId,
  }) : retryAfterMilliseconds = _requireRetryAfter(retryAfterMilliseconds),
       requestId = requestId == null ? null : _requireRequestId(requestId);

  factory SavedErrorEnvelope.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const <String>{'code', 'retryable'},
      optionalKeys: const <String>{'retry_after_ms', 'request_id'},
    );
    final retryable = json['retryable'];
    if (retryable is! bool) {
      throw const FormatException('error.retryable must be boolean.');
    }
    final retryAfter = json['retry_after_ms'];
    if (json.containsKey('retry_after_ms') && retryAfter is! int) {
      throw const FormatException(
        'error.retry_after_ms must be an integer when present.',
      );
    }
    final requestId = json['request_id'];
    if (json.containsKey('request_id') && requestId is! String) {
      throw const FormatException(
        'error.request_id must be a string when present.',
      );
    }

    try {
      return SavedErrorEnvelope(
        code: SavedErrorCode.fromWireValue(json['code']),
        retryable: retryable,
        retryAfterMilliseconds: retryAfter as int?,
        requestId: requestId as String?,
      );
    } on ArgumentError catch (error) {
      throw FormatException(
        error.message?.toString() ?? 'Invalid Saved error envelope.',
      );
    }
  }

  final SavedErrorCode code;
  final bool retryable;
  final int? retryAfterMilliseconds;
  final String? requestId;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'code': code.wireValue,
      'retryable': retryable,
      if (retryAfterMilliseconds != null)
        'retry_after_ms': retryAfterMilliseconds,
      if (requestId != null) 'request_id': requestId,
    };
  }
}

int? _requireRetryAfter(int? value) {
  if (value != null && (value < 0 || value > 86400000)) {
    throw ArgumentError.value(
      value,
      'retryAfterMilliseconds',
      'Must be between 0 and 86400000.',
    );
  }
  return value;
}

String _requireRequestId(String value) {
  final length = value.runes.length;
  if (length < 1 || length > 128) {
    throw ArgumentError.value(
      value,
      'requestId',
      'Must contain between 1 and 128 Unicode code points.',
    );
  }
  return value;
}

void _requireKeys(
  Map<String, dynamic> json, {
  required Set<String> requiredKeys,
  Set<String> optionalKeys = const <String>{},
}) {
  final actualKeys = json.keys.toSet();
  final allowedKeys = <String>{...requiredKeys, ...optionalKeys};
  if (!actualKeys.containsAll(requiredKeys) ||
      !allowedKeys.containsAll(actualKeys)) {
    throw FormatException(
      'Unexpected JSON keys. Required: ${requiredKeys.toList()..sort()}; '
      'optional: ${optionalKeys.toList()..sort()}.',
    );
  }
}
