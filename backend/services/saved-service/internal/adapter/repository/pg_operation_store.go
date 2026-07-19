package repository

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"fmt"
	"hash"
	"math"
	"sort"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	operationapp "kz/inflap/backend/services/saved-service/internal/app/operation"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

var (
	ErrInvalidOperationStoreDependencies = errors.New("invalid PostgreSQL operation store dependencies")
	ErrOperationStoreUnavailable         = errors.New("PostgreSQL operation store unavailable")
)

const maxPendingOperationsPerSubject = 32

const operationColumns = `
    subject,
    session_generation::text,
    operation_id::text,
    operation_kind,
    idempotency_key,
    semantic_request_hmac,
    request_hmac_key_version,
    first_seen_source_surface,
    accepted_platform_access_policy_revision,
    status,
    commit_deadline,
    outcome_code,
    outcome_retryable,
    refresh_scope,
    observed_relationship_version,
    observed_dependent_membership_version,
    observed_collection_metadata_version,
    observed_collection_lifecycle_version,
    applied_relationship_generation::text,
    applied_relationship_version,
    applied_user_usage_version,
    applied_dependent_membership_version,
    applied_collection_id::text,
    applied_collection_metadata_version,
    applied_collection_lifecycle_version,
    created_at,
    completed_at,
    retention_expires_at`

const findOperationSQL = `
SELECT ` + operationColumns + `
FROM saved_operations
WHERE subject = $1
  AND session_generation = $2
  AND (operation_id = $3 OR idempotency_key = $4)
ORDER BY (operation_id = $3) DESC, created_at ASC, operation_id ASC
LIMIT 1`

const insertPendingOperationSQL = `
INSERT INTO saved_operations (
    subject,
    session_generation,
    operation_id,
    operation_kind,
    idempotency_key,
    semantic_request_hmac,
    request_hmac_key_version,
    first_seen_source_surface,
    accepted_platform_access_policy_revision,
    status,
    commit_deadline,
    outcome_code,
    outcome_retryable,
    refresh_scope,
    observed_relationship_version,
    observed_dependent_membership_version,
    observed_collection_metadata_version,
    observed_collection_lifecycle_version,
    applied_relationship_generation,
    applied_relationship_version,
    applied_user_usage_version,
    applied_dependent_membership_version,
    applied_collection_id,
    applied_collection_metadata_version,
    applied_collection_lifecycle_version,
    created_at,
    completed_at,
    retention_expires_at
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9,
    $10, $11, NULL, NULL, $12,
    NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL,
    NULL, NULL, NULL,
    $13, NULL, NULL
)
ON CONFLICT DO NOTHING
RETURNING ` + operationColumns

const countLivePendingOperationsForSubjectSQL = `
SELECT count(*)::bigint
FROM saved_operations
WHERE subject = $1
  AND status = 'PENDING'
  AND commit_deadline > $2::timestamptz`

// PGOperationStore persists bounded, payload-free idempotency receipts.
type PGOperationStore struct {
	pool                 *pgxpool.Pool
	maxPendingPerSubject int
}

var _ operationapp.OperationStore = (*PGOperationStore)(nil)

func NewPGOperationStore(pool *pgxpool.Pool, maxPendingPerSubject int) (*PGOperationStore, error) {
	if pool == nil || maxPendingPerSubject < 1 || maxPendingPerSubject > maxPendingOperationsPerSubject {
		return nil, ErrInvalidOperationStoreDependencies
	}
	return &PGOperationStore{pool: pool, maxPendingPerSubject: maxPendingPerSubject}, nil
}

func (s *PGOperationStore) CreateOrFind(
	ctx context.Context,
	pending *domain.SavedOperation,
) (operationapp.CreateOrFindResult, error) {
	if err := ctx.Err(); err != nil {
		return operationapp.CreateOrFindResult{}, err
	}
	if s == nil || s.pool == nil || s.maxPendingPerSubject < 1 ||
		s.maxPendingPerSubject > maxPendingOperationsPerSubject {
		return operationapp.CreateOrFindResult{}, ErrInvalidOperationStoreDependencies
	}

	state, err := validatePendingOperation(pending)
	if err != nil {
		return operationapp.CreateOrFindResult{}, err
	}

	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{
		IsoLevel:   pgx.ReadCommitted,
		AccessMode: pgx.ReadWrite,
	})
	if err != nil {
		return operationapp.CreateOrFindResult{}, wrapOperationStoreError("begin transaction", err)
	}
	defer func() {
		_ = tx.Rollback(context.Background())
	}()

	for _, key := range operationIdentityLockKeys(state) {
		if _, err := tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", key); err != nil {
			return operationapp.CreateOrFindResult{}, wrapOperationStoreError("acquire identity lock", err)
		}
	}

	existing, found, err := findOperation(ctx, tx, state)
	if err != nil {
		return operationapp.CreateOrFindResult{}, err
	}
	if found {
		if err := tx.Commit(ctx); err != nil {
			return operationapp.CreateOrFindResult{}, wrapOperationStoreError("commit existing receipt", err)
		}
		return operationapp.CreateOrFindResult{Receipt: existing}, nil
	}

	if _, err := tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", operationSubjectLockKey(state.SubjectID)); err != nil {
		return operationapp.CreateOrFindResult{}, wrapOperationStoreError("acquire subject limit lock", err)
	}
	var livePending int64
	if err := tx.QueryRow(
		ctx,
		countLivePendingOperationsForSubjectSQL,
		state.SubjectID.String(),
		state.CreatedAt.UTC(),
	).Scan(&livePending); err != nil {
		return operationapp.CreateOrFindResult{}, wrapOperationStoreError("count live pending receipts", err)
	}
	if livePending < 0 || livePending > math.MaxInt32 {
		return operationapp.CreateOrFindResult{}, operationapp.ErrOperationStoreInvariant
	}
	if livePending >= int64(s.maxPendingPerSubject) {
		return operationapp.CreateOrFindResult{}, domain.ErrRateLimited
	}

	inserted, err := insertPendingOperation(ctx, tx, state)
	if err == nil {
		if err := tx.Commit(ctx); err != nil {
			return operationapp.CreateOrFindResult{}, wrapOperationStoreError("commit new receipt", err)
		}
		return operationapp.CreateOrFindResult{Receipt: inserted, Created: true}, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return operationapp.CreateOrFindResult{}, err
	}

	// ON CONFLICT can only reach this branch when a writer outside this store
	// ignored the advisory-lock protocol. Resolve to the canonical row instead
	// of attempting another insert or replaying application work.
	existing, found, err = findOperation(ctx, tx, state)
	if err != nil {
		return operationapp.CreateOrFindResult{}, err
	}
	if !found {
		return operationapp.CreateOrFindResult{}, operationapp.ErrOperationStoreInvariant
	}
	if err := tx.Commit(ctx); err != nil {
		return operationapp.CreateOrFindResult{}, wrapOperationStoreError("commit conflicting receipt", err)
	}
	return operationapp.CreateOrFindResult{Receipt: existing}, nil
}

func operationSubjectLockKey(subjectID uuid.UUID) int64 {
	digest := sha256.New()
	writeAdvisoryLockField(digest, []byte("saved-operation-subject-limit-v1"))
	writeAdvisoryLockField(digest, subjectID[:])
	sum := digest.Sum(nil)
	return int64(binary.BigEndian.Uint64(sum[:8]))
}

func validatePendingOperation(pending *domain.SavedOperation) (domain.PersistedOperation, error) {
	if pending == nil {
		return domain.PersistedOperation{}, operationapp.ErrOperationStoreInvariant
	}

	state := pending.PersistenceState()
	restored, err := domain.RestoreOperation(state)
	if err != nil || restored.Status() != domain.OperationStatusPending ||
		restored.Outcome() != domain.OperationOutcomePending {
		return domain.PersistedOperation{}, operationapp.ErrOperationStoreInvariant
	}
	if state.RequestHMACKeyVersion > math.MaxInt32 || state.AcceptedPolicyRevision > math.MaxInt64 {
		return domain.PersistedOperation{}, operationapp.ErrOperationStoreInvariant
	}
	return restored.PersistenceState(), nil
}

func operationIdentityLockKeys(state domain.PersistedOperation) []int64 {
	subject := state.SubjectID.String()
	keys := []int64{
		operationIdentityLockKey(subject, state.SessionGeneration, 'o', state.OperationID.String()),
		operationIdentityLockKey(subject, state.SessionGeneration, 'i', state.IdempotencyKey),
	}
	sort.Slice(keys, func(left, right int) bool { return keys[left] < keys[right] })
	if keys[0] == keys[1] {
		return keys[:1]
	}
	return keys
}

func operationIdentityLockKey(
	subject string,
	sessionGeneration uuid.UUID,
	identityKind byte,
	identity string,
) int64 {
	digest := sha256.New()
	writeAdvisoryLockField(digest, []byte("saved-operation-identity-v1"))
	writeAdvisoryLockField(digest, []byte(subject))
	writeAdvisoryLockField(digest, sessionGeneration[:])
	writeAdvisoryLockField(digest, []byte{identityKind})
	writeAdvisoryLockField(digest, []byte(identity))
	sum := digest.Sum(nil)
	return int64(binary.BigEndian.Uint64(sum[:8]))
}

func writeAdvisoryLockField(digest hash.Hash, value []byte) {
	var length [4]byte
	binary.BigEndian.PutUint32(length[:], uint32(len(value)))
	_, _ = digest.Write(length[:])
	_, _ = digest.Write(value)
}

func findOperation(
	ctx context.Context,
	tx pgx.Tx,
	state domain.PersistedOperation,
) (*domain.SavedOperation, bool, error) {
	receipt, err := scanOperation(tx.QueryRow(
		ctx,
		findOperationSQL,
		state.SubjectID.String(),
		state.SessionGeneration.String(),
		state.OperationID.String(),
		state.IdempotencyKey,
	))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, err
	}
	return receipt, true, nil
}

func insertPendingOperation(
	ctx context.Context,
	tx pgx.Tx,
	state domain.PersistedOperation,
) (*domain.SavedOperation, error) {
	receipt, err := scanOperation(tx.QueryRow(
		ctx,
		insertPendingOperationSQL,
		state.SubjectID.String(),
		state.SessionGeneration.String(),
		state.OperationID.String(),
		string(state.Kind),
		state.IdempotencyKey,
		state.SemanticRequestHMAC,
		int64(state.RequestHMACKeyVersion),
		string(state.FirstSeenSourceSurface),
		int64(state.AcceptedPolicyRevision),
		string(state.Status),
		state.CommitDeadline.UTC(),
		string(state.RefreshScope),
		state.CreatedAt.UTC(),
	))
	if err != nil {
		return nil, err
	}
	return receipt, nil
}

type rowScanner interface {
	Scan(destinations ...any) error
}

type operationRecord struct {
	subject                            string
	sessionGeneration                  string
	operationID                        string
	kind                               string
	idempotencyKey                     string
	semanticRequestHMAC                []byte
	requestHMACKeyVersion              int64
	firstSeenSourceSurface             string
	acceptedPlatformPolicyRevision     int64
	status                             string
	commitDeadline                     time.Time
	outcomeCode                        pgtype.Text
	outcomeRetryable                   pgtype.Bool
	refreshScope                       string
	observedRelationshipVersion        pgtype.Int8
	observedDependentMembershipVersion pgtype.Int8
	observedCollectionMetadataVersion  pgtype.Int8
	observedCollectionLifecycleVersion pgtype.Int8
	appliedRelationshipGeneration      pgtype.Text
	appliedRelationshipVersion         pgtype.Int8
	appliedUserUsageVersion            pgtype.Int8
	appliedDependentMembershipVersion  pgtype.Int8
	appliedCollectionID                pgtype.Text
	appliedCollectionMetadataVersion   pgtype.Int8
	appliedCollectionLifecycleVersion  pgtype.Int8
	createdAt                          time.Time
	completedAt                        pgtype.Timestamptz
	retentionExpiresAt                 pgtype.Timestamptz
}

func scanOperation(row rowScanner) (*domain.SavedOperation, error) {
	var record operationRecord
	if err := row.Scan(
		&record.subject,
		&record.sessionGeneration,
		&record.operationID,
		&record.kind,
		&record.idempotencyKey,
		&record.semanticRequestHMAC,
		&record.requestHMACKeyVersion,
		&record.firstSeenSourceSurface,
		&record.acceptedPlatformPolicyRevision,
		&record.status,
		&record.commitDeadline,
		&record.outcomeCode,
		&record.outcomeRetryable,
		&record.refreshScope,
		&record.observedRelationshipVersion,
		&record.observedDependentMembershipVersion,
		&record.observedCollectionMetadataVersion,
		&record.observedCollectionLifecycleVersion,
		&record.appliedRelationshipGeneration,
		&record.appliedRelationshipVersion,
		&record.appliedUserUsageVersion,
		&record.appliedDependentMembershipVersion,
		&record.appliedCollectionID,
		&record.appliedCollectionMetadataVersion,
		&record.appliedCollectionLifecycleVersion,
		&record.createdAt,
		&record.completedAt,
		&record.retentionExpiresAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, pgx.ErrNoRows
		}
		return nil, wrapOperationStoreError("scan receipt", err)
	}
	return record.restore()
}

func (record operationRecord) restore() (*domain.SavedOperation, error) {
	subjectID, err := parseCanonicalUUID(record.subject)
	if err != nil {
		return nil, invalidPersistedOperation()
	}
	sessionGeneration, err := parseCanonicalUUID(record.sessionGeneration)
	if err != nil {
		return nil, invalidPersistedOperation()
	}
	operationID, err := parseCanonicalUUID(record.operationID)
	if err != nil {
		return nil, invalidPersistedOperation()
	}
	if record.requestHMACKeyVersion <= 0 || record.requestHMACKeyVersion > math.MaxUint32 ||
		record.acceptedPlatformPolicyRevision <= 0 {
		return nil, invalidPersistedOperation()
	}

	observedVersion, err := nullableUint64(record.observedRelationshipVersion, false)
	if err != nil {
		return nil, invalidPersistedOperation()
	}
	appliedRelationshipVersion, err := nullableUint64(record.appliedRelationshipVersion, true)
	if err != nil {
		return nil, invalidPersistedOperation()
	}
	appliedUsageVersion, err := nullableUint64(record.appliedUserUsageVersion, false)
	if err != nil {
		return nil, invalidPersistedOperation()
	}
	observedDependentMembershipVersion, err := nullableUint64(record.observedDependentMembershipVersion, false)
	if err != nil {
		return nil, invalidPersistedOperation()
	}
	observedCollectionMetadataVersion, err := nullableUint64(record.observedCollectionMetadataVersion, false)
	if err != nil {
		return nil, invalidPersistedOperation()
	}
	observedCollectionLifecycleVersion, err := nullableUint64(record.observedCollectionLifecycleVersion, false)
	if err != nil {
		return nil, invalidPersistedOperation()
	}
	appliedDependentMembershipVersion, err := nullableUint64(record.appliedDependentMembershipVersion, false)
	if err != nil {
		return nil, invalidPersistedOperation()
	}
	appliedCollectionMetadataVersion, err := nullableUint64(record.appliedCollectionMetadataVersion, true)
	if err != nil {
		return nil, invalidPersistedOperation()
	}
	appliedCollectionLifecycleVersion, err := nullableUint64(record.appliedCollectionLifecycleVersion, true)
	if err != nil {
		return nil, invalidPersistedOperation()
	}

	var appliedRelationship *domain.AppliedRelationshipVersion
	if record.appliedRelationshipGeneration.Valid {
		generation, err := parseCanonicalUUID(record.appliedRelationshipGeneration.String)
		if err != nil || appliedRelationshipVersion == nil {
			return nil, invalidPersistedOperation()
		}
		appliedRelationship = &domain.AppliedRelationshipVersion{
			Generation: generation,
			Version:    *appliedRelationshipVersion,
		}
	} else if appliedRelationshipVersion != nil {
		return nil, invalidPersistedOperation()
	}

	var appliedCollection *domain.AppliedCollectionVersion
	if record.appliedCollectionID.Valid {
		collectionID, err := parseCanonicalUUID(record.appliedCollectionID.String)
		if err != nil || appliedCollectionMetadataVersion == nil || appliedCollectionLifecycleVersion == nil {
			return nil, invalidPersistedOperation()
		}
		appliedCollection = &domain.AppliedCollectionVersion{
			CollectionID:     collectionID,
			MetadataVersion:  *appliedCollectionMetadataVersion,
			LifecycleVersion: *appliedCollectionLifecycleVersion,
		}
	} else if appliedCollectionMetadataVersion != nil || appliedCollectionLifecycleVersion != nil {
		return nil, invalidPersistedOperation()
	}

	completedAt, err := nullableTime(record.completedAt)
	if err != nil {
		return nil, invalidPersistedOperation()
	}
	retentionExpiresAt, err := nullableTime(record.retentionExpiresAt)
	if err != nil {
		return nil, invalidPersistedOperation()
	}

	status := domain.OperationStatus(record.status)
	outcome, failure, err := restoreOutcome(status, record.outcomeCode, record.outcomeRetryable)
	if err != nil {
		return nil, invalidPersistedOperation()
	}

	restored, err := domain.RestoreOperation(domain.PersistedOperation{
		OperationID:            operationID,
		SubjectID:              subjectID,
		SessionGeneration:      sessionGeneration,
		Kind:                   domain.OperationKind(record.kind),
		IdempotencyKey:         record.idempotencyKey,
		SemanticRequestHMAC:    append([]byte(nil), record.semanticRequestHMAC...),
		RequestHMACKeyVersion:  uint32(record.requestHMACKeyVersion),
		FirstSeenSourceSurface: domain.SourceSurface(record.firstSeenSourceSurface),
		AcceptedPolicyRevision: uint64(record.acceptedPlatformPolicyRevision),
		Status:                 status,
		CommitDeadline:         record.commitDeadline.UTC(),
		CreatedAt:              record.createdAt.UTC(),
		CompletedAt:            completedAt,
		RetentionExpiresAt:     retentionExpiresAt,
		Outcome:                outcome,
		Failure:                failure,
		RefreshScope:           domain.RefreshScope(record.refreshScope),
		Versions: domain.OperationVersionEffects{
			ObservedRelationshipVersion:        observedVersion,
			ObservedDependentMembershipVersion: observedDependentMembershipVersion,
			ObservedCollectionMetadataVersion:  observedCollectionMetadataVersion,
			ObservedCollectionLifecycleVersion: observedCollectionLifecycleVersion,
			AppliedRelationship:                appliedRelationship,
			AppliedUserUsageVersion:            appliedUsageVersion,
			AppliedDependentMembershipVersion:  appliedDependentMembershipVersion,
			AppliedCollection:                  appliedCollection,
		},
	})
	if err != nil {
		return nil, invalidPersistedOperation()
	}
	return restored, nil
}

func restoreOutcome(
	status domain.OperationStatus,
	code pgtype.Text,
	retryable pgtype.Bool,
) (domain.OperationOutcome, *domain.OperationFailure, error) {
	switch status {
	case domain.OperationStatusPending:
		if code.Valid || retryable.Valid {
			return "", nil, operationapp.ErrOperationStoreInvariant
		}
		return domain.OperationOutcomePending, nil, nil
	case domain.OperationStatusSucceeded:
		outcome := domain.OperationOutcome(code.String)
		if !code.Valid || !retryable.Valid || retryable.Bool || !outcome.IsSuccess() {
			return "", nil, operationapp.ErrOperationStoreInvariant
		}
		return outcome, nil, nil
	case domain.OperationStatusRejected:
		failureCode := domain.ErrorCode(code.String)
		if !code.Valid || !retryable.Valid || !isPersistedOperationFailure(failureCode) {
			return "", nil, operationapp.ErrOperationStoreInvariant
		}
		return domain.OperationOutcomeRejected, &domain.OperationFailure{
			Code:      failureCode,
			Retryable: retryable.Bool,
		}, nil
	case domain.OperationStatusExpired:
		if !code.Valid || code.String != string(domain.OperationOutcomeExpired) ||
			!retryable.Valid || retryable.Bool {
			return "", nil, operationapp.ErrOperationStoreInvariant
		}
		return domain.OperationOutcomeExpired, nil, nil
	default:
		return "", nil, operationapp.ErrOperationStoreInvariant
	}
}

func isPersistedOperationFailure(code domain.ErrorCode) bool {
	switch code {
	case domain.ErrorCodeTargetTypeUnsupported,
		domain.ErrorCodeTargetUnavailable,
		domain.ErrorCodeDependencyUnavailable,
		domain.ErrorCodeMutationStale,
		domain.ErrorCodeReplayMismatch,
		domain.ErrorCodeCollectionNotFound,
		domain.ErrorCodeCollectionDeleted,
		domain.ErrorCodeCollectionTitleInvalid,
		domain.ErrorCodeCollectionTitleConflict,
		domain.ErrorCodeCollectionLimitReached,
		domain.ErrorCodeCollectionItemLimitReached,
		domain.ErrorCodeMembershipLimitReached,
		domain.ErrorCodeItemLimitReached,
		domain.ErrorCodeRateLimited,
		domain.ErrorCodeTemporarilyUnavailable,
		domain.ErrorCodePlatformPersonalDataLocked:
		return true
	default:
		return false
	}
}

func nullableUint64(value pgtype.Int8, positive bool) (*uint64, error) {
	if !value.Valid {
		return nil, nil
	}
	if value.Int64 < 0 || (positive && value.Int64 == 0) {
		return nil, operationapp.ErrOperationStoreInvariant
	}
	converted := uint64(value.Int64)
	return &converted, nil
}

func nullableTime(value pgtype.Timestamptz) (*time.Time, error) {
	if !value.Valid {
		return nil, nil
	}
	if value.InfinityModifier != pgtype.Finite || value.Time.IsZero() {
		return nil, operationapp.ErrOperationStoreInvariant
	}
	converted := value.Time.UTC()
	return &converted, nil
}

func parseCanonicalUUID(value string) (uuid.UUID, error) {
	parsed, err := uuid.Parse(value)
	if err != nil || parsed == uuid.Nil || parsed.String() != value {
		return uuid.Nil, operationapp.ErrOperationStoreInvariant
	}
	return parsed, nil
}

func invalidPersistedOperation() error {
	return fmt.Errorf("%w: invalid persisted receipt", operationapp.ErrOperationStoreInvariant)
}

func wrapOperationStoreError(stage string, err error) error {
	return fmt.Errorf("%w: %s: %w", ErrOperationStoreUnavailable, stage, err)
}
