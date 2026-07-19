package repository

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"sort"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	savedmaintenance "kz/inflap/backend/services/saved-service/internal/app/savedmaintenance"
)

const subjectPurgeColumns = `
    operation_id,
    subject,
    owner_user_id,
    phase,
    attempt_count,
    next_attempt_at,
    last_error_code,
    created_at,
    updated_at,
    completed_at,
    retention_expires_at`

const insertSubjectPurgeSQL = `
INSERT INTO saved_subject_purge_operations (
    operation_id,
    subject,
    owner_user_id,
    phase,
    attempt_count,
    next_attempt_at,
    created_at,
    updated_at
) VALUES ($1, $2, $3, 'OUTBOX', 0, $4, $4, $4)
ON CONFLICT DO NOTHING`

const findSubjectPurgeIdentitySQL = `
SELECT ` + subjectPurgeColumns + `
FROM saved_subject_purge_operations
WHERE operation_id = $1
   OR subject = $2
   OR owner_user_id = $3
ORDER BY (operation_id = $1) DESC, created_at, operation_id
LIMIT 1`

const getSubjectPurgeSQL = `
SELECT ` + subjectPurgeColumns + `
FROM saved_subject_purge_operations
WHERE operation_id = $1`

const lockNextSubjectPurgeSQL = `
SELECT ` + subjectPurgeColumns + `
FROM saved_subject_purge_operations
WHERE phase <> 'COMPLETED'
  AND next_attempt_at <= $1
ORDER BY next_attempt_at, created_at, operation_id
LIMIT 1
FOR UPDATE SKIP LOCKED`

const lockSubjectPurgeByIDSQL = `
SELECT ` + subjectPurgeColumns + `
FROM saved_subject_purge_operations
WHERE operation_id = $1
FOR UPDATE SKIP LOCKED`

const subjectPurgeExistsSQL = `
SELECT EXISTS (
    SELECT 1 FROM saved_subject_purge_operations WHERE operation_id = $1
)`

const advanceSubjectPurgeSQL = `
UPDATE saved_subject_purge_operations
SET phase = $3::text,
    next_attempt_at = CASE
        WHEN $3::text = 'COMPLETED' THEN NULL::timestamptz
        ELSE $2::timestamptz
    END,
    last_error_code = NULL,
    updated_at = $2::timestamptz,
    completed_at = CASE
        WHEN $3::text = 'COMPLETED' THEN $2::timestamptz
        ELSE NULL::timestamptz
    END,
    retention_expires_at = CASE
        WHEN $3::text = 'COMPLETED' THEN $4::timestamptz
        ELSE NULL::timestamptz
    END
WHERE operation_id = $1
  AND phase = $5`

type subjectPurgeRecord struct {
	operationID        uuid.UUID
	subject            string
	ownerUserID        uuid.UUID
	phase              string
	attemptCount       int
	nextAttemptAt      pgtype.Timestamptz
	lastErrorCode      pgtype.Text
	createdAt          time.Time
	updatedAt          time.Time
	completedAt        pgtype.Timestamptz
	retentionExpiresAt pgtype.Timestamptz
}

func (r *PGSavedMaintenanceRepository) StartSubjectPurge(
	ctx context.Context,
	start savedmaintenance.SubjectPurgeStart,
	now time.Time,
) (savedmaintenance.SubjectPurgeJob, error) {
	if err := ctx.Err(); err != nil {
		return savedmaintenance.SubjectPurgeJob{}, err
	}
	if r == nil || r.pool == nil {
		return savedmaintenance.SubjectPurgeJob{}, ErrInvalidSavedMaintenanceDependencies
	}
	if err := start.Validate(); err != nil || now.IsZero() {
		return savedmaintenance.SubjectPurgeJob{}, savedmaintenance.ErrInvalidSubjectPurge
	}

	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.ReadCommitted, AccessMode: pgx.ReadWrite})
	if err != nil {
		return savedmaintenance.SubjectPurgeJob{}, mapSavedMaintenanceError("start subject purge", err)
	}
	defer func() { _ = tx.Rollback(context.Background()) }()

	lockKeys := []int64{
		subjectPurgeAdvisoryKey("subject", start.Subject),
		subjectPurgeAdvisoryKey("owner", start.OwnerUserID.String()),
	}
	sort.Slice(lockKeys, func(left, right int) bool { return lockKeys[left] < lockKeys[right] })
	for index, lockKey := range lockKeys {
		if index > 0 && lockKey == lockKeys[index-1] {
			continue
		}
		if _, err := tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", lockKey); err != nil {
			return savedmaintenance.SubjectPurgeJob{}, mapSavedMaintenanceError("start subject purge", err)
		}
	}

	if _, err := tx.Exec(
		ctx,
		insertSubjectPurgeSQL,
		start.OperationID,
		start.Subject,
		start.OwnerUserID,
		now.UTC(),
	); err != nil {
		return savedmaintenance.SubjectPurgeJob{}, mapSavedMaintenanceError("start subject purge", err)
	}

	job, err := scanSubjectPurge(tx.QueryRow(
		ctx,
		findSubjectPurgeIdentitySQL,
		start.OperationID,
		start.Subject,
		start.OwnerUserID,
	))
	if err != nil {
		return savedmaintenance.SubjectPurgeJob{}, mapSavedMaintenanceError("start subject purge", err)
	}
	if job.OperationID != start.OperationID || job.Subject != start.Subject || job.OwnerUserID != start.OwnerUserID {
		return savedmaintenance.SubjectPurgeJob{}, savedmaintenance.NewError(
			"start subject purge",
			savedmaintenance.ErrorKindInvariant,
			false,
			savedmaintenance.ErrSubjectPurgeIdentityClash,
		)
	}
	if err := tx.Commit(ctx); err != nil {
		return savedmaintenance.SubjectPurgeJob{}, mapSavedMaintenanceError("start subject purge", err)
	}
	return job, nil
}

func (r *PGSavedMaintenanceRepository) GetSubjectPurge(
	ctx context.Context,
	operationID uuid.UUID,
) (savedmaintenance.SubjectPurgeJob, error) {
	if err := ctx.Err(); err != nil {
		return savedmaintenance.SubjectPurgeJob{}, err
	}
	if r == nil || r.pool == nil || operationID == uuid.Nil {
		return savedmaintenance.SubjectPurgeJob{}, ErrInvalidSavedMaintenanceDependencies
	}
	job, err := scanSubjectPurge(r.pool.QueryRow(ctx, getSubjectPurgeSQL, operationID))
	if errors.Is(err, pgx.ErrNoRows) {
		return savedmaintenance.SubjectPurgeJob{}, savedmaintenance.ErrSubjectPurgeNotFound
	}
	if err != nil {
		return savedmaintenance.SubjectPurgeJob{}, mapSavedMaintenanceError("get subject purge", err)
	}
	return job, nil
}

func (r *PGSavedMaintenanceRepository) ProcessSubjectPurge(
	ctx context.Context,
	request savedmaintenance.SubjectPurgeBatchRequest,
) (savedmaintenance.SubjectPurgeBatchResult, error) {
	if err := ctx.Err(); err != nil {
		return savedmaintenance.SubjectPurgeBatchResult{}, err
	}
	if r == nil || r.pool == nil {
		return savedmaintenance.SubjectPurgeBatchResult{}, ErrInvalidSavedMaintenanceDependencies
	}
	if err := request.Validate(); err != nil {
		return savedmaintenance.SubjectPurgeBatchResult{}, err
	}

	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.ReadCommitted, AccessMode: pgx.ReadWrite})
	if err != nil {
		return savedmaintenance.SubjectPurgeBatchResult{}, mapSavedMaintenanceError("process subject purge", err)
	}
	defer func() { _ = tx.Rollback(context.Background()) }()

	var job savedmaintenance.SubjectPurgeJob
	if request.OperationID == nil {
		job, err = scanSubjectPurge(tx.QueryRow(ctx, lockNextSubjectPurgeSQL, request.Batch.Now.UTC()))
	} else {
		job, err = scanSubjectPurge(tx.QueryRow(ctx, lockSubjectPurgeByIDSQL, *request.OperationID))
	}
	if errors.Is(err, pgx.ErrNoRows) {
		if request.OperationID != nil {
			var exists bool
			if existsErr := tx.QueryRow(ctx, subjectPurgeExistsSQL, *request.OperationID).Scan(&exists); existsErr != nil {
				return savedmaintenance.SubjectPurgeBatchResult{}, mapSavedMaintenanceError(
					"process subject purge",
					existsErr,
				)
			}
			if exists {
				return savedmaintenance.SubjectPurgeBatchResult{}, savedmaintenance.NewError(
					"process subject purge",
					savedmaintenance.ErrorKindContention,
					true,
					errors.New("subject purge checkpoint is locked"),
				)
			}
		}
		if err := tx.Commit(ctx); err != nil {
			return savedmaintenance.SubjectPurgeBatchResult{}, mapSavedMaintenanceError("process subject purge", err)
		}
		return savedmaintenance.SubjectPurgeBatchResult{}, nil
	}
	if err != nil {
		return savedmaintenance.SubjectPurgeBatchResult{}, mapSavedMaintenanceError("process subject purge", err)
	}

	result := savedmaintenance.SubjectPurgeBatchResult{
		Found:       true,
		OperationID: job.OperationID,
		PhaseBefore: job.Phase,
		PhaseAfter:  job.Phase,
		Completed:   job.Phase == savedmaintenance.SubjectPurgePhaseCompleted,
		HasMore:     job.Phase != savedmaintenance.SubjectPurgePhaseCompleted,
	}
	if result.Completed {
		if err := tx.Commit(ctx); err != nil {
			return savedmaintenance.SubjectPurgeBatchResult{}, mapSavedMaintenanceError("process subject purge", err)
		}
		return result, nil
	}

	phaseSQL, remainingSQL, nextPhase, ok := subjectPurgePhaseQueries(job.Phase)
	if !ok {
		return savedmaintenance.SubjectPurgeBatchResult{}, savedmaintenance.NewError(
			"process subject purge",
			savedmaintenance.ErrorKindInvariant,
			false,
			savedmaintenance.ErrInvalidSubjectPurge,
		)
	}
	if err := tx.QueryRow(
		ctx,
		phaseSQL,
		job.OwnerUserID,
		job.Subject,
		request.Batch.Limit,
	).Scan(&result.RowsPurged); err != nil {
		return savedmaintenance.SubjectPurgeBatchResult{}, mapSavedMaintenanceError("process subject purge", err)
	}
	if result.RowsPurged < int64(request.Batch.Limit) {
		var rowsRemain bool
		if err := tx.QueryRow(ctx, remainingSQL, job.OwnerUserID, job.Subject).Scan(&rowsRemain); err != nil {
			return savedmaintenance.SubjectPurgeBatchResult{}, mapSavedMaintenanceError("process subject purge", err)
		}
		if !rowsRemain {
			result.PhaseAfter = nextPhase
			result.PhaseAdvanced = true
			result.Completed = nextPhase == savedmaintenance.SubjectPurgePhaseCompleted
			result.HasMore = !result.Completed
			tag, err := tx.Exec(
				ctx,
				advanceSubjectPurgeSQL,
				job.OperationID,
				request.Batch.Now.UTC(),
				string(nextPhase),
				request.Batch.Now.Add(request.Batch.OperationRetention).UTC(),
				string(job.Phase),
			)
			if err != nil {
				return savedmaintenance.SubjectPurgeBatchResult{}, mapSavedMaintenanceError("process subject purge", err)
			}
			if tag.RowsAffected() != 1 {
				return savedmaintenance.SubjectPurgeBatchResult{}, savedmaintenance.NewError(
					"process subject purge",
					savedmaintenance.ErrorKindInvariant,
					false,
					savedmaintenance.ErrInvalidSubjectPurge,
				)
			}
		}
	}
	if err := result.Validate(request.Batch.Limit); err != nil {
		return savedmaintenance.SubjectPurgeBatchResult{}, savedmaintenance.NewError(
			"process subject purge",
			savedmaintenance.ErrorKindInvariant,
			false,
			err,
		)
	}
	if err := tx.Commit(ctx); err != nil {
		return savedmaintenance.SubjectPurgeBatchResult{}, mapSavedMaintenanceError("process subject purge", err)
	}
	return result, nil
}

func subjectPurgePhaseQueries(
	phase savedmaintenance.SubjectPurgePhase,
) (deleteSQL string, remainingSQL string, next savedmaintenance.SubjectPurgePhase, ok bool) {
	switch phase {
	case savedmaintenance.SubjectPurgePhaseOutbox:
		return purgeSubjectOutboxSQL, subjectOutboxRemainsSQL, savedmaintenance.SubjectPurgePhaseCollectionItems, true
	case savedmaintenance.SubjectPurgePhaseCollectionItems:
		return purgeSubjectCollectionItemsSQL, subjectCollectionItemsRemainSQL, savedmaintenance.SubjectPurgePhaseCollections, true
	case savedmaintenance.SubjectPurgePhaseCollections:
		return purgeSubjectCollectionsSQL, subjectCollectionsRemainSQL, savedmaintenance.SubjectPurgePhaseSavedItems, true
	case savedmaintenance.SubjectPurgePhaseSavedItems:
		return purgeSubjectSavedItemsSQL, subjectSavedItemsRemainSQL, savedmaintenance.SubjectPurgePhaseOperations, true
	case savedmaintenance.SubjectPurgePhaseOperations:
		return purgeSubjectOperationsSQL, subjectOperationsRemainSQL, savedmaintenance.SubjectPurgePhaseCollectionUsage, true
	case savedmaintenance.SubjectPurgePhaseCollectionUsage:
		return purgeSubjectCollectionUsageSQL, subjectCollectionUsageRemainsSQL, savedmaintenance.SubjectPurgePhaseUserUsage, true
	case savedmaintenance.SubjectPurgePhaseUserUsage:
		return purgeSubjectUserUsageSQL, subjectUserUsageRemainsSQL, savedmaintenance.SubjectPurgePhaseCompleted, true
	default:
		return "", "", "", false
	}
}

type maintenanceRowScanner interface {
	Scan(...any) error
}

func scanSubjectPurge(row maintenanceRowScanner) (savedmaintenance.SubjectPurgeJob, error) {
	var record subjectPurgeRecord
	if err := row.Scan(
		&record.operationID,
		&record.subject,
		&record.ownerUserID,
		&record.phase,
		&record.attemptCount,
		&record.nextAttemptAt,
		&record.lastErrorCode,
		&record.createdAt,
		&record.updatedAt,
		&record.completedAt,
		&record.retentionExpiresAt,
	); err != nil {
		return savedmaintenance.SubjectPurgeJob{}, err
	}
	job := savedmaintenance.SubjectPurgeJob{
		OperationID:        record.operationID,
		Subject:            record.subject,
		OwnerUserID:        record.ownerUserID,
		Phase:              savedmaintenance.SubjectPurgePhase(record.phase),
		AttemptCount:       record.attemptCount,
		LastErrorCode:      record.lastErrorCode.String,
		CreatedAt:          record.createdAt.UTC(),
		UpdatedAt:          record.updatedAt.UTC(),
		NextAttemptAt:      maintenanceNullableTime(record.nextAttemptAt),
		CompletedAt:        maintenanceNullableTime(record.completedAt),
		RetentionExpiresAt: maintenanceNullableTime(record.retentionExpiresAt),
	}
	if err := job.Validate(); err != nil {
		return savedmaintenance.SubjectPurgeJob{}, err
	}
	return job, nil
}

func maintenanceNullableTime(value pgtype.Timestamptz) *time.Time {
	if !value.Valid || value.InfinityModifier != pgtype.Finite {
		return nil
	}
	converted := value.Time.UTC()
	return &converted
}

func subjectPurgeAdvisoryKey(kind string, value string) int64 {
	digest := sha256.New()
	subjectPurgeHashField(digest, []byte("saved-subject-purge-v1"))
	subjectPurgeHashField(digest, []byte(kind))
	subjectPurgeHashField(digest, []byte(value))
	return int64(binary.BigEndian.Uint64(digest.Sum(nil)[:8]))
}

type subjectPurgeHashWriter interface {
	Write([]byte) (int, error)
}

func subjectPurgeHashField(writer subjectPurgeHashWriter, value []byte) {
	var length [4]byte
	binary.BigEndian.PutUint32(length[:], uint32(len(value)))
	_, _ = writer.Write(length[:])
	_, _ = writer.Write(value)
}
