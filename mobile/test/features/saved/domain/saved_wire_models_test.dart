import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/saved/domain/saved_error.dart';
import 'package:inflap/features/saved/domain/saved_operation.dart';
import 'package:inflap/features/saved/domain/saved_status.dart';
import 'package:inflap/features/saved/domain/saved_target.dart';

void main() {
  final target = SavedTarget(
    entityType: SavedEntityType.attraction,
    entityId: 'attraction/42',
  );

  test('batch status matches the exact nested OpenAPI fixture', () {
    final fixture = <String, dynamic>{
      'statuses': <Object?>[
        <String, Object?>{
          'target': target.toJson(),
          'saved_state': 'SAVED',
          'effective_collection_count': 2,
          'eligibility_hint': 'ELIGIBLE',
          'relationship_generation': _relationshipGeneration,
          'resource_version': 17,
        },
        <String, Object?>{
          'target': <String, Object?>{
            'entity_type': 'GUIDE',
            'entity_id': 'guide-9',
          },
          'saved_state': 'UNKNOWN',
          'effective_collection_count': 0,
          'eligibility_hint': 'UNKNOWN',
          'resource_version': 0,
        },
      ],
    };

    final batch = SavedStatusBatch.fromJson(fixture);

    expect(batch.statuses.first.target, target);
    expect(batch.statuses.first.savedState, SavedConfirmation.saved);
    expect(batch.statuses.first.eligibility, SavedEligibility.eligible);
    expect(
      batch.statuses.first.relationshipGeneration,
      _relationshipGeneration,
    );
    expect(batch.statuses.last.savedState, SavedConfirmation.unknown);
    expect(batch.toJson(), fixture);
  });

  test(
    'batch status rejects obsolete enums, extras, and malformed optionals',
    () {
      final base = <String, dynamic>{
        'target': target.toJson(),
        'saved_state': 'CONFIRMED_UNSAVED',
        'effective_collection_count': 0,
        'eligibility_hint': 'REDUCTION_ONLY',
        'resource_version': 0,
      };

      expect(
        SavedTargetSnapshot.fromJson(base).savedState,
        SavedConfirmation.confirmedUnsaved,
      );
      expect(
        () => SavedTargetSnapshot.fromJson(<String, dynamic>{
          ...base,
          'saved_state': 'UNSAVED',
        }),
        throwsFormatException,
      );
      expect(
        () => SavedTargetSnapshot.fromJson(<String, dynamic>{
          ...base,
          'eligibility_hint': 'ALLOWED',
        }),
        throwsFormatException,
      );
      expect(
        () => SavedTargetSnapshot.fromJson(<String, dynamic>{
          ...base,
          'relationship_generation': 'not-a-uuid',
        }),
        throwsFormatException,
      );
      expect(
        () => SavedTargetSnapshot.fromJson(<String, dynamic>{
          ...base,
          'resource_version': -1,
        }),
        throwsFormatException,
      );
      expect(
        () => SavedTargetSnapshot.fromJson(<String, dynamic>{
          ...base,
          'unexpected': true,
        }),
        throwsFormatException,
      );
    },
  );

  test('operation result maps scalar outcome and typed OpenAPI resources', () {
    final fixture = _operationFixture(target);

    final operation = SavedOperationResult.fromJson(fixture);

    expect(operation.operationKind, SavedOperationKind.saveTarget);
    expect(operation.status, SavedOperationStatus.succeeded);
    expect(operation.outcome, SavedOperationOutcome.applied);
    expect(
      operation.appliedResourceVersions.relationship?.generation,
      _relationshipGeneration,
    );
    expect(operation.appliedResourceVersions.dependentMembershipVersion, 6);
    expect(
      operation.appliedResourceVersions.collection?.collectionId,
      _collectionId,
    );
    expect(operation.currentResourceSnapshot, isA<SavedItemCurrentSnapshot>());
    expect(operation.savedItemSnapshot?.target, target);
    expect(
      operation.savedItemSnapshot?.toTargetSnapshot().eligibility,
      SavedEligibility.unknown,
    );
    expect(operation.toJson(), fixture);
  });

  test('all current snapshot discriminators remain valid wire data', () {
    final targetCollections = _operationFixture(target)
      ..['operation_kind'] = 'SET_TARGET_COLLECTIONS'
      ..['current_resource_snapshot'] = <String, Object?>{
        'resource_kind': 'TARGET_COLLECTIONS',
        'snapshot_version': 18,
        'snapshot_recorded_at': _recordedAt,
        'target': target.toJson(),
        'relationship': <String, Object?>{
          'state': 'ACTIVE',
          'generation': _relationshipGeneration,
          'version': 18,
        },
        'dependent_membership_version': 7,
        'effective_collection_ids': <String>[_collectionId],
      };
    final collection = _operationFixture(target)
      ..['operation_kind'] = 'DELETE_COLLECTION'
      ..['current_resource_snapshot'] = <String, Object?>{
        'resource_kind': 'COLLECTION',
        'snapshot_version': 9,
        'snapshot_recorded_at': _recordedAt,
        'collection_id': _collectionId,
        'lifecycle_state': 'DELETED',
        'metadata_version': 4,
        'lifecycle_version': 5,
      };

    final targetCollectionsResult = SavedOperationResult.fromJson(
      targetCollections,
    );
    final collectionResult = SavedOperationResult.fromJson(collection);

    expect(
      targetCollectionsResult.currentResourceSnapshot,
      isA<TargetCollectionsCurrentSnapshot>(),
    );
    expect(targetCollectionsResult.savedItemSnapshot, isNull);
    expect(
      collectionResult.currentResourceSnapshot,
      isA<CollectionCurrentSnapshot>(),
    );
    expect(collectionResult.savedItemSnapshot, isNull);
  });

  test('operation status/outcome/error combinations are enforced', () {
    final pendingApplied = _operationFixture(target)
      ..['operation_status'] = 'PENDING'
      ..['operation_outcome'] = 'APPLIED';
    final succeededRejected = _operationFixture(target)
      ..['operation_status'] = 'SUCCEEDED'
      ..['operation_outcome'] = 'REJECTED'
      ..['operation_error'] = <String, Object?>{
        'code': 'SAVED_MUTATION_STALE',
        'retryable': false,
      };
    final rejectedWithoutError = _operationFixture(target)
      ..['operation_status'] = 'REJECTED'
      ..['operation_outcome'] = 'REJECTED';
    final expiredWithError = _operationFixture(target)
      ..['operation_status'] = 'EXPIRED'
      ..['operation_outcome'] = 'EXPIRED'
      ..['operation_error'] = <String, Object?>{
        'code': 'SAVED_OPERATION_EXPIRED',
        'retryable': false,
      };

    for (final invalid in <Map<String, dynamic>>[
      pendingApplied,
      succeededRejected,
      rejectedWithoutError,
      expiredWithError,
    ]) {
      expect(
        () => SavedOperationResult.fromJson(invalid),
        throwsFormatException,
      );
    }

    final rejected = _operationFixture(target)
      ..['operation_status'] = 'REJECTED'
      ..['operation_outcome'] = 'REJECTED'
      ..['operation_error'] = <String, Object?>{
        'code': 'SAVED_TARGET_UNAVAILABLE',
        'retryable': false,
      };
    final parsed = SavedOperationResult.fromJson(rejected);
    expect(parsed.operationError?.code, SavedErrorCode.targetUnavailable);
  });

  test('operation models reject extra and malformed nested keys', () {
    expect(
      () => SavedOperationResult.fromJson(
        _operationFixture(target)..['unexpected'] = true,
      ),
      throwsFormatException,
    );
    final malformedVersions = _operationFixture(target);
    malformedVersions['applied_resource_versions'] = <String, Object?>{
      'relationship': <String, Object?>{
        'generation': _relationshipGeneration,
        'version': 0,
      },
    };
    expect(
      () => SavedOperationResult.fromJson(malformedVersions),
      throwsFormatException,
    );
    final extendedSnapshot = _operationFixture(target);
    final snapshot = Map<String, Object?>.from(
      extendedSnapshot['current_resource_snapshot']! as Map<String, Object?>,
    )..['eligibility_hint'] = 'ELIGIBLE';
    extendedSnapshot['current_resource_snapshot'] = snapshot;
    expect(
      () => SavedOperationResult.fromJson(extendedSnapshot),
      throwsFormatException,
    );
  });

  test('stable error envelope parses exact fields and rejects extensions', () {
    final envelope = SavedErrorEnvelope.fromJson(const <String, dynamic>{
      'code': 'SAVED_REQUEST_IN_PROGRESS',
      'retryable': true,
      'retry_after_ms': 250,
      'request_id': 'request-1',
    });

    expect(envelope.code, SavedErrorCode.requestInProgress);
    expect(envelope.retryAfterMilliseconds, 250);
    expect(envelope.toJson(), const <String, Object?>{
      'code': 'SAVED_REQUEST_IN_PROGRESS',
      'retryable': true,
      'retry_after_ms': 250,
      'request_id': 'request-1',
    });
    expect(
      () => SavedErrorEnvelope.fromJson(const <String, dynamic>{
        'code': 'SAVED_RATE_LIMITED',
        'retryable': true,
        'detail': 'not stable contract data',
      }),
      throwsFormatException,
    );
  });

  test('secure factory emits UUIDv4 and independent 256-bit key', () {
    final identity = SecureSavedOperationIdentityFactory().create();
    final paddedKey = identity.idempotencyKey.padRight(
      (identity.idempotencyKey.length + 3) ~/ 4 * 4,
      '=',
    );

    expect(
      identity.operationId,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(base64Url.decode(paddedKey), hasLength(32));
    expect(identity.idempotencyKey, isNot(identity.operationId));
  });

  test('idempotency keys enforce the OpenAPI 22 through 128 bound', () {
    final operationId = '11111111-2222-4333-8444-555555555555';
    final minimumKey = base64UrlEncode(
      List<int>.filled(16, 1),
    ).replaceAll('=', '');

    expect(minimumKey, hasLength(22));
    expect(
      SavedOperationIdentity(
        operationId: operationId,
        idempotencyKey: minimumKey,
      ).idempotencyKey,
      minimumKey,
    );
    expect(
      () => SavedOperationIdentity(
        operationId: operationId,
        idempotencyKey: List<String>.filled(21, 'A').join(),
      ),
      throwsArgumentError,
    );
    expect(
      () => SavedOperationIdentity(
        operationId: operationId,
        idempotencyKey: List<String>.filled(129, 'A').join(),
      ),
      throwsArgumentError,
    );
  });
}

const String _relationshipGeneration = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
const String _collectionId = '22222222-3333-4444-8555-666666666666';
const String _recordedAt = '2026-07-16T10:00:01.000Z';

Map<String, dynamic> _operationFixture(SavedTarget target) {
  return <String, dynamic>{
    'operation_id': '11111111-2222-4333-8444-555555555555',
    'operation_kind': 'SAVE_TARGET',
    'operation_status': 'SUCCEEDED',
    'operation_outcome': 'APPLIED',
    'commit_deadline': '2026-07-16T10:00:15.000Z',
    'refresh_scope': 'SAVED_ITEMS',
    'applied_resource_versions': <String, Object?>{
      'relationship': <String, Object?>{
        'generation': _relationshipGeneration,
        'version': 17,
      },
      'dependent_membership_version': 6,
      'collection': <String, Object?>{
        'collection_id': _collectionId,
        'metadata_version': 3,
        'lifecycle_version': 4,
      },
    },
    'result_recorded_at': _recordedAt,
    'current_resource_snapshot': <String, Object?>{
      'resource_kind': 'SAVED_ITEM',
      'snapshot_version': 17,
      'snapshot_recorded_at': _recordedAt,
      'target': target.toJson(),
      'saved_state': 'SAVED',
      'relationship': <String, Object?>{
        'state': 'ACTIVE',
        'generation': _relationshipGeneration,
        'version': 17,
      },
      'effective_collection_count': 2,
    },
  };
}
