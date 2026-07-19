package repository

import (
	"bytes"
	"errors"
	"math"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	operationapp "kz/inflap/backend/services/saved-service/internal/app/operation"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestNewPGOperationStoreRejectsNilPool(t *testing.T) {
	t.Parallel()

	store, err := NewPGOperationStore(nil, maxPendingOperationsPerSubject)
	if !errors.Is(err, ErrInvalidOperationStoreDependencies) {
		t.Fatalf("NewPGOperationStore() error = %v, want dependency error", err)
	}
	if store != nil {
		t.Fatal("NewPGOperationStore() returned a store for a nil pool")
	}
	if store, err = NewPGOperationStore(&pgxpool.Pool{}, 0); err == nil || store != nil {
		t.Fatal("NewPGOperationStore() accepted a zero pending-operation limit")
	}
}

func TestOperationIdentityLockKeysAreScopedAndOrdered(t *testing.T) {
	t.Parallel()

	state := domain.PersistedOperation{
		OperationID:       uuid.MustParse("11111111-1111-4111-8111-111111111111"),
		SubjectID:         uuid.MustParse("22222222-2222-4222-8222-222222222222"),
		SessionGeneration: uuid.MustParse("33333333-3333-4333-8333-333333333333"),
		IdempotencyKey:    strings.Repeat("a", 22),
	}

	keys := operationIdentityLockKeys(state)
	repeated := operationIdentityLockKeys(state)
	if !reflect.DeepEqual(keys, repeated) {
		t.Fatalf("lock keys are not deterministic: %v vs %v", keys, repeated)
	}
	if len(keys) != 2 || keys[0] >= keys[1] {
		t.Fatalf("lock keys = %v, want two strictly ordered keys", keys)
	}

	otherSession := state
	otherSession.SessionGeneration = uuid.MustParse("44444444-4444-4444-8444-444444444444")
	if reflect.DeepEqual(keys, operationIdentityLockKeys(otherSession)) {
		t.Fatal("session generation did not scope advisory lock keys")
	}

	otherSubject := state
	otherSubject.SubjectID = uuid.MustParse("55555555-5555-4555-8555-555555555555")
	if reflect.DeepEqual(keys, operationIdentityLockKeys(otherSubject)) {
		t.Fatal("subject did not scope advisory lock keys")
	}
}

func TestScanOperationMapsEveryPendingColumn(t *testing.T) {
	t.Parallel()

	record := validPendingOperationRecord()
	receipt, err := scanOperation(staticOperationRow{values: record.values()})
	if err != nil {
		t.Fatalf("scanOperation() error = %v", err)
	}

	state := receipt.PersistenceState()
	if state.SubjectID.String() != record.subject ||
		state.SessionGeneration.String() != record.sessionGeneration ||
		state.OperationID.String() != record.operationID ||
		string(state.Kind) != record.kind ||
		state.IdempotencyKey != record.idempotencyKey ||
		!bytes.Equal(state.SemanticRequestHMAC, record.semanticRequestHMAC) ||
		state.RequestHMACKeyVersion != uint32(record.requestHMACKeyVersion) ||
		string(state.FirstSeenSourceSurface) != record.firstSeenSourceSurface ||
		state.AcceptedPolicyRevision != uint64(record.acceptedPlatformPolicyRevision) ||
		string(state.Status) != record.status ||
		!state.CommitDeadline.Equal(record.commitDeadline) ||
		string(state.RefreshScope) != record.refreshScope ||
		!state.CreatedAt.Equal(record.createdAt) {
		t.Fatalf("restored pending state does not match all persisted columns: %+v", state)
	}
	if state.Outcome != domain.OperationOutcomePending || state.Failure != nil ||
		state.CompletedAt != nil || state.RetentionExpiresAt != nil ||
		state.Versions.ObservedRelationshipVersion != nil ||
		state.Versions.ObservedDependentMembershipVersion != nil ||
		state.Versions.ObservedCollectionMetadataVersion != nil ||
		state.Versions.ObservedCollectionLifecycleVersion != nil ||
		state.Versions.AppliedRelationship != nil ||
		state.Versions.AppliedUserUsageVersion != nil ||
		state.Versions.AppliedDependentMembershipVersion != nil ||
		state.Versions.AppliedCollection != nil {
		t.Fatalf("restored pending lifecycle contains terminal data: %+v", state)
	}
}

func TestOperationRecordRestoresTerminalLifecycles(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name          string
		mutate        func(*operationRecord)
		wantStatus    domain.OperationStatus
		wantOutcome   domain.OperationOutcome
		wantFailure   domain.ErrorCode
		wantRetryable bool
	}{
		{
			name: "applied",
			mutate: func(record *operationRecord) {
				completeSuccessfulRecord(record, domain.OperationOutcomeApplied)
			},
			wantStatus:  domain.OperationStatusSucceeded,
			wantOutcome: domain.OperationOutcomeApplied,
		},
		{
			name: "no-op",
			mutate: func(record *operationRecord) {
				completeSuccessfulRecord(record, domain.OperationOutcomeNoOp)
			},
			wantStatus:  domain.OperationStatusSucceeded,
			wantOutcome: domain.OperationOutcomeNoOp,
		},
		{
			name: "rejected",
			mutate: func(record *operationRecord) {
				completedAt := record.createdAt.Add(2 * time.Second)
				record.status = string(domain.OperationStatusRejected)
				record.outcomeCode = pgtype.Text{String: string(domain.ErrorCodeDependencyUnavailable), Valid: true}
				record.outcomeRetryable = pgtype.Bool{Bool: true, Valid: true}
				record.refreshScope = string(domain.RefreshScopeSavedItems)
				record.completedAt = finiteTimestamptz(completedAt)
				record.retentionExpiresAt = finiteTimestamptz(completedAt.Add(14 * 24 * time.Hour))
			},
			wantStatus:    domain.OperationStatusRejected,
			wantOutcome:   domain.OperationOutcomeRejected,
			wantFailure:   domain.ErrorCodeDependencyUnavailable,
			wantRetryable: true,
		},
		{
			name: "rejected collection operation",
			mutate: func(record *operationRecord) {
				completedAt := record.createdAt.Add(2 * time.Second)
				record.kind = string(domain.OperationKindCreateCollection)
				record.status = string(domain.OperationStatusRejected)
				record.outcomeCode = pgtype.Text{String: string(domain.ErrorCodeCollectionTitleConflict), Valid: true}
				record.outcomeRetryable = pgtype.Bool{Bool: false, Valid: true}
				record.refreshScope = string(domain.RefreshScopeCollections)
				record.completedAt = finiteTimestamptz(completedAt)
				record.retentionExpiresAt = finiteTimestamptz(completedAt.Add(14 * 24 * time.Hour))
			},
			wantStatus:  domain.OperationStatusRejected,
			wantOutcome: domain.OperationOutcomeRejected,
			wantFailure: domain.ErrorCodeCollectionTitleConflict,
		},
		{
			name: "expired",
			mutate: func(record *operationRecord) {
				completedAt := record.commitDeadline
				record.status = string(domain.OperationStatusExpired)
				record.outcomeCode = pgtype.Text{String: string(domain.OperationOutcomeExpired), Valid: true}
				record.outcomeRetryable = pgtype.Bool{Bool: false, Valid: true}
				record.refreshScope = string(domain.RefreshScopeSavedItems)
				record.completedAt = finiteTimestamptz(completedAt)
				record.retentionExpiresAt = finiteTimestamptz(completedAt.Add(14 * 24 * time.Hour))
			},
			wantStatus:  domain.OperationStatusExpired,
			wantOutcome: domain.OperationOutcomeExpired,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			record := validPendingOperationRecord()
			test.mutate(&record)

			receipt, err := record.restore()
			if err != nil {
				t.Fatalf("restore() error = %v", err)
			}
			if receipt.Status() != test.wantStatus || receipt.Outcome() != test.wantOutcome {
				t.Fatalf("restored lifecycle = (%s, %s), want (%s, %s)",
					receipt.Status(), receipt.Outcome(), test.wantStatus, test.wantOutcome)
			}
			failure := receipt.Failure()
			if test.wantFailure == "" {
				if failure != nil {
					t.Fatalf("Failure() = %+v, want nil", failure)
				}
			} else if failure == nil || failure.Code != test.wantFailure || failure.Retryable != test.wantRetryable {
				t.Fatalf("Failure() = %+v, want (%s, retryable=%t)", failure, test.wantFailure, test.wantRetryable)
			}
		})
	}
}

func TestOperationRecordRestoresCollectionVersionEffects(t *testing.T) {
	t.Parallel()

	record := validPendingOperationRecord()
	record.kind = string(domain.OperationKindSetTargetCollections)
	completeSuccessfulRecord(&record, domain.OperationOutcomeApplied)
	record.observedDependentMembershipVersion = pgtype.Int8{Int64: 7, Valid: true}
	record.appliedDependentMembershipVersion = pgtype.Int8{Int64: 8, Valid: true}
	record.appliedCollectionID = pgtype.Text{
		String: uuid.MustParse("77777777-7777-4777-8777-777777777777").String(),
		Valid:  true,
	}
	record.appliedCollectionMetadataVersion = pgtype.Int8{Int64: 1, Valid: true}
	record.appliedCollectionLifecycleVersion = pgtype.Int8{Int64: 1, Valid: true}

	receipt, err := record.restore()
	if err != nil {
		t.Fatalf("restore() error = %v", err)
	}
	state := receipt.PersistenceState()
	if state.Versions.ObservedDependentMembershipVersion == nil ||
		*state.Versions.ObservedDependentMembershipVersion != 7 ||
		state.Versions.AppliedDependentMembershipVersion == nil ||
		*state.Versions.AppliedDependentMembershipVersion != 8 ||
		state.Versions.AppliedCollection == nil ||
		state.Versions.AppliedCollection.CollectionID.String() != record.appliedCollectionID.String ||
		state.Versions.AppliedCollection.MetadataVersion != 1 ||
		state.Versions.AppliedCollection.LifecycleVersion != 1 {
		t.Fatalf("restored collection versions = %+v", state.Versions)
	}
}

func TestOperationRecordRejectsCorruptState(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		mutate func(*operationRecord)
	}{
		{
			name: "non-canonical subject",
			mutate: func(record *operationRecord) {
				record.subject = strings.ToUpper("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
			},
		},
		{
			name: "negative policy revision",
			mutate: func(record *operationRecord) {
				record.acceptedPlatformPolicyRevision = -1
			},
		},
		{
			name: "key version overflow",
			mutate: func(record *operationRecord) {
				record.requestHMACKeyVersion = int64(math.MaxUint32) + 1
			},
		},
		{
			name: "pending outcome",
			mutate: func(record *operationRecord) {
				record.outcomeCode = pgtype.Text{String: string(domain.OperationOutcomeApplied), Valid: true}
			},
		},
		{
			name: "unpaired relationship generation",
			mutate: func(record *operationRecord) {
				record.appliedRelationshipGeneration = pgtype.Text{
					String: uuid.MustParse("66666666-6666-4666-8666-666666666666").String(),
					Valid:  true,
				}
			},
		},
		{
			name: "invalid retention",
			mutate: func(record *operationRecord) {
				completeSuccessfulRecord(record, domain.OperationOutcomeApplied)
				record.retentionExpiresAt.Time = record.retentionExpiresAt.Time.Add(time.Second)
			},
		},
		{
			name: "rejection outside persisted operation vocabulary",
			mutate: func(record *operationRecord) {
				completedAt := record.createdAt.Add(2 * time.Second)
				record.status = string(domain.OperationStatusRejected)
				record.outcomeCode = pgtype.Text{String: string(domain.ErrorCodeCursorInvalid), Valid: true}
				record.outcomeRetryable = pgtype.Bool{Bool: false, Valid: true}
				record.completedAt = finiteTimestamptz(completedAt)
				record.retentionExpiresAt = finiteTimestamptz(completedAt.Add(14 * 24 * time.Hour))
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			record := validPendingOperationRecord()
			test.mutate(&record)
			if _, err := record.restore(); !errors.Is(err, operationapp.ErrOperationStoreInvariant) {
				t.Fatalf("restore() error = %v, want invariant error", err)
			}
		})
	}
}

func TestScanOperationPreservesNoRows(t *testing.T) {
	t.Parallel()

	_, err := scanOperation(staticOperationRow{err: pgx.ErrNoRows})
	if !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("scanOperation() error = %v, want pgx.ErrNoRows", err)
	}
}

func TestValidatePendingOperationRejectsTerminalReceipt(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	receipt, err := domain.NewPendingOperation(
		uuid.MustParse("11111111-1111-4111-8111-111111111111"),
		uuid.MustParse("22222222-2222-4222-8222-222222222222"),
		uuid.MustParse("33333333-3333-4333-8333-333333333333"),
		domain.OperationKindSave,
		strings.Repeat("a", 22),
		bytes.Repeat([]byte{0x42}, 32),
		1,
		domain.SourceSurfaceCard,
		7,
		now,
		now.Add(10*time.Second),
	)
	if err != nil {
		t.Fatalf("NewPendingOperation() error = %v", err)
	}
	if err := receipt.Succeed(now.Add(time.Second), domain.OperationOutcomeNoOp, domain.RefreshScopeNone, domain.OperationVersionEffects{}); err != nil {
		t.Fatalf("Succeed() error = %v", err)
	}

	if _, err := validatePendingOperation(receipt); !errors.Is(err, operationapp.ErrOperationStoreInvariant) {
		t.Fatalf("validatePendingOperation() error = %v, want invariant error", err)
	}
}

func validPendingOperationRecord() operationRecord {
	createdAt := time.Date(2026, time.July, 16, 12, 0, 0, 123000000, time.UTC)
	return operationRecord{
		subject:                        uuid.MustParse("22222222-2222-4222-8222-222222222222").String(),
		sessionGeneration:              uuid.MustParse("33333333-3333-4333-8333-333333333333").String(),
		operationID:                    uuid.MustParse("11111111-1111-4111-8111-111111111111").String(),
		kind:                           string(domain.OperationKindSave),
		idempotencyKey:                 strings.Repeat("a", 22),
		semanticRequestHMAC:            bytes.Repeat([]byte{0x42}, 32),
		requestHMACKeyVersion:          3,
		firstSeenSourceSurface:         string(domain.SourceSurfaceCard),
		acceptedPlatformPolicyRevision: 7,
		status:                         string(domain.OperationStatusPending),
		commitDeadline:                 createdAt.Add(10 * time.Second),
		refreshScope:                   string(domain.RefreshScopeNone),
		createdAt:                      createdAt,
	}
}

func completeSuccessfulRecord(record *operationRecord, outcome domain.OperationOutcome) {
	completedAt := record.createdAt.Add(2 * time.Second)
	record.status = string(domain.OperationStatusSucceeded)
	record.outcomeCode = pgtype.Text{String: string(outcome), Valid: true}
	record.outcomeRetryable = pgtype.Bool{Bool: false, Valid: true}
	record.refreshScope = string(domain.RefreshScopeBoth)
	record.observedRelationshipVersion = pgtype.Int8{Int64: 4, Valid: true}
	record.appliedRelationshipGeneration = pgtype.Text{
		String: uuid.MustParse("66666666-6666-4666-8666-666666666666").String(),
		Valid:  true,
	}
	record.appliedRelationshipVersion = pgtype.Int8{Int64: 5, Valid: true}
	record.appliedUserUsageVersion = pgtype.Int8{Int64: 6, Valid: true}
	record.completedAt = finiteTimestamptz(completedAt)
	record.retentionExpiresAt = finiteTimestamptz(completedAt.Add(14 * 24 * time.Hour))
}

func finiteTimestamptz(value time.Time) pgtype.Timestamptz {
	return pgtype.Timestamptz{Time: value, InfinityModifier: pgtype.Finite, Valid: true}
}

func (record operationRecord) values() []any {
	return []any{
		record.subject,
		record.sessionGeneration,
		record.operationID,
		record.kind,
		record.idempotencyKey,
		record.semanticRequestHMAC,
		record.requestHMACKeyVersion,
		record.firstSeenSourceSurface,
		record.acceptedPlatformPolicyRevision,
		record.status,
		record.commitDeadline,
		record.outcomeCode,
		record.outcomeRetryable,
		record.refreshScope,
		record.observedRelationshipVersion,
		record.observedDependentMembershipVersion,
		record.observedCollectionMetadataVersion,
		record.observedCollectionLifecycleVersion,
		record.appliedRelationshipGeneration,
		record.appliedRelationshipVersion,
		record.appliedUserUsageVersion,
		record.appliedDependentMembershipVersion,
		record.appliedCollectionID,
		record.appliedCollectionMetadataVersion,
		record.appliedCollectionLifecycleVersion,
		record.createdAt,
		record.completedAt,
		record.retentionExpiresAt,
	}
}

type staticOperationRow struct {
	values []any
	err    error
}

func (row staticOperationRow) Scan(destinations ...any) error {
	if row.err != nil {
		return row.err
	}
	if len(destinations) != len(row.values) {
		return errors.New("unexpected scan destination count")
	}
	for index, value := range row.values {
		destination := reflect.ValueOf(destinations[index])
		if destination.Kind() != reflect.Pointer || destination.IsNil() {
			return errors.New("scan destination is not a pointer")
		}
		destination.Elem().Set(reflect.ValueOf(value))
	}
	return nil
}
